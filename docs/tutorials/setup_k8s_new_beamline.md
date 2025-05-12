(setup-k8s-beamline)=

# Create a New Kubernetes Beamline

Up until now the tutorials have been deploying IOCs to the local docker or podman instance on your workstation using compose. In this tutorial we look into creating a beamline repository that deploy's into a Kubernetes cluster.

Helm is a package manager for Kubernetes that allows you to define a set of resources that make up your application in a **Chart**. This is the most popular way to deploy applications to Kubernetes.

Previously our beamline repository contained a **services** folder.  Each subfolder of **services** contained a **compose.yaml** with details of the generic IOC container image, plus a **config** folder that provided an IOC instance definition.

In the Kubernetes world the structure is very similar. Each folder under **services** will be an individually deployable Helm Chart. This means that instead of a **compose.yaml** file we will have a **Chart.yaml** which describes the dependencies of the chart and a **values.yaml** that describes some arguments to it. There is also a file **services/values.yaml** that describes the default arguments for all the charts in the repository.

In this tutorial we will create a new simulation beamline in a Kubernetes cluster. Here we assume that the cluster is already setup and that there is a namespace configured for use by the beamline. See the previous tutorial for how to set one up if you do not have this already.

:::{note}
DLS users: you should use your personal namespace in the test cluster **Pollux**. Your personal namespace is named after your *fedid*
:::

## Create a new beamline repository

As before, we will use a copier template to create the new beamline repository. The steps are similar to the first tutorial {any}`create_beamline`.

1. We are going to call the new beamline **bl03t** with the repository name **t03-services**. It will be created in the namespace **t03-beamline** on the local cluster that we created in the last tutorial **OR** your *fedid* namespace on the **Pollux** cluster if you are using the DLS cluster.

    ```bash
    # make sure your Python virtual environment is active and copier is pip installed
    copier copy https://github.com/epics-containers/services-template-helm t03-services
    ```

    Answer the copier template questions as follows for your own local cluster:

    <pre><font color="#5F87AF">🎤</font><b> A name for this group of IOC and service instances.</b>
    <b>   At DLS this should be the short beamline name or the technical area</b>
    <b>   for accelerator repos.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
    <b>   </b><font color="#FFAF00"><b>t03 IOC Instances and Services</b></font>
    <font color="#5F87AF">🎤</font><b> Default location where these IOCs and services will run.</b>
    <b>   At DLS this should be beamline shortname or blank for the accelerator.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> The Kubernetes cluster where the IOCs and services will run.</b>
    <b>   At DLS this should be &quot;k8s-{beamline shortname}&quot;, &quot;acastus&quot; for the</b>
    <b>   accelerator or &quot;pollux&quot; for test beamlines.</b>
    <b>   </b><font color="#FFAF00"><b>local</b></font>
    <font color="#5F87AF">🎤</font><b> Kubernetes namespace in which the IOCs and services will run.</b>
    <b>   At DLS this should be &quot;{beamline shortname}-beamline&quot; or &quot;accelerator&quot;.</b>
    <b>   </b><font color="#FFAF00"><b>t03-beamline</b></font>
    <font color="#5F87AF">🎤</font><b> Apply cluster specific details.</b>
    <b>   To add to this list make a PR to services-template-helm.</b>
    <b>   </b><font color="#FFAF00"><b>Skip</b></font>
    <font color="#5F87AF">🎤</font><b> Git platform hosting this repository.</b>
    <b>   To add to this list make a PR to services-template-helm.</b>
    <b>   </b><font color="#FFAF00"><b>github.com</b></font>
    <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
    <b>   </b><font color="#FFAF00"><b>YOUR GITHUB ACCOUNT</b></font>
    <font color="#5F87AF">🎤</font><b> Remote URI of the services repository.</b>
    <b>   </b><font color="#FFAF00"><b>https://github.com/YOUR GITHUB ACCOUNT/t03-services</b></font>
    <font color="#5F87AF">🎤</font><b> URL for centralized logging. Leave blank if not applicable.</b>
    <b>   </b><font color="#FFAF00"><b>Skip</b></font>
    </pre>

    OR like this for DLS users using the Pollux cluster:

    <pre><font color="#5F87AF">🎤</font><b> A name for this group of IOC and service instances.</b>
    <b>   At DLS this should be the short beamline name or the technical area</b>
    <b>   for accelerator repos.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
    <b>   </b><font color="#FFAF00"><b>t03 IOC Instances and Services</b></font>
    <font color="#5F87AF">🎤</font><b> Default location where these IOCs and services will run.</b>
    <b>   At DLS this should be beamline shortname or blank for the accelerator.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> The Kubernetes cluster where the IOCs and services will run.</b>
    <b>   At DLS this should be &quot;k8s-{beamline shortname}&quot;, &quot;acastus&quot; for the</b>
    <b>   accelerator or &quot;pollux&quot; for test beamlines.</b>
    <b>   </b><font color="#FFAF00"><b>pollux</b></font>
    <font color="#5F87AF">🎤</font><b> Kubernetes namespace in which the IOCs and services will run.</b>
    <b>   At DLS this should be &quot;{beamline shortname}-beamline&quot; or &quot;accelerator&quot;.</b>
    <b>   </b><font color="#FFAF00"><b>YOUR FED ID</b></font>
    <font color="#5F87AF">🎤</font><b> Apply cluster specific details.</b>
    <b>   To add to this list make a PR to services-template-helm.</b>
    <b>   </b><font color="#FFAF00"><b>DLS Cluster</b></font>
    <font color="#5F87AF">🎤</font><b> Git platform hosting this repository.</b>
    <b>   To add to this list make a PR to services-template-helm.</b>
    <b>   </b><font color="#FFAF00"><b>github.com</b></font>
    <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
    <b>   </b><font color="#FFAF00"><b>YOUR GITHUB ACCOUNT</b></font>
    <font color="#5F87AF">🎤</font><b> Remote URI of the services repository.</b>
    <b>   </b><font color="#FFAF00"><b>https://github.com/YOUR GITHUB ACCOUNT/t03-services</b></font>
    <font color="#5F87AF">🎤</font><b> URL for centralized logging. Leave blank if not applicable.</b>
    <b>   </b><font color="#FFAF00"><b>DLS GrayLog</b></font>
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

