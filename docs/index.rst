:html_theme.sidebar_secondary.remove:

.. include:: ../README.rst
    :end-before: when included in index.rst

Quick Start
===========

For a set of tutorials to introduce the concepts of epics-containers see
`user/tutorials/intro`. For a description of the architecture see
`essential`.


Update for October 2023
=======================
The final round of improvements are under way. The latest framework has
become much simpler and has a good developer experience.

The Tutorials are currently out of date and won't work. These should be
updated to the new Epics Containers Framework by end of Nov 2023.

Update for March 2023
=====================

Since the documentation for epics-containers was first published in Oct 2021,
there have been significant updates to the projects in this organization.

The documentation is now being updated to reflect these changes.

Notable improvements are:

- The developer experience has now been improved.

  - Addition of a developer container with all the necessary tools included
  - Addition of a CLI tool to assist building deploying and managing
    containerize EPICS IOCs.

- simplified container build approach which minimizes cache busting and
  improves build times.

- Addition of support for IOCS running on MVME5500 with RTEMS 5. (this
  could be extended to any cross-compiled architectures that use a
  telnet shell and get their binaries from share file-systems (such as TFTP
  or NFS))


Communication
=============

If you are interested in discussing containers for control systems, please:

- Add a brief description of your project and the status of it's use of containers to:

  - https://github.com/epics-containers/epics-containers.github.io/wiki/Brief-Overview-of-Projects-Using-Containers-in-Controls
- Join in the discussion at https://github.com/epics-containers/epics-containers.github.io/discussions


Materials
=========

The following links are to materials presented at the ICALEPCS 2021 Meeting:

  - :download:`ICALEPCS 2021 Paper: Kubernetes for EPICS IOCs<user/images/THBL04.PDF>`
  - :download:`ICALEPCS 2021 Talk: Kubernetes for EPICS IOCs<user/images/THBL04_talk.PDF>`


How the documentation is structured
-----------------------------------

The documentation is split into 2 sections:

.. grid:: 2

    .. grid-item-card:: :material-regular:`person;4em`
        :link: user/index
        :link-type: doc

        The User Guide contains documentation on how create, deploy and manage containerized IOCs.

    .. grid-item-card:: :material-regular:`code;4em`
        :link: developer/index
        :link-type: doc

        The Developer Guide contains documentation on how to develop and contribute changes back to the epics-containers organization

.. toctree::
    :hidden:

    user/index
    developer/index
