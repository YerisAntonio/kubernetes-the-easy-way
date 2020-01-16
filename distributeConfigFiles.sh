#! /bin/bash

#Copy the appropriate kubelet and kube-proxy kubeconfig files to each worker instance:

for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done

#Copy the appropriate kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done