.. _CLI:

Command Line Interface for IOC Management
=========================================

The python project ``epics-containers-cli`` is installed as part of the
Python section of the initial tutorial `../tutorials/setup_workstation`.
It provides a command line function ``ec`` with support for:

- building and debugging Generic IOC Containers
- deploying, managing and debugging IOC Instances

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
Much of the functionality is available through subcommands dev and ioc. To get
full details of a given command type the full command plus ``--help``. For
example:

.. raw:: html

    <pre>$ ec dev launch --help
    <b>                                                                                 </b>
    <b> </b><font color="#A2734C"><b>Usage: </b></font><b>ec dev launch [OPTIONS] IOC_INSTANCE                                     </b>
    <b>                                                                                 </b>
    Launch an IOC instance using configuration from a domain repo. Or by passing a
    generic IOC image ID. Can be used for local testing of IOC instances. You may
    find the devcontainer a more convenient way to do this.

    <font color="#AAAAAA">╭─ Arguments ───────────────────────────────────────────────────────────────────╮</font>
    <font color="#AAAAAA">│ </font><font color="#C01C28">*</font>    ioc_instance      <font color="#A2734C"><b>DIRECTORY</b></font>  local IOC definition folder from domain     │
    <font color="#AAAAAA">│                                   repo                                        │</font>
    <font color="#AAAAAA">│                                   [default: None]                             │</font>
    <font color="#AAAAAA">│                                   </font><font color="#80121A">[required]                                 </font> │
    <font color="#AAAAAA">╰───────────────────────────────────────────────────────────────────────────────╯</font>
    <font color="#AAAAAA">╭─ Options ─────────────────────────────────────────────────────────────────────╮</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--execute</b></font>         <font color="#A2734C"><b>TEXT               </b></font>  command to execute in the container.   │
    <font color="#AAAAAA">│                                        Defaults to executing the IOC          │</font>
    <font color="#AAAAAA">│                                        [default: /epics/ioc/start.sh; bash]   │</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--target</b></font>          <font color="#6C4C32"><b>[developer|runtime]</b></font>  choose runtime or developer target     │
    <font color="#AAAAAA">│                                        [default: developer]                   │</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--image</b></font>           <font color="#A2734C"><b>TEXT               </b></font>  override container image to use        │
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--tag</b></font>             <font color="#A2734C"><b>TEXT               </b></font>  override image tag to use.             │
    <font color="#AAAAAA">│                                        [default: None]                        │</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--args</b></font>            <font color="#A2734C"><b>TEXT               </b></font>  Additional args for podman/docker,     │
    <font color="#AAAAAA">│                                        &apos;must be quoted&apos;                       │</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--ioc-name</b></font>        <font color="#A2734C"><b>TEXT               </b></font>  container name override. Use to run    │
    <font color="#AAAAAA">│                                        multiple instances                     │</font>
    <font color="#AAAAAA">│                                        [default: test-ioc]                    │</font>
    <font color="#AAAAAA">│ </font><font color="#2AA1B3"><b>--help</b></font>            <font color="#A2734C"><b>                   </b></font>  Show this message and exit.            │
    <font color="#AAAAAA">╰───────────────────────────────────────────────────────────────────────────────╯</font>
    </pre>

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