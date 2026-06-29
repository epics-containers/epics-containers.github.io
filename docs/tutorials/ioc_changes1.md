# Changing the IOC Instance

This tutorial makes a small change to the example IOC `bl01t-ea-cam-01`: you add
a hand-crafted EPICS database record and prove the change works. This is a
**type 1** change from {any}`ioc-change-types` — you are only editing instance
configuration, so nothing is recompiled. Types 2 and 3 follow in the next two
tutorials.

Type 1 changes do not strictly need a developer container (you deployed an IOC
instance in an earlier tutorial without one), but we will use the
`ioc-adsimdetector` devcontainer here because it lets you test the change
instantly. If you closed it after the last tutorial, reopen the
`ioc-adsimdetector` folder in VSCode, press `Ctrl-Shift-P` and choose "Reopen in
Container", then re-select the instance:

```bash
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01
```

:::{note}
This tutorial assumes the `ioc.yaml`-based instance. If you switched to raw
startup assets in the previous tutorial, either revert to `ioc.yaml` or apply
the same change by appending the `dbLoadRecords` line to your `st.cmd` — see
{any}`raw-startup-assets`.
:::

## Make the change

Your instance config folder `/epics/ioc/config` is symlinked to
`/workspaces/t01-services/services/bl01t-ea-cam-01/config`, so every edit you
make here lands directly in the `t01-services` repo, ready to commit.

1. Add a file `extra.db` containing a single soft record:

   ```text
   record(ai, "BL01T-EA-CAM-01:TEST") {
      field(DESC, "Test record")
      field(DTYP, "Soft Channel")
      field(VAL, "1")
   }
   ```

2. Append a `StartupCommand` entity to `ioc.yaml` to load it (match the
   indentation of the existing `- type:` entries so the `- type:` lines align):

   ```yaml
   - type: epics.StartupCommand
     command: dbLoadRecords(config/extra.db)
   ```

## Test it

Restart the IOC inside the devcontainer:

```bash
# stop the running IOC shell first with Ctrl-D (or type exit)
cd /epics/ioc
./start.sh
```

`start.sh` runs `ibek runtime generate2` to regenerate the startup script and
database from your edited `ioc.yaml`, so your `dbLoadRecords(config/extra.db)`
line now appears in the startup log.

From a second terminal (Terminal -> New Terminal) read the new record:

```bash
caget BL01T-EA-CAM-01:TEST
```

A value of `1` confirms the change is live.

## Commit the change

Because the config edits already live in `t01-services`, commit and push them,
then tag a release of the services repo (substitute your own version):

```bash
cd /workspaces/t01-services
git add .
git commit -m "Add extra.db to bl01t-ea-cam-01"
git push
git tag 2026.7.1
git push origin 2026.7.1
```

That tag pins the version you deploy to a real beamline — see
{any}`deploy-argocd` for the cluster deployment path.

## How it works

The entities you may use in `ioc.yaml` are defined by *support YAML* files baked
into the Generic IOC at build time — one per support module, under
`/epics/ibek-defs`. `StartupCommand` comes from the global
`/epics/ibek-defs/epics.ibek.support.yaml`:

```yaml
- name: StartupCommand
  description: Adds an arbitrary command in the startup script before iocInit
  parameters:
    command:
      type: str
      description: command string
      default: ""
  pre_init:
    - type: text
      value: "{{ command }}"
```

Its companion `PostStartupCommand` does the same *after* `iocInit`. For a command
spanning several lines, use a YAML block scalar — the lines are emitted verbatim
(the nesting whitespace is stripped):

```yaml
- type: epics.StartupCommand
  command: |
    # load extra records
    dbLoadRecords(config/extra.db)
    dbLoadRecords(config/extra2.db)
```

Later tutorials show where these support YAML files come from and how to add your
own.
