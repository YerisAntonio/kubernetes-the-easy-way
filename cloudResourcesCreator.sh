#! /bin/bash
set -e

#Create the kubernetes-the-hard-way custom VPC network:
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom

#A subnet must be provisioned with an IP address range large 
#enough to assign a private IP address to each node in the Kubernetes cluster.
#Create the kubernetes subnet in the kubernetes-the-hard-way VPC network:
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24

#Create a firewall rule that allows internal communication across all protocols:
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

#Create a firewall rule that allows external SSH, ICMP, and HTTPS:
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0

#List the firewall rules in the kubernetes-the-hard-way VPC network:
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"

#Allocate a static IP address that will be attached to the external load balancer 
#fronting the Kubernetes API Servers:
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)

#Verify the kubernetes-the-hard-way static IP address was created in your 
#default compute region:
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"

#Create three compute instances which will host the Kubernetes control plane:
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done

#Create three compute instances which will host the Kubernetes worker nodes:
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
sleep 30

#List the compute instances in your default compute zone:
gcloud compute instances list

#NETWORKING SETUP

#Print the internal IP address and Pod CIDR range for each worker instance:
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

#Create network routes for each worker instance:
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done

#List the routes in the kubernetes-the-hard-way VPC network:
gcloud compute routes list --filter "network: kubernetes-the-hard-way"
sleep 30

#CONFIGURE KUBECTL ADMIN ACCESS

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
--region $(gcloud config get-value compute/region) \
--format 'value(address)')

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
--client-certificate=admin.pem \
--client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
--cluster=kubernetes-the-hard-way \
--user=admin

kubectl config use-context kubernetes-the-hard-way

# Cretate Frontend Load Balancer

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

gcloud compute http-health-checks create kubernetes \
  --description "Kubernetes Health Check" \
  --host "kubernetes.default.svc.cluster.local" \
  --request-path "/healthz"

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
  --network kubernetes-the-hard-way \
  --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
  --allow tcp

gcloud compute target-pools create kubernetes-target-pool \
  --http-health-check kubernetes

gcloud compute target-pools add-instances kubernetes-target-pool \
  --instances controller-0,controller-1,controller-2

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
  --address ${KUBERNETES_PUBLIC_ADDRESS} \
  --ports 6443 \
  --region $(gcloud config get-value compute/region) \
  --target-pool kubernetes-target-pool