## Configure the new beamline repository

If you have brought your own cluster then you may need to edit the **environment.sh** and **services/values.yaml** files to suit your cluster topology. If you are using the DLS Pollux cluster or the k3s local cluster then the template should have configured these correctly for you. See {any}`../reference/services_config` for more details.

## Setup the epics containers CLI

To deploy and manage IOC istances requires **helm** and **kubectl** command line tools. However we supply a simple wrapper for these tools that saves typing and helps with learning the commands. Go ahead and add the `edge-containers-cli` python package to your virtual environment if it is not already there.

```bash
# make sure your Python virtual environment is active, then:
pip install edge-containers-cli
# setup the environment for ec to know how to talk to the cluster
# (make sure you are in the t03-services directory)
source ./environment.sh
```


The new repository has a simple example IOC that it comes with the template and is called t03-ea-test-01.

For a new beamline we will also need to deploy the shared resources that all IOCs expect to find in their namespace, namely:
- epics-pvcs: some persistent volumes (Kubernetes data stores) for the IOCs to store autosave files, GUI files and other data
- epics-opis: an nginx web server that serves the IOC GUI files out of one of the above persistent volumes

The ec tool can help with version tracking by deploying version of services from tagged commits in the git repo. So first lets go ahead and tag the current state of the repository.

```bash
# make sure you are in the t03-services directory, then:
git tag 2024.9.1
git push origin 2024.9.1
```

Now you can deploy the shared resources to the cluster, using the version we just tagged. We will use the -v option which shows the underlying commands that are being run.

```bash
ec -v deploy epics-pvcs 2024.9.1
ec -v deploy epic-opis 2024.9.1
```

## Create a Simple Example IOC Instance

Here we will create a minimal IOC to deploy into the cluster.

Steps:

1. Create a new folder in the **services** folder called **t03-ea-test-01** by copying **services/.ioc_template**.
1. Edit **services/t03-ea-test-01/values.yaml** to tell helm which generic IOC to deploy
1. Edit **services/to3-ea-test-01/config/ioc.yaml** to describe the IOC instance.
1. Create a basic EPICS DB file to the IOC instance in **services/t03-ea-test-01/config/ioc.db**.

