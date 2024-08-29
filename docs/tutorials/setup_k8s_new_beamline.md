(setup-k8s-beamline)=

# Create a New Kubernetes Beamline

Up until now the tutorials have been deploying IOCs to the local docker or docker instance on your workstation using compose. In this tutorial we look into creating a beamline repository that deploy's into a Kubernetes cluster.

Helm is a package manager for Kubernetes that allows you to define a set of resources that make up your application in a **Chart**. This is the most popular way to deploy applications to Kubernetes.

Previously our beamline repository contained a **services** folder.  Each subfolder of **services** contained a **compose.yaml** with details of the generic IOC container image, plus a **config** folder that provided an IOC instance definition.

In the Kubernetes world each folder under **services** will be an individually deployable Helm Chart. This means that instead of a **compose.yaml** file we will have a **Chart.yaml** which describes the dependencies of the chart and a **values.yaml** that describes some arguments to it. There is also a file **services/values.yaml** that describes the default arguments for all the charts in the repository.

In this tutorial we will create a new beamline in a Kubernetes cluster. Here we assume that the cluster is already setup and that there is a namespace configured for use by the beamline. See the previous tutorial for how to set one up if you do not have this already.

:::{note}
DLS users: you should use your personal namespace in the test cluster **Pollux**. Your personal namespace is named after your *fedid*
:::

## Create a new beamline repository

As before, we will use a copier template to create the new beamline repository. The steps are similar to the first tutorial {any}`create_beamline`.

1. We are going to call the new beamline **bl03t** with the repository name **t03-services** it will be created in the namespace **bl03t** on the local cluster that we created in the last tutorial OR the *fedid* namespace on the Pollux cluster if you are using the DLS cluster.

    ```bash
    # make sure your Python virtual environment is active and copier is pip installed
    copier copy gh:epics-containers/services-template-helm t03-services
    code t03-services
    ```

    Answer the copier template questions as follows:

    <pre><font color="#5F87AF">🎤</font><b> Short name for this collection of services.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
    <b>   </b><font color="#FFAF00"><b>t03 IOC Instances and Services</b></font>
    <font color="#5F87AF">🎤</font><b> Kubernetes cluster namespace</b>
    <b>   </b><font color="#FFAF00"><b>t03-beamline</b></font>
    <font color="#5F87AF">🎤</font><b> Name of the k8s cluster where the IOCs and services in this repository will run</b>
    <b>   </b><font color="#FFAF00"><b>local</b></font>
    <font color="#5F87AF">🎤</font><b> Apply cluster specific details. For missing platform override cluster_type, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>Skip</b></font>
    <font color="#5F87AF">🎤</font><b> Default location where these IOCs and services will run. e.g. &quot;bl01t&quot;, &quot;SR01&quot;. Leave blank to configure per IOC.</b>
    <b>   </b><font color="#FFAF00"><b>bl03t</b></font>
    <font color="#5F87AF">🎤</font><b> Git platform hosting this repository. For missing platform override git_platform, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>github.com</b></font>
    <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
    <b>   </b><font color="#FFAF00"><b>gilesknap</b></font>
    <font color="#5F87AF">🎤</font><b> Remote URI of the services repository.</b>
    <b>   </b><font color="#FFAF00"><b>https://github.com/gilesknap/t03-services</b></font>
    <font color="#5F87AF">🎤</font><b> URL for centralized logging. For missing platform override logging_url, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>Skip</b></font>
    </pre>

1. Create your new repository on GitHub in your personal space by following this link <https://github.com/new>. Give it the name **t03-services** and a description of "t03 IOC Instances and Services". Then click "Create repository".

   Now copy the ssh address of your new repository from the GitHub page.

   :::{figure} ../images/copy_gh_repo_addr.png
   copying the repository address from GitHub
   :::

1. Make the first commit and push the repository to GitHub.

    ```bash
    cd t03-services
    git init -b main
    git add .
    git commit -m "initial commit"
    git remote add origin >>>>paste your ssh address here<<<<
    git push -u origin main
    ```

## Review the New Beamline Repository

The following sections are just a review of what the template project created. Those of you who are outside of DLS can use this as a guide to what you need to set up in your own beamline repository to talk you your own cluster. The template should have created the correct things already if you are using DLS's **pollux** or your own local cluster from the previous tutorial.


## Cluster Topologies

There are two supported topologies for beamline clusters:

- shared cluster with multiple beamlines' IOCs running in the same cluster
- dedicated cluster with a single beamline's IOCs running in the cluster

If you are working with the single node k3s cluster set up in the previous tutorial then this will be considered a dedicated cluster.

If you are creating a real DLS beamline or accelerator domain then this will also be a dedicated cluster. You will need to make sure the cloud team has created the cluster for the beamline and you have permissions to use it.

If you are working with one of the test beamlines at DLS then these are usually shared topology and are set up as nodes on the Pollux cluster.

Other facilities are free to choose the topology that best suits their needs.

### Shared Clusters

In the shared cluster topology we would usually want IOCs to run on the servers that are closest to the beamline. This is important for Channel Access because it is a broadcast protocol and by default only works on a single subnet.

To facilitate this we use `node affinity rules` to ensure that IOCs run on the beamline's specific nodes. `Node affinity` can look for a `label` on the node to say that it belongs to a beamline.

We can also use `taints` to stop other pods from running on our beamline nodes. A `taint` will stop pods from being scheduled
on a node unless the pod has a matching toleration.

For example the test beamline p46 at DLS has the following `taints` and
`labels`:

```
Labels:         beamline=bl46p
                nodetype=test-rig

Taints:         beamline=bl46p:NoSchedule
                nodetype=test-rig:NoSchedule
```

If you are working with your facility cluster then, you may not have permission to set up these labels and taints. In this case, your administrator will need to do this for you. At DLS, you should expect that this is already set up for you.

For an explanation of these K8S concepts see

- [Taints and Tolerances](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity-beta-feature)

### Dedicated Clusters

In the dedicated cluster topology we would usually want to let the IOCs run on all of the worker nodes in the cluster. In this case the only thing that is required is a namespace in which to run your IOCs.

By convention we use a namespace like `t03-beamline` for this purpose. This namespace will need the appropriate permissions to allow the IOCs to run with network host OR you will expose your PVs by running a ca-gateway in the cluster. At DLS we have chosen to use network host for our dedicated clusteres because:

- we prefer not to pass the Channel Access traffic through the gateway
- other protocols such as GigE Streaming also require network host because they are not NAT friendly

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
