Working with Docker
===================

DLS is a `podman` shop and therefore more testing is done with `podman` than `docker` as the container CLI used with developer containers. `podman` works extremely well with developer containers, but `docker` needs a little more work sometimes.

The primary difference is that `podman` does not require root access and `docker` does. When inside a `podman` container you appear to be root but you are running as your own host user id. When you write to any host mounted files you will be doing so with your host user permissions. In a docker container any host files written will be owned by the user id that the container is running as.

Therefore:
- It is better not to run `docker` containers as root.
- It is easiest to run `podman` containers as root for simplicity.

We do fully support `docker`, please report any issues you find.

If you would like to use docker in rootless mode then it is almost identical to podman and the following instructions are NOT required. To switch to rootless mode see the description of `dockerd-rootless-setuptool.sh` in  [these instructions](https://docs.docker.com/engine/security/rootless/#install).

There are a few things to know if you are using `docker` in your developer containers:

1. add `export EC_REMOTE_USER=$USER` into your `$HOME/.bashrc` (or `$HOME/.zshrc` for zsh users). The epics-containers devcontainer.json files will use this to set the account that your user will use inside devcontainers.
1. you may need to tell git that you are ok with the repository permissions. `vscode` may ask you about this or you may need to do the command:
    ```bash
    git config --global --add safe.directory <Git folder>
    ```
1. you can use `sudo` if you are having permissions issues. In particular the following will reset permissions on all of the epics files inside the container filesystem:
    ```bash
    sudo chown -r vscode /epics
    ```
