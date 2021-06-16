epics-containers
================

|docs_ci| |license|

epics-containers is an experimental GitHub organizaion to try out ideas
for managing EPICS IOCs in a Kubernetes cluster.

============== ==============================================================
Docs Source    https://github.com/epics-containers/k8s-epics-docs
Documentation  https://epics-containers.github.io/k8s-epics-docs/
============== ==============================================================

An important principal of the approach presented here is that an IOC container
image represents a 'generic' IOC. The generic IOC image is used for all
IOC instances that connect to a given class of device.

An IOC instance runs in a container that bases its
filesystem on a generic IOC image.
In addition the instance has configuration mapped into the
container that will bootstrap the unique properties of that instance.
In most cases the configuration need only be a single IOC boot script.

This approach reduces the number of images required and saves disk. It also
makes for simple configuration management.

.. |docs_ci| image:: https://github.com/epics-containers/k8s-epics-docs/workflows/Docs%20CI/badge.svg?branch=main
    :target: https://github.com/epics-containers/k8s-epics-docs/actions?query=workflow%3A%22Docs+CI%22
    :alt: Docs CI

.. |license| image:: https://img.shields.io/badge/License-Apache%202.0-blue.svg
    :target: https://opensource.org/licenses/Apache-2.0
    :alt: Apache License

..
    Anything below this line is used when viewing README.rst and will be replaced
    when included in index.rst

See https://epics-containers.github.io for more detailed documentation.
