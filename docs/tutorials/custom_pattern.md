# Author Your Own Runtime Pattern

In {any}`detector_plugins` you vendored a *published* runtime pattern — the
standard AreaDetector plugin set — into an existing IOC instance. Here you
author your **own** pattern: a cut-down plugin set called `basicPlugins`,
published from a fork of the `ibek-runtime-support` library.

This is the runtime mirror of {any}`generic_ioc`, where you forked a
*build-time* support library and rebuilt an image. This time nothing is
rebuilt — a generic IOC picks up your new support at its next container start,
because `ibek pattern` vendors the file-set into the instance's `config/` and
`ibek runtime generate2` discovers it at boot.

For this tutorial you are back in your **`t01-services` compose project** on the
workstation — the same repo you built up in {any}`create_ioc` and the earlier
compose tutorials — **not** the generic-IOC devcontainer from {any}`generic_ioc`.
You will use the same `bl01t` worked example; substitute your own names
throughout.

:::{note}
`ibek pattern` runs on your **workstation**. The `ibek.manifest.yaml` and
`runtime-lock.yaml` shown on this page need an `ibek` **newer than 4.6.2**:
4.6.2 and earlier ignore the manifest, stamp a `DO NOT EDIT` header into every
vendored file and write the older lock format. Install or refresh it with
`uv tool install ibek --upgrade`, and confirm with `ibek --version`.
:::

## Fork the pattern library

Patterns live in curated central libraries, so — exactly as with `ibek-support`
in {any}`generic_ioc` — you work from a fork and open a pull request later if
the pattern is generally useful.

