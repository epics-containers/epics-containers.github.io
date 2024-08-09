
# Glossary

(services-repo)=
## services repository

A repository that contains the definitions for a group of IOCs instances and other services. The grouping of instances is up to the facility. At DLS the instances are grouped by beamline for beamline IOCs. Accelerator IOC groupings by technical domain as appropriate.

epics-containers supports two kinds of services repositories:

- **Kubernetes** services repositories. These are for deployment into a Kubernetes cluster. Each repository contains a set of **Helm Charts** all of which will deploy into a single namespace in a single Kubernetes Cluster.
- **Local Machine** services repositories. These are for deployment to a local machine using docker-compose. Each repository contains a set *compose.yaml* files that describe how to deploy a set of services to the local machine. These could potentially be used for production at a facility which does not use Kubernetes, but are primarily for development, testing and the earlier tutorials in this documentation.

(edge-containers-cli)=
## edge-containers-cli

A Python command line tool for the developer that runs *outside* of containers. It provides simple features for and monitoring and managing and IOC instances within a [](services-repo).

So named 'edge' containers because these services all run close to the hardware. Uses the command line entry point `ec`. See {std:ref}`cli` for more details.

(ibek)=
## ibek
A Python command line tool that provides services *inside* of the Generic IOC container such as:

- building support modules at build time
- configuring global assets such as the RELEASE file at build time
- converting developer containers into light-weight runtime containers
- Generating startup assets for an IOC Instance from a set of yaml files at runtime.

Uses the command line entry point `ibek`.
