# Deploying and Managing IOC Instances

## Introduction

This tutorial will show you how to deploy and manage the example IOC Instance `example-test-01` that came with the template beamline repository. You will need to have your own `t01-services` beamline repository from the previous tutorial.

For these early tutorials we are not using Kubernetes and instead are deploying IOCs to the local docker or podman instance. These kind of deployments are ideal for testing and development on a developer workstation. They could also potentially be used for production deployments to beamline servers where Kubernetes is not available.

## Continuous Integration

Before we change anything, we shall make sure that the beamline repository CI
is working as expected. To do this go to the following URL (make sure you insert
your GitHub account name where indicated):

```
https://github.com/YOUR_GITHUB_ACCOUNT/t01-services/actions
```

You should see something like the following:

:::{figure} ../images/bl01t-actions.png
the GitHub Actions page for the example beamline repository
:::

This is a list of all the Continuous Integration (CI) jobs that have been
executed (or are executing) for your beamline repository. There should be
two jobs listed, one for when you pushed the main branch and one for when you
tagged with the `CalVer` version number.

If you click on the most recent job you can drill in and see the steps that
were executed. The most interesting step is `Run IOC checks`. This
is executing the script `.github/workflows/ci_verify.sh`. This goes through
each of the IOC Instances in the `services` folder and checks that they
have a valid configuration.

For the moment just check that your CI passed and if not review that you
have followed the instructions in the previous tutorial correctly.

(setup-beamline-t01)=
## Set up Environment for the t01 Beamline

Make sure you have a terminal open and the current working directory is your `t01-services` project root folder.

The standard way to set up your environment for any ec services repository is to source the environment.sh script from the root of the services repo. i.e.

```bash
source ./environment.sh
```

The environment file is the same for all local deployment services projects and sets up the following. The defaults supplied are all intended for developer workstation use:
- sets permissions on **xhost** to allow local containers to display GUIs on the host.
- sets **UIDGID** which is used to set which account and group the phoebus container is launched with. This is always 0:0 for podman and USERID:GROUPID for docker. Only required for developer workstations.
- sets **COMPOSE_PROFILES** which determines which compose profile is launched. Defaults to the 'test' profile intended for testing on developer workstations. It runs a ca-gateway container that publishes PVs on localhost and a container for phoebus to provide an OPI.
- sets **EPICS_CA_ADDR_LIST** to localhost so that host can see the containerised IOC PVs on a developer workstation.


(deploy-example-instance)=
## Deploy the Example IOC Instance

To launch all the services described by the `compose.yml` file in the root of the services repository, make sure your current working directory is still the root of your your `t01-services` project and run the following command:

```bash
docker compose up -d
```

The `up` command tells compose to make sure all of the services are up and running.  The `-d` flag tells compose to detach and run the services in the background. If you don't specify -d then your terminal will attach to the stdout of the services and you will see their output as they start up. This can be useful and is done with colour coding so you can distinguish between the different services (terminal colours must be enabled).

There will be a short delay the first time while the container images are downloaded from the GitHub container registry to your local image cache. Subsequent runs will be much faster.

The default example project will launch:

- a basic IOC instance with a few records
- a ca-gateway container that publishes the IOC PVs on localhost
- a phoebus container that can be used to view the IOC PVs using an example bob file that comes with the template.


You can see the status of the services by running the following command:

```bash
docker compose ps
```

In environment.sh we created an alias for `docker compose` named `ec` from now on we'll shorten the commands to use `ec` instead of `docker compose`.

## Managing the Example IOC Instance

### Starting and Stopping IOCs

To stop / start the example IOC try the following commands. Note that `ec ps -a` shows you all IOCs including stopped ones.

Also note that tab completion should allow you to complete the names of your commands and services. e.g.
`ec star <tab> ex <tab>`, should complete to `ec start example-test-01`.

```bash
ec ps -a
ec stop example-test-01
ec ps -a
ec start example-test-01
ec ps
```

:::{Note}
Generic IOCs.

You may have noticed that the IOC instance is showing that it has container image `ghcr.io/epics-containers/ioc-template-example-runtime:3.5.1`.

This is a Generic IOC image and all IOC Instances must be based upon one of these images. ioc-template-example-runtime is an instantiation of the template project for creating new Generic IOCs. It has only deviocstats support and no other support modules. This generic IOC can be used for serving records out of a database file as we have done in this example.
:::

### Monitoring and interacting with an IOC shell

To attach to the IOC shell you can use the following command. HOWEVER, this
will attach you to nothing in the case of this example IOC as it has no
shell. In the next tutorial we will use this command to interact with
iocShell.

```bash
ec attach example-test-01
dbl
# ctrl-p ctrl-q to detach
```

Use the command sequence ctrl-P then ctrl-Q to detach from the IOC. **However, there are issues with both VSCode and IOC shells capturing ctrl-P**. Until this is resolved it may be necessary to close the terminal window to detach. You can also restart and detach from the IOC using ctrl-D or ctrl-C, or by typing `exit`. If you do this docker will restart your IOC right away.

To run a bash shell inside the IOC container:

```bash
ec exec example-test-01 bash
caget EXAMPLE:SUM
```

Once you have a shell inside the container you could inspect the following folders. Because this is the runtime container you will only see the binaries and runtime files, not the source code:

```{eval-rst}
===================  =========================================================
/epics/ioc           ioc code
/epics/ioc/start.sh  IOC startup script
/epics/support       support modules
/epics/epics-base    EPICS base binaries
/epics/ioc/config    IOC instance config used to generate runtime files
/epics/runtime       IOC startup script and database file generated at runtime
===================  =========================================================
```

Being at a terminal prompt inside the IOC container can be useful for debugging and testing. You will have access EPICS command line tools including pvAccess, and you can inspect files such as the IOC startup script.

In the Virtual Machine supplied for testing epics-containers we do not install EPICS into the host environment. Instead you can use an IOC container when you need EPICS tools. Working this way makes your developer environment very portable, you only require docker or podman to work on any IOC project. It is equally possible to install EPICS on your host and use the host tools to interact with the IOC container, for the developer configuration you would just need to make sure `EPICS_CA_ADDR_LIST=127.0.0.1`.

### Logging

To get the current logs for the example IOC:

```bash
ec logs example-test-01
```

Or follow the IOC log until you hit ctrl-C:

```bash
ec logs example-test-01 -f
```

You should see the log of ibek loading and generating the IOC startup assets and then the ioc shell startup script log. Ibek is the tool that runs inside of the IOC container and generates the ioc shell script and database file by interpreting the /epics/ioc/config/ioc.yaml at launch time.

### Shutdown

You can stop all the services with the following command.

```bash
ec stop
```

This will stop all the currently running containers described in the `compose.yml` file.
However this will leave the resources themselves in place:-
- stopped containers
- container networks
- container volumes

To take down the services and remove all of their resources use the following command:

```bash
ec down
```
