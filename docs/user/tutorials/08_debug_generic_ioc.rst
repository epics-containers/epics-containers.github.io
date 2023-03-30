Debugging Generic IOC Builds
============================

This tutorial is a continuation of `07_generic_ioc`. Here we will look into
debugging failed builds and fix the build failure from the previous tutorial.

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
