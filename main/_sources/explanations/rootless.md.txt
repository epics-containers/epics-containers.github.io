# Rootless vs Rootfull

epics-containers is intended to support both docker and podman. Docker is rootfull by default but also supports rootless operation. Podman is rootless by default but also supports rootfull operation.

Advantages of rootless operation include:

- Security: rootless containers only have the same permissions as the user running them.
- Ease of use: in an environment where users do not have root privileges, rootless containers can be run without needing to escalate privileges. This is why DLS uses rootless containers.
- Host mounts: host mounts have the same permissions as the user running the container.
- Developer containers: rootless containers can be 'root' inside the container, but not on the host.
- Simplicity: no need to switch users in Dockerfiles - just stay as root and use psuedo-root during runtime. This maps nicely to using the same container in Kubernetes where control of the user id is up to the cluster.

Advantages of rootfull operation include:

- networking: you can create rootable bridge networks that can be accessed from the host
- power: you can give containers privileged capabilities that the user would not normally have

The advantages of rootless are ideal for developing and executing IOCs.

## Current situation

At present epics-containers requires slightly different configuration for docker and podman. However these differences are really because of the rootfull vs rootless distinction. Those distinctions for docker (rootful) are:

- EC_REMOTE_USER: must be set so that developer containers run as the current user
- Permissions on the files inside the developer container need to be set with *sudo chown* at startup
- Developer containers will sometimes have issues with git repo permissions
- docker compose deployed IOCs do run as root and write any generated files as root in host mounted folders (this needs fixing)
- UIDGID is required to be passed to the compose file for phoebus to make sure it runs as the correct user (but would not be needed at all for rootless)

## Proposed solution

We should mantate the use of rootless for epics-containers. This will make the configuration simpler and more secure.

A potential issue with this is that developers who use docker for other purposes may need to use rootfull as well.

This would therefore be accetable if it is easy to switch between rootfull and rootless operation. The next section shows how I have done this with docker on Ubuntu 24.04, I would guess that this will work on other distros but this needs to be verified.

## Configure Docker with rootless/rootfull operation

Note that some fixes to epics-containers 'Current Situtation' are required if you switch to rootless operation - we can remove some of the config requirements.

These instructions worked for me on Ubuntu 24.04. Assume docker default install is already done and is at version 27.2.0.

1. docker install comes with a script to set up rootless operation. We use --force to tell it to run even though rootfull is already set up.

    ```bash
    sudo dockerd-rootless-setuptool.sh --force
    ```

1. The script may get errors and explain how to get around them. In my case it asked me to run this:
    ```bash
    sudo sh -eux <<EOF
    # Install newuidmap & newgidmap binaries
    apt-get install -y uidmap
    EOF
    ```

1. Make sure the rootfull service is still running (may not need this step).

    ```bash
    sudo systemctl enable --now docker.service docker.socket
    ```

1. Now you can switch between both by changing the environment variable DOCKER_HOST.

1. To switch to rootless:

    ```bash
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
    docker ps -a
    ```

1. To switch back to rootfull:

    ```bash
    export DOCKER_HOST=unix:///var/run/docker.sock
    docker ps -a
    ```



