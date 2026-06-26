# Developer Containers

So far you have only changed *IOC instance* configuration, which needs no
compiler. To change what is *built into* a Generic IOC you need build tools and
system dependencies — and the Generic IOC's own **developer image** already has
them. This tutorial uses that image as a VSCode *developer container*: you build
the IOC and run it against an instance from your services repo, testing changes
locally with no build-and-publish round trip.

The worked example uses the public `ioc-adsimdetector` Generic IOC and the
`bl01t-ea-cam-01` instance you created in earlier tutorials. Substitute your own
names throughout.

(ioc-change-types)=

## Types of change

A containerized IOC can be modified in three places, in order of increasing
effort:

(changes_1)=

### 1. Change the IOC instance

Edit the instance configuration in your {any}`services-repo` — the EPICS
database, the `ibek` `ioc.yaml`, the Generic IOC version it points at, or the
shared chart/compose settings. No compilation is involved, because you only
change *configuration*, not the IOC binary. Re-launch the IOC to apply it
(`docker compose restart <ioc-name>` for compose, or redeploy for Kubernetes).

(changes_2)=

### 2. Change the Generic IOC

Alter the Generic IOC container image itself: change the EPICS base version, add
or upgrade support modules compiled into the binary, or change the system
packages installed. This requires:

- editing the Generic IOC `Dockerfile` (covered in {any}`generic_ioc`);
- pushing and tagging the repo, so CI builds and publishes a new image;
- pointing the instance at the new image and redeploying it.

(changes_3)=

### 3. Change the dependencies

Sometimes you must change a *support module* itself — to support a new device,
add a feature, or fix a bug. This requires changing the support module source,
releasing it, then repeating the steps in [](changes_2) to rebuild the Generic
IOC against the new release.

The developer container lets you test all three kinds of change *before*
publishing anything, giving a fast inner loop. Type-1 changes needed only a
container platform, an IDE and Python. Types 2 and 3 need compilers and
build-time dependencies — which differ from one Generic IOC to the next, and
which we deliberately never install on the host.

## Why the Generic IOC is its own developer container

