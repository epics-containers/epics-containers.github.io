RTEMS - Deploying an Example IOC
================================

The previous tutorials walked through how to create a generic linux soft
IOC and how to deploy an IOC instance using that generic IOC.

epics-containers also supports RTEMS 5 running on MVVME5500. We will
now will look at the differences for this architecture. Further
architectures will be supported in future.

Each beamline or accelerator domain will require a server for
serving the IOC binaries and instance files to the RTEMS devices. This
needs to be set up for your test beamline before proceeding,
see `rtems_setup`.

Once you have the file server set up, deploying an IOC instance that uses
an RTEMS Generic IOC is very similar to `deploy_example`.

We will be adding
a new IOC instance to the ``bl01t`` beamline that we created in the previous
tutorials. You will need to have worked through the previous tutorials in
order to complete this one.

Preparing the RTEMS Boot loader
-------------------------------

To try this tutorial you will need a VME crate with an MVVME5500 processor card
installed. You will also need access to the serial console over ethernet
using a terminal server or similar.

.. note::

    **DLS Users** for details of setting up RTEMS on your VME crates see
    this `internal link <https://confluence.diamond.ac.uk/pages/viewpage.action?spaceKey=CNTRLS&title=RTEMS>`_

    The following crate is already running RTEMS and can be used for this
    tutorial, but check with the accelerator controls team before using it:

    :console: ts0001 7007
    :crate monitor: ts0001 7008

    It is likely already set up as per the example below.

Use telnet to connect to the console of your target IOC. e.g.
``telnet ts0001 7007``. We want to get to the MOTLoad prompt which should look
like ``MVME5500>``. If you see an IOC Shell prompt instead hit ``Ctrl-D`` to
exit and then ``Esc`` when you see
``Boot Script - Press <ESC> to Bypass, <SPC> to Continue``

Now you want to set the boot script to load the IOC binary from the network via
TFTP and mount the instance files from the network via NFS. The command
``gevShow`` will show you the current state of the global environment variables.
e.g.

.. code-block::

    MVME5500> gevShow
    mot-/dev/enet0-cipa=172.23.250.15
    mot-/dev/enet0-snma=255.255.240.0
    mot-/dev/enet0-gipa=172.23.240.254
    mot-boot-device=/dev/em1
    rtems-client-name=bl01t-ea-ioc-02
    epics-script=172.23.168.203:/iocs:bl01t/bl01t-ea-ioc-02/config/st.cmd
    mot-script-boot
    dla=malloc 0x230000
    tftpGet -d/dev/enet1 -fbl01t/bl01t-ea-ioc-02/bin/RTEMS-beatnik/ioc.boot -m255.255.240.0 -g172.23.240.254 -s172.23.168.203 -c172.23.250.15 -adla
    go -a0095F000

    Total Number of GE Variables =7, Bytes Utilized =427, Bytes Free =3165

Now use ``gevEdit`` to change the global variables to the values you need.
For this tutorial we will create an IOC called bl01t-ea-ioc-02 and for the
example we assume the file server is on 172.23.168.203. For the details of
setting up these parameters see your site documentation but the important
values to change for this tutorial IOC would be:

:rtems-client-name: bl01t-ea-ioc-02
:epics-script: 172.23.168.203:/iocs:bl01t/bl01t-ea-ioc-02/config/st.cmd
:mot-script-boot (2nd line): tftpGet -d/dev/enet1 -fbl01t/bl01t-ea-ioc-02/bin/RTEMS-beatnik/ioc.boot -m255.255.240.0 -g172.23.240.254 -s172.23.168.203 -c172.23.250.15 -adla

Now your ``gevShow`` should look similar to the example above.

Meaning of the parameters:

:rtems-client-name: a name for the IOC crate
:epics-script: an NFS address for the IOC's root folder
:mot-script-boot: a TFTP address for the IOC's binary boot file

Note that the IP parameters to the tftpGet command are respectively:
net mask, gateway, server address, client address.


