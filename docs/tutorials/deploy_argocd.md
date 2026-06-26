(deploy-argocd)=

# Deploy an IOC with ArgoCD

:::{warning}
**DLS users:** beamline and accelerator deployments are driven through the
internal developer guide at <https://dev-guide.diamond.ac.uk/epics-containers/>
(the DLS cluster, Argus ArgoCD and webhooks), not these public cluster steps.
Follow along on your own test cluster only.
:::

You already deployed `t02-services` to the cluster with plain Helm
({any}`add_k8s_ioc`): the `ec` **K8S backend** ran `helm upgrade --install` for
each service. That works, but nothing keeps the cluster in step with git — if a
resource drifts or a pod is deleted, it stays gone until you redeploy by hand.

This tutorial adds **GitOps**. You create a **deployment repository** from a
template, bootstrap a single ArgoCD *root Application*, and switch the `ec`
backend from **K8S to ARGOCD**. From that point on `ec deploy` only *records the
desired version in git*, and ArgoCD continuously reconciles the cluster to match.

By the end you will have:

- a deployment repo (`t02-deployment`) generated from
  [`deployment-template-argocd`](https://github.com/epics-containers/deployment-template-argocd);
- a root ArgoCD Application (`t02`) that owns a set of child Applications;
- the IOC `bl02t-ea-cam-01` from {any}`add_k8s_ioc` running on your cluster, now
  with its desired version recorded in git and reconciled by ArgoCD.

The worked example continues the domain **`t02`** (beamline **`bl02t`**) and the
namespace **`t02-beamline`** from the earlier cluster tutorials, tracking the
services repository **`t02-services`** you built in {any}`setup-k8s-beamline`.
Substitute your own names throughout.

:::{note}
This is the GitOps deployment model. To understand *how* it works (the
two-repository split, app-of-apps, auto-sync) before running anything, read
{any}`../explanations/argocd` first.
:::

## Prerequisites

This tutorial assumes the pieces below are already in place; it does **not**
repeat the installation steps.

1. **A Kubernetes cluster with ArgoCD installed**, plus the `argocd` CLI
   installed and logged in. {any}`setup-argocd` installs ArgoCD into the cluster
   from {any}`setup-kubernetes` and shows how to reach its web UI (for a
   self-hosted install, by port-forwarding it to `https://localhost:8081/`). Do
   that first.

2. **A workstation with `ec`, `copier`, `git` and `kubectl`** — see
   {any}`setup_workstation`. `ec` must already be installed; the generated
   `environment.sh` only *checks* that it is present, it does not install it.

3. **A services repository to deploy from**, holding the Helm charts and
   per-service `values.yaml` files that *define* each IOC (see
   {any}`services-repo`). This tutorial uses the `t02-services` repo you built in
   {any}`setup-k8s-beamline` and extended in {any}`add_k8s_ioc`; substitute your
   own `EC_SERVICES_REPO` URL throughout.

4. **An ArgoCD project for your namespace.** The `t02-beamline` namespace already
   exists from {any}`setup-kubernetes`. ArgoCD Applications are authorised
   per-namespace and per-project, so create an ArgoCD project allowed to deploy
   into it:

   ```bash
   argocd proj create t02-beamline \
     -d https://kubernetes.default.svc,t02-beamline \
     -s "*"
   ```

   :::{note}
   The template sets each Application's `project:` field to your *namespace
   name* (the `cluster_namespace` you give `copier` below), so the ArgoCD
   project is named **`t02-beamline`** to match. `-d` whitelists the destination
   `cluster,namespace`; `-s "*"` permits any source repo. Adjust the cluster
   URL/name if your IOCs run on a different cluster from the one hosting ArgoCD.
   :::

## Scaffold a deployment repo

Generate the deployment repo from the public
[`deployment-template-argocd`](https://github.com/epics-containers/deployment-template-argocd)
template with `copier` (use `uvx copier ...` if `copier` is not installed):

```bash
copier copy https://github.com/epics-containers/deployment-template-argocd t02-deployment
```

`copier` asks a series of questions (defined in the template's `copier.yml`).
Answer them as follows for the worked example:

| Prompt | Meaning | Worked-example answer |
|---|---|---|
| `domain` | Short name for this collection of IOCs/services. Becomes the **root Application name**. | `t02` |
| `description` | One-line repo description. | *(accept default)* |
| `argocd_server` | DNS name of your ArgoCD server, used by `argocd login`. | your ArgoCD server, e.g. `localhost:8081` |
| `argocd_cluster` | The cluster where ArgoCD **creates the Application objects**. | `in-cluster` *(single-cluster install)* |
| `cluster_name` | The cluster where the **IOCs run** (child `destination.name`). | `in-cluster` *(same cluster)* |
| `cluster_namespace` | The namespace where IOCs run, **and** the ArgoCD project. | `t02-beamline` |
| `git_platform` | Where this repo will be hosted. | `github.com` |
| `github_org` | The GitHub account/org that will own the repo. | *your GitHub account or org* |
| `deployment_repo` | URL of **this** deployment repo. | *(accept default — `https://github.com/<org>/t02-deployment`)* |
| `services_repo` | URL of the **services** repo to track. | `https://github.com/<your-account>/t02-services` |
| `services_release` | Initial branch or tag of the services repo to track. | `main` |
| `logging_url` | Central log server URL (optional). | `Skip` |

:::{warning}
The template defaults are placeholders and **will not work unchanged**. The two
URLs that matter most are `deployment_repo` (the repo you are about to push) and
`services_repo` (here `https://github.com/<your-account>/t02-services`). Set
both correctly.
:::

Now create the git repository, commit the generated files, and push to the
remote you named in `deployment_repo`:

```bash
git -C t02-deployment init
git -C t02-deployment add .
git -C t02-deployment commit -m "Initial deployment repo from template"
git -C t02-deployment branch -M main
git -C t02-deployment remote add origin https://github.com/<org>/t02-deployment
git -C t02-deployment push -u origin main
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
  name: t02
  namespace: t02-beamline
  finalizers:
    - resources-finalizer.argocd.argoproj.io/background
    - resources-finalizer.argocd.argoproj.io/foreground
spec:
  project: t02-beamline
  destination:
    name: in-cluster
    namespace: t02-beamline
  source:
    path: apps
    repoURL: https://github.com/<org>/t02-deployment   # THIS (deployment) repo
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
project: t02-beamline
destination:
  name: in-cluster
  namespace: t02-beamline
source:
  repoURL: https://github.com/<your-account>/t02-services   # the SERVICES repo
  targetRevision: main

services:
  t02-epics-pvcs:
  t02-epics-opis:
  t02-epics-gateways:
```

:::{note}
`source.repoURL` here points at the **services** repo, not this one: every
*child* Application sources its Helm chart from `services/<service>` in the
services repo. The template seeds three children — `t02-epics-pvcs` (shared
storage), `t02-epics-opis` (auto-generated OPIs) and `t02-epics-gateways` (a
Channel Access gateway). A bare entry like `t02-epics-pvcs:` inherits all the
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
source ./t02-deployment/environment.sh
```

This sets the `EC_*` environment variables, enables `ec` shell completion, and
logs you into ArgoCD. The variables it exports are:

```bash
export EC_CLI_BACKEND="ARGOCD"            # the ArgoCD continuous-deployment backend
export EC_TARGET=t02-beamline/t02         # <namespace>/<root-app-name>
export EC_SERVICES_REPO=https://github.com/<your-account>/t02-services
export EC_LOG_URL=''                      # central log server (empty — logging_url Skipped)
```

`EC_SERVICES_REPO` is the repo that `ec deploy` validates versions against; for
the full `EC_*` reference see {any}`edge-containers-cli`.

:::{note}
**Site setup varies.** The template's `environment.sh` ends with a generic
`argocd login <server> --grpc-web --sso`. Adapt it to your own server and auth
method. For a self-hosted install reached via port-forward, that is typically
`argocd login localhost:8081`, logging in as `admin` with the password from your
ArgoCD install (see {any}`setup-argocd`).
:::

Check that the CLI is configured. Until you bootstrap the root Application (next
section) the target does not exist, so `ec ps` reports
`Target 't02-beamline/t02' not found`:

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
argocd app create --file t02-deployment/apps.yaml
```

ArgoCD creates the root Application `t02`, which in turn creates one child
Application per entry in `apps/values.yaml`. Within a moment you should see the
root plus its three seeded children:

```bash
argocd app list --app-namespace t02-beamline
```

```text
NAME                              SYNC STATUS   HEALTH
t02-beamline/t02                  Synced        Healthy
t02-beamline/t02-epics-pvcs       Synced        Healthy
t02-beamline/t02-epics-opis       Synced        Healthy
t02-beamline/t02-epics-gateways   Synced        Healthy
```

:::{note}
`kubectl apply -f apps.yaml` is the equivalent Kubernetes-native form (`apps.yaml`
is a valid `Application` resource). It works, but relies on your direct cluster
RBAC rather than ArgoCD's project authorisation — prefer the `argocd` CLI form
above.
:::

## Watch it sync in the ArgoCD web UI

Open your ArgoCD web UI (for a port-forwarded install, `https://localhost:8081/`)
and filter the Applications view by project `t02-beamline`. You will see a card
for the root `t02` and one per child; as ArgoCD reconciles, the cards turn green
(`Synced` / `Healthy`). Click a card to drill into the individual Kubernetes
resources (StatefulSets, Services, ConfigMaps) it manages — the quickest way to
diagnose a service that will not start.

## Deploy a service

Now deploy an IOC. The service `bl02t-ea-cam-01` already exists in
`t02-services` — you added it in {any}`add_k8s_ioc` — so you can deploy it
directly, this time through ArgoCD. Use a git tag instead of `main` (for example
`2026.6.1`) to pin a specific version:

```bash
ec deploy bl02t-ea-cam-01 main
```

Here is exactly what happened, and what did **not**:

- `ec` checked that `services/bl02t-ea-cam-01` exists in `t02-services` at
  the requested revision.
- `ec` then **committed and pushed** an entry under
  `services.bl02t-ea-cam-01` in the deployment repo's `apps/values.yaml`,
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
 t02-epics-pvcs       service   main      True    2026-06-25T09:10:00Z
 t02-epics-opis       service   main      True    2026-06-25T09:10:00Z
 t02-epics-gateways   service   main      True    2026-06-25T09:10:00Z
 bl02t-ea-cam-01   service   main      True    2026-06-25T09:14:00Z
```

And confirm the git record — pull the deployment repo and look at
`apps/values.yaml`:

```bash
git -C t02-deployment pull
```

```yaml
services:
  t02-epics-pvcs:
  t02-epics-opis:
  t02-epics-gateways:
  bl02t-ea-cam-01:
    enabled: true
    targetRevision: main
    labels:
      description: ...
```

A new card for `bl02t-ea-cam-01` also appears in the ArgoCD web UI.

## Stop, start and remove a service (optional)

The rest of the service lifecycle is also driven through `ec`:

- `ec stop bl02t-ea-cam-01` / `ec start bl02t-ea-cam-01` — pause or resume
  a service as a live ArgoCD parameter override. Add `--commit` to also record
  the change in `apps/values.yaml` as a git audit trail.
- `ec delete bl02t-ea-cam-01` — removes the entry from `apps/values.yaml`,
  commits and pushes; auto-sync then prunes the resources from the cluster.
- `ec logs bl02t-ea-cam-01` — stream a service's logs.
- `ec monitor` — a terminal UI to browse and manage all services at once.

## Clean up

Because all desired state lives in git, teardown and rebuild are cheap and
reversible. Delete the root Application and, via `prune` plus finalizers, all of
its children are removed:

```bash
argocd app delete t02-beamline/t02 -y
```

Re-bootstrap any time with `argocd app create --file t02-deployment/apps.yaml` —
ArgoCD recreates everything from git (the persistent volume claims behind
`t02-epics-pvcs` are usually the slow part).

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
