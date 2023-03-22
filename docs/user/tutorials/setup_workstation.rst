Setup a Developer Workstation
=============================

This tutorial will guide you through the steps to setup a developer workstation
for creating, deploying and managing containerized IOCs.
The only tools you need to install are:

- Visual Studio Code
- A container runtime (docker or podman)

That's it. The reason the list is so short is that epics-containers provides
a developer container which includes all the tools needed. Thus you only need
a container runtime to get that up and running.

Visual Studio Code is also recommended because it has excellent integration with
devcontainers.

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
install WSL2 and then work within the Linux subsystem. see `WSL2 instructions`_.
Ubuntu is recommended as the Linux distribution for WSL2.

.. _WSL2 instructions: https://docs.microsoft.com/en-us/windows/wsl/install-win10

Setup
-----

First install Visual Studio Code.

and a container runtime. For container runtime
you can pick podman or docker.