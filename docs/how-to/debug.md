# Debug an IOC instance locally

:::{warning}
This is an early draft
:::

This guide will show you how to debug an IOC instance locally. It will use the example IOC made in the [Create an IOC instance](./create-ioc-instance.md) guide. That IOC is called `bl01t-ea-test-02` in the guide but you may have chosen a different name.

## Setting up

Get the IOC Instance definition repository and deliberately break the IOC instance so that you can debug it.

```bash
git clone git@github.com:YOUR_GITHUB_USERNAME/bl01t.git
cd bl01t
source environment.sh
code .
# now edit services/bl01t-ea-test-02/config/ioc.yaml
```

## Breaking the IOC instance

Add the phrase 'deliberate_error' to the top of the `ioc.yaml` file. Then try to launch the IOC instance, but use the `-v` flag to see the underlying commands:

```bash
ec -v deploy-local services/bl01t-ea-test-02
```

You should see something like this (for docker users - podman users will see something similar):

<pre>$ ec -v deploy-local services/bl01t-ea-test-02
<font color="#5F8787">docker --version</font>
<font color="#5F8787">docker buildx version</font>
Deploy TEMPORARY version 2024.2.17-b8.30 from /home/giles/tutorial/bl01t/services/bl01t-ea-test-02 to the local docker instance
Are you sure ? [y/N]: y
<font color="#5F8787">docker stop -t0 bl01t-ea-test-02</font>
<font color="#5F8787">docker rm -f bl01t-ea-test-02</font>
<font color="#5F8787">docker volume rm -f bl01t-ea-test-02_config</font>
<font color="#5F8787">docker volume create bl01t-ea-test-02_config</font>
<font color="#5F8787">docker rm -f busybox</font>
<font color="#5F8787">docker container create --name busybox -v bl01t-ea-test-02_config:/copyto busybox</font>
<font color="#5F8787">docker cp /home/giles/tutorial/bl01t/services/bl01t-ea-test-02/config/ioc.yaml busybox:copyto</font>
<font color="#5F8787">docker rm -f busybox</font>
<font color="#5F8787">docker run -dit --net host --restart unless-stopped -l is_IOC=true -l version=2024.2.17-b8.30 -v bl01t-ea-test-02_config:/epics/ioc/config/ -e IOC_NAME=bl01t-ea-test-02  --name bl01t-ea-test-02 ghcr.io/epics-containers/ioc-adsimdetector-linux-runtime:2024.2.2</font>
76c2834dac805780b3329af91c332abb90fb2692a510c11b888b82e48f60b44f
<font color="#5F8787">docker ps -f name=bl01t-ea-test-02 --format &apos;{{.Names}}&apos;</font>
</pre>

Now if you try these commands you should see that the IOC instance keeps restarting and that the logs show an error:

```bash
ec ps
ec logs bl01t-ea-test-02
```

## Debugging the IOC instance

Now you can tell `ec` to stop the IOC instance and then run it in a way that you can debug it, by copying the command that `ec` used to run the IOC instance and adding the `--entrypoint bash` and removing `-d` flag and `--restart unless-stopped`. Also change the name to have a `-debug` suffix, like so:

```bash
ec stop bl01t-ea-test-02
docker run --entrypoint bash -it --net host -l is_IOC=true -l version=2024.2.17-b8.30 -v bl01t-ea-test-02_config:/epics/ioc/config/ -e IOC_NAME=bl01t-ea-test-02  --name bl01t-ea-test-02-debug ghcr.io/epics-containers/ioc-adsimdetector-linux-runtime:2024.2.2
```

You should now be in a shell inside the container. You can look at the files and run the IOC instance manually to see what the error is. You can re-run the IOC instance multiple times and you can even install your favourite editor or debugging tools.

e.g.

```bash
apt update
apt install vim
ls /epics/ioc/config/
cat /epics/ioc/config/ioc.yaml
cd /epics/ioc
./start.sh
# ctrl-d to exit
vim /epics/ioc/config/ioc.yaml
# fix the error
./start.sh
```

When you are done you can exit the container with `ctrl-d` and then remove it (or you can keep it around for later and restart it with `docker start -i bl01t-ea-test-02-debug`):

```bash
docker rm -f bl01t-ea-test-02-debug
```

You can now apply the fix you made to the local filesystem and retry the deployment.