Kubernetes Resources in an IOC Instance
=======================================

Learning about Helm and Kubernetes Manifests
--------------------------------------------

It is instructive to see what helm is doing when you deploy an IOC.

Helm uses templates to generate a Kubernetes Manifest which defines a set
of resources. It applies this manifest to the cluster using kubectl.

To inspect the kubernetes manifest YAML that is created when we deploy the
example IOC you can use the following command from inside of your example
beamline repository:

.. code-block:: bash

    ec ioc template iocs/bl01t-ea-ioc-01

This is expanding the local helm chart in the ``iocs/bl01t-ea-ioc-01`` folder and using
its ``templates/ioc.yaml`` plus the templates in ``helm-ioc-lib``. These templates
are expanded using the values in the ``iocs/bl01t-ea-ioc-01/values.yaml`` file and also
``beamline-chart/values.yaml`` and finally the default ``values.yaml`` file
from the helm-ioc-lib.

For a description of the key resources we create in this Kubernetes manifest
see the next heading.


Kubernetes Resources in an IOC Instance
---------------------------------------

TODO - This is a work in progress.

The key resources that we are asking Kubernetes to create are:

- ``Deployment``. Tells Kubernetes to run one and only one generic IOC
  container. See deployments:

  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/