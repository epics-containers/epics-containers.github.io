(quickstart)=
# Docker Compose Quickstart

Here are some minimal setup instructions to get you up and running with docker-compose and a container runtime on any platform. This is a pre-requisite for most of the tutorials in this documentation.

## Docker Already Installed

If have one of the following then you are good to go with no further setup:

- Docker Desktop on Windows WSL2
- Docker Desktop on MacOS
- Any Linux distribution with Docker installed

For WSL2 check: Settings → Resources → WSL integration → ENABLE ... Apply and Restart

(linux-installation)=
## Linux

**Debian Distros**

```bash
sudo apt install podman docker-compose-v2
```

**RPM Distros**

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install podman docker-compose-plugin
```

**Podman Integration with Docker Compose**

```bash
systemctl enable --user podman.socket --now
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

## Windows or MacOS

- Install podman desktop <https://podman-desktop.io/docs/installation>
- Follow [](linux-installation) above in a WSL2 or Mac terminal
- For Mac, add an X11 server like XQuartz

## Docker permissions

If you get docker permission errors do the following:

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
sudo reboot
```
