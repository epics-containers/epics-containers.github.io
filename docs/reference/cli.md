(cli)=

# Command Line Interface for IOC Management

The python project {any}`edge-containers-cli` is installed as part of the Python section of the initial tutorial {any}`../tutorials/setup_workstation`. It provides a command line function `ec` with support for  managing and monitoring IOC instances.

This tool is only required if you are deploying to Kubernetes. Docker compose provides a very similar set of commands for local deployment. Also note that `ec` supports both ArgoCD and pure Helm deployments. The tutorials will use ArgoCD, for information on Helm based deployments see {std:ref}`helm` .

The CLI is just a thin wrapper around the underlying tools that do the real work:

```{eval-rst}

:kubectl: the command line interface to the Kubernetes APIs
:helm: the command line interface to the Kubernetes Helm package manager
:git: the git version control system client
:argocd: the ArgoCD command line interface
```

`ec` is useful because it saves typing and provides a consistent interface when working on multiple {any}`services-repo`s. This is because it uses the environment setup by the beamline repo's `environment.sh` script. See {any}`environment`.

To see the available commands, run `ec --help`.

It may be instructive to understand the underlying tools and how they are being called. For this reason `ec` supports a `-v` option to show the underlying commands being executed. e.g.

```{raw} html
<pre>(venv) <font color="#64BA12">(main) </font>[<font color="#6491CB">hgv27681@pc0116</font> bl47p]$ ec -v ps
<font color="#5F8787">kubectl get namespace p47-iocs -o name</font>
<font color="#5F8787">helm list -n p47-iocs -o json</font>
<font color="#5F8787">kubectl get pods -n p47-iocs -o jsonpath=&apos;{range .items[*]}{..labels.app}{&quot;,&quot;}{..containerStatuses[0].ready}{&quot;,&quot;}{..containerStatuses[0].restartCount}{&quot;,&quot;}{.status.startTime}{&quot;\n&quot;}{end}&apos;</font>
             name ready restarts              started namespace app_version
 bl47p-ea-dcam-01  true        0 2024-02-09T12:34:18Z  p47-iocs  2024.2.1b2
 bl47p-ea-dcam-02  true        0 2024-02-09T15:10:06Z  p47-iocs    2024.2.1
bl47p-ea-panda-01  true        0 2024-02-09T21:57:23Z  p47-iocs  2024.2.1b2
  bl47p-mo-ioc-01  true        0 2024-02-09T15:42:24Z  p47-iocs    2024.2.1
       epics-opis  true        0 2024-02-09T21:55:21Z  p47-iocs    2024.2.2
(venv) <font color="#64BA12">(main) </font>[<font color="#6491CB">hgv27681@pc0116</font> bl47p]$
</pre>
```
