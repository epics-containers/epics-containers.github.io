Kubernetes Resources in an IOC Instance
=======================================

TODO - This is a work in progress.

The key resources that we are asking Kubernetes to create are:

- ``Deployment``. Tells Kubernetes to run one and only one generic IOC
  container. See deployments:

  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/