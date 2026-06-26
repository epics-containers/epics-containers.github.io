(create-beamline)=

# Create a Beamline Services Repository

A {any}`services-repo` holds the configuration for every IOC and service on a
beamline. Here you generate one of your own from a template, so the tutorials
that follow have a repository you can deploy, push and customise.

This is the local **`docker compose`** track — ideal for development, and for
beamline servers without Kubernetes. To build a Helm/Kubernetes services repo
instead, see {any}`setup-k8s-beamline`.

The worked example builds your own copy of the `example-services` repo you ran
in {any}`launch_example`, this time generated from
[`services-template-compose`](https://github.com/epics-containers/services-template-compose).
Substitute your own short name and repository throughout.

By the end you will have:

- a new repository, `example-services`, generated from the template;
- three ready-made example IOC instances (`bl01t-ea-test-01`,
  `bl01t-di-cam-01`, `bl01t-mo-sim-01`) plus the `gateway`, `pvagw`, `phoebus`
  and `epics-opis` services that the local `docker compose` workflow uses;
- the repo pushed to GitHub, where continuous integration (CI) validates every
  IOC configuration.

:::{note}
Names may use only lower-case letters, numbers and hyphens, and must start with
a letter (a restriction Helm imposes on package names). This applies to the
services short name and to every service/IOC name.
:::

## Prerequisites

- A [GitHub account](https://github.com/signup) (or organisation) to host the
  repository.
- `git`, and `copier` (see {any}`copier`), installed on your workstation.

For these tutorials you store everything in your personal GitHub account; in
production each facility sets its own policy for where these assets live.

(create-new-beamline-local)=
## Create the repository

1. Generate the repo from the template with `copier`:

   ```bash
   copier copy https://github.com/epics-containers/services-template-compose example-services
   ```

   :::{note}
   If `copier` is not installed you can run it on demand with `uvx`:
   `uvx copier copy https://github.com/epics-containers/services-template-compose example-services`.
   :::

   `copier` asks two questions (defined in the template's `copier.yml`). Answer
   them as follows for the worked example:

   | Prompt | Worked-example answer |
   |---|---|
   | Short name for the collection of services | `example` |
   | A One line description of the module | *(accept the default — `example IOC Instances and Services`)* |

   The short name labels the repository as a whole; the bundled example IOCs
   keep their `bl01t-*` names (the simulated beamline is `bl01t`) until you
   replace them with your own later.

   :::{note}
   Using `copier` (rather than copying files by hand) lets you pull future
   template improvements into your repo later with `copier update`, without
   losing your own changes.
   :::

2. Create a new **empty** repository named `example-services` on GitHub
   (<https://github.com/new>), then push your generated files to it:

   ```bash
   cd example-services
   git init -b main
   git add .
   git commit -m "initial commit"
   git remote add origin https://github.com/<your-org>/example-services
   git push -u origin main
   ```

   This first push triggers CI on the repo's **Actions** tab:
   `.github/workflows/ci_verify.sh` validates every IOC's `config/ioc.yaml` with
   `ibek`.

3. Tag a release so you have a versioned snapshot (CI runs on the tag too):

   ```bash
   git tag 2024.9.1
   git push origin 2024.9.1
   ```

   A date-based tag (`YYYY.M.N`) is a common choice for services repos;
   epics-containers does not enforce any versioning scheme.

4. Open the project in VSCode to work on it:

   ```bash
   code .
   ```

   :::{note}
   DLS users: first run `module load vscode`.
   :::

## Next steps

- {any}`deploy-example-instance` — deploy and manage these example IOC instances
  locally with `docker compose`.
- The tutorials that follow turn this example into a real IOC instance of your
  own.
