(create-beamline)=

# Create a Beamline Services Repository

A {any}`services-repo` holds the configuration for every IOC and service on a
beamline. Here you generate one of your own from a template, so the tutorials
that follow have a repository you can deploy, push and customise.

This is the local **`docker compose`** track — ideal for development, and for
beamline servers without Kubernetes. To build a Helm/Kubernetes services repo
instead, see {any}`setup-k8s-beamline`.

Here you generate your own services repo, **`t01-services`**, from
[`services-template-compose`](https://github.com/epics-containers/services-template-compose)
— the same template behind the `example-services` repo you ran in
{any}`launch_example`. Substitute your own short name and repository throughout.

By the end you will have:

- a new repository, `t01-services`, generated from the template;
- a ready-made example IOC instance (`example-test-01`) plus the `gateway`,
  `pvagw`, `phoebus` and `epics-opis` services that the local `docker compose`
  workflow uses;
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
   copier copy https://github.com/epics-containers/services-template-compose t01-services
   ```

   :::{note}
   If `copier` is not installed you can run it on demand with `uvx`:
   `uvx copier copy https://github.com/epics-containers/services-template-compose t01-services`.
   :::

   `copier` asks two questions (defined in the template's `copier.yml`). Answer
   them as follows for the worked example:

   | Prompt | Worked-example answer |
   |---|---|
   | Short name for the collection of services | `t01` |
   | A One line description of the module | *(accept the default)* |

   The short name labels the repository as a whole; the bundled
   `example-test-01` IOC keeps its name until you add IOCs of your own in the
   tutorials that follow.

   :::{note}
   Using `copier` (rather than copying files by hand) lets you pull future
   template improvements into your repo later with `copier update`, without
   losing your own changes.
   :::

2. Create a new **empty** repository named `t01-services` on GitHub
   (<https://github.com/new>), then push your generated files to it:

   ```bash
   cd t01-services
   git init -b main
   git add .
   git commit -m "initial commit"
   git remote add origin https://github.com/<your-org>/t01-services
   git push -u origin main
   ```

   This first push triggers the repo's CI (you will check it below).

3. Tag a release so you have a versioned snapshot (CI runs on the tag too):

   ```bash
   git tag 2026.7.1
   git push origin 2026.7.1
   ```

   A date-based tag (`YYYY.M.N`) is a common choice for services repos;
   epics-containers does not enforce any versioning scheme.

4. Confirm CI passed. Open your repository's **Actions** tab
   (`https://github.com/<your-org>/t01-services/actions`). You should see a CI
   run for the `main` push and another for the tag. Each runs a **Run IOC
   checks** step (`.github/workflows/ci_verify.sh`) that validates every IOC's
   `config/ioc.yaml` with `ibek`. Confirm the latest run is green before
   continuing.

5. Open the project in VSCode to work on it:

   ```bash
   code .
   ```

   :::{note}
   **DLS users:** first run `module load vscode`.
   :::

## Next steps

- {any}`deploy-example-instance` — deploy and manage this example IOC instance
  locally with `docker compose`.
- The tutorials that follow turn this example into a real IOC instance of your
  own.
