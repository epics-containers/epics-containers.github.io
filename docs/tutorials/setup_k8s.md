(setup-kubernetes)=

# Setup a Kubernetes Cluster

:::{Note}
**DLS Users**: DLS already has the test cluster `Pollux` which includes the test beamlines p45j, p38 and p99,  and the training beamlines p46 through to p49.

We are in the process of rolling out clusters for our production beamlines. To date (Aug 2024) we have clusters for: b01-1, b21, i03, i04, i13-1, i15-1, i18, i20-1, i22.

For this reason DLS users should skip this tutorial unless you have a spare linux machine with root access and an interest in how Clusters are created.
:::

## Introduction

This is a very easy set of instructions for setting up an experimental
single-node Kubernetes cluster, ready to test deployment of EPICS IOCs.

## Bring Your Own Cluster

If you already have a Kubernetes cluster then you can skip this section.
and go straight to the next tutorial.

IMPORTANT: you will require appropriate permissions on the cluster to work
with epics-containers. In particular you will need to be able to create
pods that run with network=host. This is to allow Channel Access traffic
to be routed to and from the IOCs. You will also need to be able to create
a namespace and a service account, although you could use an existing
namespace and service account as long as it has network=host capability.

Cloud based K8S offerings may not be appropriate because of the Channel Access
routing requirement.

## Platform Choice

These instructions have been tested on the following platforms. The simplest
option is to use a linux distribution that is supported by k3s.

```{eval-rst}
========================== ============================================
Ubuntu 22.04 and newer     any modern linux distro should also work
Raspberry Pi OS 2021-05-07 See `raspberry`
========================== ============================================
```

Note that K3S provides a good uninstaller that will clean up your system if you decide to back out. So there is no harm in trying it out.

If you prefer to investigate other implementations there are also these easy to install, lightweight Kubernetes implementations:

> - kind <https://kind.sigs.k8s.io/docs/user/quick-start/>
> - microk8s <https://microk8s.io/>
> - minikube <https://minikube.sigs.k8s.io/docs/start/>

For k3s documentation see <https://k3s.io/>.

## Installation Steps

These instructions work with a single machine or with a server running k3s and a workstation running the client CLI.

### Install K3S lightweight Kubernetes

Execute this command on your server to set up the cluster master (aka K3S Server node):

```
curl -sfL https://get.k3s.io | sh -
```

(install-kubectl)=

### Install kubectl

Kubectl is the command line tool for interacting with Kubernetes Clusters.

See https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ for the latest instructions.

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo mv kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl
```

Note that this is overwritting the kubectl that comes with k3s. That is a special version that reads its config from /etc/rancher/k3s/k3s.yaml and must therefore be run with sudo. The version we are installing here is the standard version that reads its config from $HOME/.kube/config.

```bash
### Configure kubectl

 kubectl uses a default configuration file  **$HOME/.kube/config** to connect to the cluster. Here we will copy the configuration file from the server to the workstation.

If you have one machine only then copy the k3s kubectl configuration into your home directory:

```bash
mkdir ~/.kube
sudo cp  /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown <YOUR USER> ~/.kube/config
```

If you have a separate server then from the server machine copy over the k3s kubectl configuration:

```bash
mkdir ~/.kube
sudo scp  /etc/rancher/k3s/k3s.yaml <YOUR_ACCOUNT>@<YOUR_WORKSTATION>:.kube/config
```

If you do have separate workstation then edit the file .kube/config replacing 127.0.0.1 with your server's IP Address. For a single machine the file is leftas is.

### Test your installation

```bash
kubectl get nodes
```

This should return the name of your single worker node (i.e. your server or workstation name) e.g.:

```bash
$ kubectl get node
NAME    STATUS   ROLES                  AGE   VERSION
ecws1   Ready    control-plane,master   25m   v1.30.4+k3s1
(venv)
```

### Create an epics IOCs namespace and context

For each beamline or EPICS domain there will be a kubernetes namespace. Namespaces allow
us to isolate sets of cluster resources from each other, epics-containers uses a namespace for each beamline or accelerator domain.

A context is a combination of a cluster, namespace, and user. It tells kubectl which cluster and namespace to use when communicating with the Kubernetes API.

Here we will create a namespace for our test beamline t03-beamline.

From the workstation INSIDE the devcontainer execute the following:

```bash
kubectl create namespace t03-beamline
kubectl config set-context t03-beamline --namespace=t03-beamline --user=default --cluster=default
kubectl config use-context t03-beamline
```

### Create a service account to run the IOCs

Inside of our new namespace we will create a service account that will be used to run the IOCs. Kubernetes uses a declarative model where you define the desired state of the system and Kubernetes will make it so. Here we will create a service account and a secret that will be used to authenticate the service account. In both cases these are defined directly using command line YAML which kubectl passes to the Kubernetes API.

Create the account:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
    name: bl03t-priv
EOF
```

Generate a login token for the account:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
    name: bl03t-priv-secret
    annotations:
        kubernetes.io/service-account.name: bl03t-priv
type: kubernetes.io/service-account-token
EOF
```

### Completed

That's it. You now have installed the necessary software to start experimenting with IOCs on Kubernetes.

To remove everything you have installed above and clean up the disk space
simply use this command:

```bash
k3s-uninstall.sh
```

If you are interested in looking at the k3s files see **/var/lib/rancher/k3s/**.
