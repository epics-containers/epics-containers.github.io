3. Use of substitution files to generate EPICS Databases
========================================================

Date: 2023-11-30

Status
------

Accepted

Context
-------

There are two proposals for how EPICS Databases should be generated:

1.  At IOC startup ``ibek`` should generate a substitution file that describes the
    required Databases.

    The IOC instance yaml combined with the definitions from support module yaml
    controls what the generated substitution file will look like.

    ``ibek`` will then execute ``msi`` to generate the Databases from the
    substitution file.

2.  The dbLoadRecord calls in the startup script will pass all macro substitutions
    in-line. Removing the need for a substitution file.


Decision
--------

Proposal 1 is accepted.

Some template files such as those in the ``pmac`` support module use the
following pattern:

.. code-block::

    substitute "P=$(PMAC):, M=CS$(CS):M1, ADDR=1, DESC=CS Motor A"
    include "pmacDirectMotor.template"

This pattern is supported by msi but not by the EPICS dbLoadRecord command which
does not recognise the ``substitute`` command.


Consequences
------------

An extra file ``ioc.subst`` is seen in the runtime directory. In reality this
is easier to read than a full Database file. So can be useful for debugging.

Finally those developers who are unable to use ``ibek yaml`` for some reason can
supply their own substitution file and ibek will expand it at runtime. This is
much more compact that supplying a full Database file and important due to the
1MB limit on K8S ConfigMaps.
