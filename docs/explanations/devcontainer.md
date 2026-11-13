(ioc-source)=
(devcontainer-flow)=

# How a Generic IOC Developer Container Works

This page explains what happens when you open a Generic IOC project in its
developer container, what the container holds, and how it is kept in line with
the project folder on your host. The tutorial [](../tutorials/dev_container.md) shows
the same steps in use.

## Developer container and runtime container

Every Generic IOC image is built in two targets from the project's
`Dockerfile`:

- the **developer** target holds the build tools, the compiled support modules
  and the compiled IOC. It is the image the developer container runs.
- the **runtime** target holds only what the IOC needs to run, copied from the
  developer target. It is the image that IOC instances deploy.

The developer container is where you work on a Generic IOC and its support
modules. It mounts host folders into the container so that:

- the developer container looks as similar as possible to the runtime
  container;
- you can change things and recompile them without building a new image;
- the work you keep happens in the host filesystem, so it is not lost when the
  container is rebuilt or deleted.

## The developer image

The developer container runs a published image rather than building one when
it opens. `.devcontainer/devcontainer.json` names it:

| Git platform | Developer image |
|---|---|
| GitHub | `ghcr.io/<org>/<repo>-developer:latest` |
| DLS GitLab | `gitlab.diamond.ac.uk:5050/controls/containers/iocs/<repo>/<repo>-linux-developer:latest` |

`.devcontainer/initializeCommand` names the same image. A repository that
changes one must change the other.

When CI builds a full release tag, such as `2.11ec1`, it also gives that
release's developer image the tag `latest`. A pre-release tag,
such as `2.11ec1b1`, does not move `latest`, and the runtime image never has a
`latest` tag. So:

- the image is the one built from the full release tag pushed most recently,
  which is usually the latest release. Changes merged
  to main since that release are not in it: `ibek dev sync` reports each
  difference (see [](devcontainer-drift));
- a repository that has made no full release has no `latest`, so the first
  start builds the image locally (see [](devcontainer-open)).

To pull from the DLS GitLab registry the host must be logged in to it, with
`podman login gitlab.diamond.ac.uk:5050` (or `docker login`). Without a login
the pull fails, and the image is the local one, or a local build when there is
none (see [](devcontainer-open)).

(devcontainer-open)=

## What happens when the container opens

When you choose **Reopen in Container**, VSCode runs
`.devcontainer/initializeCommand` on the host. It:

1. creates the host folders that the container mounts:
   `$HOME/.config/terminal-config`, `$HOME/.cache/uv` and the project's
   `opi/auto-generated`;
2. runs `git submodule update --init` when the `ibek-support` submodule is not
   checked out, which is the case in a fresh clone made without
   `--recursive` (see [](devcontainer-submodule));
3. gets the developer image, in this order:
   - when the marker file `.devcontainer/local-build` exists, it builds the
     image from the project folder with `./build`
     (see [](devcontainer-local-build));
   - otherwise it pulls the image;
   - when the pull fails, it uses the local image of that name;
   - when there is no local image either, it builds one with `./build`;
4. records the ID of that image in `.devcontainer/image-id`, and prints a
   WARNING when an existing container for this project was created from a
   different image (see [](devcontainer-reopen)).

It prints one coloured line that says which way it got the image. It uses
docker when docker works, and podman otherwise or when `USE_PODMAN` is set, as
`./build` does.

VSCode then starts the container. A container being created for the first
time also runs `.devcontainer/postCreateCommand`, which removes the IOC build
products from the project's `ioc` folder (see [](devcontainer-ioc-folder)) and
records which image the container was created from. On every start, including
the first, the container runs `ibek dev sync`, which brings the container in
line with the project folder (see [](devcontainer-drift)).

(devcontainer-local-build)=

### Building the image locally

To run an image built from your own project folder instead of the published
one, for example after changing the `Dockerfile`, or on a branch far from the
last release, create the marker file on the host and then use
**Dev Containers: Rebuild Container**:

```bash
# on the host, in the project folder
touch .devcontainer/local-build
```

While that file exists, every start builds the image with `./build` instead of
pulling it. The build is quick when its layers are cached. It gives the image
the same name as the published one, so the container runs it in the same way.
The file's content is ignored and git ignores the file. Delete it to go back
to the published image.

