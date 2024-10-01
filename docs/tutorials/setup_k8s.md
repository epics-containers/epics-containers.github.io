(setup-kubernetes)=

# Setup a Kubernetes Cluster

:::{Note}
**DLS Users**: DLS already has the test cluster `Pollux` which includes the test beamlines p45j, p38 and p99,  and the training beamlines p46 through to p49.

We are in the process of rolling out clusters for our production beamlines. To date (Aug 2024) we have clusters for: b01-1, b21, i03, i04, i13-1, i15-1, i18, i20-1, i22.

For this reason DLS users should skip this tutorial unless you have a spare linux machine with root access and an interest in how Clusters are created.
:::

## Introduction

This is a very easy set of instructions for setting up an experimental single-node Kubernetes cluster, ready for a test deployment of EPICS IOCs.

## Bring Your Own Cluster

If you already have a Kubernetes cluster then you can skip this section.
and go straight to the next tutorial.

IMPORTANT: you will require appropriate permissions on the cluster to work with epics-containers. In particular you will need to be able to create pods that run with network=host. This is to allow Channel Access traffic to be routed to and from the IOCs. You will also need to be able to create a namespace and a service account, although you could use an existing namespace and service account as long as it has network=host capability. The alternative to running with network=host is to run a ca-gateway in the cluster and expose the PVs to the IOCs via the gateway.

Cloud based K8S offerings may not be appropriate because of the Channel Access
routing requirement.

## Platform Choice

These instructions have been tested on Ubuntu 22.04; however, any modern Linux distribution that is supported by k3s and running on a modern x86 machine should also work.

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

Note that by default, the kubectl that comes with k3s reads its config from /etc/rancher/k3s/k3s.yaml and would therefore be run with sudo. By using $KUBECONFIG we conform to the standard version that reads its config from $HOME/.kube/config.

```
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
source $HOME/.bashrc
```
(replace `$HOME/.bashrc` with `$HOME/.zshrc` for zsh user)

Then log out and back in for this to be set for all shells.

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

If you do have separate workstation then edit the file .kube/config replacing 127.0.0.1 with your server's IP Address. For a single machine the file is left as is.

### Install helm

Helm is a package manager for Kubernetes. It is used to install and manage software on Kubernetes clusters.

See https://helm.sh/docs/intro/install/.

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

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

### Install persistent volume support

As per <https://docs.k3s.io/storage/>, the "Longhorn" distributed block storage system can be set up in our cluster. This is done in order to get support for ReadWriteMany persistent volume claims, which is not supported by the out of the box "Local Path Provisioner".

```bash
# Install dependancies
sudo apt-get update; sudo apt-get install -y open-iscsi nfs-common jq

# Set up longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/longhorn.yaml

# Monitor while Longhorn starts up
kubectl get pods --namespace longhorn-system --watch

# Confirm ready
kubectl get storageclass
```

### Set up k8s dashboard (Optional)

The Kubernetes dashboard is a web-based Kubernetes user interface.
As per <https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/> it can be installed into the cluster as follows:

```
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

To access the gui through a browser on `https://localhost:8080/`:
```
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8080:443
```

To generate a bearer token in order to log in - first create a Service Account:
```
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

Then bind the Service Account to a role with suitable permissions:
```
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

Finally generate a short duration token that can be used to log in:
```
kubectl -n kubernetes-dashboard create token admin-user
```


### Set up Argo CD

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. As per <https://argo-cd.readthedocs.io/en/stable/> it can be installed into the cluster as follows:

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

To access the gui through a browser on `https://localhost:8081/`:
```
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

The user is `admin` and the password can be retrived using:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode ; echo
```

To install the `argocd` cli tool:
```
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Create a new argocd project from the command line, with permissions to deploy into your namespace:
```
argocd login localhost:8081
argocd proj create t03 -d https://kubernetes.default.svc,t03-beamline -d https://kubernetes.default.svc,argocd -s "*"
```

When deploying to the same cluster that Argo CD is running in the destination cluster is by default aliased as "in-cluster".
Argocd Apps should be deployed into the argocd namespace.

### Set up kube-prometheus-stack (Optional)

Prometheus + Grafana + Alertmanager is a common stack used for cluster monitoring. The "kube-prometheus-stack" Helm chart already has Prometheus configured to scrape the cluster and Grafana comes with some prebuilt dashboards to visualize the data.

As per <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack> it can be installed into the cluster as follows:
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --create-namespace --namespace monitoring --set kube-state-metrics.extraArgs="{--metric-labels-allowlist=pods=[*]}"
```

To access the Grafana gui through a browser on `https://localhost:3000/`:
```
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```
The user is `admin` and the password is `prom-operator`


### Completed

That's it. You now have installed the necessary software to start experimenting with IOCs on Kubernetes.

To remove everything you have installed above and clean up the disk space
simply use this command:

```bash
k3s-uninstall.sh
```

If you are interested in looking at the k3s files see **/var/lib/rancher/k3s/**.
