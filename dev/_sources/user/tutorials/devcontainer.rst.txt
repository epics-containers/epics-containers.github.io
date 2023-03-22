
02 Setup the Devcontainer
=========================

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
Edit the file ``~/.config/Code/User/settings.json`` and add the following:

.. code-block:: json

    {
        "dev.containers.dockerPath": "podman"
    }

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

Things to note:

    Your workspace folder is mounted inside the container at the same path as
    the host folder. This means that you can edit files in the container
    and the changes are reflected outside the container and vice versa.

    Your home folder is also mounted in its usual location. BUT $HOME is set
    to ``/root``.

    Podman users are running as root inside the container but files will be
    written with your user id and group id.

Configuring the Devcontainer
----------------------------

For epics-containers the most important configuration is held in the ``.bashrc_dev``
file. You can take a copy of ``.devcontainer/.bashrc_dev`` and place it in your
home folder to customize it. The terminals in the devcontainer will source this
file when they start.
i.e.:

.. code-block:: bash

    # important use /home/$USER not $HOME
    cp .devcontainer/.bashrc_dev /home/${USER}/.bashrc_dev
    code /home/${USER}/.bashrc_dev

The primary configuration options are the environment variables exported by
this script. These are listed below and we will cover them in more detail as we
introduce configuration of the cluster and registries.

**DLS users**: these settings are already configured for interacting with the
test beamline bl45p.

.. code-block:: bash

    # point at your cluster config file
    export KUBECONFIG=/home/${USER}/.kube/config_pollux

    # the default beamline for ec commands
    export BEAMLINE=p45 # equivalent to K8S_DOMAIN=bl45p

    # where to get HELM charts for ec commands
    export K8S_HELM_REGISTRY=helm-test.diamond.ac.uk/iocs

    # set to true to add /$K8S_DOMAIN to the helm registry URL
    export K8S_HELM_REGISTRY_ADD_DOMAIN=true

    # where to get container IMAGES for ec commands
    export K8S_IMAGE_REGISTRY=ghcr.io/epics-containers

    # the URL for the facility logging system
    export K8S_LOG_URL='https://graylog2.diamond.ac.uk/search?rangetype=relative&fields=message%2Csource&width=1489&highlightMessage=&relative=172800&q=pod_name%3A{ioc_name}*'

After editing ``/home/$USER/.bashrc_dev`` you will need to close any open terminals and
restart them to pick up the changes.


.. Note::

    For advanced users with knowledge of docker or podman.

    You can also alter the parameters for launch of the container by editing the
    ``.devcontainer/devcontainer.json`` file.
    `See here for details <https://containers.dev/implementors/json_reference/>`_

    If you wish to persist these changes
    then it is suggested that you make your own github repo of .devcontainer and
    push the changes there.

