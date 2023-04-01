Choose Your Developer Environment
=================================

The tutorials walk through the use of a standard set of developer tools. You
can use others if you wish as detailed below.

.. _own_editor:

Working with your own code editor
---------------------------------

If you have your own preferred code editor, you can use it instead of
vscode. This does mean that you will forgo the benefits of the devcontainer
integration.

TODO: update dev-e7 to have its own launcher like
https://github.com/dls-controls/dev-c7
then link to it's documentation and discuss how to use it with epics-containers.

If you do not want to use a devcontainer at all and instead prefer to install all
the tools natively on your workstation then please see below.

.. _no_devcontainer:

Working without a Devcontainer
------------------------------

**Not recommended.**

If you do not want to do development inside of a container then you can
install all the tools natively on your workstation. You are then responsible
for keeping these updated as necessary.
You will also be responsible for the configuration of these tools.

The tools required are (at least):-

- Python 3.10 or greater
- pip
- python package epics-containers-cli
- docker (or podman)
- kubernetes client tools appropriate to your cluster K8S version

  - helm >= 4.2.0
  - kubectl >= 1.23.0
  - oidc-login (or whichever tool you use to authenticate to your cluster)

- git
- build essentials tools
- EPICS V7 client tools