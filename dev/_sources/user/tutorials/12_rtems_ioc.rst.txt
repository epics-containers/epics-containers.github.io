RTEMS - Deploying an IOC
========================

The previous tutorials walked through how to create a generic linux soft
IOC and how to deploy an IOC instance using that generic IOC.

epics-containers also supports RTEMS 5 running on MVVME5500. This
tutorial will look at the differences for this architecture. Further
architectures will be supported in future.

Note that each beamline or accelerator domain will require a server for
serving up the IOC binaries and instance files. For details of how to set this
up see `11_rtems_setup`.

Once you have the file server set up, creating an RTEMS Generic IOC is very
similar to `07_generic_ioc`. The main difference is that the binary is
cross compiled using the RTEMS toolchain. Deploying an IOC instance that uses
an RTEMS Generic IOC is also very similar to `05_deploy_example`.

Creating an RTEMS Generic IOC
-----------------------------

Deploying an RTEMS IOC Instance
-------------------------------