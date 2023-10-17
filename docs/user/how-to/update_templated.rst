Updating Template Based Projects
================================

The tutorials use two template projects as follows:

.. list-table:: Template Projects
    :widths: 30 70
    :header-rows: 1

    * - Template Project
      - Purpose
    * - ioc-template
      - create a new Generic IOC container project
    * - blxxi-template
      - create a new IOC Instance Domain project

The instructions for for making these project used a clone of
the template. The reason for this is that the template projects
may be updated in future to add new features or fix bugs.

Occasionally it may be useful to update your project to use the
latest version of the template. Because your project contains
commits from the original template this can easily be done using
git.

For an ioc-template based project:

.. code-block:: bash

    cd ioc-my-ioc-template-based-project
    git pull git@github.com:epics-containers/ioc-template.git

For an blxxi-template based project:

.. code-block:: bash

    cd ioc-my-ioc-template-based-project
    git pull git@github.com:epics-containers/ioc-template.git.git

The pull command will merge any changes from the template into your
project. You may need to resolve any conflicts.



