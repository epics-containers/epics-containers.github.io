Create a Working Example IOC Instance
=====================================

Introduction
------------

The last section covered deploying and managing the example Instance that
came with the template beamline repository. Here we will create a new
IOC Instance that implements a simulated detector.

Create a New IOC Instance
-------------------------

To create a new IOC Instance simply add a new folder to the ``iocs`` folder
in your beamline repo. The name of the folder will be the name of the IOC.
This folder needs to contain these two items:

:values.yaml: a file that specifies which Generic IOC Image your IOC Instance
    will run inside of.

:config: a folder that contains the IOC configuration files. The configuration
    can take a number of forms, and these were listed inside of the example
    IOC from the previous Tutorial.
    `Click this link to review the options <https://github.com/epics-containers/ibek/blob/ea9da7e1cfe88f2a300ad236f820221837dd9dcf/src/ibek/templates/ioc/config/start.sh>`_

 We will start by creating the values.yaml file:

.. code-block:: bash

    cd bl01t
    mkdir iocs/bl01t-ea-ioc-02
    code values.yaml

This should launch vscode and open the values.yaml file. Add the following:

.. code-block:: yaml

    image: ghcr.io/epics-containers/ioc-adsimdetector-linux-runtime:2023.10.5

This tells the IOC Instance to run in the ``ioc-adsimdetector-linux-runtime``
container. This container was built by the Generic IOC source repo here
https://github.com/epics-containers/ioc-adsimdetector. The container has
support for AreaDetector and ADSimDetector compiled into its IOC binary.

Generic IOCs have compiled IOC binaries and `dbd` files but no startup script or
EPICS database files. These are baked into the container at container build
time.

Startup and Database are provided by the IOC Instance at container run time.
This is what makes a unique IOC Instance from a Generic IOC container.

Therefore we need to create a startup and EPICS Database to make this into
a functional IOC Instance. To do that we will use the ``ibek`` tool. To
recap, we have two python CLI tools for supporting epics-containers:

:ibek: runs *inside* the Generic IOC containers and provides commands for:
    - Fetching and compiling support modules at build time
    - Other build time utilities such as creating and compiling IOC source and
      extracting runtime assets for the runtime container target.
    - Generating startup scripts and EPICS databases at container runtime
      from IOC yaml files

:ec: provides developer support *outside* of the container such as:
    - Deploying, managing and debugging IOC Instances
    - Building and debugging Generic IOC containers

``ibek`` is already installed inside of the Generic IOC container we selected
above. So now we will provide some IOC yaml files to ``ibek`` so that it
will generate startup assets for our IOC Instance.

Create IOC YAML Files
---------------------

IOC yaml files are a sequence of ``entities``. Each entity is a dictionary

TODO continue: show how Support YAML works and show how IOCs publish schema etc.











.. figure:: ../images/c2dv.png

    the c2dv viewer showing an image from the example IOC