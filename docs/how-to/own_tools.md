# Choose Your Developer Environment

The tutorials walk through a standard set of developer tools. You can use
others if you wish, but support for them is limited at present.

(own-editor)=

## Working with your own code editor

If you have a preferred code editor you can use it instead of VSCode. We
recommend developing Generic IOCs inside a developer container, as the
[Developer Containers](../tutorials/dev_container.md) tutorial describes;
editors with developer-container support are listed at
<https://containers.dev/supporting>.

epics-containers has been tested with:

- VSCode
- GitHub Codespaces

Terminal editors such as `neovim` or `emacs` work too. As that tutorial's
note explains, launch the Generic IOC's developer container with the
[devcontainer CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)
rather than by hand, so it picks up the host mounts and other settings from
`.devcontainer/devcontainer.json`.

To make your editor available inside the developer container, add an
`apt install` line for it to the `developer` stage of the Generic IOC's
`Dockerfile`.

(personalise-shell)=

## Personalise the developer container

### Shell settings and history

Generic IOC developer containers are built on
[ubuntu-devcontainer](https://github.com/DiamondLightSource/ubuntu-devcontainer),
which reads your shell configuration from a host folder, so one set of
personal settings is shared by every developer container you use.

`$HOME/.config/terminal-config` on the host is mounted at
`/user-terminal-config` in the container. The first time a container is
created it adds three starter files there, and it never overwrites them
afterwards:

| File | Purpose |
|---|---|
| `bashrc` | sourced by every `bash` terminal in the container |
| `zshrc` | the same for `zsh` |
| `inputrc` | readline behaviour, such as history search on the up arrow |

Each starter file loads a set of opinionated defaults. Add your own aliases,
prompt and environment variables below that line, or delete the line to drop
the defaults. Both `bashrc` and `zshrc` also have a block for commands that
should run only once per container, on the first shell started in it. Shell history is kept in the same folder
(`.bash_eternal_history`, `.zsh_eternal_history`), so it survives container
rebuilds and is shared between projects.

These files replace the older `.bashrc_dev_container`,
`.bashprofile_dev_container` and `/workspaces/.devcontainer_rc` mechanisms,
which are no longer used.

:::{note}
These hooks are installed in `/root/.bashrc`, `/root/.zshrc` and
`/root/.inputrc`, so they apply when the container runs as root (podman or
rootless docker). With rootful docker and `EC_REMOTE_USER` set to your own user
(see {doc}`../reference/docker`), your shell does not load them.
:::

### VSCode extensions

The extensions a Generic IOC needs are listed in its
`.devcontainer/devcontainer.json`. To add your own favourites to **every**
developer container without editing each project, list them in the
`dev.containers.defaultExtensions` setting in your VSCode *user* settings:

```json
"dev.containers.defaultExtensions": [
    "eamodio.gitlens",
    "vscodevim.vim"
]
```

(devcontainer-cli)=

## Using the devcontainer CLI

The `devcontainer` CLI builds and launches the same developer container that
VSCode would, but driven entirely from the terminal. This is the route to take
if you use a terminal editor, or want to script your workflow.

### Install the CLI once, shared across IOCs

The CLI is an npm package, so you need Node.js and `npm` available first.

```{note}
**DLS users:** run `module load node` to get `npm` on your workstation.
```

A plain `npm install @devcontainers/cli` drops a `node_modules/`,
`package.json` and `package-lock.json` into the current folder — if you run it
inside a Generic IOC clone, it leaves the repo dirty. Instead install the CLI
**globally, once**, into a user-writable prefix. A single install then serves
every IOC and keeps your repos clean:

```bash
npm config set prefix ~/.local          # one-time: a user-writable global prefix
npm install -g @devcontainers/cli
devcontainer --version                  # run from anywhere once ~/.local/bin is on PATH
```

```{note}
Make sure `~/.local/bin` is on your `PATH` so the `devcontainer` command is
found. The rest of this page calls `devcontainer` directly; if you skipped the
global install, prefix each command with `npx` and run it from the IOC folder.
```

### Build the Generic IOC first

Clone your Generic IOC repo and run its `./build` script before launching the
container. This pulls in the `ibek-support` submodules and surfaces any errors
in the container build step up front, where they are easy to read:

```bash
git clone <your-ioc-xxx-repo-url>
cd ioc-xxx
./build
```

```{tip}
If a support module fails to build, comment it out of the `Dockerfile` so the
container can build. You can then debug that module interactively from inside
the developer container.
```

### Launch and attach

From the IOC directory, bring the developer container up. It builds the image
if needed and then runs in the background:

```bash
devcontainer up --workspace-folder .
# wait for the build to complete; the container is now running in the background
podman ps   # confirm it is up
```

Attach as many shells inside the running container as you need:

```bash
devcontainer exec --workspace-folder . bash
```

```{note}
The CLI uses `--workspace-folder` to locate the right container. Point `up` and
every `exec` at the **same** IOC folder (`.` when you are inside it, or an
absolute path such as `/path/to/ioc-xxx` from elsewhere), or a mismatch will
start or target the wrong container.
```

### Clean up

The developer container keeps running in the background until you stop it. There
is no `devcontainer down` command — the CLI creates an ordinary podman
container, so tear it down with podman directly:

```bash
podman ps                  # find the container's name or id
podman stop <name-or-id>   # stop it (keeps the container for a fast restart)
podman rm -f <name-or-id>  # stop and remove it completely
```

To rebuild from scratch on the next launch — for example after editing the
`Dockerfile` — recreate the container with:

```bash
devcontainer up --workspace-folder . --remove-existing-container
```

### Troubleshooting

`Error: spawn docker ENOENT` means the CLI cannot find a container engine. The
devcontainer CLI expects `docker` on the `PATH`; on a podman host you need
podman configured to provide a `docker`-compatible command (a `docker` alias or
the `podman-docker` shim). Confirm your developer container launches from VSCode
first — if that works, the engine itself is fine and the CLI just needs the
`docker` entry point. Running `./build` first is a good diagnostic, as it
exercises the same engine and submodules.
Otherwise, add ` export DOCKER_PATH=$(which podman)` to your local `.bashrc`.

When building the container for the first time, if it tries to change ownership of
vscode directories: 
`chown: changing ownership of '/home/vscode': Invalid argument (os error 22)`, 
add the following to your devcontainer.json `"updateRemoteUserUid": false` 
to avoid remapping of UIDs.
