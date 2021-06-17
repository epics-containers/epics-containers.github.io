Kubernetes Cluster Config
=========================

Cluster Options
---------------

Three cluster topology approaches were considered for this project.

- **Separate Kubernetes cluster per beamline**. This could be as simple as
  a single server and the K3S installation described in
  `setup_kubernetes` may be sufficient. The documentation at
  https://rancher.com/docs/k3s/ also details how to make a high availability
  cluster, requiring a minimum of 4 servers.

- **A Central Facility Cluster**. A central facility cluster that runs
  all IOCs on its own nodes would keep everything centralized and provide
  economy of scale. However, there are significant issues with routing
  Channel Access, PVA and some device protocols to IOCs running in a
  different subnet to the beamline. DLS spent some time working around these
  issues but eventually abandoned this approach.

- **Central Cluster with Beamline nodes**. This approach uses the central
  cluster but adds beamline nodes that sit in the beamline itself,
  connected to the beamline subnet. This has all the benefits of central
  management but is able to overcome the problems with protocol routing.
  The DLS argus cluster configuration described below is an example of
  how to achieve this.



DLS Argus Cluster
-----------------

**TODO** this section will give details of the topology and special
configuration used by the DLS argus cluster to enable running
IOCs on a Beamline.

Brief Overview of DLS Argus cluster
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Beamline Local Cluster Nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

hostNetwork = true
~~~~~~~~~~~~~~~~~~

Namespaces and Permissions
~~~~~~~~~~~~~~~~~~~~~~~~~~

Taints and Tolerances
~~~~~~~~~~~~~~~~~~~~~
