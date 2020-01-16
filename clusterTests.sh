#! /bin/bash

#Data encryption test
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"

gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"

#The etcd key should be prefixed with k8s:enc:aescbc:v1:key1, which indicates 
#the aescbc provider was used to encrypt the data with the key1 encryption key.

#Deployments test
kubectl create deployment nginx --image=nginx
kubectl get pods -l app=nginx

#PortForwarding test
#In this section you will verify the ability to access applications remotely using 
#port forwarding.

POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

#Forward port 8080 on your local machine to port 80 of the nginx pod:
#kubectl port-forward $POD_NAME 8080:80

#Forwarding from 127.0.0.1:8080 -> 80
#Forwarding from [::1]:8080 -> 80

#In a new terminal make an HTTP request using the forwarding address:

#curl --head http://127.0.0.1:8080

#HTTP/1.1 200 OK
#Server: nginx/1.17.3
#Date: Sat, 14 Sep 2019 21:10:11 GMT
#Content-Type: text/html
#Content-Length: 612
#Last-Modified: Tue, 13 Aug 2019 08:50:00 GMT
#Connection: keep-alive
#ETag: "5d5279b8-264"
#Accept-Ranges: bytes

#Testing Logs

kubectl logs $POD_NAME

#Testing Exec

kubectl exec -ti $POD_NAME -- nginx -v

#Testing services

kubectl expose deployment nginx --port 80 --type NodePort

NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes-the-hard-way

EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

curl -I http://${EXTERNAL_IP}:${NODE_PORT}

#HTTP/1.1 200 OK
#Server: nginx/1.17.3
#Date: Sat, 14 Sep 2019 21:12:35 GMT
#Content-Type: text/html
#Content-Length: 612
#Last-Modified: Tue, 13 Aug 2019 08:50:00 GMT
#Connection: keep-alive
#ETag: "5d5279b8-264"
#Accept-Ranges: bytes