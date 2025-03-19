# Developer Containers

(ioc-change-types)=

## Types of Changes

Containerized IOCs can be modified in 3 distinct places in order of decreasing frequency of change but increasing complexity:

(changes_1)=
### 1. Changing the IOC instance

This means making changes to the IOC instance folders which appear in the `services` folder of a {any}`services-repo`. e.g.:

- changing the EPICS DB (or the `ibek` files that generate it)
- altering the IOC boot script (or the `ibek` files that generate it)
- changing the version of the Generic IOC used
- changing any other configuration for the IOC instance i.e.
  - changes to compose.yml in the IOC instance folder
  - changes to any of the shared compose.yml files in the services repo
  - for Kubernetes IOCs the same is true except that the compose.yml is replaced by Helm Chart configuration files


To make a change like this requires:

- change the IOC instance ioc.yaml or other configuration files in the services repository
- re-launch the IOC with `docker compose restart <ioc-name>`
- that's it. No compilation required because we are only changing instance configuration here, not the IOC binary or dbd.

(changes_2)=
### 2. Changing the Generic IOC

This involves altering the Generic IOC container image. This means making changes to a Generic IOC source repo, building and publishing a new version of the container image.

Types of changes include:

   - changing the EPICS base version
   - changing the versions of EPICS support modules compiled into the IOC binary
   - adding new support modules
   - altering the system dependencies installed into the container image

To make a change like this requires:

- make changes to the Generic IOC Dockerfile (which holds the build instructions for a Generic IOC - we will discuss this in {any}`generic_ioc`)
- push the changes and tag the repo - this will build and publish a new container image using CI
- change the IOC instance in the services repo to point at the new container image
- redeploy the IOC with `docker compose restart <ioc-name>`


(changes_3)=
### 3. Changing the dependencies

Sometimes you will need to alter the support modules used by the Generic IOC. Reasons to do this include:

- developing a new support module for a new device
- fix a bug in a support module
- update to support a new version of the device
- update to support a feature of the device not yet implemented in the support module

To make a change like this would require:

- making the change in the support module source code
- test and publish a release of the above
- repeat the steps in [](changes_2)

## Need for a Developer Container

For all of the above types of changes, the epics-containers approach allows local testing of the changes before going through the publishing cycle. This allows us to have a fast 'inner loop' of development and testing.

Also, epics-containers provides a mechanism for creating a separate workspace for working on all of the above elements in one place.

The earlier tutorials were firmly in the realm of [](changes_1) above. It was adequate for us to install a container platform, IDE and python and that is all we needed.

Once you get to the level of [](changes_2) you need to have compilers and build tools installed. You might also require system level dependencies. AreaDetector, that we used earlier has a long list of system dependencies that need to be installed in order to compile it. Traditionally we have installed all of these onto developer workstations or separately compiled the dependencies as part of the build.

These tools and dependencies will likely differ from one Generic IOC to the next.

When using epics-containers we don't need to install any of these tools or dependencies on our local machine. Instead we can use a developer container, and in fact our Generic IOC *is* our developer container.

