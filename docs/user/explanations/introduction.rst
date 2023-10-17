.. _essential:

Essential Concepts
==================

Overview
--------

.. include:: ../overview.rst

See below for more detail on each of these.

Concepts
--------

Images and Containers
~~~~~~~~~~~~~~~~~~~~~
Containers provide the means to package up IOC software and execute it
in a lightweight virtual environment. These packages are then saved
into public or private image registries such as DockerHub or Github Container
Registry.

The Open Container Initiative (OCI) defines the set of container services
and their APIs such that container images can be interchanged between
different frameworks.

Thus, in this project we develop, build and test our container images
using docker or podman but the images can be run under Kubernetes' own
container runtime.

This article does a good job of explaining the relationship between docker /
containers and Kubernetes https://semaphoreci.com/blog/kubernetes-vs-docker

An important outcome of using containers is that you can alter the
environment inside the container to suit the IOC code, instead of altering the
code to suit your infrastructure. At DLS, this means that we are able to use
vanilla EPICS base and support modules. We no longer require our own
forks of these repositories.

.. _generic iocs:

Generic IOCs and instances
""""""""""""""""""""""""""

An important principal of the approach presented here is that an IOC container
image represents a 'Generic' IOC. The Generic IOC image is used for all
IOC instances that connect to a given class of device. For example the
Generic IOC image here:
ghcr.io/epics-containers/ioc-adaravis-linux-runtime:2023.10.1
uses the AreaDetector driver ADAravis to connect to GigE cameras.

An IOC instance runs in a container runtime by loading two things:

- The Generic IOC image passed to the container runtime.
- The IOC instance configuration. This is mapped into the container at
  runtime by mounting it into the filesystem at runtime. The mount point
  for this configuration is alway /epics/ioc/config.

The configuration will bootstrap the unique properties of that instance.
The following contents for the configuration are supported:

- ioc.yaml: an **ibek** IOC description file which **ibek** will use to generate
  st.cmd and ioc.subst
- st.cmd, ioc.subst: an IOC shell startup script and an optional substitution file
  st.cmd can refer any additional files in the configuration directory
- start.sh a bash script to fully override the startup of the IOC. start.sh
  can refer to any additional files in the configuration directory


This approach reduces the number of images required and saves disk. It also
makes for simple configuration management.

Throughout this documentation we will use the terms Generic IOC and
IOC Instance. The word IOC without this context is ambiguous.


Kubernetes
~~~~~~~~~~
https://kubernetes.io/

Kubernetes easily and efficiently manages containers across clusters of hosts.

It builds upon 15 years of experience of running production workloads at
Google, combined with best-of-breed ideas and practices from the community,
since it was open-sourced in 2014.

Today it is by far the dominant orchestration technology for containers.

In this project we use Kubernetes and helm to provide a standard way of
implementing these features:

- Auto start IOCs when servers come up
- Manually Start and Stop IOCs
- Monitor IOC status and versions
- Deploy versioned IOCs to the beamline
- Rollback to a previous IOC version
- Allocate a server with adequate resources on which to run each IOC
- Failover to another server (for soft IOCs not tied to hardware in a server)
- View the current log
- View historical logs (via graylog or other centralized logging system)
- Connect to an IOC and interact with its shell
- debug an ioc by starting a bash shell inside it's container


Kubernetes Alternative
~~~~~~~~~~~~~~~~~~~~~~

If you do not have the resources to maintain a Kubernetes cluster then this project
is experimentally supporing the use of podman-compose or docker-compose to deploy
IOCs to a single server. Where a beamline has multiple servers the distribution of
IOCs across those servers is managed by the user. These tools would replace
Kubernetes and Helm in the technology stack.

TODO: more on this once we have a working example.

Helm
~~~~
https://helm.sh/

Helm is the most popular package manager for Kubernetes applications.

The packages are called Helm Charts. They contain templated YAML files to
define a set of resources to apply to a Kubernetes cluster.

Helm has functions to deploy Charts to a cluster and manage multiple versions
of the chart within the cluster.

It also supports registries for storing version history of charts,
much like docker.

In this project we use Helm Charts to define and deploy IOC instances.
Each beamline (or accelerator domain) has its own git repository that holds
the beamline Helm Chart for its IOCs. Each IOC instance need only provide a
values.yaml file to override the default values in the Helm Chart and a config folder
as described in `generic iocs`.

