# The Environment Configuration File

:::{warning}
**DLS users — live deployments:** you do **not** need to create or source an
`environment.sh` for production beamline or accelerator deployments. At DLS the
module system configures `ec` to deploy to the production clusters for you.
Sourcing `environment.sh` is only required for local/standalone work and for
non-DLS clusters.
:::

:::{note}
This page documents the environment variables understood by `ec`
(the [edge-containers-cli](https://epics-containers.github.io/edge-containers-cli/)).

The role of `environment.sh` depends on the project type:

- in **Helm/Kubernetes services repos** and **deployment repos** it sets the
  `EC_*` variables documented below to point `ec` at your cluster;
- in **compose-based services repos** it instead sets up your local
  `docker compose` environment (container engine, `UIDGID`,
  `COMPOSE_PROFILES`, EPICS name servers) and does **not** configure `ec`.

The variables documented on this page are the `ec` ones. For the full `ec`
command reference and a detailed description of each backend, see the
[edge-containers-cli documentation](https://epics-containers.github.io/edge-containers-cli/).
:::

`environment.sh` is a configuration file that is provided in each domain
(beamline or accelerator) repository. It is sourced to set up your shell so
that `ec` interacts with the correct services repository and deployment
target (a Kubernetes cluster, an ArgoCD instance, or a local demo).

An important part of creating a new domain repository is to edit
`environment.sh` so that it suits the domain you are targeting.

There are 3 sections to the file as follows:

## Environment Variables Setup

The first section defines a number of environment variables. These should be
adjusted to suit your domain. Every variable can also be supplied as a command
line option (for example `EC_TARGET` ↔ `ec -t/--target`), and you can print
the values `ec` is currently using with:

```bash
ec env
```

The three variables you normally set for each domain are:

| Variable | Sets | Example |
| :--- | :--- | :--- |
| `EC_SERVICES_REPO` (`ec -r/--repo`) | the services repository that defines this domain; `ec` fetches a git-tagged copy of an instance's configuration from here at deploy time | `https://github.com/<your-org>/t02-services` |
| `EC_TARGET` (`ec -t/--target`) | where `ec` deploys — the Kubernetes **namespace** (`K8S` backend) or `app-namespace/root-app` (`ARGOCD` backend) | `t02-beamline` or `t02-beamline/t02` |
| `EC_CLI_BACKEND` (`ec -b/--backend`) | which backend `ec` drives: `ARGOCD` (the default), `K8S` or `DEMO`; the available commands change per backend — see {ref}`helm` | `K8S` |

`ec` understands several more variables — for backend authentication
(`EC_LOGIN`), historical logs (`EC_LOG_URL`), logging verbosity
(`EC_LOG_LEVEL`) and diagnostics (`EC_VERBOSE`, `EC_DRYRUN`, `EC_DEBUG`).
Rather than duplicate the catalogue here, see the
[edge-containers-cli environment-variables reference](https://epics-containers.github.io/edge-containers-cli/reference/environment-variables.html)
for the full list, each variable's command-line flag and its default.

## Installation of `ec`

The second section of the `environment.sh` file installs the `ec` command from
the `edge-containers-cli` package. The recommended approach is to install `ec`
globally on your workstation (and then omit this section from your
`environment.sh` files).

The simplest way is to install `ec` as a `uv` tool (DLS users can obtain `uv`
with `module load uv`):

```bash
uv tool install edge-containers-cli
```

Then add the following to your `$HOME/.bashrc` (or `$HOME/.zshrc` for zsh users):

```bash
PATH=$PATH:$HOME/.local/bin
```

## Connecting to a Namespace on your Kubernetes Cluster

The third section of the `environment.sh` sets up how the `kubectl` command
will connect to a namespace on your Kubernetes cluster. This usually involves
setting the `KUBECONFIG` environment variable to point to a file that contains
the cluster configuration.

When we set up a cluster in the tutorials we will create a namespace for you
and discuss how to update `environment.sh` to connect to it.

If you are connecting to your own facility's cluster then you will need to ask
your admins for the correct configuration.

If you are not deploying to Kubernetes (for example when using the `DEMO`
backend or a local compose project) then you can leave this section out.

:::{note}
**DLS users:** the module system connects you to each beamline/accelerator
cluster, so you normally do not edit this section by hand. Your cluster
services repo (for example `t02-services`, generated from
[services-template-helm](https://github.com/epics-containers/services-template-helm))
ships an `environment.sh` that shows the pattern, including shell completion for
the Kubernetes tools `kubectl` and `helm`. See the
[DLS developer guide](https://dev-guide.diamond.ac.uk/epics-containers/) for the
module commands specific to Diamond.
:::
