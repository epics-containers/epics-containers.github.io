Working with Support Modules
=============================

.. Warning::

    This tutorial is out of date and will be updated soon.

TODO: this is currently a stub with some pointers.

TODO: suggest that we will make a new Stream Device that will be a
simple echo server. Use this to step through the process of creating a
new support module.

This is a type 3. change from the list at `ioc_change_types`.

If you are starting a new support module then the preceding tutorials
have covered all of the skills you will need.

To work on a new support module you will need a Generic IOC project to
work inside. You could choose to create two new projects:

:MyNewDeviceSupport:

    a traditional EPICS Support module,

:ioc-MyNewDeviceSupport:

    a Generic IOC container definition based on ioc-template

Once you have created the project(s), working on the support module will
look very similar to the procedures set out here `debug_generic_ioc`

