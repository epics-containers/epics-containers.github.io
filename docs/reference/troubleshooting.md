# Troubleshooting

(multiple-iocs)=
## Running Multiple IOCs in DevContainers on one Workstation

If you want to test two or more IOCs on a workstation, you can launch two developer containers and run an IOC instance in each.

However, the auto port forwarding will not be able to bind to the default ports for the second container. It will therefore pick a different port number to bind to on the host. Inside of the container the IOC will still be listening on the default ports, but on the host the ports will be different. For example here is the PORTS tab of vscode when I have launched a second IOC on my workstation:

:::{figure} ../images/auto-ports2.png
Port Forwarding in the bottom panel of VSCode
:::

You will be able to interact with each of these IOCs as usual inside the container but what if you want to connect to both of them from outside the container? This can be done by adding the list of ports to the appropriate environment variables. For example:

```bash
export EPICS_CA_NAME_SERVERS="127.0.0.1:5064 127.0.0.1:5065"
export EPICS_PVA_NAME_SERVERS="127.0.0.1:5075 127.0.0.1:5076"
```

The equivalent settings in phoebus' settings.ini file would be:

```ini
org.phoebus.pv.ca/name_servers=127.0.0.1:5064 127.0.0.1:5065
org.phoebus.pv.pva/epics_pva_name_servers=127.0.0.1:5075 127.0.0.1:5076
```

## Unable to contact IOC PVs from outside the developer container

Note that sometimes you may get a zombie process holding on to your host's Channel Access ports. In this case when you start an IOC in devcontainer it will not bind to those ports as they are already in use. You just need to go to the PORTS tab and see which ports have been bound to the IOC and then set the environment variables accordingly. See the {any}`multiple-iocs` section for more information.

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


## Cleaning up Container Cache

Very occasionally it may be necessary to reset all of your container cache. You might want to do this if you have filled up your disk or if you just want to get back to a known state.

To remove all container cache on a workstation:

```bash
# clean out the podman local cache
podman system reset -f
```

The above removes:
- all images
- all containers including running containers
- all volumes
- all networks


If on the other hand you would like to just clear individual containers or images then:


```bash
# list all containers including stopped ones
podman ps -a
# use the generated name (last column) to remove some containers
podman rm container_name1 container_name2

# list all images
podman images
# use the image id to remove some images
podman rmi image_id1 image_id2
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

## Cannot connect to the container service

`podman` is daemonless, but `docker compose` talks to it through the podman
socket. If compose cannot connect, the podman user socket is probably not
running — see {any}`podman-integration` for how to enable it and point
`DOCKER_HOST` at it.

(If you are using docker instead of podman, see {any}`using-docker` for docker
daemon troubleshooting.)

## Container storage errors initializing the storage driver

Solution: The most likely reason is that you are using a filesystem like `zfs`
or `btrfs` which requires a special storage driver, click
[link](https://docs.docker.com/engine/storage/drivers/select-storage-driver/)
for more information

## Error processing a compose file

Solution: make sure your docker compose is up to date

## Disable recursive git-repository scanning in VSCode

Generic IOC dev containers mount many git repositories under `/epics/support`
(the `ibek-support` submodule plus support modules). Stop VSCode scanning them
all by adding to your user settings (`Ctrl-Shift-P` ->
`Preferences: Open User Settings (JSON)`):

```json
"scm.alwaysShowRepositories": true,
"git.repositoryScanMaxDepth": 0,
"scm.repositories.visible": 12,
```
