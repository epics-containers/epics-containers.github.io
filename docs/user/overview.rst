**epics-containers** applies modern industry best practice for software
delivery to the management of EPICS IOCs.

There are 5 themes to this strategy:

:Containers:
  Package IOC software and execute it in a lightweight virtual environment.

:Kubernetes:
  Centrally orchestrate all IOCs at a facility.

:Helm Charts:
  Deploy IOCs into Kubernetes with version management.

:Repositories:
  Source, container and helm repositories manage all of the above assets.
  No shared file systems required.

:Continuous Integration / Delivery:
  Source repositories automatically build container and helm charts
  delivering them to OCI registries.
