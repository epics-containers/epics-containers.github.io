Change Log
==========

Each individual repository in the `epics-containers` GitHub Organization will have its own changelog. This page is intended for users of `epics-containers` who are adopting the next versions of the templates into their services projects or generic IOC projects. See [](../explanations/changes) for a discussion of how changes are managed in this framework.

blxxi-ea-test-01
----------------

The `ec-services-template` creates beamline (or other IOC grouping) repostories that initially contain an example IOC and set of essential services. The example IOC will be called `blxxi-ea-test-01` and could be used to deploy a sim-detector.

It is quite useful to keep this example because if you do so it can be used to easily see what changes to each IOC instance might need to be made. The copier template will attempt to update all your own IOC Instances. But the reliable way to keep them up to date is to verify that they have the same changes as the example.

Such changes will be rare but it just happens that 3.4.0 is an example of this. See below.

April 2024 - templates 3.4.0
----------------------------

### ioc-template and ec-services-template

- `dependabot.yaml` no longer looks for changes in docker or python dependencies from your ioc-xxx projects. The philosophy here is that all dependency updates should happen in a controlled manner via the copier update mechanism. TODO: it would be good to have dependabot monitor the copier template updates, but this is not currently possible.

### ioc-template

- The significant change here is that the CI is now multi target and supports cross compilation to RTEMS-beatnik as well as native linux x86. The template has a new question that asks if you want RTEMS support, you should select no unless your Generic IOC is intended for this target architecture.


### ec-services-template

- The mechanism by which the configmap of each IOC's config folder has changed. It now requires that there is a `templates` folder in each IOC instance folder that is a soft link to ../../include/ioc/templates. Although the template includes a migration script that is supposed to do this, it has not always proved to work. To create these folders yourself, the easiest way is to copy and paste from the blxxi-ea-test-01 IOC instance.
