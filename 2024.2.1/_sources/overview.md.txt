**epics-containers** applies modern industry best practice for software
delivery to the management of EPICS IOCs.

There are 5 themes to this strategy:

```{eval-rst}

:Kubernetes:
  Centrally orchestrates all IOCs at a facility.

:Helm Charts:
  Deploy IOCs into Kubernetes with version management.

:Repositories:
  Source, container and helm repositories manage all of the above assets.
  No shared file systems required.

:Continuous Integration / Delivery:
  Source repositories automatically build containers and helm charts
  delivering them to OCI registries.
```
