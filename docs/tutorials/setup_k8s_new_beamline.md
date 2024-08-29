(setup-k8s-beamline)=

# Create a New Kubernetes Beamline

Up until now the tutorials have been deploying IOCs to the local docker or podman instance on your workstation using compose. In this tutorial we look into creating a beamline repository that deploy's into a Kubernetes cluster.

Helm is a package manager for Kubernetes that allows you to define a set of resources that make up your application in a **Chart**. This is the most popular way to deploy applications to Kubernetes.

Previously our beamline repository contained a **services** folder.  Each subfolder of **services** contained a **compose.yaml** with details of the generic IOC container image, plus a **config** folder that provided an IOC instance definition.

In the Kubernetes world, each folder under **services** will be an individually deployable Helm Chart. This means that instead of a **compose.yaml** file we will have a **Chart.yaml** which describes the dependencies of the chart and a **values.yaml** that describes some arguments to it. There is also a file **services/values.yaml** that describes the default arguments for all the charts in the repository.

In this tutorial we will create a new beamline in a Kubernetes cluster. Here we assume that the cluster is already setup and that there is a namespace configured for use by the beamline. See the previous tutorial for how to set one up if you do not have this already.

:::{note}
DLS users: you should use your personal namespace in the test cluster **Pollux**. Your personal namespace is named after your *fedid*
:::

## Create a new beamline repository

As before, we will use a copier template to create the new beamline repository. The steps are similar to the first tutorial {any}`create_beamline`.

1. We are going to call the new beamline **bl03t** with the repository name **t03-services**. It will be created in the namespace **bl03t** on the local cluster that we created in the last tutorial OR your *fedid* namespace on the **Pollux** cluster if you are using the DLS cluster.

    ```bash
    # make sure your Python virtual environment is active and copier is pip installed
    copier copy gh:epics-containers/services-template-helm t03-services
    code t03-services
    ```

    Answer the copier template questions as follows for your own local cluster:

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
    <b>   </b><font color="#FFAF00"><b>YOUR_GITHUB_USER</b></font>
    <font color="#5F87AF">🎤</font><b> Remote URI of the services repository.</b>
    <b>   </b><font color="#FFAF00"><b>https://github.com/YOUR_GITHUB_USER/t03-services</b></font>
    <font color="#5F87AF">🎤</font><b> URL for centralized logging. For missing platform override logging_url, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>Skip</b></font>
    </pre>

    OR like this for DLS users using the Pollux cluster:

    <pre><font color="#5F87AF">🎤</font><b> Short name for this collection of services.</b>
    <b>   </b><font color="#FFAF00"><b>t03</b></font>
    <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
    <b>   </b><font color="#FFAF00"><b>t03 IOC Instances and Services</b></font>
    <font color="#5F87AF">🎤</font><b> Kubernetes cluster namespace</b>
    <b>   </b><font color="#FFAF00"><b>YOUR_FED_ID</b></font>
    <font color="#5F87AF">🎤</font><b> Name of the k8s cluster where the IOCs and services in this repository will run</b>
    <b>   </b><font color="#FFAF00"><b>pollux</b></font>
    <font color="#5F87AF">🎤</font><b> Apply cluster specific details. For missing platform override cluster_type, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>DLS Cluster</b></font>
    <font color="#5F87AF">🎤</font><b> Default location where these IOCs and services will run. e.g. &quot;bl01t&quot;, &quot;SR01&quot;. Leave blank to configure per IOC.</b>
    <b>   </b><font color="#FFAF00"><b>bl03t</b></font>
    <font color="#5F87AF">🎤</font><b> Git platform hosting this repository. For missing platform override git_platform, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>github.com</b></font>
    <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
    <b>   </b><font color="#FFAF00"><b>YOUR_GITHUB_USER</b></font>
    <font color="#5F87AF">🎤</font><b> Remote URI of the services repository.</b>
    <b>   </b><font color="#FFAF00"><b>https://github.com/YOUR_GITHUB_USER/t03-services</b></font>
    <font color="#5F87AF">🎤</font><b> URL for centralized logging. For missing platform override logging_url, or add your own in a PR.</b>
    <b>   </b><font color="#FFAF00"><b>DLS</b></font>
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

To deploy and manage IOC istances requires helm and kubectl command line tools. However we supply a simple wrapper for these tools that saves typing and helps with learning the commands. This is the `ec` command line tool. Go ahead and add the `ec` python package to your virtual environment.

```bash
# make sure your Python virtual environment is active, then:
pip install ec-cli
# make sure ec is not currently aliased to docker compose
unalias ec
# setup the environment for ec to know how to talk to the cluster
# (make sure you are in the t03-services directory)
source ./environment.sh
```

## Deploy an Example IOC Instance

The new repository has an example IOC that it comes with the template and is called t03-ea-test-01. It is a simple example IOC that is used for testing the deployment of IOCs to the cluster.

For a new beamline we will also need to deploy the shared resources that all IOCs expect to find in their namespace, namely:
- epics-pvcs: some persistent volumes (Kubernetes data stores) for the IOCs to store autosave files, GUI files and other data
- epics-opis: an nginx web server that serves the IOC GUI files out of one of the above persistent volumes

The ec tool can help with version tracking by deploying tagged version of services. So first lets go ahead and tag the current state of the repository.

```bash
# make sure you are in the t03-services directory, then:
git tag 2024.9.1
git push origin 2024.9.1
```

Now you can deploy the shared resources and the example IOC instance to the cluster. Using the version we just tagged. We will use the -v option which shows you the underlying commands that are being run.

```bash
source environment.sh
ec -v deploy epics-pvcs 2024.9.1
ec -v deploy epic-opis 2024.9.1
```

You are now ready to deploy the example IOC instance.

```bash
ec -v deploy t03-ea-test-01 2024.9.1
```

You can check the status of the deployment using:

```bash
ec ps
```

You could also investigate the other commands that `ec` provides by running `ec --help`.

:::{note}
At DLS you can get to a Kubernetes Dashboard for your beamline via a landing page `https://pollux.diamond.ac.uk` for test beamlines on `Pollux` - remember to select the namespace from the dropdown in the top left.

For production beamlines with dedicated clusters, you can find the landing page for example:
`https://k8s-i22.diamond.ac.uk/` for BL22I.
`https://k8s-b01-1.diamond.ac.uk/` for the 2nd branch of BL01B.
in this case the namespace will be ixx-beamline.
:::
