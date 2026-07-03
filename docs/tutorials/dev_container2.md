# Developer Containers Part 2

The developer container you built in [the previous tutorial](dev_container.md)
is a complete EPICS environment. This short follow-up shows two things you can
do with it once your IOC is running: talk to the IOC with the EPICS
command-line tools *inside* the container, and launch Phoebus *on the host* to
view the IOC's auto-generated engineering screens.

:::{note}
If you closed the container after the last tutorial, reopen it and restart the
IOC:

```bash
cd ioc-adsimdetector
code .            # then ctrl-shift-p -> "Reopen in Container"

# only if the container was rebuilt do you need to rebuild the IOC:
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01
cd /epics/ioc && make

# otherwise just start it:
/epics/ioc/start.sh
```
:::

## Channel Access

The container ships the full set of EPICS tools, so `caget`, `caput` and
`camonitor` work against the running IOC from any VSCode terminal. The IOC shell
is still occupying the terminal you started it in, so open a second terminal
(`Terminal → New Terminal`) for these commands and leave the IOC running:

```bash
caget BL01T-EA-CAM-01:DET:Acquire
caput BL01T-EA-CAM-01:DET:Acquire 1
caput BL01T-EA-CAM-01:ARR:EnableCallbacks 1
# read the first 10 elements of the (changing) image array
caget -#10 BL01T-EA-CAM-01:ARR:ArrayData
```

:::{warning}
Channel Access sees the IOC's PVs both via localhost and UDP broadcast
so you will get a warning like:

```
Warning: "Identical process variable names on multiple servers"
```

To silence this warning, make CA look only at localhost before running `caget`/`caput`:

```bash
export EPICS_CA_ADDR_LIST=localhost EPICS_CA_AUTO_ADDR_LIST=NO
```
:::

You are `root` inside the container (podman maps that back to your own user on
the host), so no `sudo` is needed. The image is Ubuntu-based, so install any
extra tool you need with `apt update && apt install <package>`.

## Phoebus

Generic IOCs use PVI to auto-generate Phoebus engineering screens — one for the
driver and one for every AreaDetector plugin in the instance. The IOC's `opi/`
folder ships a launcher script that opens them.

:::{important}
Run the launcher **on the host, not inside the developer container.** It looks
for a host Phoebus install or starts a Phoebus container, neither of which works
from within the dev container.
:::

```bash
# run this OUTSIDE the developer container
cd ioc-adsimdetector
./opi/phoebus-launch.sh
```

By default the script launches Phoebus in a container
(`ghcr.io/epics-containers/ec-phoebus:latest`). To use a local install instead,
comment out the `use_container=1` line at the top of `opi/phoebus-launch.sh`; it
then runs `phoebus.sh` from your `PATH`. Either way the script fills in the
correct Channel Access and PV Access ports for you, so Phoebus connects straight
to the IOC running in the container.

Phoebus opens `opi/auto-generated/index.bob`, the entry point to the generated
screens. The `opi/auto-generated/` folder is not committed to git — the IOC
fills it in at runtime. You should see a button for the simDetector driver and
for each plugin; click through to interact with the detector.

:::{note}
For how a client outside the container reaches an IOC running inside it, see
[](../explanations/epics_protocols.md).
:::

## A nicer overview screen

Earlier we used a hand-coded screen with a proper image widget that worked with the same IOC instance we are using now (see {any}`change-the-opi-screen`). To open it, close Phoebus and relaunch it pointing at that screen:

```bash
./opi/phoebus-launch.sh -resource /workspaces/t01-services/opi/demo-simdet.bob
```

:::{figure} ../images/custom_bob.png
A hand-coded overview screen for bl01t-ea-cam-01.
:::
