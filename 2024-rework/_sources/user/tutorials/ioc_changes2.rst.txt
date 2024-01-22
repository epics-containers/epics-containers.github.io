Changing a Generic IOC
======================

.. warning ::

    TODO: This tutorial is a work in progress. It is not yet complete.

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

This tutorial will make some changes to the generic IOC ``ioc-adsample``.
This Generic IOC is a simplified copy of ``ioc-adsimdetector`` tailored for
use in these tutorials.

For this exercise we will initially work locally inside the ``ioc-adsample``
developer container.

At the end we will push the changes and see the CI build a new version of the
generic IOC container image. This allows for the demonstration of:

- Deploying an IOC instance using a new image published by the CI
- Showing how to do a Pull Request back to the original repository.

For this exercise we will be using an example IOC Instance to test our changes.
Instead of working with a beamline repository, we will use the example ioc instance
that comes with ``ioc-adsample``. It is a good idea for Generic IOC authors to
include an example IOC Instance in their repository for testing changes in
isolation.


Preparation
-----------

Because we want to push our changes we will first make a fork of the
``ioc-adsample`` repository. We will then clone our fork locally and
make the changes there.

To make a fork go to
`ioc-adsample <https://github.com/epics-containers/ioc-adsample>`_
and click the ``Fork`` button in the top right corner. This will create a fork
of the repository under your own GitHub account.

Now, clone the fork, build the container image locally and open the
developer container:

.. code-block:: console

    git clone git@github.com:<YOUR GITHUB ACCOUNT NAME>/ioc-adsample.git
    cd ioc-adsample
    ./build
    code .
    # click the green button in the bottom left corner of vscode and select
    # "Reopen in Container"

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

- Build the IOC source code
- Select an IOC instance definition to run

The folder ``ioc`` inside of the ``ioc-adsample`` is where the IOC source code
is created and built. When you open the developer container, this folder does
not yet exist. The following command will create it and build the IOC:

.. code-block:: console

    ec ioc build

The IOC instance definition is a YAML file that tells ``ibek`` what the runtime
assets (ie. EPICS DB and startup script) should look like. Previous tutorials
selected the IOC instance definition from a beamline repository. In this case
we will use the example IOC instance that comes with ``ioc-adsample``. The
following command will select the example IOC instance:

.. code-block:: console

    ibek dev instance /epics/ioc-adsample/ioc_examples/bl01t-ea-ioc-02

In an earlier tutorial when learning about the dev container, we manually
performed this step, see `choose-ioc-instance`. The above command does
exactly the same thing: removes the existing config folder in ``/epics/ioc``
and symlinks in the chosen IOC instance definition's ``config`` folder.

Now  run the IOC:

.. code-block:: console

    ibek dev run

You should see a iocShell prompt and no error messages above.

.. note::

    The ``ec ioc build`` command required to re-create the IOC source code.
    This is even though the container you are using already had the IOC
    source code built by its Dockerfile (``ioc-adsample/Dockerfile``
    contains the same command).

    For a detailed explanation of why this is the case see
    `ioc-source`


TODO: complete by adding iocStats and using it in the ioc instance, then
pushing and verifying CI runs and publishes a new image.
TODO: now that cacheing is working, consider using ioc-adsimdetector instead
of ioc-adsample. This is simpler - the change could be the addition of
auto start of the sim detector IOC just like the presentation.
