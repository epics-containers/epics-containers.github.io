Source and Registry Locations
=============================

.. note::

    **DLS Users** DLS is currently using these locations for assets:

    - Generic IOC Source: ``https://github.com/epics-containers<Generic ioc>``
    - Beamline Source repos: ``https://gitlab.diamond.ac.uk/controls/containers/beamline/<beamline>``
    - Accelerator Source repos: ``https://gitlab.diamond.ac.uk/controls/containers/accelerator/<domain>``
    - Generic IOC Container Images: ``ghcr.io/epics-containers/<Generic ioc>``
    - epics-containers Helm Charts: ``https://github.com/orgs/epics-containers/packages?repo_name=ec-helm-charts``

Where to Keep Source Code
-------------------------

There are two main kinds of source repositories used in epics-containers:

- Generic IOC Source
- Beamline / Accelerator Domain IOC Instance Source

Generic IOC Source Repositories
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For Generic IOCs it is recommended that these be stored in public repositories
on GitHub.  This allows the community to benefit from the work of others and
also contribute to the development of the IOC.

The intention is that a Generic IOC container image is a reusable component
that can be used by multiple IOC instances in multiple domains. Because
Generic IOCs are containerized and not facility specific, they should work
anywhere. Therefore these make sense as public repositories.

There may be cases where the this is not possible, for example if the
Generic IOC relies on proprietary support modules with restricted licensing.

The existing Continuous
Integration files for Generic IOCs work with GitHub actions, but also
can work with DLS's internal GitLab instance (this could be adapted for
other facilities' internal GitLab instances or alternative CI system).

IOC Instance Domain Repositories
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These repositories are very much specific to a particular domain or beamline
in a particular facility. For this reason there is no strong reason to make
them public, other than to share with others how you are using epics-containers.

At DLS we have a private GitLab instance and we store our domain Repositories
there.

The CI for domain repos works both with GitHub actions and with DLS's internal
GitLab instance (this could be adapted for
other facilities' internal GitLab instances or alternative CI system).

BL45P
~~~~~

The test/example beamline at DLS for epics-containers is BL45P.
The domain repository for this
is at https://github.com/epics-containers/bl45p. This will always be
kept in a public repository as it is a live example of a domain repo.

Where to put Registries
-----------------------

Generic IOC Container Images and Source Repos
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Usually GHCR but internal supported for license e.g. Nexus Repository Manager

IOC Instance Domain Repos
~~~~~~~~~~~~~~~~~~~~~~~~~

Internal git registry or private GitHub registry.

