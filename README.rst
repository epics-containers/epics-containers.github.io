epics-containers
================

|docs_ci| |license|

The epics-containers GitHub organization holds a collection of tools and
documentation for building, deploying and managing containerized EPICS IOCs
in a Kubernetes cluster.

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


..
    Anything below this line is used when viewing README.rst and will be replaced
    when included in index.rst

See https://epics-containers.github.io for more detailed documentation.

Update for March 2023
=====================

Since the documentation for epics-containers was first published in Oct 2021,
there have been significant updates to the projects in this organization.

The documentation is now being updated to reflect these changes.

Notable improvements are:

- The developer experience has now been improved.

  - Addition of a developer container with all the tools needed to build
    and test the epics-containers projects included.
  - Addition of a CLI tool to assist building deploying and managing
    containerize EPICS IOCs.

- overhaul of the container build approach to minimize cache busting and
  improve build times.

- Addition of support for IOCS running on MVME5500 with RTEMS 5. (this
  could be extended to any cross-compiled architectures that use a
  telnet shell and get their binaries from share file-systems (such as TFTP))
