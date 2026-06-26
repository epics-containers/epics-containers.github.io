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
