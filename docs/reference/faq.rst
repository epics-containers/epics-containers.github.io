Frequently Asked Questions
==========================

Why have ioc-XXX repositories?
------------------------------
Why not put the Dockerfile and image generating in the support module itself
instead of creating a separate generic ioc module for each image we
generate?

Answers:

  - There is not always a 1-1 relationship between support modules and generic
    IOCs. A generic IOC image is free to add any number of support modules it
    requires.

  - The lifecycle of a support module will often differ from a generic IOC.
    The version number of the image is tied to the ioc-XXX source repo that
    generates, so we can have separate versions for support and IOC.

  - Not all users of a support module will need images generated and it is
    counter productive for them to be required to fix the Dockerfile when
    they are working on changes to a support module.
