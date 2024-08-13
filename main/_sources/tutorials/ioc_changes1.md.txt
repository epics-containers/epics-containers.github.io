# Changing the IOC Instance

This tutorial will make a very simple change to the example IOC `bl01t-ea-cam-01`. This is a type 1 change from {any}`ioc-change-types`, types 2, 3 will be covered in the following 2 tutorials.

Strictly speaking, Type 1 changes do not require a devcontainer. You created and deployed the IOC instance in a previous tutorial without one. It is up to you how you choose to make these types of changes. Types 2,3 do require a devcontainer because they involve compiling Generic IOC / support module code.

These instructions are for running inside the devcontainer. If you closed your developer container from the last tutorial, then open it again now. To do so, open your `ioc-adsimdetector` folder in vscode and then press `Ctrl-Shift-P` and type `Remote-Containers: Reopen in Container`.

We are going to add a hand crafted EPICS DB file to the IOC instance. This will be a simple record that we will be able to query to verify that the change is working. We will use the version of the IOC instance that used `ioc.yaml`. If you changed to using raw startup assets in the previous tutorial then revert to using `ioc.yaml` for this tutorial or see [](raw-startup-assets).

Make the following changes in your test IOC config folder
(`/epics/ioc/config` which is currently the same as `/workspaces/t01-services/services/bl01t-ea-cam-01/config`):

1. Add a file called `extra.db` with the following contents.

   ```text
   record(ai, "BL01T-EA-CAM-01:TEST") {
      field(DESC, "Test record")
      field(DTYP, "Soft Channel")
      field(SCAN, "Passive")
      field(VAL, "1")
   }
   ```

2. Add the following lines to the end of `ioc.yaml` (verify that the indentation
   matches the above entry so that `- type:` statements line up):

   ```yaml
   - type: epics.StartupCommand
     command: dbLoadRecords(config/extra.db)
   ```

## Locally Testing Your changes

You can immediately test your changes by restarting the IOC instance inside the developer container as follows:

```bash
# stop any existing IOC shell by hitting Ctrl-D or typing exit
cd /epics/ioc
./start.sh
```

If all is well you should see your iocShell prompt and the output should show `dbLoadRecords(config/extra.db)`.

Test your change from another terminal (VSCode menus -> Terminal -> New Terminal) like so:

```bash
caget BL01T-EA-CAM-01:TEST
```

If you see the value 1 then your change is working.


Because of the symlink between `/epics/ioc/config` and `/workspaces/bl01t/services/bl01t-ea-cam-01/config` the same files you are testing by launching the IOC inside of the devcontainer are also ready to be committed and pushed to the `t01-services` repo. The following commands show how to do this:

```bash
cd /workspaces/t01-services
git add .
git commit -m "Added extra.db"
git push
# tag a new version of the beamline repo
git tag 2024.8.2
git push origin 2024.8.2
```

If you like working entirely from the vscode window you can open a terminal in vscode *outside* of the devcontainer. To do so, press `Ctrl-Shift-P` and choose the commnd `Terminal: Create New Integrated Terminal (Local)`. This will open a terminal to the host. You can then run `ec` from there.

## Launching the Test Beamline

Because the changes have been made in `t01-services` you can now launch the test beamline from outside of the devcontainer.
However, it is important to remember that we cannot have two ca-gateway's trying to bind to the default CA port on the same host.

Make sure the ca-gateway from the previous tutorial is stopped before launching the test beamline with the following:

```bash
# IMPORTANT: do this in a terminal outside of the devcontainer
cd ioc-adsimdetector/compose
. ./environment.sh
ec down
```

Now you can launch your test beamline and it will have picked up the new extras.db.

```bash
# IMPORTANT: do this in a terminal outside of the devcontainer
cd t01-services
. ./environment.sh
ec up -d
caget BL01T-EA-CAM-01:TEST

# Now shut down the beamline again so we can continue with further developer container tutorials
ec down
```

## Raw Startup Assets

If you plan not to use `ibek` runtime asset creation you could use the raw startup assets from {any}`raw-startup-assets`. If you do this then the process above is identical except that you will add the `dbLoadRecords` command to the end of raw `st.cmd`.

## More about ibek Runtime Asset Creation

The set of `entities` that you may create in your ioc.yaml is defined by the `ibek` IOC schema that we reference at the top of `ioc.yaml`. The schema is in turn defined by the set of support modules that were compiled into the Generic IOC (ioc-adsimdetector). Each support module has an `ibek` *support YAML* file that contributes to the schema.

The *Support yaml* files are in the folder `/epics/ibek-defs` inside of the container. They were placed there during the compilation of the support modules at Generic IOC build time.

It can be instructive to look at these files to see what entities are available to *IOC instances*. For example the global support yaml file `/epics/ibek-defs/epics.ibek.support.yaml` contains the following (snippet):

```yaml
  ---
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

  - name: PostStartupCommand
    description: Adds an arbitrary command in the startup script after iocInit
    parameters:
      command:
        type: str
        description: command string
        default: ""
    post_init:
      - type: text
        value: "{{ command }}"
  ---
```

These two definitions allow you to add arbitrary commands to the startup script before and after iocInit. This is how we added the `dbLoadRecords` command.

If you want to specify multiple lines in a command you can use the following syntax for multi-line strings:

> ```yaml
> - type: epics.StartupCommand
>   command: |
>     # loading extra records
>     dbLoadRecords(config/extra.db)
>     # loading even more records
>     dbLoadRecords(config/extra2.db)
> ```

This would place the 4 lines verbatim into the startup script (except that they would not be indented - the nesting whitespace is stripped).

In later tutorials we will see where the *Support yaml* files come from and how to add your own.
