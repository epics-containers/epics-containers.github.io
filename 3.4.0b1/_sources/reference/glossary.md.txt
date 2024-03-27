
# Glossary

(ec-services-repo)=
## ec-services repository

A repository that contains the definitions for a group of IOC and service instances that are deployed in a Kubernetes cluster. The grouping of instances is up to the facility. At DLS the instances are grouped by beamline for beamline IOCs. Accelerator IOC groupings are by location or by technical domain as appropriate.

(edge-containers-cli)=
## edge-containers-cli

A Python command line tool for the developer that runs *outside* of containers. It provides features for deploying and managing service and IOC instances within an [](ec-services-repo).

So named 'edge' containers because these services all run close to the hardware. Uses the command line entry point `ec`.

(ibek)=
## ibek
A Python command line tool that provides services *inside* of the Generic IOC container such as:

- building support modules at build time
- configuring global assets such as the RELEASE file at build time
- converting developer containers into light-weight runtime containers
- Generating startup assets for an IOC Instance from a set of yaml files at runtime.

Uses the command line entry point `ibek`.
