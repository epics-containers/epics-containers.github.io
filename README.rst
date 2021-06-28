epics-containers
================

|docs_ci| |license|

epics-containers is an experimental GitHub organization to try out ideas
for managing EPICS IOCs in a Kubernetes cluster.

Please contribute with comments and suggestions in the wiki or issues pages:

============== ==============================================================
Documentation  https://epics-containers.github.io
Wiki           https://github.com/epics-containers/epics-containers.github.io/wiki
Issues         https://github.com/epics-containers/epics-containers.github.io/issues
Docs Source    https://github.com/epics-containers/epics-containers.github.io
Organization   https://github.com/epics-containers
============== ==============================================================


.. |docs_ci| image:: https://github.com/epics-containers/k8s-epics-docs/workflows/Docs%20CI/badge.svg?branch=main
    :target: https://github.com/epics-containers/k8s-epics-docs/actions?query=workflow%3A%22Docs+CI%22
    :alt: Docs CI

.. |license| image:: https://img.shields.io/badge/License-Apache%202.0-blue.svg
    :target: https://opensource.org/licenses/Apache-2.0
    :alt: Apache License


Overview
========

.. include:: overview.rst

This diagram shows how the assets combine to create a running IOC on a
Kubernetes worker node.

.. image:: images/example.png
    :width: 1500px
    :align: center

- The Helm Chart defines an IOC instance: IMAGE + STARTUP SCRIPT + K8S DEPLOYMENT​
- The entire definition of the P45 beamline is held in https://github.com/orgs/epics-containers/packages

..
    Anything below this line is used when viewing README.rst and will be replaced
    when included in index.rst

See https://epics-containers.github.io for more detailed documentation.
