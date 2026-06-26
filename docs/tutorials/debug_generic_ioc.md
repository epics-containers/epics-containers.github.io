# Debugging Generic IOC Builds

This tutorial continues from {any}`generic_ioc`. There we built the
`ioc-lakeshore340` Generic IOC; here we look at what to do when such a build
*fails*.

The recommended workflow is to do all your work inside a developer container,
and that container is built from the Generic IOC image. So when the image build
itself fails you have no container to work in. There are two ways out:

- **Edit and rebuild.** Change the `Dockerfile` (or an `ibek-support` recipe)
  and run `./build` again. The build cache makes this fast, so it is often
  enough.
- **Shell into the part-built image.** Open a shell in the image as it stood at
  the last successful step and retry the failing command interactively. This is
  the approach we cover below — it is far quicker when an early change only
  surfaces as a failure much later in the build.

## Break the build

Let us deliberately break the `ioc-lakeshore340` build. Open
`ibek-support/StreamDevice/StreamDevice.install.yml` and comment out the
`apt_developer` section:

```yaml
# apt_developer:
#   - libpcre3-dev
```

`apt_developer` lists the system packages installed *before* a support module is
compiled. Removing `libpcre3-dev` strips the PCRE headers, so StreamDevice will
fail to compile.

Now rebuild from a terminal *outside* the devcontainer:

```bash
cd ioc-lakeshore340   # wherever you cloned it
./build
```

The build cache skips rapidly over the unchanged steps and only re-runs from
`COPY ibek-support/StreamDevice/ StreamDevice` onwards (because a file in that
folder changed). It then fails:

```text
../RegexpConverter.cc:27:10: fatal error: pcre.h: No such file or directory
   27 | #include "pcre.h"
      |          ^~~~~~~~
compilation terminated.
```

## Shell into the part-built image

A failed build leaves an image committed up to the last *successful* step. We
can start a shell there and retry the command that failed.

Scroll up to the last successful step and copy the hash printed beneath it:

```text
--> 43eb74c72eab
STEP 17/22: COPY ibek-support/StreamDevice/ StreamDevice
--> da81452bc214
STEP 18/22: RUN ansible.sh StreamDevice
```

Here `da81452bc214` is the image *after* the `COPY` but *before* the failing
`ansible.sh`. Start a shell in it and re-run the command:

```bash
podman run -it --entrypoint /bin/bash da81452bc214
ansible.sh StreamDevice
```

You get the same error — but now you can investigate it live.

## Find the missing dependency

A missing header almost always means a missing system package. The handiest way
to find which package provides a file is `apt-file`. It is not installed by
default, and inside the container you are `root`, so install it with no `sudo`:

```bash
apt update
apt install apt-file
apt-file update
apt-file search pcre.h
```

The promising result is:

```text
libpcre3-dev: /usr/include/pcre.h
```

A missing header file is nearly always supplied by a package whose name ends in
`-dev`. Install it and retry:

```bash
apt-get install -y libpcre3-dev
ansible.sh StreamDevice
```

This time the module builds.

:::{note}
Build-time dependencies (headers, `-dev` packages) belong in the
`apt_developer` key of the module's `*.install.yml`; libraries the IOC needs at
*run* time go in `apt_runtime`. `StreamDevice.install.yml` lists `libpcre3-dev`
under the former and `libpcre3` under the latter.
:::

StreamDevice also needs the compiler told where the PCRE library lives. That is
done by the `patch_lines` section of the same file, which adds a `PCRE_LIB`
macro to `CONFIG_SITE.linux-x86_64.Common`. The point of working *inside* the
container is that you can try out such tweaks interactively — `ansible.sh` is
idempotent, so you can re-run it as often as you like without duplicating
entries — before committing to a recipe.

## Make the fix permanent

Once the manual steps work, record them in `ibek-support` and/or the
`Dockerfile` so the next build does them automatically (here, simply uncomment
the `apt_developer` section again), then run a full `./build` to confirm.

## Tools inside the container

The developer container ships [`busybox`](https://www.busybox.net/), which
provides network diagnostics such as `ifconfig` plus many small utilities — run
`busybox` to list them. Because you are `root`, you can `apt-get install`
anything else you need to investigate a build, exactly as we did with `apt-file`
above.
