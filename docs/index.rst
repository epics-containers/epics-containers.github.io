:html_theme.sidebar_secondary.remove:

.. include:: ../README.rst
    :end-before: when included in index.rst

Update for October 2023
=======================
The final round of improvements done. The latest framework has
become much simpler and has a good developer experience.

**WARNING**

The Tutorials are currently out of date and won't work. These are
being updated now and will be available by end of November 2023.


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
