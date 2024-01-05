Things to write about in the coming chapters.
=============================================

ioc_changes1.rst - simple change to an IOC instance
---------------------------------------------------
done

ioc_changes2.rst - simple change to a generic IOC
-------------------------------------------------

Use a fork of ioc-sampledetector
to update the version number of adsimdetector and to add dev-iocstats
(ioc-sampledetector is copy of ioc-adsimdetector with some changes -
deviocstats is removed and it is using an earlier version of adsimdetector
support)

- push and run the CI
- verify a local instance can use resulting image
  - add dev-iocstats and update generic IOC version number
- do a pull request back to ec

ioc_changes3.rst - a change to ibek-support
-------------------------------------------

Add some kind of additional feature into ioc-adsampledetector
maybe something from one of the ADCore plugins

- requires forking and updating ibek-support
- also update ioc-sampledetector to ue the new ibek-support
- verify a local instance can use resulting image
- do a pull request back to ec


generic_ioc.rst - make a new generic IOC
----------------------------------------

This will involve creating a new support module from scratch and
making a generic IOC for it.

The support module will be a very basic stream device.

Note that the generic IOC comes first because it provides the development
environment for the support module.

IMPORTANT: this serves as a how-to for if you already have a support module
and want to make a generic IOC for it.
TODO: maybe it is worth having a seperate how-to for and existing areadetector
support module because this will be a common use case and we can use
ioc-adsimdetector as the template (I made it a template for this reason).

