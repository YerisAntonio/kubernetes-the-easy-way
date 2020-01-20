#! /bin/bash

# Deploy CodeDNS DNS Plugin

kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

kubectl get pods -l k8s-app=kube-dns -n kube-system

# Verification

kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600

kubectl get pods -l run=busybox

POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

kubectl exec -ti $POD_NAME -- nslookup kubernetes

#Server:    10.32.0.10
#Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

#Name:      kubernetes
#Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