When the CI builds a Generic IOC it always creates [two targets](https://github.com/orgs/epics-containers/packages?repo_name=ioc-adsimdetector)

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

### Preparation

For this section we will work with the ADSimDetector Generic IOC that we used in previous tutorials. Let's go and fetch a version of the Generic IOC source and build it locally.

:::{note}
Before continuing this tutorial make sure you have not left any IOCs running from a previous tutorial. Execute this command outside of the devcontainer to stop it:

```bash
cd t01-services
. ./environment.sh
docker compose down
```

One issue with compose is that you must have the project available to use compose commands. If you have removed t01-services then you can stop all the services manually instead. To stop and remove all containers on your workstation use the following command:

```bash
docker stop $(docker ps -q)
```
:::



For the purposes of this tutorial we will place the source in a folder right
next to your test beamline `t01-services` folder:

```bash
# start from folder t01-services, making the clone next to t01-services
cd ..
git clone --recursive git@github.com:epics-containers/ioc-adsimdetector.git
```

Make sure you use the `--recursive` flag to fetch the `ibek-support` submodule. This submodule is shared between all the Generic IOC container images and contains the files that tell `ibek` how to build support modules inside the container environment and how to use them at runtime. Your container build will fail if this submodule is not present.

If you forget to use the `--recursive` flag you can fetch the submodule with `git submodule update --init`.

:::{important}
Users of docker need to instruct the devcontainer to use their own user id inside the container. You can do this with the following command:

```bash
export EC_REMOTE_USER=$USER
```

It is recommended that you place this command in `$HOME/.bashrc` (or `$HOME/.zshrc` for zsh users) to make it permanent.

If you do not do this, your devcontainer will run as root. This will cause problems as all files written on your host workspace will be owned by root.
:::

### Launching the Developer Container

In this section we are going to use vscode to launch a developer container. This means that all vscode terminals and editors will be running inside our container and browsing for files within the container filesystem. This is a very convenient way to work because:
- the development environment is saved alongside the source code
- you can easily share the development environment with other developers
- your development environment is portable between machines
- development has no dependencies on the host machine except for docker/podman

For epics-containers, the generic IOC *is* the developer container. When you build the developer target of the container in CI, it will contain all the build tools and dependencies needed to build the IOC. It will also contain the IOC source code and the support module source code. For this reason, we can also use the same developer target image to make the developer container itself. We then have an environment that encompasses all the source you could want to change inside of a Generic IOC, and the tools to build and test it.

It is also important to understand that although your VSCode session is entirely inside the container, some of your host folders have been mounted into the container. This is done so that important changes to source code would not be lost if the container were rebuilt. See [](container-layout) for details of which host folders are mounted into the container.

First, open the ioc-adsimdetector project in VSCode:

```bash
cd ioc-adsimdetector
code .
```

When it opens, VSCode may prompt you to open in a devcontainer, if so then choose to do so. If not then use `ctrl-shift-p` and type `Reopen in Container`.

The first time you do this, vscode will build the container image from the Dockerfile in the project. The file .devcontainer/devcontainer.json is used to configure how this container build is done.

This will take a few minutes to complete. A philosophy of epics-containers is that Generic IOCs build all of their own support from source. This is to avoid problematic dependency trees. For this reason building something as complex as AreaDetector will take a few minutes the first time.

A nice thing about containers is that the build steps are cached so that a second build will be almost instant. When you change something in the Dockerfile all the steps before the line you change will still use the cache.

Once the build completes you will see the project files in the Explorer pane on the left and will be able to open a terminal in vscode.

You are now *inside* the container. All terminals started in VSCode will be running inside the container. Every file that you open with the VSCode editor will be inside the container.

There are some caveats because some folders are mounted from the host file system. For example, the `ioc-adsimdetector` project folder is mounted into the container as a volume. It is mounted under `/workspaces/ioc-adsimdetector`. This means that you can edit the source code from your local machine and the changes will be visible inside the container and outside the container. This is a good thing as you should consider the container filesystem as temporary. The container filesystem will be destroyed when the container is rebuilt or deleted. Again, see [](container-layout) for details of which host folders are mounted into the container.

### Preparing the IOC for Testing

Now that you are *inside* the container you have access to the tools built into it, this includes `ibek`.

The first commands you should run are as follows:

```bash
# open a terminal: Menu -> Terminal -> New Terminal
cd /epics/ioc
make
```
:::{note}
The `make` process may report warnings regarding unsupported Locale settings. These are benign and will not affect the build.
:::


The IOC source code is entirely boilerplate, `/epics/ioc/iocApp/src/Makefile` determines which dbd and lib files to link by including two files that `ibek` generated during the container build. You can see these files in `/epics/support/configure/lib_list` and `/epics/support/configure/dbd_list`.

Although all Generic IOCs derived from ioc-template start out with the same generic source, you are free to change them if there is a need for different compilation options etc.

The Generic IOC should now be ready to run inside of the container. To do this:

```bash
cd /epics/ioc
./start.sh
```

You will just see the default output of a Generic IOC that has no Instance configuration. Hit `Ctrl-C` to stop the default script.

Next we will add some instance configuration from one of the IOC instances in the `t01-services` beamline.

To do this we will add some other folders to our VSCode workspace to make it easier to work with `t01-services` and to investigate the container filesystem.

## Adding the Example Beamline to the Workspace

To meaningfully test the Generic IOC we will need an instance to test it against. We will use the `t01-services` beamline that you already made in earlier tutorials. The devcontainer has been configured to mount some useful host folders into the container including the parent folder of the workspace as `/workspaces` so we can work on multiple peer projects.

In VSCode click the `File` menu and select `Add Folder to Workspace`. Navigate to `/workspaces` and you will see all the peers of your `ioc-adsimdetector`. Choose the `t01-services` folder and add it to the workspace.

:::{warning}
  At time of writing you will usually see this error the first time you add a folder to your devcontainer. It is safe to ignore it and click `Cancel`

  :::{figure} ../images/add-workspace-error.png
  :::
:::

Also take this opportunity to add the folder `/epics` to the workspace. This is the root folder in which all of the EPICS source and built files are located.

- File -> Add Folder to Workspace
- Select `/epics`
- Click cancel if you see an error

You can now easily browse around the `/epics` folder and see all the support modules and epics-base. This will give you a feel for the layout of files in the container. The table below summarizes the important folders in a generic IOC developer container. `${localWorkspaceFolder}` is the root of the Generic IOC source repo (the directory containing `.devcontainer/devcontainer.json`):

(container-layout)=
## Generic IOC Container Filesystem Layout

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
     - ${localWorkspaceFolder}/ioc
     - soft link to IOC source tree

   * - /epics/opi
     - ${localWorkspaceFolder}/opi/autogenerated
     - auto generated OPI files for the IOC

   * - /epics/runtime
     - N/A
     - generated startup script and EPICS database files

   * - /epics/ibek-defs
     - N/A
     - All ibek *Support yaml* files

   * - /epics/pvi-defs
     - N/A
     - all PVI definitions from support modules

   * - /workspaces
     - ${localWorkspaceFolder}/../
     - all peers to Generic IOC source repo

   * - /workspaces/ioc-adsimdetector
     - ${localWorkspaceFolder}
     - Generic IOC source repo (in this example)

   * - /epics/generic-source
     - ${localWorkspaceFolder}
     - A second - fixed location mount of the Generic IOC source repo to allow `ibek` to find it easily.
```

IMPORTANT: remember that the container filesystem is temporary and will be destroyed when the container is rebuilt or deleted. All folders above with `Host Mount Path` showing `N/A` are in the container filesystem. The devcontainer has been configured to mount the most useful host folders, but note that all support modules are in the container filesystem. Later we will learn how to work on support modules, first ensuring that they are made available in the host filesystem.

Also note that VSCode keeps your developer container until you rebuild it
or explicitly delete it. Restarting your PC and coming back to the same
devcontainer does keep all state. This can make you complacent about doing
work in the container filesystem, but it is still not recommended.

(choose-ioc-instance)=

## Choose the IOC Instance to Test

Now that we have the beamline repo visible in our container we can easily supply some instance configuration to the Generic IOC. This will use the `ibek` tool convenience function `dev instance` which declares which IOC instance you want to work on in the developer container.

:::{note}
If you have followed previous tutorials, you will need to swap back to the branch you created where the IOC "bl01t-ea-cam-01" is created.
:::

Try the following:

```
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01

# check the it worked - should see a symlink to the config folder
cd /epics/ioc
ls -l config
# now start the IOC by running the standard entry point script
./start.sh
# you should now see the IOC instance startup and show the ioc shell prompt
```

This removed any existing config folder and replaced it with the config from the IOC instance bl01t-ea-cam-01 by symlinking to its config folder. Note that we used a soft link, this means we can edit the config, restart the IOC to test it and the changes will already be in place in the beamline repository.


## Wrapping Up

We now have a tidy development environment for working on the Generic IOC,
IOC Instances and even the support modules inside the Generic IOC, all in one
place. We can easily test our changes in place too. In particular note that
we are able to test changes without having to go through a container build
cycle.

In the following tutorials we will look at how to make changes at each of the
3 levels listed in {any}`ioc-change-types`.
