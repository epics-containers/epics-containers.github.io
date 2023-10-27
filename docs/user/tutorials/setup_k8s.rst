.. _setup_kubernetes:


Setup a Kubernetes Server
=========================

.. Warning::

    This information is out of date. It will be updated soon.

.. Note::

    **DLS Users**: DLS already has the test cluster Pollux and further
    beamline and machine clusters are coming soon.

    To use the Pollux cluster, run ``module load pollux`` outside of the
    devcontainer and then run the script ``.devcontainer/dls-copy-k8s-crt.sh``

    The Pollux Cluster already has a beamline namespace ``bl01t``
    for you to use as a training area. *You will need
    to ask SciComp to add you as a user of this namespace.*
    Please be aware that this is a shared resource so others might be using
    it at the same time.

    The Pollux Cluster already has the Kubernetes dashboard installed.
    To access it go to http://pollux.diamond.ac.uk and click
    ``Pollux K8S Dashboard``.

    Then select ``bl01t`` from the namespace drop down menu in the top left,
    to see the training namespace.

Introduction
------------
This is a very easy set of instructions for setting up an experimental
single-node Kubernetes cluster,
ready to test deployment of EPICS IOCs.

.. note::

    From this point onward the tutorials assume that you are using
    Kubernetes and Helm to deploy your EPICS IOCs.

    However:

    The approach of creating Generic IOC's in containers and then deploying
    IOC instances as Generic IOC's + some configuration will also work
    standalone, or with other orchestration tools. e.g. In `ioc_changes`
    we will demonstrate running an IOC locally using podman alone.


Bring Your Own Cluster
----------------------

If you already have a Kubernetes cluster then you can skip this section.
and go straight to `./create_beamline`.

IMPORTANT: you will require appropriate permissions on the cluster to work
with epics-containers. In particular you will need to be able to create
pods that run with network=host. This is to allow Channel Access traffic
to be routed to and from the IOCs. You will also need to be able to create
a namespace and a service account, although you could use an existing
namespace and service account as long as it has network=host capability.

Cloud based K8S offerings may not be appropriate because of the Channel Access
routing requirement.

Platform Choice
---------------

These instructions have been tested on the following platforms. The simplest
option is to use a linux distribution that is supported by k3s.

========================== ============================================
Ubuntu 20.10               any modern linux distro should also work
Raspberry Pi OS 2021-05-07 See `raspberry`
Windows WSL2               See `wsl`
========================== ============================================

Note that K3S provides a good uninstaller that will clean up your system
if you decide to back out. So there is no harm in trying it out.

If you prefer to investigate other implementations there are also these
easy to install, lightweight Kubernetes implementations:

  - kind https://kind.sigs.k8s.io/docs/user/quick-start/
  - microk8s https://microk8s.io/
  - minikube https://minikube.sigs.k8s.io/docs/start/

For k3s documentation see https://k3s.io/.

Installation Steps
------------------

These instructions work with a single machine or with a server running k3s
and a workstation running the client CLI. The client CLI commands should
all be run inside the devcontainer (at an [E7] prompt).


Install K3S lightweight Kubernetes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This command should be run OUTSIDE of the devcontainer.

Execute this command on your server to set up the cluster master
(aka K3S Server node)::

    curl -sfL https://get.k3s.io | sh -

.. _install_kubectl:

Configure kubectl
~~~~~~~~~~~~~~~~~

Kubectl is the command line tool for interacting with Kubernetes Clusters. It is
already installed inside the devcontainer. It uses a configuration file in
$HOME/.kube to connect to the cluster. Here we will copy the configuration file
from the server to the workstation.

These commands should be run OUTSIDE of the devcontainer.

If you have one machine only then copy the k3s kubectl configuration:

.. code-block:: bash

    mkdir ~/.kube
    sudo cp  /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown <YOUR USER> ~/.kube/config

If you have a separate server then from the server machine copy over the k3s
kubectl configuration:

.. code-block:: bash

    mkdir ~/.kube
    sudo scp  /etc/rancher/k3s/k3s.yaml <YOUR_ACCOUNT>@<YOUR_WORKSTATION>:.kube/config

If you do have separate workstation then edit the file .kube/config replacing
127.0.0.1 with your server's IP Address. For a single machine the file is left
as is.


Create an epics IOCs namespace and context
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For each beamline or EPICS domain there will be a kubernetes namespace. A
namespace is a virtual cluster within a Kubernetes cluster. Namespaces allow
us to isolate a set of cluster resources from each other, epics-containers
uses a namespace for each beamline or accelerator domain.

A context is a combination of a cluster, namespace, and user. It tells kubectl
which cluster and namespace to use when communicating with the Kubernetes API.

So here we will create a namespace for our first test beamline BEAMLINE TEST 01
or bl01t for short. We will also create a context for this namespace and set
it as the default context.

From the workstation INSIDE the devcontainer execute the following:

.. code-block:: bash

    kubectl create namespace bl01t
    kubectl config set-context bl01t --namespace=bl01t --user=default --cluster=default
    kubectl config use-context bl01t

Create a service account to run the IOCs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Inside of our new namespace we will create a service account that will be used
to run the IOCs.

Create the account:

.. code-block:: bash

    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
        name: bl01t-priv
    EOF

Generate a login token for the account:

.. code-block:: bash

    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    metadata:
        name: bl01t-priv-secret
        annotations:
            kubernetes.io/service-account.name: bl01t-priv
    type: kubernetes.io/service-account-token
    EOF



Completed
~~~~~~~~~
That's it. You now have installed the necessary software to start experimenting
with IOCs on Kubernetes.

To remove everything you have installed above and clean up the disk space
simply use this command:

.. code-block:: bash

    k3s-uninstall.sh

If you are interested in looking at the k3s files see **/var/lib/rancher/k3s/**.
