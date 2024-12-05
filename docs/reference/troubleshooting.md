# Troubleshooting

## Resetting VSCode Cache

Occasionally if vscode gets stuck in a bad state, you may need to reset the cache.

```bash
# close vscode

# make sure there are no stuck vscode processes
pkill code

# remove the vscode caches
rm -rf ~/.vscode/* ~/.vscode-server/*

# restart vscode
```

## Permissions issues with GitHub

Problem: in the devcontainer you see the following error:

```none
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

Solution: you may need to add your github ssh key to the ssh-agent as
follows:

```none
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Where `id_rsa` is the name of your private key file you use for connecting
to GitHub.

## Cannot connect to the Docker daemon

Solution 1: start the daemon manually with `systemctl start docker`,
if the daemon was already running, add your user to the `docker` group, then
log out and in for the change to be effective.

Solution 2: use rootless docker, the way to setup this depends on your
distribution, in some cases, it's a matter of installing a variant package
like `docker-rootless`.

## Docker daemon errors initializing graphdriver

Solution: The most likely reason is that you are using a filesystem like `zfs`
or `btrfs` which requires a special storage driver, click
[link](https://docs.docker.com/engine/storage/drivers/select-storage-driver/)
for more information

## Error processing a compose file

Solution: make sure your docker compose is up to date
