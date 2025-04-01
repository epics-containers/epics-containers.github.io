(quickstart)=
# Docker Compose Quickstart

Here are some minimal setup instructions to get you up and running with docker-compose and a container runtime on any platform.

## Docker Already Installed

If you have any Linux distribution with Docker installed you are all set.

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
**Podman Integration with Docker Compose**

```bash
systemctl enable --user podman.socket --now
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

## Windows

- PowerShell: `wsl --install -d Ubuntu`
- Open Ubuntu terminal and follow [](linux-installation)

## Mac OS

- Follow this gist <https://gist.github.com/kaaquist/dab64aeb52a815b935b11c86202761a3>
- Install an X11 server like XQuartz

## Diamond Light Source workstation

Setup a podman service and socket:
```bash
systemctl enable --user podman.socket --now
```

Add this to your `~/.profile` and logout and back in:
```bash
export PATH=/dls_sw/apps/docker-compose/2.33.1/bin/:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
alias docker=podman
```
