(setup-argocd)=

# Set up Argo CD

:::{note}
**DLS users:** Diamond runs a managed ArgoCD (Argus) — do not install your own.
See the internal [developer guide](https://dev-guide.diamond.ac.uk/epics-containers/).
This page targets self-hosted, non-DLS clusters only.
:::

[Argo CD](https://argo-cd.readthedocs.io/en/stable/) is the GitOps continuous
delivery tool used by the {any}`deploy-argocd` tutorial. Earlier cluster
tutorials deploy with plain Helm; ArgoCD adds the GitOps layer on top. This
short page installs ArgoCD into the cluster from {any}`setup-kubernetes`,
reaches its web UI, retrieves the admin password and installs the `argocd` CLI.

## Install the Argo CD server

Install ArgoCD into its own `argocd` namespace, using the upstream `stable`
install manifest:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for the pods to come up:

```bash
kubectl -n argocd get pods --watch
```

## Reach the web UI

The ArgoCD server is not exposed outside the cluster by default. Port-forward it
to your workstation, then open `https://localhost:8081/` in a browser (accept the
self-signed certificate):

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

## Retrieve the admin password

The web UI and the CLI both log in as `admin`. The initial password is stored in
a Kubernetes secret — print it with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode ; echo
```

## Install the argocd CLI

Finally install the `argocd` command-line client (used by `ec` and by
{any}`deploy-argocd`):

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

With the port-forward running, log in to check everything works:

```bash
argocd login localhost:8081
```

## Next steps

ArgoCD is now installed and reachable. Continue with {any}`deploy-argocd` to put
a services repo under GitOps control.
