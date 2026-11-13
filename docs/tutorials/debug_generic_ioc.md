# Debugging Generic IOC Builds

This tutorial continues from {any}`generic_ioc`, where we built the
`ioc-adsim-demo` Generic IOC and re-authored its `ADSimDetector` recipe.
Here we look at what to do when such a build *fails*.

The developer container opens from a developer image that was built already:
the one CI published with the project's latest full release, or a local one
(see {any}`devcontainer-open`). So a recipe that no longer builds does not stop
the container opening. You find the failure and fix it inside the container,
which is the exact environment the image is built in.

Only when the image itself has to be built as the container opens can a
failing recipe stop it opening. That case has its own trick, described in
[](image-build-fails).

## Break the build

Let us introduce a realistic mistake into the `ADSimDetector` recipe you
authored in {any}`generic_ioc`. Open the `ioc-adsim-demo` developer container,
open `ibek-support/ADSimDetector/ADSimDetector.install.yml` and change
`version` to a tag that does not exist:

```yaml
module: ADSimDetector
version: R2-111          # typo — there is no such tag
```

Ask the container how it now differs from the project, in a terminal in the
container (Terminal -> New Terminal):

```bash
ibek dev status
```

It reports `ADSimDetector` as out of date and names the command that rebuilds
it, `ibek dev sync --build`. Run that:

```bash
ibek dev sync --build
```

It runs the module's own line of the `Dockerfile`, `ansible.sh ADSimDetector`.
`ansible.sh` clones the module before building it, and the clone fails because
the requested ref is not in the upstream repo:

```text
fatal: Remote branch R2-111 not found in upstream origin
```

:::{note}
A wrong `organization` (or a private repo with no credentials) fails at the same
step with an *authentication* or *repository not found* error — same place,
different message.
:::

## Fix it live inside the container

Correct the version in `ibek-support/ADSimDetector/ADSimDetector.install.yml`
back to the real tag:

```yaml
version: R2-11
```

and run the rebuild again:

```bash
ibek dev sync --build
```

This time the module clones and builds, then the IOC is built. You can re-run
it as often as you like: it carries on from the module that failed. You can
also run `ansible.sh ADSimDetector` by hand while you iterate; it is idempotent.
`ibek dev status` keeps reporting the module until `ibek dev sync --build` has
built it.

## Make the fix permanent

The fix is in your `ibek-support` checkout on the host. To confirm that the
image builds cleanly with it, run a full build from a terminal *outside* the
container:

```bash
cd ioc-adsim-demo     # wherever you cloned it
./build
```

:::{note}
This is the same try-it-live-then-make-it-permanent loop you used to *add*
modules in {any}`generic_ioc` — only here it starts from a failure. Anything you
can fix interactively with `ansible.sh` can be recorded in the recipe or
`Dockerfile` and replayed by `./build`.
:::

(image-build-fails)=

## When the image build fails

`.devcontainer/initializeCommand` builds the image as the container opens when
the marker file `.devcontainer/local-build` exists, or when it can neither pull
the image nor find a local one, as for a repository with no release (see
{any}`devcontainer-local-build`). If a recipe fails in that build, there is no
image and so no container to open. The fix is a small trick:

1. Comment out the failing `RUN ansible.sh …` line in the `Dockerfile`, leaving
   its matching `COPY` in place:

   ```dockerfile
   COPY ibek-support/ADSimDetector/ ADSimDetector
   # RUN ansible.sh ADSimDetector
   ```

   The image now builds again — it simply omits the `ADSimDetector` support
   for the moment.
2. Open the container with `Ctrl-Shift-P` -> *Dev Containers: Rebuild
   Container*, so that the image is built from the edited `Dockerfile` and the
   container is created from it.
3. Run the failing command by hand inside the container, `ansible.sh
   ADSimDetector`, and fix the recipe until it passes.
4. Uncomment the line and run a full `./build` on the host to confirm.

## Aside: a missing system header

A different class of failure is a module that *clones* fine but fails to
**compile** with a missing header:

```text
fatal error: tiffio.h: No such file or directory
```

A missing header almost always means a missing system `-dev` package. Inside the
container you are `root`, so find which package provides the header and install
it with no `sudo`:

```bash
apt update
apt install apt-file
apt-file update
apt-file search tiffio.h
```

Once you know the package, record it in the module's `*.install.yml` so the next
build installs it automatically. Recipes split their system packages into two
keys:

| Key | Installed | Holds |
|---|---|---|
| `apt_developer` | in the build stage only | headers and `-dev` packages needed to *compile* the module |
| `apt_runtime` | into the slim runtime image | shared libraries the IOC needs at *run* time |

For example `ADCore.install.yml` lists `libtiff-dev` under `apt_developer` and
`libtiff6` under `apt_runtime`.

## Tools inside the container

The dev container is Ubuntu-based and you are `root` (podman maps that back to
your own user on the host), so you can `apt-get install` anything you need to
investigate a build. It also ships [`busybox`](https://www.busybox.net/), which
provides network diagnostics such as `ifconfig` plus many small utilities — run
`busybox` to list them.
