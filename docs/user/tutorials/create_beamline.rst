.. _create_beamline:

Create a Beamline Repository
============================

In this tutorial we will create a new beamline source repository.

All IOC Instances that we deploy will be grouped into domains and each
domain will have its own repository which defines those Instances.
Typically each beamline would have its own domain and
the accelerator would be split into a few functional domains.

In the case of Beamlines, the domain is named after the beamline itself. At DLS
we use the naming convention ``blxxc`` where ``xx`` is the beamline number,
and c is the class of beamline.

.. note::

    You may choose your own naming convention, but lower case letters,
    numbers and hyphens only are recommended for both domain names and
    IOC names. This is a restriction that helm introduces for package names.

We are going to create the test beamline repository ``bl01t``.
When the project ``bl01t`` is pushed to GitHub, continuous integration will
verify that each of the IOCs in the beamline are valid by launching them
with basic configuration.

The tests on beamline repositories are basic at present. However the intention
is that eventually each device on a beamline will be simulated using
`Tickit <https://github.com/dls-controls/tickit>`_ . Then Continuous
Integration will perform system tests for each IOC against simulated hardware.

Also note that each of these IOC instances will be launched using a
Generic IOC image. Ideally the CI for each Generic IOC should have already run
system tests against simulated (but not beamline specific) hardware.

This beamline repo will be taken from a template that comes with a single example
IOC and further steps in the following tutorials will teach you how to add your own.

For accelerator domains the approach described here will be identical. The
only difference is that IOC repos are split by domain rather than by beamline.


To Start
--------

For this exercise you will require a github user account or organization in
which to place the new repo. If you do not have one then follow GitHub's
`instructions`_.

Log in to your account by going here https://github.com/login.

You will also need to setup ssh keys to authenticate to github from git. See
`about ssh`_.

.. _instructions: https://docs.github.com/en/get-started/signing-up-for-github/signing-up-for-a-new-github-account
.. _about ssh: https://docs.github.com/en/enterprise-server@3.0/github/authenticating-to-github/connecting-to-github-with-ssh/about-ssh


Create a New Repository
-----------------------

Here we will copy the beamline template repository and change it's name to bl01t.
We will then step through the changes that are required to make it your own.

NOTE: for these tutorials we will use your personal GitHub Account to
store everything we do, all source repositories and container images. For
production, each facility will need its own policy for where to store these
assets. See `../explanations/repositories`.

Steps
-----

#.  Go to the template repository here:
    https://github.com/epics-containers/blxxi-template. Click on the green
    button ``Use this template`` and follow the instructions to create a new
    repository in your own account and give it the name bl01t.

    If you are using an alternative to GitHub for your repositories then
    see `these instructions`_ for an alternative approach.

    .. _these instructions: https://github.com/epics-containers/blxxi-template#how-to-copy-this-template-project

#.  Clone the template repo locally (substituting in your own GitHub Account).

    .. code-block:: bash

        git clone git@github.com:**YOUR GITHUB ACCOUNT**/bl01t.git


#.  Open the project in vscode.

    .. code-block:: bash

        cd bl01t
        # DLS users make sure you have done: module load vscode
        code .

#.  Now make the necessary changes to the template to make the project your
    own. These changes will be covered in more detail in the remaining
    sections of this page.

    #. Replace README.md with your own README.md as you see fit.

    #. edit ``environment.sh``

    #. change the name of the example ioc from ``iocs/blxxi-ea-ioc-01`` to
       ``iocs/bl01t-ea-ioc-01``

    #. change the beamline name in the two bash scripts in the ``services``
       directory.

    #. add some meaningful configuration to the example IOCs config folder
       ``iocs/bl01t-ea-ioc-01/config/ioc.yaml``. We will do this in the
       next tutorial.

Environment.sh
~~~~~~~~~~~~~~

Environment.sh is a bash script that is sourced by a beamline user or developer
in order to setup their environment to work with the beamline.

The command line tool ``ec`` uses the environment configured by this script
to determine where to deploy IOCS and where to find container images etc.

For details of what goes in this file see `../reference/environment`.
For the purpose of this tutorial for ``bl01t`` you should have the following
in your environment.sh (make sure you insert your GitHub account name
where indicated):

- SECTION 1:

  - ``export EC_REGISTRY_MAPPING='github.com=ghcr.io'``
  - ``export EC_K8S_NAMESPACE=``
  - ``export EC_DOMAIN_REPO=git@github.com:**YOUR GITHUB ACCOUNT**/bl01t``

- SECTION 2:

  - The existing script code in blxxi-template is fine for this tutorial.
    It checks to see if ``ec`` is available and installs it into a
    virtual environment if not. It requires that you already have a
    virtual environment set up. See `python_setup` for details.

- SECTION 3:

  - We are not using Kubernetes for the first few tutorials so you can
    leave this section blank for now.

.. note::

    DLS Users: ``ec`` is already installed for you. So leave SECTION 2
    blank. See `ec` for details.

Change the IOC Name
~~~~~~~~~~~~~~~~~~~

The IOC name is
taken from the folder name under ``iocs``. In this case we want to change
``blxxi-ea-ioc-01`` to ``bl01t-ea-ioc-01``.

.. code:: bash

    cd iocs
    mv blxxi-ea-ioc-01 bl01t-ea-ioc-01

Change the Beamline Name in Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are two files in the ``services/`` directory that need to be changed. These
files are used to set up some beamline wide resources on each beamline domain.
At present they are only relevant to Kubernetes installations but we will change
then now so that bl01t is ready for Kubernetes when we get to that tutorial.

Open both files in ``services/`` and replace blxxi with bl01t.

TODO: add support for local docker installations of these services.

Wrapping Up
-----------

You should now have a working beamline repository. It contains a single
IOC Instance which is a non-functional example. In the following two
tutorials we will investigate the example and then create a real IOC Instance.

You can now push the repository up to GitHub and give it a version tag like this:

.. code:: bash

    git add .
    git commit -m "changed blxxi to bl01t"
    git push
    git tag 2023.11.1
    git push origin 2023.11.1


We use ``CalVer`` version numbers for beamline repositories and Generic IOCs.
This is a versioning scheme that uses the date of release as the version number.
The last digit is the number of the release in that month.

CalVer is described here: https://calver.org/ and is used where semantic
versioning is not appropriate because the repository contains a mix of
dependencies and does not have a clear API.

