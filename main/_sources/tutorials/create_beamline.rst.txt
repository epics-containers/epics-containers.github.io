Create a beamline repository
============================

In this tutorial we will create a new beamline source repository on github.

This is where the definitions of IOCs for a beamline will be held. Continuous
integration will generate helm charts for each IOC and push them to
your account's package repository.

The beamline will come with an example IOC and further steps in the
tutorial will teach you how to add your own.


To Start
--------

For this exercise you will require a github user account or organization in
which to place the new repo. If you do not have one then follow GitHub's
`instructions`_.

Log in to your account by going here https://github.com/login.

.. _instructions: https://docs.github.com/en/get-started/signing-up-for-github/signing-up-for-a-new-github-account

Create a repository
-------------------

Navigate to the beamline template repo here https://github.com/epics-containers/blxx-template

Click on 'Use This Template'. Choose a name and description for your repo.
Click 'Create Repository From Template'.

.. image:: ../images/create_repo.png
    :align: center

This will create your new repository and take you to its Code panel.

Now Click on 'Code' and copy the SSH or HTTPS link presented. This depends on
how you will authenticate to github. HTTPS will ask you for your user name
and password for all transactions. To setup SSH authentication see `about ssh`_

.. _about ssh: https://docs.github.com/en/enterprise-server@3.0/github/authenticating-to-github/connecting-to-github-with-ssh/about-ssh


Clone and Tag the Repository
----------------------------

For the remainder of the tutorial the examples will use the ssh URL for
the account gilesknap and the repository name bl00i. Please substitute in
your own details.

In a terminal use git to clone the repository by pasting in the URL you copied
in the previous step::


    git clone git@github.com:gilesknap/bl00i.git

Now test that CI is working by tagging the repo and pushing it back to github::

    cd bl00i
    git tag 0.1
    git push origin 0.1

This will cause github CI to generate a helm chart for the example IOC and
deliver it to the account packages repository.

To watch the progress go to the Actions Panel for your project.

.. image:: ../images/github_actions.png
    :align: center

Once the CI completes you should have a helm chart delivered in your packages.
Go to the code pane and click on the example Package circled below to see it.


.. image:: ../images/github_package.png
    :align: center

There will be one version of the package, with two tags:

- the tag you set on the source
- and the 'latest' tag


.. image:: ../images/github_example_package.png
    :align: center
