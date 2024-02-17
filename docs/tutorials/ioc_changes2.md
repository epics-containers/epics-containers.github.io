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
If you are considering making a change to a Generic IOC because you
want to add support for a second device, this is allowed but you should
consider the alternative of creating a new Generic IOC.
If you keep your Generic IOCs simple and focused on a single device, they
will be smaller and there will be less of them. IOCs' records can still be
linked via CA links and this is preferable to recompiling a Generic IOC
for every possible combination of devices. Using Kubernetes to
manage multiple small services is cleaner than having a handful of
monolithic services.
:::

This tutorial will make some changes to the generic IOC `ioc-adsimdetector`
that you already used in earlier tutorials.

For this exercise we will work locally inside the `ioc-adsimdetector`
developer container. Following tutorials will show how to fork repositories
and push changes back to GitHub

For this exercise we will be using an example IOC Instance to test our changes.
Instead of working with a beamline repository, we will use the example ioc instance
inside `ioc-adsimdetector`. It is a good idea for Generic IOC authors to
include an example IOC Instance in their repository for testing changes in
isolation.

## Preparation

First, clone the `ioc-adsimdetector` repository and make sure the container
build is working:

```console
git clone git@github.com:epics-containers/ioc-adsimdetector.git
cd ioc-adsimdetector
./build
code .
# Choose "Reopen in Container"
```

Note that if you do not see the prompt to reopen in container, you can open
the `Remote` menu with `Ctrl+Alt+O` and select `Reopen in Container`.

The `build` script does two things.

- it fetches the git submodule called `ibek-support`. This submodule is shared
  between all the EPICS IOC container images and contains the support YAML files
  that tell `ibek` how to build support modules inside the container
  environment and how to use them at runtime.
- it builds the Generic IOC container image developer target locally using
  podman or docker.

## Verify the Example IOC Instance is working

When a new Generic IOC developer container is opened, there are two things
that need to be done before you can run an IOC instance inside of it.

- Build the IOC binary
- Select an IOC instance definition to run

The folder `ioc` inside of the `ioc-adsimdetector` is where the IOC source code
resided. However our containers always make a symlink to this folder at
`/epics/ioc`. This is so that it is always in the same place and can easily be
found by ibek (and the developer!). Therefore you can build the binary with the
following command:

```console
cd /epics/ioc
make
```

:::{note}
Note that we are required to build the IOC.
This is even though the container you are using already had the IOC
source code built by its Dockerfile (`ioc-adsimdetector/Dockerfile`
contains the same command).

For a detailed explanation of why this is the case see {any}`ioc-source`
:::

The IOC instance definition is a YAML file that tells `ibek` what the runtime
assets (ie. EPICS DB and startup script) should look like. Previous tutorials
selected the IOC instance definition from a beamline repository. In this case
we will use the example IOC instance that comes with `ioc-adsimdetector`. The
following command will select the example IOC instance:

```console
ibek dev instance /workspaces/ioc-adsimdetector/ioc_examples/bl01t-ea-test-02
```

The above command removes the existing config folder `/epics/ioc/config` and
symlinks in the chosen IOC instance definition's `config` folder.

Now run the IOC:

```console
cd /epics/ioc
./start.sh
```

You should see an iocShell prompt and no error messages above.

Let us also make sure we can see the simulation images that the IOC is
producing. For this we need the `c2dv` tool that we used earlier. You
can use the same virtual environment that you created earlier, or create
a new one and install again. Note that these commands are to be run
in a terminal outside of the developer container.

```console
python3 -m venv c2dv
source ~/c2dv/bin/activate
pip install c2dataviewer
```

Run the `c2dv` tool and connect it to our IOCs PVA output:

```console
c2dv --pv BL01T-EA-TST-03:PVA:OUTPUT &
```

Back inside the developer container, you can now start the detector and
the PVA plugin, by opening a new terminal and running the following:

```console
caput BL01T-EA-TST-03:PVA:EnableCallbacks 1
caput BL01T-EA-TST-03:CAM:Acquire 1
```

You should see the moving image in the `c2dv` window. We now have a working
IOC instance that we can use to test our changes.

## Making a change to the Generic IOC

One interesting way of changing a Generic IOC is to modify the support YAML
for one of the support modules. The support YAML describes the `entities` that
an IOC instance can make use of in its instance YAML file. This will be
covered in much more detail in {any}`generic_ioc`.

For this exercise we will make a change to the `ioc-adsimdetector` support
YAML file. We will change the startup script that it generates so that the
simulation detector is automatically started when the IOC starts.

To make this change we just need to have the startup script set the values
of the records `BL01T-EA-TST-03:CAM:Acquire` and
`BL01T-EA-TST-03:PVA:EnableCallbacks` to 1.

To make this change, open the file
`ibek-support/ADSimDetector/ADSimDetector.ibek.support.yaml`
and add a `post_init` section just after the `pre_init` section:

```yaml
post_init:
  - type: text
    value: |
      dbpf {{P}}{{R}}Acquire 1
```

Next make a change to the file `ibek-support/ADCore/ADCore.ibek.support.yaml`.
Find the NDPvaPlugin section and also add a `post_init` section:

```yaml
post_init:
  - type: text
    value: |
      dbpf {{P}}{{R}}EnableCallbacks 1
```

If you now go to the terminal where you ran your IOC, you can stop it with
`Ctrl+C` and then start it again with `./start.sh`. You should see the
following output at the end of the startup log:

```console
dbpf BL01T-EA-TST-03:CAM:Acquire 1
DBF_STRING:         "Acquire"
dbpf BL01T-EA-TST-03:PVA:EnableCallbacks 1
DBF_STRING:         "Enable"
epics>
```

You should also see the `c2dv` window update with the moving image again.

If you wanted to publish these changes you would have to commit both the
`ibek-support` submodule and the `ioc-adsimdetector` repository and push
them in that order because of the sub-module dependency. But we won't be
pushing these changes as they are just for demonstration purposes. In later
tutorials we will cover making forks and doing pull requests for when you have
changes to share back with the community.

Note: this is a slightly artificial example, as it would change the behaviour
for all instances of a PVA plugin and a simDetector. In a real IOC you would
do this on a per instance basis.

Let us quickly do the instance YAML change to demonstrate the correct approach
to this auto-starting detector.

Undo the support yaml changes:

```console
cd /workspaces/ioc-adsimdetector/ibek-support
git reset --hard
```

Add the following to
`/workspaces/ioc-adsimdetector/ioc_examples/bl01t-ea-test-02/config/ioc.yaml`:

```yaml
- type: epics.dbpf
  pv: BL01T-EA-TST-03:CAM:Acquire
  value: "1"

- type: epics.dbpf
  pv: BL01T-EA-TST-03:PVA:EnableCallbacks
  value: "1"
```

Now restart the IOC and you should see the same behaviour as before. Here
we have made the change on a per instance basis, and used the `dbpf` entity
declared globally in `ibek-support/_global/epics.ibek.support.yaml`.
