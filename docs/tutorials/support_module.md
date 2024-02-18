# Working with Support Modules

:::{Warning}
This tutorial is an early draft and is not yet complete.
:::

This is a type 3. change from the list at {any}`ioc-change-types`.

In the tutorial on {doc}`/tutorials/generic_ioc`, we created a new Generic IOC container image that wrapped the existing support module `lakeshore340`.

If you wanted to create a completely new support module then you would use a very similar workflow to the above.

In brief, the steps are:

- Create a new Generic IOC project using the <https://github.com/epics-containers/ioc-template>
- Create a new folder in /workspaces/YOUR_SUPPORT_MODULE_NAME
- Link the new folder to the epics support folders:
  - ln -s /workspaces/YOUR_SUPPORT_MODULE_NAME /epics/support/YOUR_SUPPORT_MODULE_NAME
  - TODO the ibek command `ibek dev support YOUR_SUPPORT_MODULE_NAME` will do this in future
- Now work on your support module and get it compiling
- Then add `ibek-support` for the new module as per {doc}`/tutorials/generic_ioc`
- create an example instance in the Generic IOC project to test your work
- When ready, push your new support and new ioc-support projects.
