Essential Concepts
==================

Overview
--------

Kubernetes for EPICS IOCs provides the means to deploy and manage IOCs using
modern industry standard approaches.

This page briefly describes the required concepts and technologies.


Concepts
--------

Generic IOCs and instances
~~~~~~~~~~~~~~~~~~~~~~~~~~

An important principal of the approach presented here is that an IOC container
image represents a 'generic' IOC. The generic IOC image is used for all
IOC instances that connect to a given class of device.

An IOC instance runs in a container that bases its
filesystem on a generic IOC image.
In addition the instance has configuration mapped into the
container that will bootstrap the unique properties of that instance.
In most cases the configuration need only be a single IOC boot script.

This approach reduces the number of images required and saves disk. It also
makes for simple configuration management.

Throughout this documentation we will use the terms Generic IOC and
IOC Instance. The word IOC without this context is ambiguous.

Repositories
~~~~~~~~~~~~

Another important principal is that all of the assets required to manage a
set of IOCs for a beamline are held in repositories.

These repositories all maintain their own history and version information.

Thus all configuration management is done
via these repositories and no special locations in
the local filesystem are required
(The legacy approach at DLS relied heavily on
know locations in the filesystem).

In the epics-containers examples all 3 repositories are held in the same
github organization. This is nicely contained and means that only one set
of credentials is required to access all the resources.

There are many alternative services for storing these repositories, both
in the cloud and on premises. Below we list the choices we have tested
during proof of concept.

The 3 repositories are as follows:

- **Source Repository** This not only holds the source but also provides the
  Continuous Integration actions for testing, building and publishing to
  the following 2 repositories. These have been tested
  during proof of concept:

  - github
  - gitlab (on prem)

- **An image registry** that holds the generic IOC container images and their
  dependencies. The following have been tested during proof of concept:

  - github packages
  - dockerhub
  - Google Cloud Container Registry

- **A helm chart registry**. This is where the definitions of IOC instances
  are stored. They are in the form of a helm chart which describes to
  Kubernetes the resources needed to spin up the IOC.
  The following have been tested during proof of concept:

  - github packages
  - Google Cloud Artifact Registry

Continuous Integration
~~~~~~~~~~~~~~~~~~~~~~

Our examples all use continuous integration to get from pushed source
to the published images / helm charts.

This allows us to maintain a clean code base that is continually tested for
integrity and also to maintain a direct relationship between source code tags
and the tags of their built resources.

There are these types of CI:

:Generic IOC repositories:
    - builds a generic IOC container image
    - runs some tests against that image
    - publishes the image to github packages (only if the commit is tagged)

:beamline repositories:
    - builds a helm chart from each ioc definition
      (TODO ibek will do this - at present the charts are hand coded)
    - TODO: IOCs which are unchanged should not be published again
    - publishes the charts to github packages (only if the commit is tagged)

:helm library repositories:
    - builds the helm chart
    - publishes it to github packages (only if the commit is tagged)

:documentation repository:
    - builds the sphinx docs
    - publishes it to github.io pages

Industry Standard Technologies
------------------------------

Images and Containers
~~~~~~~~~~~~~~~~~~~~~
**TODO**

Kubernetes
~~~~~~~~~~
**TODO**

Helm
~~~~
**TODO**

Additional Tools
----------------

k8s-epics-utils
~~~~~~~~~~~~~~~
**TODO**

Ibek
~~~~
**TODO**

