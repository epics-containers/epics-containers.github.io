
# Launch A Simulation Beamline

In this tutorial we will launch a simulation beamline using docker compose. This demonstrates that the a containerised beamline is portable and that the setup instructions from the previous tutorial have been successful.

:::{note}
This tutorial has been tested with the following versions of software. If you have issues then you may need to update your software to these versions or higher.

- git 2.43.5
- One of the following
  - docker 20.10.0
  - podman 4.9.4 and docker-compose 2.29.2

See "Start the Podman system service" in [this article](https://www.redhat.com/sysadmin/podman-docker-compose) to set up podman and docker-compose

If you have a choice, a recent docker version is the preferred option.
:::

The example beamline wiil launch the following set of containers:
- a simulation Area Detector IOC
- a simulation Motion IOC
- a basic IOC with a sum record
- a ca-gateway to expose the above to the host
- a phoebus instance to view the beamline

To launch simply run the following commands:

```bash
git clone https://github.com/epics-containers/example-services
cd example-services
# setup some environment variables
source ./environment.sh
# lauch the docker compose configuration (with dc alias for docker compose)
dc up -d
```

If all is well you should see phoebus lauch with an overview of the beamline like the following:

:::{figure} ../images/example_beamline.png
The example beamline overview screen
:::

You can now try out the following commands to interact with the beamline:

```bash
# use caget/put locally
export EPICS_CA_ADDR_LIST=127.0.0.1
caget BL01T-DI-CAM-01:DET:Acquire_RBV

# OR if you don't have caget/put locally then use one of the containers instead:
# execute caget from inside one of the example IOCs
dc exec bl01t-ea-test-01 caget BL01T-DI-CAM-01:DET:Acquire_RBV
# or get a shell inside an example IOC and use caget
dc exec bl01t-ea-test-01 bash
caget BL01T-DI-CAM-01:DET:Acquire_RBV

# attach to logs of a service (-f follows the logs, use ctrl-c to exit)
dc logs bl01t-di-cam-01 -f
# stop a service
dc stop bl01t-di-cam-01
# restart a service
dc start bl01t-di-cam-01
# attach to a service stdio
dc attach bl01t-di-cam-01
# exec a process in a service
dc exec bl01t-di-cam-01 bash
# delete a service (deletes the container)
dc down bl01t-di-cam-01
# create and launch a single service (plus its dependencies)
dc up bl01t-di-cam-01 -d
# close down and delete all the containers
# volumes are not deleted to preserve the data
dc down
```

This tutorial is a simple introduction to validate that the setup is working. In the following tutorials you will get to create your own beamline and start adding IOCs to it.

::: {important}
Before moving on to the next tutorial always make sure to stop and delete the containers from your current example as follows:

```bash
dc down
```

If you do not do this you will get name clashes when trying the next example. If this happens - return to the previous project directory and use `dc down`.

This is a deliberate choice as we can only run a single ca-gateway on a given host port at a time. For more complex setups you could share one ca-gateway between multiple compose configurations, but we have chosen to keep things simple for these tutorials.
