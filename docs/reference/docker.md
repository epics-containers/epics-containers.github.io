(using-docker)=

Using Docker Instead of Podman
==============================

epics-containers recommends `podman` as the container engine for the
tutorials and for production use. The rest of this documentation refers to
`podman` throughout. This page is the **single place** that describes how to
use `docker` instead. If you would prefer to use `docker`, read this page and
then continue with the rest of the documentation, mentally substituting
`docker` wherever you see `podman`.

`podman` and `docker` share (almost) the same command line interface, so every
`podman ...` command in these tutorials has an identical `docker ...`
equivalent. For convenience you can add an alias so that you can copy and paste
the `podman` commands verbatim:

```bash
# place this in $HOME/.bashrc (or $HOME/.zshrc for zsh users)
alias podman=docker
```

:::{note}
We continue to use **docker compose** with both engines. `docker compose` is the
multi-container orchestration tool used for the local-deployment tutorials and
it works against either `podman` or `docker`. See {any}`podman-compose` for how
to use `docker compose` with `podman`; with `docker`, `docker compose` is built
in and needs no extra configuration.
:::

## Installing Docker

Install the free Linux CLI tools from <https://docs.docker.com/engine/install/>.

The docker install page encourages you to install Docker Desktop. This is a paid
for product and is not required for these tutorials. You can install the free
Linux CLI tools by clicking on the appropriate Linux distribution link under the
"Supported Platforms" heading; for simplicity it is easiest to use the option
"Install using the convenience script".

epics-containers has been tested with docker 24.0.5 and higher. Any version of
docker since 20.10 will work.

## Rootless vs Rootful Docker

The main difference between `podman` and `docker` is that `podman` is rootless by
default while `docker` is rootful by default. See {any}`rootless` for an
explanation of why rootless operation is preferred for developing and running
IOCs.

The good news is that `docker` also supports a rootless mode. **We recommend
running docker in rootless mode** because it then behaves almost identically to
`podman` and none of the extra steps in the {ref}`rootful-docker` section below
are required.

### Recommended: Rootless Docker

In rootless mode docker is, for our purposes, equivalent to podman and you can
follow the rest of the documentation without any of the extra steps below.

To switch an existing docker install to rootless mode see the description of
`dockerd-rootless-setuptool.sh` in
[the docker rootless instructions](https://docs.docker.com/engine/security/rootless/#install).

The following worked on Ubuntu 24.04 with a default docker install at version
27.2.0. Your mileage may vary on other distributions.

1. The docker install comes with a script to set up rootless operation. We use
   `--force` to tell it to run even though rootful is already set up.

    ```bash
    dockerd-rootless-setuptool.sh --force
    ```

1. The script may report errors and explain how to get around them. In one case
   it asked for the `uidmap` package to be installed:

    ```bash
    sudo apt-get install -y uidmap
    ```

1. You can switch between rootless and rootful operation by changing the
   `DOCKER_HOST` environment variable.

   To use rootless docker:

    ```bash
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
    docker ps -a
    ```

   To switch back to rootful docker:

    ```bash
    export DOCKER_HOST=unix:///var/run/docker.sock
    docker ps -a
    ```

   (Make sure the rootful service is still running if you intend to switch back
   to it: `sudo systemctl enable --now docker.service docker.socket`.)

(rootful-docker)=
### Using Rootful Docker

If you cannot or do not want to use rootless docker then you can still use
rootful docker, but a few extra steps are required. These are needed because a
rootful docker container runs as the `root` user on the host, so any host files
written by the container are owned by `root`.

The differences when using rootful docker are:

- **It is best not to run containers as root.** Tell developer containers to run
  as your own user id by adding the following to your `$HOME/.bashrc` (or
  `$HOME/.zshrc` for zsh users):

    ```bash
    export EC_REMOTE_USER=$USER
    ```

  The epics-containers `devcontainer.json` files use this to set the account
  that you will use inside developer containers. If you do not set this, your
  developer container will run as root and all files written to your host
  workspace will be owned by root.

- **UIDGID** must be passed to the compose file so that the phoebus container
  runs as the correct user. The `environment.sh` files set `UIDGID` to
  `USERID:GROUPID` for docker (it is `0:0` for podman, which needs no special
  handling).

- **Git repository permissions.** `vscode` may ask you to mark the repository as
  safe, or you may need to run:

    ```bash
    git config --global --add safe.directory <Git folder>
    ```

- **Fixing file ownership.** If you hit permissions issues you can use `sudo`
  inside the container. For example, the following resets ownership on all of
  the EPICS files inside the container filesystem:

    ```bash
    sudo chown -R vscode /epics
    ```

We do fully support rootful `docker`, please report any issues you find.

## Troubleshooting Docker

### Cannot connect to the Docker daemon

Solution 1: start the daemon manually with `systemctl start docker`. If the
daemon was already running, add your user to the `docker` group, then log out
and in for the change to be effective.

Solution 2: use rootless docker as described above; the way to set this up
depends on your distribution and in some cases is a matter of installing a
variant package like `docker-rootless`.

### Docker daemon errors initializing graphdriver

Solution: the most likely reason is that you are using a filesystem like `zfs`
or `btrfs` which requires a special storage driver, click
[link](https://docs.docker.com/engine/storage/drivers/select-storage-driver/)
for more information.
