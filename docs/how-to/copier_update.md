Updating User Repositories with Copier
======================================

In the tutorials we created an example beamline repo and also an example generic IOC. In both cases we used the copier tool to create these projects from a template.

This tool can also be used to merge in the latest changes to the framework into your existing projects. This is done by running the `copier update` command in the root of your project.

Below are some details on how to use this tool.

Introduction
------------

copier is a python package. To make use of it you require an activated python virtual environment with copier installed. If you don't already have one of these then the following commands will set one up for you:

```bash
python3 -m venv venv
source venv/bin/activate
pip install copier
```

NOTE: generic IOCs with a given major version number template should work with beamline repos with the same major version number template. When updating a beamline repo to a new major version, you may also need to update the generic IOCs it references. If this is the case it will be noted in [](../reference/changelog.md). Having said this, the two types of repo are reasonably well decoupled and we would aim to avoid this necessity. In which case update the beamline repo first and then the generic IOCs as and when new features are required.

Updating a Beamline Repository
------------------------------

A beamline (or other grouping) repository is a collection of IOC instances and services that are deployed together. The beamline repository is created using the `services-template-helm` copier template. See [](../tutorials/create_beamline.md) for the tutorial on how to create a new beamline repository.

To update your beamline repository to the latest version of the templates you should run the following command in the root of your repository:

```bash
copier update -r VERSION_NUMBER .
```

You can supply the VERSION_NUMBER of the template you want or omit the `-r` option to get the latest released version.

This will update your project in place. You should then inspect the changes using git (the source control pane in vscode is excellent for this purpose) and commit them to your repository. Once you are happy with the changes you can test them by re-deploying some of your IOC instances. When everything is working you can push the changes to your repository.

For example, in version 3.4.0 the `services-template-helm` changed the way that the configmap is created for each IOC instance. This added a soft-link **templates** folder that points at **../../include/ioc/templates**. Looking at what changes happened in the example IOC will help you to understand what changes you might need to make in your own IOC instances. Copier migrations will attempt to make these changes for you but it is recommended to check that they have been done correctly.


Updating a Generic IOC Repository
---------------------------------

To see details of how to initially create a generic IOC repository see {any}`create_generic_ioc`.

To update your generic IOC repository to the latest version of the templates you should run the following command in the root of your repository:

```bash
copier update -r VERSION_NUMBER --trust .
```

Typically the only file that the user will have changed is the Dockerfile and typically merges will work well. It is still a good idea to validate the changes to the repo before committing them.

When Update fails
-----------------

Copier cannot do the 'update' command if any of the following is true:

- Your repo pre-dates the use of copier
- The copier template version that you last used is no longer available.

In this case you can still do an update using the 'copy' command - you just need to be more careful with the merge.

For the generic IOC case:

```bash
copier copy https://github.com/epics-containers/ioc-template --trust .
```

For the beamline case:

```bash
copier copy https://github.com/epics-containers/services-template-helm .
```

In both cases you should select Y for each notice of a conflict, then resolve those conflicts in your editor.

Using copy will mean that you get asked the template questions again, but copier is smart enough to supply your previous answers as defaults (if your repo predates copier then you will need to answer all the questions for the first time).

The difference from 'update' is that you will need to do the merge yourself. For example in a generic IOC you will want to restore your support module instantiations in the middle of the Dockerfile, whereas the top and bottom of the Dockerfile should be updated by the template. Using vscode's SOURCE CONTROL pane is useful for this. The following image is an example of a Dockerfile merge:

:::{figure} ../images/dockerfile_merge.png
merging a Dockerfile after a copy copy
:::

In the above example the **copier copy** has made many changes to the repo. Because the only user supplied change is the list of support modules in the middle of the Dockerfile, the merge is simple. Using vscode you just need to click button indicated by the red arrow, save your changes, then:

```bash
# from the root of the repo
git add .
git commit -m'update to template version 3.4.0'
git push
```
