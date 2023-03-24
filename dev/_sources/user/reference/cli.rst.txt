.. _CLI:

Command Line Interface for IOC Management
=========================================

Built in to the devcontainer is epics-containers-cli, a command line interface
for assisting with building and managing IOCs in the cluster.

The CLI is just a thin wrapper around these tools:-

- kubectl
- helm
- podman (or docker)

To help with learning the above tools. The CLI will print out the commands it
executes before running them. This can be suppressed with the ``--quiet`` flag,
or by setting the ``K8S_QUIET=true`` in your environment.

The CLI entrypoint is ``ec``. To see the available commands, run ``ec --help``.
Much of the functionality is available through subcommands dev and ioc.
Below is pasted the current version of help for the CLI.

.. code-block::


        [E7][work-ec]$ ec --help

        Usage: ec [OPTIONS] COMMAND [ARGS]...

        EPICS Containers assistant CLI

        ╭─ Options ─────────────────────────────────────────────────────╮
        │ --version                           Log the version of ec and │
        │                                     exit                      │
        │ --domain              -d      TEXT  Domain namespace to use   │
        │                                     [default: bl00t]          │
        │ --image-registry              TEXT  Image registry to pull    │
        │                                     from                      │
        │                                     [default:                 │
        │                                     ghcr.io/gilesknap]        │
        │ --helm-registry               TEXT  Helm registry to pull     │
        │                                     from                      │
        │                                     [default:                 │
        │                                     ghcr.io/gilesknap]        │
        │ --quiet               -q            Suppress printing of      │
        │                                     commands executed         │
        │ --log-level                   TEXT  Log level (DEBUG, INFO,   │
        │                                     WARNING, ERROR, CRITICAL) │
        │                                     [default: WARN]           │
        │ --install-completion                Install completion for    │
        │                                     the current shell.        │
        │ --show-completion                   Show completion for the   │
        │                                     current shell, to copy it │
        │                                     or customize the          │
        │                                     installation.             │
        │ --help                              Show this message and     │
        │                                     exit.                     │
        ╰───────────────────────────────────────────────────────────────╯
        ╭─ Commands ────────────────────────────────────────────────────╮
        │ dev        Commands for building, debugging containers. See   │
        │            'ec dev --help'                                    │
        │ ioc        Commands for managing IOCs in the cluster. See 'ec │
        │            ioc --help'                                        │
        │ monitor    Monitor the status of IOCs in a domain             │
        │ ps         List the IOCs running in the current domain        │
        │ resources  Output information about a domain's cluster        │
        │            resources                                          │
        ╰───────────────────────────────────────────────────────────────╯

        [E7][work-ec]$ ec dev --help

        Usage: ec dev [OPTIONS] COMMAND [ARGS]...

        Commands for building, debugging containers. See 'ec dev
        --help'

        ╭─ Options ─────────────────────────────────────────────────────╮
        │ --help          Show this message and exit.                   │
        ╰───────────────────────────────────────────────────────────────╯
        ╭─ Commands ────────────────────────────────────────────────────╮
        │ build       Build a container locally from a container        │
        │             project.                                          │
        │ debug-last  Launches a container with the most recent image   │
        │             build. Useful for debugging failed builds         │
        │ ioc-launch  Launch an IOC instance using a local helm chart   │
        │             definition. Set folder for a locally editable     │
        │             generic IOC or tag to choose any version from the │
        │             registry.                                         │
        │ launch      Launch a bash prompt in a container               │
        │ make        make the generic IOC source code inside its       │
        │             container                                         │
        ╰───────────────────────────────────────────────────────────────╯

        [E7][work-ec]$ ec ioc --help

        Usage: ec ioc [OPTIONS] COMMAND [ARGS]...

        Commands for managing IOCs in the cluster. See 'ec ioc --help'

        ╭─ Options ─────────────────────────────────────────────────────╮
        │ --help          Show this message and exit.                   │
        ╰───────────────────────────────────────────────────────────────╯
        ╭─ Commands ────────────────────────────────────────────────────╮
        │ attach        Attach to the IOC shell of a live IOC           │
        │ delete        Remove an IOC helm deployment from the cluster  │
        │ deploy        Pull an IOC helm chart and deploy it to the     │
        │               cluster                                         │
        │ deploy-local  Deploy a local IOC helm chart directly to the   │
        │               cluster with dated beta version                 │
        │ exec          Execute a bash prompt in a live IOC's container │
        │ log-history   Open historical logs for an IOC                 │
        │ logs          Show logs for current and previous instances of │
        │               an IOC                                          │
        │ restart       Restart an IOC                                  │
        │ start         Start an IOC                                    │
        │ stop          Stop an IOC                                     │
        │ template      print out the helm template generated from a    │
        │               local ioc helm chart                            │
        │ versions      List all versions of the IOC available in the   │
        │               helm registry                                   │
        ╰───────────────────────────────────────────────────────────────╯
