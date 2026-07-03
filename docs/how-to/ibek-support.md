# Updating and Testing ibek-support

The [ibek-support](https://github.com/epics-containers/ibek-support) repository
contains `ibek` support YAML (files named `*.ibek.support.yaml`). Here is an
example procedure for local testing of changes to support YAML in ibek-support
alongside the IOC instance YAML that uses it.

(Suggest you do this inside a developer workspace devcontainer.)

:::{note}
**DLS users:** obtain `uv` with `module load uv` before running
`uv tool install ibek`.
:::

```bash
cd my-workspace-folder

# clone ibek-support
git clone https://github.com/epics-containers/ibek-support.git
# clone a services repo that contains example IOC instance YAML
git clone https://github.com/epics-containers/example-services.git

# get the latest ibek installed
uv tool install ibek

cd example-services/services/bl01t-ea-test-01
ibek runtime generate config/ioc.yaml ../../../ibek-support/*/*ibek.support.yaml
```

This gets `ibek` to generate a startup script and a database generation script.
It uses `config/ioc.yaml` as the description of the IOC 'entities' to
instantiate, and the support YAML files in ibek-support as the source of the
definitions of the classes of entities available.

By default the generated files are written to the runtime output folder
(`/epics/runtime`); pass `-o <folder>` to write them somewhere else, for example
`-o .` to write into the current directory.

If your IOC instance is split across more than one entity file (for example
`config/ioc.yaml` plus extra entity YAML vendored into `config/` with
`ibek pattern add`), use `generate2`, which takes the config folder and
discovers all of them:

```bash
ibek runtime generate2 config --definitions ../../../ibek-support/*/*ibek.support.yaml
```
