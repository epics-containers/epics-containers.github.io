# Create an IOC Instance

## Introduction

The last section covered deploying and managing the example Instance that came with the template services repository. Here we will create a new IOC Instance that implements a simulated detector.

For this tutorial some familiarity with the EPICS AreaDetector framework is useful. Take a look at this documentation if you have not yet come across AreaDetector: <https://areadetector.github.io/master/index.html>.

(create-new-ioc-instance)=
## Add a New IOC Instance to t01-services

### Introduction

To create a new IOC Instance simply add a new folder to the `services` folder in your services repo. The name of the folder will be the name of the IOC. This folder needs to contain these items:

```{eval-rst}
=================== ====================================================
**compose.yml**     Instructions to compose to say what to deploy
**config**          A folder that contains the IOC instance
                    configuration files.
=================== ====================================================
```

The configuration files in the config folder can take a number of forms [listed here](https://github.com/epics-containers/ioc-template/blob/main/template/ioc/start.sh). The recommended contents of this folder is a single ibek IOC description yaml file named `ioc.yaml`. But the generic IOCs support raw startup script, substitution files and database files as well. Thus, users that have their own preferred way of generating startup assets can use that method, including hand written files.

### Using .ioc-template

The template project added a folder to `services` called `.ioc-template` this is a useful starting point to make a new service. Let us call our new IOC `bl01t-ea-cam-01`. We will copy the `.ioc-template` folder to a new folder called `bl01t-ea-cam-01` and then edit the `compose.yml` file to reflect the new IOC name:

```bash
cd t01-services
code .
# navigate to the services folder and copy the .ioc-template folder
# paste it into the services folder and rename it to bl01t-ea-cam-01
```

### Compose.yml

Our new example IOC will be a simulation detector using the AreaDetector SimDetector. There is already a Generic IOC for the SimDetector, therefore to create an IOC Instance, we just need to refer to that Generic IOC container image and provide some configuration for it.

You can find the Generic IOC container source for SimDetector here: <https://github.com/epics-containers/ioc-adsimdetector>. This repository publishes its container image at: `ghcr.io/epics-containers/ioc-adsimdetector-runtime:2024.8.1`. Later tutorials will cover how to build and publish your own Generic IOC container images.

Edit the `compose.yml` file in the `bl01t-ea-cam-01` folder to reflect the new IOC name and to refer to the Generic IOC container image for the SimDetector:

- find and replace **replace_me** with **bl01t-ea-cam-01**
- replace **replace_with_image_uri** with **ghcr.io/epics-containers/ioc-adsimdetector-runtime:2024.8.1**

That's it for the `compose.yml` file. This file is essentially boilerplate and would look very similar for every IOC Instance you create. The two unique things that this file does are:
- determine the name of the IOC
- determine the container image to use

Your compose.yml should now look like this:

```yaml
services:

  bl01t-ea-cam-01:

    extends:
      service: linux_ioc
      file: ../../include/ioc.yml

    image: ghcr.io/epics-containers/ioc-adsimdetector-runtime:2024.8.1

    labels:
      version: 0.1.0

    environment:
      IOCSH_PS1: bl01t-ea-cam-01 >
      IOC_NAME: bl01t-ea-cam-01

    volumes:
      - ../../opi/iocs/bl01t-ea-cam-01:/epics/opi

    configs:
      - source: bl01t-ea-cam-01_config
        target: epics/ioc/config

configs:
  bl01t-ea-cam-01_config:
    file: ./config

include:
  - path:
      ../../include/networks.yml
```

You can read about the format of a compose file here: <https://docs.docker.com/compose/compose-file>. Below is a brief description of the fields in our compose file:

```{eval-rst}
==================  =======================================================
field               description
==================  =======================================================
bl01t-ea-cam-01     declares that we are creating a service called
                    **bl01t-ea-cam-01**
extends             most of the definition of an ioc comes from the file
                    **include/ioc.yml**, we are extending that, which
                    means the dictionaries described by the two files are
                    merged
image               the container image to use
labels              arbitrary labels that can be used to filter services -
                    we use one to indicate the version of the IOC Instance
                    (as opposed to the version of the Generic IOC)
environment         environment variables to set in the container
IOCSH_PS1           ioc shell prompt
IOC_NAME            the name of the IOC
volumes             mount the IOC OPI files into the container at
                    **/epics/opi**
configs             mount the IOC config folder into the container at
                    **/epics/ioc/config**
include             include a shared definition of the container networks
                    we use
==================  =======================================================
```


### IOC Instance Config

The config folder can contain a variety of different files [as listed here](https://github.com/epics-containers/ioc-template/blob/main/ioc/start.sh). In this case we are going to define the Instance using an `ibek` IOC instance yaml file.

*IOC yaml* files are a sequence of `entities`. Each entity is an instance of an `entity_model` declared in the *Support yaml* that one of the support modules provides. `entity_models` can:

- define a set of parameters, that are to be used as substitutions below
- add templated lines of code to the startup script with substitutions
- instantiate 1 more more EPICS Database templates with a set of macro substitutions

Each `entity` listed in the *IOC yaml* file will create an instance of the support module `entity_model` that it refers to. It will pass a number of arguments to the `entity_model` that will be used to generate the startup script entries and EPICS Database entries for that entity. The `entity_model` is responsible for declaring the parameters it expects and how they are used in the script and DB entries it generates. It supplies types and descriptions for each of these parameters, plus may supply default values.

We will be creating a simulation detector from the `ioc-adsimdetector` Generic IOC. The following *Support yaml* for the simulation detector is baked into the container. Once you have your container up and running you can use `ec exec bl01t-ea-cam-01 bash` to get a shell inside and see this file at **/epics/ibek_defs/ADSimDetector.ibek.support.yaml**.

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ibek/releases/download/3.0.1/ibek.support.schema.json

module: ADSimDetector

entity_models:
  - name: simDetector
    description: |-
      Creates a simulation detector
    parameters:
      P:
        type: str
        description: Device Prefix
      R:
        type: str
        description: Device Suffix
      PORT:
        type: id
        description: Port name for the detector
      TIMEOUT:
        type: str
        description: Timeout
        default: "1"
      ADDR:
        type: str
        default: "0"
        description: Asyn Port address
      WIDTH:
        type: int
        default: 1280
        description: Image Width
      HEIGHT:
        type: int
        default: 1024
        description: Image Height
      DATATYPE:
        type: int
        description: Datatype
        default: 1
      BUFFERS:
        type: int
        description: Maximum number of NDArray buffers to be created for plugin callbacks
        default: 50
      MEMORY:
        type: int
        description: Max memory to allocate, should be maxw*maxh*nbuffer for driver and all attached plugins
        default: 0

    pre_init:
      - type: text
        value: |
          # simDetectorConfig(portName, maxSizeX, maxSizeY, dataType, maxBuffers, maxMemory)
          simDetectorConfig("{{PORT}}", {{WIDTH}}, {{HEIGHT}}, {{DATATYPE}}, {{BUFFERS}}, {{MEMORY}})

    databases:
      - file: $(ADSIMDETECTOR)/db/simDetector.template
        args:
          P:
          R:
          PORT:
          TIMEOUT:
          ADDR:

    pvi:
      yaml_path: simDetector.pvi.device.yaml
      ui_macros:
        P:
        R:
      pv: true
      pv_prefix: $(P)$(R)

```

You can see that this lists a number of parameters that it requires and several others that have defaults. It then declares how these will be used to substitute values into the simDetector database template. Finally it declares some lines to go into the startup script (`pre_init` means this goes before `iocInit`).

Note that the process for taking a *Support yaml* entity_model with values from *IOC yaml* entity and generating a startup script and EPICS Database uses Jinja2 templating. In its simplest form this just means that you can use `{{ }}` to substitute values from the *IOC yaml* arguments into the *Support yaml* `pre_init` and `databases` sections. When the database section provides no value for the parameters it lists this means that the argument is used verbatim, e.g. **$(ADSIMDETECTOR)/db/simDetector.template** is instantiated with `PORT=$(PORT)`, `P=$(P)` etc.

To learn more about Jinja templating see here: <https://jinja.palletsprojects.com/en/3.0.x/templates/>.

Therefore, we can update our *IOC yaml* file by adding an ADSimDetector entity to the entities list. In vscode, open **services/t01-ea-cam-01/config/ioc.yaml** and edit the boilerplate template so that it looks like the following:


```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ioc-adsimdetector/releases/download/2024.6.1/ibek.ioc.schema.json

ioc_name: "{{ _global.get_env('IOC_NAME') }}"

description: An IOC instance that simulates a detector

entities:
  - type: epics.EpicsEnvSet
    name: EPICS_TZ
    value: GMT0BST

  - type: devIocStats.iocAdminSoft
    IOC: "{{ ioc_name | upper }}"

  - type: ADSimDetector.simDetector
    PORT: DET.DET
    P: BL01T-EA-CAM-01
    R: ":DET:"
```

:::{note}
If you are unfamiliar with YAML then you could take a look at the YAML spec here: <https://yaml.org/spec/1.2.2/>. It is an extension of JSON (javascript object notation) that is designed to be human readable/writeable. It is also the format for all Kubernetes configuration files.

Be aware that white space is significant. i.e. indentation represents nesting. Above we have a list of entities, each list item is denoted by `-`. There are currently 3 entities in the list, each of which is a dictionary
of key value pairs. The last entry we just added has first key of `type` with value `ADSimDetector.simDetector`.
:::

This will create us a simulation detector driver with PV prefix `BL01T-EA-CAM-01:DET:` that publishes its output on the Asyn port `DET.DET`.

Be aware that YAML tries to minimize the amount of punctuation used. So strings can usually be written without quotes. But ':' and '{' are significant characters and if your string starts with one of these you must quote it.

Note that the Generic IOC includes all of the support modules that are dependencies of `ADSimDetector` and each of those contributes its own set of `entity_models` in its own *Support yaml* file. Let us also add an `AreaDetector` plugin and wire it to our simulation detector by adding this to our *IOC yaml* file:

```yaml

  - type: ADCore.NDStdArrays
    PORT: DET.ARR
    P: BL01T-EA-CAM-01
    R: ":ARR:"
    NDARRAY_PORT: DET.DET
    TYPE: Int8
    FTVL: CHAR
    NELEMENTS: 1048576
```

This adds a Standard Arrays plugin to the IOC that will publish the output of the simulation detector via channel access. The *Support yaml* that declared the plugin came from the ADCore module. This is a dependency of ADSimDetector and so is included in the Generic IOC container.

You have now defined your first IOC instance.

## Trying Out The IOC Instance

### Update the Services List

In the root of our services repository is the root compose.yml file that includes all of the services. We will edit that to add our new IOC. The result should look like this:

```yaml
include:
    # all profiles
    - services/example-test-01/compose.yml
    - services/bl01t-ea-cam-01/compose.yml
    - services/gateway/compose.yml

    # develop profile only
    - services/phoebus/compose.yml

    # deploy profile only
    - services/epics-opis/compose.yml
```

### Change the OPI screen

To make this tutorial more interactive, the template includes a hand coded bob screen for the ADSimDetector you just made. It has the few widgets necessary to start the detector, enable the stdarrays plugin and view the stdarrays plugin output.

You can make phoebus automatically load this screen upon startup by changing the `command` entrypoint in the `phoebus` service's `compose.yml` file. The bob file you need is called opi/demo-simdet.bob.

i.e.

```yaml
    command: phoebus-product/phoebus.sh -settings /config/settings.ini -resource /opi/demo-simdet.bob -server 7010
```

### Launch the IOC Instance

We can launch all the services in the beamline as we did in the earlier tutorial as follows:

```bash
cd t01-services
source ./environment.sh
ec up -d
```

The new screen will allow you to hit 'Acquire' on the CAMERA pane, and 'Enable' on the Standard Array pane. You should see the moving image from the simulation detector in the right hand image pane.

The screen has a link to the autogenerated OPI screens for the IOC Instance. If you click the `bl01t-ea-cam-01` button you will see a list of the 'entities' that were instantiated in the IOC Instance. You can click on each of these to see the engineering screen of the entity which includes all of the PVs that it made.


## Ibek Explanation

### Overview

Above we looked at some ibek *Support yaml* and created an *IOC yaml* file.
The details of where *Support yaml* files come from and how to create your
own are covered in a later tutorial {any}`generic_ioc`.

However, without looking into the set of *Support yaml* files that are
inside a given Generic IOC we can still make a meaningful *IOC yaml* file.
That is because every Generic IOC publishes an *IOC schema* that describes
the set of entities that an instance of that IOC may instantiate.

The Generic IOC we used was released at this location:
<https://github.com/epics-containers/ioc-adsimdetector/releases/tag/2024.2.2>.
This page includes the assets that are published as part of the release and
one of those is `ibek.ioc.schema.json`. This is the *IOC schema* for the
`ioc-adsimdetector` Generic IOC. This is what we referred to at the top of
our *IOC yaml* file like this:

```yaml
# yaml-language-server: $schema=https://github.com/epics-containers/ioc-adsimdetector/releases/download/2024.6.1/ibek.ioc.schema.json
```

When editing with a YAML aware editor like VSCode this will enable auto
completion and validation of the *IOC yaml* file. To enable this in VSCode
you will need to install the YAML extension from here:
<https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml>

Now is a good time to try installing the extension and experimenting with
editing the *IOC yaml* file.

Using `ibek` yaml files to describe IOC instances has the following advantages:

- there is pre-runtime checking that the IOC Instance is valid
- instance authors are guided by schema
- details of what a support module needs to be instantiated are under the
  control of the support module author (at Generic IOC specification time).
- functions with long argument lists are made easier to use because the
  instance author supplies named arguments only.

However, if you already have a framework for generating startup assets or you
prefer hand coding them, this is also supported.


### Experiment With Changes

The engineering screens are generated by PVI at startup. We will look into PVI in more detail in a later tutorial. But for now you could experiment with adding more AreaDetector plugins to your IOC Instance and seeing how the additional engineering screens get added. If you try editing your *IOC yaml* file you will see that what you can add is controlled by the schema that the Generic IOC publishes. This makes it easier to create valid IOC Instances.

First make sure that you have the 'Redhat YAML' extension installed in VSCode. This will give you auto completion and validation of your *IOC yaml* file based on the schema line at the top of the file.

Now try adding the following to the entities list in your *IOC yaml* file:

```yaml
  - type: ADCore.N
```

You should find that auto-completion will list all the types of plugin that you can add. Go ahead and complete it with 'NDProcess'.

Now you will see a red squiggle at the start of 'type'. Hover over this and it will show you the parameters that you are required to supply to NDProcess.

:::{figure} ../images/ioc-yaml-schema.png
using schema to add an NDProcess plugin
:::

Fill out the rest of you NDProcess entity as follows:
```yaml
  - type: ADCore.NDProcess
    PORT: DET.PROC
    P: BL01T-EA-CAM-01
    R: ":PROC:"
    NDARRAY_PORT: DET.DET
```

Now restart you simulation detector IOC:

```bash
ec restart bl01t-ea-cam-01
```

Once it is back up you can click on the bl01t-ea-cam-01 button in the 'Autogenerated Engineering Screens' pane and you will see a new 'NDProcess' entity. If you know about wiring up AreaDetector you can now wire this plugin into your pipeline and make modifications to the image data as it passes through.


## Raw Startup Script and Database

This section demonstrates how to use your own startup assets. This involves
placing your own `st.cmd` and `ioc.subst` files in the **config**
folder. Or alternatively you could override behaviour completely by placing
`start.sh` in the **config** folder, this can contain any script you like.

To see what ibek generated you can go and look inside the IOC container:

```bash
ec exec bl01t-ea-test-02
cd /epics/runtime/
cat ioc.subst
cat st.cmd
```

:::{note}
The startup script and database are generated at container run time,
by `ibek`. They are generated in the /epics/runtime folder
of the container.
In Kubernetes this will be a persistent volume so that it can be
shared for easy debugging of IOC Instances.
:::

If you would like to see an IOC Instance that uses a raw startup script and
database then you can copy these two files out of the container and into
your IOC Instance config folder like this (replace docker with
docker if that is what you are using):

```bash
docker cp t01-services-bl01t-ea-cam-01-1:/epics/runtime/st.cmd services/bl01t-ea-cam-01/config
docker cp t01-services-bl01t-ea-cam-01-1:/epics/runtime/ioc.subst services/bl01t-ea-cam-01/config/ioc.subst
# no longer need an ibek ioc yaml file
rm services/bl01t-ea-test-02/config/ioc.yaml
```

You will need to make a minor change to the `ioc.subst` file. Edit this and remove references to the two template files with `.pvi` in their name. These are PVI generated templates for use with OphydAsync and are not available in manually build IOC Instances.

Your IOC Instance will now be using the raw startup script and database. But should behave exactly the same as before. You are free to experiment with changes in the startup script and substitution file and re-deploy the IOC.

Restart the IOC to see it operating as before (except that engineering screen generation will no longer happen):
```bash
ec restart bl01t-ea-cam-01
```
