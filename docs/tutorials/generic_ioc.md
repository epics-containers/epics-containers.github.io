# Create a Generic IOC

In this tutorial you build a **Generic IOC**: a container image that wraps an
EPICS support module so that IOC *instances* can be created from it with nothing
but a YAML file. You will also embed an example instance for testing.

This is a *type 2* change from {any}`ioc-change-types`.

The worked example wraps the **Lakeshore 340** temperature controller, a
StreamDevice support module. Substitute your own device and support module
throughout. By convention a Generic IOC repository is named `ioc-<module>`, so
here we build **`ioc-lakeshore340`**.

## Publish the support module

epics-containers builds support straight from public git repositories, so the
first step is to make sure your support module is published and builds with a
standard EPICS layout. The
[Lakeshore 340](https://www.lakeshore.com/products/categories/overview/discontinued-products/discontinued-products/model-340-cryogenic-temperature-controller)
module now lives at <https://github.com/DiamondLightSource/lakeshore340>;
genericizing it required:

- an Apache V2 `LICENSE` file in the root;
- a `RELEASE.local` include at the end of `configure/RELEASE`;
- a Makefile tweak to skip the DLS-specific `etc` folder.

See the [commit](https://github.com/DiamondLightSource/lakeshore340/commit/0ff410a3e1131c96078837424b2dfcdb4af2c356)
where these changes were made.

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
GitHub repository named `ioc-lakeshore340` at <https://github.com/new>, then
generate the project into it (if you do not have `copier`, see {any}`copier`):

```bash
# creates the folder ioc-lakeshore340 in the current directory
copier copy https://github.com/epics-containers/ioc-template --trust ioc-lakeshore340
```

Answer the prompts:

| Prompt | Worked-example answer |
|---|---|
| A name for this project (starts `ioc-`) | `ioc-lakeshore340` |
| A one line description of the module | `Generic IOC for the Lakeshore 340` |
| Git platform hosting the repository | `github.com` |
| The GitHub organisation that will contain this repo | *your GitHub account or org* |
| Remote URI of the repository | *(accept the default)* |

Accept the defaults for any remaining prompts. Then make the first commit and
push:

```bash
cd ioc-lakeshore340
git add .
git commit -m "initial commit"
git push -u origin main
```

Pushing triggers a GitHub Actions build of the (still empty) Generic IOC. It is
not published — there is no release tag yet — but it primes the build cache so
your later builds are fast. Watch it under the **Actions** tab.

Finally open the project and launch its developer container, where all the work
below happens:

```bash
cd ioc-lakeshore340
code .
# then Ctrl-Shift-P -> "Dev Containers: Reopen in Container"
```

:::{note}
DLS users: run `module load vscode` before `code .`, and start podman with
`source /dls_sw/apps/setup-podman/setup.sh`.
:::

## What you need to change

The template is mostly boilerplate. For a typical Generic IOC you touch only
three things:

1. **`Dockerfile`** — add the support modules you need.
2. **`README.md`** — describe your Generic IOC.
3. **`ibek-support`** — add build recipes and support definitions for new
   modules (a git submodule, covered below).

Advanced IOCs may customise more — for example `ioc-adaravis` overrides
`start.sh` to interrogate its cameras at startup — but you rarely need to.

## Add support modules to the Dockerfile

The `Dockerfile` builds the container image. Its `FROM` line pulls an
epics-containers developer base image, then a few common modules are built in:

```dockerfile
COPY ibek-support/iocStats/ iocStats
RUN ansible.sh iocStats

COPY ibek-support/pvlogging/ pvlogging/
RUN ansible.sh pvlogging

COPY ibek-support/autosave/ autosave
RUN ansible.sh autosave
```

Each module is built by copying its `ibek-support/<module>` folder and running
`ansible.sh <module>`. That script applies an `ibek-support` *recipe* that clones
the module from upstream, builds it with standard EPICS steps, and records its
dbds and libs for the IOC link. Add `-v <version>` to override the tested default
version, e.g. `ansible.sh -v R4-45 asyn`.

lakeshore340 is a StreamDevice, so it needs `asyn` and `StreamDevice`. Build them
in your running devcontainer first (Terminal -> New Terminal):

```bash
ansible.sh asyn
ansible.sh StreamDevice
```

They now exist under `/epics/support`. Make the next image build include them by
adding matching lines to the `Dockerfile`:

```dockerfile
COPY ibek-support/asyn/ asyn/
RUN ansible.sh asyn

COPY ibek-support/StreamDevice/ StreamDevice/
RUN ansible.sh StreamDevice
```

:::{note}
This is the core devcontainer workflow: try something live, then make it
permanent by adding the same command to the `Dockerfile`. The per-module
`COPY`/`RUN` pairs look repetitive, but they maximise the build cache hit rate —
editing one recipe does not force every module to rebuild. You can also build the
image outside VSCode with `./build`.
:::

## Fork the ibek-support submodule

New modules need recipes, which live in `ibek-support` — a submodule shared by
all `ioc-*` projects. It is curated, so you work from a fork (open a pull request
later if your recipe is generally useful).

- Fork it at <https://github.com/epics-containers/ibek-support/fork> (untick
  *Copy the main branch only*).
- Copy the fork's **HTTPS** *Code* URL and point the submodule at it:

```bash
cd /workspaces/ioc-lakeshore340
git submodule set-url ibek-support <YOUR FORK HTTPS URL>
git submodule update
cd ibek-support
git fetch
git checkout tutorial-KEEP   # snapshot for this tutorial; see note
git remote -v                # confirm origin is your fork
cd ..
```

:::{note}
`tutorial-KEEP` is a frozen snapshot so this tutorial is reproducible. For real
work, branch off `main` instead: `git checkout main`, then
`git checkout -b my-feature && git push -u origin my-feature`.
:::

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

## Add a build recipe

A recipe is a `<module>.install.yml` file that drives `ansible.sh`. Create one
for lakeshore340:

```bash
cd /workspaces/ioc-lakeshore340/ibek-support
mkdir lakeshore340
code lakeshore340/lakeshore340.install.yml
```

```yaml
# yaml-language-server: $schema=../_scripts/support_install_variables.json
module: lakeshore340
version: 2-6-4
organization: https://github.com/DiamondLightSource/

protocol_files:
  - lakeshore340App/protocol/lakeshore340.proto

comment_out:
  - path: Makefile
    regexp: documentation
```

The keys are minimal:

- **module** — the upstream repo name (and the folder under `/epics/support`).
- **version** — the upstream tag to build. Use a recent one; `ibek-support` CI
  builds every module to confirm the set works together.
- **organization** — URL prefix of the repo. Defaults to
  `https://github.com/epics-modules`.
- **protocol_files** — StreamDevice `.proto` files to copy into the runtime
  protocol search path.
- **comment_out** — regex of Makefile lines to drop (here, the docs build).

The schema on the first line gives auto-completion and validation in VSCode (via
the Red Hat YAML extension). Every available key is listed in
`ibek-support/_ansible/roles/support/vars/main.yml`.

Build it, then add it to the `Dockerfile`:

```bash
ansible.sh lakeshore340
```

```dockerfile
COPY ibek-support/lakeshore340/ lakeshore340/
RUN ansible.sh lakeshore340
```

## Add a support definition

The recipe builds the *binary*; a **support definition** lets instances describe
themselves in YAML instead of hand-writing `st.cmd` and `ioc.subst`. (You can
still supply those files by hand — the Generic IOC accepts both.) Defining
parameters in YAML means a schema-aware editor validates each instance as you
type it, and your services repo's CI re-checks it on push.

In the same folder create `lakeshore340.ibek.support.yaml`:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ibek/releases/download/3.0.1/ibek.support.schema.json

module: lakeshore340

entity_models:
  - name: lakeshore340
    description: Lakeshore 340 Temperature Controller
    parameters:
      P:
        type: str
        description: Prefix for PV name
      PORT:
        type: str
        description: Asyn port name
      ADDR:
        type: int
        description: Address on the bus
        default: 0
      SCAN:
        type: int
        description: SCAN rate for non-temperature parameters
        default: 5
      TEMPSCAN:
        type: int
        description: SCAN rate for temperature/voltage readings
        default: 5
      name:
        type: id
        description: Object and GUI association name
      LOOP:
        type: int
        description: Heater PID loop to control
        default: 1

    databases:
      - file: $(LAKESHORE340)/db/lakeshore340.template
        # pass every instance parameter straight to the template
        args:
          .*:
```

Each `entity_model` declares the parameters an instance may set, the database
templates to instantiate, and any iocShell lines to add. Values are Jinja
templates, so you can combine parameters — e.g. a richer PV prefix:

```yaml
args:
  P: "{{ P + ':' + name + ':' }}"
```

:::{important}
The file **must** end in `.ibek.support.yaml`. `ansible.sh` symlinks it into
`/epics/ibek-defs`, where `ibek` collects every support definition into the
schema used to validate instances. Re-run `ansible.sh` to register it (it is
idempotent, so re-running is safe):

```bash
ansible.sh lakeshore340
```
:::

We have added new support since the IOC binary was last built, so rebuild it:

```bash
cd /epics/ioc
make
```

:::{note}
**DLS users:** a DLS module carries an `etc/builder.py` for the legacy XML
Builder. `ibek` can convert it into a support definition, but only at DLS (it
needs the DLS support forks). See the dev-guide
[convert-ioc how-to](https://dev-guide.diamond.ac.uk/epics-containers/how-tos/convert-ioc.html).
:::

## Test with an example instance

To exercise the Generic IOC you need an instance. The template ships one at
`tests/config/ioc.yaml` — a great place to embed an example that doubles as a CI
smoke test. Most real devices need a simulator to stand in for the hardware.

First generate a schema for *this* Generic IOC so your editor can validate the
instance; it covers your new lakeshore340 model plus every other module in the
container:

```bash
ibek ioc generate-schema > /tmp/ibek.ioc.schema.json
```

Once the repo is released, the same schema is published with it at
`https://github.com/<org>/ioc-lakeshore340/releases/download/<tag>/ibek.ioc.schema.json`,
which is what real instances reference.

Replace `tests/config/ioc.yaml` with a lakeshore example:

```yaml
# yaml-language-server: $schema=/tmp/ibek.ioc.schema.json

ioc_name: "{{ ioc_yaml_file_name }}"

description: example IOC for testing lakeshore340

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: asyn.AsynIP
    name: p1
    port: 127.0.0.1:5401

  - type: lakeshore340.lakeshore340
    P: BL01T-EA-TEMP-01
    PORT: p1
    ADDR: 12
    SCAN: 5
    TEMPSCAN: 2
    LOOP: 2
    name: lakeshore
```

This instance sets the timezone, adds devIocStats monitoring PVs, opens an asyn
IP port to the simulator, and creates the lakeshore340 device on that port.

Start the simulator in one terminal:

```bash
cd /epics/support/lakeshore340/etc/simulations/
./lakeshore340_sim.py
```

In a second terminal, link the instance in, build and run it:

```bash
ibek dev instance /workspaces/ioc-lakeshore340/tests
cd /epics/ioc
make
./start.sh
```

The IOC should start and connect to the simulator, which logs the queries it
receives. To iterate on the instance you do **not** need to rebuild the binary —
edit `tests/config/ioc.yaml`, stop the IOC with `Ctrl-D`, and run `./start.sh`
again. (Rebuild with `make` only after changing the *set of support modules*.)

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
cd /workspaces/ioc-lakeshore340/ibek-support
git checkout -b add-lakeshore340
git add .
git commit -m "add lakeshore340 support module"
git push -u origin add-lakeshore340

cd ..
git add .
git commit -m "add lakeshore340 support and dependencies"
git push   # a tutorial may push to main; real projects use a PR
```

The push triggers a CI image build (watch the **Actions** tab). To *publish* to
GHCR, cut a release: on the repo's **Releases** tab choose **Create a new
release**, pick a tag such as `0.1.0`, click **Generate release notes**, then
**Publish release**.

:::{figure} ../images/lakeshore_releases.png
Create a new release on GitHub
:::

CI then builds and pushes the image, which appears under the repo's
**Packages**.

:::{note}
If the `release` job fails with `Resource not accessible by integration`, go to
Settings -> Actions -> General -> Workflow Permissions and select **Read and
write permissions**.
:::

## Next steps

You now have a published `ioc-lakeshore340` image. As an exercise, add an
instance that uses it to your `bl01t` beamline and run it with
`docker compose up -d` (see {any}`deploy-example-instance`) — and try running a
local simulator for it to talk to.
