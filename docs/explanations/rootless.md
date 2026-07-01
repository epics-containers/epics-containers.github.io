(rootless)=
# Rootless vs Rootful

epics-containers recommends running containers **rootless**. This is why we
recommend `podman`, which is rootless by default. (`docker` is rootful by
default but also supports a rootless mode - see {any}`using-docker`.)

Advantages of rootless operation include:

- Security: rootless containers only have the same permissions as the user running them.
- Ease of use: in an environment where users do not have root privileges (for
  example a shared facility or managed workstation), rootless containers can be
  run without needing to escalate privileges.
- Host mounts: host mounts have the same permissions as the user running the container.
- Developer containers: rootless containers can be 'root' inside the container, but not on the host.
- Simplicity: no need to switch users in Dockerfiles - just stay as root and use psuedo-root during runtime. This maps nicely to using the same container in Kubernetes where control of the user id is up to the cluster.

:::{note}
**DLS users:** managed workstations run rootless containers for exactly these
reasons. See the
[DLS dev-guide setup](https://dev-guide.diamond.ac.uk/epics-containers/reference/setup.html)
for site-specific configuration.
:::

Advantages of rootful operation include:

- networking: you can create rootable bridge networks that can be accessed from the host
- power: you can give containers privileged capabilities that the user would not normally have

The advantages of rootless are ideal for developing and executing IOCs, which
is why `podman` (rootless) is the recommended container engine throughout this
documentation.

## Why podman is recommended

Because `podman` is rootless by default it gives the simplest and most secure
experience:

- when you appear to be `root` inside a `podman` container you are really
  running as your own host user id, so any host files you write are owned by
  you;
- developer containers can run as `root` inside the container without any extra
  configuration;
- there is no need to set `EC_REMOTE_USER`, fix file ownership with `sudo chown`,
  or pass a special `UIDGID` to the compose file.

If you choose to use `docker` instead, running it rootless gives you the same
benefits. Running `docker` rootful is also supported, but a few extra
configuration steps are then required. Both options are described in
{any}`using-docker`.
