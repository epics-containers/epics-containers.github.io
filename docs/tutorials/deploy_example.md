# Deploy and Manage IOC Instances Locally

This tutorial deploys and manages the IOC instance and services in your
`t01-services` repo on your workstation with `docker compose` — no Kubernetes
required. This local path is ideal for
development and testing, and is a valid production option for sites that run
IOCs on standalone servers. For the cluster-based GitOps path, see
{any}`deploy-argocd`.

You will deploy and manage the example IOC and services in the `t01-services`
repo you created in {any}`create-beamline`. Substitute your own services
repository and service names throughout.

:::{note}
`environment.sh` sets up your local `docker compose` environment (container
engine, `UIDGID`, `COMPOSE_PROFILES`, EPICS name servers). See
{any}`../reference/environment` for the full list of what it can set in each
kind of repository.
:::

(setup-beamline-t01)=
## Set up the environment

From the root of the services repo, source its environment file:

```bash
cd t01-services
source ./environment.sh
```

This is the standard way to prepare your shell for any epics-containers services
repo. For the local `docker compose` track it:

- selects podman or docker as the container engine and sets `UIDGID` for the
  phoebus container's X11 access;
- sets `COMPOSE_PROFILES=test` so `docker compose` launches the
  developer-workstation profile (IOCs, gateways and an OPI viewer);
- points Channel Access and PV Access at the gateways on localhost
  (`EPICS_CA_NAME_SERVERS=127.0.0.1:9064`) so host tools can see the
  containerised PVs.

(deploy-example-instance)=
## Deploy the services

Bring up every service defined in the repo's `compose.yaml`:

```bash
docker compose up -d
```

`up` creates and starts the services; `-d` detaches and runs them in the
background — omit it to follow the colour-coded combined logs instead. The first
run is slow while images download from the GitHub container registry; later runs
start from the local cache.

Check what is running:

```bash
docker compose ps
```

Among the running services you should see the example IOC (`example-test-01`),
the Channel Access and PV Access gateways, the `epics-opis` OPI web server, the
`phoebus` OPI viewer, and a one-shot `init` container that generates the PV
Access gateway and phoebus config and then exits.

## Start and stop a service

Each service is managed by name; `docker compose ps -a` also lists stopped ones:

```bash
docker compose stop example-test-01
docker compose ps -a
docker compose start example-test-01
```

:::{note}
Tab completion expands service names: `docker compose start example-test<tab>`
completes to `docker compose start example-test-01`.
:::

:::{note}
**Generic IOCs.** `docker compose ps` shows `example-test-01` running the image
`ghcr.io/epics-containers/ioc-template-example-runtime:3.5.1`. Every IOC instance
is built on a *Generic IOC* image like this; the instance only adds its
`config/` folder. This particular Generic IOC carries just `devIocStats` support,
enough to serve records from a database file. See {any}`generic_ioc`.
:::

## Explore an IOC instance

Open a shell inside the running IOC container and read one of its PVs:

```bash
docker compose exec example-test-01 bash
caget EXAMPLE:SUM
```

Because this is a runtime image you see only binaries and generated files, not
source:

| Path | Contents |
|---|---|
| `/epics/ioc` | Generic IOC binary and `start.sh` |
| `/epics/ioc/config` | this instance's config (`ioc.yaml`, `ioc.db`) |
| `/epics/runtime` | `st.cmd` and database generated at startup |
| `/epics/support` | support modules |
| `/epics/epics-base` | EPICS base |

A shell inside the container gives you the EPICS command-line tools (`caget`,
`caput`, `pvget`, ...) without installing EPICS on your host — your only
requirement is a container engine.

## Follow the logs

These `docker compose` commands run on your **host**, not inside the IOC
container. If you are still in the container shell from the previous step, exit
it first (`exit` or `ctrl-d`) or open a new terminal at the `t01-services` repo
root — a new shell needs `source ./environment.sh` again before `docker
compose` will work:

```bash
docker compose logs example-test-01 -f      # ctrl-c to stop following
```

At startup you will see `ibek` generate the IOC's `st.cmd` and database from
`/epics/ioc/config/ioc.yaml` (via `ibek runtime generate2`), followed by the
iocShell output.

## Attach to the IOC shell

Attach to the live iocShell to run iocsh commands:

```bash
docker compose attach example-test-01
dbl                 # list this IOC's records
# ctrl-p ctrl-q to detach
```

:::{warning}
Both VSCode and the iocShell capture `ctrl-p`, so the `ctrl-p ctrl-q` detach
sequence may not reach compose. If it does not, close the terminal window
instead. Note that `ctrl-c`, `ctrl-d` or `exit` will stop the IOC — compose then
restarts it automatically.
:::

## Shut down

`stop` leaves the containers, networks and volumes in place so a later `start`
is quick:

```bash
docker compose stop
```

`down` removes the containers and networks. Volumes are kept, preserving IOC
autosave data:

```bash
docker compose down
```

## Preview the ec CLI

On a cluster, IOCs are managed with the `ec` CLI instead of `docker compose`
(see {any}`deploy-argocd`). You can preview that interface now, without a
cluster, by selecting its `DEMO` backend — it serves a set of fake services:

```bash
export EC_CLI_BACKEND=DEMO
ec ps                     # list services
ec logs demo-ea-01        # show a service's logs
ec stop demo-ea-01        # stop / start by name
ec monitor                # full-screen TUI (Escape to exit)
```

The same commands drive real services once `ec` is pointed at a cluster. For the
full command and environment-variable reference, see the
[edge-containers-cli documentation](https://epics-containers.github.io/edge-containers-cli/).
