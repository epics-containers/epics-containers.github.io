Debugging Generic IOC Builds
============================

.. Warning::

    This tutorial is out of date and will be updated soon.

This tutorial is a continuation of `generic_ioc`. Here we will look into
debugging failed builds and fix the issue we saw in the previous tutorial.

This also comes under the category of type 2. change from the list
at `ioc_change_types`.

There are two ways to debug a failed build:

- Keep changing the Dockerfile and rebuilding the container until the build
  succeeds. This is the simplest approach and is often sufficient since our
  Dockerfile design maximizes the use of the build cache.

- Investigate the build failure by running a shell inside the
  partially-built container and
  using make. This is a good idea if you have to make fundamental changes
  such as installing a new system package. System package install happens
  at the start of the Dockerfile and would trigger a full rebuild when
  changed.

You already have the knowledge to apply the first approach. In this tutorial
we will look debugging the build from *inside* the container.

Investigate the Build Failure
-----------------------------

When a container build fails the container image is created up to the point
where the last successful Dockerfile command was run. This means that we can
investigate the build failure by running a shell in the container. ``ec``
provides us with the following convenience command to do this:

.. code-block:: bash

    ec dev debug-last

Now we have a prompt inside the part-built container and can retry the failed
command.

.. code-block:: bash

    cd /repos/epics/support/adurl
    make

You should see the same error again.

A really good way to investigate this kind of error is with ``apt-file``
which is a command line tool for searching Debian packages. apt-file is
already installed in our devcontainer. So get another terminal open
with the ``[E7]`` prompt and run the following commands:

.. code-block:: bash

    apt-file search Magick++.h

        graphicsmagick-libmagick-dev-compat: /usr/include/Magick++.h
        libgraphicsmagick++1-dev: /usr/include/GraphicsMagick/Magick++.h
        libmagick++-6-headers: /usr/include/ImageMagick-6/Magick++.h

The middle result looks most promising so we will install it (back *inside*
the Generic IOC container now):

.. code-block:: bash

    apt-get install -y libgraphicsmagick++1-dev

The reason using apt-file outside of the Generic IOC works is because
the Generic IOC and the devcontainer are built upon the same version of
Ubuntu and have the same packages available.

If we try the build again now it will still fail. We need to tell the
AreaDetector build system where to find the new header file. This
is documented here `CONFIG_SITE.local`_. The documentation says that we
need to set the variable ``GRAPHICSMAGICK_INCLUDE`` in
``CONFIG_SITE.linux-x86_64.Common``.
We can see from the ``apt-file`` output that the header file is in
``/usr/include/GraphicsMagick`` which is not a default include path.
Therefore we need to edit this file inside our Generic IOC container:
``/repos/epics/support/adurl/configure/CONFIG_SITE.linux-x86_64.Common``

.. _CONFIG_SITE.local: https://areadetector.github.io/areaDetector/install_guide.html#edit-config-site-local-and-optionally-config-site-local-epics-host-arch


Making Changes Inside the Container
-----------------------------------

You will find that the container includes busybox tools and there is a
rudimentary version of ``vi`` installed. You could also install any editor
you like from the Ubuntu repositories.

HOWEVER, there is a much easier way ...

When you launch containers with ``ec`` commands the ``/repos`` folder is
synchronized to a local folder ioc-XXX/repos and that is mounted into the
container. This means that you can edit files in the container using VSCode.
The mounted repos folder also ensures that any changes you make inside the
container are saved between invocations of the container.

See the image below to see how to navigate to
``CONFIG_SITE.linux-x86_64.Common``
in the ``adurl`` support module inside the ioc-adurl container.

.. figure:: ../images/repos_folder.png

    VSCode file explorer showing the mounted repos folder

Using VSCode file explorer as pictured above, navigate to the file
``CONFIG_SITE.linux-x86_64.Common`` and update the GRAPHICSMAGICK section to
look like this:

