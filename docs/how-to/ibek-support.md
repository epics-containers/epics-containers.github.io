# Updating and Testing ibek-support

The [ibek-support](https://github.com/epics-containers/ibek-support) repository
holds the build recipe (`<module>.install.yml`) and the `ibek` support YAML
(`*.ibek.support.yaml`) of each support module. Each Generic IOC has it as the
`ibek-support` submodule. This page shows how to test changes to it.

## In a Generic IOC developer container

The best place to test a change to `ibek-support` is the developer container of
a Generic IOC that uses the modules you are changing. The container's support
modules and definition links come from the image, and the `ibek dev` commands
bring them in line with your checkout of the submodule (see
{any}`devcontainer-drift`).

Make the change in the submodule: edit its files, or check out the branch that
holds the change, on the host or in the container:

```bash
# in the container; on the host, use your clone's ibek-support folder
cd /workspaces/ioc-xxx/ibek-support
git fetch
git checkout <branch>
```

Then, in the container, see how the container differs from your checkout:

```bash
ibek dev status
```

- Changes to definition files (`*.ibek.support.yaml`, `*.pvi.device.yaml`,
  `*.req`) need no build. `ibek dev sync` links them again and regenerates the
  IOC schema. The container runs it on every start; run it yourself after a
  change:

  ```bash
  ibek dev sync
  ```

- Changes that need a build, such as an `install.yml` change or a move of the
  submodule to a commit with other recipes, are reported with the command that
  rebuilds them. It rebuilds each changed module, every module after it in the
  `Dockerfile`, and then the IOC:

  ```bash
  ibek dev sync --build
  ```

Then test an IOC instance that uses the modules:

```bash
ibek dev instance /workspaces/<services-repo>/services/<ioc-instance>
cd /epics/ioc
make
./start.sh
```

`make` builds the IOC binary, which a new container does not have.
`ibek dev instance` also prints how the container differs from your checkout,
so you can see that nothing is left to sync before you start the IOC.

To publish the change, commit and push it in `ibek-support` first, then commit
the new submodule commit in the Generic IOC repository.

## Without a container

You can also check support YAML against IOC instance YAML with `ibek` alone,
outside any container. This generates the startup script and database from the
files, but builds nothing.

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
