RTEMS - Deploying an Example IOC
================================

The previous tutorials walked through how to create a generic linux soft
IOC and how to deploy an IOC instance using that generic IOC.

epics-containers also supports RTEMS 5 running on MVVME5500. We will
now will look at the differences for this architecture. Further
architectures will be supported in future.

Each beamline or accelerator domain will require a server for
serving the IOC binaries and instance files. For details of how to set this
up see `rtems_setup`.

Once you have the file server set up, deploying an IOC instance that uses
an RTEMS Generic IOC is very similar to `deploy_example`.

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

Once you have the correct configuration you can restart the IOC with
the ``reset`` command. But you need the kubernetes pod for this IOC to be
up and running first so that it places the necessary files on the file server.
See the next section for setting up the kubernetes pod.


Creating an RTEMS Generic IOC
-----------------------------

Deploying an RTEMS IOC Instance
-------------------------------