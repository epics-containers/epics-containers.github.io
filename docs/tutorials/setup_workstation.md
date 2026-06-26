# Set up a Developer Workstation

This page will guide you through the steps to set up a developer workstation
in readiness for the remaining tutorials.
The tools you need to install are:

- Visual Studio Code
- a container platform: podman (plus docker-compose)
- Python 3.10 or later (uv can also install this for you)
- uv, to install the Python CLI tools (copier and ec)
- git client for version control (Configured for the current user, with read-write access for Repository Contents and Workflows.)

If you prefer to use a virtual machine, we provide a VirtualBox appliance with all the software pre-installed. This is the easiest way to get started.

Visual Studio Code is recommended because it has excellent integration with
devcontainers. It also has useful extensions for working with Kubernetes,
EPICS, Yaml files and more.

:::{note}
**Using a Personal Access Token (PAT):** If following the tutorials on an untrusted machine, using a PAT for authentication is encouraged as it can be scoped and time bound. For Github users a new token can be created via Settings -> Developer Settings -> Personal access tokens -> Fine-grained tokens. Give your new token R/W access to Repository Contents and Workflows.

```
# Remember credentials for 5 hours duration
git config --global credential.helper 'cache --timeout 18000'
# When asked to login
Username for `https://github.com': <ENTER YOUR USERNAME>
Password for `https://<YOUR USERNAME>@github.com': <ENTER YOUR PAT>
```

When using Personal Access Tokens, replace `git@github.com:` with `https://github.com/` throughout these tutorials.
:::


## Options

You are not required to use VSCode to develop with epics-containers.
If you have your own preferred code editor you can use that.

See these how-to pages for more information:

- {any}`own-editor`

## Platform Support

The containers used in the tutorials are x86_64 Linux. The best way to experience the tutorials is to use an Intel Linux workstation or laptop. arm64 container images have been tested but are not yet widely used in the available images.

**UPDATE**: See the new [quickstart instructions](quickstart) for setting up the container runtime on any platform, therefore not requiring the virtualbox appliance unless that is your preferred option.

Whatever your platform, if you can install virtualbox, then you can work using the appliance we provide.

In all cases you will need an internet connection to download the software and the container images. (if you are at DLS you do not need access to DLS network resources, only the internet).

| Platform | Requirements |
|----------|--------------|
| Any Linux | admin rights only: go to {ref}`installation-steps` |
| Windows | Virtualbox: go to {ref}`appliance`  or WSL2 and Podman Desktop |
| Mac x86 | Virtualbox: go to {ref}`appliance` or Podman Desktop |
| Mac M1 | Virtualbox: go to {ref}`appliance` or Podman Desktop |
| DLS RHEL 8 | go to {ref}`installation-steps` |

(appliance)=
## VirtualBox Appliance

This section is for those that want to use a virtual machine to run the tutorials. If you already have a linux distribution with admin permissions and you want to work with that instead, please go to {ref}`installation-steps` below.

If you are using a Mac or Windows then the simplest approach is to use the Linux Virtual Machine with pre-installed software that we provide.

