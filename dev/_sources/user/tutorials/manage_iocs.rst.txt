Manage IOCs
===========

IOCs running in Kubernetes can be managed using the kubectl command.

The script kube-functions.sh that we used in `deploy_example` provides some
shortcuts for common operations. Look inside the script to learn the
underlying kubectl commands being used.

Starting and Stopping IOCs
--------------------------

To stop / start  the example IOC::

    k8s-ioc stop example
    k8s-ioc start example

Monitoring and interacting with an IOC shell
--------------------------------------------

To attach to the ioc shell::

    k8s-ioc attach example

Use the command sequence ^P^Q to detach or ^D to detach and restart the IOC.

To run a bash shell inside the IOC container::

    k8s-ioc exec example

This is a minimal ubuntu distribution. To get access to useful utility commands
use the following::

    busybox sh
    busybox  # shows the set of commands now available

Also note that the following folders may be of interest:

=============== ==============================================================
ioc code        /epics/ioc
support modules /epics/support
epics binaries  /epics/epics-base
=============== ==============================================================


Logging
-------

To get the current logs for the example IOC::

    k8s-ioc log example

Or stream the IOC log until you hit ^C::

    k8s-ioc log example -f

Monitor your beamline IOCs::

    k8s-ioc monitor blxxi

Note that the beamline is called blxxi rather than bl01t. To change the
beamline name that your IOC deploys to you would need to edit
bl01t/iocs/example/values.yaml, push the changes and execute deploy again.
See `../how-to/add_ioc` for more details on values.yaml.




