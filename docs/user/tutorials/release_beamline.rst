

Make a Release of Example Beamline bl01t
----------------------------------------

.. Warning ::

    This information is out of date. It will be updated soon.

To make a release of the project we defined in `deploy_example`,
we will
tag your repo with a calendar based version number see (https://calver.org/).

We use YY.MM.MINOR for versioning things like beamlines and Generic IOCs. You
can choose your own scheme, but because these projects do not have APIs as
such it is more instructive to use a date based scheme.

The example version below was the first revision in the month of April 2023.

.. code-block:: bash

    cd bl01t
    git tag 23.4.1
    # push the tag
    git push origin 23.4.1

This will cause GitHub to create a release of the project and trigger
continuous integration. The continuous integration will look at all of
the IOCs in the beamline and generate helm charts for each one. If the helm
chart has changed since the last release then a new version of the helm chart
is delivered to your GitHub account's OCI registry.

To watch the progress go to the Actions Panel for your project at
https://github.com/<YOUR USER NAME>/bl01t/actions

.. figure:: ../images/github_actions.png

Once the CI completes you should have a helm chart delivered in your project
OCI registry. You can see this listed in project 'packages'.
Look for a link to the package on the right hand side of your
project page.

Go to the code pane and click on the example package circled below to see it.

.. figure:: ../images/github_package.png

The OCI registry name of the helm chart will be
ghcr.io/<YOUR USER NAME>/bl01t/bl01t-ea-ioc-01:23.4.1.

You have now completed this tutorial. Here you have created a new beamline
repository and made a release of it. The release includes the example IOCs
instance called ``bl01t-ea-ioc-01``. This IOC has had a helm chart generated
for it and published ready for deployment to your cluster.

In the next tutorial we will look into what we have created in more detail
and we will deploy and test the new example IOC.

For details of what goes into the helm chart of an IOC instance see
`../reference/ioc_helm_chart`.
