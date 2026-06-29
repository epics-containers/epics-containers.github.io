# Create a Generic IOC

In this tutorial you build a **Generic IOC**: a container image that wraps an
EPICS support module so that IOC *instances* can be created from it with nothing
but a YAML file. You will also embed an example instance for testing.

This is a *type 2* change from {any}`ioc-change-types`.

The worked example wraps the **areaDetector simulation detector**
([`ADSimDetector`](https://github.com/areaDetector/ADSimDetector)) — a camera
that generates frames internally, so it needs no hardware and no external
simulator. Substitute your own detector and support module throughout. By
convention a Generic IOC repository is named `ioc-<module>`, so here we build
**`ioc-adsimdetector`**.

:::{note}
A detector is a good worked example because it shows the one real twist over a
plain device: an areaDetector IOC builds on the **AreaDetector developer base
image**, which already ships ADCore and ADSupport. You add only the
detector-specific module on top.
:::

epics-containers builds support straight from public git repositories, so a
support module needs to be published with a standard EPICS layout. `ADSimDetector`
already is, so there is nothing to prepare. When you wrap your *own* module,
make sure it is public and standard first — see {any}`support_module`.

:::{warning}
Open-source your support modules before containerising where you can: it makes
collaboration and maintenance far easier. Legitimate reasons to keep one private
include a dependency on a proprietary library (check the licence first — you can
still open-source the module and supply the library at runtime via a PVC, as DLS
does for the Andor3 SDK), or code that is facility-specific or still a prototype.
Internal git repositories are fully supported.
:::

(create_generic_ioc)=

## Create the Generic IOC project

Like a beamline, a Generic IOC starts from a `copier` template. Create an empty
GitHub repository named `ioc-adsimdetector` at <https://github.com/new>, then
generate the project into it (if you do not have `copier`, see {any}`copier`):

```bash
# creates the folder ioc-adsimdetector in the current directory
copier copy https://github.com/epics-containers/ioc-template --trust ioc-adsimdetector
```

Answer the prompts:

| Prompt | Worked-example answer |
|---|---|
| A name for this project (starts `ioc-`) | `ioc-adsimdetector` |
| A one line description of the module | `Generic IOC for the areaDetector simulation detector` |
| Git platform hosting the repository | `github.com` |
| The GitHub organisation that will contain this repo | *your GitHub account or org* |
| Remote URI of the repository | *(accept the default)* |

Accept the defaults for any remaining prompts. Then make the first commit and
push:

```bash
cd ioc-adsimdetector
git add .
git commit -m "initial commit"
git push -u origin main
```

Pushing triggers a GitHub Actions build of the (still empty) Generic IOC. It is
not published — there is no release tag yet — but it primes the build cache so
your later builds are fast. Watch it under the **Actions** tab.

Open the project in VSCode — but **stay on the host for now**; do not reopen in
the container yet. You will first point the `Dockerfile` at the correct base
image and build it once, so the developer container you open afterwards is
already the right image, cached:

```bash
cd ioc-adsimdetector
code .
```

:::{note}
**DLS users:** run `module load vscode` before `code .`, and start podman with
`source /dls_sw/apps/setup-podman/setup.sh`.
:::

## Switch to the AreaDetector base image

The `Dockerfile` builds the container image. Its `ARG` lines pick the
**developer** base image to build in and the **runtime** base image to ship.
The template defaults to the plain `epics-base` images and then builds a few
common modules (`iocStats`, `pvlogging`, `autosave`) on top.

For an areaDetector IOC, point `DEVELOPER` at the AreaDetector developer base
instead. It is built on `ioc-asyn` and already contains ADCore, ADSupport,
`asyn` and the common modules — so you can **delete** those per-module
`COPY`/`RUN` lines and add only the detector-specific module:

```dockerfile
ARG RUNTIME=${REGISTRY}/epics-base${IMAGE_EXT}-runtime:7.0.10ec1
ARG DEVELOPER=${REGISTRY}/ioc-areadetector${IMAGE_EXT}-developer:3.14ec2
```

```dockerfile
COPY ibek-support/ADSimDetector/ ADSimDetector
RUN ansible.sh ADSimDetector
```

Each module is built by copying its `ibek-support/<module>` folder and running
`ansible.sh <module>`. That script applies an `ibek-support` *recipe* that
clones the module from upstream, builds it with standard EPICS steps, and
records its dbds and libs for the IOC link. ADCore is supplied by the base
image — do **not** re-author or rebuild it.

:::{note}
The per-module `COPY`/`RUN` pairs look repetitive, but they maximise the build
cache hit rate — editing one recipe does not force every module to rebuild.
:::

## Build the image and open the devcontainer

With the base image set, build the developer image **on the host** so you can
watch the full log — VSCode otherwise hides it behind a progress notification.
The AreaDetector base is large, so the first build takes a few minutes; the
layers are cached for every build after that:

```bash
./build
```

`./build` calls `docker` (or `podman` if `USE_PODMAN` is set). Once it succeeds,
reopen the project in its developer container — it reuses the image you just
built, so it opens straight away:

- `Ctrl-Shift-P` -> *Dev Containers: **Rebuild and Reopen in Container***

Use **Rebuild and Reopen**, not plain *Reopen in Container*: VSCode keys its
devcontainers by project name, so a plain reopen can attach you to a stale
container left over from an earlier `ioc-adsimdetector` instead of your freshly
built image.

:::{tip}
This is a recurring theme: whenever a devcontainer misbehaves or will not open,
reach for the **Rebuild** option (`Ctrl-Shift-P` -> *Dev Containers: Rebuild
Container*). The rebuild is still fast because the image layers are cached.
:::

All the work below happens inside this container.

## Fork the ibek-support submodule

New modules need recipes, which live in `ibek-support` — a submodule shared by
all `ioc-*` projects. It is curated, so you work from a fork (open a pull
request later if your recipe is generally useful).

- Fork it at <https://github.com/epics-containers/ibek-support/fork>.
- Copy the fork's **HTTPS** *Code* URL and point the submodule at it:

```bash
cd /workspaces/ioc-adsimdetector
git submodule set-url ibek-support <YOUR FORK HTTPS URL>
git submodule update
cd ibek-support
git fetch
git checkout main            # work from your fork's main branch
git remote -v               # confirm origin is your fork
cd ..
```

:::{important}
Use the **HTTPS** URL, not SSH — CI clones have no SSH keys. HTTPS reads fine; to
*push*, tell git to swap in SSH by adding this to your `~/.gitconfig`:

```text
[url "ssh://git@github.com/"]
        insteadOf = https://github.com/
```

Rebuild the devcontainer (Ctrl-Shift-P -> *Dev Containers: Rebuild Container*)
for this to take effect inside it.
:::

## Re-author the build recipe

`ibek-support` already ships an `ADSimDetector` recipe, but re-authoring it from
scratch is the whole lesson. Deleting the stock folder and rebuilding it here
also keeps the tutorial self-contained: you end up with a known recipe you wrote
yourself, rather than depending on whatever happens to be checked out in the
submodule. Delete the stock folder and start clean:

```bash
cd /workspaces/ioc-adsimdetector/ibek-support
rm -rf ADSimDetector
mkdir ADSimDetector
code ADSimDetector/ADSimDetector.install.yml
```

A recipe is a `<module>.install.yml` file that drives `ansible.sh`:

```yaml
# yaml-language-server: $schema=../_scripts/support_install_variables.json

module: ADSimDetector
version: R2-11
dbds:
  - simDetectorSupport.dbd
libs:
  - simDetector

organization: http://github.com/areaDetector/
```

The keys are minimal:

- **module** — the upstream repo name (and the folder under `/epics/support`).
- **version** — the upstream tag to build. Use a recent one; `ibek-support` CI
  builds every module to confirm the set works together.
- **organization** — URL prefix of the repo. Defaults to
  `https://github.com/epics-modules`; areaDetector modules live under
  `areaDetector` instead.
- **dbds** / **libs** — the database-definition(s) and library(ies) the module
  publishes, to link into the IOC. They default to empty and are **not** inferred
  from the module name, so almost every recipe lists them explicitly — here
  `simDetectorSupport.dbd` and `simDetector`.

The schema on the first line gives auto-completion and validation in VSCode (via
the Red Hat YAML extension). Every available key is listed in
`ibek-support/_ansible/roles/support/vars/main.yml`. Build it from a devcontainer
terminal (Terminal -> New Terminal):

```bash
ansible.sh ADSimDetector
```

`ansible.sh` runs the `ibek-support` Ansible role for the module, which:

- installs any system packages the recipe declares;
- clones the module from its git repository at the pinned `version`;
- fixes up `configure/RELEASE` to point at the modules already in the image, and
  applies any patches the recipe specifies;
- builds it with the standard EPICS `make`;
- appends its `dbds` and `libs` to the global `/epics/support/configure/dbd_list`
  and `/epics/support/configure/lib_list` so the IOC links them in;
- registers its runtime files — symlinking the `*.ibek.support.yaml`, PVI
  device, autosave request and StreamDevice protocol files into `/epics`.

The module now exists under `/epics/support`.

## Add a support definition

The recipe builds the *binary*; a **support definition** lets instances describe
themselves in YAML instead of hand-writing `st.cmd` and `ioc.subst`. (You can
still supply those files by hand — the Generic IOC accepts both.) Defining
parameters in YAML means a schema-aware editor validates each instance as you
type it, and your services repo's CI re-checks it on push.

In the same folder create `ADSimDetector.ibek.support.yaml`:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ibek/releases/download/3.0.1/ibek.support.schema.json

module: ADSimDetector

entity_models:
  - name: simDetector
    description: Creates a simulation detector
    parameters:
      P:
        type: str
        description: Device Prefix
      R:
        type: str
        description: Device Suffix
      PORT:
        type: id
        description: Port name for the detector
      TIMEOUT:
        type: str
        default: "1"
        description: Timeout
      ADDR:
        type: str
        default: "0"
        description: Asyn Port address
      WIDTH:
        type: int
        default: 1280
        description: Image Width
      HEIGHT:
        type: int
        default: 1024
        description: Image Height
      DATATYPE:
        type: int
        default: 1
        description: Datatype
      BUFFERS:
        type: int
        default: 50
        description: Maximum number of NDArray buffers for plugin callbacks
      MEMORY:
        type: int
        default: 0
        description: Max memory to allocate (0 = unlimited)

    pre_init:
      - type: text
        value: |
          # simDetectorConfig(portName, maxSizeX, maxSizeY, dataType, maxBuffers, maxMemory)
          simDetectorConfig("{{PORT}}", {{WIDTH}}, {{HEIGHT}}, {{DATATYPE}}, {{BUFFERS}}, {{MEMORY}})

    databases:
      - file: simDetector.template
        args:
          P:
          R:
          PORT:
          TIMEOUT:
          ADDR:

    pvi:
      yaml_path: simDetector.pvi.device.yaml
      ui_macros:
        P:
        R:
      pv: true
      pv_prefix: $(P)$(R)
```

Each `entity_model` declares the parameters an instance may set, the database
templates to instantiate, and any iocShell lines to add (`pre_init` runs
`simDetectorConfig` before `iocInit`). Values are Jinja templates, so you can
combine parameters.

The `pvi:` block points at a **PVI device description** that PVI turns into an
auto-generated Phoebus screen. Hand-writing one is ~6 KB of GUI layout, so reuse
the stock version rather than typing it out. You deleted it earlier, but it is
still in the submodule's git history, so restore just that one file:

```bash
cd /workspaces/ioc-adsimdetector/ibek-support
git checkout HEAD -- ADSimDetector/simDetector.pvi.device.yaml
```

:::{note}
TODO: Auto generation of PVI device descriptions from the module DB and screens
is under development. For now, we copy the stock one from the submodule.
:::

:::{important}
The support definition file **must** end in `.ibek.support.yaml`. `ansible.sh`
symlinks it into `/epics/ibek-defs`, where `ibek` collects every support
definition into the schema used to validate instances. Re-run `ansible.sh` to
register it (it is idempotent, so re-running is safe):

```bash
ansible.sh ADSimDetector
```
:::

We have added new support since the IOC binary was last built, so rebuild it:

```bash
cd /epics/ioc
make
```

## Test with an example instance

To exercise the Generic IOC you need an instance — and you already have a perfect
one: the `bl01t-ea-cam-01` instance in your `t01-services` repo, which you have
driven throughout the earlier tutorials. Now you can test it against the image
you just built yourself. The simulation detector generates frames internally, so
**no external simulator is required**. Its `ioc.yaml` already carries a local
schema line from the earlier tutorials, so your editor validates it as-is.

Select the instance, build and run it:

```bash
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01
cd /epics/ioc
make
./start.sh
```

The IOC should start and begin generating frames. To iterate on the instance you
do **not** need to rebuild the binary — edit
`/workspaces/t01-services/services/bl01t-ea-cam-01/config/ioc.yaml`, stop the IOC
with `Ctrl-D`, and run `./start.sh` again. (Rebuild with `make` only after
changing the *set of support modules*.)

To see what `ibek` generated, look in `/epics/runtime` (the expanded startup
script and database) and `/epics/ibek-defs` (the registered support
definitions). When a build *fails*, see {any}`debug_generic_ioc`.

:::{note}
**DLS users:** builder beamlines can convert existing builder XML instances into
`ibek` YAML with `builder2ibek`. See the
[builder2ibek documentation](https://epics-containers.github.io/builder2ibek).
:::

## Publish the Generic IOC

Commit your `ibek-support` recipe (on a branch) and the IOC project, then push:

```bash
cd /workspaces/ioc-adsimdetector/ibek-support
git checkout -b add-adsimdetector
git add .
git commit -m "re-author ADSimDetector support module"
git push -u origin add-adsimdetector

cd ..
git add .
git commit -m "add ADSimDetector support and example instance"
git push   # a tutorial may push to main; real projects use a PR
```

The push triggers a CI image build (watch the **Actions** tab). To *publish* to
GHCR, cut a release: on the repo's **Releases** tab choose **Create a new
release**, pick a tag such as `2.11ec3`, click **Generate release notes**, then
**Publish release**.

:::{note}
**Figure (screenshot TODO — maintainer walkthrough):** the GitHub *Create a new
release* form for `ioc-adsimdetector`, with a tag such as `2.11ec3` entered and
the generated release notes shown.
:::

CI then builds and pushes the image, which appears under the repo's
**Packages** as `ghcr.io/<org>/ioc-adsimdetector-runtime`.

:::{note}
If the `release` job fails with `Resource not accessible by integration`, go to
Settings -> Actions -> General -> Workflow Permissions and select **Read and
write permissions**.
:::

## Next steps

You now have a published `ioc-adsimdetector` image.

- {any}`detector_plugins` — add the standard areaDetector plugin set to an
  instance **at runtime**, with no image rebuild.
- {any}`custom_pattern` — author your *own* runtime support pattern (the
  runtime-vendoring mirror of the build-time work you just did here).
- As an exercise, add an instance that uses this image to your `bl01t` beamline
  and run it with `docker compose up -d` (see {any}`deploy-example-instance`).
