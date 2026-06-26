(setup-kubernetes)=

# Set up a Kubernetes Cluster

:::{important}
**DLS users:** stop here. Diamond runs managed clusters for its beamlines and
the accelerator, and all cluster work is covered by the internal developer
guide at <https://dev-guide.diamond.ac.uk/epics-containers/>. These public
cluster tutorials target self-hosted, non-DLS clusters. Continue only if you
have a spare Linux machine and want to build your own test cluster.
:::

This tutorial stands up an experimental single-node Kubernetes cluster with
[k3s](https://k3s.io/), ready for a test deployment of EPICS IOCs. It also
installs the client tools (`kubectl` and `helm`) you will use in the
later cluster tutorials. K3S ships a clean uninstaller, so there is no harm in
trying it out — see [Clean up](#clean-up).

## Bring your own cluster

If you already have a Kubernetes cluster, skip to the [namespace
step](#create-a-namespace). You will need permissions to:

- create pods that run with `hostNetwork: true` — epics-containers routes
  Channel Access traffic directly to and from the IOCs, so the IOC pods share
  the host network;
- create a namespace (or use an existing one that allows host networking).

:::{note}
The alternative to host networking is to run a CA gateway in the cluster and
expose PVs to the IOCs through it. Cloud-hosted Kubernetes may not suit
epics-containers because of the Channel Access routing requirement.
:::

These instructions were tested on Ubuntu 22.04, but any modern x86 Linux that
k3s supports should work. If you prefer a different lightweight implementation,
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/),
[microk8s](https://microk8s.io/) and
[minikube](https://minikube.sigs.k8s.io/docs/start/) install just as easily.

## Install k3s

Run this on the machine that will host the cluster (the k3s server node):

```bash
curl -sfL https://get.k3s.io | sh -
```

(install-kubectl)=

## Install kubectl

`kubectl` is the command line tool for talking to a cluster. K3S bundles its
own copy that reads `/etc/rancher/k3s/k3s.yaml` and must be run with `sudo`. To
use the standard `kubectl` that reads `$HOME/.kube/config`, set `KUBECONFIG`:

```bash
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
source $HOME/.bashrc
```

(Use `$HOME/.zshrc` for zsh.) Log out and back in so all shells pick it up.

Now copy the k3s config into place. On a **single machine**:

```bash
mkdir ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
```

If your workstation is **separate** from the server, copy it across instead and
replace `127.0.0.1` in `~/.kube/config` with the server's IP address:

```bash
mkdir ~/.kube
scp <YOUR_ACCOUNT>@<YOUR_SERVER>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```

## Install helm

Helm is the Kubernetes package manager (see
<https://helm.sh/docs/intro/install/>):

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## Test your installation

```bash
kubectl get nodes
```

This should list your single node, ready:

```text
NAME    STATUS   ROLES                  AGE   VERSION
ecws1   Ready    control-plane,master   25m   v1.30.4+k3s1
```

(create-a-namespace)=

## Create a namespace

epics-containers uses one Kubernetes namespace per beamline or accelerator
domain, to isolate each domain's resources. A *context* binds a cluster,
namespace and user so `kubectl` knows where to send commands.

Create a namespace and context for the test beamline `t02-beamline` (substitute
your own name):

```bash
kubectl create namespace t02-beamline
kubectl config set-context t02-beamline --namespace=t02-beamline --user=default --cluster=default
kubectl config use-context t02-beamline
```

## Install persistent volume support

The shared services that IOCs expect (for example `t02-epics-pvcs`) use
`ReadWriteMany` persistent volume claims, which k3s' default Local Path
Provisioner does not support. Per <https://docs.k3s.io/storage/>, install the
Longhorn distributed block storage system to provide them:

```bash
# Longhorn prerequisites
sudo apt-get update; sudo apt-get install -y open-iscsi nfs-common jq

# Install Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/longhorn.yaml

# Watch it start up
kubectl get pods --namespace longhorn-system --watch

# Confirm the storage class is ready
kubectl get storageclass
```

(k8s-dashboard)=

## Set up the Kubernetes dashboard (optional)

The [Kubernetes dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
is a web UI for the cluster. Install it with Helm:

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace --namespace kubernetes-dashboard
```

Reach it in a browser at `https://localhost:8080/` by port-forwarding:

```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8080:443
```

To log in you need a bearer token. Follow the upstream dashboard
[Creating a sample user](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)
guide to create an `admin-user` service account bound to `cluster-admin`, then
mint a short-lived token:

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

(clean-up)=

## Clean up

To remove everything installed above and reclaim the disk space:

```bash
k3s-uninstall.sh
```

You now have the tools to start experimenting with IOCs on Kubernetes. Continue
with {any}`setup-k8s-beamline` to create a beamline that deploys onto this
cluster.
