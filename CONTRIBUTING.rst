Contributing
============

Contributions and issues are most welcome! All issues and pull requests for
the documentation or for the ideas expressed in the epics-containers
organization are handled through github on the `k8s-epics-docs repository`_.

Report issues for generic iocs etc. in their own repos.

.. _k8s-epics-docs repository: https://github.com/epics-containers/k8s-epics-docs/issues

Running the tests
-----------------

This module contains no code but running the tests does verify the sphinx
documentation.

To get the source source code and run the unit tests, run::

    $ git clone git://github.com/epics-containers/k8s-epics-docs.git
    $ cd k8s-epics-docs
    $ pipenv install --dev
    $ pipenv run tests

Code Styling
------------

This documentation module currently has no code but the style applies to any
python modules in the epics-containers organization.

The code in this repository conforms to standards set by the following tools:

- black_ for code formatting
- flake8_ for style checks
- isort_ for import ordering
- mypy_ for static type checking

.. _black: https://github.com/psf/black
.. _flake8: http://flake8.pycqa.org/en/latest/
.. _isort: https://github.com/timothycrosley/isort
.. _mypy: https://github.com/python/mypy

These tests will be run on code when running ``pipenv run tests`` and also
automatically at check in. Please read the tool documentation for details
on how to fix the errors it reports.

Documentation
-------------

Documentation is contained in the ``docs`` directory and extracted from
docstrings of the API.

Docs follow the underlining convention::

    Headling 1 (page title)
    =======================

    Heading 2
    ---------

    Heading 3
    ~~~~~~~~~


You can build the docs from the project directory by running::

    $ pipenv run docs
    $ firefox build/html/index.html

The documentation is automatically built and published on github pages when
this repo is pushed to main or with a tag.

See https://epics-containers.github.io/k8s-epics-docs/

