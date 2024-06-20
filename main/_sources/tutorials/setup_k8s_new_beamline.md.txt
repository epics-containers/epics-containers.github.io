(setup-k8s-beamline)=

# Create a New Kubernetes Beamline

:::{warning}
This is a second draft that has been tested against a DLS test beamline
only. I will remove this warning once it has been tested against:

- the k3s example cluster described in the previous tutorial
- a real DLS beamline.
:::

Up until now the tutorials have been deploying IOCs to the local docker or
podman instance on your workstation. In this tutorial we look into setting
up a Kubernetes cluster for a beamline and deploying a test IOC there.

The advantage of using Kubernetes is that it is a production grade container
orchestration system. It will manage the CPU, disk and memory available across
your cluster of nodes, scheduling your IOCs and other services accordingly.
It will also restart them if they fail and monitor their health.
It can provide centralised logging and monitoring
of all of your services including IOCs.

In this tutorial we will create a new beamline in the Kubernetes cluster.
Here we assume that the cluster is already setup and that there is
a namespace configured for use by the beamline. See the previous tutorial
for how to set one up if you do not have this already.

:::{note}
DLS users: these instructions are for the BL46P beamline. Which is a training beamline.

To setup the beamline repo for other beamlines you will need to change the answers to the copier template questions.


At present DLS users will need to request access to the cluster for each beamline you want to work on. The following link is for making such a request but you will need someone who already has access to make the request for you:
<https://jira.diamond.ac.uk/servicedesk/customer/portal/2/create/92> (ask giles if you don't know who to ask for this access.)
:::

## Create a new beamline repository

This step is almost exactly the same as [](create-new-beamline-local). Except that you will answer some of the questions in the copier template differently. In fact you can re-use the same repository you created in the previous tutorial and update the copier to change where we deploy the IOCs to. The following steps will guide you through this, but if you want to keep your old local beamline repo, just follow the steps in [](create-new-beamline-local) but pick a new name and use the answers below.

In order to change our original `bl01t` beamline to a Kubernetes beamline perform the following steps:

```bash
# make sure your Python virtual environment is active
pip install copier

git clone git@github.com:YOUR_GITHUB_ACCOUNT/bl01t.git
cd bl01t
copier update --trust .
```

Answer the copier template questions as follows:

   <pre><font color="#5F87AF">🎤</font><b> Where are you deploying these IOCs and services?</b>
   <b>   </b><font color="#FFAF00"><b>beamline</b></font>
   <font color="#5F87AF">🎤</font><b> Short name for the beamline, e.g. &quot;bl47p&quot;, &quot;bl20j&quot;, &quot;bl21i&quot;</b>
   <b>   </b><font color="#FFAF00"><b>bl01t</b></font>
   <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
   <b>   </b><font color="#FFAF00"><b>beamline bl01t IOC Instances and Services</b></font>
   <font color="#5F87AF">🎤</font><b> Cluster namespace. local for no K8S or e.g. p38-iocs, j20-iocs, p47-iocs</b>
   <b>   </b><font color="#FFAF00"><b>p46-iocs</b></font>
   <font color="#5F87AF">🎤</font><b> Name of the cluster where the IOCs and services in this repository will run</b>
   <b>   </b><font color="#FFAF00"><b>pollux</b></font>
   <font color="#5F87AF">🎤</font><b> This controls how the `environment.sh` script connects to the cluster.</b>
   <b>   </b><font color="#FFAF00"><b>Shared Cluster (inc accelerator)</b></font>
   <font color="#5F87AF">🎤</font><b> Add node-type tolerations for the target hosts&apos; node type</b>
   <b>   </b><font color="#FFAF00"><b>training-rig</b></font>
   <font color="#5F87AF">🎤</font><b> Git platform hosting the repository.</b>
   <b>   </b><font color="#FFAF00"><b>github.com</b></font>
   <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
   <b>   </b><font color="#FFAF00"><b>YOUR_GITHUB_USER</b></font>
   <font color="#5F87AF">🎤</font><b> Remote URI of the repository.</b>
   <b>   </b><font color="#FFAF00"><b>git@github.com:YOUR_GITHUB_USER/bl01t.git</b></font>
   <font color="#5F87AF">🎤</font><b> URL for centralized logging.</b>
   <b>   </b><font color="#FFAF00"><b>DLS</b></font>
   </pre>

:::{warning}
DLS Users: These instructions are for the BL46P beamline. This beamline is a training rig and it is OK to install some test Simulation IOCs on it. However you will need to get access before you can deploy to it. Ask giles to request access to the `p46-iocs` namespace on the `pollux` cluster. In future the ec-services-template will be updated to allow you to deploy IOCs to your own namespace on the `pollux` cluster.
:::

## Review the New Beamline Repository

The following sections are just a review of what the template project created. Those of you who are outside of DLS can use this as a guide to what you need to set up in your own beamline repository to talk you your own cluster. DLS users will already have these things set up by the copier template to talk to the p46-iocs namespace on pollux cluster. If you believe your repo is already configured to talk to your cluster then you could jump ahead to [](create-test-ioc-k8s).


## Cluster Topologies

There are two supported topologies for beamline clusters:

- shared cluster with multiple beamlines' IOCs running in the same cluster
- dedicated cluster with a single beamline's IOCs running in the cluster

If you are working with the single node k3s cluster set up in the previous
tutorial then this will be considered a dedicated cluster.

If you are creating a real DLS beamline or accelerator domain then this will
also be a dedicated cluster. You will need to make sure the cloud team has
created the cluster for the beamline and you have permissions to use it.

If you are working with one of the test beamlines at DLS then these are usually
shared topology and are set up as nodes on the Pollux cluster.

