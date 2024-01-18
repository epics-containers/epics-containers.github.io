Create a Generic IOC
====================

.. Warning::

    This tutorial is out of date and will be updated soon.

In this tutorial we will learn how to create a Generic IOC container image and
test our changes locally before deploying it.

This is a type 2. change from the list at `ioc_change_types`.

The example IOC used ADSimDetector, we will make a similar IOC that uses
ADUrl to get images from a webcam.

Create a New Generic IOC project
--------------------------------

By convention Generic IOC projects are named ``ioc-XXX`` where ``XXX`` is the
name of the primary support module used by the IOC. Here we will be building
``ioc-adurl``.

Much like creating a new beamline we have a template project that can be used
as the starting point for a new Generic IOC. Again we will create this in
your personal GitHub user space.

Create a new ioc-XXX repo
~~~~~~~~~~~~~~~~~~~~~~~~~

TODO: the following steps to create a new Generic IOC project will be automated
using an ``ec`` command.

#.  Create a new, completely blank repository in your GitHub account
    called ``ioc-adurl``. To do this got to https://github.com/new
    and fill in the details as per the image below. Click
    ``Create repository``.

#.  Clone the template repo locally and rename from ioc-template to ioc-adurl

    .. code-block:: bash

        git clone git@github.com:epics-containers/ioc-template.git
        mv ioc-template ioc-adurl
        cd ioc-adurl

#.  Add your new repo to your VSCode workspace and take a look at what you
    have.

    From the VSCode menus: File->Add Folder to Workspace
    then select the folder ioc-adurl

#.  Push the repo back to a new repo on github

    .. code-block:: bash

        git remote rm origin
        git remote add origin git@github.com:<YOUR USER NAME>/ioc-adurl.git
        git push --set-upstream origin main


Prepare the New Repo for Development
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are a few things that all new ioc-XXX repos need to do:

:Choose Architecture:

    Update the file ``.github/workflows/build.yml`` to choose the architectures
    you are targeting find the ``architecture:`` line and change it accordingly.
    For this project we want ``linux`` only.

:Fix the tests:

    ioc-template comes with some tests and they will continue to work. This is
    because they rely a default EPICS db. Specified in ``ioc/config/ioc.db``.
    You should update default example files in ``ioc/config/ioc.db`` to be
    relevant to your IOC and change the script in ``tests`` to match.

For now leave the tests alone as we will be working with them in
`test_generic_ioc`.

Now we will go ahead and make the specific changes to the template
needed for our ioc-adurl project.

Configure the ibek-defs Submodule
---------------------------------

The ``ibek-defs`` submodule is used to share information about how to build
support modules. It contains two kinds of files:

#.  Patch Files: these are used to update a support module so that it will
    build correctly in the container environment. These should typically only
    add one or both of these files:

    - configure/RELEASE.local
    - configure/CONFIG_SITE.linux-x86_64.Common

#.  IBEK support module definitions: These are used to help IOCs build their
    iocShell boot scripts from YAML descriptions. They are not used in this
    tutorial as we are supplying a hand crafted boot script. For information
    on IBEK see https://github.com/epics-containers/ibek.

ibek-defs is curated for security reasons, therefore we need to work with
a fork of it so we can add our own definitions for ADUrl. If you make changes
to ibek-defs that are generally useful you can use a pull request to get them
merged into the main repo.

Perform the following steps to create a fork and update the submodule:

- goto https://github.com/epics-containers/ibek-defs/fork
- uncheck ``Copy the main branch only``
- click ``Create Fork``
- click on ``<> Code`` and COPY the ssh URL
- cd to the ioc-adurl directory
-
  .. code-block:: bash

        git submodule set-url ibek-defs <PASTE URL HERE>
        git submodule init
        git submodule update
        cd ibek-defs
        git checkout tutorial
        cd ..

We are using the ``tutorial`` branch which has a snapshot of the ibek-defs state
appropriate for this tutorial. Normally you would use the ``main`` branch and
therefore omit ``git checkout tutorial``.

The git submodule allows us to share the ibek-defs definitions between all
ioc-XXX projects but also allows each project to have its copy fixed to
a particular commit (until updated with ``git pull``) see
https://git-scm.com/book/en/v2/Git-Tools-Submodules for more information.


Modify the Dockerfile
---------------------

The heart of every ioc-XXX project is the Dockerfile. This is a text file
that contains a set of instructions that are used to build a container image.
See https://docs.docker.com/engine/reference/builder/ for details of how
to make Dockerfiles.

All ioc-XXX projects will have the same pattern of Dockerfile instructions
and will all be based upon the epics base images named:

- ghcr.io/epics-containers/epics-base-<ARCH>-<TARGET>

Where ARCH is currently ``linux`` or ``rtems`` and TARGET will always be ``developer``
and ``runtime``. Support for further architectures will be added in the future.

The ``developer`` image contains all the tools needed to build support modules
and is used for building and debugging the Generic IOC. The ``runtime`` image
is a minimal image that holds the minimum required to run the Generic IOC.

The changes we will make to the template Dockerfile are as follows:

Add more support modules
~~~~~~~~~~~~~~~~~~~~~~~~

After the make of ``busy`` add 3 more support module fetch and make steps
like this:

.. code-block:: dockerfile

    COPY ibek-defs/adsupport/ /ctools/adsupport/
    RUN python3 modules.py install ADSUPPORT R1-10 github.com/areaDetector/adsupport.git --patch adsupport/adsupport.sh
    RUN make -C ${SUPPORT}/adsupport -j $(nproc)

    COPY ibek-defs/adcore/ /ctools/adcore/
    RUN python3 modules.py install ADCORE R3-12-1 github.com/areaDetector/adcore.git --patch adcore/adcore.sh
    RUN make -C ${SUPPORT}/adcore -j $(nproc)

    COPY ibek-defs/adurl/ /ctools/adurl/
    RUN python3 modules.py install ADURL R2-3 github.com/areaDetector/adurl.git --patch adurl/adurl.sh
    RUN make -C ${SUPPORT}/adurl -j $(nproc)

This instructs the build to fetch the support module source code from GitHub
for ADURL and its two dependencies ADSUPPORT and ADCORE. It also makes each
module after fetching.

.. note::

    You may think that there is a lot of duplication here but this is explicitly
    done to make the build cache more efficient and speed up development.
    For example we could copy everything out of the ibek-defs directory
    in a single command but then if I changed the ADURL patch file the
    build would have to re-fetch and re-make all the support modules.

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

Add ibek-defs Patch file for ADURL
----------------------------------

In the above we referred to a patch file for ADURL. Add this in the ``ibek-defs``
folder by creating directory called ``ibek-defs/adurl`` and adding a file called
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
  located at ``/repos/epics/support/configure/RELEASE``. Therefore we
  place a reference to this file in the RELEASE.local file. Whenever
  ``python3 modules.py install`` is run it will update the global release
  file and also fixup any ``SUPPORT=`` lines in all ``configure/RELEASE*``
  files.

ADCore and ADSupport already have ibek-defs files as they were previously created
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
ibek support YAML supplied with each module in ibek-defs.


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
