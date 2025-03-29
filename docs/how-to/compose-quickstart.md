(quickstart)=
# Docker Compose Quickstart

Here are some minimal setup instructions to get you up and running with docker-compose and a container runtime on any platform. This is a pre-requisite for most of the tutorials in this documentation.

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

- Install WSL2 with Ubuntu Distro (for systemd)
- Open Ubuntu terminal and follow [](linux-installation)

## Mac OS

- brew install podman
- brew install docker-compose
- Follow 'Podman Integration with Docker Compose'
- Add an X11 server like XQuartz

## Docker permissions

If you get docker permission errors do the following:

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
sudo reboot
```
