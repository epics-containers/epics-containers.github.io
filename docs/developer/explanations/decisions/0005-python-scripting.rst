2. Use Python for scripting inside and outside containers
=========================================================

Date: 2022-11-30

Status
------

Accepted

Context
-------

Inside the container, we use the ``ibek`` tool for scripting. Outside we
use ``ec`` from ``epics-containers-cli``.

Much of what these tools do is
call command line tools like ``docker``, ``helm``, ``kubectl``, compilers,
etc. This seems like a natural fit for bash scripts.

These features were originally implemented in bash but were converted to
python for the following reasons:

- python provides for much richer command line arguments
- it is also much easier to provide rich help
- managing errors is vastly improved with exception handling
- the unit testing framework allows for 85% coverage in continuous integration
- complex string handling is a common requirement and is much easier in python
- there is a clear versioning strategy and packages can be installed with pip,
  meaning that you can check which version of the script you are running and
  report bugs against a specific version
- the code is much easier to read and maintain
- because the packages can be pip installed they can be used in CI and inside
  multiple containers without having to copy the scripts around

Decision
--------

We always prefer Python and keep bash scripts to a minimum

Consequences
------------

Scripting is much easier to maintain and is more reliable.
