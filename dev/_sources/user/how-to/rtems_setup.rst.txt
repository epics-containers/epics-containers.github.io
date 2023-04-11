RTEMS - Creating a File Server
==============================

RTEMS IOCs are an example of an 'hard' IOC. Each IOC is a crate that contains
a number of I/O cards and a processor card.

For these types of
IOC the Kubernetes cluster runs a pod that represents the individual IOC,
but the IOC code actually runs on the processor card instead of the pod.
Instead, the pod provides the following services:

- Sets up the files to serve to the RTEMS OS
- Provides a connection to the IOC console just like a linux IOC
- Pauses, unpauses, restarts the IOC as necessary - thus the IOC is controlled
  by the Kubernetes cluster in the same way as a linux IOC
- Provides logging of the IOC console in the same way as linux IOCs
- Monitors the IOC and restarts it if it crashes - using the same mechanism
  as linux IOCs