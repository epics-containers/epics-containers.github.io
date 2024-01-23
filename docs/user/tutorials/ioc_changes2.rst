Changing a Generic IOC
======================

This is a type 2 change from `ioc_change_types`.

The changes that you can make in an IOC instance are limited to what
the author of the associated Generic IOC has made configurable.
Therefore you will
occasionally need to update the Generic IOC that your instance is using.
Some of the reasons for doing this are:

- Update one or more support modules to new versions
- Add additional support such as autosave or iocStats
- For ibek generated IOC instances, you may need to add or change functionality
  in the support YAML file.

.. note::

    If you are considering making a change to a Generic IOC because you
    want to add support for a second device, this is allowed but you should
    consider the alternative of creating a new Generic IOC.
    If you keep your Generic IOCs simple and focused on a single device, they
    will be smaller and there will be less of them. IOCs can still be
    linked via CA and this is preferable to recompiling a Generic IOC
    for every possible combination of devices. Using Kubernetes to
    manage multiple small services is cleaner than having a handful of
    monolithic services.


This tutorial will make some changes to the generic IOC ``ioc-adsimdetector``
that you already used in earlier tutorials.

For this exercise we will work locally inside the ``ioc-adsimdetector``
developer container. To discover how to fork repositories and push changes
back to GitHub

For this exercise we will be using an example IOC Instance to test our changes.
Instead of working with a beamline repository, we will use the example ioc instance
inside ``ioc-adsimdetector``. It is a good idea for Generic IOC authors to
include an example IOC Instance in their repository for testing changes in
isolation.

Preparation
-----------

First, clone the ``ioc-adsimdetector`` repository and make sure the container
build is working:

.. code-block:: console

    git clone git@github.com:epics-containers/ioc-adsimdetector.git
    cd ioc-adsimdetector
    ./build
    code .
    # Choose "Reopen in Container"

Note that if you do not see the prompt to reopen in container, you can open
the ``Remote`` menu with ``Ctrl+Alt+O`` and select ``Reopen in Container``.

The ``build`` script does two things.

- it fetches the git submodule called ``ibek-support``. This submodule is shared
  between all the EPICS IOC container images and contains the support YAML files
  that tell ``ibek`` how to build support modules inside the container
  environment.
- it builds the Generic IOC container image locally.

.. note::

    The ``build`` script is a convenience script that is provided in the
    Generic IOC Template project. It is exactly equivalent to cloning
    with ``--recursive`` flag and then running ``ec dev build``.

Verify the Example IOC Instance is working
------------------------------------------

When a new Generic IOC developer container is opened, there are two things
that need to be done before you can run an IOC instance inside of it.

- Build the IOC binary
- Select an IOC instance definition to run

The folder ``ioc`` inside of the ``ioc-adsimdetector`` is where the IOC source code
resided. However the devcontainer always makes a symlink to this folder at
``/epics/ioc``. This is so that it is always in the same place and can easily be
found by ibek and the developer. Therefore you can build the binary with the
following command:

.. code-block:: console

    cd /epics/ioc
    make

.. note::

    Note that we are required to build the IOC.
    This is even though the container you are using already had the IOC
    source code built by its Dockerfile (``ioc-adsimdetector/Dockerfile``
    contains the same command).

    For a detailed explanation of why this is the case see
    `ioc-source`

The IOC instance definition is a YAML file that tells ``ibek`` what the runtime
assets (ie. EPICS DB and startup script) should look like. Previous tutorials
selected the IOC instance definition from a beamline repository. In this case
we will use the example IOC instance that comes with ``ioc-adsimdetector``. The
following command will select the example IOC instance:

.. code-block:: console

    ibek dev instance /epics/ioc-adsimdetector/ioc_examples/bl01t-ea-ioc-02

In an earlier tutorial when learning about the dev container, we manually
performed this step, see `choose-ioc-instance`. The above command does
exactly the same thing: removes the existing config folder in ``/epics/ioc``
and symlinks in the chosen IOC instance definition's ``config`` folder.

Now  run the IOC:

.. code-block:: console

    cd /epics/ioc
    ./start.sh

You should see an iocShell prompt and no error messages above.
