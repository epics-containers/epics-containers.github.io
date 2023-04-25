
The EPICS Devcontainer
======================

Introduction
------------

For working with epics-containers we provide a developer container with
all the tools you need to build and deploy EPICS IOCs already installed.
In this tutorial we will install and configure this devcontainer.

In `devcontainer` we demonstrated launching a container for a single project.
Here we will create a workspace that will allow
you to manage multiple projects within a single devcontainer.

The base container is defined in https://github.com/epics-containers/dev-e7
but we will use a customizable image derived from that. The customizable
container definition is in https://github.com/epics-containers/.devcontainer.


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

.. seealso:: `./devcontainer`

Having setup your devcontainer, to verify things are working as expected,
open a terminal in VSCode from the menus ``Terminal > New Terminal``.
You should see a prompt like this:

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
  written with your user id and group id when writing to the mounted
  workspace folder (or your home directory).

- In the following tutorials we will create further project folders and add
  them to the workspace that you have just created. These projects will
  all be managed inside the devcontainer we have just set up.

.. _devcontainer-configure:

Configuring the Devcontainer
----------------------------

.. note::

    **DLS users**: the settings in the default ``.bashrc_dev`` are already
    configured for interacting with the test beamline bl01t on the test
    cluster Pollux. HOWEVER: for this exercise we will use your personal
    GitHub account to avoid clashes with other users of this tutorial.
    Therefore the ``K8S_HELM_REGISTRY`` variable must be set to your
    GitHub user name and the other variables left as is.

    To enable access to the pollux cluster, execute the following commands
    from OUTSIDE of the dev container:

    .. code-block:: bash

        module load pollux
        klogout
        .devcontainer/dls-copy-k8s-crt.sh # a script in the .devcontainer repo
        kubectl get nodes

    The last command will ask for your fed-id and password and then show a
    list of nodes in the pollux cluster. Your credentials are cached for a
    week after which you will see authentication errors. To fix this
    repeat the above steps.

You devcontainer environment is configured by a file called
``.bashrc_dev`` file. The terminals in the devcontainer will source this
file when they start.

Much of this file is setting up convenience features like the prompt and bash
history. You can change these to suit your own preferences.

The primary configuration options are the environment variables exported by
this script. These are listed below with some recommended values for running
these tutorials. Paste the following into the ``.bashrc_dev`` file and
add your GitHub organization or user to K8S_HELM_REGISTRY.

.. code-block:: bash

    ############ REPLACE all environment below with your details ###################

    # point at your cluster config file
    export KUBECONFIG=/home/${USER}/.kube/config

    # the default domain for ec commands (REMOVE if this is supplied by the host)
    export K8S_DOMAIN=bl01t

    # where to get HELM charts for ec commands
    export K8S_HELM_REGISTRY=ghcr.io/<YOUR GITHUB USER OR ORGANIZATION>

    ################################################################################

After editing ``.bashrc_dev`` you will need to close any open terminals and
restart them to pick up the changes.


.. Note::

    For advanced users with knowledge of docker or podman.

    You can also alter the parameters for launch of the container by editing the
    ``.devcontainer/devcontainer.json`` file.
    `See here for details <https://containers.dev/implementors/json_reference/>`_

    In addition, you can alter the system packages installed in the container or make
    any other changes to the Dockerfile and regenerate your own container image.

    To pick up such changes to ``.devcontainer`` run the ``Rebuild Container``
    command from VSCode command pallette (accessed via ctrl-shift-P).

    If you wish to persist these changes
    then it is suggested that you make your own github repo of .devcontainer and
    push the changes there.
