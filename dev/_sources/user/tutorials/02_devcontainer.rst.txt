
Setup the Devcontainer
======================

Introduction
------------

The devcontainer provides the environment in which you will do all your development
and management of IOCs.

The base container is defined in https://github.com/epics-containers/dev-e7
but we will use a customizable image derived from that. The customizable
container definition is in https://github.com/epics-containers/.devcontainer.


Configure Visual Studio Code
----------------------------

For podman users, you must first tell vscode to use podman instead of docker.
Open a vscode window and hit "ctrl ," (control-comma) to open the user
settings editor and search for
"dev.containers.dockerPath", change its value from "docker" to "podman".


Launching the Devcontainer
--------------------------

To setup your devcontainer, perform the following steps:

-  create a workspace folder
-  clone the .devcontainer repository into the workspace folder
-  open the workspace folder with Visual Studio Code.

for example:

.. code-block:: bash

    mkdir work-ec
    cd work-ec
    git clone git@github.com:epics-containers/.devcontainer.git
    code .

This will open the workspace folder in Visual Studio Code. You will be prompted
to reopen the folder in a container. Click on the ``Reopen in Container`` button.

.. figure:: ../images/vscode-reopen-in-container.png
    :width: 600px
    :align: center

    reopen in container dialogue

Now all of your vscode terminals and file explorer will be running inside of
the devcontainer and have access to all the tools installed there.

To verify things are working as expected, open a terminal in vscode from
the menus ``Terminal > New Terminal``. You should see a prompt like this:

.. code-block:: bash

    [E7][work-ec]$

The E7 is used to indicate that you are running inside the
``dev-e7`` developer container.
``work-ec`` is the name of the current working directory. You are
welcome to alter the prompt by changing PS1 in ``.bashrc_dev`` (see next
section), but it is a good idea to keep an indication of the container
name in the prompt.

Things to note:

- Your workspace folder is mounted inside the container at the same path as
  the host folder it is mapped to. This means that you can edit files in
  the container and the changes are reflected outside the container and
  vice versa.

- Your home folder is also mounted in its usual location. BUT $HOME is set
  to ``/root``.

- Podman users are running as root inside the container but files will be
  written with your user id and group id.

.. _devcontainer-configure:

Configuring the Devcontainer
----------------------------

.. note::

    **DLS users**: the settings in the default ``.bashrc_dev`` are already
    configured for interacting with the test beamline bl01t on the test
    cluster Pollux. HOWEVER: for this exercise we will use your personal
    GitHub account to avoid clashes with other users of this tutorial.
    Therefore follow the instructions below and for the KUBECONFIG setting
    use the following:

    .. code-block:: bash

        # point at your cluster configuration file
        export KUBECONFIG=/home/${USER}/.kube/config_pollux

    To enable access to the pollux cluster, execute the following commands
    from outside of the dev container:

    .. code-block:: bash

        module load pollux
        .devcontainer/dls-copy-k8s-crt.sh # a script in the .devcontainer repo
        kubectl get nodes

    The last command will ask for your fed-id and password and then show A
    list of nodes in the pollux cluster.

You devcontainer environment is configured by a file called
``.bashrc_dev`` file. The terminals in the devcontainer will source this
file when they start.

You can take a copy of ``.devcontainer/.bashrc_dev`` and place it in your
home folder to customize it.
i.e.:


    # IMPORTANT: use /home/$USER not $HOME
    cp .devcontainer/.bashrc_dev /home/${USER}/.bashrc_dev
    code /home/${USER}/.bashrc_dev

Alternatively you can take a fork of the .devcontainer repo and make your
own version of the .bashrc_dev file in place.

Much of this file is setting up convenience features like prompt and bash
history. You can change these to suit your own preferences.

The primary configuration options are the environment variables exported by
this script. These are listed below with some recommended values for running
these tutorials. Paste the following into the ``.bashrc_dev`` file and
change GITHUB_ORG to your GitHub organization or user.

.. code-block:: bash

    ############ REPLACE all environment below with your details ###################

    # Github organization or user name
    export GITHUB_ORG=<YOUR GITHUB ORGANIZATION OR USER GOES HERE>

    # point at your cluster configuration file
    export KUBECONFIG=/home/${USER}/.kube/config

    # the default beamline or domain for ec commands
    export BEAMLINE=t01 # equivalent to K8S_DOMAIN=bl01t

    # where to get HELM charts for ec commands
    export K8S_HELM_REGISTRY=ghcr.io/${GITHUB_ORG}

    # where to get container IMAGES for ec commands
    export K8S_IMAGE_REGISTRY=ghcr.io/${GITHUB_ORG}

    # the URL for the facility logging system
    export K8S_LOG_URL='none'

    # set this to True to suppress output of commands in 'ec' CLI
    unset K8S_QUIET

    # extra arguments to supply to containerized CLI commands
    export K8S_CLI_ARGS=''

After editing ``/home/$USER/.bashrc_dev`` you will need to close any open terminals and
restart them to pick up the changes.


.. Note::

    For advanced users with knowledge of docker or podman.

    You can also alter the parameters for launch of the container by editing the
    ``.devcontainer/devcontainer.json`` file.
    `See here for details <https://containers.dev/implementors/json_reference/>`_

    In addition, you can alter the system packages installed in the container or make
    any other changes to the Dockerfile and regenerate your own container image.

    If you wish to persist these changes
    then it is suggested that you make your own github repo of .devcontainer and
    push the changes there.

