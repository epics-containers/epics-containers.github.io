Create a Generic IOC
====================

In this tutorial you will learn how to take an existing support module and
create a Generic IOC builds it. You will also learn how to embed an
example IOC instance into the Generic IOC for testing and demonstration.

This is a type 2. change from the list at `ioc_change_types`.

Lakeshore 340 Temperature Controller
------------------------------------

The example we will use is a Lakeshore 340 temperature controller. This
is a Stream Device based support module that has historically been internal
to Diamond Light Source.

See details of the device:
`lakeshore 340 <https://www.lakeshore.com/products/categories/overview/discontinued-products/discontinued-products/model-340-cryogenic-temperature-controller>`_

.. note::

    DLS has an existing IOC building tool ``XML Builder`` for traditional
    IOCs. It has allowed DLS to have concise way of describing a beamline for many
    years. However, it requires some changes to the support modules and for this
    reason DLS maintain's a fork of all upstream support modules it uses.
    epics-containers is intended to remove this barrier to collaboration and
    use support modules from public repositories wherever appropriate. This
    includes external publishing of previously internal support modules.

The first step was to publish the support module to a public repository. The
support module now lives at:

https://github.com/DiamondLightSource/lakeshore340

The project requires a little genericizing as follows:

- add an Apache V2 LICENCE file in the root
- Make sure that configure/RELEASE has an include of RELEASE.local at the end
- change the make file to skip the ``XML Builder`` /etc folder

The commit where these changes were made is
`0ff410a3e1131 <https://github.com/DiamondLightSource/lakeshore340/commit/0ff410a3e1131c96078837424b2dfcdb4af2c356>`_

Something like these steps may be required when publishing any
facility's previously internal support modules.


Create a New Generic IOC project
--------------------------------

By convention Generic IOC projects are named ``ioc-XXX`` where ``XXX`` is the
name of the primary support module. So here we will be building
``ioc-lakeshore340``.

Much like creating a new beamline we have a template project that can be used
as the starting point for a new Generic IOC. Again we will create this in
your personal GitHub user space.

Go to the Generic IOC template project at:

https://github.com/epics-containers/ioc-template

Click on the ``Use this template`` button and create a new repository called
``ioc-lakeshore340`` in your personal GitHub account.

As soon as you do this the build in GitHub Actions CI will start building the
project. This will make a container image of the template project, but
not publish it because there is no release tag as yet. You can watch this
by clicking on the ``Actions`` tab in your new repository.

You might think building the template project was a waste of GitHub CPU. But,
this is not so, because of container build cacheing. The next time you build
the project in CI, with your changes, it will re-use most of the steps
and be much faster.

Prepare the New Repo for Development
------------------------------------

There are only three places where you need to change the Generic IOC template
to make your own Generic IOC.

#.  Dockerfile - add in the support modules you need
#.  README.md - change to describe your Generic IOC
#.  ibek-support - add new support module recipes into this submodule

To work on this project we will make a local developer container. All
changes and testing will be performed inside this developer container.

To get the developer container up and running:

.. code-block:: bash

    git clone git@github.com:<YOUR GITHUB ACCOUNT>/ioc-lakeshore340.git
    cd ioc-lakeshore340
    ./build
    code .
    # choose "Reopen in Container"

Once the developer container is running it is always instructive to have the
``/epics`` folder added to your workspace:

- File -> Add Folder to Workspace
- Select ``/epics``
- Click ignore if you see an error
- File -> Save Workspace As...
- Choose the default ``/workspaces/ioc-lakeshore340/ioc-lakeshore340.code-workspace``

Note that workspace files are not committed to git. They are specific to your
local development environment. Saving a workspace allows you to reopen the
same set of folders in the developer container, using the *Recent* list shown
when opening a new VSCode window.

Now is a good time to edit the README.md file and change it to describe your
Generic IOC as you see fit.

Initial Changes to the Dockerfile
---------------------------------

The Dockerfile is the recipe for building the container image. It is a set
of steps that get run inside a container, the starting container filesystem
state is determined by a ``FROM`` line at the top of the Dockerfile.

In the Generic IOC template the ``FROM`` line gets a version of the
epics-containers base image. It then demonstrates how to add a support module
to the container image. The ``iocStats`` support module is added and built
by the template. It is recommended to keep this module as the default
behaviour in Kubernetes is to use ``iocStats`` to monitor the health of
the IOC.

Thus you can start adding support modules by adding more ``COPY`` and ``RUN``
lines to the Dockerfile. Just like those for the ``iocStats`` module.

The rest of the Dockerfile is boilerplate and for best results you only need
to remove the comment below and replace it with the additional support
modules you need. Doing this means it is easy to adopt changes to the original
template Dockerfile in the future.

