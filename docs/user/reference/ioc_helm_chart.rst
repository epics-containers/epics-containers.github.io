IOC Helm Chart Details
======================

IOC instances are described using a helm chart which in turn generates
a Kubernetes manifest to tell Kubernetes what resources to create in order
to run the IOC instance.

Here we will look inside the template IOC instance in the template
domain repository blxxi-template.

You can see these files in Github here:
https://github.com/epics-containers/blxxi-template/tree/main/iocs/blxxi-ea-ioc-01


Examine the Example IOC Instance
--------------------------------

Take a look in the folder iocs/blxxi-ea-ioc-01. This contains a helm chart
that defines the example IOC instance. To make new IOC instance you could
copy this folder into your own domain repository's iocs folder. You would then
need to rename it and make a few changes. Below is a description of the files
in this folder and what you would need to change in your new IOC instance:

-   ``Chart.yaml`` - this is the helm chart definition file. It contains
    metadata about the chart and a list of dependencies. Most of this file
    can be left as is for all IOC instances. But you do need to change these
    fields:

    - ``name`` - the unique name for the chart and the IOC instance it represents.
    - ``Description`` - a short description of the IOC instance.

-   ``values.yaml`` - this is the helm values file. It contains the values that
    are substituted in to the helm templates when the helm chart is built. Most
    of the values that go into an IOC instance chart will be drawn from
    domain defaults which can be found in the folder ``beamline-chart``. Values
    you need to supply here are:

    -   ``base_image`` - the Generic IOC image to use for this IOC instance. A
        Generic IOC image contains all the necessary support modules for a
        given class of device and a compiled IOC binary with all those modules
        linked. The IOC instance we are defining in a helm chart provides the startup
        script and possibly database that makes this IOC instance unique. In this
        case the Generic IOC is for the area-detector simulator device.

    -   ``prefix`` - the EPICS PV prefix for this IOC instance. This will set an
        environment variable IOC_PREFIX which declares the prefix for the IOC's
        devIOCStats records. You can leave this value out if you use the ioc
        name as the prefix, but in this case we have used an uppercase version of
        IOC name as the prefix.

-   ``templates/ioc.yaml`` this is the master template for this helm chart,
    it pulls in all the other templates from our dependencies. This file
    has to appear here but is boilerplate and should not need to be changed.

-   ``config`` this folder contains any files unique to this IOC instance. At
    runtime on the cluster when the Generic IOC image is running it will see
    these files as mounted into the folder ``/repos/epics/ioc/config``.
    In this case we have an EPICS startup script ``st.cmd`` only
    and the default behaviour is just to run the IOC binary and pass it
    ``st.cmd``.

    To see how the Generic IOC makes use of the config folder take a look
    at `this bash script`_ which runs on Generic IOC startup.

    If you want to have completely custom behaviour in your IOC instance,
    you can place a bash script called ``start.sh`` in the config folder
    this will run in place of the above script.


.. _this bash script:  https://github.com/epics-containers/ioc-template/blob/main/ioc/start.sh