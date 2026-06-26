(deploy-argocd)=

# Deploy IOCs with ArgoCD

This tutorial walks you through the production *continuous deployment* (CD)
path for epics-containers: you create a **deployment repository** from a
template, bootstrap a single ArgoCD *root Application*, and then deploy an IOC
with one `ec deploy` command. From that point on, ArgoCD keeps your cluster in
sync with what is recorded in git.

:::{note}
**DLS users:** this page deploys to a Kubernetes cluster. Stop here and switch
to the internal
[developer guide](https://dev-guide.diamond.ac.uk/epics-containers/) for the DLS
cluster, Argus ArgoCD and webhooks.
:::

By the end you will have:

- a deployment repo (`t01-deployment`) generated from
  [`deployment-template-argocd`](https://github.com/epics-containers/deployment-template-argocd);
- a root ArgoCD Application (`t01`) that owns a set of child Applications;
- the IOC `bl01t-ea-fastcs-01` running on your cluster, with its desired
  version recorded in git.

The worked example uses the domain **`t01`** (beamline **`bl01t`**), the
namespace **`t01-beamline`**, and the public services repository
[`t01-services`](https://github.com/epics-containers/t01-services). Substitute
your own names throughout.

:::{note}
This is the GitOps deployment model. To understand *how* it works (the
two-repository split, app-of-apps, auto-sync) before running anything, read
{any}`../explanations/argocd` first.
:::

## Prerequisites

This tutorial assumes the pieces below are already in place; it does **not**
repeat the installation steps.

1. **A Kubernetes cluster with ArgoCD installed**, plus the `argocd` CLI
   installed and logged in. The {any}`setup-kubernetes` tutorial covers all of
   this and shows how to reach the ArgoCD web UI (for a self-hosted install,
   typically by port-forwarding it to `https://localhost:8081/`). Do that first.

2. **A workstation with `ec`, `copier`, `git` and `kubectl`** — see
   {any}`setup_workstation`. `ec` must already be installed; the generated
   `environment.sh` only *checks* that it is present, it does not install it.

3. **A services repository to deploy from**, holding the Helm charts and
   per-service `values.yaml` files that *define* each IOC (see
   {any}`services-repo`). This tutorial uses the public
   [`t01-services`](https://github.com/epics-containers/t01-services), so you do
   not need to create one. To build your own, see {any}`setup-k8s-beamline` and
   {any}`create-beamline`.

4. **A namespace and a matching ArgoCD project for your domain.** ArgoCD
   Applications are authorised per-namespace and per-project. Create the
   namespace your IOCs will run in, and an ArgoCD project allowed to deploy into
   it:

   ```bash
   kubectl create namespace t01-beamline
   argocd proj create t01-beamline \
     -d https://kubernetes.default.svc,t01-beamline \
     -s "*"
   ```

   :::{note}
   The template sets each Application's `project:` field to your *namespace
   name* (the `cluster_namespace` you give `copier` below), so the ArgoCD
   project is named **`t01-beamline`** to match. `-d` whitelists the destination
   `cluster,namespace`; `-s "*"` permits any source repo. Adjust the cluster
   URL/name if your IOCs run on a different cluster from the one hosting ArgoCD.
   :::

## Scaffold a deployment repo

Generate the deployment repo from the public
[`deployment-template-argocd`](https://github.com/epics-containers/deployment-template-argocd)
template with `copier` (use `uvx copier ...` if `copier` is not installed):

```bash
copier copy https://github.com/epics-containers/deployment-template-argocd t01-deployment
```

`copier` asks a series of questions (defined in the template's `copier.yml`).
Answer them as follows for the worked example:

| Prompt | Meaning | Worked-example answer |
|---|---|---|
| `domain` | Short name for this collection of IOCs/services. Becomes the **root Application name**. | `t01` |
| `description` | One-line repo description. | *(accept default)* |
| `argocd_server` | DNS name of your ArgoCD server, used by `argocd login`. | your ArgoCD server, e.g. `localhost:8081` |
| `argocd_cluster` | The cluster where ArgoCD **creates the Application objects**. | `in-cluster` *(single-cluster install)* |
| `cluster_name` | The cluster where the **IOCs run** (child `destination.name`). | `in-cluster` *(same cluster)* |
| `cluster_namespace` | The namespace where IOCs run, **and** the ArgoCD project. | `t01-beamline` |
| `git_platform` | Where this repo will be hosted. | `github.com` |
| `github_org` | The GitHub account/org that will own the repo. | *your GitHub account or org* |
| `deployment_repo` | URL of **this** deployment repo. | *(accept default — `https://github.com/<org>/t01-deployment`)* |
| `services_repo` | URL of the **services** repo to track. | `https://github.com/epics-containers/t01-services` |
| `services_release` | Initial branch or tag of the services repo to track. | `main` |
| `logging_url` | Central log server URL (optional). | `Skip` |

:::{warning}
The template defaults are placeholders and **will not work unchanged**. The two
URLs that matter most are `deployment_repo` (the repo you are about to push) and
`services_repo` (here `https://github.com/epics-containers/t01-services`). Set
both correctly.
:::

Now create the git repository, commit the generated files, and push to the
remote you named in `deployment_repo`:

```bash
git -C t01-deployment init
git -C t01-deployment add .
git -C t01-deployment commit -m "Initial deployment repo from template"
git -C t01-deployment branch -M main
git -C t01-deployment remote add origin https://github.com/<org>/t01-deployment
git -C t01-deployment push -u origin main
```

:::{important}
ArgoCD must be able to **read** this repo. The simplest option is a public repo.
If you use a private repo, register the credentials with ArgoCD first —
otherwise the root Application reports
`ComparisonError: authentication required`.
:::

## Tour the generated repo

The deployment repo is deliberately tiny — it records only *which* services run
and *at what version*; the service content lives in the services repo.

| Path | Role |
|---|---|
| `apps.yaml` | The ArgoCD **root Application** ("app of apps"). `source.path: apps` points at the `apps/` chart in this repo; `syncPolicy` is `automated` with `prune` and `selfHeal`. You bootstrap this once. |
| `apps/values.yaml` | The **control surface** — the only file you (or CI) normally edit. Declares the project, destination, the **services-repo** source, and the `services:` map. |
| `apps/Chart.yaml` | A Helm chart whose only dependency is the `argocd-apps` library chart, pulled as an **OCI** artifact from `oci://ghcr.io/epics-containers/charts`. |
| `apps/templates/all_apps.yaml` | A one-line template that expands the `services:` map into one child Application per service. |
| `environment.sh` | Sourced to set the `EC_*` environment variables, enable `ec` shell completion, and log into ArgoCD. |

The root `apps.yaml` (genericized):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: t01
  namespace: t01-beamline
  finalizers:
    - resources-finalizer.argocd.argoproj.io/background
    - resources-finalizer.argocd.argoproj.io/foreground
spec:
  project: t01-beamline
  destination:
    name: in-cluster
    namespace: t01-beamline
  source:
    path: apps
    repoURL: https://github.com/<org>/t01-deployment   # THIS (deployment) repo
    targetRevision: main
    helm:
      version: v3
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

And `apps/values.yaml` — the control surface:

```yaml
project: t01-beamline
destination:
  name: in-cluster
  namespace: t01-beamline
source:
  repoURL: https://github.com/epics-containers/t01-services   # the SERVICES repo
  targetRevision: main

services:
  t01-epics-pvcs:
  t01-epics-opis:
  t01-epics-gateways:
```

:::{note}
`source.repoURL` here points at the **services** repo, not this one: every
*child* Application sources its Helm chart from `services/<service>` in the
services repo. The template seeds three children — `t01-epics-pvcs` (shared
storage), `t01-epics-opis` (auto-generated OPIs) and `t01-epics-gateways` (a
Channel Access gateway). A bare entry like `t01-epics-pvcs:` inherits all the
defaults above.
:::

For the full model behind these files — the two-repository split, the
`argocd-apps` library chart, and how one map becomes many Applications — see
{any}`../explanations/argocd`.

(configure-your-environment)=

## Configure your environment

Source the generated `environment.sh` from the directory that contains the
deployment repo:

```bash
source ./t01-deployment/environment.sh
```

This sets the `EC_*` environment variables, enables `ec` shell completion, and
logs you into ArgoCD. The variables it exports are:

```bash
export EC_CLI_BACKEND="ARGOCD"            # the ArgoCD continuous-deployment backend
export EC_TARGET=t01-beamline/t01         # <namespace>/<root-app-name>
export EC_SERVICES_REPO=https://github.com/epics-containers/t01-services
export EC_LOG_URL=''                      # central log server (empty — logging_url Skipped)
```

`EC_SERVICES_REPO` is the repo that `ec deploy` validates versions against; for
the full `EC_*` reference see {any}`edge-containers-cli`.

:::{note}
**Site setup varies.** The template's `environment.sh` ends with a generic
`argocd login <server> --grpc-web --sso`. Adapt it to your own server and auth
method. For a self-hosted install reached via port-forward, that is typically
`argocd login localhost:8081`, logging in as `admin` with the password from your
ArgoCD install (see {any}`setup-kubernetes`).
:::

Check that the CLI is configured. Until you bootstrap the root Application (next
section) the target does not exist, so `ec ps` reports
`Target 't01-beamline/t01' not found`:

```bash
ec ps
```

That error is expected here; it confirms `ec` is talking to ArgoCD with the
right target. Once the root Application exists, the same command lists your
services.

## Bootstrap the root Application

This is the single manual step. From the directory that contains the deployment
repo, create the root Application from `apps.yaml`:

```bash
argocd app create --file t01-deployment/apps.yaml
```

ArgoCD creates the root Application `t01`, which in turn creates one child
Application per entry in `apps/values.yaml`. Within a moment you should see the
root plus its three seeded children:

```bash
argocd app list --app-namespace t01-beamline
```

```text
NAME                              SYNC STATUS   HEALTH
t01-beamline/t01                  Synced        Healthy
t01-beamline/t01-epics-pvcs       Synced        Healthy
t01-beamline/t01-epics-opis       Synced        Healthy
t01-beamline/t01-epics-gateways   Synced        Healthy
```

:::{note}
`kubectl apply -f apps.yaml` is the equivalent Kubernetes-native form (`apps.yaml`
is a valid `Application` resource). It works, but relies on your direct cluster
RBAC rather than ArgoCD's project authorisation — prefer the `argocd` CLI form
above.
:::

## Watch it sync in the ArgoCD web UI

Open your ArgoCD web UI (for a port-forwarded install, `https://localhost:8081/`)
and filter the Applications view by project `t01-beamline`. You will see a card
for the root `t01` and one per child; as ArgoCD reconciles, the cards turn green
(`Synced` / `Healthy`). Click a card to drill into the individual Kubernetes
resources (StatefulSets, Services, ConfigMaps) it manages — the quickest way to
diagnose a service that will not start.

## Deploy a service

Now deploy an IOC. The service `bl01t-ea-fastcs-01` already exists in
`t01-services`, so you can deploy it directly. Use a git tag instead of `main`
(for example `2024.12.1`) to pin a specific version:

```bash
ec deploy bl01t-ea-fastcs-01 main
```

Here is exactly what happened, and what did **not**:

- `ec` checked that `services/bl01t-ea-fastcs-01` exists in `t01-services` at
  the requested revision.
- `ec` then **committed and pushed** an entry under
  `services.bl01t-ea-fastcs-01` in the deployment repo's `apps/values.yaml`,
  recording the desired version. This commit is the source of truth.
- `ec` ran `argocd app get --refresh` to ask ArgoCD to re-read git immediately
  (otherwise ArgoCD notices on its next poll — every 3 minutes by default, or
  instantly if you have configured a git webhook).
- ArgoCD's **auto-sync** (the `automated`/`prune`/`selfHeal` policy) then
  reconciles the cluster to match git.

:::{important}
`ec deploy` does **not** run `argocd app sync`. Under the ArgoCD backend it only
*records desired state in git* and refreshes ArgoCD; the reconciliation is done
by ArgoCD's auto-sync. To force an immediate sync (e.g. if auto-sync is paused),
use the **Sync** button in the web UI, or `argocd app sync`.
:::

Verify with `ec ps`:

```bash
ec ps
```

```text
 name                 label     version   ready   deployed
 t01-epics-pvcs       service   main      True    2026-06-25T09:10:00Z
 t01-epics-opis       service   main      True    2026-06-25T09:10:00Z
 t01-epics-gateways   service   main      True    2026-06-25T09:10:00Z
 bl01t-ea-fastcs-01   service   main      True    2026-06-25T09:14:00Z
```

And confirm the git record — pull the deployment repo and look at
`apps/values.yaml`:

```bash
git -C t01-deployment pull
```

```yaml
services:
  t01-epics-pvcs:
  t01-epics-opis:
  t01-epics-gateways:
  bl01t-ea-fastcs-01:
    enabled: true
    targetRevision: main
    labels:
      description: ...
```

A new card for `bl01t-ea-fastcs-01` also appears in the ArgoCD web UI.

## Stop, start and remove a service (optional)

The rest of the service lifecycle is also driven through `ec`:

- `ec stop bl01t-ea-fastcs-01` / `ec start bl01t-ea-fastcs-01` — pause or resume
  a service as a live ArgoCD parameter override. Add `--commit` to also record
  the change in `apps/values.yaml` as a git audit trail.
- `ec delete bl01t-ea-fastcs-01` — removes the entry from `apps/values.yaml`,
  commits and pushes; auto-sync then prunes the resources from the cluster.
- `ec logs bl01t-ea-fastcs-01` — stream a service's logs.
- `ec monitor` — a terminal UI to browse and manage all services at once.

## Clean up

Because all desired state lives in git, teardown and rebuild are cheap and
reversible. Delete the root Application and, via `prune` plus finalizers, all of
its children are removed:

```bash
argocd app delete t01-beamline/t01 -y
```

Re-bootstrap any time with `argocd app create --file t01-deployment/apps.yaml` —
ArgoCD recreates everything from git (the persistent volume claims behind
`t01-epics-pvcs` are usually the slow part).

:::{note}
The cluster is fully reconstructable from git, with one caveat: IOC autosave
files held inside persistent volumes are *not* in git, so deleting the
underlying PVCs discards that state.
:::

## Next steps

- {any}`../explanations/argocd` — the GitOps model in depth: two repositories,
  app-of-apps, auto-sync, and the `ec` CLI's role.
- {any}`helm` — deploy with pure Helm instead of ArgoCD (the manual, non-GitOps
  alternative).
- {any}`add_k8s_ioc` — add and configure your own IOC instances in a services
  repo, ready to deploy here.
- {any}`deploy-example-instance` — the local / `docker compose` deployment path,
  for contrast with this cluster-based CD flow.
