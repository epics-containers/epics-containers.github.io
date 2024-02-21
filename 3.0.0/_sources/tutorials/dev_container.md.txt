# Developer Containers

(ioc-change-types)=

## Types of Changes

Containerized IOCs can be modified in 3 distinct places (in order of decreasing
frequency of change but increasing complexity):

(changes_1)=
### Changing the IOC instance

This means making changes to the IOC instance folders
which appear in the `iocs` folder of an {any}`ec-services-repo`. e.g.:

- changing the EPICS DB (or the `ibek` files that generate it)
- altering the IOC boot script (or the `ibek` files that generate it)
- changing the version of the Generic IOC used in values.yaml
- for Kubernetes: the values.yaml can override any settings used by helm
  so these can also be adjusted on a per IOC instance basis.
- for Kubernetes: changes to the global values.yaml
  file found in `helm/shared`, these affect all IOCs in the repository.

(changes_2)=
### Changing the Generic IOC

This involves altering how the Generic IOC container image
is built. This means making changes to an `ioc-XXX`
source repo and publishing a new version of the container image.
Types of changes include:

   - changing the EPICS base version
   - changing the versions of EPICS support modules compiled into the IOC binary
   - adding new support modules
   - altering the system dependencies installed into the container image

(changes_3)=
### Changing the dependencies

Sometimes you will need to alter the support modules used by the Generic IOC. To make use of these changes would require:

- publishing a new release of the support module,
- updating and publishing the Generic IOC
- updating and publishing the IOC instance

## Need for a Developer Container

For all of the above types of changes, the epics-containers approach allows local testing of the changes before going through the publishing cycle. This allows us to have a fast 'inner loop' of development and testing.

Also, epics-containers provides a mechanism for creating a separate workspace for working on all of the above elements in one place.

The earlier tutorials were firmly in the realm of [](changes_1) above. It was adequate for us to install a container platform, IDE and python and that is all we needed.

Once you get to level of [](changes_2) you need to have compilers and build tools installed. You might also require system level dependencies. AreaDetector, that we used earlier has a long list of system dependencies that need to be installed in order to compile it. Traditionally we have installed all of these onto developer workstations or separately compiled the dependencies as part of the build.

These tools and dependencies will differ from one Generic IOC to the next.

When using epics-containers we don't need to install any of these tools or dependencies on our local machine. Instead we can use a developer container, and in fact our Generic IOC *is* our developer container.

