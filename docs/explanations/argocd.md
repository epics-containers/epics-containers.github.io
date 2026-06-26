(argocd)=

# How ArgoCD Deploys Your IOCs

epics-containers builds IOCs and other services as Helm charts, but it does
not push them into your cluster with `helm install`. Instead the production
deployment path is *GitOps*, driven by [ArgoCD](https://argo-cd.readthedocs.io/).
This page explains the model: which Git repositories hold what, how a single
root "app-of-apps" fans out into one ArgoCD `Application` per service, and how
the `ec` command line tool fits into the picture.

:::{note}
This is the conceptual companion to the hands-on walk-through in
{any}`deploy-argocd`. If you want to follow along end to end with the `t01`
worked example, start there and refer back here for the "why".
:::

## GitOps in one picture

The central idea of GitOps is that **Git is the single source of truth for the
desired state of the cluster**, and a controller running *in* the cluster
continuously reconciles reality to match. With ArgoCD you never run an
imperative "deploy" command against the cluster. You change a file in Git, and
ArgoCD notices and makes the cluster agree.

That indirection buys you a lot:

- **The current desired state is discoverable.** One file lists exactly which
  IOC versions are supposed to be running.
- **Deploys are consistent.** The same reconciliation runs every time, so there
  is no "it worked on my machine" drift between operators.
- **You get a full history for free.** Every change is a Git commit with an
  author, a timestamp and a message.
- **Rollback is just `git revert`.** Going back to the state from any past date
  is reverting a commit; ArgoCD reconciles the cluster back to it.

ArgoCD itself is installed once into your Kubernetes cluster as part of cluster
setup (see {any}`setup-kubernetes`). Everything below assumes it is already
running and that the `argocd` CLI is logged in.

## Two repositories, two jobs

The model deliberately splits responsibilities across **two** Git repositories.
Keeping them separate is the single most important thing to understand.

The **services repository** (the worked example is the public
<https://github.com/epics-containers/t01-services>) holds the *content* of each
IOC and service: a Helm chart per service plus its `values.yaml`. This is where
service definitions are authored and version-tagged, and it is what the earlier
tutorials build up (see {any}`create-beamline` and {any}`setup-k8s-beamline`).
See the {any}`services-repo` glossary entry for the full definition.

The **deployment repository** records *which* of those services run, *where*,
and at *what version*. It is deliberately tiny. You do not clone a ready-made
one; you scaffold your own (named `t01-deployment` in the worked example) from
the public `deployment-template-argocd` template. ArgoCD watches this
repository, not the services repository.

This separation matters because the two repositories change for different
reasons and at different rates. Service definitions churn as IOCs are developed;
that activity stays in the services repository and keeps its history clean.
Deciding to roll `bl01t-ea-fastcs-01` from one tag to the next is an
*operational* decision, and it lands as a one-line change in the deployment
repository. The two histories never get tangled.

:::{note}
ArgoCD is not mandatory. If you would rather drive Helm yourself without a
GitOps controller, the {any}`helm` page covers the pure-Helm (`EC_CLI_BACKEND=K8S`)
alternative. The rest of this page describes the ArgoCD path.
:::

## The root Application (app-of-apps)

ArgoCD's unit of deployment is the `Application` custom resource (an "App"). An
App points at a Git repository, a path within it, and a target revision, and
keeps the matching Kubernetes resources in sync.

The deployment repository contains a single root App, defined in `apps.yaml` and
named for the domain (`t01` in the worked example). Its source path is the
`apps/` directory **of the deployment repository itself**:

```yaml
# apps.yaml (the root Application)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: t01                       # named for the domain
  namespace: t01-beamline
spec:
  source:
    path: apps                    # the apps/ chart in THIS (deployment) repo
    repoURL: https://github.com/your-org/t01-deployment
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

This is an *app-of-apps*: the one App you bootstrap by hand renders the `apps/`
chart, which in turn produces all the other Apps. Bootstrapping it is a single
command (`argocd app create --file apps.yaml`, or the equivalent action in your
ArgoCD web UI), and from then on the domain manages itself. A freshly scaffolded
deployment repository seeds a few shared children automatically:
`t01-epics-pvcs` (shared persistent storage), `t01-epics-opis` (auto-generated
engineering screens served over HTTP), and, if you enabled gateways,
`t01-epics-gateways`.

## The control surface: apps/values.yaml

The one file that humans and CI actually edit is `apps/values.yaml`. It is the
values file for the `apps/` chart, and it declares both the defaults shared by
every service and the per-service map of what to run:

```yaml
project: t01-beamline             # ArgoCD project (= the namespace)
destination:
  name: your-cluster              # the cluster where the IOCs RUN
  namespace: t01-beamline
source:
  repoURL: https://github.com/epics-containers/t01-services   # the SERVICES repo
  targetRevision: main            # default branch/tag of the services repo
services:
  t01-epics-pvcs:                 # a bare entry inherits all the defaults
  t01-epics-opis:
  bl01t-ea-fastcs-01:
    enabled: true
  bl01t-di-cam-01:
    targetRevision: main          # per-service version override
```

The crucial detail is that `source.repoURL` here points at the **services
repository**, not the deployment repository. The root App reads its chart
(`apps/`) from the deployment repository; the *child* Apps it generates read
their charts from the services repository. The deployment repository is the
catalogue; the services repository is the warehouse.

Each entry under `services:` is keyed by service name, and its (optional) value
is a small dictionary. The keys you will use most are:

- **`enabled`** (default `true`): set to `false` to *stop* a service without
  forgetting it. The App stays, but its workload is scaled down.
- **`removed`** (default `false`): set to `true` to omit the App entirely, so
  ArgoCD prunes it from the cluster.
- **`targetRevision`**: a per-service override of the top-level
  `source.targetRevision`, so one service can pin a different branch or tag.
- **`labels`**: labels applied to the service's Kubernetes resources (for
  example a human-readable `description`).

A bare entry with no value (such as `t01-epics-pvcs:` above) is valid and simply
inherits every default.

## How one file becomes many Applications

The expansion from "a map of services" to "many ArgoCD Apps" is done by a Helm
library chart, not by hand. `apps/Chart.yaml` declares a single dependency on
the **`argocd-apps`** chart, pulled as an **OCI dependency** from
`oci://ghcr.io/epics-containers/charts`. The one template in the deployment
repository, `apps/templates/all_apps.yaml`, just includes it:

```yaml
{{- include "ec-helm-charts.argocd-apps" . -}}
```

That library template iterates over the `services:` map and emits one child
`Application` per entry (skipping any marked `removed: true`). Each child App is
wired to track `services/<service-name>` in the services repository at the
resolved revision. So the full chain is: you edit `apps/values.yaml` → the root
App renders the `apps/` chart → `argocd-apps` expands the map → N child Apps →
each one deploys its service's chart from the services repository.

## Auto-sync: automated, prune, selfHeal

Both the root App and every child App carry the same automated/prune/selfHeal
policy (child Apps additionally set a couple of `syncOptions`):

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

All three behaviours matter:

- **automated** applies changes from Git as soon as ArgoCD sees them, with no
  manual "Sync" click.
- **prune** deletes cluster resources once they disappear from Git, so removing
  a service from `apps/values.yaml` really removes it from the cluster.
- **selfHeal** reverts *out-of-band* changes. If someone edits a live resource
  with `kubectl` directly, ArgoCD notices the drift from Git and undoes it.

The combined consequence is that **editing Git is the only action you ever need
to take**. There is no separate "now deploy it" step, and the cluster cannot
quietly drift away from what the deployment repository says.

## When does it sync? webhooks vs poll

ArgoCD discovers Git changes in two ways. By default it **polls** each
repository on a fixed interval, which is **3 minutes** (the ArgoCD default of
180 seconds). If you configure a **Git webhook** on the deployment repository,
a push triggers reconciliation immediately instead of waiting for the next poll.

If automation is ever paused, or you simply do not want to wait for the poll,
you can force a sync from the ArgoCD web UI with the **Sync** button (or the
`argocd app sync` command). Note that this is a *manual* escape hatch; the
normal flow needs none of it.

## Revision tracking: branch vs tag

Because `targetRevision` can be set globally and overridden per service, you can
mix tracking strategies in one deployment repository. Services whose content is
safe to follow continuously, such as auto-generated OPIs, can track a branch
like `main`: merge a change in the services repository and it deploys. IOCs are
usually pinned to a specific **tag** instead, so an IOC changes *only* when its
tag is deliberately bumped in `apps/values.yaml`. This is how individual IOCs
get individual version control even though every chart lives in the one shared
services repository.

## Where Apps live vs where workloads run

It is worth separating two locations that are easy to conflate. The
`Application` objects are created in the cluster that hosts ArgoCD. The
*workloads* those Apps deploy are sent wherever each App's `destination.name`
points, which can be the same cluster or a **different** one. A single ArgoCD
can therefore reconcile into many target clusters, and a site may run more than
one ArgoCD instance.

Authorization follows ArgoCD **Projects**. Apps are grouped into a Project
(named for the domain in this layout), and access is granted per namespace:
whoever can create resources in a namespace can create Apps that deploy into it.
An App is created in the same namespace as the resources it manages.

## The ec CLI's role

The {any}`edge-containers-cli` tool (`ec`) is a thin wrapper over `git`,
`kubectl`, `helm` and `argocd`. Under the ArgoCD backend, selected with
`EC_CLI_BACKEND=ARGOCD`, it is configured by three environment variables, all
set for you when you `source ./environment.sh` from your deployment repository:

- **`EC_CLI_BACKEND=ARGOCD`** selects the GitOps backend (it is also the
  default).
- **`EC_TARGET`** is `<namespace>/<root-app>`, for example `t01-beamline/t01`.
- **`EC_SERVICES_REPO`** is the services repository URL, for example
  `https://github.com/epics-containers/t01-services`.

The important thing to understand is what `ec deploy` actually does. Running:

```bash
ec deploy bl01t-ea-fastcs-01 2024.12.1
```

does **not** push anything into the cluster directly. It **records the desired
state in Git**: it commits and pushes the new `targetRevision` for
`services.bl01t-ea-fastcs-01` into `apps/values.yaml` in the deployment
repository, and then runs `argocd app get --refresh` so ArgoCD re-reads Git
immediately rather than waiting for the next poll. The actual reconciliation is
done by ArgoCD's auto-sync. In other words, **`ec deploy` does not run
`argocd app sync`** — it edits Git and lets the controller do its job. That is
exactly the GitOps model from the top of this page, with `ec` providing a
convenient front end to it.

For the step-by-step version of all of this, including scaffolding the
deployment repository, bootstrapping the root App and watching the sync in the
web UI, see {any}`deploy-argocd`. For the contrasting local, non-Kubernetes
workflow that the introductory tutorials use, see {any}`deploy-example-instance`.
