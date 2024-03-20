# Changing the IOC Instance

This tutorial will make a very simple change to the example IOC `bl01t-ea-test-02`.
This is a type 1 change from {any}`ioc-change-types`, types 2, 3 will be covered in the
following 2 tutorials.

Strictly speaking, Type 1 changes do not require a devcontainer. You created
and deployed the IOC instance in a previous tutorial without one. It is up to
you how you choose to make these types of changes. Types 2,3 do require a
devcontainer because they involve compiling Generic IOC / support module code.

These instructions are for running inside the devcontainer. If you closed your developer container from the last tutorial, then open it again now. To do open your `bl01t` folder in vscode and then press `Ctrl-Shift-P` and type `Remote-Containers: Reopen in Container`.

We are going to add a hand crafted EPICS DB file to the IOC instance. This will be a simple record that we will be able to query to verify that the change is working. We will use the version of the IOC instance that used `ioc.yaml`. If you changed to using raw startup assets in the previous tutorial then revert to using `ioc.yaml` for this tutorial or see [](raw-startup-assets).

:::{note}
Before doing this tutorial make sure you have not left the IOC bl01t-ea-test-02 running from a previous tutorial. Execute this command *outside* of the devcontainer to stop it:

```bash
ec stop bl01t-ea-test-02
```
:::

Make the following changes in your test IOC config folder
(`bl01t/services/bl01t-ea-test-02/config`):

1. Add a file called `extra.db` with the following contents.

   ```text
   record(ai, "bl01t-ea-test-02:TEST") {
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

You can immediately test your changes by running the IOC locally. The following
command will run the IOC locally using the config files in your test IOC config
folder:

```bash
# stop any existing IOC shell by hitting Ctrl-D or typing exit
cd /epics/ioc
./start.sh
```

If all is well you should see your iocShell prompt and the output should
show `dbLoadRecords(config/extra.db)`.

Test your change
from another terminal (VSCode menus -> Terminal -> New Terminal) like so:

```bash
caget bl01t-ea-test-02:TEST
```

If you see the value 1 then your change is working.

:::{Note}
If you are using podman, you are likely to see *"Identical process variable names on multiple servers"* warnings. This is because caget can see the PV on the host network and the container network, but as these are the same IOC this is not a problem.

You can change this and make your devcontainer network isolated by removing the line `"--net=host",` from `.devcontainer/devcontainer.json`, but it is convenient to leave it if you want to run OPI tools locally on the
host. You may want to isolate your development network if multiple developers are working on the same subnet. In this case some other solution is required for running OPI tools on the host (TODO add link to solution - likely to be container networks).
:::

Because of the symlink between `/epics/ioc/config` and
`/workspaces/bl01t/services/bl01t-ea-test-02/config` the same files you are testing
by launching the IOC inside of the devcontainer are also ready to be
committed and pushed to the bl01t repo. i.e.:

```bash
# Do this from a host terminal (not a devcontainer terminal)
cd bl01t
git add .
git commit -m "Added extra.db"
git push
# tag a new version of the beamline repo
git tag 2024.3.2
git push origin 2024.3.2
# deploy the new version of the IOC to the local docker / podman instance
ec deploy bl01t-ea-test-02 2024.3.2
```

You can now see that the versioned IOC instance is running and loading the extra.db by looking at its log with:

```bash
ec logs bl01t-ea-test-02
```


The above steps were performed on a host terminal because we are using `ec`. However all of the steps except for the `ec` command could have been done *inside* the devcontainer starting with `cd /workspaces/bl01t` which is where your project is mounted *inside* the devcontainer.

We choose not to have `ec` installed inside of the devcontainer because that would involve containers in containers which adds too much complexity.

If you like working entirely from the vscode window you can open a terminal in vscode *outside* of the devcontainer. To do so, press `Ctrl-Shift-P` and choose the commnd `Terminal: Create New Integrated Terminal (Local)`. This will open a terminal to the host. You can then run `ec` from there.

(raw-startup-assets)=
## Raw Startup Assets

If you plan not to use `ibek` runtime asset creation you could use the raw
startup assets from the previous tutorial. If you do this then the process
above is identical except that you will add the `dbLoadRecords` command to
the end of `st.cmd`.

## More about ibek Runtime Asset Creation

The set of `entities` that you may create in your ioc.yaml is defined by the
`ibek` IOC schema that we reference at the top of `ioc.yaml`.
The schema is in turn defined by the set of support modules that were compiled
into the Generic IOC (ioc-adsimdetector). Each support module has an
`ibek` *support YAML* file that contributes to the schema.

The *Support yaml* files are in the folder `/epics/ibek-defs` inside of the
container. They were placed there during the compilation of the support
modules at Generic IOC build time.

It can be instructive to look at these files to see what entities are available
to *IOC instances*. For example the global support yaml file
`/epics/ibek-defs/epics.ibek.support.yaml` contains the following:

```yaml
- name: StartupCommand
  description: Adds an arbitrary command in the startup script before iocInit
  args:
    - type: str
      name: command
      description: command string
      default: ""
  pre_init:
    - type: text
      value: "{{ command }}"

- name: PostStartupCommand
  description: Adds an arbitrary command in the startup script after iocInit
  args:
    - type: str
      name: command
      description: command string
      default: ""
  post_init:
    - type: text
      value: "{{ command }}"
```

These two definitions allow you to add arbitrary commands to the startup script
before and after iocInit. This is how we added the `dbLoadRecords` command.

If you want to specify multiple lines in a command you can use the following
syntax for multi-line stings:

> ```yaml
> - type: epics.StartupCommand
>   command: |
>     # loading extra records
>     dbLoadRecords(config/extra.db)
>     # loading even more records
>     dbLoadRecords(config/extra2.db)
> ```

This would place the 4 lines verbatim into the startup script (except that
they would not be indented - the nesting whitespace is stripped).

In later tutorials we will see where the *Support yaml* files come from and
how to add your own.
