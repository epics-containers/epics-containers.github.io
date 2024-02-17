# Configuration for epics-containers

A collection of all the configuration points mentioned in the rest of this
documentation.

TODO: this needs completing - pull all configuration discussions into
one place. Most of these will come from the original Setting up the
Workspace document.


## Git Configuration

```
[url "ssh://git@github.com/"]
        insteadOf = https://github.com/
```

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

