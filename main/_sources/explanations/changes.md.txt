Change Management Manifesto
===========================

Pledge
------

This page represents a pledge to control breaking changes for users of `epics-containers`. The framework is still under development and there still may be breaking changes in future updates. However we now have a mechanism in place to allow users to adopt the framework, take advantage of the current features and then accept future updates in a controlled fashion.

From version 3.4.0 onwards we will make changes in a controlled fashion that obeys SemVer 2.0.0 rules. We will also ensure that it is possible to apply updates in a gradual manner and not require a blanket update.

The [](../reference/changelog.md) will give details of any things to be aware of between versions, including minor version updates.

Dependency Matrix
-----------------

Users of the framework will develop two kinds of repository:

|     |     |
| --- | --- |
| Beamline repo | A beamline or other grouping of IOC instance descriptions |
| Generic IOC repo | A definition of a generic IOC container image for a particular class of device |

Both of these types of repository are initially created using a copier template. The copier template version will have a SemVer version number that determines which component versions it is compatible with.

For a discussion on how to update your projects to the latest version of the templates see [](../how-to/copier_update).

Any breaking changes to the framework will be made in a new Major version of the framework and hence a new Major version of the copier templates.

The following diagram shows the set of components that are involved in the framework and the relationships between them. The dependencies between these components are not a strict API and the diagram attempts to highlight the features of each component that affect other components.

The diagram may be used by developers of the framework to plan how changes will be made and to ensure that breaking changes are made in a controlled manner.

Users of the framework are only concerned with the top two boxes and these are always updated on an as-needed basis via the copier templates.

:::{figure} ../images/dependency_matrix.png
`epics-containers` dependency matrix
:::

All `ec` SemVer components will always have their major version bumped simultaneously. Likewise for `ibek` SemVer components. These are at versions 3.4.0 and 2.0.0 respectively at the time of writing.


Updating user projects
----------------------

A repository that was originally created using a copier template can be updated to a new version using the following command (assumes you have an active python venv with copier installed):

```bash
copier update -r VERSION_NUMBER --trust .
```

You can supply the VERSION_NUMBER of the template you want or omit the -r option to get the latest released version.

This will update your project in place. You should then inspect the changes using git (the source control pane in vscode is excellent for this purpose) and commit them to your repository.

When a beamline repository is updated, it is still possible to deploy old versions of its IOC instances, even with a major version difference. That is because the deploy mechanism makes a temporary clone of the beamline repository and deploys the instance described in that version.

User Project Versioning
-----------------------

The documentation has recommended using DateVer for beamline repos and generic IOC repos. This is because SemVer is not really applicable to these. However, DateVer is not required and you are free to use any scheme you wish for these repositories.

It is easy to determine which template version and thus which `ec` SemVer version your repository was last updated from. Inspect the file `.copier_answers.yml` in the root of your repository. This file contains the version of the template that was used to create the repository in the field `_commit`.


Types of Changes
----------------

Changes to the framework are likely to be initiated in one of the places described under the following headings. As far as possible such changes will be backwards compatible going forward, and if they are not then a major version release will be made.

### ibek


Changes to the CLI commands inside of the container build/runtime are initiated in the `ibek` python module that lives inside every generic IOC. This can affect the support module build recipes in `ibek-support` and potentially the Dockerfile in Generic IOC projects.

### ec-helm-charts

Changes here affect how IOCs and other services are deployed into Kubernetes. These would likely affect beamline repositories as they contain the versions of Helm Charts used to deploy their instances. Potentially changes to these Charts may require an update to the edge-services-cli to support new features.

### ioc-template

The Generic IOC template is well established and stable. However, each time a new target architecture is added, this will need updates to the CI. We will be supporting Windows and ARM targets in future. These changes should certainly be backwards compatible and not affect existing projects.


### ibek-support

`ibek-support` is a unique project in that it is a submodule of all Generic IOCs. It is expected that there will be constant change to this module as new support modules are added. However, such changes will almost entirely be adding new folders and not affect existing generic IOCs. We encourage users to fork this repository, add their own support modules and submit PRs back to the original so that a wide range of support modules can be shared (a branch rather than fork is preferred for internal developers).

If there is a need to change the CLI that ibek-support uses, then a new version of `ibek` will be released. Only generic IOCs that have been updated to pick up the new version of `ibek` would be able to use these changes. Because older generic IOCs will retain the old commit of the 'ibek-support' submodule, they will not be affected by the changes until they are updated.
