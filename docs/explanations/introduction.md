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

The generic IOC image contains:

- a set of compiled support modules
- a compiled IOC binary that links all those modules
- a dbd file for all the support modules.

It does not contain a startup script pr EPICS database, these are instance specific and added at runtime.

An IOC instance runs in a container runtime by loading two things:

- The Generic IOC image passed to the container runtime.
- The IOC instance configuration. This is mapped into the container at  runtime by mounting it into the filesystem. The mount point for this configuration is usually the folder `/epics/ioc/config`.

The configuration will bootstrap the unique properties of that instance. The following contents for the configuration folder are supported:

- ``ioc.yaml``: an **ibek** IOC description file which **ibek** will use to generate
  st.cmd and ioc.subst.
- ``st.cmd`` and ``ioc.subst``: an IOC shell startup script and an optional substitution file.
  st.cmd can refer to any additional files in the configuration directory.
- ``start.sh``: a bash script to fully override the startup of the IOC. start.sh
  can refer to any additional files in the configuration directory.

This approach reduces the number of images required and saves disk and memory. It also makes for simpler configuration management.

Throughout this documentation we will use the terms Generic IOC and IOC Instance. The word IOC without this context is ambiguous.

### Kubernetes

<https://kubernetes.io/>

Kubernetes efficiently manages containers across clusters of hosts. It builds upon years of experience of running production workloads at Google, combined with best-of-breed ideas and practices from the community, since it was open-sourced in 2014.

Today Kubernetes is by far the dominant orchestration system for containers. It is managed by The Cloud Native Computing Foundation (CNCF) which is part of the Linux Foundation. You can read about its active community here <https://www.cncf.io/>.

When deploying an IOC into a Kubernetes cluster, you request the resources needed by the IOC and Kubernetes will then schedule the IOC onto a suitable host with sufficient resources.

In this project we use Kubernetes and Helm (the package manager for Kubernetes) to provide a standard way of
implementing these features:

- Auto start IOCs when the cluster comes up from power off
- Allocate a server with adequate resources on which to run each IOC
- Manually Start and Stop IOCs
- Monitor IOC health, automatically restart IOCs that have failed
- Deploy versioned IOCs to the beamline
- Report the versions, uptime, restarts and other metadata of the IOCs
- Rollback an IOC to a previous version
- Failover to another server (for soft IOCs not tied to hardware in a server) if the server fails
- View the current log
- View historical logs (via graylog or other centralized logging system)
- Connect to an IOC and interact with its shell
- debug an IOC by starting a bash shell inside it's container

### Kubernetes Alternatives
If you do not wish to maintain a Kubernetes cluster then you could simply install IOCs directly into the local docker or podman instance on each server. Instead of using Kubernetes and Helm, you can use docker compose to manage such IOC instances. But this is just an example, epics-containers is intended to be modular so that you can make use of any parts of it without adopting the whole framework as used at DLS.

We provide a template services project that uses docker compose with docker or podman as the runtime engine. Docker compose allows us to describe a set of IOCs and other services for each beamline server, similar to the way Helm does. Where a beamline has multiple servers, the distribution of IOCs across those servers could be managed by maintaining a separate docker-compose file for each server in the root of the services repository.

If you choose to use this approach then you may find it useful to have another tool for viewing and managing the set of containers you have deployed across your beamline servers. There are various solutions for this, one that has been tested with **epics-containers** is Portainer <https://www.portainer.io/>. Portainer is a paid for product that provides excellent visibility and control of your containers through a web interface. Such a tool could allow you to centrally manage the containers on all your servers.

The multi-server orchestration tool Docker Swarm might also serve to replace some of the functionality of Kubernetes. The epics-containers team have not yet tried Swarm, but it is compatible with the docker-compose files we template.

### Helm

<https://helm.sh/>

Helm is the most popular package manager for Kubernetes applications.

The packages are called Helm Charts. They contain templated YAML files to
define a set of resources to apply to a Kubernetes cluster.

Helm has functions to deploy Charts to a cluster and manage multiple versions
of the Chart within the cluster.

It also supports registries for storing version history of Charts,
much like docker.

In this project we use Helm Charts to define and deploy IOC instances. IOCs are grouped into a {any}`services-repo`. Typical services repositories represent a beamline or accelerator technical area but any grouping is allowed. Each of these repositories holds the Helm Charts for its IOC Instances and any other services we require. Each IOC instance folder need only contain:

- a values.yaml file to override the default values in the repository's global values.yaml.
- a config folder as described in {any}`generic-iocs`.
- a couple of boilerplate Helm files that are the same for all IOCs.

**epics-containers** does not use helm registries for storing each IOC instance. Such registries only hold a zipped version of the Chart files, and this is redundant when we have a git repository holding the same information. Instead a single global helm chart represents the shared elements between all IOC instances and is stored in a helm registry. Each folder in the services repository is itself a helm chart that includes that global chart as a dependency.

