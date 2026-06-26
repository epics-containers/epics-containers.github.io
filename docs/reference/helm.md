(helm)=
# Deploying with Helm (the `ec` backends)

`ec` (the [edge-containers-cli](https://epics-containers.github.io/edge-containers-cli/))
is a thin wrapper around the tools that actually deploy and manage your
services — `git`, `kubectl`, `helm` and `argocd`. The tool it drives is
selected by a **backend**, set with the `EC_CLI_BACKEND` environment variable
(or the `ec -b/--backend` option). There are three backends:

| Backend  | `EC_CLI_BACKEND` | Deploys via | Typical use |
|----------|------------------|-------------|-------------|
| ArgoCD   | `ARGOCD` (default) | A deployment repository reconciled by ArgoCD | Production continuous deployment |
| Kubernetes | `K8S`           | `helm` directly against a cluster | Pure-Helm clusters with no ArgoCD |
| Demo     | `DEMO`           | An in-memory simulation | Trying out `ec` / running the tutorials offline |

The available commands and options change per backend: when a command is not
implemented for the selected backend it is dropped from `ec --help` entirely.
So the output of `ec --help` reflects whichever backend is currently active.

```bash
export EC_CLI_BACKEND=K8S
ec --help        # shows only the commands the K8S backend implements
```

For the authoritative, per-command reference, see the
[edge-containers-cli documentation](https://epics-containers.github.io/edge-containers-cli/).

## ARGOCD (default)

This is the recommended path for production continuous deployment. The services
repository describes IOC instances as Helm charts, but `ec` does not deploy
them directly. Instead a companion **deployment repository** records which
version of each service should be running, and
[ArgoCD](https://argo-cd.readthedocs.io/) — a Kubernetes-native tool that keeps
a set of Helm charts in a git repository in sync with the cluster —
continuously reconciles the cluster to match it. For the full picture of how
this works, see {any}`argocd`.

With this backend `ec deploy <service> <version>` works by committing the
chosen version into the deployment repository; ArgoCD then rolls it out. Here
`EC_TARGET` is `app-namespace/root-app` (the namespace hosting ArgoCD plus the
name of the root app-of-apps Application).

:::{note}
DLS users: this is the deployment model in production across the facility. See
the [DLS dev-guide](https://dev-guide.diamond.ac.uk/epics-containers/) for the
site-specific accelerator and conventions.
:::

## K8S

You are not required to use ArgoCD; the `K8S` backend uses Helm directly. `ec`
adds version-management features on top of Helm that to some extent replicate
ArgoCD's ability to track versions, but without the git-driven audit trail.

With this backend `EC_TARGET` is simply the Kubernetes **namespace** to deploy
into. `ec deploy <service> [version]` shallow-clones `EC_SERVICES_REPO` at the
requested git tag and runs `helm upgrade --install` on the service's chart;
`ec template` and `ec deploy-local` operate on a local chart instead. Lifecycle
commands map onto cluster operations — start/stop scale the StatefulSet,
`ec delete` runs `helm delete`, and `ec logs`/`ec exec`/`ec attach` use
`kubectl`.

## DEMO

The `DEMO` backend simulates a cluster in memory so you can explore the `ec`
command set without any infrastructure. It is used by the introductory
tutorials and for experimenting offline.
