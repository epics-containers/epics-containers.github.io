# Set up a Developer Workstation

This page will guide you through the steps to set up a developer workstation
in readiness for the remaining tutorials.
The tools you need to install are:

- Visual Studio Code
- a container platform, either podman or docker
- Python 3.11 or later + a Python virtual environment
- git client for version control

Visual Studio Code is recommended because it has excellent integration with
devcontainers. It also has useful extensions for working with Kubernetes,
EPICS, WSL2 and more.

## Options

You are not required to use VSCode to develop with epics-containers.
If you have your own preferred code editor you can use that.

See these how-to pages for more information:

- {any}`own-editor`

## Platform Support

The containers used in the tutorials are x86_64 Linux. The best way to experience the tutorials is to use an Intel Linux workstation or laptop. arm64 container images have been tested but are not yet widely used in the available images.

If you are using a Mac or Windows then the simplest approach is to use the Linux Virtual Machine with pre-installed software that we provide. First install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and then download the [Virtual Machine](https://drive.google.com/file/d/1ejJjiVDcODkiJsTShkCclQyod02f4Tex/view?usp=drive_link) TODO: currently hosted on giles Google Drive - find a better hosting solution. The downloaded file is an OVA file which can be imported into VirtualBox using ``File->Import Appliance ...``. During the import process you will be able to modify the resources that the VM uses, the defaults are recommended, but you may decrease them if your host machine has limited resources.

If you are using Windows you could instead install WSL2 and then work within the Linux subsystem. see [WSL2 installation instructions]. Ubuntu is recommended as the Linux distribution for WSL2. This has not been tested with the tutorials recently so the VM above is the preferred option.

## Installation Steps

If you are using the Virtual Machine, then you can skip to "Setup virtual environment", because the first three requirements are already installed.

If you are using your own Linux machine then follow all the steps below to install the required software.

### Setup VSCode

:::{Note}
**DLS Users**: You can access VSCode with `module load vscode`.
:::

First download and install Visual Studio Code.

- [Download Visual Studio Code]
- [Setup Visual Studio Code]

VSCode has a huge library of extensions. The following list of extensions are
useful for working with epics-containers. You will need to install the *Required*
extensions before proceeding to the next tutorial. See the links for instructions
on how to do this.

The recommended extensions will be installed for you when you launch the
devcontainer in the next tutorial.

- Required: [Remote Development]
- Required for Windows: [VSCode WSL2] (see [How to use WSL2 and Visual Studio Code])
- Recommended: [VSCode EPICS]
- Recommended: [Kubernetes]

### Setup Docker or Podman

:::{Note}
**DLS Users**: RHEL 8 Workstations at DLS have podman 4.9.4 installed by default.
RHEL 7 Workstations are not supported.
:::

Next install docker or podman as your container platform. epics-containers
has been tested with podman 4.4.1 and higher on RedHat 8, and Docker 24.0.5 and higher on for Ubuntu 22.04 and higher.

If you are using docker, simply replace `podman` with `docker` in the commands listed in these tutorials. `docker` users should also take a look at this page: [](../reference/docker.md)

The podman version required is 4.0 or later. Any version of docker since 20.10 will also work. Pick the tool that has the most recent version for your platform. RedHat 8 and above have recent podman versions. Older Debian platforms don't yet
have recent podman versions available. If you have a choice then podman is slightly preferred because it does not require root access and it is the tool with which epics-containers has had the most testing. However, docker is the most widely used container platform and is also well supported.

The links below have details of how to install your choice of container platform:

- [Install docker]
- [Install podman]

The docker install page encourages you to install Docker Desktop. This is a paid for product and is not required for this tutorial. You can install the free linux CLI tools by clicking on the appropriate linux distribution link.

(python-setup)=

### Install Python

:::{Note}
**DLS Users**: for this step just use `module load python/3.11`
:::

Go ahead and install Python 3.11 or later.

There are instructions for installing Python on all platforms here:
<https://docs.python-guide.org/starting/installation/>

### Setup virtual environment


Once you have python, set up a virtual environment for your epics-containers
work. In the examples we will use `$HOME/ec-venv` as the virtual environment
but you can choose any folder.

:::{Note}
**DLS Users**: As `$HOME` is a network drive it has an 8GB limit, consider other locations such as `/dls/science/` or `/scratch/`. Read more [here](https://dev-portal.diamond.ac.uk/guide/developer-environment/how-tos/disk-quota-troubleshooting/)
:::

```bash
python -m venv $HOME/ec-venv
source $HOME/ec-venv/bin/activate
python -m pip install --upgrade pip
```

Note that each time you open a new shell you will need to activate the virtual environment again. (Or place its bin folder in your path by adding it in your .bashrc).

(ec)=

### edge-containers-cli

Above we set up a python virtual environment. Now we will install the {any}`edge-containers-cli` python tool into that environment. This tool is used to manage the IOC instances in Kubernetes and is only required for the later tutorials.

```bash
pip install edge-containers-cli
```

See {any}`CLI` for more details.

:::{note}
DLS Users: `ec` is already installed for you on `dls_sw` just do the following to make sure it is always available:

```bash
# use the ec version from /dls_sw/work/python3
mkdir -p $HOME/.local/bin
ln -fs /dls_sw/work/python3/ec-venv/bin/ec $HOME/.local/bin/ec
# log out and back in again to make sure the new path is available
```
:::

## Git

If you don't already have git installed see
<https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>. Any recent
version of git will work.

### Kubernetes

You don't need Kubernetes yet.

The following tutorials will take you through creating, deploying and
debugging IOC instances, generic IOCs and support modules.

For simplicity we don't encourage using Kubernetes at this stage. Instead we will deploy containers to the local workstation's docker or podman instance.

If you are planning not to use Kubernetes at all then now might be a good time to install an alternative container management platform such as [Portainer](https://www.portainer.io/). Such tools will help you visualise and manage your containers across a number of servers. These are not required and you could just manage everything from the docker compose command line if you prefer.

[download visual studio code]: https://code.visualstudio.com/download
[how to use wsl2 and visual studio code]: https://code.visualstudio.com/blogs/2019/09/03/wsl2
[install docker]: https://docs.docker.com/engine/install/
[install podman]: https://podman.io/getting-started/installation
[kubernetes]: https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools
[remote development]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
[setup visual studio code]: https://code.visualstudio.com/learn/get-started/basics
[vscode epics]: https://marketplace.visualstudio.com/items?itemName=nsd.vscode-epics
[vscode wsl2]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl
[wsl2 installation instructions]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
