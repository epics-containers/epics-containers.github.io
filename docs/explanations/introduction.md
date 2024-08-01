(essential)=

# Essential Concepts

## Overview

```{include} ../overview.md
```

See below for more details on each of these.

## Concepts

### Images and Containers

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
containers and Kubernetes <https://semaphoreci.com/blog/kubernetes-vs-docker>

An important outcome of using containers is that you can alter the
environment inside the container to suit the IOC code, instead of altering the
code to suit your infrastructure. At DLS, this means that we are able to use
vanilla EPICS base and support modules. We no longer require our own
forks of these repositories.

(generic-iocs)=

#### Generic IOCs and instances

An important principal of the approach presented here is that an IOC container image represents a 'Generic' IOC. The Generic IOC image is used for all IOC instances that connect to a given class of device. For example the Generic IOC image here: [ghcr.io/epics-containers/ioc-adaravis-runtime:2024.2.2 ](https://github.com/epics-containers/ioc-adaravis/pkgs/container/ioc-adaravisruntime) uses the AreaDetector driver ADAravis to connect to GigE cameras.

An IOC instance runs in a container runtime by loading two things:

- The Generic IOC image passed to the container runtime.
- The IOC instance configuration. This is mapped into the container at
  runtime by mounting it into the filesystem. The mount point
  for this configuration is always `/epics/ioc/config`.

The configuration will bootstrap the unique properties of that instance.
The following contents for the configuration are supported:

- ioc.yaml: an **ibek** IOC description file which **ibek** will use to generate
  st.cmd and ioc.subst.
- st.cmd, ioc.subst: an IOC shell startup script and an optional substitution file.
  st.cmd can refer any additional files in the configuration directory.
- start.sh a bash script to fully override the startup of the IOC. start.sh
  can refer to any additional files in the configuration directory.

This approach reduces the number of images required and saves disk and memory. It also makes for simpler configuration management.

Throughout this documentation we will use the terms Generic IOC and
IOC Instance. The word IOC without this context is ambiguous.

### Kubernetes

<https://kubernetes.io/>

Kubernetes easily and efficiently manages containers across clusters of hosts.
When deploying an IOC into a Kubernetes cluster, you request the resources
required by the IOC and Kubernetes will then schedule the IOC onto a suitable host.

It builds upon years of experience of running production workloads at Google, combined with best-of-breed ideas and practices from the community, since it was open-sourced in 2014.

Today it is by far the dominant orchestration technology for containers.

In this project we use Kubernetes and helm to provide a standard way of
implementing these features:

- Auto start IOCs when the cluster comes up from power off
- Manually Start and Stop IOCs
- Monitor IOC health and versions
- Deploy versioned IOCs to the beamline
- Rollback IOCs to a previous version
- Allocate a server with adequate resources on which to run each IOC
- Failover to another server (for soft IOCs not tied to hardware in a server)
- View the current log
- View historical logs (via graylog or other centralized logging system)
- Connect to an IOC and interact with its shell
- debug an IOC by starting a bash shell inside it's container

### Kubernetes Alternative
If you do not have the resources to maintain a Kubernetes cluster then this project supports installing IOC instances directly into the local docker or podman runtime on the current server. Where a beamline has multiple servers the distribution of IOCs across those servers is managed by the user. These tools would replace Kubernetes and Helm in the technology stack. Docker compose allows us to describe a set of IOCs and other services for each beamline server.

If you choose to use this approach then you may find it useful to have another
tool for viewing and managing the set of containers you have deployed across
your beamline servers. There are various solutions for this, one that has
been tested with **epics-containers** is Portainer <https://www.portainer.io/>.
Portainer is a paid for product
that provides excellent visibility and control of your containers through a
web interface. It is very easy to install.

The downsides of not using Kuberenetes are:

- manually managing the resources. i.e. deciding up front which server to run each IOC on.
- no automatic failover to another server if the current server fails or becomes overloaded.
- no continuous deployment
-

 is that you will need to manually manage the resources available to each IOC instance and manually decide which server to run each IOC on. It also means that you cannot take advantage of the Kubernetes feat

### Helm

<https://helm.sh/>

Helm is the most popular package manager for Kubernetes applications.

The packages are called Helm Charts. They contain templated YAML files to
define a set of resources to apply to a Kubernetes cluster.

Helm has functions to deploy Charts to a cluster and manage multiple versions
of the chart within the cluster.

It also supports registries for storing version history of charts,
much like docker.

In this project we use Helm Charts to define and deploy IOC instances. Each beamline or accelerator area has its own git {any}`ec-services-repo` that holds the Helm Charts for its IOC Instances. Each IOC instance need only provide:

- a values.yaml file to override the default values in the repository's global Helm Chart
- a config folder as described in {any}`generic-iocs`.

**epics-containers** does not use helm repositories for storing IOC instances.
Such repositories only hold a zipped version of the chart and a values.yaml file,
and this is seen as redundant when we have a git repository holding the same
information. Instead we provide a command line tool for installing and updating
IOCs. Which performs the following steps:

- Clone the beamline repository at a specific tag to a temporary folder
- install the resulting chart into the cluster
- remove the temporary folder
- helm templating for making multiple similar IOCs is not available
- no centralized access to ioc shell or debug shell - instead you must ssh to the correct server first.


### Repositories

All of the assets required to manage a set of IOC Instances for a beamline are held in repositories.

Thus all version control is done via these repositories and no special locations in a shared filesystem are required. (The legacy approach at DLS relied heavily on know locations in a shared filesystem).

In the **epics-containers** examples all repositories are held in the same github organization. This is nicely contained and means that only one set of credentials is required to access all the resources.

There are many alternative services for storing these repositories, both in the cloud and on premises. Below we list the choices we have tested during the POC.

The classes of repository are as follows:

```{eval-rst}
:Source Repository:

  Holds the source code but also provides the Continuous Integration actions for testing, building and publishing to the image / helm repositories. These have been tested:

  - GitHub
  - GitLab (on premises)

:Generic IOC Source Repositories:

  Define how a Generic IOC image is built, this does not typically include source code, but instead is a set of instructions for building the Generic IOC image by compiling source from a number of upstream support module repositories. Boilerplate IOC source code is also included in the Generic IOC source repository and can be customized if needed.

:Services Source Repositories:

  Define the IOC instances and other services for a beamline, accelerator domain or any other grouping strategy. This includes the IOC boot scripts and any other configuration required to make the IOC instance unique. For **ibek** based IOCs, each IOC instance is defined by an **ibek** yaml file only.

:An OCI Image Repository:

  Holds the Generic IOC container images and their dependencies. Also used to hold he helm charts that define the shared elements between all domains.

  The following have been tested:

  - Github Container Registry
  - DockerHub
  - Google Cloud Container Registry
```

### Continuous Integration

Our examples all use continuous integration to get from pushed source
to the published images, IOC instances helm charts and documentation.

This allows us to maintain a clean code base that is continually tested for
integrity and also to maintain a direct relationship between source code version
tags and the tags of their built resources.

There are these types of CI:

```{eval-rst}

:Generic IOC source:
    - builds a Generic IOC container image
    - runs some tests against that image - these will eventually include
      system tests that talk to simulated hardware
    - publishes the image to github packages (only if the commit is tagged)
      or other OCI registry

:services source:
    - prepares a helm chart from each IOC instance or other service definition
    - tests that the helm chart is deployable (but does not deploy it)
    - locally launches each IOC instance and loads its configuration to
      verify that the configuration is valid (no system tests because this
      would require talking to real hardware instances).

:documentation source:
    - builds the sphinx docs
    - publishes it to github.io pages with version tag or branch tag.

:global helm chart source:
    - ``ec-helm-chars`` repo only
    - packages a helm chart from source
    - publishes it to github packages (only if the commit is tagged)
      or other OCI registry
```

## Scope

This project initially targets x86_64 Linux Soft IOCs and RTEMS IOC running
on MVME5500 hardware. Soft IOCs that require access to hardware on the
server (e.g. USB or PCIe) will be supported by mounting the hardware into
the container (these IOCS will not support Kubernetes failover).

Other linux architectures could be added to the Kubernetes cluster. We have
tested arm64 native builds and will add this as a supported architecture
in the future.

Python soft IOCs are also supported.

GUI generation for engineering screens is supported via the PVI project. See <https://github.com/epics-containers/pvi>.

## Additional Tools

### edge-containers-cli

This is the 'outside of the container' helper tool. The command
line entry point is **ec**.

The project is a python package featuring simple command line functions for deploying monitoring IOC instances. It is a thin wrapper around the argocd, kubectl, helm and git commands. This tool can be used by developers and beamline staff to get a quick CLI based view of IOCs running in the cluster, as well as stop/start and obtain logs from them.

See {any}`CLI` for more details.

### **ibek**

IOC Builder for EPICS and Kubernetes is the developer's 'inside the container'
helper tool. It is a python package that is installed into the Generic IOC
container images. It is used:

- at container build time: to fetch and build EPICS support modules
- at container run time: to extract all useful build artifacts into a
  runtime image
- inside the developer container: to assist with testing and debugging.

See <https://github.com/epics-containers/ibek>.

### PVI

The Process Variables Interface project is a python package that is installed
inside Generic IOC container images. It is used to give structure to the IOC's
Process Variables allowing us to:

- add metadata to the IOCs DB records for use by [Bluesky] and [Ophyd]
- auto generate screens for the device (as bob, adl or edm files)

[bluesky]: https://blueskyproject.io/
[ophyd]: https://github.com/bluesky/ophyd-async
[pvi]: https://github.com/epics-containers/pvi