### Repositories

All of the assets required to manage all of the IOC Instances for a facility are held in repositories.

Thus all version control is done via these repositories and no special locations in a shared filesystem are required. (The legacy approach at DLS relied heavily on know locations in a shared filesystem).

In the **epics-containers** examples all repositories are held in the same github organization. This is nicely contained and means that only one set of credentials is required to access all the resources.

There are many alternative services for storing these repositories, both in the cloud and on premises. Below we list the choices we have tested during the proof of concept.

The most common classes of repository are as follows:

```{eval-rst}

:Generic IOC Source Repositories:

  Define how a Generic IOC image is built, this does not typically include source code, but instead is a set of instructions for building the Generic IOC image by compiling source from a number of upstream support module repositories. Boilerplate IOC source code is also included in the Generic IOC source repository and can be customized if needed. These have been tested:

  - GitHub
  - GitLab (on premises)

:Services Source Repositories:

  Define the IOC instances and other services for a beamline, accelerator technical area or any other grouping strategy. These have been tested:

  - GitHub
  - GitLab (on premises)


:An OCI Image Registry:

  Holds the Generic IOC container images and their dependencies. Also used to hold the helm Charts that define the shared elements between all domains.

  The following have been tested:

  - Github Container Registry
  - DockerHub
  - Google Cloud Container Registry
```

### Continuous Integration

Our examples all use continuous integration to get from pushed source
to the published images, IOC instances Helm Charts and documentation.

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

:Services Source:
    - prepares a helm Chart from each IOC instance or other service definition
    - tests that the helm Chart is deployable (but does not deploy it)
    - locally launches each IOC instance and loads its configuration to
      verify that the configuration is valid (no system tests because this
      would require talking to real hardware instances).

:Documentation Source:
    - builds the sphinx docs that you are reading now
    - publishes it to github.io pages with version tag or branch tag.

:Global Helm Chart Source:
    - ``ec-helm-chars`` repo only
    - packages a helm Chart from source
    - publishes it to github packages (only if the commit is tagged)
      or other OCI registry
```

### Continuous Deployment

ArgoCD is a Kubernetes controller that continuously monitors running applications and compares their current state with the desired state described in a git repository. If the current state does not match the desired state, ArgoCD will attempt to reconcile the two.

For this purpose each services repository will have a companion deployment repository which tracks which version of each IOC in the services repository should currently be deployed to the cluster. This list of IOC versions is in a single YAML file and updating this file and pushing it to the deployment repository will trigger ArgoCD to update the cluster accordingly.

In this fashion changes to IOC versions are tracked in git and it is easy to roll back to the same state as a given date because there is a complete record.

## Scope

This project initially targets x86_64 Linux Soft IOCs and RTEMS 'hard' IOCs running on MVME5500 hardware. Soft IOCs that require access to hardware on the server (e.g. USB or PCIe) will be supported by mounting the hardware into the container (these IOCS will not support Kubernetes failover).

Other linux architectures could be added to the Kubernetes cluster. We have tested arm64 native builds and will add this as a supported architecture in the future.

Python soft IOCs are also supported. See <https://github.com/DiamondLightSource/pythonSoftIOC>

GUI generation for engineering screens is supported via the PVI project. See <https://github.com/epics-containers/pvi>.

## Additional Tools

### edge-containers-cli

This is the 'outside of the container' helper tool. The command
line entry point is **ec**.

The project is a python package featuring simple command line functions for deploying and monitoring IOC instances. It is a thin wrapper around the ArgoCD, kubectl, helm and git commands. This tool can be used by developers and beamline staff to get a quick CLI based view of IOCs running in the cluster, as well as stop/start and obtain logs from them.

See {any}`CLI` for more details.

### **ibek**

IOC Builder for EPICS and Kubernetes is the developer's 'inside the container' helper tool. It is a python package that is installed into the Generic IOC container images. It is used:

- at container build time: to fetch and build EPICS support modules
- at container run time: to generate all useful build artifacts into a runtime image e.g. generating the st.cmd and ioc.db file from the ioc.yaml configuration file.
- inside the developer container: to assist with testing and debugging.

See <https://github.com/epics-containers/ibek>.

### PVI

The Process Variables Interface project is a python package that is installed inside Generic IOC container images. It is used to give structure to the IOC's Process Variables allowing us to:

- add metadata to the IOCs DB records for use by [Bluesky] and [Ophyd]
- auto generate screens for the device (as bob, adl or edm files)

[bluesky]: https://blueskyproject.io/
[ophyd]: https://github.com/bluesky/ophyd-async
[pvi]: https://github.com/epics-containers/pvi
