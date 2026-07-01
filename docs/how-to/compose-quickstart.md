(quickstart)=
# Docker Compose Quickstart

Here are some minimal setup instructions to get you up and running with docker-compose and a container runtime on any platform. We recommend `podman` as the container runtime; if you would rather use `docker` see {any}`using-docker`.

## Podman Already Installed

If you have any Linux distribution with podman and docker-compose installed you are all set.

(linux-installation)=
## Linux

**Debian Distros**

```bash
sudo apt update
sudo apt install podman docker-compose-v2
```

**RPM Distros**

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install podman docker-compose-plugin
```

(podman-integration)=
### Podman Integration with Docker Compose

`docker compose` is daemonless podman's only blind spot: it talks to podman
through a docker-compatible API socket. Enable the user socket and point
`DOCKER_HOST` at it:

```bash
systemctl enable --user podman.socket --now
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

Add the `export` line to your shell profile (`~/.bashrc` or `~/.zshrc`) so it
is set in every new shell.

## Windows

- PowerShell: `wsl --install -d Ubuntu`
- Open Ubuntu terminal and follow [](linux-installation)

## Mac OS

Install podman and docker-compose with [Homebrew](https://brew.sh), then start
a podman virtual machine:

```bash
brew install podman docker-compose
podman machine init
podman machine start
```

Point `docker compose` at the podman socket inside the machine:

```bash
export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')"
```

To run EPICS GUI tools (e.g. Phoebus) you will also need an X11 server such as
XQuartz.

## Diamond Light Source workstation

:::{note}
**DLS users:** podman is already installed. The first time you use it on a
workstation, run the shared setup script:

```bash
/dls_sw/apps/setup-podman/setup.sh
```

Then set up the podman service and socket:

```bash
systemctl enable --user podman.socket --now
```

Add this to your `~/.profile`, then log out and back in. The explicit `PATH`
entry ensures `docker-compose` is also available to remote VSCode sessions:

```bash
export PATH=/dls_sw/apps/docker-compose/5.1.4/bin/:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

First run `ls /dls_sw/apps/docker-compose/` to check the most recent version of
docker-compose available, and use that in place of `5.1.4` above.
:::
