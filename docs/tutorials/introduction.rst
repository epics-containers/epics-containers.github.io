Quick Start Introduction
========================

Overview
~~~~~~~~

Kubernetes for EPICS IOCs provides the means to deploy and manage IOCs using
modern industry standard approaches.

This page briefly describes the technology and concepts behind this
approach.

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

Images and Containers
~~~~~~~~~~~~~~~~~~~~~
**TODO**

Kubernetes
~~~~~~~~~~
**TODO**

Helm
~~~~
**TODO**

Ibek
~~~~
**TODO**