.. code-block:: dockerfile

    ################################################################################
    #  TODO - Add further support module installations here
    ################################################################################

Because lakeshore340 support is a StreamDevice we will need to add in the
required dependencies. These are ``asyn`` and ``StreamDevice``. We will
first install those inside our devcontainer as follows:

.. code-block:: bash

    cd /workspaces/ibek-support
    asyn/install.sh R4-42
    StreamDevice/install.sh 2.8.24

This pulls the two support modules from GitHub and builds them in our devcontainer.
Now any IOC instances we run in the devcontainer will be able to use these support
modules.

Next, make sure that the next build of our ``ioc-lakeshore340`` container
image will have the same support built in by updating the Dockerfile as follows:

.. note::

    You may think that there is a lot of duplication here e.g. ``asyn`` appears
    3 times. However, this is explicitly
    done to make the build cache more efficient and speed up development.
    For example we could copy everything out of the ibek-support directory
    in a single command but then if I changed a StreamDevice ibek-support file the
    build would have to re-fetch and re-make all the support modules. By,
    only copying the files we are about to use in the next step we can,
    massively increase the build cache hit rate.

.. code-block:: dockerfile

    COPY ibek-support/asyn/ asyn/
    RUN asyn/install.sh R4-42

    COPY ibek-support/StreamDevice/ StreamDevice/
    RUN StreamDevice/install.sh 2.8.24

The above adds ``StreamDevice`` and its dependency ``asyn``. For each support module
we copy it's ``ibek-support`` folder and then run the ``install.sh`` script. The
only argument to ``install.sh`` is the git tag for the version of the support
module required. ``ibek-support`` is a submodule used by all the Generic IOC
projects that contains recipes for building support modules, it will be covered
in more detail as we learn to add our own recipe for lakeshore340 below.

.. note::

    These changes to the Dockerfile mean that if we were to exit the devcontainer,
    and then run ``./build`` again, it would would add the ``asyn`` and
    ``StreamDevice`` support modules to the container image. Re-launching the
    devcontainer would then have the new support modules available right away.

    This is a common pattern for working in these devcontainers. You can
    try out installing anything you need. Then once happy with it, add the
    commands to the Dockerfile, so that these changes become permanent.


Configure the ibek-support Submodule
------------------------------------

The ``ibek-support`` submodule is used to share information about how to build
and use support modules. It contains two kinds of files:

#.  install.sh - These are used to fetch and build support modules. They are
    run from the Dockerfile as described above.

#.  IBEK support module definitions: These are used to help IOCs build their
    iocShell boot scripts and EPICS Database from YAML descriptions.

ibek-support is curated for security reasons, therefore we need to work with
a fork of it so we can add our own recipe for lakeshore340. If you make changes
to ibek-support that are generally useful you can use a pull request to get them
merged into the main repo.

Perform the following steps to create a fork and update the submodule:

- goto https://github.com/epics-containers/ibek-support/fork
- uncheck ``Copy the main branch only``
- click ``Create Fork``
- click on ``<> Code`` and COPY the *HTTPS* URL
- cd to the ioc-lakeshore340 directory
-
  .. code-block:: bash

        git submodule set-url ibek-support <PASTE *HTTPS* URL HERE>
        git submodule init
        git submodule update
        cd ibek-support
        git checkout tutorial-KEEP # see note below
        cd ..

We are using the ``tutorial-KEEP`` branch which is a snapshot of the ibek-support state
appropriate for this tutorial. Normally you would use the ``main`` branch and
then create your own branch off of that to work in.

.. warning::

    IMPORTANT: we used an *HTTPS* URL for the ibek-support submodule, not
    a *SSH* URL. This is because other clones of ``ioc-lakeshore340`` will not
    be guaranteed to have the required SSH keys. HTTPS is fine for reading, but
    to write you need SSH. Therefore add the following to your ``~/.gitconfig``:

    .. code-block::

    [url "ssh://git@github.com/"]
            insteadOf = https://github.com/

    This tells git to use SSH for all GitHub URLs, when it sees an HTTP URL.


The git submodule allows us to share the ibek-support definitions between all
ioc-XXX projects but also allows each project to have its copy fixed to
a particular commit (until updated with ``git pull``) see
https://git-scm.com/book/en/v2/Git-Tools-Submodules for more information.


Add a new support module
~~~~~~~~~~~~~~~~~~~~~~~~


Add System Dependencies
~~~~~~~~~~~~~~~~~~~~~~~

If you tried to build the container image at this point you would find that
it is missing the boost libraries which are required by areaDetector. You
can use ``apt`` to install anything you need inside the container. Replace
the commented out ``apt-get`` lines with:

