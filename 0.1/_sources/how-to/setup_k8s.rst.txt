Set up a lightwieght Kubernetes Cluster for experimentation
===========================================================

# Intro
This is a very easy set of instructions for setting up a Kubernetes cluster
ready to deploy epics IOCs.

It has been tested on Ubuntu 20.10 and Raspbian Buster.

Give it a try, K3S provides a good uninstaller that will clean up your system
if you decide to back out.

If you prefer to investigate other implementations there are also:

  - kind https://kind.sigs.k8s.io/docs/user/quick-start/
  - microk8s https://microk8s.io/
  - minikube https://minikube.sigs.k8s.io/docs/start/

# Installation Steps

## Install K3S lightweight Kubernetes
Execute this command on your server to set up the cluster master (aka K3S Server node):
```
curl -sfL https://get.k3s.io | sh -
```

Install kubectl on the workstation from which you will be managing the cluster
(workstation==server if you have one machine only)
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
Go to the server machine and copy over the kubectl configuration to your
workstation
```
sudo scp  /etc/rancher/k3s/k3s.yaml <YOUR_ACCOUNT>@<YOUR_WORKSTATION>:.kube/config
# edit the file .kube/config replacing 127.0.0.1 with your server IP Address
```

## Create an epics IOCs namespace and context
From the workstation execute the following:
```
kubectl create namespace epics-iocs
kubectl config set-context epics-iocs --namespace=epics-iocs --user=default --cluster=default
kubectl config use-context epics-iocs
```

## Install helm
Execute this on the workstation:
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
bash get_helm.sh
```
