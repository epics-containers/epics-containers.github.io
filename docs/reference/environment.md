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
The `environment.sh` file that sets them differs slightly between project
types (services-using-compose, services-using-helm, and deployment repos),
but the variables themselves are the same.

For the full `ec` command reference and a detailed description of each
backend, see the
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

The variables are as follows:

### Commonly set variables

- **EC_SERVICES_REPO**: a link to the services repository that defines this
  domain, for example
  `EC_SERVICES_REPO=https://github.com/epics-containers/example-services`.
  `ec` uses this to fetch a versioned (git-tagged) copy of an IOC instance's
  configuration at deploy time. (`ec -r/--repo`.)

- **EC_TARGET**: where `ec` deploys to. Its meaning depends on the backend:

  - for the `K8S` backend it is the Kubernetes **namespace** your IOC
    instances are deployed to, e.g. `EC_TARGET=t01`;
  - for the default `ARGOCD` backend it is `app-namespace/root-app` — the
    namespace that hosts ArgoCD together with the name of the root
    (app-of-apps) Application, e.g. `EC_TARGET=t01-beamline/root`.

  (`ec -t/--target`.)

- **EC_CLI_BACKEND**: selects which backend `ec` drives. One of `ARGOCD`
  (the default), `K8S`, or `DEMO`. The set of available commands and options
  changes per backend — see [](helm). (`ec -b/--backend`.)

### Optional variables

- **EC_LOGIN**: an optional command that `ec` runs to authenticate to the
  cluster/backend before performing an operation. Leave unset if your shell is
  already authenticated (for example via `KUBECONFIG`, see below).

- **EC_LOG_URL**: if you have a centralized logging service with a web UI then
  you can set this variable to the URL of the web UI. It is displayed by
  `ec log-history <service>`. The service name is inserted into the URL using
  the `{service_name}` placeholder, e.g.

  - `EC_LOG_URL='https://graylog2.diamond.ac.uk/search?rangetype=relative&fields`
    `=message%2Csource&width=1489&highlightMessage=&relative=172800&q=pod_name%3A`
    `{service_name}*'`

- **EC_LOG_LEVEL**: sets the logging verbosity of `ec` itself. One of `DEBUG`,
  `INFO`, `WARNING`, `ERROR`, `CRITICAL`.

- **EC_VERBOSE**: print each external command (git, kubectl, helm, argocd) that
  `ec` runs. Equivalent to `ec -v/--verbose`.

- **EC_DRYRUN**: print the external commands that `ec` would run without
  executing them. Equivalent to `ec --dryrun`.

- **EC_DEBUG**: causes `ec` to output debug information (including Python
  tracebacks) for all commands. For more targeted debugging you can use
  `ec -d ...`.

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
DLS users: the module system is used to connect us to each beamline/accelerator
cluster. The example `environment.sh` file in
[example-services](https://github.com/epics-containers/example-services/blob/main/environment.sh)
shows how to do this, including how to set up command line completion for the
Kubernetes tools `kubectl` and `helm`.
:::
