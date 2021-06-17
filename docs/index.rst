.. include:: ../README.rst
    :end-before: when included in index.rst

How the documentation is structured
-----------------------------------

.. rst-class:: columns

:ref:`tutorials`
~~~~~~~~~~~~~~~~

Tutorials for setting up a test cluster, and deploying an IOC.

.. rst-class:: columns

:ref:`explanations`
~~~~~~~~~~~~~~~~~~~

Explanation of the principal ideas for deploying IOCs in Kubernetes.

.. rst-class:: columns

:ref:`how-to`
~~~~~~~~~~~~~

Practical step-by-step guides for the more experienced user.

.. rst-class:: columns

:ref:`reference`
~~~~~~~~~~~~~~~~

Technical reference material.

.. rst-class:: endcolumns

About the documentation
~~~~~~~~~~~~~~~~~~~~~~~

`Why is the documentation structured this way? <https://documentation.divio.com>`_

.. toctree::
    :caption: Tutorials
    :name: tutorials
    :maxdepth: 1

    tutorials/setup_k8s
    tutorials/create_beamline
    tutorials/add_ioc
    tutorials/manage_iocs

.. toctree::
    :caption: Explanations
    :name: explanations
    :maxdepth: 1

    explanations/introduction
    explanations/strategy
    explanations/whats_in
    explanations/net_protocols

.. toctree::
    :caption: How-to Guides
    :name: how-to
    :maxdepth: 1

    how-to/create_ioc
    how-to/generic_iocs
    how-to/debug
    how-to/kubernetes_cluster

.. rst-class:: no-margin-after-ul

.. toctree::
    :caption: Reference
    :name: reference
    :maxdepth: 1

    reference/faq
    reference/cli
    reference/contributing

