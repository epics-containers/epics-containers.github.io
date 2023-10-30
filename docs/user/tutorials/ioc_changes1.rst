Changing the IOC Instance
=========================

This tutorial will make a very simple change to the example IOC ``bl01t-ea-ioc-02``.
This is a type 1 change from `ioc_change_types`, types 2, 3 will be covered in the
following 2 tutorials.

Strictly speaking, Type 1 changes do not require a devcontainer. You created
and deployed the IOC instance a previous tutorial without one. It is up to
you how you choose to make these types of changes. Types 2,3 do require a
devcontainer because they involve compiling Generic IOC / support module code.

We are going to add a hand crafted EPICS DB file to the IOC instance. This will
be a simple record that we will be able to query to verify that the change
is working.

Make the following changes in your test IOC config folder
(``bl01t/iocs/bl01t-ea-ioc-02/config``):

1. Add a file called ``extra.db`` with the following contents.

   .. code-block:: text

      record(ai, "BL01T-EA-IOC-01:TEST") {
         field(DESC, "Test record")
         field(DTYP, "Soft Channel")
         field(SCAN, "Passive")
         field(VAL, "1")
      }

2. Add the following lines to the end ``ioc.yaml`` (verify that the indentation
   matches the above entry so that ``- type:`` statements line up):

   .. code-block:: yaml

      - type: epics.StartupCommand
        command: dbLoadRecords(config/extra.db)

Locally Testing Your changes
----------------------------

You can immediately test your changes by running the IOC locally. The following
command will run the IOC locally using the config files in your test IOC config
folder:

.. code-block:: bash

    # stop the first IOC shell by hitting Ctrl-D or typing exit
    cd /epics/ioc
    ./start.sh

If all is well you should see your iocShell prompt and the output should
show ``dbLoadRecords(config/extra.db)``.

Test your change
from another terminal (VSCode menus -> Terminal -> New Terminal) like so:

.. code-block:: bash

   caget $USER-EA-IOC-01:TEST

If you see the value 1 then your change is working.

.. Note::

    You are likely to see
    *"Identical process variable names on multiple servers"* warnings. This is
    because caget can see the PV on the host network and the container network,
    but as these are the same IOC this is not a problem.

    You can change this and make your devcontainer network isolated by removing
    the line ``"--net=host",`` from ``.devcontainer/devcontainer.json``, but
    it is convenient to leave it if you want to run OPI tools locally on the
    host. You may want to isolate your development network if multiple
    developers are working on the same subnet. In this case some other solution
    is required for running OPI tools on the host (TODO add link to solution).

Because of the symlink between ``/epics/ioc/config`` and
``/repos/bl01t/iocs/bl01t-ea-ioc-02/config`` the same files you are testing
by launching the ioc inside of the devcontainer are also ready to be
committed and pushed to the bl01t repo. i.e.:

.. code-block:: bash

    # Do this from the host terminal (not the devcontainer terminal)
    cd bl01t
    git add .
    git commit -m "Added extra.db"
    git push
    # tag a new version of the beamline repo
    git tag 2023.11.2
    git push origin 2023.11.2
    ec deploy bl01t-ea-ioc-02 2023.11.2

The above steps were performed on a host terminal because we are using ``ec``
but all of the previous steps could have been done *inside* the devcontainer
starting with ``cd /repos/bl01t``.

Raw Startup Assets
------------------

If you plan not to use `ibek` runtime asset creation you could use the raw
startup assets from the previous tutorial. If you do this then the process
above is identical except that you will add the ``dbLoadRecords`` command to
the end of ``st.cmd``.

More about ibek Runtime Asset Creation
--------------------------------------

The set of ``entities`` that you may create in your ioc.yaml is defined by the
``ibek`` IOC schema that we reference at the top of ``ioc.yaml``.
The schema is in turn defined by the set of support modules that were compiled
into the Generic IOC (ioc-adsimdetector). Each support module has an
``ibek`` *support YAML* file that contributes to the schema.

The *Support yaml* files are in the folder ``/epics/ibek``

