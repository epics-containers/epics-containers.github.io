# Create a New Support Module

In {any}`generic_ioc` you wrapped an *existing* support module (`ADSimDetector`)
in a Generic IOC. This tutorial covers the harder case: the EPICS support code
does not exist upstream yet, so you are writing it yourself. This is a **type 3**
change from {any}`ioc-change-types`.

The good news is that almost all of the work is identical to {any}`generic_ioc`.
Only one thing is genuinely new — developing brand-new support source inside the
developer container — so this page focuses on that and links back for the rest.
The worked example uses a module called `mymodule`; substitute your own name.

## Develop the support source

Start a new Generic IOC project from
[`ioc-template`](https://github.com/epics-containers/ioc-template) and open its
developer container, exactly as in {any}`generic_ioc`. That container has the
EPICS build tools you need.

Keep your support source under `/workspaces` so it is version-controlled and
visible in the editor, but symlink it into `/epics/support`, where the EPICS
build system expects every module to live:

```bash
mkdir /workspaces/mymodule          # write your support code here
ln -s /workspaces/mymodule /epics/support/mymodule
```

Now iterate with the standard EPICS build (`make`) until the module compiles
inside the developer container, just as you would build any support module.

## Publish the support module

An `ibek-support` recipe fetches a module from a git repository at a specific
release, so your new module needs a public home before CI can build your Generic
IOC against it. Push the source to its own repository (for example a public
GitHub repo) and tag a release. Once it is published you can drop the symlink and
let the recipe clone it like any other module.

## Add the ibek-support recipe

From here on the steps are exactly those in {any}`generic_ioc` — create an
`ibek-support/mymodule/` folder containing:

- **`mymodule.install.yml`** — fetch-and-build variables for `ansible.sh`. Set
  `module`, `version` (your release tag or branch) and `organization` (the URL
  prefix of the repo, such as `https://github.com/your-org/`) so the recipe
  pulls *your* repository. Test it with `ansible.sh mymodule`.
- **`mymodule.ibek.support.yaml`** — the `entity_models` that IOC instances may
  use, with their parameters and the databases / startup lines they generate.

Then add a `COPY` / `RUN ansible.sh mymodule` pair to the Generic IOC
`Dockerfile`, build an example instance in `tests/config/ioc.yaml`, test it with
`ibek dev instance` followed by `make` and `./start.sh`, and finally push both
the `ibek-support` recipe and the Generic IOC repository. Each of these steps is
covered in detail in {any}`generic_ioc`.

:::{note}
**TODO (maintainer walkthrough):** add a short section here on generating and
using the instance schema for a brand-new module — `ibek ioc generate-schema >
/tmp/ibek.ioc.schema.json`, pointing the instance's schema line at it for editor
validation before the first release, and the published-release schema URL that
real instances reference afterwards. (`generic_ioc` now glosses over this because
it reuses an existing instance that already has a local schema.)
:::
