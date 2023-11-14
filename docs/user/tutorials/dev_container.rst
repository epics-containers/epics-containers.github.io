Developer Containers
====================

.. _ioc_change_types:

Types of Changes
----------------

Containerized IOCs can be modified in 3 distinct places (in order of decreasing
frequency of change but increasing complexity):

#. The IOC instance: this means making changes to the IOC instance folders
   which appear in the ``iocs`` folder of a domain repository. e.g.:

   - changing the EPICS DB (or the ``ibek`` files that generate it)
   - altering the IOC boot script (or the ``ibek`` files that generate it)
   - changing the version of the Generic IOC used in values.yaml
   - for Kubernetes: the values.yaml can override any settings used by helm
     so these can also be adjusted on a per IOC instance basis.
   - for Kubernetes: changes to the global values.yaml
     file found in ``beamline-chart``, these affect all IOCs in the domain.

#. The Generic IOC: i.e. altering how the Generic IOC container image
   is built. This means making changes to an ``ioc-XXX``
   source repo and publishing a new version of the container image.
   Types of changes include:

   - changing the EPICS base version
   - changing the versions of EPICS support modules compiled into the IOC binary
   - adding new support modules
   - altering the system dependencies installed into the container image

#. The dependencies - Support modules used by the Generic IOC. Changes to support
   module repos. To make use of these changes would require:

   - publishing a new release of the support module,
   - updating and publishing the Generic IOC
   - updating and publishing the IOC instance

For all of the above, the epics-containers approach allows
local testing of the changes before going through the publishing cycle.
This allows us to have a fast 'inner loop' of development and testing.

Also, epics-containers provides a mechanism for creating a separate workspace for
working on all of the above elements in one place.

Need for a Developer Container
------------------------------

The earlier tutorials were firmly in the realm of ``1`` above.
It was adequate for us to install a container platform, IDE and python
and that is all we needed.

Once you get to level ``2`` changes you need to have compilers and build tools
installed. You might also require system level dependencies. AreaDetector,
that we used earlier has a long list of system dependencies that need to be
installed in order to compile it. Traditionally we have installed all of these
onto developer workstations or separately compiled the dependencies as part of
the build.

These tools and dependencies will differ from one Generic IOC to the next.

When using epics-containers we don't need to install any of these tools or
dependencies on our local machine. Instead we can use a developer container,
and in fact our Generic IOC *is* our developer container.

When the CI builds a Generic IOC it creates
`two targets <https://github.com/orgs/epics-containers/packages?repo_name=ioc-adsimdetector>`_:

:developer: this target installs all the build tools and build time dependencies
   into the container image. It then compiles the support modules and IOC.

:runtime: this target installs only the runtime dependencies into the container.
   It also extracts the built runtime assets from the developer target.

The developer stage of the build is a necessary step in order to get a
working runtime container. However, we choose to keep this stage as an additional
build target and it then becomes a perfect candidate for a developer container.

VSCode has excellent support for using a container as a development environment.
The next section will show you how to use this feature. Note that you can use
any IDE that supports remote development in a container, you could also
simply launch the developer container in a shell and use it via CLI only.

Starting a Developer Container
------------------------------

.. Warning::

  DLS Users and Redhat Users:

  There is a
  `bug in VSCode devcontainers extension <https://github.com/microsoft/vscode-remote-release/issues/8557>`_
  at the time of writing
  that makes it incompatible with podman and an SELinux enabled /tmp directory.
  This will affect most Redhat users and you will see an error regarding
  permissions on the /tmp folder when VSCode is building your devcontainer.

  Here is a workaround that disables SELinux labels in podman.
  Paste this into a terminal:

  .. code-block:: bash

    sed -i ~/.config/containers/containers.conf -e '/label=false/d' -e '/^\[containers\]$/a label=false'


For this section we will work with the ADSimDetector Generic IOC that we
used in previous tutorials. Let's go and fetch a version of the Generic IOC
source and build it locally.

For the purposes of this tutorial we will place the source in a folder right
next to your test beamline ``bl01t`` folder. We will also be getting a
specific version of the Generic IOC source so that future changes don't break
this tutorial:

.. code-block:: bash

    # starting from folder bl01t so that the clone is next to bl01t
    cd ..
    git clone --recursive git@github.com:epics-containers/ioc-adsimdetector.git -b 2023.11.1
    cd ioc-adsimdetector
    ec dev build

The last step uses one of the ``ec dev`` sub commands to build the developer
target of the container to your local container cache. This will take a few
minutes to complete. A philosophy of epics-containers is that Generic IOCs
build all of their own support. This is to avoid problematic dependency trees.
For this reason building something as complex as AreaDetector will take a
few minutes when you first build it.

A nice thing about containers is that the build is
cached so that a second build will be almost instant unless you have changed
something that requires some steps to be rebuilt.

The ``ec dev`` commands are a set of convenience commands
for working on Generic IOCs from *outside* of the container. These commands
are useful for debugging container builds: although most work is done inside
the container, you will need these commands if it fails to build.


.. note::

   Before continuing this tutorial make sure you have not left the IOC
   bl01t-ea-ioc-02 running from a previous tutorial. Execute this command
   outside of the devcontainer to stop it:

   .. code-block:: bash

      ec ioc stop bl01t-ea-ioc-02