A repository with no full release builds its image locally the first time, as
above. Later starts cannot pull either, so they use that local image as it is,
even after the `Dockerfile` changes. Create the marker file to build it again.

`./build` builds the image from the project folder and leaves the folder as it
is, apart from checking out the `ibek-support` submodule when it is missing.
`.dockerignore` keeps the IOC build products and the `ioc/config` link out of
the image.

## What is mounted where

The developer container mounts the parent of the project folder at
`/workspaces`, so the project and all its peers, such as your services repo,
are in the container. It also mounts the project folder a second time, at
`/epics/generic-source`. The image build copies the project's source to that
same path, so the source is found in the same place in the developer container
and in the runtime container. In the developer container the mount hides the
image's copy: what you see at `/epics/generic-source` is your host project
folder.

The rest of `/epics` belongs to the image:

- `/epics/support` holds the support modules, cloned and compiled when the
  image was built.
- `/epics/ibek-defs`, `/epics/pvi-defs` and `/epics/autosave` hold one symbolic
  link per definition file: the `*.ibek.support.yaml`, `*.pvi.device.yaml` and
  `*.req` files of each support module. Each link points into
  `/epics/generic-source/ibek-support*/<module>/`, so in the developer
  container it resolves to your host checkout of `ibek-support`.
  `/epics/ibek-defs` also holds `ioc.schema.json`, the IOC schema generated
  from those files.
- `/epics/ioc` is a link to `/epics/generic-source/ioc`.

The tutorial's [](container-layout) table lists every mount.

:::{important}
What is in the image, such as `/epics/support`, lives in the container's own
filesystem. Changes there are lost when the container is rebuilt or deleted.
Keep the work you want in the host folders.
:::

(devcontainer-ioc-folder)=

## The ioc folder

The `ioc` folder of the project holds the Generic IOC source. It is much the
same for every Generic IOC, but each project has its own copy so that it can be
changed when needed. The image build compiles it, so the runtime image has the
IOC binary.

In the developer container `/epics/ioc` resolves to the `ioc` folder of your
host project, which holds the source only: the binary that the image build
compiled is hidden. So you build the IOC in the container:

```bash
# in the container
cd /epics/ioc
make
```

What `make` builds lands in the host project folder, and it is linked against
the support modules of the container that built it. A container from a
different image may have different support modules, so when a container is
created, `.devcontainer/postCreateCommand` removes the build products from the
`ioc` folder: `bin`, `lib`, `dbd`, `db` and every `O.*` folder. It keeps all
source files, and the `ioc/config` link that `ibek dev instance` makes.
Reopening an existing container keeps its build products, which still match
it.

Your changes to the IOC source are in the host project folder, so they are
under version control and survive the container.

(devcontainer-drift)=

## Keeping the container in line with the project

The image was built from the project as it was at that time. Your host project
folder may differ from it: you may have pulled changes merged since the last
release, edited a support module's definition files, or changed the
`Dockerfile`. As the last step of the image build, `ibek dev stamp` records
what the image was built from in `/epics/dev-stamp.json`. The `ibek dev`
commands compare that record with the project folder mounted at
`/epics/generic-source`:

| Command | What it does |
|---|---|
| `ibek dev status` | prints the comparison and changes nothing |
| `ibek dev sync` | fixes what needs no build and reports the rest. The container runs it on every start |
| `ibek dev sync --build` | also rebuilds what needs a build |
| `ibek dev instance <folder>` | links an IOC instance's config folder to `/epics/ioc/config`, then prints the comparison |

Each part of the report names the command that fixes it, where there is one.
What is compared:

