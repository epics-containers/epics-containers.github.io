epics-containers Organization Documentation
===========================================

|docs_ci| |license|

epics-containers is an experimental area for trying ideas for managing
EPICS IOCs in a kubernetes cluster.

This will include a full implemtation of all the IOCs for the test beamline
BL45P at Diamond Light Source.

The organization includes container images for generic iocs and
these might also be used independently of kubernetes.

============== ==============================================================
Docs Source    https://github.com/epics-containers/k8s-epics-docs
Documentation  https://epics-containers.github.io
============== ==============================================================

An important principal of the approach presented here is that an IOC container
image represents a 'generic' IOC. The generic IOC image is used for all
IOC instances that connect to a give class of device.

An IOC instance will use a generic IOC image plus some configuration that
will bootstrap the unique properties of the instance. In nearly all cases the
configuration need only be a single IOC boot script.

This approach reduces the number of images required and saves disk. It also
makes for simple configuration management.

.. |docs_ci| image:: https://github.com/epics-containers/k8s-epics-docs/workflows/Docs%20CI/badge.svg?branch=master
    :target: https://github.com/epics-containers/k8s-epics-docs/actions?query=workflow%3A%22Docs+CI%22
    :alt: Docs CI

.. |license| image:: https://img.shields.io/badge/License-Apache%202.0-blue.svg
    :target: https://opensource.org/licenses/Apache-2.0
    :alt: Apache License

..
    Anything below this line is used when viewing README.rst and will be replaced
    when included in index.rst

See https://epics-containers.github.io for more detailed documentation.