.. code-block:: dockerfile

   RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libboost-all-dev

Add ibek-support Patch file for ADURL
-------------------------------------

In the above we referred to a patch file for ADURL. Add this in the ``ibek-support``
folder by creating directory called ``ibek-support/adurl`` and adding a file called
``adurl.sh`` with the following contents:

.. code-block:: bash

    #!/bin/bash

    echo '
    CROSS_COMPILER_TARGET_ARCHS =

    # Enable file plugins and source them all from ADSupport

    WITH_GRAPHICSMAGICK = YES
    GRAPHICSMAGICK_EXTERNAL = NO

    WITH_JPEG     = YES
    JPEG_EXTERNAL = NO

    WITH_PVA      = YES
    WITH_BOOST    = YES
    ' > configure/CONFIG_SITE.linux-x86_64.Common

    echo '
    # Generic RELEASE.local file that should work for all Support modules and IOCs

    SUPPORT=NotYetSet
    AREA_DETECTOR=$(SUPPORT)
    include $(SUPPORT)/configure/RELEASE
    ' > configure/RELEASE.local

This is a pretty standard patch file and most support modules will need
something similar.
It creates two files in the ADURL support module's configure folder as
follows:

- ``CONFIG_SITE.linux-x86_64.Common`` - This tells the ADURL build
  to use the GraphicsMagick and JPEG libraries that are built by ADSUPPORT.
  For details of what to put in CONFIG_SITE for AreaDetector modules see
  `CONFIG_SITE.local`_.
- ``RELEASE.local`` - This tells the ADURL build where to find
  the support modules that it depends on. epics-containers maintains a
  global release file that is used by all support modules and IOCs. It
  located at ``/workspaces/epics/support/configure/RELEASE``. Therefore we
  place a reference to this file in the RELEASE.local file. Whenever
  ``python3 modules.py install`` is run it will update the global release
  file and also fixup any ``SUPPORT=`` lines in all ``configure/RELEASE*``
  files.

ADCore and ADSupport already have ibek-support files as they were previously created
when making ``ioc-adsimdetector``.


.. _CONFIG_SITE.local: https://areadetector.github.io/areaDetector/install_guide.html#edit-config-site-local-and-optionally-config-site-local-epics-host-arch

Update the IOC Makefile
-----------------------

The IOC Makefile tells the IOC which modules to link against. We need to update
it to pull in ADUrl and dependencies. Replace the file ``ioc/iocApp/src/Makefile``
with the following:

.. code-block:: makefile

    TOP = ../..
    include $(TOP)/configure/CONFIG

    PROD_IOC = ioc
    DBD += ioc.dbd
    ioc_DBD += base.dbd
    ioc_DBD += devIocStats.dbd
    ioc_DBD += asyn.dbd
    ioc_DBD += busySupport.dbd
    ioc_DBD += ADSupport.dbd
    ioc_DBD += NDPluginSupport.dbd
    ioc_DBD += NDFileHDF5.dbd
    ioc_DBD += NDFileJPEG.dbd
    ioc_DBD += NDFileTIFF.dbd
    ioc_DBD += NDFileNull.dbd
    ioc_DBD += NDPosPlugin.dbd
    ioc_DBD += URLDriverSupport.dbd
    ioc_DBD += PVAServerRegister.dbd
    ioc_DBD += NDPluginPva.dbd

    ioc_SRCS += ioc_registerRecordDeviceDriver.cpp

    ioc_LIBS += ntndArrayConverter
    ioc_LIBS += nt
    ioc_LIBS += pvData
    ioc_LIBS += pvDatabase
    ioc_LIBS += pvAccessCA
    ioc_LIBS += pvAccessIOC
    ioc_LIBS += pvAccess
    ioc_LIBS += URLDriver
    ioc_LIBS += NDPlugin
    ioc_LIBS += ADBase
    ioc_LIBS += cbfad
    ioc_LIBS += busy
    ioc_LIBS += asyn
    ioc_LIBS += devIocStats
    ioc_LIBS += $(EPICS_BASE_IOC_LIBS)
    ioc_SRCS += iocMain.cpp

    include $(TOP)/configure/RULES

TODO: in future the IBEK tool will generate the Makefile for you based on the
ibek support YAML supplied with each module in ibek-support.


Build the Generic IOC
---------------------

Now we can build the IOC. Run the following command from the ioc-adurl
directory:

.. code-block:: bash

    ec dev build

.. warning::

    This will FAIL. There is a deliberate error which we will fix in the next
    Tutorial.

    You should see this error::

        ../URLDriver.cpp:22:10: fatal error: Magick++.h: No such file or directory

In the next tutorial we will look at how to fix build errors like this.