| What changed in the project | `ibek dev sync` | `ibek dev sync --build` |
|---|---|---|
| A support module's definition files: `*.ibek.support.yaml`, `*.pvi.device.yaml`, `*.req` | Fixes it: links the files again, removes links that point at nothing, and regenerates `ioc.schema.json` | The same |
| A support module's other files in `ibek-support`, such as its `install.yml`, or its `RUN ansible.sh` line in the `Dockerfile` | Reports it | Rebuilds that module and every module after it in the `Dockerfile`, then the IOC |
| What a module clones: the version, repository or patch in its `install.yml` | Reports it, and names the folder that a rebuild removes | Removes `/epics/support/<module>` and clones it again, discarding any edits in that folder, then rebuilds as above |
| The list of `RUN ansible.sh` lines in the `Dockerfile` | Reports it | Rebuilds from the first place where the list differs, then the IOC. A removed module stays installed, and reported, until the container is created from an image built without it |
| `ibek-support/_ansible` | Reports it | Rebuilds every module, then the IOC |
| `requirements.txt` | Reports it | Upgrades the Python packages and regenerates the schema, then stops: run it again for anything more |
| The `Dockerfile`'s `ARG` and `FROM` lines (the base image) | Reports it | Reports it: pull a newer developer image, or build one locally |
| The IOC binary: missing, older than the IOC source, or older than the last module rebuild | Reports it: run `make` in `/epics/ioc` | Builds the IOC |

`ibek dev sync` never compiles anything. Its output on container start is easy
to miss, so run `ibek dev status` when you want to see where the container
stands.

What `ibek dev sync --build` rebuilds lives in the container's own filesystem.
A container created again starts from the image, so run it again there if
`ibek dev status` asks for it.

An image built without `ibek dev stamp` has nothing to compare: the commands
say so in one line.

(devcontainer-reopen)=

## Reopen and Rebuild

VSCode keeps a project's container between sessions. The two commands that
open the project differ:

- **Reopen in Container** starts the existing container if there is one. It
  stays on the image it was created from, and keeps everything in its own
  filesystem.
- **Dev Containers: Rebuild Container** deletes the container and creates
  another from the image that `.devcontainer/initializeCommand` has just
  pulled or built. Changes to the container's own filesystem are lost, and the
  IOC build products are removed.

So a newer image that `initializeCommand` pulls takes effect only after
**Rebuild Container**. While the existing container was created from a
different image, two warnings say so: `.devcontainer/initializeCommand` prints
one in yellow on the host as the container opens, and the `ibek dev` commands
print one in the container. Both start `WARNING:` and both are cleared by
**Dev Containers: Rebuild Container**.

(devcontainer-submodule)=

## The ibek-support submodule

The `ibek-support` submodule holds the build recipes and definition files of
the support modules. `.devcontainer/initializeCommand` and `./build` check it
out only when it is not checked out at all. Once it is, they leave it alone,
so a branch or commit you have checked out in it stays as it is.

After a `git pull` that moves the project's `ibek-support` commit, update the
submodule yourself:

```bash
# on the host, in the project folder
git submodule update
```

Then run `ibek dev sync` in the container, which fixes or reports what the
move changed (it also runs on every container start), and `ibek dev status` to
see what is left.

## Working on a support module

Changing the source of a support module, rather than its `ibek-support`
recipe, is covered by `ibek dev support`.

:::{admonition} To be written
:class: note

This section will describe `ibek dev support`.
:::

(devcontainer-template-version)=

## Generic IOCs from earlier templates

A Generic IOC generated from a version of
[ioc-template](https://github.com/epics-containers/ioc-template) below 5.1.0
works differently. Its `.devcontainer/devcontainer.json` has a `build` block
in place of an `image`, so VSCode builds the `developer` target from the
project's `Dockerfile` when it creates the container, and the `ibek dev sync`
checks above do not run. epics-containers builds all support from source, so
building something as large as AreaDetector takes a few minutes the first
time; the layers are cached, so later builds are quick up to the first line
that changed. The `_commit` line of the project's
`.copier-answers.yml` shows the template version. To move the project to the
published-image flow, update it from the template (see
[](../how-to/copier_update.md)).

## Summing up

For the most part you can ignore the details and remember:

- **Reopen in Container** to carry on; **Dev Containers: Rebuild Container**
  when a WARNING asks for it, or to move to a newer image;
- run `make` in `/epics/ioc` to build the IOC, and `./start.sh` there to run
  it;
- run `ibek dev status` to see how the container differs from the project, and
  `ibek dev sync --build` when it asks for a rebuild;
- your changes to the project folder are on the host and under version
  control.