Once built, open the project in VSCode:

.. code-block:: bash

    code .

When it opens, VSCode may prompt you to open in a devcontainer. If not then click
the green icon in the bottom left of the VSCode window and select
``Reopen in Container``.

You should now be *inside* the container. All terminals started in VSCode will
be inside the container. Every file that you open with the VSCode editor
will be inside the container.

There are some caveats because some folders are mounted from the host file
system. For example, the ``ioc-adsimdetector`` project folder
is mounted into the container as a volume. It is mounted under
``/epics/ioc-adsimdetector``. This means that you can edit the source code
from your local machine and the changes will be visible inside the container and
outside the container. This is a good thing as you should consider the container
filesystem to be a temporary filesystem that will be destroyed when the container
is deleted.

Now that you are *inside* the container you have access to the tools built into
it, this includes ``ibek``. The first command you should run is:

.. code-block:: bash

   ibek ioc build

This generates an IOC source tree in the ``ioc`` folder under your
``ioc-adsimdetector`` folder and compiles it. Note that the IOC code is
boilerplate, but that the ``src/Makefile`` is generated according to the
support modules this Generic IOC contains. You can go and take a look at
the Makefile and see that it contains ``dbd`` and ``lib`` references for each
of the support modules in the container.
See ``/epics/ioc-adsimdetector/ioc/iocApp/src/Makefile``

You will note that the ``ioc`` folder is greyed out in the VSCode explorer. This
is because it is in ``.gitignore`` and it is purely generated code. If you
particularly needed to customize the contents of the ioc source tree then
you can remove it from ``.gitignore`` and commit your changes to the repo. These
changes would then always get loaded for every instance of the Generic IOC.

The Generic IOC should now be ready to run inside of the container. To do this:

.. code-block:: bash

   cd ioc
   ./start.sh

You will just see the default output of a Generic IOC that has no Instance
configuration. Next we will add some instance configuration from one of the
IOC instances in the ``bl01t`` beamline.

Let's now add some other folders to our VSCode workspace to make it easier to
work with ``bl01t`` and to investigate the container.

Adding the Beamline to the Workspace
------------------------------------

To meaningfully test the Generic IOC we will need an instance to test it
against. We will use the ``bl01t`` beamline that you already made. The container 
has been configured to mount some useful local files from the user's home directory,
including the parent folder of the workspace as ``/repos`` so we can work on 
multiple peer projects. 

In VSCode click the ``File`` menu and select ``Add Folder to Workspace``.
Navigate to ``/repos`` and you will see all the peers of your ``ioc-adsimdetector``
folder (see `container-layout` below) . Choose the ``bl01t`` folder and add it to the
workspace - you may see an error but if so clicking "reload window" will
clear it.

Also take this opportunity to add the folder ``/epics`` to the workspace.

.. note::

  Docker Users: your account inside the container will not be the owner of
  /epics files. vscode will try to open the repos in epics-base and support/*
  and git will complain about ownership. You can cancel out of these errors
  as you should not edit project folders inside of ``/epics`` - they were
  built by the container and should be considered immutable. We will learn
  how to work on support modules in later tuorials. This error should only
  be seen on first launch. podman users will have no such problem becuase they
  will be root inside the container and root build the container.

You can now easily browse around the ``/epics`` folder and see all the
support modules and epics-base. This will give you a feel for the layout of
files in the container. Here is a summary (where WS is your workspace on your
host. i.e. the root folder under which your projects are all cloned):

.. _container-layout:

.. list-table:: Developer Container Layout
   :widths: 25 35 45
   :header-rows: 1

   * - Path Inside Container
     - Host Mount Path
     - Description

   * - /epics/support
     - N/A
     - root of compiled support modules

   * - /epics/epics-base
     - N/A
     - compiled epics-base

   * - /epics/ioc-adsimdetector
     - WS/ioc-adsimdetector
     - Source repository for the Generic IOC

   * - /epics/ioc
     - WS/ioc-adsimdetector/ioc
     - soft link to IOC source tree

   * - /epics/ibek
     - N/A
     - All ibek *Support yaml* files

   * - /epics/pvi
     - N/A
     - all PVI definitions from support modules

   * - /epics/opi
     - N/A
     - all OPI files (generated or copied from support)

   * - /repos
     - WS
     - all peers to Generic IOC source repo


Now that we have the beamline repo visible in our container we can
easily supply some instance configuration to the Generic IOC.
Try the following:

.. code::

   cd /epics/ioc
   rm -r config
   ln -s /repos/bl01t/iocs/bl01t-ea-ioc-02/config .
   # check the ln worked
   ls -l config
   ./start.sh

This removed the boilerplate config and replaced it with the config from
the IOC instance bl01t-ea-ioc-02. Note that we used a soft link, this
means we can edit the config, restart the IOC to test it and the changes
will already be in place in the beamline repo. You can even open a shell
onto the beamline repo and commit and push the changes.

Wrapping Up
-----------

We now have a tidy development environment for working on the Generic IOC,
IOC Instances and even the support modules inside the Generic IOC, all in one
place. We can easily test our changes in place too. In particular note that
we are able to test changes without having to go through a container build
cycle.

In the following tutorials we will look at how to make changes at each of the
3 levels listed in `ioc_change_types`.
