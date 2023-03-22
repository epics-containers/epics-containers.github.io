Setup a Developer Workstation
=============================

This tutorial will guide you through the steps to setup a developer workstation
for creating, deploying and managing containerized IOCs.
The only tools you need to install are:

- Visual Studio Code
- A container runtime (docker or podman)

That's it. The reason the list is so short is that we will be using
a developer container which includes all the tools needed. Thus you only need
docker or podman to get the devcontainer up and running.

Visual Studio Code is also recommended because it has excellent integration with
devcontainers. It also has useful extensions for working with Kubernetes,
EPICS, WSL2 and more.

.. Note::

    **DLS Users**: RHEL 8 Workstations in DLS have podman installed by default.
    You can access vscode with ``module load vscode``. RHEL 7 Workstations
    also have podman but it is an unsupported version.

Options
-------

You are not required to use the tools above to develop with epics-containers.
If you have your own preferred code editor you can use that. If you prefer
not to work inside a container to do development that is also a possibility.

See these how-to pages for more information:

- `../how-to/own_editor`
- `../how-to/native_tools`

Platform Support
----------------

epics-containers can use Linux, Windows or MacOS as the host operating system for
the developer workstation.

If you are using Windows then you must first
install WSL2 and then work within the Linux subsystem. see
`WSL2 installation instructions`_.
Ubuntu is recommended as the Linux distribution for WSL2.

.. _WSL2 installation instructions: https://docs.microsoft.com/en-us/windows/wsl/install-win10

Setup
-----

First download and install Visual Studio Code.

- `Download vscode`_
- `Setup Visual Studio Code`_

Add the following extensions to Visual Studio Code:

- Required: `Remote Development`_
- Recommended: `VSCode EPICS`_
- Recommended: `Kubernetes`_
- Required for Windows: `VSCode WSL2`_ (see `How to use WSL2 and Visual Studio Code`_)

.. _VSCode WSL2: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl
.. _How to use WSL2 and Visual Studio Code: https://code.visualstudio.com/blogs/2019/09/03/wsl2
.. _Kubernetes: https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools
.. _VSCode EPICS: https://marketplace.visualstudio.com/items?itemName=nsd.vscode-epics
.. _Remote Development: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
.. _Setup Visual Studio Code: https://code.visualstudio.com/learn/get-started/basics
.. _Download VSCode: https://code.visualstudio.com/download


Next install docker or podman as the your container platform. The author is using
podman on RHEL8 but docker is also supported. All commands in these tutorials
will use ``podman`` cli commands. If you are using docker, simply replace ``podman``
with ``docker`` in the commands.

The podman version required is 4.0 or later. This is not easy to obtain on debian
distributions at the time of writing, therefore docker may be a better choice.

The links below have details of how to install your choice of container platform:

- `Install docker`_
- `Install podman`_

.. _Install docker: https://docs.docker.com/engine/install/
.. _Install podman: https://podman.io/getting-started/installation

