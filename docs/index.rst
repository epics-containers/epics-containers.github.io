.. include:: ../README.rst
    :end-before: when included in index.rst

How the documentation is structured
===================================

Documentation is split into four categories, accessible from links in the side-bar.

.. rst-class:: columns

Tutorials
~~~~~~~~~

Tutorials for setting up a test cluster, and deploying an IOC.

.. rst-class:: columns

Explanations
~~~~~~~~~~~~

Explanation of the principal ideas for deploying IOCs in Kubernetes.

.. rst-class:: columns

How-to Guides
~~~~~~~~~~~~~

Practical step-by-step guides for the more experienced user.

.. rst-class:: columns

Reference
~~~~~~~~~

Technical reference material.

.. rst-class:: endcolumns

.. toctree::
    :caption: Tutorials
    :hidden:

    tutorials/setup_k8s
    tutorials/useful_k8s
    tutorials/create_beamline
    tutorials/deploy_example
    tutorials/manage_iocs

.. toctree::
    :caption: Explanations
    :hidden:

    explanations/introduction
    explanations/whats_in
    explanations/net_protocols
    explanations/kubernetes_cluster

.. toctree::
    :caption: How-to Guides
    :hidden:

    how-to/add_ioc
    how-to/create_ioc
    how-to/generic_iocs
    how-to/debug

.. rst-class:: no-margin-after-ul

.. toctree::
    :caption: Reference
    :hidden:

    reference/faq
    reference/cli
    reference/contributing

.. rst-class:: endcolumns

About the documentation
~~~~~~~~~~~~~~~~~~~~~~~

`Why is the documentation structured this way? <https://documentation.divio.com>`_
