.. _setup_k8s_beamline:


Create a New Kubernetes Beamline
================================

.. warning::

    This is a first draft that has been tested against a DLS test beamline
    only. I will remove this warning once it has been tested against:

    - the k3s example cluster described in the previous tutorial
    - a real DLS beamline.

    TODO: would it be better to have a separate tutorial for each of these?

Up until now the tutorials have been deploying IOCs to the local docker or
podman instance on your workstation. In this tutorial we look into setting
up a Kubernetes cluster for a beamline and deploying a test IOC there.

The advantage of using Kubernetes is that it is a production grade container
orchestration system. It will manage the CPU, disk and memory available across
your cluster of nodes, scheduling your IOCs and other services accordingly.
It will also restart them if they fail and monitor their health.
It can provide centralised logging and monitoring
of all of your services including IOCs.


In this tutorial we will create a new beamline in the Kubernetes cluster.
Here we assume that the cluster is already setup and that there is
a namespace configured for use by the beamline. See the previous tutorial
for how to set one up if you do not have this already.

.. note::

    DLS users: these instructions are for the BL46P beamline. This beamline
    already exists at DLS, so you could just skip ahead to creating the
    example IOC. You will need to ask the cloud team for permission on
    cluster ``pollux``, namespace ``p46-iocs`` to do this.
    Go to this URL to request access:
    https://jira.diamond.ac.uk/servicedesk/customer/portal/2/create/92

    HOWEVER, these instructions can be also used to setup any
    new beamline at DLS - just substitute the beamline name where appropriate.
    You will need to have a beamline cluster already created for the
    beamline by the cloud team and have requested access via the URL above.

Create a new beamline repository
--------------------------------

To create a new beamline repository, use the template repository at
https://github.com/epics-containers/blxxi-template. Click on the green
"Use this template" button to create a new repository. Name the repository
bl46p (or choose your own name and remember to substitute it in the rest of
this tutorial). Create this repository in your own GitHub account.

.. note::

    DLS users: if this is real beamline then it needs to be
    created in our internal GitLab registry at
    https://gitlab.diamond.ac.uk/controls/containers/beamline.
    For this purpose use the template description for `bl38p
    <https://github.com/epics-containers/bl38p?tab=readme-ov-file#how-to-create-a-new-beamline--accelerator-domain>`_.

    For test DLS beamlines these should still be created in github
    as per the below instructions.

Clone the new repository to your local machine and change directory into it.

.. code-block:: bash

    git clone https://github.com/YOUR_GITHUB_ACCOUNT/bl46p.git
    cd bl46p

Next make some changes to the repository to customise it for your beamline.
Cut and paste the following script to do so.