.. code-block:: makefile

    WITH_GRAPHICSMAGICK = YES
    GRAPHICSMAGICK_EXTERNAL = YES
    GRAPHICSMAGICK_INCLUDE = /usr/include/GraphicsMagick

Now go back to the terminal and run ``make`` again. This time it should
succeed.

Applying Changes Made Inside the Container
------------------------------------------

When you use the 'inside the container' approach to get the build working
you still need to apply the changes you made 'outside' so that invoking
container build will also succeed.

:TIP: do NOT apply the below, the next heading supplies a better solution
      for this specific case.

There are a few kinds of changes that need different approaches as follows:

:apt install:

    We did an apt install of ``libgraphicsmagick++1-dev``. Additional system
    package installs like this need to be added to the ``apt-get install``
    command at the top of the Dockerfile.

:CONFIG_SITE:

    We edited ``CONFIG_SITE.linux-x86_64.Common``. This file is not part of
    the ADURL support module but was supplied by us from ibek-defs.

:Patching:

    This should be avoided, but occasionally it may be necessary to patch other
    files in the support modules. This is just a variation of the CONFIG_SITE
    case above. You can place whatever script code you like in the
    ``ioc-XXX/patch`` folder.

:Support Module:

    Potentially we could have made changes to the ADUrl support module itself
    because we found a bug or wanted to add a feature. In this case we would
    push those changes back up to GitHub and get a release made so we
    could use the new version in our Dockerfile, This would in turn mean A
    change to the version number in the ``modules.py install ADURL``
    command. NOTE: the developer container we are using already holds clones
    of all the support modules so we could make changes in place and push them
    back.

An Easier Fix Using ADSupport
-----------------------------

Although we managed to fix the build by installing Graphics Magick, into the
container there is an easier solution that is specific to areaDetector. The
ADSupport module is capable of building most of the system dependencies that
areaDetector needs. This has proved to be very useful in making containers
because the curation of all of the compatible versions of these dependencies
has already been done.

So the error we saw was due to us telling ADUrl to look for an 'internal'
version of Graphics Magick built by ADSupport. However, we did not tell
ADSupport to build Graphics Magick.

So the simple fix to this is to add the following line to the
``ioc-adurl/ibek-defs/adsupport/adsupport.sh`` file:

.. code-block:: makefile

    WITH_GRAPHICSMAGICK = YES
    GRAPHICSMAGICK_EXTERNAL = NO

Then rebuild the container:

.. code-block:: bash

    ec dev build

Note that the build skips quickly over the support modules until it gets
to ADSupport. This is the build cache saving time.
However this build will STILL FAIL, it turns out that building Graphics Magick
does need one system library install.

The final fix is to add ``libxext-dev`` to the ``apt-get install`` command in
our Dockerfile. So that it looks like this:

.. code-block:: bash

    RUN apt-get update && apt-get upgrade -y && \
        apt-get install -y --no-install-recommends \
        libboost-all-dev \
        libxext-dev

This is an example of a change that also requires a system package
install for the runtime version of the container. Locate the second
``apt-get install`` command in the Dockerfile and add ``libxext6`` so
that it looks like this:

.. code-block:: bash

    RUN apt-get update && apt-get upgrade -y && \
        apt-get install -y --no-install-recommends \
        libxext6 \
    && rm -rf /var/lib/apt/lists/*

You can remove the RTEMS specific runtime packages that came with ioc-template.
Note that the ``rm -rf /var/lib/apt/lists/`` removes the apt cache and keeps
the runtime image size down.

This build should now succeed. Unfortunately it has to rebuild the entire
container from scratch because we changed the first command in the Dockerfile.

Wrapping Up
-----------

You now have a new Generic IOC that can be used to test the ADUrl plugin.

The next tutorial will discuss how to test this IOC, including publishing
the image to a container registry so that it can run in Kubernetes.


.. Once running:-
.. caput -S $USER-EA-TST-02:CAM:URL1