Creating an RTEMS IOC Instance
------------------------------

We will be adding a new IOC instance to the ``bl01t`` beamline that we created in
:doc:`create_beamline`. The first step is to make a copy of our existing IOC instance
and make some modifications to it. We will call this new IOC instance
``bl01t-ea-ioc-02``.

.. code-block:: bash

    cd bl01t
    cp -r iocs/bl01t-ea-ioc-01 iocs/bl01t-ea-ioc-02
    # don't need this file for the new IOC
    rm iocs/bl01t-ea-ioc-02/config/extra.db

We are going to make a very basic IOC with some hand coded database with
a couple of simple records. Therefore the generic IOC that we use can just
be ioc-template.

Generic IOCs have multiple targets, they always have a
``developer`` target which is used for building and debugging the generic IOC and
a ``runtime`` target which is lightweight and usually used when running the IOC
in the cluster. The matrix of targets also includes an architecture dimension,
at present the ioc-template supports two architectures, ``linux`` and
``rtems``, thus there are 4 targets in total as follows:

- ghcr.io/epics-containers/ioc-template-linux-runtime
- ghcr.io/epics-containers/ioc-template-linux-developer
- ghcr.io/epics-containers/ioc-template-rtems-runtime
- ghcr.io/epics-containers/ioc-template-rtems-developer

We want to run the RTEMS runtime target on the cluster so this will appear
at the top of the ``values.yaml`` file. In addition there are a number of
environment variables required for the RTEMS target that we also specify in
``values.yaml``.
Edit the file
``iocs/bl01t-ea-ioc-02/values.yaml`` to look like this:

.. code-block:: yaml

    base_image: ghcr.io/epics-containers/ioc-template-rtems-runtime:23.4.2

    env:
    # This is used to set EPICS_IOC_ADDR_LIST in the liveness probe client
    # It is only needed if auto addr list discovery would fail
    - name: K8S_IOC_ADDRESS
        value: 172.23.250.15

    # RTEMS console connection details
    - name: RTEMS_VME_CONSOLE_ADDR
        value: ts0001.cs.diamond.ac.uk
    - name: RTEMS_VME_CONSOLE_PORT
        value: "7007"
    - name: RTEMS_VME_AUTO_REBOOT
        value: true
    - name: RTEMS_VME_AUTO_PAUSE
        value: true

If you are not at DLS you will need to change the above to match the
parameters of your RTEMS Crate. The environment variables are:


.. list-table:: RTEMS Environment Variables
    :widths: 30 70
    :header-rows: 1

    * - Variable
      - Description
    * - K8S_IOC_ADDRESS
      - The IP address of the IOC (mot-/dev/enet0-cipa above)
    * - RTEMS_VME_CONSOLE_ADDR
      - Address of terminal server for console access
    * - RTEMS_VME_CONSOLE_PORT
      - Port of terminal server for console access
    * - RTEMS_VME_AUTO_REBOOT
      - true to reboot the hard IOC when the IOC container changes
    * - RTEMS_VME_AUTO_PAUSE
      - true to pause/unpause when the IOC container stops/starts

Edit the file ``iocs/bl01t-ea-ioc-02/Chart.yaml`` and change the 1st 4 lines
to represent this new IOC (the rest of the file is boilerplate):

.. code-block:: yaml

    apiVersion: v2
    name: bl01t-ea-ioc-02
    description: |
        example RTEMS IOC for bl01t

For configuration we will create a simple database with a few of records and
a basic startup script. Add the following files to the
``iocs/bl01t-ea-ioc-02/config`` directory.

.. code-block::  :caption: bl01t-ea-ioc-02.db

    record(calc, "bl01t-ea-ioc-02:SUM") {
        field(DESC, "Sum A and B")
        field(CALC, "A+B")
        field(SCAN, ".1 second")
        field(INPA, "bl01t-ea-ioc-02:A")
        field(INPB, "bl01t-ea-ioc-02:B")
    }

    record(ao, "bl01t-ea-ioc-02:A") {
        field(DESC, "A voltage")
        field(EGU,  "Volts")
        field(VAL,  "0.0")
    }

    record(ao, "bl01t-ea-ioc-02:B") {
        field(DESC, "B voltage")
        field(EGU,  "Volts")
        field(VAL,  "0.0")
    }

