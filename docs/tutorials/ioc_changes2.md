# Changing a Generic IOC

This is a type 2 change from {any}`ioc-change-types`.

The changes that you can make in an IOC instance are limited to what
the author of the associated Generic IOC has made configurable.
Therefore you will
occasionally need to update the Generic IOC that your instance is using.
Some of the reasons for doing this are:

- Update one or more support modules to new versions
- Add additional support such as autosave or iocStats
- For ibek generated IOC instances, you may need to add or change functionality
  in the support YAML file.

:::{note}
If you are considering making a change to a Generic IOC because you want to add support for a second device, this is allowed but you should consider the alternative of creating a new Generic IOC for the second device. If you keep your Generic IOCs simple and focused on a single device, they will be smaller and there will be less of them. IOCs' records can still be linked via CA links and this is preferable to recompiling a Generic IOC for every possible combination of devices. Using Kubernetes to manage multiple small services is cleaner than having a handful of monolithic services.

Having said this. If there is a common collection of devices that are frequently deployed together and usually restarted together then there is merit in making a Generic IOC for that collection. For example, at DLS we have a Single generic IOC for the set of vacuum equipment that we deploy on every beamline.
:::

This tutorial will make some changes to the generic IOC `ioc-adsimdetector` that you already used in earlier tutorials.

For this exercise we will work locally inside the `ioc-adsimdetector` developer container and will not commit our changes back. Following tutorials will show how to fork repositories and push changes back to GitHub

For this exercise we will be using an example IOC Instance to test our changes. Instead of working with a beamline repository, we will use the example ioc instance that is already inside `ioc-adsimdetector`. It is a good idea for Generic IOC authors to include an example IOC Instance in their repository for testing changes in isolation. Obviously, this is easy for a simulation IOC, for IOCs that normally connect to real hardware this would require a simulator of some kind.

## Preparation

First, clone the `ioc-adsimdetector` repository and make sure the container build is working. You may also use the existing clone you have from previous tutorials.

```bash
git clone --recursive git@github.com:epics-containers/ioc-adsimdetector.git
cd ioc-adsimdetector
code .
# ctrl+shift+p and choose "Remote-Containers: Reopen in Container"
```

## Verify the Example IOC Instance is working

When a new Generic IOC developer container is opened, there are two things that need to be done before you can run an IOC instance inside of it.

- Build the IOC binary
- Select an IOC instance definition to run

The folder `ioc` inside of the `ioc-adsimdetector` is where the IOC source code resides. However our containers always make a symlink to this folder at `/epics/ioc`. This is so that it is always in the same place and can easily be found by ibek (and the developer!). Therefore you can build the IOC binary with the following command:

```bash
cd /epics/ioc
make
```

The IOC instance definition is a YAML file that tells `ibek` what the runtime assets (ie. EPICS DB and startup script) should look like. Previous tutorials selected the IOC instance definition from a beamline repository. In this case we will use the example IOC instance that comes with `ioc-adsimdetector`. It can be found in `services/bl01t-ea-ioc-02`. The following command will select the example IOC instance:

```bash
ibek dev instance /workspaces/ioc-adsimdetector/services/bl01t-ea-ioc-02
```

The above command removes the existing config folder `/epics/ioc/config` and symlinks in the chosen IOC instance definition's `config` folder to  `/epics/ioc/config`.

Now run the IOC:

```bash
./start.sh
```

You should see an iocShell prompt and no error messages above.

Let us also make sure we can see the simulation images that the IOC is producing. For this we will use phoebus and we will create a screen to display the image. Previously we had a pre-defined screen from the template project for this - but this example IOC uses a different PV prefix so we need to create a new screen.

From *outside of the developer container* start up phoebus using the supplied script:

```bash
cd ioc-adsimdetector
./opi/phoebus-launch.sh
```

Phoebus should now be up and running and showing the auto generated **index.bob**, In phoebus do the following steps:

- right click in the index.bob screen and choose "Open in editor"
- from the plots section of the widget pallet select "Image" and drag a rectangle for you image widget in the index.bob screen.
- in the properties pane
  - deselect X and Y axis Visible checkboxes
  - set PV Name to 'BL01T-EA-TST-02:ARR:ArrayData'
  - set Name to 'SimDetector Image'
  - set Data Width and Data Height to 1024
- choose File -> Save As and save as `/workspaces/ioc-adsimdetector/services/opi/bl01t-ea-ioc-02.bob`
- note you will need to create the opi folder under services
- click the 'Execute Display' green arrow button on the right of the top toolbar


