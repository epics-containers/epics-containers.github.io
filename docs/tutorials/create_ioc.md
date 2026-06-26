# Create an IOC Instance

In {any}`create-beamline` you generated `t01-services` with one example IOC
instance (`example-test-01`). Now you will add your own: a simulated area
detector built on the public `ioc-adsimdetector` Generic IOC. Substitute your
own names throughout.

:::{note}
A little familiarity with the EPICS
[AreaDetector](https://areadetector.github.io/areaDetector/index.html)
framework is helpful but not required.
:::

(create-new-ioc-instance)=
## Add a New IOC Instance

An IOC instance is just a folder under `services/`. Its folder name is the IOC
name, and it contains two things:

| Item | Purpose |
|---|---|
| `compose.yml` | Boilerplate that says *which container image* to run and *what to call it*. |
| `config/` | The IOC configuration, normally a single `ibek` file named `ioc.yaml`. |

Your services repo ships a `.ioc_template` skeleton to copy. In a terminal at
the repo root:

```bash
cd t01-services
cp -r services/.ioc_template services/bl01t-ea-cam-01
code .
```

:::{note}
DLS users: `module load vscode` first, then `code .`.
:::

### compose.yml

The skeleton's `compose.yml` has two placeholders. In
`services/bl01t-ea-cam-01/compose.yml`, replace **every** `ioc_default_name`
with `bl01t-ea-cam-01`, and replace `replace_with_image_uri` with the
SimDetector Generic IOC image:

```yaml
    image: ghcr.io/epics-containers/ioc-adsimdetector-runtime:2.11ec1
```

That name and that image are the only per-IOC content; everything else is
boilerplate. `extends` merges in the shared IOC definition from
`include/ioc.yml`, and `configs` mounts your `config/` folder at
`/epics/ioc/config` inside the container. The
[compose file format](https://docs.docker.com/compose/compose-file) covers the
rest.

### config/ioc.yaml

An `ibek` `ioc.yaml` is a list of `entities`; each instantiates an
`entity_model` from a support module, which turns its named parameters into
startup-script lines and database records. The Generic IOC bakes in all the
support it can instantiate, so nothing extra is downloaded here.

Open `services/bl01t-ea-cam-01/config/ioc.yaml`, point the schema line at the
SimDetector Generic IOC, and add a `simDetector` plus a Standard Arrays plugin
wired to it:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ioc-adsimdetector/releases/download/2.11ec1/ibek.ioc.schema.json

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
    P: BL01T-EA-CAM-01
    R: ":DET:"

  - type: ADCore.NDStdArrays
    PORT: DET.ARR
    P: BL01T-EA-CAM-01
    R: ":ARR:"
    NDARRAY_PORT: DET.DET
    TYPE: Int8
    FTVL: CHAR
    NELEMENTS: 1048576
```

This creates a simulation detector with PV prefix `BL01T-EA-CAM-01:DET:` on the
Asyn port `DET.DET`, and a Standard Arrays plugin that publishes its image over
Channel Access.

:::{note}
YAML indentation is significant: each `- type:` starts a new entity. Quote any
value that begins with `:` or `{` (as with `R: ":DET:"`).
:::

Finally register the instance by adding it to the `include:` list in the
repo-root `compose.yml`:

```yaml
include:
  - services/example-test-01/compose.yml
  - services/bl01t-ea-cam-01/compose.yml
  ...
```

(change-the-opi-screen)=
## Run It and View the Screens

Bring the beamline up:

```bash
source ./environment.sh
docker compose up -d
```

At startup PVI generates an **engineering screen per entity** for your new IOC
into `opi/auto-generated/bl01t-ea-cam-01/`. In Phoebus, open
`auto-generated/bl01t-ea-cam-01/index.bob`: on the `simDetector` panel hit
**Acquire**, and on the `NDStdArrays` panel **Enable** the plugin. These widgets
drive your `BL01T-EA-CAM-01` PVs, and a moving simulation image appears.

The hand-coded overview screen `opi/demo.bob` that Phoebus opens by default
drives the *shipped* example IOCs, not your new one. To surface
`bl01t-ea-cam-01` there too, copy one of its panes and re-point the macros at
`BL01T-EA-CAM-01` — but the auto-generated screens above already give you full
control with no editing. Manage the running IOC with the same `docker compose`
commands from {any}`deploy_example`.

:::{note}
This IOC is reused by later tutorials, so commit it now:

```bash
git add .
git commit -m "Create bl01t-ea-cam-01 IOC"
```
:::

## How ibek Builds the IOC

You wrote no startup script or database. At container start,
`ibek runtime generate2` reads `config/ioc.yaml` plus the support definitions
baked into the image and writes the `st.cmd` and database into `/epics/runtime/`.
The schema line at the top of `ioc.yaml` also drives completion and validation
in VSCode — install the
[Red Hat YAML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml).
To learn where entity models come from and build your own, see
{any}`generic_ioc`.

(raw-startup-assets)=
## Raw Startup Script and Database

Prefer to hand-write startup assets? Drop your own `st.cmd` and `ioc.subst`
(or an `ioc.db`) into `config/` instead of `ioc.yaml` — `start.sh` copies those
files straight through, and a `config/start.sh` overrides startup entirely.

To start from what `ibek` generated, copy it out of the running container,
delete `ioc.yaml`, and restart:

```bash
podman cp t01-services-bl01t-ea-cam-01-1:/epics/runtime/st.cmd services/bl01t-ea-cam-01/config
podman cp t01-services-bl01t-ea-cam-01-1:/epics/runtime/ioc.subst services/bl01t-ea-cam-01/config
rm services/bl01t-ea-cam-01/config/ioc.yaml
docker compose restart bl01t-ea-cam-01
```

The IOC then behaves as before, minus the auto-generated engineering screens:
drop the `.pvi`-named template lines from `ioc.subst`, since those screens are
only produced by the `ibek` path.

:::{note}
Later tutorials assume the `ioc.yaml` version, so keep this experiment on a
branch:

```bash
git checkout -b raw-startup
git add . && git commit -m "use raw startup script and database"
git checkout main
```
:::
