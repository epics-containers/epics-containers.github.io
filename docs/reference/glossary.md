
# Glossary

(ec-services-repo)=
## ec-services repository

A repository that contains the definitions for a group of IOC and service instances that are deployed in a Kubernetes cluster. The grouping of instances is up to the facility. At DLS the instances are grouped by beamline, accelerator groupings are by location or by technical domain as appropriate.

(edge-containers-cli)=
## edge-containers-cli

A command line tool for deploying and managing service and IOC instances within an [](ec-services-repo). So named 'edge' containers because these services all run close to the hardware. Historically this tool was called epics containers cli and both versions use the command line entry point ``ec``.
