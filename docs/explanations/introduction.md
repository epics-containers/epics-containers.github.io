(essential)=

# Essential Concepts

## Overview

```{include} ../overview.md
```

The rest of this page explains each of these in turn.

## Concepts

### Images and Containers

A container packages IOC software with everything it needs to run, and executes
it in a lightweight, isolated environment. Images are stored in public or
private registries such as DockerHub or the GitHub Container Registry.

The Open Container Initiative (OCI) standardises container images and their
runtime APIs, so an image is interchangeable between tools. We build and test
our images with podman, but the same image runs unchanged under Kubernetes'
container runtime. For more on how containers and Kubernetes relate, see
[this overview](https://semaphoreci.com/blog/kubernetes-vs-docker).

The key payoff: you change the environment *inside* the container to suit the
IOC, instead of changing the IOC to suit your infrastructure. At DLS this means
we build against vanilla EPICS base and support modules — we no longer maintain
our own forks.

(generic-iocs)=

#### Generic IOCs and instances

The central idea is that an IOC container image is a **Generic IOC**: one image
shared by every IOC instance that talks to a given class of device. For example
[ghcr.io/epics-containers/ioc-adaravis-runtime:2026.4.3](https://github.com/epics-containers/ioc-adaravis/pkgs/container/ioc-adaravis-runtime)
uses the AreaDetector driver ADAravis to drive any GigE camera.

A Generic IOC image contains:

- a set of compiled support modules
- a compiled IOC binary that links all those modules
- a dbd file for all the support modules.

It deliberately contains no startup script or EPICS database — those are
instance-specific and supplied at runtime.

An **IOC instance** runs by combining two things:

- the Generic IOC image, passed to the container runtime
- its instance configuration, mounted into the container's filesystem (usually
  at `/epics/ioc/config`).

The configuration bootstraps the unique properties of that instance. The config
folder can hold any of:

- `ioc.yaml`: an **ibek** IOC description that **ibek** turns into `st.cmd` and
  `ioc.subst`.
- `st.cmd` plus an optional `ioc.subst`: a shell startup script and substitution
  file. `st.cmd` may refer to other files in the config directory.
- `start.sh`: a bash script that fully overrides IOC startup. It may also refer
  to other files in the config directory.

Sharing one image across many instances keeps the number of images small,
saves disk and memory, and makes configuration management simpler.

Throughout these docs we use the terms **Generic IOC** and **IOC instance**.
The bare word "IOC" without that context is ambiguous.

### Kubernetes

[Kubernetes](https://kubernetes.io/) efficiently runs and manages containers
across a cluster of hosts. It is the dominant container orchestration system,
governed by the [Cloud Native Computing Foundation](https://www.cncf.io/).

You tell Kubernetes the resources an IOC needs; it schedules the IOC onto a host
with enough capacity. We use Kubernetes and Helm (its package manager) to get a
standard way to:

- auto-start IOCs when the cluster powers up
- place each IOC on a server with adequate resources
- start and stop IOCs on demand
- monitor IOC health and restart failed IOCs automatically
- deploy versioned IOCs to a beamline
- report version, uptime, restarts and other metadata
- roll an IOC back to a previous version
- fail a (hardware-independent) soft IOC over to another server
- view current and historical logs (the latter via Graylog or similar)
- attach to an IOC's shell, or open a bash shell inside its container to debug.

### Kubernetes Alternatives

You don't have to run Kubernetes. **epics-containers** is modular — you can
adopt any part of it without taking the whole framework.

If you would rather not maintain a cluster, install IOCs directly into the local
podman on each server and manage them with docker compose instead of Helm. We
provide a template services project that does exactly this: a compose file
describes the set of IOCs and other services for a server, much as Helm does. A
beamline with several servers can keep one compose file per server.

For a web view across servers you may want an additional tool.
[Portainer](https://www.portainer.io/) (free Community Edition, paid Business
Edition) has been tested with **epics-containers** and gives good visibility and
control of containers through a browser.

Docker Swarm could replace some of Kubernetes' multi-server orchestration too.
We have not tried it, but it is compatible with the compose files we template.

### Helm

[Helm](https://helm.sh/) is the most popular package manager for Kubernetes.
Its packages, called Helm Charts, are templated YAML files describing the
resources to apply to a cluster. Helm deploys Charts, manages multiple versions
in the cluster, and can store version history in a registry much like a
container image registry.

We use Helm Charts to define and deploy IOC instances. IOCs are grouped into a
{any}`services-repo` — typically one per beamline or accelerator technical area,
though any grouping works. Each IOC instance folder need only contain:

- a `values.yaml` that overrides the repository's global defaults
- a config folder, as described in {any}`generic-iocs`
- a little boilerplate that is identical for every IOC.

We do **not** push each IOC instance to a Helm registry. Such a registry would
only hold a zipped copy of Chart files that already live in git — redundant.
Instead, a single global Helm Chart captures everything shared between instances
and lives in a Helm registry; each folder in the services repository is itself a
Chart that pulls in that global Chart as a dependency.

### Repositories

Every asset needed to manage a facility's IOC instances lives in git
repositories. All version control happens there — no special shared-filesystem
locations required. (The legacy DLS approach leaned heavily on known paths in a
shared filesystem.)

In our examples every repository sits in one GitHub organization, so a single
set of credentials reaches everything. Many alternatives exist, in the cloud or
on premises; the lists below show what we have tested. The most common
repository types are:

```{eval-rst}

:Generic IOC Source Repositories:

  Define how a Generic IOC image is built. This is mostly a set of instructions
  for compiling source from upstream support module repositories, rather than
  source code itself. Boilerplate IOC source is included too and can be
  customised if needed. Tested on:

  - GitHub
  - GitLab (on premises)

:Services Source Repositories:

  Define the IOC instances and other services for a beamline, accelerator
  technical area, or any other grouping. Tested on:

  - GitHub
  - GitLab (on premises)


:An OCI Image Registry:

  Holds the Generic IOC container images and their dependencies, plus the global
  Helm Chart shared between domains. Tested on:

  - GitHub Container Registry
  - DockerHub
  - Google Cloud Container Registry
```

### Continuous Integration

Our examples use CI to get from pushed source to published images, Helm Charts
and documentation. This keeps the codebase continually tested and ties every
built artifact's version tag directly to a source commit tag.

```{eval-rst}

:Generic IOC source:
    - builds a Generic IOC container image
    - runs tests against the image to verify the container loads and the Generic
      IOC starts with a sample configuration
    - publishes the image to an OCI registry (only when the commit is tagged)

:Services Source:
    - prepares a Helm Chart from each IOC instance or other service definition
    - tests that the Helm Chart is deployable (without deploying it)
    - launches each IOC instance locally and loads its configuration to verify
      it is valid (no system tests, as those would need real hardware)

:Documentation Source:
    - builds the Sphinx docs you are reading now
    - publishes them to GitHub Pages, tagged by version or branch

:Global Helm Chart Source:
    - the ``ec-helm-charts`` repo only
    - packages a Helm Chart from source
    - publishes it to an OCI registry (only when the commit is tagged)
```

### Continuous Deployment

[ArgoCD](https://argo-cd.readthedocs.io/) is a Kubernetes controller that
continuously compares the cluster's running state with the desired state
declared in git, and reconciles any difference.

To drive it, each services repository has a companion deployment repository that
records which version of each IOC should currently be deployed. That list of
versions is a single YAML file; pushing a change to it triggers ArgoCD to update
the cluster. Because every change is in git, rolling the whole beamline back to
its state on a given date is straightforward — there is a complete record.

## Scope

This project targets x86_64 Linux soft IOCs. Soft IOCs that need direct hardware
access on the server (e.g. USB or PCIe) are supported by mounting the hardware
into the container — though these IOCs cannot use Kubernetes failover.

Other Linux architectures could be added to the cluster. arm64 native builds
have been prototyped but are not yet a supported architecture.

Python soft IOCs are also supported — see
[pythonSoftIOC](https://github.com/DiamondLightSource/pythonSoftIOC).

GUI generation for engineering screens is provided by the PVI project — see
[pvi](https://github.com/epics-containers/pvi).

## Additional Tools

### ec

**ec** is the "outside the container" helper. It is a Python package providing
simple command-line functions for deploying and monitoring IOC instances — a
thin wrapper around the ArgoCD, kubectl, helm and git commands. Developers and
beamline staff use it for a quick CLI view of IOCs in the cluster, and to
stop/start them and fetch their logs. See
[edge-containers-cli](https://github.com/epics-containers/edge-containers-cli).

### ibek

**ibek** (IOC Builder for EPICS and Kubernetes) is the developer's "inside the
container" helper, installed into every Generic IOC image. It is used:

- at build time: to fetch and build EPICS support modules
- at run time: to generate build artifacts, e.g. `st.cmd` and the IOC database,
  from the `ioc.yaml` configuration
- inside the developer container: to assist with testing and debugging.

See [ibek](https://github.com/epics-containers/ibek).

### PVI

**PVI** (Process Variables Interface) is a Python package installed inside
Generic IOC images. It gives structure to an IOC's process variables, letting us:

- add metadata to the IOC's DB records for use by [Bluesky] and [Ophyd]
- auto-generate device screens (as bob, adl or edm files).

[bluesky]: https://blueskyproject.io/
[ophyd]: https://github.com/bluesky/ophyd-async
[pvi]: https://github.com/epics-containers/pvi
