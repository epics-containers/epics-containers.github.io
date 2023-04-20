RTEMS - Creating a File Server
==============================

Introduction
------------

RTEMS IOCs are an example of a 'hard' IOC. Each IOC is a physical crate that
contains a number of I/O cards and a processor card.

For these types of
IOC, the Kubernetes cluster runs a pod that represents the individual IOC.
However, the IOC code itself runs on the processor card instead of the pod.
The pod provides the following features:

- Sets up the files to serve to the RTEMS OS
- Provides a connection to the IOC console just like a linux IOC
- Pauses, unpauses, restarts the IOC as necessary - thus the IOC is controlled
  by the Kubernetes cluster in the same way as a linux IOC
- Provides logging of the IOC console in the same way as linux IOCs
- Monitors the IOC and restarts it if it crashes - using the same mechanism
  as linux IOCs

At present epics-containers supports the MVVME5500 processor card running
RTEMS 5. The same model as described above can be used for other 'hard' IOC
types in future.

Create a File Server Service
----------------------------

When an RTEMS 5 IOC boots the bootloader loads the IOC binary from a TFTP
address, this binary is then given access to a filesystem over NFS V2, this is
where the IOC startup script and other configuration is loaded.

Therefore we need a TFTP server and an NFS V2 server to serve the files to
the IOC. For each EPICS domain a single service running in Kubernetes will
supply a TFTP and NFS V2 server for all the IOCs in that domain.

In the tutorial :doc:`create_beamline` we created a beamline repository that
defines the IOC instances in the beamline ``bl01t``. The template project
that we copied contains a folder called ``services/nfsv2-tftp``. The folder
is a helm chart that will deploy a TFTP and NFS V2 server to Kubernetes.

Before deploying the service we need to configure it. Make the following
changes:

- Change the ``name`` value in ``Chart.yaml`` to ``bl01t-ioc-files``
- Change the ``loadBalancerIP`` value in ``values.yaml`` to a free IP address
  in your cluster's Static Load Balancer range. This IP address will be used
  to access the TFTP and NFS V2 servers from the IOC.

.. note::

  **DLS Users** The load balancer IP range on Pollux is
  ``172.23.168.201-172.23.168.222``. Please use ``172.23.168.203``. The test
  RTEMS crate is likely to already be set up to point at this address. There
  are a limited number of addresses available, hence we have reserved a single
  address for the training purposes.

  Also note that ``bl01t`` is a shared resource so if there is already a
  ``bl01t-ioc-files`` service running then you could just use the existing
  service.

You can verify if the service is already running using kubectl. The command
shown below will list all the services in the ``bl01t`` namespace, and the
example output shows that there is already a ``bl01t-ioc-files`` service
using the IP address ``172.23.168.203``.

.. code-block:: bash

  $ kubectl get services -n bl01t
  NAME                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                                                        AGE
  bl01t-ioc-files     LoadBalancer   10.108.219.193   172.23.168.203   111:31491/UDP,2049:30944/UDP,20048:32277/UDP,69:32740/UDP                      32d

Once you have made the changes to the helm chart you can deploy it to the
cluster using the following command:

.. code-block:: bash

  cd bl01t
  helm upgrade --install bl01t-ioc-files services/nfsv2-tftp -n bl01t

Now if you run the ``kubectl get services`` command again you should see the
new service.

Once you have this service up and running you can leave it alone. It will
serve the files to the IOCs using the IP address you configured over both
TFTP and NFS V2. It uses a persistent volume to store the files and this
persistent volume is shared with hard IOC pods so that they can place the
files they need to serve to the IOC.

See the next tutorial for how to deploy a hard IOC pod to the cluster.



