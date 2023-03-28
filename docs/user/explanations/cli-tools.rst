CLI Tools
=========

Experimental feature.

It is possible to install every single tool you might need into one big devcontainer
image.

However to keep container bloat down we are experimenting with using
'cli tools' instead. This adds a folder into your path ``/cli-tools/tools``.

If here you can place launch scripts that pull a containerized version of a
tool and run that instead.

It is very simple to add new tools to this folder. Just create a script with
the same names as the tool you want to execute and drop it in ``/cli-tools/tools``.
This requires that the tool is packaged in a container already, many vendors
already do this anyway.

If the tool is not packaged already you could make your own container using
the pattern here https://github.com/epics-containers/pytools.

Below is the example launch script for the PVA viewer tool.

.. code-block:: bash

    export podarg="
    -e EPICS_PVA_ADDR_LIST
    -e EPICS_PVA_AUTO_ADDR_LIST
    "

    echo $EPICS_PVA_ADDR_LIST
    _execute ghcr.io/epics-containers/pytools-linux-runtime:23.3.1 c2dv ${@}

_execute does the actual work of pulling the container and running it.
The environment variable ``podarg`` is used to pass additional arguments to the
podman invocation. In this case we are passing two environment variables to the
container.

