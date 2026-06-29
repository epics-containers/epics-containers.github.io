# Add a Device Driver at Runtime with `ibek pattern`

In {any}`detector_plugins` you vendored a *plugin set* into an existing instance
with `ibek pattern`. Here you vendor a *device driver* the same way — but onto a
new IOC, and with the device's own **simulator** running alongside it.

You build a new IOC on the **generic** `ioc-streamdevice` image, vendor the
`lakeshore340` temperature-controller support into it, and run the device
simulator as a compose sidecar. Substitute your own names throughout.

By the end you will have:

- a new IOC instance, `bl01t-ea-temp-01`, on the `ioc-streamdevice` image;
- the `lakeshore340` StreamDevice support vendored into it at a pinned version,
  recorded in `runtime-lock.yaml`;
- a simulator running as a sidecar, with the IOC reading temperatures from it.

:::{note}
The same image can host *any* of the StreamDevice drivers in the library — you
choose the device per instance by vendoring it, rather than by picking a
different image. The IOC loads the vendored support at container start, so no
rebuild is needed.
:::

## Create the instance

An instance is a folder under `services/`; copy the skeleton and open the repo
in your editor, exactly as in {any}`create_ioc`:

```bash
cd t01-services
cp -r services/.ioc_template services/bl01t-ea-temp-01
code .
```

In `services/bl01t-ea-temp-01/compose.yml`, replace **every** `ioc_default_name`
with `bl01t-ea-temp-01`, and set the image to the generic StreamDevice IOC:

```yaml
    image: ghcr.io/epics-containers/ioc-streamdevice-runtime:2.8.26ec1
```

## Vendor the `lakeshore340` support

`ibek pattern` runs on your **workstation**. From the repo root, vendor the
driver into the instance you just created:

```bash
ibek pattern add ibek-runtime-streamdevice:lakeshore340@0.1.1 services/bl01t-ea-temp-01
```

:::{note}
`ibek pattern` needs **ibek ≥ 4.6.1**. If it is not on your `PATH`, run it on
demand with `uvx --from ibek ibek pattern add …`.
:::

`ibek-runtime-streamdevice` is one of ibek's built-in libraries, resolved from
its name to
[its GitHub repo](https://github.com/epics-containers/ibek-runtime-streamdevice).
The command vendors three files into `config/` — each with a
`# Vendored … DO NOT EDIT` header — and writes a `runtime-lock.yaml` at the
instance root:

| File | Role |
|---|---|
| `config/lakeshore340.ibek.support.yaml` | The entity model `lakeshore340.lakeshore340` you instantiate below. |
| `config/lakeshore340.proto` | The StreamDevice protocol (the serial command set). |
| `config/lakeshore340.template` | The EPICS database of temperature/heater records. |
| `runtime-lock.yaml` | Pins the version and the per-file SHA-256 hashes. |

Commit the lock with the instance. Anyone can later confirm the vendored files
are untampered with:

```bash
ibek pattern check services/bl01t-ea-temp-01
```

## Configure the IOC

Open `services/bl01t-ea-temp-01/config/ioc.yaml` and define the device. The
`asyn.AsynIP` entity opens a TCP connection to the simulator (added next); the
`lakeshore340.lakeshore340` entity — supplied by the support file you just
vendored — drives it over that port:

```yaml
ioc_name: "{{ _global.get_env('IOC_NAME') }}"

description: A simulated Lakeshore 340 temperature controller

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: epics.EpicsEnvSet
    name: STREAM_PROTOCOL_PATH
    value: /epics/runtime/protocol/

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: asyn.AsynIP
    name: p1
    port: lakeshore-sim:5401

  - type: lakeshore340.lakeshore340
    P: BL01T-EA-TEMP-01
    PORT: p1
    name: lakeshore
```

`STREAM_PROTOCOL_PATH` tells StreamDevice where to find the vendored `.proto`
file at runtime; the IOC's `start.sh` copies it there at container start (via
`ibek runtime place-files`). `PORT: p1` wires the
device to the Asyn port, and `port: lakeshore-sim:5401` is the **service name**
of the simulator on the compose network.

## Run the simulator as a sidecar

The `lakeshore340` controller is an external serial device, so the IOC needs
something to talk to. Diamond ships a small pure-stdlib simulator; download it
into the instance folder:

```bash
curl -o services/bl01t-ea-temp-01/lakeshore340_sim.py \
  https://raw.githubusercontent.com/DiamondLightSource/lakeshore340/main/etc/simulations/lakeshore340_sim.py
```

:::{note}
The `DiamondLightSource/lakeshore340` repository is being retired; the simulator
will move into `ibek-runtime-streamdevice`. When it does, only the URL above
needs updating.
:::

Add a second service to `services/bl01t-ea-temp-01/compose.yml` that runs the
script on a stock Python image, on the same `channel_access` network as the IOC:

```yaml
  lakeshore-sim:
    image: python:3-slim
    command: python /sim/lakeshore340_sim.py 5401
    volumes:
      - ./lakeshore340_sim.py:/sim/lakeshore340_sim.py:ro
    security_opt:
      - label=disable
    networks:
      - channel_access
```

The IOC reaches it by service name (`lakeshore-sim:5401`); because both are on
`channel_access`, compose provides the DNS. The whole instance — IOC, config and
simulator — is now self-contained and reproducible.

## Bring it up

Register the instance by adding it to the `include:` list in the repo-root
`compose.yaml`:

```yaml
include:
  - services/bl01t-ea-temp-01/compose.yml
  ...
```

Then start the beamline:

```bash
source ./environment.sh
docker compose up -d
```

## Check it works

The simulator logs every query it receives. Follow its output:

```bash
docker compose logs lakeshore-sim -f      # ctrl-c to stop following
```

```text
Initialising ls340 simulator, V2.0 2024.01.21
Listening on port: 5401
Connection from: ('170.200.0.3', 54312)
RECEIVED: *IDN?
RECEIVED: KRDG? 0
RECEIVED: SETP? 1
```

The IOC reads the device ID, the temperature channels (`KRDG0`–`KRDG3`), the
setpoint (`SETP`) and the heater output (`HTR`). Confirm a couple of PVs from
inside the IOC container:

```bash
docker compose exec bl01t-ea-temp-01 caget BL01T-EA-TEMP-01:ID BL01T-EA-TEMP-01:KRDG0
```

```text
BL01T-EA-TEMP-01:ID     LSCI,MODEL340,123456,02032001
BL01T-EA-TEMP-01:KRDG0  23.4
```

:::{note}
Unlike the AreaDetector plugins in {any}`detector_plugins`, StreamDevice device
support such as `lakeshore340` ships no auto-generated PVI screen, so inspect
its PVs directly with `caget` or the Phoebus **Probe** tool.
:::

:::{note}
**Figure (screenshot TODO — maintainer walkthrough):** the Phoebus **Probe**
panel (or a PV table) showing `BL01T-EA-TEMP-01:ID` and the live `KRDG0`
temperature reading from the simulator.
:::

Manage the running IOC and its sidecar with the same `docker compose` commands
from {any}`deploy_example`.

## Next steps

- {any}`detector_plugins` — vendor a *plugin set* (the AreaDetector mirror of
  this device-support workflow) into an existing IOC.
- {any}`generic_ioc` — go the other way and bake your own support into a Generic
  IOC at **build** time.
