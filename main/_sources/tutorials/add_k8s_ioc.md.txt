(add-k8s-ioc)=

# Deploy an IOC with Helm

:::{warning}
**DLS users:** beamline and accelerator IOCs are deployed through the internal
developer guide at <https://dev-guide.diamond.ac.uk/epics-containers/>, not these
public cluster steps. Follow along on your own test cluster only.
:::

This is your **first deployment of your own IOC onto the cluster**, using plain
Helm. In {any}`setup-k8s-beamline` you created the services repo `t02-services`
and deployed its shared services with the `ec` **K8S backend** (which runs
`helm upgrade --install` under the hood). Now you add **your own** IOC — a
simulated area detector, much like the one built in {any}`create_ioc`, but
defined for a Helm {any}`services repo <services-repo>` — and deploy it the same
way, with `ec deploy`. Substitute your own names throughout.

By the end you will have a new IOC instance folder in your services repo,
committed, pushed and running on the cluster. Later, {any}`deploy-argocd` puts
this same repo under GitOps control with ArgoCD.

## Add a new instance folder

An IOC instance is a folder under `services/`. Its folder name is the IOC name,
and it holds two things:

| Item | Purpose |
|---|---|
| `values.yaml` | Helm values for the `ioc-instance` chart — chiefly *which container image* to run. |
| `config/` | The IOC configuration, mounted into the container as a Kubernetes ConfigMap. Normally a single `ibek` file, `ioc.yaml`. |

Your services repo ships a `.ioc_template` skeleton to copy. From the repo root:

```bash
cd t02-services
cp -r services/.ioc_template services/bl02t-ea-cam-01
code .
```

:::{note}
**DLS users:** `module load vscode` first, then `code .`.
:::

The skeleton's `Chart.yaml` and `templates/` are symlinks into the shared
`.helm-shared/` chart, so every instance reuses the same `ioc-instance` chart —
you never edit them.

## Set the image — values.yaml

Edit `services/bl02t-ea-cam-01/values.yaml` and replace the placeholder image
with the SimDetector Generic IOC:

```yaml
# yaml-language-server: $schema=../../.helm-shared/values.schema.json

ioc-instance:
  image: ghcr.io/epics-containers/ioc-adsimdetector-runtime:2.11ec3
```

`ioc-instance:` is the key the chart imports its values under. Shared defaults
(such as `hostNetwork: true`) come from the repo-root `services/values.yaml`, so
a per-instance file normally only overrides what differs — usually just `image`.

## Configure the IOC — config/ioc.yaml

An `ibek` `ioc.yaml` is a list of `entities`; each instantiates a model
contributed by a support module. The Generic IOC bakes in the support it can
instantiate, so nothing extra is downloaded here. Open
`services/bl02t-ea-cam-01/config/ioc.yaml` and replace its body:

```yaml
# yaml-language-server: $schema=../ioc.schema.json

ioc_name: "{{ _global.get_env('IOC_NAME') }}"

description: An IOC that simulates an area detector

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: ADSimDetector.simDetector
    PORT: DET.DET
    P: BL02T-EA-CAM-01
    R: ":DET:"

  - type: ADCore.NDStdArrays
    PORT: DET.ARR
    P: BL02T-EA-CAM-01
    R: ":ARR:"
    NDARRAY_PORT: DET.DET
    TYPE: Int8
    FTVL: CHAR
    NELEMENTS: 1048576
```

This makes a simulation detector with PV prefix `BL02T-EA-CAM-01:DET:` and a
Standard Arrays plugin that publishes its image over Channel Access.

:::{note}
YAML indentation is significant: each `- type:` starts a new entity, and a value
that begins with `:` must be quoted (as in `R: ":DET:"`).
:::

The schema line points at `../ioc.schema.json`. Generate it once so VSCode (with
the Red Hat YAML extension) offers completion and validation for exactly the
entities this image provides:

```bash
ibek pattern schema services/bl02t-ea-cam-01
```

`ibek` fetches the published schema for your pinned image and writes
`services/bl02t-ea-cam-01/ioc.schema.json`. To learn where these entity models
come from and build your own, see {any}`generic_ioc`.

## Vendor extra runtime support (optional)

Some IOCs need runtime inputs that are **not** compiled into the image —
StreamDevice protocol files, EPICS DB templates, and the `ibek` models that
describe them. Vendor them into the instance's `config/` from a central pattern
library:

```bash
ibek pattern add <library>:<pattern>@<tag> services/bl02t-ea-cam-01
```

This copies the files into `config/`, records each one with a pinned version and
`sha256` hash in `services/bl02t-ea-cam-01/runtime-lock.yaml`, and refreshes
`ioc.schema.json` so the new entities validate too. Because `config/` is mounted
as the ConfigMap, keep its total content under 1 MiB. `ibek pattern check`
verifies the vendored files still match the lock. The simulated detector above
needs none of this, so you can skip the section.

## Deploy it

Make sure your environment is configured for the **K8S backend** — source the
repo's `environment.sh` (see {any}`setup-k8s-beamline`), which sets
`EC_CLI_BACKEND=K8S`. Then commit your new instance and push it to the services
repo that `ec` deploys from (`EC_SERVICES_REPO`):

```bash
git add services/bl02t-ea-cam-01
git commit -m "Add bl02t-ea-cam-01 IOC"
git push
```

Now deploy it (`-v` prints the underlying helm/kubectl commands):

```bash
ec -v deploy bl02t-ea-cam-01 main
```

Under the K8S backend `ec deploy` does **not** go through ArgoCD or a deployment
repo. Instead it:

- clones `t02-services` at the requested revision (`main` here);
- packages `services/bl02t-ea-cam-01` as a Helm chart, applying the shared
  `services/values.yaml` and the instance `values.yaml`;
- runs `helm upgrade --install bl02t-ea-cam-01 ... --namespace t02-beamline`
  directly against the cluster.

Use a git tag instead of `main` (for example `ec deploy bl02t-ea-cam-01 2026.7.1`)
to pin a specific version, exactly as you tagged and deployed the shared services
in {any}`setup-k8s-beamline`.

Confirm it is running, then inspect it:

```bash
ec ps                          # list services in your namespace
ec logs bl02t-ea-cam-01        # stream the IOC's container logs
```

```text
 name                version   ready   deployed
 t02-epics-pvcs      2026.7.1  True    2026-07-01T09:10:00Z
 t02-epics-opis      2026.7.1  True    2026-07-01T09:11:00Z
 bl02t-ea-cam-01     main      True    2026-07-01T09:20:00Z
```

Pause and resume the IOC without removing it:

```bash
ec stop bl02t-ea-cam-01
ec start bl02t-ea-cam-01
```

See {any}`edge-containers-cli` for the full `ec` command and environment-variable
reference.

## Next steps

- {any}`setup-argocd` — install ArgoCD, the next step towards GitOps deployment.
- {any}`deploy-argocd` — put this same repo under GitOps control with ArgoCD (the
  production continuous-deployment flow), switching the `ec` backend from K8S to
  ARGOCD.
- {any}`helm` — the pure-Helm reference for what `ec deploy` runs under the K8S
  backend.
- {any}`generic_ioc` — build your own Generic IOC image when no published one
  fits.
