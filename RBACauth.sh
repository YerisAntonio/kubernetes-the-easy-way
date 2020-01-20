#! /bin/bash

#In this section you will configure RBAC permissions to allow the Kubernetes API Server 
#to access the Kubelet API on each worker node. Access to the Kubelet API is required for 
#retrieving metrics, logs, and executing commands in pods.

#This tutorial sets the Kubelet --authorization-mode flag to Webhook. Webhook mode uses 
#the SubjectAccessReview API to determine authorization.

#The commands in this section will effect the entire cluster and only need to be run once 
#from one of the controller nodes.

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

#The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the 
#client certificate as defined by the --kubelet-client-certificate flag.

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF



# {
#  "major": "1",
#  "minor": "15",
#  "gitVersion": "v1.15.3",
#  "gitCommit": "2d3c76f9091b6bec110a5e63777c332469e0cba2",
#  "gitTreeState": "clean",
#  "buildDate": "2019-08-19T11:05:50Z",
#  "goVersion": "go1.12.9",
#  "compiler": "gc",
#  "platform": "linux/amd64"
# }