.. code-block:: bash

    BEAMLINE=bl46p

    # update the readme
    echo "Beamline repo for the beamline $BEAMLINE" > README.md

    # remove the sample IOC directory
    rm -r iocs/blxxi-ea-ioc-01
    # change the services setup scripts to use the new beamline name
    sed -i "s/blxxi/$BEAMLINE/g" services/* beamline-chart/values.yaml

Cluster Topologies
------------------

There are two supported topologies for beamline clusters:

- shared cluster with multiple beamlines' IOCs running in the same cluster
- dedicated cluster with a single beamline's IOCs running in the cluster

If you are working with the single node k3s cluster set up in the previous
tutorial then this will be considered a dedicated cluster.

If you are creating a real DLS beamline or accelerator domain then this will
also be a dedicated cluster. You will need to make sure the cloud team has
created the cluster for the beamline and you have permissions to use it.

If you are working with one of the test beamlines at DLS then these are usually
shared topology and are set up as nodes on the Pollux cluster.

Other facilities are free to choose the topology that best suits their needs.

Shared Clusters
~~~~~~~~~~~~~~~

In the shared cluster topology we would usually want IOCs to run on the
servers that are closest to the beamline. This is important for Channel Access
because it is a broadcast protocol and by default only works on a single
subnet.

To facilitate this we use ``node affinity rules`` to ensure that IOCs
run on the beamline's specific nodes. ``Node affinity`` can look for a ``label``
on the node to say that it belongs to a beamline.
We can also use ``taints`` to stop other pods from
running on our beamline nodes. A ``taint`` will stop pods from being scheduled
on a node unless the pod has a matching toleration.

For example the test beamline p46 at DLS has the following ``taints`` and
``labels``:

.. code-block::

    Labels:         beamline=bl46p
                    nodetype=test-rig

    Taints:         beamline=bl46p:NoSchedule
                    nodetype=test-rig:NoSchedule

If you are working with your facility cluster then, you are may not to
have permission to set up these labels and taints. In this case, your
administrator will need to do this for you. At DLS, you should expect that
this is already set up for you.

For an explanation of these K8S concepts see

- `Taints and Tolerances <https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/>`_
- `Node Affinity <https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity-beta-feature>`_

Dedicated Clusters
~~~~~~~~~~~~~~~~~~

In the dedicated cluster topology we would usually want to let the IOCs
run on all of the worker nodes in the cluster. In this case the only thing
that is required is a namespace in which to run your IOCs.

By convention we use a namespace like ``bl46p-iocs`` for this purpose. This
namespace will need the appropriate permissions to allow the IOCs to run
with network host.

Environment Setup
-----------------

Every beamline repository has an ``environment.sh`` file used to configure
your shell so that the command line tools know which cluster to talk to.
Up to this point we have been using the local docker or podman instance,
but here we will configure it to use the beamline cluster.

For the detail of what goes into ``environment.sh`` see
`../reference/environment`.

Now edit ``environment.sh`` make changes as follows:

Section 1
~~~~~~~~~

Change this section to set the following variables:

.. code-block:: bash

    export EC_REGISTRY_MAPPING='github.com=ghcr.io'
    export EC_K8S_NAMESPACE=p46-iocs
    export EC_DOMAIN_REPO=git@github.com:YOUR_GITHUB_ACCOUNT/bl46p.git

This tells the ``ec`` command line tool to use the GitHub container registry
when it sees github projects, the name of the Kubernetes namespace to use and
the location of the beamline repository.

Section 2
~~~~~~~~~

The script should also make sure that ``ec`` CLI is available and it is also
useful to set up command line completion up. The simplest way to do this is:

.. code-block:: bash

    set -e # exit on error
    source <(ec --show-completion ${SHELL})

For a review of how to set up the epics-containers-cli tool ``ec`` see
`python_setup` and `ec`.

Section 3
~~~~~~~~~

This is where you make sure the cluster is contactable. For the k3s cluster
we set up the default ``~/.kube/config`` file to point to the local cluster.
So we can leave this section blank.

At DLS you would need to load a module to set up the environment for the
beamline cluster. For example:

.. code-block:: bash

    module load pollux # for all test beamlines
    module load k8s-i22 # for the real beamline i22

Once ``environment.sh`` is set up, source it to set up your shell.

.. code-block:: bash

    source environment.sh

You are now ready to start talking to the cluster. You can verify this with
the following command that should list all the nodes on the cluster. You
will be asked for your credentials if required.

.. code-block:: bash

    kubectl get nodes

Setting up the Beamline Helm Chart Defaults
-------------------------------------------

The beamline helm chart is used to deploy IOCs to the cluster. Each IOC instance
gets to override any of the settings available in the chart. This is done
in ``iocs/<iocname>/values.yaml`` for each IOC instance. However, all
settings except ``image`` have default values supplied at the beamline level.
For this reason most IOC instances only need supply the ``image`` setting
which specifies the Generic IOC container image to use.

Before making the first IOC instance we need to set up the beamline defaults.
These are all held in the file ``beamline-chart/values.yaml``.

Open this file and make the following changes depending on your beamline
type.

All cluster types
~~~~~~~~~~~~~~~~~

.. code-block:: yaml

  beamline: bl46p
  namespace: p46-iocs
  hostNetwork: true # required for channel access access on the host

  opisClaim: bl46p-opi-claim
  runtimeClaim: bl46p-runtime-claim
  autosaveClaim: bl46p-autosave-claim

k3s single server cluster
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

  dataVolume:
    pvc: true
    # point at a PVC created by kubernetes
    hostPath: /data/

DLS test beamlines
~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

  dataVolume:
    pvc: true
    # point at local disk on the server
    hostPath: /exports/mybeamline

  # extra tolerations for the training rigs
  tolerations:
  - key: nodetype
      operator: "Equal"
      value: training-rig
      effect: "NoSchedule"

DLS real beamlines
~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

  dataVolume:
    pvc: true
    # point at the shared filesystem data folder for the beamline
    hostPath: /dls/p46/data

Set Up The One Time Only Beamline Resources
-------------------------------------------

There are two scripts in the ``services`` directory that set up some initial
resources. You should run each of these in order:

- ``services/install-pvcs.sh``: this sets up some persistent volume claims for
   the beamline. PVCS are Kubernetes managed chunks of storage that can be
   shared between pods if required. The 3 PVCS created here relate to the
   ``Claim`` entries in the ``beamline-chart/values.yaml`` file. These are
   places to store:
   - autosave files
   - runtime generated startup scripts and EPICS database files
   - OPI screens (usually auto generated)
- ``services/install-opi.sh``: this sets up an nginx web server for the
   beamline. It serves the OPI screens from the ``opisClaim`` PVC. Each IOC
   instance will place its OPI screens in a subdirectory of this PVC.
   OPI clients like phoebus can then retrieve these files via HTTP.

Create a Test IOC to Deploy
---------------------------

TODO: WIP (but this looks just like it did in the first IOC deployment tutorial)