.. code-block::  :caption: st.cmd

    # RTEMS Test IOC bl01t-ea-ioc-02

    dbLoadDatabase "/iocs/bl01t/bl01t-ea-ioc-02/dbd/ioc.dbd"
    ioc_registerRecordDeviceDriver(pdbbase)

    # db files from the support modules are all held in this folder
    epicsEnvSet(EPICS_DB_INCLUDE_PATH, "/iocs/bl01t/bl01t-ea-ioc-02/support/db")

    # load our hand crafted database
    dbLoadRecords("/iocs/bl01t/bl01t-ea-ioc-02/config/bl01t-ea-ioc-02.db")
    # also make Database records for DEVIOCSTATS
    dbLoadRecords(iocAdminSoft.db, "IOC=bl01t-ea-ioc-02")
    dbLoadRecords(iocAdminScanMon.db, "IOC=bl01t-ea-ioc-02")

    iocInit

You now have a new helm chart in iocs/bl01t-ea-ioc-02 that describes an IOC
instance for your RTEMS device. Recall that this is not literally where the IOC
runs, it deploys a kubernetes pod that manages the RTEMS IOC. It does contain
the IOC's configuration and the IOC's binary code, which it will copy to the
file-server on startup.

Finally you will need to tell the IOC to mount the Persistent Volume Claim
that the bl01t-ioc-files service is serving over NFS and TFTP. To do this
add the following lines to ``iocs/bl01t-ea-ioc-02/values.yaml``:

.. code-block:: yaml

    # for RTEMS IOCS this is the PVC name for the filesystem where RTEMS
    # IOCs look for their files - enable this in RTEMS IOCs only
    nfsv2TftpClaim: bl01t-ioc-files-claim

You are now ready to deploy the IOC instance to the cluster and test it out.


Deploying an RTEMS IOC Instance
-------------------------------

To deploy an IOC instance to the cluster you can use one of two approaches:

- push your beamline repo to GitHub and tag it. Then use ``ec ioc deploy`` to
  deploy the resulting versioned IOC instance. This was covered for linux IOCs
  in `deploy_example`.

- use ``ec ioc deploy-local`` to directly deploy the local copy of the IOC
  instance helm chart to kubernetes as a beta version. This was covered for
  linux IOCs in `local_deploy_ioc`.

Both types of deployment of IOC instances above work exactly the same for
linux and RTEMS IOCs. We will do the latter as it is quicker for
the purposes of the tutorial.

Execute the following commands:

.. code-block:: bash

    cd bl01t
    ec ioc deploy-local iocs/bl01t-ea-ioc-02

When an RTEMS Kubernetes pod runs up it will make a telnet connection to
the hard IOC's console and present the console as stdin/stdout of the
container. This means once you have done the above deployment the command:


.. code-block:: bash

    ec logs bl01t-ea-ioc-02 -f

will show the RTEMS console output, and follow it along (``-f``) as the IOC
starts up. You can hit ``^C`` to stop following the logs.

You can also attach to the container and interact with the RTEMS console via
the telnet connection with:

.. code-block:: bash

    ec attach bl01t-ea-ioc-02

Most likely for the first deploy your IOC will still be sitting at the
``MVME5500>`` prompt. If you see this prompt when you attach then you need
to type ``reset`` to restart the boot-loader. This should then go through
the boot-loader startup and eventually start the IOC.

Checking your RTEMS IOC
-----------------------

To verify that your RTEMS IOC is working you should be able to execute the
following commands and get correct sum of the A and B values:

.. code-block:: bash

    caput bl01t-ea-ioc-02:A 12
    caput get bl01t-ea-ioc-02:B 13
    caget get bl01t-ea-ioc-02:SUM
