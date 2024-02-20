# Builder2ibek.support Conversion Tool

:::{warning}
This page is only relevant to DLS users who are converting
a DLS support module with builder support into an epics-containers
Generic IOC. i.e. support modules that have an `etc/builder.py` file.
:::

TODO: this page is WIP and will be updated by Feb 2024.

`builder2ibek.support` is a tool to convert DLS builder support modules
into ibek support YAML for the `ibek-support` repository.

## builder2ibek.support example

```bash
./builder2ibek.support.py /dls_sw/prod/R3.14.12.7/support/lakeshore340/2-6 ioc-lakeshore340/ibek-support/lakeshore340/lakeshore340.yaml
```

```xml
   <?xml version="1.0" ?>
   <components arch="linux-x86_64">
       <devIocStats.devIocStatsHelper ioc="BL16I-EA-IOC-07" name="STATS"/>
       <asyn.AsynIP name="p1" port="127.0.0.1:5400"/>
       <lakeshore340.lakeshore340 ADDR="12" LOOP="1" P="BL16I-EA-LS340-01" PORT="p1" SCAN="5" TEMPSCAN="1" gda_desc="Lakeshore 340 Temperature Controller" gda_name="LS340b" name="lakeshore"/>
       <EPICS_BASE.dbpf name="d1" pv="BL16I-EA-LS340-01:DISABLE" value="1"/>
   </components>


.. code:: yaml

   # yaml-language-server: $schema=https://github.com/epics-containers/ibek/releases/download/1.2.0/ibek.support.schema.json

   module: lakeshore340

   defs:

   - name: lakeshore340
       description: |-
       Lakeshore 340 Temperature Controller
       Notes: The temperatures in Kelvin are archived once every 10 secs.
       args:

       - type: str
           name: P
           description: |-
           Prefix for PV name

       - type: str
           name: PORT
           description: |-
           Bus/Port Address (eg. ASYN Port).

       - type: str
           name: ADDR
           description: |-
           Address on the bus

       - type: str
           name: SCAN
           description: |-
           SCAN rate for non-temperature/voltage parameters.

       - type: str
           name: TEMPSCAN
           description: |-
           SCAN rate for the temperature/voltage readings

       - type: id
           name: name
           description: |-
           Object and gui association name

       - type: str
           name: gda_name
           description: |-
           Name in gda interface file (Default = )

       - type: str
           name: gda_desc
           description: |-
           Description in gda interface file (Default = )

       - type: int
           name: LOOP
           description: |-
           Which heater PID loop to control (Default = 1)
           default: 1

       databases:

       - file: $(LAKESHORE340)/db/lakeshore340.template
           args:
           name:
           SCAN:
           gda_name:
           P:
           TEMPSCAN:
           gda_desc:
           PORT:
           LOOP:
           ADDR:
```
