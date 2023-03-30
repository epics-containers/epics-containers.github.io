Working with Generic IOCs
=========================

In this tutorial we will learn how to create a generic IOC container image and
test our changes locally before deploying it.

The example IOC used a ADSimDetector, we will make a similar IOC that uses a
ADUrl to get images from a web cam.

Create a New Generic IOC project
--------------------------------

Much like creating a new beamline we have a template project that can be used
as the starting point for a new generic IOC. Again we will create this in
your personal GitHub user space.

TODO: the following steps to create a new generic IOC project will be automated
using an ``ec`` command.

#.  Create a new, completely blank repository in your GitHub account
    called ``ioc-adurl``. To do this got to https://github.com/new
    and fill in the details as per the image below. Click
    ``Create repository``.

#.  Clone the template repo locally and rename from ioc-template to ioc-adurl

    .. code-block:: bash

        git clone git@github.com:epics-containers/ioc-template.git
        mv ioc-template ioc-adurl
        cd ioc-adurl

#.  Add your new repo to your VSCode workspace and take a look at what you
    have.

    From the VSCode menus: File->Add Folder to Workspace
    then select the folder ioc-adurl

#.  Push the new repo back to a the new repo on github

    .. code-block:: bash

        git remote rm origin
        git remote add origin git@github.com:<YOUR USER NAME>/ioc-adurl.git
        git push origin main

Configure the ibek-defs Submodule
---------------------------------

The ``ibek-defs`` submodule is used to share information about how to build
support modules. It contains two kinds of files:

#.  Patch Files: these are used to update a support module so that it will
    build correctly in the container environment. These should typically only
    add one or both of these files:

    - configure/RELEASE.local
    - configure/CONFIG_SITE.linux-x86_64.Common

#.  IBEK support module definitions: These are used to help IOCs build their
    iocShell boot scripts from YAML descriptions. They are not used in this
    tutorial as we are supplying a hand crafted boot script. For information
    on IBEK see https://github.com/epics-containers/ibek.

ibek-defs is curated for security reasons, therefore we need to work with
a fork of it so we can add our own definitions for ADUrl. If you make changes
to ibek-defs that are generally useful you can use a pull request to get them
merged into the main repo.

Perform the following steps to create a fork and update the submodule:

- goto https://github.com/epics-containers/ibek-defs/fork
- uncheck ``Copy the main branch only``
- click ``Create Fork``
- click on ``<> Code`` and COPY the ssh URL
- cd to the ioc-adurl directory
-
  .. code-block:: bash

        git submodule set-url ibek-defs <PASTE URL HERE>
        git submodule init
        git submodule update
        cd ibek-defs
        git checkout tutorial
        cd ..

We are using the tutorial branch which has a snapshot of the ibek-defs state
appropriate for this tutorial.

The git submodule allows us to share the ibek-defs definitions between all
ioc-XXX projects but also allows each project to have its copy fixed to
a particular commit (until updated with ``git pull``).


.. git submodule init
.. git submodule update
.. cd ibek ibek-defs TODO - do they need a fork of this??
.. checkout main
.. push --set-upstream origin main
.. mkdir adurl

.. ec dev build


.. copy steps from ADSimDetector
.. copy makefile from ADSimDetector/ioc/iocApp/Makefile

.. Update this but discuss how we could have changed ADSupport to build GraphicsMagick
.. configure/CONFIG_SITE.linux-x86_64.Common
..     WITH_GRAPHICSMAGICK = YES
..     GRAPHICSMAGICK_INCLUDE=/usr/include/GraphicsMagick

..     # THIS COULD GO INTO ADSUPPORT AND THEN WE DONT NEED INCLUDE OR apt-install
..     # GRAPHICSMAGICK_EXTERNAL = NO

.. apt update
.. apt install apt-file
.. apt-file find Magick++.h
.. add boost lib apt install
.. AND libgraphicsmagick++1-dev
.. change last step to adurl from ADSimDetector
.. cp ibek-defs/adcore/adcore.sh ibek-defs/adurl/adurl.sh


.. Once running:-
.. caput -S BL01T-EA-TST-02:CAM:URL1
