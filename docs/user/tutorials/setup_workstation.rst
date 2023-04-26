Setup a Developer Workstation
=============================

This page will guide you through the steps to setup a developer workstation
in readiness for the remaining tutorials.
The only tools you need to install are:

- Visual Studio Code
- a container platform, either podman or docker

That's it. The reason the list is so short is that we will be using
a developer container which includes all the tools needed. Thus you only need
docker or podman to get the devcontainer up and running.

Visual Studio Code is also recommended because it has excellent integration with
devcontainers. It also has useful extensions for working with Kubernetes,
EPICS, WSL2 and more.

.. Note::

    **DLS Users**: RHEL 8 Workstations at DLS have podman installed by default.
    You can access VSCode with ``module load vscode``. RHEL 7 Workstations
    are not supported.

Options
-------

You are not required to use the tools above to develop with epics-containers.
If you have your own preferred code editor you can use that. If you prefer
not to work inside a container to do development that is also a possibility.

See these how-to pages for more information:

- `own_editor`
- `no_devcontainer`

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

- `Download Visual Studio Code`_
- `Setup Visual Studio Code`_

VSCode has an huge library of extensions. The following list of extensions are
useful for working with epics-containers. You will need to install the *Required*
extensions before proceeding to the next tutorial. See the links for instructions
on how to do this.

The recommended extensions will be installed for you when you launch the
devcontainer in the next tutorial.

- Required: `Remote Development`_
- Required for Windows: `VSCode WSL2`_ (see `How to use WSL2 and Visual Studio Code`_)
- Recommended: `VSCode EPICS`_
- Recommended: `Kubernetes`_

.. _VSCode WSL2: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl
.. _How to use WSL2 and Visual Studio Code: https://code.visualstudio.com/blogs/2019/09/03/wsl2
.. _Kubernetes: https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools
.. _VSCode EPICS: https://marketplace.visualstudio.com/items?itemName=nsd.vscode-epics
.. _Remote Development: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
.. _Setup Visual Studio Code: https://code.visualstudio.com/learn/get-started/basics
.. _Download Visual Studio Code: https://code.visualstudio.com/download


Next install docker or podman as the your container platform. I am using
podman 4.2.0 on RHEL8, docker *could* also be supported but note the warning below.
All commands in these tutorials will use ``podman`` cli commands.
If you are using docker, simply replace ``podman`` with ``docker`` in the commands.

The podman version required is 4.0 or later. This is not easy to obtain on debian
distributions at the time of writing, but details of how to compile from source
are contained
`in this Dockerfile <https://github.com/epics-containers/dev-e7/blob/main/docker/Dockerfile>`_
under the heading  ``Stage to add a recent podman client``


The links below have details of how to install your choice of container platform:

- `Install docker`_
- `Install podman`_

The docker install page encourages you to install Docker Desktop. This is a paid
for product and is not required for this tutorial. You can install the free linux
CLI tools by clicking on the appropriate linux distribution link.

.. _Install docker: https://docs.docker.com/engine/install/
.. _Install podman: https://podman.io/getting-started/installation

.. Warning::

    To support docker we need to do one of two things: 1) use the docker cli
    in user mode or 2) set the user id and gid when launching the container.
    If we don't do this then all files written to mounted volumes will be owned
    by root.

    **TODO**: write up how to do this. **TODO** the container image may
    need some minor modifications to support docker. (I recently got this
    working `here <https://github.com/gilesknap/gphotos-sync/issues/279#issuecomment-1475317852>`_)
