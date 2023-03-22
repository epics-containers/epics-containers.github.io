Working without a Devcontainer
==============================

Not recommended.

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
