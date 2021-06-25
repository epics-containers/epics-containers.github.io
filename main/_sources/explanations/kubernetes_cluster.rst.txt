Kubernetes Cluster Config
=========================

Cluster Options
---------------

Three cluster topology approaches were considered for this project.

:Cluster per beamline:
  This could be as simple as
  a single server: the K3S installation described in
  `setup_kubernetes` may be sufficient. The documentation at
  https://rancher.com/docs/k3s/ also details how to make a high availability
  cluster, requiring a minimum of 4 servers.
  This approach keeps the configuration of the clusters quite straightforward
  but at the cost of having multiple separate clusters to maintain. Also
  it requires control plane servers for every beamline, whereas a centralized
  approach would only need a handful of control plane servers for the entire
  facility.

:Central Facility Cluster:
  A central facility cluster that runs
  all IOCs on its own nodes would keep everything centralized and provide
  economy of scale. However, there are significant issues with routing
  Channel Access, PVA and some device protocols to IOCs running in a
  different subnet to the beamline. DLS spent some time working around these
  issues but eventually abandoned this approach.

:Beamline Worker Nodes:
  This approach uses the central
  cluster but adds remote beamline nodes located in the beamline itself,
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
