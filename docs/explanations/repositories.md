# Source and Registry Locations

:::{note}
**DLS Users** DLS is currently using these locations for assets:

- Public Generic IOC Source:   <https://github.com/epics-containers/>
- Private Generic IOC Source:  <https://gitlab.diamond.ac.uk/controls/containers/iocs>
- Beamline Source repos:       <https://gitlab.diamond.ac.uk/controls/containers/beamline/>
- Accelerator Source repos:    <https://gitlab.diamond.ac.uk/controls/containers/accelerator/>
- Generic IOC Container Images: ghcr.io/epics-containers
- epics-containers Helm Charts:<https://github.com/orgs/epics-containers/packages?repo_name=ec-helm-charts>
:::

## Where to Keep Source Code

There are two main kinds of source repositories used in epics-containers:

- Generic IOC Source
- Beamline / Accelerator Services Repositories for IOC instances and other services.

### Generic IOC Source Repositories

For public Generic IOC container images, the GitHub Container Registry is a good choice. It allows the containers to live at a URL related to the source repository that generated them. The default ioc-template comes with Github Actions that build the container and push it to the GitHub Container Registry.

The intention is that a Generic IOC container image is a reusable component
that can be used by multiple IOC instances in multiple domains. Because
Generic IOCs are containerized and not facility specific, they should work
anywhere. Therefore these make sense as public repositories.

There may be cases where this is not possible, for example if the
Generic IOC relies on proprietary support modules with restricted licensing.

The existing Continuous
Integration files for Generic IOCs work with GitHub actions, but also
can work with DLS's internal GitLab instance (this could be adapted for
other facilities' internal GitLab instances or alternative CI system).

### IOC Services Repositories

These repositories are very much specific to a particular domain or beamline
in a particular facility. For this reason there is no strong reason to make
them public, other than to share with others how you are using epics-containers.

At DLS we have a private GitLab instance and we store our Services Repositories
there.

The CI for domain repos works both with GitHub actions and with DLS's internal
GitLab instance (this could be adapted for
other facilities' internal GitLab instances or alternative CI system).

### p45-services

The test/example beamline at DLS for epics-containers is p45.
The domain repository for this is at <https://github.com/epics-containers/p45-services>. This will always be kept in a public repository as it is a live example of a domain repo.

This beamline is deployed to Kubernetes at DLS using Argo CD continuous deployment. The repository containing the Argo CD apps that control the deployment is at <https://github.com/epics-containers/p45-deployment>