::: {note}
We saved the screen in **services/opi** because this is a hand crafted overview screen specific to an IOC instance described in that **services** folder. The root **opi** folder is reserved for generic screens (i.e. with macros) and as a place for auto-generated screens to go when running the developer container.
:::

Back inside the developer container, you can now start the detector and the Std Arrays plugin, by opening a new terminal and running the following:

```bash
caput BL01T-EA-TST-02:ARR:EnableCallbacks 1
caput BL01T-EA-TST-02:DET:Acquire 1
```

You should see the moving image in the Phoebus window. We now have a working
IOC instance that we can use to test our changes.


:::{figure} ../images/phoebus2.png
Phoebus with image widget
:::

Note: the buttons to launch the engineering screens won't work right away because your new screen is in a different folder. To fix this, go back into the screen editor and add `../../opi/auto-generated/` to the beginning of the `Display Path` in the `Open Display` action for each button.

## Making a change to the Generic IOC

One interesting way of changing a Generic IOC is to modify the support YAML
for one of the support modules. The support YAML describes the `entities` that
an IOC instance can make use of in its instance YAML file. This will be
covered in much more detail in {any}`generic_ioc`.

For this exercise we will make a change to the `ioc-adsimdetector` support
YAML file. We will change the startup script that it generates so that the
simulation detector is automatically started when the IOC starts.

To make this change we just need to have the startup script set the values
of the records `BL01T-EA-TST-02:DET:Acquire` and
`BL01T-EA-TST-02:ARR:EnableCallbacks` to 1.

To make this change, open the file
`/workspaces/ioc-adsimdetector/ibek-support/ADSimDetector/ADSimDetector.ibek.support.yaml`
and add a `post_init` section just after the `pre_init` section:

```yaml
post_init:
  - type: text
    value: |
      dbpf {{P}}{{R}}Acquire 1
```

Next make a change to the file `/workspaces/ioc-adsimdetector/ibek-support/ADCore/ADCore.ibek.support.yaml`.
Find the `NDStdArrays`, `NDROI`, and `NDProcess` sections and also add a `post_init` section to each one:

```yaml
post_init:
  - type: text
    value: |
      dbpf {{P}}{{R}}EnableCallbacks 1
```

The values that you add into entities like the above are rendered at runtime to make the startup script. The `{{P}}` and `{{R}}` are placeholders that are replaced with the PV prefix and record name of the IOC instance. They are rendered using Jinja with a context that includes all of the values of the parameters in the entity. You can go and look at your rendered startup script in `/epics/runtime/st.cmd`.

If you now go to the terminal where you ran your IOC, you can stop it with
`Ctrl+C` and then start it again with `./start.sh`. You should see the
following output at the end of the startup log:

```console
dbpf BL01T-EA-TST-02:DET:Acquire 1
DBF_STRING:         "Acquire"
dbpf BL01T-EA-TST-02:ROI:EnableCallbacks 1
DBF_STRING:         "Enable"
dbpf BL01T-EA-TST-02:PROC:EnableCallbacks 1
DBF_STRING:         "Enable"
dbpf BL01T-EA-TST-02:ARR:EnableCallbacks 1
DBF_STRING:         "Enable"
epics>
```

You should also see the demo window update with the moving image again.

If you wanted to publish these changes you would have to commit both the
`ibek-support` submodule and the `ioc-adsimdetector` repository and push
them in that order because of the sub-module dependency. But we won't be
pushing these changes as they are just for demonstration purposes. In later
tutorials we will cover making forks and doing pull requests for when you have
changes to share back with the community.

Note: this is a slightly artificial example, as it would change the behaviour
for all instances of a StdArray plugin and a simDetector. In a real IOC you would
do this on a per instance basis.

Let us quickly do the instance YAML change to demonstrate the correct approach
to this auto-starting detector.

Undo the support yaml changes:

```bash
cd /workspaces/ioc-adsimdetector/ibek-support
git reset --hard
```

If you restart the IOC now you will see that the detector does not start.

Add the following to
`/epics/ioc/config/ioc.yaml`:

```yaml
  - type: epics.dbpf
    pv: BL01T-EA-TST-02:DET:Acquire
    value: "1"

  - type: epics.dbpf
    pv: BL01T-EA-TST-02:ROI:EnableCallbacks
    value: "1"

  - type: epics.dbpf
    pv: BL01T-EA-TST-02:PROC:EnableCallbacks
    value: "1"

  - type: epics.dbpf
    pv: BL01T-EA-TST-02:ARR:EnableCallbacks
    value: "1"
```

Now restart the IOC and you should see the same behaviour as before. Here
we have made the change on a per instance basis, and used the `dbpf` entity
declared globally in `ibek-support/_global/epics.ibek.support.yaml`.