- Fork [`ibek-runtime-support`](https://github.com/epics-containers/ibek-runtime-support/fork).
- Clone your fork next to your `t01-services` checkout:

```bash
# run alongside your t01-services directory
git clone https://github.com/<your-org>/ibek-runtime-support
```

## Author the pattern

A pattern is just a **top-level folder named after the pattern**, holding one
or more files. The only required member is the `*.ibek.support.yaml` support
definition. Create the folder and file in your fork:

```bash
cd ibek-runtime-support
mkdir basicPlugins
code basicPlugins/basicPlugins.ibek.support.yaml
```

`basicPlugins` declares a single `entity_model` whose `sub_entities` wire up
just **two** AreaDetector plugins — a viewable Channel Access array
(`NDStdArrays`) and live statistics (`NDStats`). It mirrors the shape of the
real `detectorPlugins` model but trimmed to the essentials:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ibek/releases/download/3.0.1/ibek.support.schema.json

module: basicPlugins

entity_models:
  - name: basicPlugins
    description: A minimal AreaDetector plugin set — a viewable array and stats
    parameters:
      P:
        type: str
        description: Prefix for the AreaDetector PVs
      CAM:
        type: str
        description: AreaDetector NDArray port name of the camera
      PORTPREFIX:
        type: str
        description: Prefix for all plugin ports

    sub_entities:
      - type: ADCore.NDStdArrays
        P: "{{ P }}"
        R: ":ARR:"
        PORT: "{{ PORTPREFIX }}.arr"
        NDARRAY_PORT: "{{ CAM }}"
        NELEMENTS: 1048576
        TYPE: Int8
        FTVL: CHAR

      - type: ADCore.NDStats
        P: "{{ P }}"
        R: ":STAT:"
        PORT: "{{ PORTPREFIX }}.stat"
        NDARRAY_PORT: "{{ CAM }}"
        HIST_SIZE: 256
        XSIZE: 1280
        YSIZE: 1024
```

Only the three wiring parameters are exposed. Most of the plugins' tuning knobs
(channel count, queue depth …) keep their `ADCore` defaults; the few that have
**no** default are set inline — `NELEMENTS` so the array is big enough to view,
and `NDStats`'s required `HIST_SIZE` / `XSIZE` / `YSIZE` (the histogram bin count
and the maximum image dimensions it computes statistics over). A production
pattern like the real `detectorPlugins` promotes more of these to parameters —
add them the same way when you need them.

The `ADCore` plugins it references are compiled into every AreaDetector image,
so this pattern needs **no `.db` / `.template` of its own** — it only adds the
`ibek` entities that instantiate and connect them at runtime.

### Optional: declare what gets vendored

`basicPlugins` holds one file and every byte of it belongs in the IOC, so there
is nothing to declare. That is the usual case: **a pattern with no manifest
vendors every file in its folder into the instance's `config/`**, exactly as
patterns always have.

Write one only when the folder holds something an IOC must not receive — a
`README`, a datasheet, device notes you want browsable in the library.
Everything in `config/` is mounted into the IOC container (and on Kubernetes it
*is* the ConfigMap), so whatever lands there travels to the beamline. An
`ibek.manifest.yaml` at the root of the pattern folder lists what counts as a
runtime file:

```yaml
version: 1
vendor:
  - src: '.*\.(template|db|req|proto|protocol|ibek\.support\.yaml|pvi\.device\.yaml)$'
    dest: config
```

`src` is a regular expression that must match a file's **whole** path within the
pattern folder — `ibek` matches with `re.fullmatch`, so a rule of `'\.proto$'`
on its own matches nothing; lead each one with `.*`. `dest` is where the matched
files land, relative to the instance root, and `config` is the only destination
a services repo needs.

The list is an **allow-list**: a file matched by no entry is not vendored, which
is exactly how the `README` stays out of the IOC. The manifest itself is never
vendored either. That cuts both ways — a runtime file your rules forget is
dropped just as quietly, with no error and a passing `ibek pattern check` — so
the alternation has to name every extension the pattern really ships. Only a
manifest matching *nothing at all* is reported as a mistake.

Narrowing a manifest later takes effect the next time the instance is
re-vendored **from a version that carries it**. A bare
`ibek pattern update services/<instance>` re-fetches each pattern at the version
already pinned, so a manifest added after that tag is not seen: cut a new tag
and re-pin with `-v <tag>` (below, a local `--source` pins `HEAD`, so re-running
`ibek pattern add` is enough). When it does re-vendor, files the manifest
stopped matching are deleted from `config/`, so the instance never keeps a copy
the pattern no longer claims.

## Create a fresh instance to vendor into

Make a new instance `bl01t-ea-cam-02` exactly as you made `bl01t-ea-cam-01` in
{any}`create_ioc`: copy `services/.ioc_template`, set the **name** and **image**
in its `compose.yml`, and register it in the repo-root `compose.yml`. Use a
separate instance so its plugin ports do not clash with the `detectorPlugins`
already running in `bl01t-ea-cam-01`. Pin the SimDetector image:

```yaml
    image: ghcr.io/epics-containers/ioc-adsimdetector-runtime:2.11ec3
```

Give it a camera in `services/bl01t-ea-cam-02/config/ioc.yaml`:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ioc-adsimdetector/releases/download/2.11ec3/ibek.ioc.schema.json

ioc_name: "{{ _global.get_env('IOC_NAME') }}"

description: An IOC that simulates an area detector

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: ADSimDetector.simDetector
    PORT: DET.DET
    P: BL01T-EA-CAM-02
    R: ":DET:"
```

## Vendor your pattern

Because you are still iterating, vendor straight from your **local clone** with
`--source`. A local-path source is copied as-is, so you do not have to commit,
push or tag the fork between edits:

```bash
cd t01-services
ibek pattern add --source ../ibek-runtime-support basicPlugins services/bl01t-ea-cam-02
```

This writes `basicPlugins.ibek.support.yaml` into
`services/bl01t-ea-cam-02/config/` — an exact copy of the file in your fork —
and records its `sha256` in `services/bl01t-ea-cam-02/runtime-lock.yaml`.
That is all the vendor step needs: at container start `ibek runtime generate2
config` discovers the vendored support file and loads your entity — no image
rebuild, and nothing else to wire up.

The lock now pins the pattern. A local source pins to `HEAD`:

```yaml
version: 1
patterns:
  basicPlugins:
    version: HEAD
    source: ../ibek-runtime-support
    files:
      config/basicPlugins.ibek.support.yaml: sha256:…
```

The `files:` keys are relative to the **instance root**, which is why `config/`
appears in them.

:::{warning}
Keep editing the pattern **in your fork** and re-run `ibek pattern add` — never
the copy under `config/`. The copy looks like any other file, and only the lock
records that it is not yours: an edit there is overwritten by the next `add`,
`update` or `restore`, and fails `ibek pattern check` before that.
:::

`ibek pattern check services/bl01t-ea-cam-02` re-hashes the vendored file and
exits non-zero if it has drifted from the lock — run it in CI or a pre-commit
hook to guarantee the committed `config/` matches what was pinned. Because the
copy is byte-for-byte the file in the library, plain `diff` works as a second
opinion:

```bash
diff -r services/bl01t-ea-cam-02/config/ ../ibek-runtime-support/basicPlugins/
```

Vendored files that appear on both sides compare equal; your own `ioc.yaml` and
anything the pattern does not vendor show up as `Only in …` lines.

## Use the new entity

Add one `basicPlugins.basicPlugins` entity to the instance's `ioc.yaml`, wired
to the camera's Asyn port (`CAM: DET.DET`, the `simDetector` PORT above):

```yaml
  - type: basicPlugins.basicPlugins
    P: BL01T-EA-CAM-02
    CAM: DET.DET
    PORTPREFIX: DET
```

This single entity expands — via its `sub_entities` — into both plugins.

Now set the compose project up to run it. First register the instance in the
repo-root `compose.yml` `include:` list:

```yaml
include:
  - services/bl01t-ea-cam-01/compose.yml
  - services/bl01t-ea-cam-02/compose.yml
  ...
```

Then point Phoebus at the new instance. PVI auto-generates an `index.bob` for it
at `opi/auto-generated/bl01t-ea-cam-02/index.bob`; open it on launch by editing
the `command:` line of the `phoebus` service in `services/phoebus/compose.yml`:

```yaml
    command: phoebus-product/phoebus.sh -settings /config/settings.ini -resource /opi/auto-generated/bl01t-ea-cam-02/index.bob -server 7010
```

Bring the beamline up:

```bash
source ./environment.sh
docker compose up -d
```

At startup PVI generates an engineering screen per entity under
`opi/auto-generated/bl01t-ea-cam-02/`. Your new pattern adds two panels: an
**NDStdArrays** panel publishing the camera frames as a Channel Access waveform
(open it in Phoebus's image widget after **Acquire** on the `simDetector` and
**Enable** on the plugin), and an **NDStats** panel showing live min/max/mean,
sigma and a histogram. A maintainer screenshot will be added here.

## Promote the pattern

Local-path vendoring is for iteration only. Once the pattern is settled, make
it shareable:

1. Commit and push it to your fork, then cut a release tag (`vX.Y.Z`) — a tag
   versions the whole library at once.
2. Re-pin the instance from the published fork instead of the local path.
   Point the `ibek-runtime-support` library name at your fork with the
   `IBEK_PATTERN_LIBRARIES` environment variable, then `add` the qualified
   reference at your new tag:

   ```bash
   export IBEK_PATTERN_LIBRARIES="ibek-runtime-support=https://github.com/<your-org>/ibek-runtime-support"
   ibek pattern add ibek-runtime-support:basicPlugins@v0.1.0 services/bl01t-ea-cam-02
   ```

   The lock now records `version: v0.1.0` and
   `source: github.com/<your-org>/ibek-runtime-support` — a fully reproducible
   pin. Once the pattern is merged upstream you can drop the override and pin
   the canonical library directly.

3. If the pattern is generally useful, open a pull request against
   [`ibek-runtime-support`](https://github.com/epics-containers/ibek-runtime-support)
   so every beamline can vendor it.

:::{note}
A pattern's file-set is **not** fixed to a single file. The lock simply hashes
a *file list*, so a pattern may also ship `.template` / `.db`, autosave `.req`
files, or a `.pvi.device.yaml` screen descriptor alongside its support yaml —
whatever the support definition references. All of it is vendored unless an
`ibek.manifest.yaml` narrows the set. {any}`stream_device` vendors exactly such
a multi-file device-support pattern.
:::
