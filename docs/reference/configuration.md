# Configuration for epics-containers

A collection of all the configuration points mentioned in the rest of this
documentation.

TODO: this needs completing - pull all configuration discussions into
one place. Most of these will come from the original Setting up the
Workspace document.

| | |
|---|---|

## Git Configuration

This setting replaces https URLS for github repositories with ssh URLs. This is useful for the ibek-support submodule in the ioc-XXX repositories because it uses an HTTPS URL so that it can be built anywhere. When you want to push changes it is more convenient to use ssh URLs.
```
[url "ssh://git@github.com/"]
        insteadOf = https://github.com/
```

| | |
|---|---|

## Vscode Settings

These settings can be edited using `Ctrl-Shift-P`: `Preferences: Open User Settings: (JSON)`

(scm_settings)=
### Disable recursive search for git repositories

Because all ioc-XXX have the same submodule `ibek-support` and because `/epics/support` in Generic IOCs contains many repositories, it is best not to automatically have vscode search for git repositories in the workspace. These settings are useful in this regard.

```json
    "scm.alwaysShowRepositories": true,
    "git.repositoryScanMaxDepth": 0,
    "scm.repositories.visible": 12,
```

### zsh shell

For a much richer command line experience, it is recommended to use the zsh shell in vscode, this will work inside Generic IOC devcontainers too. Use the following settings:

```json
    "terminal.integrated.profiles.linux": {
        "bash": {
            "path": "bash",
        },
        "zsh": {
            "path": "zsh"
        }
    },
    "terminal.integrated.defaultProfile.linux": "zsh",
```

| | |
|---|---|