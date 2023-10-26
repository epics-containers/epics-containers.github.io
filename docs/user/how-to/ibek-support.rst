Updating and Testing ibek-support
=================================

.. Warning::

    This is draft only and out of date. It will be updated soon.

The ibek-defs repository contains ibek support yaml. Here is an example
procedure for local testing of changes to support yaml in ibek-defs
along side IOC yaml that uses it.

(Suggest you do this inside a dev-e7 workspace devcontainer)

.. code-block:: bash

    cd my-workspace-folder

    # clone ibek-defs
    git clone git@github.com:epics-containers/ibek-defs.git
    # clone an example domain repo with example IOC yaml
    git clone git@gitlab.diamond.ac.uk:controls/containers/accelerator/acc-psc.git

    # get latest ibek installed
    pip install ibek

    cd acc-psc/iocs/sr25a-ioc-01
    ibek build-startup config/ioc.boot.yaml ../../../ibek-defs/*/*.yaml

This will get ibek generate a startup script and database generation script
in the config folder. It uses config/ioc.boot.yaml as the description of
the IOC 'entities' to instantiate and all of the support yaml files
in ibek-defs as a source of the definitions of the classes of entities
available.

The example currently uses the timingtemplates definitions only.

Note that at present ibek generates a script of msi invocations instead
of a substitution file. This will be changed in the future.