**epics-containers** does not use helm repositories for storing IOC instances.
Such repositories only hold a zipped version of the chart and a values.yaml file,
and this is seen as redundant when we have a git repository holding the same
information. Instead we provide a command line tool for installing and updating
IOCs. Which performs the following steps:

- Clone the beamline repository at a specific tag to a temporary folder
- extract the beamline chart and apply the values.yaml to it
- additionally generate a config map from the config folder files
- install the resulting chart into the cluster
- remove the temporary folder

This means that we don't store the chart itself but we do store all of the
information required to re-generate it in a version tagged repository.


Repositories
~~~~~~~~~~~~

All of the assets required to manage a
set of IOCs for a beamline are held in repositories.

Thus all version control is done
via these repositories and no special locations in
a shared filesystem are required
(The legacy approach at DLS relied heavily on
know locations in a shared filesystem).

In the **epics-containers** examples all repositories are held in the same
github organization. This is nicely contained and means that only one set
of credentials is required to access all the resources.

There are many alternative services for storing these repositories, both
in the cloud and on premises. Below we list the choices we have tested
during the POC.

The 2 classes of repository are as follows:

:Source Repository:

  - Holds the source code but also provides the
    Continuous Integration actions for testing, building and publishing to
    the image / helm repositories. These have been tested:

    - github
    - gitlab (on premises)

  - epics-containers defines two classes of source repository:

    - Generic IOC source. Defines how a Generic IOC image is built, this does
      not typically include source code, but instead is a set of instructions
      for building the Generic IOC image.
    - Beamline / Accelerator Domain source. Defines the IOC instances for a
      beamline or Accelerator Domain. This includes the IOC boot scripts and
      any other configuration required to make the IOC instance unique.
      For **ibek** based IOCs, each IOC instance is defined by an **ibek**
      yaml file only.

:An OCI image repository:

  - Holds the Generic IOC container images and their
    dependencies. The following have been tested:

    - Github Container Registry
    - DockerHub
    - Google Cloud Container Registry


Continuous Integration
~~~~~~~~~~~~~~~~~~~~~~

Our examples all use continuous integration to get from pushed source
to the published images.

This allows us to maintain a clean code base that is continually tested for
integrity and also to maintain a direct relationship between source code tags
and the tags of their built resources.

There are these types of CI:

:Generic IOC source:
    - builds a Generic IOC container image
    - runs some tests against that image
    - publishes the image to github packages (only if the commit is tagged)
      or other OCI registry

:beamline definition source:
    - builds a helm chart from each ioc definition
    - tests that the helm chart is deployable (but does not deploy it)
    - locally launches each IOC instance and loads its configuration to
      verify that the configuration is valid (no system tests because this
      would require talking to beamline hardware).

:documentation source:
    - builds the sphinx docs
    - publishes it to github.io pages with version tag or branch tag.

Scope
-----
This project initially targets x86_64 Linux Soft IOCs and RTEMS IOC running
on MVME5500 hardware. Soft IOCs that require access to hardware on the
server (e.g. USB or PCIe) will be supported by mounting the hardware into
the container (theses IOCS will not support failover).

Other linux architectures could be added to the Kubernetes cluster. We have
tested arm64 native builds and will add this as a supported architecture
in the future.


Additional Tools
----------------

epics-containers-cli
~~~~~~~~~~~~~~~~~~~~
This define the developer's 'outside of the container' helper tool. The command
line entry point is **ec**.

The project is a python package featuring simple command
line functions for deploying, monitoring building and debugging
Generic IOCs and IOC instances. It is a wrapper
around the standard command line tools kubectl, podman/docker, helm, and git
but saves typing and provides help and command line completion.

See `CLI` for details.


**ibek**
~~~~~~~~
IOC Builder for EPICS and Kubernetes is the developer's 'inside the container'
helper tool. It is a python package that is installed into the Generic IOC
container images. It is used:

- at container build time to fetch and build EPICS support modules
- to generate the IOC source code and compile it
- to extract all useful build artifacts into a runtime image

See https://github.com/epics-containers/ibek.

PVI
~~~
Process Variables Interface is a python package that is installed into the
Generic IOC container images. It is used to give structure to the IOC's PVI
interface allowing us to:

- add metadata to the IOCs DB records for use by bluesky
- auto generate screens for the device (as bob, adl or edm files)



