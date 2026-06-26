
# Launch a Simulation Beamline

This tutorial launches a complete simulation beamline on your workstation with
`docker compose`. It proves the container engine you set up in
{any}`setup_workstation` works, and gives you a running beamline to experiment
with before you build your own.

The example lives in the public
[`example-services`](https://github.com/epics-containers/example-services)
repository. One `docker compose up` brings up a self-contained set of
containers:

- a simulated area-detector IOC (`bl01t-di-cam-01`);
- a simulated motion IOC (`bl01t-mo-sim-01`);
- a simple example IOC with a sum record (`bl01t-ea-test-01`);
- a Channel Access gateway (`ca-gateway`) and a PVA gateway (`pvagw`) that
  expose the IOCs' PVs to the host;
- a Phoebus instance to view the beamline.

:::{note}
You need `docker compose` (the v2 plugin, **not** `podman-compose`) plus a
container engine — Docker or podman. See {any}`quickstart` to install these on
any platform.
:::

## Launch it

```bash
git clone https://github.com/epics-containers/example-services
cd example-services
source ./environment.sh        # set the EPICS ports and compose variables
docker compose up -d           # -d detaches; omit it to follow the combined logs
```

Phoebus opens with an overview of the running beamline:

:::{figure} ../images/example_beamline.png
The example beamline overview screen.
:::

## Talk to the beamline

`source ./environment.sh` pointed your shell's Channel Access at the gateway
(`EPICS_CA_NAME_SERVERS=127.0.0.1:9064`), so if you have the EPICS tools
installed locally you can read a PV straight away:

```bash
caget BL01T-DI-CAM-01:DET:Acquire_RBV
```

No local EPICS tools? Run `caget` inside one of the IOC containers instead:

```bash
docker compose exec bl01t-ea-test-01 caget BL01T-DI-CAM-01:DET:Acquire_RBV
```

:::{note}
The gateway binds the Channel Access ports to `127.0.0.1` only, so these PVs are
reachable **only** from this host. That makes the example safe for tutorials —
nothing leaks onto the wider network.
:::

Manage individual services with the usual compose subcommands (each takes a
service name from the list above):

```bash
docker compose logs bl01t-di-cam-01 -f    # follow a service's logs (ctrl-c to exit)
docker compose stop bl01t-di-cam-01       # stop a service
docker compose start bl01t-di-cam-01      # start it again
```

## Clean up

Always tear the example down before moving on to the next tutorial. Volumes are
kept, so IOC autosave data survives:

```bash
docker compose down
```

:::{important}
If `docker compose down` times out removing the PVA gateway, just run it again —
the second pass clears the remaining container.
:::
