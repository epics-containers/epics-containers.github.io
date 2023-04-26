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
