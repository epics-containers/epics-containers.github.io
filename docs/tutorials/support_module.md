# Change a Support Module

In {any}`generic_ioc` you wrapped an existing support module, `ADSimDetector`,
without changing its source. This tutorial changes the source of the module
itself, the most common **type 3** change from {any}`ioc-change-types`: add a
record, fix a driver bug, expose a new parameter. You build the change in the
developer container of the Generic IOC with `ibek dev support`, test it, publish
it, and point the module's `ibek-support` recipe at the release that holds it.

The worked example adds a record to `ADSimDetector` in the `ioc-adsim-demo`
project from {any}`generic_ioc`. The same steps work for any module that a
Generic IOC builds. The last section starts a brand-new module the same way.

[](../explanations/devcontainer.md) explains what the commands do in more
detail (see [](devcontainer-dev-support)).

## Before you start

Open the `ioc-adsim-demo` project in its developer container, as in
{any}`generic_ioc`. `ibek dev support` needs ibek 4.12.0 or later in the
container:

```bash
# in the container
ibek --version
```

If it is earlier, follow [](devcontainer-ibek-version) first.

## Build the module from a clone

In a terminal in the container:

```bash
# in the container
ibek dev support ADSimDetector
```

The command:

1. clones the repository named in
   `ibek-support/ADSimDetector/ADSimDetector.install.yml` to
   `/workspaces/ADSimDetector`, at its `version`, `R2-11`. On the host that
   folder is next to your `ioc-adsim-demo` folder;
2. removes the `ADSimDetector` that the image built and links
   `/epics/support/ADSimDetector` to the clone;
3. builds `ADSimDetector`, the modules after it in the `Dockerfile`, and the
   IOC.

It ends with the comparison of the container with the project, which says
that `ADSimDetector` is linked to its clone. Add `/workspaces/ADSimDetector` to the
VSCode workspace (`File -> Add Folder to Workspace`) to edit it.

The build leaves its mark on the clone. The files it makes are hidden from
`git status`, by the module's `.gitignore` or, where that does not cover them,
by the clone's `.git/info/exclude`. It also edits `configure/RELEASE` so that the module builds against the
other modules in the container. That edit shows in `git status`: do not commit
it.

## Change the source

Add a record to the end of
`/workspaces/ADSimDetector/simDetectorApp/Db/simDetector.template`:

```text
record(stringin, "$(P)$(R)Greeting")
{
   field(VAL, "Hello from my ADSimDetector")
}
```

Build the module again, with the modules after it and the IOC:

```bash
# in the container
ibek dev support ADSimDetector
```

Run the same command after each change to the source.

## Test it

Run the instance from {any}`generic_ioc`:

```bash
ibek dev instance /workspaces/t01-services/services/bl01t-ea-cam-01
cd /epics/ioc
./start.sh
```

At the `epics>` prompt, find the record and read it:

```text
epics> dbgrep "*Greeting"
epics> dbgf <the record name that dbgrep printed>
```

`dbgf` prints `Hello from my ADSimDetector`. Stop the IOC with `Ctrl-D`.

## Publish the change

An `ibek-support` recipe builds a module from a git repository at a given
version, so the change needs a release in a repository before a Generic IOC
image can build it. You cannot push to `areaDetector/ADSimDetector`, so fork it
on GitHub and push the change to your fork. Commit only your own change, not
the edit to `configure/RELEASE`:

```bash
# on the host, or in the container
cd /workspaces/ADSimDetector
git checkout -b greeting
git add simDetectorApp/Db/simDetector.template
git commit -m "Add a Greeting record"
git remote add fork <YOUR FORK HTTPS URL>
git push fork greeting
git tag R2-11-greeting
git push fork R2-11-greeting
```

For a change that others need too, open a pull request at the module's own
repository, and point the recipe at the release that includes it once the
maintainers make one. For the tutorial, the tag in your fork will do.

Point the recipe at the tag. Edit
`ibek-support/ADSimDetector/ADSimDetector.install.yml` in the project:

```yaml
version: R2-11-greeting
organization: https://github.com/<YOUR GITHUB USER>/
```

## Build the release

Stop building from the clone, and build the version of the recipe instead:

```bash
# in the container
ibek dev support --release ADSimDetector
ibek dev sync --build
```

`--release` removes the link to the clone and builds nothing; the clone stays
on the host. `ibek dev sync --build` then clones `ADSimDetector` at
`R2-11-greeting` from your fork and builds it, the modules after it and the
IOC, as the image build will. Run the instance again to check that the record
is there.

Commit the recipe in your `ibek-support` fork, commit the new submodule commit
in `ioc-adsim-demo`, push both and release the Generic IOC, as in
[](generic-ioc-release-submodule).

## Start a brand-new module

A new support module is worked on in the same way, once it has a repository and
a minimal recipe:

1. Create the module's repository, for example `mymodule` on GitHub, with at
   least one commit on its default branch, such as a README.
2. In the project's `ibek-support`, write
   `ibek-support/mymodule/mymodule.install.yml`:

   ```yaml
   # yaml-language-server: $schema=../_scripts/support_install_variables.json

   module: mymodule
   version: main
   organization: https://github.com/<YOUR GITHUB USER>/
   ```

   and add the module to the project's `Dockerfile`, after the modules it
   depends on (see {any}`module-build-order`):

   ```dockerfile
   COPY ibek-support/mymodule/ mymodule
   RUN ansible.sh mymodule
   ```

3. Clone the repository to `/workspaces/mymodule` and lay out the EPICS source
   there. `makeBaseApp.pl`, from EPICS base, makes a support module layout:

   ```bash
   # in the container
   cd /workspaces
   git clone https://github.com/<YOUR GITHUB USER>/mymodule.git
   cd mymodule
   makeBaseApp.pl -t support mymodule
   git add .
   git commit -m "EPICS support module layout"
   ```

   Commit the layout before the first build, so that `git status` shows the
   build's edits to `configure/RELEASE` and you leave them out of your commits.

4. Build it from the clone, which `ibek dev support` uses because its remote is
   the repository of the recipe:

   ```bash
   ibek dev support mymodule
   ```

   Add the `dbds` and `libs` that the module installs to its `install.yml` (see
   {any}`generic_ioc`) as the source comes to install them: the layout installs
   no library until it has source files. Write its
   `mymodule.ibek.support.yaml`, then work on the source as above.

:::{warning}
The order of the `<module>_DBD` lines in `*App/src/Makefile` matters. List each
DBD file after the DBD files it depends on, or the Generic IOC build fails. See
{any}`dbd-order`.
:::

Commit the source, without the build's edits to `configure/RELEASE`, tag a
release, and set the recipe's `version` to that tag
before you release the Generic IOC.

A new module has no published Generic IOC release yet, so there is no online
schema for its example instance to validate against. Generate one in the
container from the definitions that the container has linked:

```bash
ibek ioc generate-schema > /tmp/ibek.ioc.schema.json
```

and point the example instance's schema line at that file until the Generic IOC
is released:

```yaml
# yaml-language-server: $schema=/tmp/ibek.ioc.schema.json
```
