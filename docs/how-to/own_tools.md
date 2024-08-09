# Choose Your Developer Environment

The tutorials walk through the use of a standard set of developer tools. You
can use others if you wish but support is limited currently.

(own-editor)=

## Working with your own code editor

If you have your own preferred code editor, you can use it instead of
vscode. We recommend developing generic IOCs using
a devcontainer. Devcontainer supporting tools are listed here
<https://containers.dev/supporting>.

epics-containers has been tested with

- vscode
- Github Codespaces

If you prefer console based editors like neovim or emacs, then you will get the best results by launching the development containers defined in the epics-containers using the devcontainer CLI as described here <https://containers.dev/supporting#devcontainer-cli>.

In addition you could install your editor inside the developer container by adding an apt-install command into the `epics-containers` user personalization file. See [details here](https://github.com/epics-containers/epics-containers.github.io/blob/3a87e808e1c7983430a30c5a4dcd0d0661895d60/.devcontainer/postCreateCommand#L23-L27)
