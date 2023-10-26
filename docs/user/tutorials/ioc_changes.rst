Testing Changes to IOC Instances
================================

.. Warning::

    This tutorial is out of date and will be updated soon.

.. _ioc_change_types:

Types of Changes
----------------

Containerized IOCs can be modified in 3 distinct places:

#. The IOC instance: this means making changes to the IOC instance helm chart
   which appears in the ``iocs`` folder of a beamline or accelerator domain
   source repository. This includes things like:

   - changing the EPICS DB (or files that generate it)
   - altering the iocShell boot script (or files that generate it)
   - changing parameters in the values file for the chart - e.g. increasing
     the memory limit for the IOC container

#. The Generic IOC - alter the details of how the Generic IOC container image
   is built. This means making changes to an ``ioc-XXX`` source repo and
   publishing a new version of the Generic IOC container image.
   This includes things like:

   - changing the EPICS base version
   - changing the versions of EPICS support modules compiled into the IOC binary
   - adding new support modules
   - altering the system dependencies installed into the container image

#. The dependencies - Support modules used by the Generic IOC. Changes to support
   module repos. This means publishing a new release of the support module.

As far as possible the epics-containers approach to all of the above allows
local testing of the changes before publishing. This allows us to have a
fast 'inner loop' of development and testing.

Also, epics-containers provides a mechanism for creating a separate workspace for
working on all of the above elements in one place.

Changing the IOC Instance
-------------------------

This tutorial will make a very simple change to the example IOC ``bl01t-ea-ioc-01``.
This is a type 1. change from the above list, types 2, 3 will be covered in the
following 2 tutorials.

We are going to add a hand crafted EPICS DB file to the IOC instance. This will
be a simple record that we will be able to query to verify that the change
is working.

Make the following changes in your test IOC config folder
(``bl01t/iocs/bl01t-ea-ioc-01/config``):

1. Add a file called ``extra.db`` with the following contents.
   IMPORTANT replace [$USER] with your username:

   .. code-block:: text

      record(ai, "[$USER]-EA-IOC-01:TEST") {
         field(DESC, "Test record")
         field(DTYP, "Soft Channel")
         field(SCAN, "Passive")
         field(VAL, "1")
      }

2. Add the following line to the ``st.cmd`` file after the last ``dbLoadRecords``
   line:

   .. code-block:: text

      dbLoadRecords(config/extra.db)

Locally Testing Your changes
----------------------------

You can immediately test your changes by running the IOC locally. The following
command will run the IOC locally using the config files in your test IOC config
folder:

.. code-block:: bash

    ec dev ioc-launch iocs/bl01t-ea-ioc-01

This will launch Generic IOC container specified in the ``bl01t-ea-ioc-01``
helm chart and mount into it the local config specified in
``/iocs/bl01t-ea-ioc-01/config``.

If all is well you should see your iocShell prompt and you can test your change
from another terminal (VSCode menus -> Terminal -> New Terminal) like so:

.. code-block:: bash

   caget $USER-EA-IOC-01:TEST

If you see the value 1 then your change is working.

.. note::

   If you also wanted to make local changes
   to the Generic IOC itself you could clone the Generic IOC source repo,
   locally build the container image and then use ``ec dev ioc-launch`` as
   follows:

   .. code-block:: bash

      # advanced example - not part of this tutorial
      cd <root of your workspace>
      git clone git@github.com:epics-containers/ioc-adsimdetector.git
      cd ioc-adsimdetector
      # this makes a local image with tag :local
      ec dev build
      cd ../bl01t
      ec dev ioc-launch iocs/bl01t-ea-ioc-01 ../ioc-adsimdetector


Note you can see your running IOC in podman using this command:

.. code-block:: bash

    podman ps

You should see a container named bl01t-ea-ioc-01 and also a another one with a
random name and an image called ``localhost/vsc-work...``. The latter is the
container that is running your developer environment.

If you would like to take a look inside the container you can run a bash shell
in the container like this:

.. code-block:: bash

    podman exec -it bl01t-ea-ioc-01 bash

When you type exit on the iocShell the container will stop and and be removed.

.. _local_deploy_ioc:

Deploying a Beta IOC Instance to The Cluster
============================================

In ``05_deploy_example`` we deployed a tagged version of the IOC instance to
the cluster. This the correct way to deploy a production IOC instance as it
means there is a record of version of the IOC instance in the Helm Chart
OCI registry and you can always roll back to that version if needed.

However, it is also possible to directly deploy a version of the IOC instance
from your local machine to the cluster.
This is useful for testing changes to the IOC instance
before publishing a new version. In this case
your IOC will be given a beta tag in the cluster, indicating that it has
not yet been released.

To deploy your changes direct to the cluster use the following command:

.. code-block:: bash

    ec ioc deploy-local iocs/bl01t-ea-ioc-01

You will get a warning that this is a temporary deployment and you will see that
the version number will look something like ``2023.3.29-b14.29`` this
indicates that this is a beta deployment made at 14:29 on 29th March 2023.

Now when you ask for the IOCs running in your domain you should see your IOC
with beta version listed:

.. code-block:: bash

   $ ec ps -w
   POD                                VERSION            STATE     RESTARTS   STARTED                IP             GENERIC_IOC_IMAGE
   bl01t-ea-ioc-01-7d7c5bc759-5bjsr   2023.3.29-b14.29   Running   0          2023-03-29T14:29:18Z   192.168.0.32   ghcr.io/epics-containers/ioc-adsimdetector-linux-runtime:23.3.4

You can check it is working as before (replace the IP with yours
from the above command):

.. code-block:: bash

    export EPICS_CA_ADDR_LIST=192.168.0.32
    caget $USER-EA-IOC-01:TEST

Once you are happy with your changes you can push and tag your beamline repo.
This will publish a new version of the IOC instance helm chart to the OCI helm
registry. You can then deploy the versioned IOC instance to the cluster.




