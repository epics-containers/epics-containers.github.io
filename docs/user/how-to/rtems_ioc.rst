RTEMS - Deploying an IOC
========================

The tutorials walked through how to create a generic linux soft IOC and how
to deploy an IOC instance using that generic IOC.

epics-containers also supports RTEMS 5 running on MVVME5500. This
tutorial will look at the differences for this architecture. Further
architectures will be supported in future.

Note that each beamline or accelerator domain will require a server for
serving up the IOC binaries and instance files. For details of how to set this
up see `rtems_setup`.

