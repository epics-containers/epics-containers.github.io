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

### Turn off locale detection

If your host system locale settings differ from the dev container image settings, you may receive locale-related warning messages when using the integrated terminal in a dev container; e.g. during a module build:
```
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
        LANGUAGE = (unset),
        LC_ALL = (unset),
        LC_CTYPE = "C.UTF-8",
        LANG = "en_US.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to the standard locale ("C").
```
You can either generate and add the required locale settings to your system (with sudo permissions),
or simply turn off the locale detection in VSCode's settings to avoid having LANG set in the integrated terminal
```
Settings > Remote Dev_Container > Terminal > Integrated:Detect_Locale Off
```

| | |
|---|---|
