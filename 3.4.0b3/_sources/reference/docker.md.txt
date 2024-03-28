Working with Docker
===================

DLS is a `podman` shop and therefore more testing is done with `podman` than `docker` as the container CLI used with developer containers. `podman` works extremely well with developer containers, but `docker` needs a little more work sometimes.

We do fully support `docker`, please report any issues you find.

There are a few things to know if you are using `docker` in your developer containers:

1. add `export EC_REMOTE_USER=vscode` into your `~/.bashrc` or `~/.bash_profile`. The epics-containers devcontainer.json files will use this to set the account that your user will use inside devcontainers.
1. you may need to tell git that you are ok with the repository permissions. `vscode` may ask you about this or you may need to do the command:
    ```bash
    git config --global --add safe.directory <Git folder>
    ```
1. you can use `sudo` if you are having permissions issues. In particular the following will reset permissions on a folder:
    ```bash
    sudo chown -r vscode <folder>
    ```
