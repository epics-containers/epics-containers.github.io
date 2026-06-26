# Set up a Developer Workstation

This page gets your workstation ready for the rest of the tutorials. By the end
you will have the handful of tools the tutorials rely on:

- **Visual Studio Code** — the recommended editor, for its devcontainer,
  Kubernetes, YAML and EPICS integration.
- **A container platform** — `podman` (recommended) or `docker`, plus
  `docker compose`.
- **`uv`** — installs and runs the Python CLI tools (`copier` and `ec`).
- **`git`** — configured for your user with access to your repositories.
- **Python 3.13+** — optional; `uv` can provide it for you.

Not using VSCode? You can use any editor — see {any}`own-editor`.

:::{note}
**Personal Access Tokens (PAT).** On an untrusted machine, authenticate to
GitHub with a fine-grained PAT (Settings → Developer Settings → Personal access
tokens) scoped to **Repository Contents** and **Workflows**, rather than an SSH
key. Cache it so you are not prompted repeatedly:

```bash
git config --global credential.helper 'cache --timeout 18000'
```

When prompted, enter your username and the PAT as the password. With a PAT,
clone over `https://github.com/...` rather than `git@github.com:...`.
:::

## Platform support

The tutorial container images are **x86_64 Linux**. The best experience is an
Intel Linux workstation or laptop (`arm64` images exist but are less widely
tested). On any other platform you have two options:

- run the container runtime natively — see the [quickstart](quickstart);
- or use the pre-built **VirtualBox appliance** below.

Either way you only need an internet connection to download the software and
images. (At DLS you do *not* need DLS network resources — just the internet.)

| Platform | Route |
|----------|-------|
| Any Linux (incl. DLS RHEL 8) | {ref}`installation-steps` |
| Windows | {ref}`appliance`, or WSL2 + Podman Desktop |
| Mac (Intel or Apple silicon) | {ref}`appliance`, or Podman Desktop |

(appliance)=
## VirtualBox Appliance

If you are on Mac or Windows and would rather not configure a container runtime
natively, use the Linux VM we provide with everything pre-installed. If you
already have a Linux machine with admin rights, skip to {ref}`installation-steps`
instead.

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Download the [virtual machine](https://drive.google.com/file/d/1AZ1ptVqTV4-YjCsNKQXdjOkA-d77hWp7/view?usp=sharing)
   (an OVA file) and import it with **File → Import Appliance**. The default
   resources are fine; 8 GB RAM and 4 CPUs is a sensible minimum.
3. Start the VM and log in as `ec-demo` / `demo1`.

The VM ships with Ubuntu 22.04, Python 3.13, VSCode, podman and a zsh shell. To
personalise it you only need to set up your git credentials and install the
Python CLI tools — jump to {ref}`cli-completion`, then {ref}`python-setup`.

(installation-steps)=
## Installation Steps

On your own Linux machine, work through the sections below.

### VSCode

:::{note}
**DLS users:** load it with `module load vscode`, then open your project with
`code .`.
:::

[Download and install VSCode](https://code.visualstudio.com/download), then add
the extensions you need. Only the first is required before the next tutorial;
the devcontainer installs the in-container extensions (Python, YAML, EPICS,
Ansible, …) for you.

- **Required:** [Remote Development] (the Dev Containers pack).
- **Windows:** [VSCode WSL2] (see [using WSL2 with VSCode]).
- Recommended: [VSCode EPICS] and [Kubernetes].

### Podman

We recommend `podman` because it is rootless by default — simpler and more
secure for developing and running IOCs (see {any}`rootless`). Version **4.0 or
later** is required; it is tested on RHEL 8 and Ubuntu 22.04+.

- [Install podman]

:::{note}
**DLS users:** RHEL 8 workstations ship podman 4.9.4 (RHEL 7 is not supported).
The first time you use podman on a DLS machine, run the shared setup script:

```bash
/dls_sw/apps/setup-podman/setup.sh
```
:::

:::{note}
**Prefer docker?** epics-containers fully supports `docker` too. The tutorials
say `podman` throughout, but every command has an identical `docker`
equivalent; see {any}`using-docker` for how to install it and the couple of
extra steps rootful docker needs in devcontainers.
:::

(podman-compose)=
### Docker Compose for podman users

`docker compose` runs a set of IOCs and other services together. The early
tutorials use it before moving on to Kubernetes, and it can also underpin a
non-Kubernetes production deployment.

:::{note}
**DLS users:** run `module load docker-compose` and you can skip the steps
below.
:::

1. Expose podman's docker-compatible API socket (once per workstation):

   ```bash
   systemctl enable --user podman.socket --now
   ```

2. Point docker tooling at that socket from your shell profile
   (`~/.bashrc` or `~/.zshrc`):

   ```bash
   export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
   ```

3. Install the standalone `docker compose` binary using the
   [docker compose install docs](https://docs.docker.com/compose/install/standalone).
   We prefer it over `podman-compose`; uninstall `podman-compose` if present.

(cli-completion)=
### Command line completion (optional)

Shell completion makes podman much easier to explore. Run once:

```bash
# bash
mkdir -p ~/.local/share/bash-completion/completions
podman completion bash > ~/.local/share/bash-completion/completions/podman

# zsh (oh-my-zsh)
mkdir -p ~/.oh-my-zsh/completions
podman completion zsh > ~/.oh-my-zsh/completions/_podman
```

(python-setup)=
### Python (optional)

The CLI tools need Python **3.13 or later**. You do not have to install it
yourself — `uv` (next) can manage Python versions for you. If you would rather
use a system Python, see the
[installation guide](https://docs.python-guide.org/starting/installation/).

:::{note}
**DLS users:** `module load python/3.13`.
:::

### uv

We use [uv](https://docs.astral.sh/uv/) to install and run the Python CLI tools
(`copier` and `ec`). It installs each tool into its own isolated environment and
puts it on your `PATH`, so there is no virtual environment to activate.

:::{note}
**DLS users:** `module load uv` instead of running the installer below.
:::

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

See the [uv install docs](https://docs.astral.sh/uv/getting-started/installation/)
for other methods (including Windows).

(copier)=
### copier and ec

`copier` stamps out the templates for services repositories and generic IOCs.
Install it now, along with `ec` (the edge-containers CLI used in the Kubernetes
tutorials):

```bash
uv tool install copier
uv tool install edge-containers-cli
```

Both are now on your `PATH` in every new shell — nothing to activate. Upgrade
later with `uv tool upgrade --all`. If a freshly installed tool is not found,
run `uv tool update-shell` and open a new shell.

### git

Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) if
you do not have it, then set your identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Set up credentials for your GitHub repositories using either a PAT (see the note
at the top of this page) or an
[SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

### Kubernetes

You do **not** need Kubernetes yet. The next tutorials create, deploy and debug
IOCs locally by deploying containers to your workstation's podman with
`docker compose`. Kubernetes comes later.

[download and install vscode]: https://code.visualstudio.com/download
[using wsl2 with vscode]: https://code.visualstudio.com/blogs/2019/09/03/wsl2
[install podman]: https://podman.io/getting-started/installation
[kubernetes]: https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools
[remote development]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
[vscode epics]: https://marketplace.visualstudio.com/items?itemName=nsd.vscode-epics
[vscode wsl2]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl
