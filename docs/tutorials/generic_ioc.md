# Create a Generic IOC

In this tutorial you build a **Generic IOC**: a container image that wraps an
EPICS support module so that IOC *instances* can be created from it with nothing
but a YAML file. You will also embed an example instance for testing.

This is a *type 2* change from {any}`ioc-change-types`.

The worked example wraps the **areaDetector simulation detector**
([`ADSimDetector`](https://github.com/areaDetector/ADSimDetector)) — a camera
that generates frames internally, so it needs no hardware and no external
simulator. Substitute your own detector and support module throughout. By
convention a Generic IOC repository is named `ioc-<module>` (which would make
this `ioc-adsimdetector`); to keep the tutorial repo separate from the published
`ioc-adsimdetector` example we build **`ioc-adsim-demo`** here instead.

:::{note}
A detector is a good worked example because it shows the one real twist over a
plain device: a detector driver needs the areaDetector stack under it. The
Generic IOC's `Dockerfile` builds that whole stack itself — `asyn`, `ADCore`
and the modules they depend on — before the detector-specific module.
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
GitHub repository named `ioc-adsim-demo` at <https://github.com/new>, then
generate the project into it (if you do not have `copier`, see {any}`copier`):

```bash
# creates the folder ioc-adsim-demo in the current directory
copier copy https://github.com/epics-containers/ioc-template --trust ioc-adsim-demo
```

Answer the prompts:

| Prompt | Worked-example answer |
|---|---|
| A name for this project (starts `ioc-`) | `ioc-adsim-demo` |
| A one line description of the module | `Generic IOC for the areaDetector simulation detector` |
| Git platform hosting the repository | `github.com` |
| The GitHub organisation that will contain this repo | *your GitHub account or org* |
| Build and publish an arm64 image as well as amd64? | *(accept the default, yes)* |

`copier` also initialises git in the new folder, adds the `ibek-support`
submodule and sets `origin` to
`git@github.com:<your account or org>/ioc-adsim-demo.git`. Make the first
commit and push:

```bash
cd ioc-adsim-demo
git add .
git commit -m "initial commit"
git push -u origin main
```

Pushing triggers a GitHub Actions build of the (still empty) Generic IOC. It is
not published — there is no release tag yet — but it primes the build cache so
your later builds are fast. Watch it under the **Actions** tab.

Open the project in VSCode — but **stay on the host for now**; do not reopen in
the container yet. You will first add the areaDetector support modules to the
`Dockerfile`, so that the developer image is built with them the first time:

```bash
cd ioc-adsim-demo
code .
```

:::{note}
**DLS users:** run `module load vscode` before `code .`
:::

(generic-ioc-dockerfile)=
## Add the areaDetector stack to the Dockerfile

The `Dockerfile` builds the container image. Its `ARG` lines pick the
`epics-base` **developer** image to build in and the `epics-base` **runtime**
image to ship:

```dockerfile
ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/epics-base-runtime:7.0.11ec2
ARG DEVELOPER=${REGISTRY}/epics-base-developer:7.0.11ec2
```

Every Generic IOC builds from these two images and compiles all of its support
modules itself, from the recipes in the `ibek-support` submodule: each module is
a `COPY ibek-support/<module>/` line and a `RUN ansible.sh <module>` line. No
Generic IOC image is built on another one, so each Generic IOC chooses and pins
every module it contains, and one Generic IOC can be released without
rebuilding any other.

The template builds three common modules, `iocStats`, `pvlogging` and
`autosave`. An areaDetector driver also needs `asyn`, `ADCore` (which builds
`ADSupport` too) and the modules they depend on. Add them to the `Dockerfile`,
so that the module list after the `ENV PATH` line, down to the `ioc` build,
reads:

```dockerfile
COPY ibek-support/iocStats/ iocStats
RUN ansible.sh iocStats

COPY ibek-support/sequencer/ sequencer
RUN ansible.sh sequencer

COPY ibek-support/sscan/ sscan
RUN ansible.sh sscan

COPY ibek-support/calc/ calc
RUN ansible.sh calc

COPY ibek-support/asyn/ asyn
RUN ansible.sh asyn

COPY ibek-support/busy/ busy
RUN ansible.sh busy

COPY ibek-support/autosave/ autosave
RUN ansible.sh autosave

COPY ibek-support/pvlogging/ pvlogging
RUN ansible.sh pvlogging

COPY ibek-support/ADCore/ ADCore
RUN ansible.sh ADCore

# get the ioc source and build it
COPY ioc ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc
```

This is the same list, in the same order, that the published
[ioc-adsimdetector](https://github.com/epics-containers/ioc-adsimdetector/blob/main/Dockerfile)
builds, less `ffmpegServer` (an MJPEG streaming plugin that this example does
not use) and the detector module itself, which you add later in this tutorial.
Each module comes after the modules it depends on; see {any}`module-build-order`.

## Build the image and open the devcontainer

A developer container normally opens from the developer image that CI
publishes with each full release. This repository has no release yet, so there
is no image to pull: when you open the container, `.devcontainer/initializeCommand`
builds the developer image on the host with `./build` instead (see
{any}`devcontainer-open`). The first build compiles every support module, and
`ADCore` is large, so it takes a while; Docker caches each `RUN ansible.sh`
step, so later builds start again only from the first line that changed.

- `Ctrl-Shift-P` -> *Dev Containers: **Reopen in Container***

VSCode hides the build output behind a progress notification. Click **show
log** in that notification to watch it.

Later starts still have nothing to pull, so they reuse the image you built as
it is. To build it again after changing the `Dockerfile`, create the marker
file `.devcontainer/local-build` and rebuild the container, as
{any}`devcontainer-local-build` describes.

:::{tip}
If you ever have problems opening a devcontainer
try the **Rebuild** option (`Ctrl-Shift-P` -> *Dev Containers: Rebuild
Container*). It creates a new container from the image, so it is quick.
:::

All the work below happens inside this container.

## Fork the ibek-support submodule

New modules need recipes, which live in `ibek-support` — a submodule shared by
all `ioc-*` projects. It is curated, so you work from a fork (open a pull
request later if your recipe is generally useful).

- Fork it at <https://github.com/epics-containers/ibek-support/fork>.
- Copy the fork's **HTTPS** *Code* URL and point the submodule at it:

```bash
cd /workspaces/ioc-adsim-demo
git submodule set-url ibek-support <YOUR FORK HTTPS URL>
git submodule update
cd ibek-support
git fetch
git checkout main            # work from your fork's main branch
git pull --ff-only           # bring it up to date with your fork
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
cd /workspaces/ioc-adsim-demo/ibek-support
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

:::{note}
If you want to read exactly what this does, follow the Ansible playbook at
`/workspaces/ioc-adsim-demo/ibek-support/_ansible/playbook.yml`.
:::

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

    post_init:
      - type: text
        value: |
          # THIS IOC WAS GENERATED AS PART OF AN epics-container TUTORIAL
          # SEE https://epics-containers.github.io/main/tutorials/generic_ioc.html

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
cd /workspaces/ioc-adsim-demo/ibek-support
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

:::{note}
During startup you may see an error like:

```
ERROR: Record 'BL01T-EA-CAM-01:STAT:TSAcquiring' not found
```

This is benign and will be fixed soon — the IOC still starts normally.
:::

:::{warning}
If instead you see an error like:

```
Input tag 'ADSimDetector.simDetector' found using 'type' does not match any of the expected tags:
```

your support definition is not registered. Re-run `ansible.sh ADSimDetector` to
symlink the `.ibek.support.yaml` into `/epics/ibek-defs`, then try again.
:::

The IOC should start up and the output should end with:

<pre>iocRun: All initialization complete
<font color="#268BD2"><b># THIS IOC WAS GENERATED AS PART OF AN epics-containers TUTORIAL</b></font>
<font color="#268BD2"><b># SEE https://epics-containers.github.io/main/tutorials/generic_ioc.html</b></font>
<font color="#859900"><b>epics&gt; </b></font>
</pre>

To iterate on the instance you do **not** need to rebuild the binary — edit
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

(module-build-order)=
## Add the module to the Dockerfile

The recipe works inside the devcontainer, but the *published* image is built by
CI from the `Dockerfile`, which does not yet know about the detector. Now that
the recipe exists, add its `COPY`/`RUN` pair after `ADCore`, before the `ioc`
build:

```dockerfile
COPY ibek-support/ADSimDetector/ ADSimDetector
RUN ansible.sh ADSimDetector
```

Each module is built by copying its `ibek-support/<module>` folder and running
`ansible.sh <module>`. That script applies the `ibek-support` recipe that clones
the module from upstream, builds it with standard EPICS steps, and records its
dbds and libs for the IOC link.

:::{note}
Your container was created from an image built without these lines, so
`ibek dev status` now reports `ADSimDetector: not built in this container`.
`ansible.sh` has already built it there, so you can carry on.
`ibek dev sync --build` builds it again, with any modules after it and the IOC,
and clears the report.
:::

:::{note}
The per-module `COPY`/`RUN` pairs look repetitive, but they maximise the build
cache hit rate — editing one recipe does not force every module to rebuild.
:::

:::{important}
Put the `COPY`/`RUN` pairs in dependency order, with each module after the
modules it depends on. A module build needs its dependencies already in
`/epics/support`. The order also sets the order of `dbd_list`, and the IOC
link needs each DBD file after the DBD files it depends on. See
{any}`dbd-order`.
:::

(generic-ioc-release-submodule)=
## Publish the Generic IOC

Commit your `ibek-support` recipe to your fork's `main` branch, then commit
the IOC project, which records the new submodule commit, and push both:

```bash
cd /workspaces/ioc-adsim-demo/ibek-support
git add .
git commit -m "re-author ADSimDetector support module"
git push origin main

cd ..
git add .
git commit -m "add ADSimDetector tutorial version"
git push   # a tutorial may push to main; real projects use a PR
```

:::{important}
A full release tag fails CI unless the `ibek-support` submodule commit is on
the default branch of the submodule's `origin`, the URL in `.gitmodules`. The
image records only that commit, so it must stay reachable for anyone to rebuild
the image from its source. That is why the tutorial commits the recipe on your
fork's `main`.

For a real Generic IOC, open a pull request with the recipe at
[ibek-support](https://github.com/epics-containers/ibek-support), so that other
Generic IOCs can use it too. While it is under review, publish pre-release tags
such as `2.11ec1b1`: CI skips the check for them, and does not tag the
developer image `latest`. Once the pull request is merged, point the submodule
back at `ibek-support` and move it to a commit on its `main`:

```bash
cd /workspaces/ioc-xxx
git submodule set-url ibek-support https://github.com/epics-containers/ibek-support.git
cd ibek-support
git fetch origin
git checkout origin/main
cd ..
git add .gitmodules ibek-support
git commit -m "use the merged ibek-support recipe"
```

Then make the full release.
:::

:::{note}
### Version naming convention for ioc-xxx generic IOC releases.

We use `2.11ec1` below meaning that the primary support module inside this
generic IOC is `2.11` (i.e. ADSimDetector Support module version). With
`ec1` meaning this is the first epics-containers generic IOC published
against that support module version.

A generic IOC with no clear primary support module is tagged with the date
instead, e.g. `2026.9.1` meaning the first release of September 2026.
:::

The push triggers a CI image build (watch the **Actions** tab). To *publish* to
GHCR, cut a release: on the repo's **Releases** tab choose **Create a new
release**, pick a tag such as `2.11ec1`, click **Generate release notes**, then
**Publish release**.



:::{figure} ../images/simDetActions.png
The `build.yml` workflow running on the `ioc-adsim-demo` **Actions** tab after
the push — the matrix `build` job compiles the image, then the `release` job
publishes it.
:::

CI then builds and pushes the image, which appears under the repo's
**Packages** as `ghcr.io/<org>/ioc-adsim-demo-runtime`. A full release also
tags the developer image `ghcr.io/<org>/ioc-adsim-demo-developer` as `latest`,
which the devcontainer pulls from then on.

:::{figure} ../images/simDetRelease.png
The resulting `2.11ec1` release for `ioc-adsim-demo`, with the published
`ibek.ioc.schema.json` schema attached as a release asset.
:::

:::{note}
If the `release` job fails with `Resource not accessible by integration`, go to
Settings -> Actions -> General -> Workflow Permissions and select **Read and
write permissions**.
:::

## Next steps

You now have a published `ioc-adsim-demo` image.

- {any}`custom_pattern` — author your *own* runtime support pattern (the
  runtime-vendoring mirror of the build-time work you just did here).
- As an exercise, add an instance that uses this image to your `bl01t` beamline
  and run it with `docker compose up -d` (see {any}`deploy-example-instance`).
