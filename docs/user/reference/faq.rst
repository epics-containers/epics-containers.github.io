Frequently Asked Questions
==========================

.. _no_opi:

Why no mention of Operator Interfaces?
--------------------------------------
OPI was out of scope for the proof of concept. That is because we
expect there to be a web based EPICS OPI available by the time we go
live with K8s IOCs. Kubernetes is very well suited to running web
servers so this is a natural fit.

There are a number of ways to support the current OPI solutions without
breaking the repositories-only model. The simplest approach is to extract
the OPI files from the container running in Kubernetes with **kubectl cp**.
Then keep a local cache and run the OPI code locally.


Why have ioc-XXX repositories?
------------------------------
Why not put the Dockerfile and image generating in the support module itself
instead of creating a separate generic ioc module for each image we
generate?

Answers:

- There is not always a 1-1 relationship between support modules and generic
  IOCs. A generic IOC image is free to add any number of support modules it
  requires.

- The lifecycle of a support module will often differ from a generic IOC.
  The version number of the image is tied to the ioc-XXX source repo that
  it generates, so we can have separate versions for support and IOC.

- Not all users of a support module will need images generated and it may be
  counter productive for them to be required to update the Dockerfile when
  they are working on changes to a support module.


How can I do IOC rollback if the internet is down?
--------------------------------------------------
The examples all use cloud registries for storing the generic IOC images and
IOC instance Helm Charts. However it is still possible to roll back an IOC
version when the internet is not available.

That is because Helm keeps track of several versions of each chart it
deploys, they are stored in the cluster itself (as ReplicaSets). By
default the last 10 are saved.

It is also necessary for Kubernetes to be able to pull the generic IOC image. If
the beamline has only one Kubernetes worker node then the previous image will
be in the node's local cache. If you have more than one then you will need
a global image cache which is useful anyway for reducing traffic to the
registries (JetStack have performed a POC for DLS that demonstrates such a
global cache)

Note that making changes to an IOC and spinning them up would not be possible
if all registries were in the cloud. However it is recommended that the 'work'
registries are on prem. The production helm registry is also likely to be on
prem since there is little benefit in sharing a facility's IOC instances.