First install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and then download the [Virtual Machine](https://drive.google.com/file/d/1AZ1ptVqTV4-YjCsNKQXdjOkA-d77hWp7/view?usp=sharing). The downloaded file is an OVA file which can be imported into VirtualBox using ``File->Import Appliance ...``

During the import process you will be able to modify the resources that the VM uses, the defaults are recommended, but you may decrease them if your host machine has limited resources. We recommend 8GB of RAM and 4 CPUs for the VM but more is better for the developer container tutorials!

Now start the VM and log in as `ec-demo` with password `demo1`.

This VM has the following software pre-installed:
- Ubuntu 22.04
- Python 3.10
- Visual Studio Code
- Podman
- zsh shell with oh-my-zsh

You will need to complete the following steps to personalize the VM:
- Set up your github credentials
- Install `uv` and the Python CLI tools (copier and ec)
- Set up your podman CLI completion if you want it

Now jump to {ref}`cli-completion` below.


(installation-steps)=
## Installation Steps

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

- Required: [Remote Development]
- Required for Windows: [VSCode WSL2] (see [How to use WSL2 and Visual Studio Code])
- Recommended: [VSCode EPICS]
- Recommended: [Kubernetes]

### Setup Podman

:::{Note}
**DLS Users**: RHEL 8 Workstations at DLS have podman 4.9.4 installed by default. RHEL 7 Workstations are not supported.

If this is the first time you have used podman **OR you are using a DLS Redhat laptop** then you must perform the following steps:

```bash
# setup the podman config folders in your home directory
/dls_sw/apps/setup-podman/setup.sh
# disable se labels in mounted folders for podman
sed -i ~/.config/containers/containers.conf -e '/label=false/d' -e '/^\[containers\]$/a label=false'
```
:::

We recommend `podman` as your container platform. epics-containers works best
with `podman` because it is rootless by default, which is simpler and more
secure for developing and running IOCs (see {any}`rootless` for the details).
epics-containers has been tested with podman 4.4.1 and higher on RedHat 8 and
Ubuntu 22.04 and higher. The podman version required is 4.0 or later.

The link below has details of how to install podman:

- [Install podman]

:::{note}
**Prefer to use docker?** epics-containers fully supports `docker` as well. The
rest of this documentation refers to `podman` throughout, so if you would rather
use `docker` see {any}`using-docker` for how to install it and the few
extra steps it requires. Everything else in the tutorials works the same way.
:::

(podman-compose)=
### Docker Compose For Podman Users

docker compose allows you to define and run multi-container Docker applications. epics-containers uses it for describing a set of IOCs and other services that are deployed together. It is a useful starting point for tutorials before moving on to Kubernetes. It could also form the basis of a production deployment for those not using Kubernetes.

Since you installed podman you will need to install docker compose separately (the steps below show how). We prefer to use docker-compose instead of podman-compose because it is more widely used and there are still some issues with podman-compose at the time of writing.

:::{Note}
**DLS Users**: docker compose integration with podman is available on RHEL 8 Workstations at DLS. Run `module load docker-compose` to enable it.
:::

Steps to combine podman and docker-compose:-

1. Launch a podman user service and expose a docker API socket as follows. This step need only be done once per workstation.

    ```bash
    systemctl enable --user podman.socket --now
    ```
1. Add the following to your shell profile (e.g. ~/.bashrc or ~/.zshrc) to instruct docker-compose and any other docker tool to use podman's docker API socket.

    ```bash
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
    ```

1. Use these instructions <https://docs.docker.com/compose/install/standalone> to install the docker compose binary. Some linux distributions have docker-compose in their package manager, this is the easiest way to install it if available.

1. we recommend uninstalling podman-compose if you have it installed.

    ```bash
    # Debian/Ubuntu
    sudo apt uninstall podman-compose
    # RHEL/Centos
    sudo dnf remove podman-compose
    # Arch
    sudo pacman -R podman-compose
    ```

### Using docker instead of podman

From here on the tutorials always refer to `podman` on the command line. If you
have chosen to use `docker` instead, the two tools have (almost) the same CLI so
every `podman` command has an identical `docker` equivalent. See
[](../reference/docker.md) for how to install docker, how to run it rootless
(recommended) and the couple of extra steps that rootful docker requires to work
in developer containers.

(cli-completion)=
### Command Line Completion

This is an optional step to set up CLI completion for podman.

It is much easier to investigate the commands available to you with command line completion enabled. You need only do the following steps once to permanently enable this feature for podman.

```bash
# these steps will make cli completion work for bash
mkdir -p ~/.local/share/bash-completion/completions
podman completion bash > ~/.local/share/bash-completion/completions/podman

# these steps will make cli completion work for zsh
mkdir -p ~/.oh-my-zsh/completions
podman completion zsh > ~/.oh-my-zsh/completions/_podman
```

(python-setup)=
### Install Python

:::{Note}
**DLS Users**: for this step just use `module load python/3.11`
:::

Go ahead and install Python if it is not already installed, the minimum version you should use is 3.10. Virtualbox Appliance users will already have Python 3.10 installed.

There are instructions for installing Python on all platforms here:
<https://docs.python-guide.org/starting/installation/>


### Install uv

We use [uv](https://docs.astral.sh/uv/) to install and run the Python command
line tools used in these tutorials (such as `copier` and `ec`). `uv` installs
each tool into its own isolated environment and puts it on your `PATH`, so there
is no virtual environment to create or activate every time you open a shell.

:::{Note}
**DLS Users**: you can obtain `uv` with `module load uv` instead of installing
it yourself, in which case you can skip the install command below.
:::

Install `uv` with its standalone installer:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

See the [uv installation docs](https://docs.astral.sh/uv/getting-started/installation/)
for other installation methods (including Windows). `uv` can also manage Python
versions for you, so the tools below will work even without the system Python
installed above.

(copier)=

### copier

Now we will install `copier` which is used to copy the templates for the
services repositories and generic IOCs. Also you could take this opportunity to
install the `ec` tool that we will use later when we get to the Kubernetes
tutorials.

```bash
uv tool install copier
uv tool install edge-containers-cli
```

These commands put `copier` and `ec` on your `PATH` in every new shell, so there
is nothing to activate. To upgrade them later run `uv tool upgrade --all`. If a
freshly installed tool is not found, run `uv tool update-shell` (or add
`$HOME/.local/bin` to your `PATH`) and open a new shell.

### Git

If you don't already have git installed see
<https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>. Any recent
version of git will work.

You will also want to set up your git user name and email address:

```bash
git config --global user.name "Your Name"
git config --global user.email "your email"
```

And set up your git credentials so that you can access your personal github repositories. Your choices are:

- use a Personal Access Token (PAT) as described in the first section above.
- setup an ssh key following the instructions [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

### Kubernetes

You don't need Kubernetes yet.

The following tutorials will take you through creating, deploying and debugging IOC instances, generic IOCs and support modules.

For simplicity we don't encourage using Kubernetes at this stage. Instead we will deploy containers to the local workstation's podman instance using docker compose.

If you are planning not to use Kubernetes at all then now might be a good time to install an alternative container management platform such as [Portainer](https://www.portainer.io/). Such tools will help you visualise and manage your containers across a number of servers. These are not required and you could just manage everything from the docker compose command line if you prefer.

[download visual studio code]: https://code.visualstudio.com/download
[how to use wsl2 and visual studio code]: https://code.visualstudio.com/blogs/2019/09/03/wsl2
[install podman]: https://podman.io/getting-started/installation
[kubernetes]: https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools
[remote development]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
[setup visual studio code]: https://code.visualstudio.com/learn/get-started/basics
[vscode epics]: https://marketplace.visualstudio.com/items?itemName=nsd.vscode-epics
[vscode wsl2]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl
[wsl2 installation instructions]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
