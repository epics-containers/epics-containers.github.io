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

(devcontainer-cli)=

## Using the devcontainer CLI

The `devcontainer` CLI builds and launches the same developer container that
VSCode would, but driven entirely from the terminal. This is the route to take
if you use a terminal editor, or want to script your workflow.

### Install the CLI

The CLI is an npm package, so you need Node.js and `npm` available first.

```{note}
**DLS users:** run `module load node` to get `npm` on your workstation.
```

Install the CLI and check it runs:

```bash
npm install @devcontainers/cli
npx devcontainer --version
```

```{note}
`npm install` places the package in a `node_modules` directory **in the current
folder**, not globally. The simplest approach is to run the install, and all
subsequent `devcontainer` commands, from the same directory — your Generic IOC
clone works well. If you prefer to run from elsewhere, pass the IOC directory
explicitly with `--workspace-folder`, for example
`npx devcontainer up --workspace-folder /path/to/ioc-xxx`.
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
npx devcontainer up
# wait for the build to complete; the container is now running in the background
podman ps   # confirm it is up
```

Attach as many shells inside the running container as you need:

```bash
npx devcontainer exec bash
```

```{note}
Run `devcontainer up` and every `devcontainer exec` from the **same directory**
(the IOC folder), or pass `--workspace-folder /path/to/ioc-xxx` to each command.
The CLI uses the working directory to locate the right container, so a mismatch
will start or target the wrong one.
```

### Troubleshooting

`Error: spawn docker ENOENT` means the CLI cannot find a container engine. The
devcontainer CLI expects `docker` on the `PATH`; on a podman host you need
podman configured to provide a `docker`-compatible command (a `docker` alias or
the `podman-docker` shim). Confirm your developer container launches from VSCode
first — if that works, the engine itself is fine and the CLI just needs the
`docker` entry point. Running `./build` first is a good diagnostic, as it
exercises the same engine and submodules.
