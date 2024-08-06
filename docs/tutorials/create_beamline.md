(create-beamline)=

# Create a Beamline Repository

In this tutorial we will create a new {any}`services-repo`.

All IOC Instances that we deploy will be grouped into repositories that define a set of IOC and service instances. Typically each beamline would have its own repository and the accelerator would be split by technical area.

In the case of Beamlines, the repo is named after the beamline itself. At DLS
we use the naming convention `cxx` where `xx` is the beamline number,
and c is the class of beamline. Our naming convention for beamline services repositories is
cxx-services.

:::{note}
You may choose your own naming convention, but lower case letters,
numbers and hyphens are the only characters allowed for both domain names and
IOC names. This is a restriction that helm introduces for package names.
:::

Here we are going to create the test beamline repository `t01-services`. When the project is pushed to GitHub, continuous integration (CI) will verify each of the IOC instances.

This beamline repository will be made from a template that comes with a single example IOC and further steps in the following tutorials will teach you how to add your own.

:::{note}
If you are working is a shared environment you need not create a unique beamline name or PV prefix because the example runs with all PVs published on localhost only. Your example beamline will be isolated from other users on the same network.
:::

## To Start

For this exercise you will require a github user account or organization in which to place the new repo. If you do not have one then follow GitHub's [instructions].

Log in to your account by going here <https://github.com/login>.

You will also need to set up ssh keys to authenticate to Github from git. See [about ssh].

(create-new-beamline-local)=
## Create a New Beamline Repo for local deployments

Here we will use a services template repository to make a new beamline.

NOTE: for these tutorials we will use your personal GitHub Account to store everything we do, all source repositories and container images. For production, each facility will need its own policy for where to store these assets. See {any}`../explanations/repositories`.

## Steps

1. Make sure you have activated the python virtual environment and that `copier` is installed. See instructions here: {any}`ec`.

1. Use copier to copy the services template repository to a new repository named `t01-services`. Note that there are two services templates, one for local deployments (using docker compose) and one for deployments to Kubernetes. We will use the local deployment template here.

   ```bash
   copier copy gh:epics-containers/services-template-compose t01-services
   ```

1. Answer the copier template questions with their default values as follows:

   <pre><font color="#75507B">hgv27681</font>@<font color="#C4A000">pc0116</font>: <font color="#729FCF"><b>/scratch/hgv27681/work</b></font>
   $ copier copy gh:epics-containers/services-template-compose t01-services                                                                                     <font color="#4E9A06">[10:47:49]</font>
   This template will create a new repository for deploying IOCs and services to
   the local machine using docker compose.

   <font color="#5F87AF">🎤</font><b> Short name for the collection of services, e.g. &quot;t01&quot;, &quot;p47&quot;, &quot;i20-1&quot;, &quot;i21&quot;</b>
   <b>   </b><font color="#FFAF00"><b>t01</b></font>
   <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
   <b>   </b><font color="#FFAF00"><b>t01 IOC Instances and Services</b></font>

   Copying from template version 3.5.0
   <font color="#06989A"> ... </font>
   </pre>

1. Create your new repository on GitHub in your personal space by following this link <https://github.com/new>. Give it the name t01-services and a description of "t01 IOC Instances and Services". Then click "Create repository".

Now copy the ssh address of your new repository from the GitHub page.

:::{figure} ../images/copy_gh_repo_addr.png
copying the repository address from GitHub
:::

1. Make the first commit and push the repository to GitHub.

   ```bash
   cd t01-services
   git init -b main
   git add .
   git commit -m "initial commit"
   git remote add origin >>>>paste your ssh address here<<<<
   git push -u origin main
   ```

1. Open the project in vscode.

   ```bash
   # DLS users make sure you have done: module load vscode
   code .
   ```

## Wrapping Up

You should now have a working beamline repository. It contains a single IOC Instance which is a very basic example. In the following two tutorials we will investigate the example and then create a real IOC Instance.

You can now give your repository a version tag like this:

```bash
# open a terminal in vscode: Menu -> Terminal -> New Terminal
git tag 2024.9.1
git push origin 2024.9.1
```

We use `CalVer` version numbers for beamline repositories and Generic IOCs.
This is a versioning scheme that uses the date of release as the version number.
The last digit is the number of the release in that month.

CalVer is described here: <https://calver.org/> and is used where semantic
versioning is not appropriate because the repository contains a mix of
dependencies and does not have a clear API.

Note that 2024.9.1 represents the date that this tutorial was last updated.
For completeness you could use the current year and month instead. You
are also free to choose your own versioning scheme as this is not enforced by
any of the epics-containers tools.

[about ssh]: https://docs.github.com/en/enterprise-server@3.0/github/authenticating-to-github/connecting-to-github-with-ssh/about-ssh
[instructions]: https://docs.github.com/en/get-started/signing-up-for-github/signing-up-for-a-new-github-account
