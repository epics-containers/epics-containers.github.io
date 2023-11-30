4. How to configure autosave for IOCs
=====================================

Date: 2023-11-30

Status
------

Accepted

Context
-------

There is a choice of supplying the list of PVs to autosave by:

- adding info tags to the Database Templates
- supplying a raw req file with list of PVs to autosave

Decision
--------

We will go with req files for the following reasons:

- https://epics.anl.gov/tech-talk/2019/msg01600.php
- adding info tags would require upstream changes to most support modules
- default req files are already supplied in many support modules
- req files are in common use and many facilities may already have their own
  req files for support modules.

We expect to autogenerate the list of PVs to autosave from the IOC's. We could
therefore generate a Database override file which adds info tags. But it is
simpler to just generate a req file.

The mechanism for using req files is that defaults will come from the support
module or from the generic IOC if the support module does not supply a req file.

Then override files can exist at the beamline level and / or at the IOC
instance level. These will simply take the form of a req file with the same
name as the one it is overriding.

Consequences
------------

Everything is nice and simple.