The **values.yaml** file should look like this:
```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ec-helm-charts/releases/download/4.1.3/ioc-instance.schema.json
ioc-instance:
  image: ghcr.io/epics-containers/ioc-template-example-runtime:4.1.0
```

The ioc-template-example is a basic generic IOC that just includes epics-base and pvxs. It is generated as part of the CI for testing the ioc-template project.

The **ioc.yaml** file should look like this:
```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ioc-template-example/releases/download/4.1.0/ibek.ioc.schema.json

ioc_name: "{{ _global.get_env('IOC_NAME') }}"

description: Very generic instance for testing generic IOCs

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: epics.StartupCommand
    command: dbLoadRecords("/epics/ioc/config/ioc.db")
```

This is essentially an empty IOC instance that loads a database file. We will create that database file next.


The **ioc.db** file should look like this:
```
record(calc, "EXAMPLE:SUM") {
  field(DESC, "Sum A and B")
  field(CALC, "A+B")
  field(INPA, "EXAMPLE:A")
  field(INPB, "EXAMPLE:B")
}

record(ao, "EXAMPLE:A") {
    field(DESC, "A voltage")
    field(PREC, "3")
    field(EGU,  "Volts")
    field(DRVL, "-10")
    field(DRVH, "+10")
    field(VAL,  "0.000")
    field(FLNK, "EXAMPLE:SUM")
}

record(ao, "EXAMPLE:B") {
    field(DESC, "B voltage")
    field(PREC, "3")
    field(EGU,  "Volts")
    field(DRVL, "-10")
    field(DRVH, "+10")
    field(VAL,  "0.000")
    field(FLNK, "EXAMPLE:SUM")
}
```

This simple EPICS Db just creates a couple of analogue out records and a calc record that sums them.

Once you have completed the above, commit your changes and tag the repository.

```bash
git add .
git commit -m "added t03-ea-test-01 IOC instance"
git tag 2024.12.2
git push origin 2024.12.2
```

The new example IOC is now ready to be deployed.

## Deploy an Example IOC Instance

You are now ready to deploy the example IOC instance.

```bash
ec -v deploy t03-ea-test-01 2024.12.2
```

You can check the status of the deployment using:

```bash
ec ps
```

You could also investigate the other commands that `ec` provides by running `ec --help`.

:::{note}
When things are not working as expected or you want to examine the resources you are deploying, you can use the `kubectl describe` command e.g.

```bash
kubectl describe pod t03-ea-test-01
```

If you prefer a more interactive approach, then look at the Kubernetes Dashboard. For a k3s local cluster refer to the notes on installing the dashboard in the previous tutorial (see {any}`k8s-dashboard`).

At DLS you can get to a Kubernetes Dashboard for your beamline via a landing page `https://pollux.diamond.ac.uk` for test beamlines on `Pollux` - remember to select your fed_id namespace from the dropdown in the top left.

For production beamlines with dedicated clusters, the landing pages are named after the beamline, for example:
`https://k8s-i22.diamond.ac.uk/` for BL22I.
`https://k8s-b01-1.diamond.ac.uk/` for the 2nd branch of BL01B.
in this case the namespace will be i22-beamline, b01-1-beamline, etc.
:::

## Verify that the IOC is working

Right now you cannot see PVs from your IOC because it is running in a container network and channel access clients won't be able to contact it.

For k3s users you can simply fix this by setting 'hostNetwork: true' in **services/values.yaml**. Then re-deploy the IOC instance (by pushing the change and making a new tag).

DLS users do not have permission to run host network in their personal namespaces.

The best solution is to use a channel access gateway to bridge the container network to the host network. We will do this in a later tutorial.

For now you can check you IOC by launching a shell inside it's container and using the `caput` and`caget` commands. All IOC containers have the epics-base tools installed. Try the following commands to confirm that the IOC is running and that the PVs are accessible.

```bash
$ ec exec t03-ea-test-01
root@t03-ea-test-01-0:/# caput EXAMPLE:A 1.1
Old : EXAMPLE:A                 0
New : EXAMPLE:A                 1.1
root@t03-ea-test-01-0:/# caput EXAMPLE:B 2
Old : EXAMPLE:B                 0
New : EXAMPLE:B                 2
root@t03-ea-test-01-0:/# caget EXAMPLE:SUM
EXAMPLE:SUM                     3.1
```
