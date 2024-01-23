.. _ioc-source:

Dev Container vs Runtime Container
==================================

Introduction
------------

The dev container is where all development of IOCs and support modules will
take place. The runtime container is where the IOC will run when deployed
to a target system.

The dev container mounts several host folders into the container to achieve
the following goals:

- make the developer container look as similar as possible to the runtime
  container
- allow the developer to make changes and recompile things without having
  to rebuild the container
- make sure that all useful changes occur in the host filesystem so that
  they are not lost when the container is rebuilt or deleted

The details of which folders are mounted where in the container are
shown here: `container-layout`.

The ioc-XXX project folder is found in the container at ``/workspaces/ioc-XXX``,
along with all of it's peers (because the parent folder is mounted
at ``/workspaces``).


The ioc Folder
--------------

The ioc folder contains the Generic IOC source code. It is typically the same
for all Generic IOCs but is included in the ioc-XXX repo in /ioc so that it can be
modified if necessary.

At container build time this folder is copied into the container at
``/epics/generic-source/ioc`` and it is compiled so that the binaries are
available at runtime.

In the dev container the ``/epics/generic-source`` folder has the project
folder ioc-XXX mounted over the top of it. This means:

- the project folder ioc-XXX is mounted in two locations in the container
  - ``/workspaces/ioc-XXX``
  - ``/epics/generic-source``
- the ioc source folder ``/epics/generic-source/ioc`` is also mounted over
  and now contains the source only. The compiled binaries are no longer
  visible inside the dev container.

It is for this reason that a newly created dev container needs to have the IOC
binaries re-compiled. But this is a good thing, because now any changes you
make to the IOC source code can be compiled and tested, but also those
changes are now visible on the host filesystem inside the project folder
``ioc-XXX/ioc``. This avoids loss of work.

Finally the ``ioc`` folder is always soft linked from ``/epics/ioc`` so that
the source and binaries are always in a known location.

Summing Up
----------

The above description makes things sound rather complicated. However,
you can for the most part ignore the details and just remember:

- use ``/epics/ioc`` to compile and run the IOC.
- you are free to make changes to the above folder and recompile
- the changes you make will be visible on the host filesystem in the
  original project folder.

