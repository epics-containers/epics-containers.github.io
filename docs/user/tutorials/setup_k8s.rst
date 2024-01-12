.. _setup_kubernetes:


Setup a Kubernetes Server
=========================

.. Note::

    **DLS Users**: DLS already has the test cluster ``Pollux`` which includes
    the test beamline p45 and the training beamlines p46 through to p49.

    We have also started to roll out production clusters for some of our
    beamlines. To date we have clusters for p38, i20, i22 and c01.

    For this reason DLS users should skip this tutorial unless you have a
    spare linux machine with root access and an interest in how Clusters
    are created.

Introduction
------------
This is a very easy set of instructions for setting up an experimental
single-node Kubernetes cluster, ready to test deployment of EPICS IOCs.


Bring Your Own Cluster
----------------------

If you already have a Kubernetes cluster then you can skip this section.
and go straight to the next tutorial.

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

Here we will create a namespace for our first test beamline bl46p. We are
using this name because it is the name of the first test Kubernetes beamline
at DLS. This just means I can use some of the following tutorials for both
DLS and non-DLS users.

From the workstation INSIDE the devcontainer execute the following:

.. code-block:: bash

    kubectl create namespace bl46p
    kubectl config set-context bl46p --namespace=bl46p --user=default --cluster=default
    kubectl config use-context bl46p

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
        name: bl46p-priv
    EOF

Generate a login token for the account:

.. code-block:: bash

    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    metadata:
        name: bl46p-priv-secret
        annotations:
            kubernetes.io/service-account.name: bl46p-priv
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

