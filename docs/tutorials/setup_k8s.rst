.. _setup_kubernetes:

Setup a Kubernetes Server
=========================

Introduction
------------
This is a very easy set of instructions for setting up an experimental
Kubernetes 'cluster' containing a single server and
ready to deploy EPICS IOCs.

It has been tested on the following:

========================== ============================================
Ubuntu 20.10               any modern linux distro should also work
Raspberry Pi OS 2021-05-07 See `raspberry`
Windows WSL2               See `wsl`
========================== ============================================

Give it a try, K3S provides a good uninstaller that will clean up your system
if you decide to back out.

If you prefer to investigate other implementations there are also:

  - kind https://kind.sigs.k8s.io/docs/user/quick-start/
  - microk8s https://microk8s.io/
  - minikube https://minikube.sigs.k8s.io/docs/start/

For k3s documentation see https://k3s.io/.

Installation Steps
------------------

These instructions work with a single machine or with a server running k3s
and a workstation running the kubectl client CLI. If you only have a single
machine then server==workstation for all instructions.


Install K3S lightweight Kubernetes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Execute this command on your server to set up the cluster master
(aka K3S Server node)::

    curl -sfL https://get.k3s.io | sh -

.. _install_kubectl:

Install kubectl
~~~~~~~~~~~~~~~

Kubectl is the command line tool for interacting with your cluster.

On the workstation install the binary::

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    source <(kubectl completion bash)

The last step adds command line completion and is worth adding to your profile.

If you have one machine only then copy the k3s kubectl configuration::

    mkdir ~/.kube
    sudo cp  /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown <YOUR USER> ~/.kube/config

If you have a separate server then from the server machine copy over the k3s kubectl configuration::

    mkdir ~/.kube
    sudo scp  /etc/rancher/k3s/k3s.yaml <YOUR_ACCOUNT>@<YOUR_WORKSTATION>:.kube/config

If you do have separate workstation then edit the file .kube/config replacing
127.0.0.1 with your server's IP Address. For a single machine the file is left
as is.


Create an epics IOCs namespace and context
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

From the workstation execute the following::

    kubectl create namespace epics-iocs
    kubectl config set-context epics-iocs --namespace=epics-iocs --user=default --cluster=default
    kubectl config use-context epics-iocs

Create a service account to run the IOCs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create the account::

    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
        name: epics-iocs-priv
    EOF

Generate a login token for the account::

    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    metadata:
        name: epics-iocs-priv-secret
        annotations:
            kubernetes.io/service-account.name: epics-iocs-priv
    type: kubernetes.io/service-account-token
    EOF

.. _setup_helm:

Install helm
~~~~~~~~~~~~

Execute this on the workstation::

    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    bash get_helm.sh


Completed
~~~~~~~~~
That's it. You now have installed the necessary software to start experimenting
with IOCs on Kubernetes.

To remove everything you have installed above and clean up the disk space
simply use this command::

    k3s-uninstall.sh

If you are interested in looking at the k3s files see **/var/lib/rancher/k3s/**.
