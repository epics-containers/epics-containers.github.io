# Recommended VSCode Settings

I've picked a handful of my user settings which I think are useful for most
people working on epics-containers.

TODO: write up a description of why these are useful. Particularly with
regards to auto discovery of git repos.

```
scm.repositories.visible: 10
git.repositoryScanMaxDepth: 0
git.openRepositoryInParentFolders: never
files.trimTrailingWhitespace: true
terminal.integrated.scrollback: 20000
    dev.containers.defaultExtensions: [
        "samuelcolvin.jinjahtml",
        "moshfeu.compare-folders",
        "GitHub.copilot",
        "charliermarsh.ruff",
        "Gruntfuggly.todo-tree",
        "streetsidesoftware.code-spell-checker",
        "eamodio.gitlens",
        "tamasfe.even-better-toml",
        "redhat.vscode-yaml",
        "ryanluker.vscode-coverage-gutters",
        "mhutchie.git-graph",
        "ms-vscode.makefile-tools"
        "peakchen90.open-html-in-browser",
    ],
"[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
},
```
