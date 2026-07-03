# Edit or Create a Support Module

In {any}`generic_ioc` you wrapped an *existing* support module (`ADSimDetector`)
unchanged. This tutorial covers the case where you need to change the support
code **itself** — either **editing an existing module** (by far the more common
case: add a record, fix a driver bug, expose a new parameter) or **writing a
brand-new one** from scratch. Both are a **type 3** change from
{any}`ioc-change-types`.

The two are essentially the same job: you develop EPICS support source inside a
Generic IOC developer container, publish it, and point an `ibek-support` recipe
at it. The only difference is your starting point — an existing module you clone,
or an empty folder you create. Almost everything else is identical to
{any}`generic_ioc`, so this page focuses on developing the support source and
links back for the rest. The worked example uses a module called `mymodule`;
substitute your own name.

## Develop the support source

Start (or reopen) a Generic IOC project from
[`ioc-template`](https://github.com/epics-containers/ioc-template) and open its
developer container, exactly as in {any}`generic_ioc`. That container has the
EPICS build tools you need.

Get your support source under `/workspaces` so it is version-controlled and
visible in the editor, then symlink it into `/epics/support`, where the EPICS
build system expects every module to live.

**Editing an existing module** — clone it (a fork if you do not have push
rights) and symlink that:

```bash
cd /workspaces
git clone https://github.com/your-org/mymodule   # the module you are editing
ln -s /workspaces/mymodule /epics/support/mymodule
```

**Creating a new module** — start from an empty folder instead:

```bash
mkdir /workspaces/mymodule          # write your support code here
ln -s /workspaces/mymodule /epics/support/mymodule
```

Now iterate with the standard EPICS build (`make`) until the module compiles
inside the developer container, just as you would build any support module.

## Publish the support module

An `ibek-support` recipe fetches a module from a git repository at a specific
release, so your changes need a public home before CI can build your Generic IOC
against them. Push the source — to its own new repository for a brand-new module,
or to your fork/branch for an existing one — and tag a release. Once it is
published you can drop the symlink and let the recipe clone it like any other
module.

## Add the ibek-support recipe

From here on the steps are exactly those in {any}`generic_ioc`. **When you are
editing an existing module** its recipe already lives in `ibek-support/mymodule/`
— usually all you change is the `version` in `mymodule.install.yml` to point at
your new release (and `organization`, if you pushed to a fork), then re-run
`ansible.sh mymodule`. **For a brand-new module** create the
`ibek-support/mymodule/` folder containing:

- **`mymodule.install.yml`** — fetch-and-build variables for `ansible.sh`. Set
  `module`, `version` (your release tag or branch) and `organization` (the URL
  prefix of the repo, such as `https://github.com/your-org/`) so the recipe
  pulls *your* repository. Test it with `ansible.sh mymodule`.
- **`mymodule.ibek.support.yaml`** — the `entity_models` that IOC instances may
  use, with their parameters and the databases / startup lines they generate.

Then make sure the Generic IOC `Dockerfile` has a `COPY` / `RUN ansible.sh
mymodule` pair (already present when you are editing a module the image already
builds; add it for a new one), build an example instance in
`tests/config/ioc.yaml`, test it with `ibek dev instance` followed by `make` and
`./start.sh`, and finally push both the `ibek-support` recipe and the Generic IOC
repository. Each of these steps is covered in detail in {any}`generic_ioc`.

## Validate instances before the first release

A brand-new module has no published release yet, so there is no online schema for
its example instance to validate against. Generate one locally from inside the
developer container: once `ansible.sh` has registered your
`mymodule.ibek.support.yaml` into `/epics/ibek-defs`, `ibek ioc generate-schema`
builds a schema covering exactly the entities your image provides:

```bash
ibek ioc generate-schema > /tmp/ibek.ioc.schema.json
```

Point your example instance's schema line at that file so the editor offers
completion and validation before you cut a release:

```yaml
# yaml-language-server: $schema=/tmp/ibek.ioc.schema.json
```

Once the Generic IOC is published, real instances reference the schema attached
to its release instead — the `ibek.ioc.schema.json` asset described in
{any}`generic_ioc`. Swap the local path for that release URL at that point.
