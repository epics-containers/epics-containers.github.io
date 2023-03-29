Developer Contributing
======================

This project is documentation only. However the below steps set up a virtual
python environment with the required tools to generate the sphinx documentation.

Other projects in this repository do contain code and will have their own
details on how to build and test them.

These instructions will take you through the minimal steps required to get a dev
environment setup, so you can build the documentation locally.

Once completed see `../how-to/build-docs` for how to build the documentation.

Clone the repository
--------------------

First clone the repository locally using `Git
<https://git-scm.com/downloads>`_::

    $ git clone git://github.com/epics-containers/epics-containers.github.io.git

Install dependencies
--------------------

You can choose to either develop on the host machine using a `venv` (which
requires python 3.8 or later) or to run in a container under `VSCode
<https://code.visualstudio.com/>`_

.. tab-set::

    .. tab-item:: Local virtualenv

        .. code::

            $ cd epics-containers.github.io
            $ python3 -m venv venv
            $ source venv/bin/activate
            $ pip install -e '.[dev]'

    .. tab-item:: VSCode devcontainer

        .. code::

            $ code epics-containers.github.io
            # Click on 'Reopen in Container' when prompted
            # Open a new terminal

See what was installed
----------------------

To see a graph of the python package dependency tree type::

    $ pipdeptree

Build and check
---------------

Now you have a development environment you can run checks in a terminal::

    $ tox -p

