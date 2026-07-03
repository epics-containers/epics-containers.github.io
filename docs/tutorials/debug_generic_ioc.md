# Debugging Generic IOC Builds

This tutorial continues from {any}`generic_ioc`, where we built the
`ioc-adsimdetector` Generic IOC and re-authored its `ADSimDetector` recipe.
Here we look at what to do when such a build *fails*.

The developer container is built **from the Generic IOC image** (the `developer`
target of the same `Dockerfile`). That is normally a strength — you debug in the
exact environment the image is built in — but it has one catch: when the *image*
build fails, there is no container to open. The fix is a small trick:

1. Comment out the failing `RUN ansible.sh …` line so the image — and therefore
   the dev container built from it — builds again.
2. Reopen the dev container.
3. Run the failing command **by hand** inside the live container and iterate
   until it passes.
4. Uncomment the line and run a full `./build` to confirm.

This makes the dev container the debugging surface, which is the project's
gold-standard loop.

## Break the build

Let us introduce a realistic mistake into the `ADSimDetector` recipe you
authored in {any}`generic_ioc`. Open
`ibek-support/ADSimDetector/ADSimDetector.install.yml` and change `version` to a
tag that does not exist:

```yaml
module: ADSimDetector
version: R2-111          # typo — there is no such tag
```

Now rebuild from a terminal *outside* the dev container:

```bash
cd ioc-adsimdetector     # wherever you cloned it
./build
```

The build cache skips the unchanged steps and re-runs from
`COPY ibek-support/ADSimDetector/ ADSimDetector` onwards. `ansible.sh` clones the
module before building it, and the clone fails because the requested ref is not
in the upstream repo:

```text
fatal: Remote branch R2-111 not found in upstream origin
```

:::{note}
A wrong `organization` (or a private repo with no credentials) fails at the same
step with an *authentication* or *repository not found* error — same place,
different message.
:::

## Get a working dev container

Because the image will not build, the dev container cannot open. Comment out the
failing line in the `Dockerfile`, leaving its matching `COPY` in place:

```dockerfile
COPY ibek-support/ADSimDetector/ ADSimDetector
# RUN ansible.sh ADSimDetector
```

The `developer` image now builds again — it simply omits the `ADSimDetector`
support for the moment. Reopen and rebuild the dev container so it picks up the
edited `Dockerfile`:

```bash
code .
# then Ctrl-Shift-P -> "Dev Containers: Rebuild Container"
```

## Fix it live inside the container

Open a terminal in the dev container (Terminal -> New Terminal) and run the
command that failed, by hand:

```bash
ansible.sh ADSimDetector
```

You get the same clone error — but now you can fix it in place. Correct the
version in `ibek-support/ADSimDetector/ADSimDetector.install.yml` back to the
real tag and re-run. `ansible.sh` is idempotent, so you can re-run it as often as
you like:

```yaml
version: R2-11
```

```bash
ansible.sh ADSimDetector
```

This time the module clones and builds.

## Make the fix permanent

Uncomment the `RUN ansible.sh ADSimDetector` line in the `Dockerfile`, then run a
full build from outside the container to confirm the image builds cleanly from
scratch:

```bash
./build
```

:::{note}
This is the same try-it-live-then-make-it-permanent loop you used to *add*
modules in {any}`generic_ioc` — only here it starts from a failure. Anything you
can fix interactively with `ansible.sh` can be recorded in the recipe or
`Dockerfile` and replayed by `./build`.
:::

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
