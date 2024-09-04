# Configuring a Services Repository for a Cluster

:::{warning}
This page is a work in progress.
:::

## Intro

In {any}`../tutorials/setup_k8s_new_beamline` we created a new beamline repository for a Kubernetes cluster. The copier template is capable of fully configuring the repo for the following types of cluster:

- a local k3s cluster created in {any}`../tutorials/setup_k8s`
- your DLS *fedid* namespace in the Pollux cluster
- a dedicated beamline cluster at DLS
- a shared accelerator cluster at DLS

If you have a cluster that is not in the above list then you will need edit your **environment.sh** and **services/values.yaml** files accordingly. The following sections introduce the details of this process.


## Cluster Topologies

There are two supported topologies for beamline clusters:

- shared cluster with multiple beamlines' IOCs running in the same cluster
- dedicated cluster with a single beamline's IOCs running in the cluster

If you are working with the single node k3s cluster set up in the previous tutorial then this will be considered a dedicated cluster.

If you are creating a real DLS beamline then this will also be a dedicated cluster. However if your repo contains a set of accelerator IOCs this will share the single accelerator cluster amongst several serives repositories and is therefore a shared cluster.

If you are working with one of the test beamlines at DLS then these are usually shared topology and are set up as nodes on the Pollux cluster.

Other facilities are free to choose the topology that best suits their needs.

### Shared Clusters

In a shared cluster topology we will likely need to tell the IOCs which servers they are allowed to run on. This is primarily becasuse the server needs to be able to connect to the device the IOC is controlling.

In the case of the DLS accelerator will be 2 nodes (AKA servers) per CIA connected to the local instrumentation network. Only those nodes will be able to see the devices on the local instrumentation network.

To facilitate this we use `node affinity rules` to ensure that IOCs run on the correct nodes. `Node affinity` can look for a `label` on the node to say that it belongs to a beamline or CIA.

We can also use `taints` to stop other pods from running on our beamline nodes. A `taint` will stop pods from being scheduled
on a node unless the pod has a matching toleration.

For example the test beamline p47 at DLS has the following `taints` and
`labels`:

```
Labels:         beamline=bl47p
                nodetype=test-rig

Taints:         beamline=bl47p:NoSchedule
                nodetype=test-rig:NoSchedule
```

That test beamline has a single server which has the labels `beamline=bl47p` and `nodetype=test-rig`. It also has the taints `beamline=bl47p:NoSchedule` and `nodetype=test-rig:NoSchedule`. All of the devices on the test beamline are connected directly to this server and only visible on local IP addresses. The taints and tolerences assure that only p47 IOCs are scheduled on this server and that those IOCs will never run anywhere else.

If you are working with your facility cluster then, you may not have permission to set up these labels and taints. In this case, your administrator will need to do this for you. At DLS, you should expect that this is already set up for you.

For an explanation of these K8S concepts see

- [Taints and Tolerances](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity-beta-feature)

### Dedicated Clusters

In the dedicated cluster topology we would usually want to let the IOCs run on any of the worker nodes in the cluster. In this case the only thing that is required is a namespace in which to run your IOCs.

By convention we use a namespace like `t03-beamline` for this purpose. This namespace will need the appropriate permissions to allow the IOCs to run with network host OR you will expose your PVs by running a ca-gateway in the cluster. At DLS we have chosen to use network host for our dedicated clusteres because:

- we prefer not to pass the Channel Access traffic through the gateway
- other protocols such as GigE Streaming also require network host because they are not NAT friendly

TODO - these following sections are WORK IN PROGRESS.

## Environment Setup

Every services repository has an `environment.sh` file used to configure your shell so that the command line tools know which cluster to talk to. Up to this point we have been using the local docker or podman instance, but here we have configured it to use the the cluster. The copier template should have created the correct settings in **environment.sh** for you. But you can review them by if needed here {any}`../reference/environment`.

TODO pull the above ref into this page and update it.


## Setting up the Beamline Helm Chart Defaults

You do not need to understand helm in detail to deploy IOCs to the cluster. But it may be instructive to understand what is happening under the hood. You will need to know how to edit the **values.yaml** files to configure your charts for your individual cluster topology.

TODO incomplete.

