Add an IOC instance to a beamline
=================================

Introduction
~~~~~~~~~~~~

In the tutorials section we created a beamline repository that contains
a single IOC called example. Here we discuss how to create your own IOCs
using this example as a template.

Quick Start
~~~~~~~~~~~

At present this discussion is around copying and modifying the Helm Chart
definition for the IOC. In future the tool **ibek** will generate the Helm
Chart from a YAML description of the IOC.

Inside the beamline repo the folder iocs/example holds a Helm Chart. Much of
the contents is boilerplate so creating a new IOC involves:

- making a copy of the example IOC folder, giving it the name of your new IOC.
- Then the modifying a few files as follows:

:Chart.yaml:
    change the name and description fields

:values.yaml:
    - update the name of the beamline for this IOC instance
    - choose a base image for the generic IOC
    - for production deployment you may want to change other fields discussed later

:config/ioc.boot:
    - replace this with your IOC startup script
    - you can also put any other files needed by the startup script in this folder
    - but the total size cannot exceed 1MB

:config/start.sh:
    - this is the script called on container startup
    - it is intended to be generic but can be altered if special startup is needed

The generic IOC base image needs to contain all of the support modules required
by your IOC. A selection of such images is available at
https://github.com/orgs/epics-containers/packages. If you need an additional
generic IOC image then see `create_ioc`.

For the moment you will have to implement your own approach to providing a GUI,
see `no_opi`.

Production Deployment
~~~~~~~~~~~~~~~~~~~~~

For a more complete deployment there are a few more fields in values.yaml
that may be useful. Below is the default template value.yaml from example:

.. code-block:: yaml

    beamline: blxxi
    namespace: epics-iocs
    base_image: ghcr.io/epics-containers/ioc-adsimdetector:2.10r2.0

    # root folder of generic ioc source - not expected to change
    iocFolder: /epics/ioc

    # when autosave is true: create PVC and mount at /autosave
    autosave: false
    # when useAffinity is true: only run on nodes with label beamline:blxxi
    useAffinity: false
    # resource limits
    memory: 2048Mi
    cpu: 4

:autosave:

    If set to true then Kubernetes is instructed to create a Persistent
    Volume Claim and mount it at /autosave. You should configure autosave in
    your startup script to save its files in /autosave. The PVC will be
    persisted even through IOC upgrades. NOTE: this requires that your cluster
    has PVC dynamic provisioning. See `storage provisioning`_.

:useAffinity:

    This allows us to target the worker nodes on which the IOC instance will
    run. At DLS we have beamline worker nodes remote from the central cluster
    that reside on the beamline's own subnet. This is a very useful way to
    solve network protocol issues.

    When useAffinity is true the IOC pod will only run on nodes with the label
    beamline:blxxi (where blxxi is the beamline name supplied at he top of
    values.yaml)

    Also the pod will be given a tolerance for the taint nodetype=blxxi ,
    effect=NoSchedule. This means that you can create a taint on the
    beamline worker nodes so they only run beamline IOCs. For details of
    configuring your nodes like this see `taints and tolerations`_.

:memory:

    This specifies a resource limit and helps Kubernetes balance resources
    across available nodes. This limit will be enforced on your IOC instance.

:cpu:

    This is also a resource limit and is in units of whole cores. May be
    specified in milli-CPU e.g. 500m is half a CPU. The IOC instance will be
    throttled if it exceeds this limit.

..  _storage provisioning: https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/
.. _taints and tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

Future Improvements
~~~~~~~~~~~~~~~~~~~

This is the full set of options that the helm library supports at present.
It is only a first pass implementation and much finer control of the
Kubernetes deployment could be exposed in future.