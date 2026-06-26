# Changing a Generic IOC

This is a **type 2** change from {any}`ioc-change-types`: you change the Generic
IOC itself, not just an instance's config. You need this when the behaviour you
want is not exposed as an instance parameter — for example to:

- bump a support module to a new version,
- add support such as autosave or iocStats,
- adjust the support YAML so instances can use new entities.

:::{note}
Tempted to add a second device to a Generic IOC? Prefer a *separate* Generic IOC
per device: smaller images, fewer rebuilds, and records still link across IOCs
via Channel Access. Kubernetes makes running many small services cleaner than a
few monolithic ones. The exception is a set of devices always deployed and
restarted together — at DLS, for instance, one Generic IOC covers a beamline's
vacuum equipment.
:::

You test type 2 changes inside the Generic IOC's own devcontainer, against an
example instance it bundles. `ioc-adsimdetector` bundles
`services/bl01t-ea-ioc-02` (PV prefix `BL01T-DI-CAM-01`) and a ready-made
Phoebus screen — a simulation detector is ideal here because it needs no real
hardware. We will make changes locally and not push them; later tutorials cover
forks and pull requests.

## Preparation

Open `ioc-adsimdetector` in its devcontainer (clone it if you did not keep it
from earlier tutorials):

```bash
git clone --recursive https://github.com/epics-containers/ioc-adsimdetector.git
cd ioc-adsimdetector
code .
# Ctrl-Shift-P -> "Reopen in Container"
```

A fresh devcontainer needs two things before an IOC will run: a built binary and
a selected instance. The IOC source is symlinked to `/epics/ioc`, so build there
and select the bundled example:

```bash
cd /epics/ioc
make
ibek dev instance /workspaces/ioc-adsimdetector/services/bl01t-ea-ioc-02
./start.sh
```

`ibek dev instance` symlinks the chosen instance's `config` folder to
`/epics/ioc/config`. You should see an iocShell prompt with no errors above it.

## View the simulated image

The bundled instance auto-starts acquisition — its `ioc.yaml` includes an
`epics.PostStartupCommand` entity that sets `Acquire` and the plugin
`EnableCallbacks` records — so an image is already streaming. To see it, launch
Phoebus *from outside the devcontainer*:

```bash
cd ioc-adsimdetector
./opi/phoebus-launch.sh
```

`phoebus-launch.sh` opens the auto-generated `index.bob` plus the hand-made
`opi/bl01t-ea-ioc-02.bob`, which displays the detector's PVA image
(`BL01T-DI-CAM-01:PVA:OUTPUT`). You should see the moving simulation image.

:::{figure} ../images/phoebus2.png
The bundled `bl01t-ea-ioc-02.bob` screen showing the simulated image.
:::

## Make a change to the Generic IOC

The example auto-starts acquisition the **per-instance** way: an
`epics.PostStartupCommand` in its `ioc.yaml` (a type 1 change — see
{any}`ioc-change-types`). To make the same behaviour part of the **Generic
IOC**, so *every* instance built from it inherits the behaviour, edit the
support YAML instead.

The support YAML describes the *entities* an instance may use. Open
`ibek-support/ADSimDetector/ADSimDetector.ibek.support.yaml`, find the
`simDetector` entity, and add a `post_init` section after its `pre_init`:

```yaml
post_init:
  - type: text
    value: |
      dbpf {{P}}{{R}}Acquire 1
```

`{{P}}` and `{{R}}` are the entity's parameters, rendered with Jinja at runtime —
here `BL01T-DI-CAM-01` and `:DET:`. Restart the IOC (`Ctrl-D` to exit the shell,
then `./start.sh`). `start.sh` re-runs `ibek runtime generate2`, so your line now
appears in the rendered startup script `/epics/runtime/st.cmd`:

```console
dbpf BL01T-DI-CAM-01:DET:Acquire 1
```

Every instance of this Generic IOC now acquires on startup without needing the
command in its own config.

:::{note}
This is deliberately artificial: a `post_init` here changes behaviour for *all*
simDetector instances. For per-instance behaviour, prefer the `epics.dbpf` or
`epics.PostStartupCommand` entity in `ioc.yaml` (both defined globally in
`ibek-support/_global/epics.ibek.support.yaml`) — the type 1 approach the
bundled example already uses.
:::

Support YAML — entities, `pre_init`/`post_init`, and parameters — is covered in
depth in {any}`generic_ioc`.

## Publishing and cleaning up

We will not push these demo changes. To publish a real Generic IOC change you
would commit the `ibek-support` submodule first, then the parent
`ioc-adsimdetector` repo, because of the submodule dependency. Later tutorials
cover forks and pull requests for sharing changes back.

Undo the demo edit:

```bash
cd /workspaces/ioc-adsimdetector/ibek-support
git reset --hard
```
