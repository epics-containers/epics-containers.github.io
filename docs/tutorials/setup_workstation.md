# Set up a Developer Workstation

This page will guide you through the steps to set up a developer workstation
in readiness for the remaining tutorials.
The tools you need to install are:

- Visual Studio Code
- a container platform, either docker or podman and docker-compose
- Python 3.10 or later + a Python virtual environment
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
- Docker
- zsh shell with oh-my-zsh

You will need to complete the following steps to personalize the VM:
- Set up your github credentials
- Set up your python virtual environment
- Set up your docker or podman CLI completion if you want it

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

### Setup Docker or Podman

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

Next install docker or podman as your container platform. epics-containers
has been tested with podman 4.4.1 and higher on RedHat 8, and Docker 24.0.5 and higher on for Ubuntu 22.04 and higher.

The podman version required is 4.0 or later. Any version of docker since 20.10 will also work.

Because we use docker compose which is built in to later versions of docker, we recommend using docker if you have a choice.

The links below have details of how to install your choice of container platform:

- [Install docker]
- [Install podman]

The docker install page encourages you to install Docker Desktop. This is a paid for product and is not required for this tutorial. You can install the free linux CLI tools by clicking on the appropriate linux distribution link under the "Supported Platforms" heading, for simplicity it is easiest to use the option "Install using the convenience script".

(podman-compose)=
### Docker Compose For Podman Users

docker compose allows you to define and run multi-container Docker applications. epics-containers uses it for describing a set of IOCs and other services that are deployed together. It is a useful starting point for tutorials before moving on to Kubernetes. It could also form the basis of a production deployment for those not using Kubernetes.

If you installed docker using the above instructions then docker compose is already installed. If you installed podman then you will need to install docker compose separately. We prefer to use docker-compose instead of podman-compose because it is more widely used and there are still some issues with podman-compose at the time of writing.

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

### Important Notes Regarding docker and podman

From here on when we refer to `docker` in a command line, you can replace it with `podman` if you are using podman. The two tools have (almost) the same CLI. For convenience if you are a podman user you might want to place
```bash
alias docker=podman
```
in your `$HOME/.bashrc` (or `$HOME/.zshrc` for zsh users).

`docker` users should also take a look at this page: [](../reference/docker.md) which describes a couple of extra steps that are required to make docker work in developer containers.

(cli-completion)=
### Command Line Completion

This is an optional step to set up CLI completion for docker or podman.

It is much easier to investigate the commands available to you with command line completion enabled. You need only do the following steps once to permanently enable this feature for docker and docker compose.

```bash
# these steps will make cli completion work for bash
mkdir -p ~/.local/share/bash-completion/completions
docker completion bash > ~/.local/share/bash-completion/completions/docker
# OR
podman completion bash > ~/.local/share/bash-completion/completions/podman

# these steps will make cli completion work for zsh
mkdir -p ~/.oh-my-zsh/completions
docker completion zsh > ~/.oh-my-zsh/completions/_docker
# OR
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


### Setup virtual environment

Once you have python, set up a virtual environment for your epics-containers
work. In the examples we will use `$HOME/ec-venv` as the virtual environment
but you can choose any folder.

:::{Note}
**DLS Users**: As `$HOME` is a network drive it has an 8GB limit, consider other locations such as `/dls/science/` or `/scratch/`. Read more [here](https://dev-portal.diamond.ac.uk/guide/developer-environment/how-tos/disk-quota-troubleshooting/)
:::

```bash
python3 -m venv $HOME/ec-venv
source $HOME/ec-venv/bin/activate
python3 -m pip install --upgrade pip
```

Note that each time you open a new shell you will need to activate the virtual environment again. (Or place its bin folder in your path by adding `PATH=$HOME/ec-venv/bin:$PATH` in your `$HOME/.bashrc` (or `$HOME/.zshrc` for zsh users)).

(copier)=

### copier

Above we set up a python virtual environment. Now we will install `copier` which is used to copy the templates for the services repositories and generic IOCs. Also you could take this opportunity to install the `ec` tool that we will use later when we get to the Kubernetes tutorials.

```bash
pip install copier
pip install edge-containers-cli
```

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

For simplicity we don't encourage using Kubernetes at this stage. Instead we will deploy containers to the local workstation's docker or podman instance using docker compose.

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
