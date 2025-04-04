# Debugging Generic IOC Builds

This tutorial is a continuation of {any}`generic_ioc`. Here we will look into
debugging failed builds of Generic IOCs.

For the most part the recommended workflow is to always be working inside
of a developer container. We always use a Generic IOC as the base for our
developer containers. But what if the build of the Generic IOC fails, then
you don't have a container to work in and need some other way to debug the
build.

There are two ways to debug such a failed build:

- Keep changing the Dockerfile and rebuilding the container until the build
  succeeds. This is the simplest approach and is often sufficient since our
  Dockerfile design maximizes the use of the build cache.
- Investigate the build failure by running a shell inside the
  partially-built container and retrying the failed command. This is particularly
  useful if you are fixing something early in the Dockerfile that causes a
  failure much later in the build. This type of failure is tedious to debug
  using the first approach above.

In this tutorial we will look debugging the build from *inside* the container.

## Break the Build

Let us break the build of our ioc-lakeshore340 project in the last
tutorial. Open the the file
`ioc-lakeshore340/ibek-support/StreamDevice/StreamDevice.install.yml`.
Comment out the app_developer section like this:

```yaml
# apt_developer:
#   - libpcre3-dev
```

This removes installation of the system dependency on the `libpcre3-dev` package and StreamDevice will therefore fail to build.

Now rebuild the container - do this command from a new terminal *outside* of the devcontainer:

```bash
# for docker users - builkit complicates debugging at present
export DOCKER_BUILDKIT=0
cd ioc-lakeshore340 # where you cloned it
./build
```

First of all, notice the build cache. The build rapidly skips
over all the steps until it gets to the StreamDevice support module. The,
cache fails only when you get to `COPY ibek-support/StreamDevice/ StreamDevice/`
because a file in the source folder has changed.

You should see the build fail with the following error:

```bash
../RegexpConverter.cc:27:10: fatal error: pcre.h: No such file or directory
27 | #include "pcre.h"
    |          ^~~~~~~~
compilation terminated.
```

## Investigate the Build Failure

When a container build fails the container image is created up to the point
where the last successful Dockerfile command was run. This means that we can
investigate the build failure by running a shell in the container.

- scroll up the page until you see the last successful build step e.g.

```bash
--> 43eb74c72eab
STEP 17/22: COPY ibek-support/StreamDevice/ StreamDevice
--> da81452bc214
STEP 18/22: RUN ansible.sh StreamDevice
... etc ...
```

- copy the hash of the step you want to debug e.g. `da81452bc214` in this case
- `docker run -it --entrypoint /bin/bash da81452bc214 # (the hash you copied)`

Now we have a prompt inside the part-built container and can retry the failed
command.

```bash
ansible.sh StreamDevice
```

You should see the same error again.

This is a pretty common type of error
when building a new support module. It implies that there is some dependency
missing. There is a good chance this is a system dependency, in which case
we want to search the Ubuntu repositories for the missing package.

A really good way to investigate this kind of error is with `apt-file`
which is a command line tool for searching Debian packages. `apt-file` is
not currently installed in the devcontainer. So you have two choices:

- Install it in the devcontainer - this is temporary and will be lost when
  the container is rebuilt. Ideal if you don't have install rights on your
  workstation.
- Install it on your workstation - ideal if you have rights as you only need
  to install it once.

TODO: consider adding apt-file to the base container developer target.

Whether inside the container or in your workstation terminal, install
`apt-file` like this:

```bash
# drop the sudo from the start of the command if using podman
sudo apt update
sudo apt install apt-file
```

Now we can search for the missing file:

```bash
apt-file update
apt-file search pcre.h
```

There are a few results, but the most promising is:

> libpcre3-dev: /usr/include/pcre.h

Pretty much every time you are missing a header file you will find it in a
system package with a name ending in `-dev`.

Now we can install the missing package in the container and retry the build:

```bash
apt-get install -y libpcre3-dev
ansible.sh StreamDevice
```

You should find the build succeeds. But this is not the whole story. There is another section in `StreamDevice.install.yml` that I added to make this work:

```yaml
patch_lines:
  - path: "{{ config_linux_host }}"
    regexp: PCRE_LIB
    line: PCRE_LIB=/usr/lib/x86_64-linux-gnu
    when: "{{ is_linux }}"
```

This added a macro to `CONFIG_SITE.linux-x86_64.Common` that tells the
Makefiles to add an extra include path to the compiler command line. working
out how to do this is a matter of taking a look in the Makefiles. But the
nice thing is that you can experiment with things inside the container and
get them working without having to keep rebuilding the container.
(TODO: strictly speaking this could be improved, we should remove the {{ is_linux }} and use the path {{ config_linux_target }} instead, that updates CONFIG_SITE.Common.linux-x86_64 which only affects the linux-x86_64 target)

Note that ansible is idempotent, so you can run it multiple times without getting repeated entries in the CONFIG.

Once you are happy with your manual changes you can make them permanent by adding to the `<module>install.yml` or Dockerfile, then try a full rebuild.

## Tools Inside the Container

You will find that the developer container includes busybox tools, vim and ifconfig. These should provide enough tools to investigate and fix most build problems. You are also free to use apt-get to install any other tools you need as demonstrated above. (type busybox to see the list of available tools).
