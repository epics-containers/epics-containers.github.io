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
using and ``ec`` command.

#.  Create a new, completely blank repository in your GitHub account
    called ``ioc-adurldetector``. To do this got to https://github.com/new
    and fill in the details as per the image below. Click
    ``Create repository``.

#.  Clone the template repo locally and rename from ioc-template to ioc-adurldetector

    .. code-block:: bash

        git clone git@github.com:epics-containers/ioc-template.git
        mv ioc-template ioc-adurldetector
        cd ioc-adurldetector

#.  Add your new repo to your VSCode workspace and take a look at what you
    have.

    From the VSCode menus: File->Add Folder to Workspace
    then select the folder ioc-adurldetector

#.  Push the new repo back to a the new repo on github

    .. code-block:: bash

        git remote rm origin
        git remote add origin git@github.com:<YOUR USER NAME>/ioc-adurldetector.git
        git push origin main