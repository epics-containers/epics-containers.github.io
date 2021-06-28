epics-containers Contents
=========================

The epics-containers organization contains the following elements.

Example Beamline
----------------

By way of example we will include a full implementation of the
test beamline BL45P at Diamond Light Source.

The benefit of this is that it will be live and constantly kept up to date with
the latest developments. Also proven to work, see `argus` for details of the
DLS cluster which hosts this beamline.

The downside is that it will only serve as an example; those without access
to the beamline will not be able to run the code without getting errors.

**TODO**: we will supply a demo beamline that is based purely on simulated devices
so that anyone can experiment with Kubernetes for EPICS IOCs, this will be
used in the tutorials to walk through deployment.


Production generic IOCs
-----------------------

The generic IOC container images supplied here are intended for general use.
All EPICS modules included in these images are vanilla versions direct from
their official repositories with the absolute minimum of changes.

A great benefit of using containers is that you can adjust the container
environment to suit the software instead of needing to modify the software to
suit your organizations infrastructure.

Therefore there is a real possibility that multiple facilities can use the
same images with all the economies of scale that this implies.

These generic images are intended to be used in production at DLS once the
Beamline Kubernetes infrastructure is rolled out.


Utilities
---------

The repository k8s-epics-utils contains scripts simplifying the
managing IOCs using helm and kubectl. It also contains a personal
container for developers, this allows a developer to work on the support
modules and IOCs without installing anything on their desktop except docker.


Packages in the Organization
----------------------------

In addition to source repositories the epics-containers organization also hosts
the container images and helm charts that it generates. See
https://github.com/orgs/epics-containers/packages for the packages registry
that stores these.


Naming Convention for Repositories
----------------------------------

The following naming conventions help identify the source repositories. Note
that where a repository generates an image the image will have the same name.
e.g.

- the repo

  - https://github.com/epics-containers/epics-base
- generates the image

  - https://github.com/epics-containers/epics-base/pkgs/container/epics-base


:epics:
    this prefix is for images that are nodes in the network of
    image dependencies.
    e.g. epics-base, epics-areadetector

:iocs:
    this prefix is for images that are leaves in the network of
    image dependencies. These are the images which IOC instances make
    containers from. e.g. ioc-pmac, ioc-adaravis

:k8s:
    this prefix is for utilities repositories.

:helm:
    this prefix is for definitions of helm charts or helm chart libraries

:bl:
    this prefix is for the example beamline repositories e.g. bl45p. Note
    that when tagged commit is pushed to these repositories, they will
    generate a helm chart per ioc defined in the beamline. These helm charts
    are also pushed to the packages registry.
    e.g.

    - https://github.com/epics-containers/bl45p/pkgs/container/bl45p-mo-ioc-01