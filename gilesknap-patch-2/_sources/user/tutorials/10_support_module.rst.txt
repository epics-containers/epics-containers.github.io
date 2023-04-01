Working with Support Modules
=============================

If you are starting a new support module then the preceding tutorials
have covered all of the skills you will need.

To work on a new support module you will need a generic IOC project to
work inside. You could choose to create two new projects, MyNewDeviceSupport
and ioc-MyNewDeviceSupport, or you could create a single project which looks
like a traditional EPICS Support module and merge in the files from
ioc-template.

Once you have created the project(s), working on the support module will
look very similar to the procedures set out here `08_debug_generic_ioc`


TODO: suggest that we will make a new Stream Device that will be a
simple echo server. Use this to step through the process of creating a
new support module.