When the CI builds a Generic IOC it creates [two targets](https://github.com/orgs/epics-containers/packages?repo_name=ioc-adsimdetector)

| | |
|---|---|
| **developer** | this target installs all the build tools and build time dependencies into the container image. It then compiles the support modules and IOC. |
| **runtime** | this target installs only the runtime dependencies into the container. It also extracts the built runtime assets from the developer target. |

The developer stage of the build is a necessary step in order to get a
working runtime container. However, we choose to keep this stage as an additional
build target and it then becomes a perfect candidate for a developer container.

VSCode has excellent support for using a container as a development environment.
The next section will show you how to use this feature. Note that you can use
any IDE that supports remote development in a container, you could also
simply launch the developer container in a shell and use it via CLI only.

If you want to use the CLI and terminal based editors like `neovim` then
you should use the developer container CLI to get your developer container
started. This means the configuration in `.devcontainer/devcontainer.json`
is used to start the container. This is necessary as that is where the
useful host filesystem mounts and other config items are defined. See
[devcontainer-cli](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)
for details.

## Starting a Developer Container

:::{Warning}
DLS Users and Redhat Users:

There is a
[bug in VSCode devcontainers extension](https://github.com/microsoft/vscode-remote-release/issues/8557)
at the time of writing that makes it incompatible with podman and an SELinux
enabled /tmp directory. This will affect most Redhat users and you will see an
error regarding permissions on the /tmp folder when VSCode is building your
devcontainer.

Here is a workaround that disables SELinux labels in podman.
Paste this into a terminal:

```bash
sed -i ~/.config/containers/containers.conf -e '/label=false/d' -e '/^\[containers\]$/a label=false'
```
:::

### Preparation

For this section we will work with the ADSimDetector Generic IOC that we used in
previous tutorials. Let's go and fetch a version of the Generic IOC source and
build it locally.

For the purposes of this tutorial we will place the source in a folder right
next to your test beamline `bl01t`:

```bash
# starting from folder bl01t so that the clone is next to bl01t
cd ..
git clone git@github.com:epics-containers/ioc-adsimdetector.git
cd ioc-adsimdetector
./build
```

This will take a few minutes to complete. A philosophy of epics-containers is
that Generic IOCs build all of their own support. This is to avoid problematic
dependency trees. For this reason building something as complex as AreaDetector
will take a few minutes when you first build it.

A nice thing about containers is that the build is cached so that a second build
will be almost instant unless you have changed something that requires some
steps to be rebuilt.

:::{note}
Before continuing this tutorial make sure you have not left the IOC
bl01t-ea-test-02 running from a previous tutorial. Execute this command
outside of the devcontainer to stop it:

```bash
ec stop bl01t-ea-test-02
```
:::

### Launching the Developer Container

In the this section we are going to use vscode to launch a developer container.
This means that all vscode terminals and editors will be running inside a container
and accessing the container filesystem. This is a very convenient way to work
because it makes it possible to archive away the development environment
along side the source code. It also means that you can easily share the
development environment with other developers.

For epics-containers the generic IOC *is* the developer container. When
you build the developer target of the container in CI it will contain all the
build tools and dependencies needed to build the IOC. It will also contain
the IOC source code and the support module source code. For this reason
we can also use the same developer target image to make the developer
container itself. We then have an environment that encompasses all the
source you could want to change inside of a Generic IOC, and the
tools to build and test it.

It is also important to understand that although your vscode session is
entirely inside the container, some of your host folders have been mounted
into the container. This is done so that your important changes to source
code would not be lost if the container were rebuilt. See [](container-layout)
for details of which host folders are mounted into the container.

Once built, open the project in VSCode:

```bash
code .
```

When it opens, VSCode may prompt you to open in a devcontainer. If not then click
the green icon in the bottom left of the VSCode window and select
`Reopen in Container`.

You should now be *inside* the container. All terminals started in VSCode will
be running inside the container. Every file that you open with the VSCode editor
will be inside the container.

There are some caveats because some folders are mounted from the host file
system. For example, the `ioc-adsimdetector` project folder
is mounted into the container as a volume. It is mounted under
`/workspaces/ioc-adsimdetector`. This means that you can edit the source code
from your local machine and the changes will be visible inside the container and
outside the container. This is a good thing as you should consider the container
filesystem to be a temporary filesystem that will be destroyed when the container
is rebuilt or deleted.

### Preparing the IOC for Testing

:::{note}
Troubleshooting: if you are experiencing problems with the devcontainer you
can try resetting your vscode and vscode server caches on your host machine.
To do this, exit vscode use the following command and restart vscode:

```bash
rm -rf ~/.vscode/* ~/.vscode-server/*
```
:::

Now that you are *inside* the container you have access to the tools built into
it, this includes `ibek`.

The first commands you should run are as follows:

```bash
# open a terminal: Menu -> Terminal -> New Terminal
cd /epics/ioc
make
```

It is useful to understand that `/epics/ioc` is a soft link to the IOC source that came with your generic IOC source code. Therefore if you edit this code and recompile it, the changes will be visible inside the container and outside the container. Meaning that the repository `ioc-adsimdetector` is now showing your changes in it's `ioc` folder and you could push them
up to GitHub if you wanted.

epics-containers devcontainers have carefully curated host filesystem mounts. This allows the developer environment to look as similar as possible to the runtime container. It also will preserve any important changes that you make in the host file system. This is essential because the container filesystem is temporary and will be destroyed when the container is rebuilt or deleted.

See [](container-layout) for details of which host folders are mounted into the container.

The IOC source code is entirely boilerplate, `/epics/ioc/iocApp/src/Makefile` determines which dbd and lib files to link by including two files that `ibek` generated during the container build. You can see these files in `/epics/support/configure/lib_list` and `/epics/support/configure/dbd_list`.

Although all Generic IOCs derived from ioc-template start out with the same generic source, you are free to change them if there is a need for different compilation options etc.

The Generic IOC should now be ready to run inside of the container. To do this:

```bash
cd /epics/ioc
./start.sh
```

You will just see the default output of a Generic IOC that has no Instance
configuration. Hit `Ctrl-C` to stop the this default script.

Next we will add some instance configuration from one of the
IOC instances in the `bl01t` beamline.

To do this we will add some other folders to our VSCode workspace to make it
easier to work with `bl01t` and to investigate the container filesystem.

## Adding the Beamline to the Workspace

To meaningfully test the Generic IOC we will need an instance to test it
against. We will use the `bl01t` beamline that you already made. The devcontainer
has been configured to mount some useful host folders into the container
including the parent folder of the workspace as `/workspaces` so we can work on
multiple peer projects.

In VSCode click the `File` menu and select `Add Folder to Workspace`.
Navigate to `/workspaces` and you will see all the peers of your `ioc-adsimdetector`
folder (see {any}`container-layout` below). Choose the `bl01t` folder and add it to the
workspace - you may see an error but if so clicking "Cancel" will
clear it.

Also take this opportunity to add the folder `/epics` to the workspace. This
is the root folder in which all of the EPICS source and built files are
located.

:::{note}
Docker Users: your account inside the container will not be the owner of
/epics files. vscode may try to open the repos in epics-base and support/\*
and git will complain about ownership. You can cancel out of these errors
as you should not edit project folders inside of `/epics` - they were
built by the container and should be considered immutable. We will learn
how to work on support modules in later tutorials. This error should only
be seen on first launch. podman users will have no such problem because they
will be root inside the container and root built the container.

To mitigate this problem you can tell vscode not to look for git repos in subfolders, see [](scm_settings).
:::

You can now easily browse around the `/epics` folder and see all the
support modules and epics-base. This will give you a feel for the layout of
files in the container. Here is a summary (where WS is your workspace on your
host. i.e. the root folder under which your projects are all cloned):

(container-layout)=

```{eval-rst}
.. list-table:: Developer Container Layout
   :widths: 25 35 45
   :header-rows: 1

   * - Path Inside Container
     - Host Mount Path
     - Description

   * - /epics/support
     - N/A
     - root of compiled support modules

   * - /epics/epics-base
     - N/A
     - compiled epics-base

   * - /epics/ioc
     - WS/ioc-adsimdetector/ioc
     - soft link to IOC source tree

   * - /epics/runtime
     - N/A
     - generated startup script and EPICS database files

   * - /epics/ibek-defs
     - N/A
     - All ibek *Support yaml* files

   * - /epics/pvi-defs
     - N/A
     - all PVI definitions from support modules

   * - /epics/opi
     - N/A
     - all OPI files (generated or copied from support)

   * - /workspaces
     - WS
     - all peers to Generic IOC source repo

   * - /workspaces/ioc-adsimdetector
     - WS/ioc-adsimdetector
     - Generic IOC source repo (in this example)

   * - /epics/generic-source
     - WS/ioc-adsimdetector
     - A second - fixed location mount of the Generic IOC source repo to allow `ibek` to find it easily.
```

IMPORTANT: remember that the container filesystem is temporary and will be
destroyed when the container is rebuilt or deleted. All folders above with
`Host Mount Path` `N/A` are in the container filesystem. The devcontainer
has been configured to mount the most useful host folders, but note that
all support modules are in the container filesystem. Later we will learn
how to work on support modules, first ensuring that they are made available
in the host filesystem.

Also note that VSCode keeps your developer container until you rebuild it
or explicitly delete it. Restarting your PC and coming back to the same
devcontainer does keep all state. This can make you complacent about doing
work in the container filesystem, but it is still not recommended.

(choose-ioc-instance)=

## Choose the IOC Instance to Test

Now that we have the beamline repo visible in our container we can easily supply some instance configuration to the Generic IOC. This will use the `ibek` tool convenience function `dev instance` which declares which IOC instance you want to work on in the developer container.

Try the following:

```
cd /epics/ioc
ibek dev instance /workspaces/bl01t/services/bl01t-ea-test-02
# check the it worked - should see a symlink to the config folder
ls -l config
./start.sh
```

This removed any existing config folder and replaced it with the config from the IOC instance bl01t-ea-test-02 by symlinking to that IOC Instance's config folder. Note that we used a soft link, this means we can edit the config, restart the IOC to test it and the changes will already be in place in the beamline repository. You could therefore open a shell onto the beamline repository at `/workspaces/bl01t` and commit and push the changes.

## Wrapping Up

We now have a tidy development environment for working on the Generic IOC,
IOC Instances and even the support modules inside the Generic IOC, all in one
place. We can easily test our changes in place too. In particular note that
we are able to test changes without having to go through a container build
cycle.

In the following tutorials we will look at how to make changes at each of the
3 levels listed in {any}`ioc-change-types`.