CI builds every Generic IOC in two
[targets](https://github.com/orgs/epics-containers/packages?repo_name=ioc-adsimdetector):

| target | contents |
|---|---|
| **developer** | all build tools and build-time dependencies, plus the compiled support modules and IOC source. |
| **runtime** | only runtime dependencies, with the built assets copied in from the developer target. |

The `developer` target is a necessary build stage, and it already contains
everything you could want to change inside a Generic IOC plus the tools to build
it. So we reuse it directly as a developer container — the Generic IOC *is* your
developer environment.

:::{note}
This tutorial uses VSCode, which has first-class developer-container support.
Any container-aware IDE works, and for terminal editors such as `neovim` you can
launch the same container from the
[devcontainer CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)
— it reads the host mounts and other settings from
`.devcontainer/devcontainer.json`, so always start it that way rather than by
hand.
:::

## Fetch a Generic IOC

First make sure no IOCs are left running from an earlier tutorial:

```bash
podman stop $(podman ps -q)
```

Clone the Generic IOC source as a **peer** of your services repo, so both appear
side by side under `/workspaces` inside the container:

```bash
# run this next to your t01-services folder
git clone --recursive https://github.com/epics-containers/ioc-adsimdetector.git
```

:::{warning}
Use `--recursive` to fetch the `ibek-support` submodule — it tells `ibek` how to
build and use each support module, and the container build fails without it. If
you forget, run `git submodule update --init`.
:::

## Launch the developer container

Open the project in VSCode:

```bash
cd ioc-adsimdetector
code .
```

When prompted, choose to reopen in the container (or `Ctrl-Shift-P` →
`Reopen in Container`). The first time, VSCode builds the `developer` target
from the project `Dockerfile`, guided by `.devcontainer/devcontainer.json`.
Because epics-containers builds all support from source to avoid dependency-tree
problems, building something as large as AreaDetector takes a few minutes the
first time; the layers are cached, so rebuilds are near-instant up to whatever
line you changed.

Once it finishes you are **inside** the container: every VSCode terminal and
editor runs in the container filesystem. A few host folders are mounted in so
your work survives a rebuild — most importantly the project itself, mounted at
`/epics/generic-source`. See [](container-layout) for the full map.

## Build and run the Generic IOC

Open a terminal (`Terminal → New Terminal`) and build the IOC:

```bash
cd /epics/ioc
make
```

The IOC source is boilerplate: `iocApp/src/Makefile` links the dbd and lib files
that `ibek` listed in `/epics/support/configure/dbd_list` and `lib_list` during
the image build. You may change it if you need different compile options.

:::{note}
`make` may warn about unsupported locale settings. These are benign.
:::

Now run it with the standard entry point:

```bash
./start.sh
```

You will see an error, and that is expected:

```text
+ /epics/ioc/bin/linux-x86_64/ioc /epics/runtime/st.cmd
Can't open /epics/runtime/st.cmd: No such file or directory
epics>
```

This is a purely **generic** IOC with no database or startup script, because you
have not given it any instance configuration yet. A Generic IOC is configured at
runtime from an IOC instance — which you will supply next. Press `Ctrl-D` to
exit the IOC shell.

(container-layout)=

## Generic IOC container filesystem layout

The devcontainer mounts the parent of your project as `/workspaces`, so all
peer repos (such as `t01-services`) are visible inside the container — use
`File → Add Folder to Workspace` and pick from `/workspaces` to browse them in
the Explorer. The most useful paths are:

| Path inside container | Host mount | Description |
|---|---|---|
| `/epics/generic-source` | `${localWorkspaceFolder}` | Generic IOC source repo (fixed mount so `ibek` finds it) |
| `/epics/ioc` | → `/epics/generic-source/ioc` | IOC source tree (symlink into the mount) |
| `/epics/opi` | `${localWorkspaceFolder}/opi/auto-generated` | auto-generated OPI screens (not in git) |
| `/workspaces` | `${localWorkspaceFolder}/..` | all peers of the Generic IOC repo |
| `/epics/support` | *(container only)* | compiled support modules |
| `/epics/epics-base` | *(container only)* | compiled EPICS base |
| `/epics/runtime` | *(container only)* | generated `st.cmd` and EPICS database |
| `/epics/ibek-defs` | *(container only)* | all `ibek` *Support YAML* files |
| `/epics/pvi-defs` | *(container only)* | all PVI definitions from support modules |

`${localWorkspaceFolder}` is the root of the Generic IOC source repo — the
directory that holds `.devcontainer/devcontainer.json`.

:::{important}
Paths marked *container only* live in the **temporary** container filesystem and
are lost when the container is rebuilt or deleted — including all the support
modules. VSCode keeps your container across PC restarts, which makes this easy to
forget, so treat anything outside a host mount as disposable. A later tutorial
shows how to bring support modules out into the host filesystem to work on them.
:::

(choose-ioc-instance)=

## Choose the IOC instance to test

To test the Generic IOC meaningfully, point it at one of your IOC instances. The
`ibek dev instance` convenience symlinks an instance's `config/` folder into
`/epics/ioc/config`:

```bash
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01

# confirm the symlink, then start the IOC
cd /epics/ioc
ls -l config
./start.sh
```

The IOC now starts with the instance's configuration and drops you at the
`epics>` prompt with real records. Because `config` is a *symlink* into the
beamline repo, edits you make are already in place there — change the config,
restart, and re-test without leaving the container.

:::{note}
If you followed earlier tutorials, switch back to the branch where you created
`bl01t-ea-cam-01` before running the command above.
:::

## Wrapping up

You now have one workspace for working on the Generic IOC, its IOC instances and
even its support modules, with no build-and-publish cycle between edit and test.
The following tutorials use this environment to make changes at each of the
three levels in {any}`ioc-change-types`.
