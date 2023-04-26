Run an IOC without Kubernetes
=============================

When we run a containerized IOC we are selecting a generic IOC container image
to launch and some configuration to pass to the IOC.  The configuration we
pass is what makes the IOC a unique instance instead of a generic IOC.

In the tutorials we are running the IOC in a Kubernetes cluster and we
use a Kubernetes ConfigMap to pass the configuration to the IOC.

However it is perfectly possible to do this without Kubernetes. To demonstrate
this easily, first create the test beamline repo as described in
`../tutorials/create_beamline`.

Now if you cd into the test beamline repo and run the following command you
will see the IOC running in a container:

.. code-block:: bash

    podman run --net host -it --rm -v $(pwd)/iocs/bl01t-ea-ioc-01/config:/repos/epics/ioc/config  ghcr.io/epics-containers/ioc-template-linux-runtime:23.3.3

What you have done here is pull down the generic ``ioc-template-linux-runtime``
container image from the GitHub Container Registry and run it.
The ``-it`` means it is an interactive terminal session.  ``--rm`` means the
container is removed when it exits, best for keeping your cache tidy.
Note that you could also add ``-d`` to run the container in the background,
you could then attach to it with the ``podman attach`` command.

The ``--net host`` means the container will use the same network namespace as
the host.  This is required because channel access protocol does not
travel through a NAT to a container network (See `../explanations/net_protocols`)

The -v mounts the local directory ``iocs/bl01t-ea-ioc-01/config`` into the
container at ``/repos/epics/ioc/config``.  This is where the IOC expects to
find its configuration. The leading $(pwd) means the current working directory
is appended to the path and that is required because the path for mounting
into a container must be absolute.

``iocs/bl01t-ea-ioc-01/config`` contains a simple iocShell boot script and the
default behaviour is to pass that to the generic IOC binary.

Using this approach you could manage your config folders and IOC launches
yourself using whatever mechanism you prefer. Probably docker compose or
docker swarm would be the most likely candidates.

It may be worth noting that this ``ec`` command does exactly the same
thing as the above podman command:

.. code-block:: bash

    ec dev ioc-launch iocs/bl01t-ea-ioc-01

That is because ``ioc-launch`` is intended for locally testing an IOC instance
that is destined for Kubernetes.

