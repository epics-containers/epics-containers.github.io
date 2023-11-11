The Environment Configuration File
==================================

``environment.sh`` is a configuration file that is provided in each domain
(beamline or accelerator) repository. It is used to set up the environment
such that the ``epics-containers-cli`` will interact with the correct
cluster (or local server if you are not using Kubernetes).

An important part of creating a new domain repository is to edit the
``environment.sh`` so that it suits the domain you are targetting.

There are 3 sections to the file as follows:

Environment Variables Setup
---------------------------

The first section defines a number of environment variables. These should
be adjusted to suit your domain. The variables are as follows:


Required Variables
~~~~~~~~~~~~~~~~~~

-   **EC_REGISTRY_MAPPING**: defines a mapping between git source repositories and
    container repositories. This is used to determine where a Generic IOC
    container image is pushed to (or pulled from). If you are using GitHub then
    you could use the following value:

    - ``EC_REGISTRY_MAPPING='github.com=ghcr.io'``

    Which means containers whose source repository is at:

    - ``GitHub/organisation/my_generic_ioc``

    will be pushed to:

    - ``ghcr.io/organisation/my_generic_ioc:VERSION``.

    You can have multiple mappings if needed by separating them with a space.

-   **EC_K8S_NAMESPACE**: defines the namespace in a Kubernetes Cluster that your IOC
    Instances will be deployed to. When you come to set up a cluster you will
    need to create a namespace for your domain. This is the name you should
    use here. If you are not using Kubernetes then you can leave this as
    ``EC_K8S_NAMESPACE=local`` and this will deploy IOC Instances to the local server's
    docker or podman instance.

-   **EC_DOMAIN_REPO**: this is a link back to the repository that defines this
    domain. For example the bl38p reference beamline repository uses
    ``EC_DOMAIN_REPO=git@github.com:epics-containers/bl38p.git``. This variable
    is used by ``ec`` to fetch versioned IOC Instance from the repo and deploy
    time.


Optional Variables
~~~~~~~~~~~~~~~~~~

- **EC_LOG_URL**: if you have a centralized logging service with a web UI then
  you can set this variable to the URL of the web UI. This will then be
  displayed when the command ``ec ioc log-history <ioc-name>`` is run. The
  ioc name is added to the URL using ``{ioc-name}`` as a placeholder e.g.

  - ``EC_LOG_URL='https://graylog2.diamond.ac.uk/search?rangetype=relative&fields``
    ``=message%2Csource&width=1489&highlightMessage=&relative=172800&q=pod_name%3A``
    ``{ioc_name}*'``

- **EC_CONTAINER_CLI**: this sets the name of the container CLI to use. supported
  options are ``podman`` or ``docker``. If not set then ``ec`` will try to
  determine which one to use. You would only need this variable if you have
  both podman and docker installed and you want to use one over the other, or
  if you want to use a different container CLI such as ``singularity``.
  IMPORTANT: the application you reference must have docker compatible CLI
  (at least for common functions).

- **EC_DEBUG**: causes the ``ec`` command to output debug information for all
  commands. For more targetted debugging you can use ``ec -d ...``.

Installation of ``ec``
----------------------

The second section of the ``environment.sh`` file is used to install the
``ec`` command by pip installing the ``epics-containers-cli`` package. The
``blxxi-template`` project comes with a suggested way of doing this, but
it would probably be best to have ``ec`` installed globally on your
workstation and then omit this section from your ``environment.sh`` files.

Perhaps the simplest way to achieve this is to install ``ec`` into your user
space using the following command:

.. code:: bash

    pip install --user epics-containers-cli

Then add the following to your ``.bashrc`` file:

.. code:: bash

    export PATH=$PATH:$HOME/.local/bin

Connecting to a Namespace on your Kubernetes Cluster
----------------------------------------------------

The third section of the ``environment.sh`` sets up how the ``kubectl`` command
will connect to a namespace on your Kubernetes cluster. This usually involves
setting the ``KUBECONFIG`` environment variable to point to a file that contains
the cluster configuration.

When we set up a cluster in the tutorials we will create a namespace for your
and discuss how to update ``environment.sh`` to connect to it.

If you are connecting to your own facility's cluster then you will need to
ask your admins for the correct configuration.

If you are not using Kubernetes then you can leave this section out.

.. note::

    DLS users: the module system is used to connect us to each beamline/accelerator
    cluster. The example ``environment.sh`` file in ``bl38p`` shows how to do this
    see https://github.com/epics-containers/bl38p/blob/main/environment.sh

One other thing that is useful is to set up command line completion for the
Kubernetes tools ``kubectl`` and ``helm``. See the end of the bl38p
``environment.sh`` file for an example of how to do this at
https://github.com/epics-containers/bl38p/blob/main/environment.sh.



