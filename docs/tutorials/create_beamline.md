(create-beamline)=

# Create a Beamline Repository

In this tutorial we will create a new {any}`ec-services-repo`.

All IOC Instances that we deploy will be grouped into repositories that define a set of IOC and service instances. Typically each beamline would have its own repository and the accelerator would be split by location or technical area.

In the case of Beamlines, the repo is named after the beamline itself. At DLS
we use the naming convention `blxxc` where `xx` is the beamline number,
and c is the class of beamline.

:::{note}
You may choose your own naming convention, but lower case letters,
numbers and hyphens only are recommended for both domain names and
IOC names. This is a restriction that helm introduces for package names.
:::

Here we are going to create the test beamline repository `bl01t`. When the project `bl01t` is pushed to GitHub, continuous integration (CI) will verify each of the IOC instances.

This beamline repository will be made from a template that comes with a single example IOC and further steps in the following tutorials will teach you how to add your own.

:::{note}
If you are going to work in a shared environment then it is worth choosing
a different name for your test beamline and its associated PV prefixes. PVs
will be published on the local subnet by default so two people working on the
tutorials without doing this will clash. If you do this just remember to
substitute your beamline name for `bl01t` in the following instructions.
:::


## To Start

For this exercise you will require a github user account or organization in
which to place the new repo. If you do not have one then follow GitHub's
[instructions].

Log in to your account by going here <https://github.com/login>.

You will also need to setup ssh keys to authenticate to github from git. See
[about ssh].

(create-new-beamline-local)=
## Create a New Beamline Repo for local deployments

Here we will use the copy the ec services template repository to make a new beamline.

NOTE: for these tutorials we will use your personal GitHub Account to
store everything we do, all source repositories and container images. For
production, each facility will need its own policy for where to store these
assets. See `../explanations/repositories`.

## Steps

1. Go to your GitHub account home page. Click on 'Repositories' and then 'New', give your new repository the name `bl01t` plus a description, then click 'Create repository'.

1. From a command line with your virtual environment activated. Use copier to start to make a new repository like this:

      ```bash
      pip install copier
      # this will create the folder bl01t in the current directory
      copier copy gh:epics-containers/ec-services-template --trust bl01t
      ```
1. Answer the copier template questions as follows:


   <pre><font color="#5F87AF">🎤</font><b> Where are you deploying these IOCs and services?</b>
   <b>   </b><font color="#FFAF00"><b>beamline</b></font>
   <font color="#5F87AF">🎤</font><b> Short name for the beamline, e.g. &quot;bl47p&quot;, &quot;bl20j&quot;, &quot;bl21i&quot;</b>
   <b>   </b><font color="#FFAF00"><b>bl01t</b></font>
   <font color="#5F87AF">🎤</font><b> A One line description of the module</b>
   <b>   </b><font color="#FFAF00"><b>beamline bl01t IOC Instances and Services</b></font>
   <font color="#5F87AF">🎤</font><b> Cluster namespace for these IOCs and services.</b>
   <b>   </b><font color="#FFAF00"><b>local</b></font>
   <font color="#5F87AF">🎤</font><b> Git platform hosting the repository.</b>
   <b>   </b><font color="#FFAF00"><b>github.com</b></font>
   <font color="#5F87AF">🎤</font><b> The GitHub organisation that will contain this repo.</b>
   <b>   </b><font color="#FFAF00"><b>YOUR_GITHUB_NAME_GOES_HERE</b></font>
   <font color="#5F87AF">🎤</font><b> Remote URI of the repository.</b>
   <b>   </b><font color="#FFAF00"><b>git@github.com:YOUR_GITHUB_NAME/bl01t.git</b></font>
   </pre>

1. Make the first commit and push the repository to GitHub.

   ```bash
   cd bl01t
   git add .
   git commit -m "initial commit"
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
git tag 2024.3.1
git push origin 2024.3.1
```

We use `CalVer` version numbers for beamline repositories and Generic IOCs.
This is a versioning scheme that uses the date of release as the version number.
The last digit is the number of the release in that month.

CalVer is described here: <https://calver.org/> and is used where semantic
versioning is not appropriate because the repository contains a mix of
dependencies and does not have a clear API.

Note that 2024.3.1 represents the time that this tutorial was last updated.
For completeness you could use the current year and month instead. You
are also free to choose your own versioning scheme as this is not enforced by
any of the epics-containers tools.

[about ssh]: https://docs.github.com/en/enterprise-server@3.0/github/authenticating-to-github/connecting-to-github-with-ssh/about-ssh
[instructions]: https://docs.github.com/en/get-started/signing-up-for-github/signing-up-for-a-new-github-account
