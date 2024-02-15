.. _CLI:

Command Line Interface for IOC Management
=========================================

The python project ``epics-containers-cli`` is installed as part of the
Python section of the initial tutorial `../tutorials/setup_workstation`.
It provides a command line function ``ec`` with support for:

- deploying, managing and debugging IOCs and other application Instances

The CLI is just a thin wrapper around the underlying tools that do the real
work:

:kubectl: the command line interface to the Kubernetes APIs
:helm: the command line interface to the Kubernetes Helm package manager
:podman (or docker): CLIs for container engines
:git: the git version control system client

``ec`` is useful because it saves typing and provides a consistent interface
when working on multiple beamlines. This is because it uses the environment
setup by the beamline repo's ``environment.sh`` script. See `environment`.

To see the available commands, run ``ec --help``.

It may be instructive to understand the underlying tools and how they are
are being called. For this reason ``ec`` supports a ``-v`` option to show
the underlying commands being executed. e.g.

.. raw:: html

    <pre>$ ec -v ps
    <font color="#5F8787">kubectl get namespace p38-iocs -o name</font>
    <font color="#5F8787">kubectl -n p38-iocs get pod -l is_ioc==True -o custom-columns=IOC_NAME:metadata.labels.app,VERSION:metadata.labels.ioc_version,STATE:status.phase,RESTARTS:status.containerStatuses[0].restartCount,STARTED:metadata.managedFields[0].time</font>
    IOC_NAME            VERSION             STATE     RESTARTS   STARTED
    bl38p-ea-ioc-03     2023.10.6           Running   0          2023-10-25T14:07:44Z
    bl38p-ea-panda-02   2023.10.25-b16.24   Running   0          2023-10-25T15:24:41Z
    </pre>