Other facilities are free to choose the topology that best suits their needs.

### Shared Clusters

In the shared cluster topology we would usually want IOCs to run on the
servers that are closest to the beamline. This is important for Channel Access
because it is a broadcast protocol and by default only works on a single
subnet.

To facilitate this we use `node affinity rules` to ensure that IOCs
run on the beamline's specific nodes. `Node affinity` can look for a `label`
on the node to say that it belongs to a beamline.
We can also use `taints` to stop other pods from
running on our beamline nodes. A `taint` will stop pods from being scheduled
on a node unless the pod has a matching toleration.

For example the test beamline p46 at DLS has the following `taints` and
`labels`:

```
Labels:         beamline=bl46p
                nodetype=test-rig

Taints:         beamline=bl46p:NoSchedule
                nodetype=test-rig:NoSchedule
```

If you are working with your facility cluster then, you may not
have permission to set up these labels and taints. In this case, your
administrator will need to do this for you. At DLS, you should expect that
this is already set up for you.

For an explanation of these K8S concepts see

- [Taints and Tolerances](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity-beta-feature)

### Dedicated Clusters

In the dedicated cluster topology we would usually want to let the IOCs
run on all of the worker nodes in the cluster. In this case the only thing
that is required is a namespace in which to run your IOCs.

By convention we use a namespace like `bl46p-iocs` for this purpose. This
namespace will need the appropriate permissions to allow the IOCs to run
with network host.

## Environment Setup

Every beamline repository has an `environment.sh` file used to configure
your shell so that the command line tools know which cluster to talk to.
Up to this point we have been using the local docker or podman instance,
but here we will configure it to use the beamline cluster.

For the detail of what goes into `environment.sh` see
{any}`../reference/environment`.

Now edit `environment.sh` make changes as follows:

### Section 1

Change this section to set the following variables:

```bash
export EC_REGISTRY_MAPPING='github.com=ghcr.io'
export EC_K8S_NAMESPACE=p46-iocs
export EC_SERVICES_REPO=git@github.com:YOUR_GITHUB_ACCOUNT/bl46p.git
```

This tells the `ec` command line tool to use the GitHub container registry
when it sees github projects, the name of the Kubernetes namespace to use and
the location of the beamline repository.

### Section 2

The script should also make sure that `ec` CLI is available and it is also
useful to set up command line completion up. The simplest way to do this is:

```bash
set -e # exit on error
source <(ec --show-completion ${SHELL})
```

For a review of how to set up the epics-containers-cli tool `ec` see
{any}`python-setup` and {any}`ec`.

### Section 3

This is where you make sure the cluster is contactable. For the k3s cluster
we set up the default `~/.kube/config` file to point to the local cluster.
So we can leave this section blank.

At DLS you would need to load a module to set up the environment for the
beamline cluster. For example:

```bash
module load pollux # for all test beamlines
module load k8s-i22 # for the real beamline i22
```

Once `environment.sh` is set up, source it to set up your shell.

```bash
source environment.sh
```

You are now ready to start talking to the cluster. You can verify this with
the following command that should list all the nodes on the cluster. You
will be asked for your credentials if required.

```bash
kubectl get nodes
```

## Setting up the Beamline Helm Chart Defaults

The beamline helm chart is used to deploy IOCs to the cluster. Each IOC instance
gets to override any of the settings available in the chart. This is done
in `services/<iocname>/values.yaml` for each IOC instance. However, all
settings except `image` have default values supplied at the beamline level.
For this reason most IOC instances only need supply the `image` setting
which specifies the Generic IOC container image to use.

Before making the first IOC instance we need to set up the beamline defaults.
These are all held in the file `helm/shared/values.yaml`.

Open this file and make the following changes depending on your beamline type. (Note that the new `ec-services-template` will have already set up the values below for you, assuming you are looking at one of the cluster types supported by it.)

### All cluster types

```yaml
beamline: bl46p
namespace: p46-iocs
hostNetwork: true # required for channel access access on the host

opisClaim: bl46p-opi-claim
runtimeClaim: bl46p-runtime-claim
autosaveClaim: bl46p-autosave-claim
```

### k3s single server cluster

```yaml
dataVolume:
  pvc: true
  # point at a PVC created by kubernetes
  hostPath: /data/
```

### DLS test beamlines

```yaml
dataVolume:
  pvc: true
  # point at local disk on the server
  hostPath: /exports/mybeamline

# extra tolerations for the training rigs
tolerations:
- key: nodetype
    operator: "Equal"
    value: training-rig
    effect: "NoSchedule"
```

### DLS real beamlines

```yaml
dataVolume:
  pvc: true
  # point at the shared filesystem data folder for the beamline
  hostPath: /dls/p46/data
```
(create-test-ioc-k8s)=
## Create a Test IOC to Deploy

TODO: This is work in progress (but essentially just repeat what we did in [](deploy-example-instance)).

You should be able to deploy `bl01t-ea-test-02` IOC that you made in [](create-new-ioc-instance) to the k3s cluster with the same command as before:

```bash
cd bl01t
source environment.sh
ec local/deploy services/bl01t-ea-test-02
```

:::{note}
At DLS you can get to a Kubernetes Dashboard for your beamline via
a landing page `https://pollux.diamond.ac.uk` for test beamlines on
`Pollux` - remember to select the namespace `p46-iocs` for example.

For real beamlines dedicated clusters, you can find the landing page for example:
`https://k8s-i22.diamond.ac.uk/` for BL22I.
`https://k8s-b01-1.diamond.ac.uk/` for the 2nd branch of BL01B.
:::
