Setup a Developer Workstation
=============================

This page will guide you through the steps to setup a developer workstation
in readiness for the remaining tutorials.
The tools you need to install are:

- Visual Studio Code
- a container platform, either podman or docker
- Python 3.9 or later + a Python virtual environment
- git client for version control

Visual Studio Code is recommended because it has excellent integration with
devcontainers. It also has useful extensions for working with Kubernetes,
EPICS, WSL2 and more.

Options
-------

You are not required to use VSCode to develop with epics-containers.
If you have your own preferred code editor you can use that.

See these how-to pages for more information:

- `own_editor`

Platform Support
----------------

epics-containers can use Linux, Windows or MacOS as the host operating system for
the developer workstation.

If you are using Windows then you must first
install WSL2 and then work within the Linux subsystem. see
`WSL2 installation instructions`_.
Ubuntu is recommended as the Linux distribution for WSL2.

.. _WSL2 installation instructions: https://docs.microsoft.com/en-us/windows/wsl/install-win10

Installation Steps
------------------

Setup VSCode
~~~~~~~~~~~~

.. Note::

    **DLS Users**:  You can access VSCode with ``module load vscode``.

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


Setup Docker or Podman
~~~~~~~~~~~~~~~~~~~~~~

.. Note::

    **DLS Users**: RHEL 8 Workstations at DLS have podman 4.4.1 installed by default.
    RHEL 7 Workstations are not supported.

Next install docker or podman as the your container platform. epics-containers
has been tested with podman 4.4.1 on RedHat 8, and Docker 24.0.5 on
for Ubuntu 22.04.

If you are using docker, simply replace ``podman`` with ``docker`` in the
commands listed in these tutorials.

The podman version required is 4.0 or later. Any version of docker since 20.10
will also work. Pick the tool that has the most recent version for your platform.
RedHat 8 and above have recent podman versions. Debian platforms don't yet
have recent podman versions available. If you have a choice then podman is
preferred because it does not require root access and it is the tool with
which epics-containers has had the most testing.

The links below have details of how to install your choice of container platform:

- `Install docker`_
- `Install podman`_

The docker install page encourages you to install Docker Desktop. This is a paid
for product and is not required for this tutorial. You can install the free linux
CLI tools by clicking on the appropriate linux distribution link.

.. _Install docker: https://docs.docker.com/engine/install/
.. _Install podman: https://podman.io/getting-started/installation

.. _python_setup:

Install Python
~~~~~~~~~~~~~~

.. Note::

    **DLS Users**: RHEL 8 Workstations at DLS have Python 3.9 installed by default.

Go ahead and install Python 3.9 or later. 3.11 is recommended as this is the
highest version that epics-containers has been tested with.

There are instructions for installing Python on all platforms here:
https://docs.python-guide.org/starting/installation/


Once you have python set up a virtual environment for your epics-containers
work. In the examples we will use ``$HOME/ec-venv`` as the virtual environment
but you can choose any folder.

.. code-block:: bash

    python -m venv $HOME/ec-venv
    source $HOME/ec-venv/bin/activate
    python -m pip install --upgrade pip

Note that each time you open a new shell you will need to activate the virtual
environment again. (Or place it's bin folder in your path permanently).


.. _ec:

epics-containers-cli
~~~~~~~~~~~~~~~~~~~~

Above we set up a python virtual environment. Now we will install
the epics-containers-cli python tool into that environment.

.. code-block:: bash

    pip install epics-containers-cli

This is the developer's 'outside of the container' helper tool. The command
line entry point is ``ec``. We will be using many ``ec`` command line
functions in the next tutorial.

See `CLI` for more details.

.. note::

    DLS Users: ``ec`` is already installed for you on ``dls_sw`` just do the
    following to make sure it is always available:

    .. code:: bash

        # use the ec version from dls_sw/work/python3
        mkdir -p $HOME/.local/bin
        ln -fs /dls_sw/work/python3/ec-venv/bin/ec $HOME/.local/bin/ec

Git
---
If you don't already have git installed see
https://git-scm.com/book/en/v2/Getting-Started-Installing-Git. Any recent
version of git will work.

Kubernetes
~~~~~~~~~~

You don't need Kubernetes yet.

The following tutorials will take you through creating, deploying and
debugging IOC instances, generic IOCs and support modules.

For simplicity we don't encourage using Kubernetes at this stage. Instead we
will deploy containers to the local workstation's docker or podman instance.

However, everything in these tutorials would also work with Kubernetes. If you
are particularly interested in Kubernetes then you can jump to
`setup_kubernetes` and follow the instructions there. Then come back to this
point and continue with the tutorials.

If you are planning not to use Kubernetes at all then now might be
a good time to install an alternative container management platform such
as `Portainer <https://www.portainer.io/>`_. Such tools will help you
visualise and manage your local containers. They are not required and you
could just manage everything from epics-containers command line interface
if you prefer.

