# epics-containers Documentation Review — suggested updates

## Scope & method

This review covers two documentation sets:

- **Public docs** — the published site source at `epics-containers.github.io/docs` (Tutorials / How-to / Explanations / Reference / Landing).
- **Internal docs** — the DLS developer-guide at `developer-guide/topics/epics-containers/docs` (Explanations / Tutorials / How-tos / Reference).

Both were checked against the current local working copies of the implementation repos:

- `ibek` (CLI command tree incl. the new `ibek pattern` group, `runtime generate2`/`place-files`/`generate-autosave`).
- `edge-containers-cli` (`ec`) — the backend model (`ARGOCD` default / `K8S` / `DEMO`), per-backend command/option dropping, and the `ENV` variable set.
- `ioc-template` (Generic IOC copier template), `services-template-helm` (services repo copier template), `ec-helm-charts` (shared Helm charts: `ioc-instance`, `argocd-apps`, `epics-pvcs`, `epics-opis`, `carepeater`, `nfsv2-tftp`).
- `i21-services` as a real beamline services-repo example, and the ArgoCD deployment model via `t01-deployment` + `deployment-template-argocd` (with `edge-containers-cli` as the `ec` source).

**Caveat:** `i21-deployment` was not available locally (it lives on Diamond GitLab), so `t01-deployment` was used as the deployment-repo stand-in. All findings are stated against local working copies; line numbers refer to those copies.

---

## Executive summary

### Counts by repo × severity

| Repo | critical | major | minor | nit | Total |
|---|---|---|---|---|---|
| Public | 6 | 28 | 24 | 6 | 64 |
| Internal | 4 | 12 | 9 | 3 | 28 |
| Both (cross-cutting) | 1 | 2 | 1 | 0 | 4 |
| **Total** | **11** | **42** | **34** | **9** | **96** |

(Findings tagged `both` are reported once in Part 3.)

### Top themes (highest impact)

1. **`ibek pattern` runtime-support vendoring is undocumented everywhere.** The entire vendoring model (`add/update/check/restore/schema`, `runtime-lock.yaml`, per-instance `ioc.schema.json`, DO-NOT-EDIT headers, strict sha256 integrity, `DIRTY` opt-out, central pattern libraries) appears in zero public or internal pages — despite being wired into pre-commit, CI and Renovate. New pages are needed.
2. **ArgoCD deployment model has no tutorial/reference page.** The production CD path (deployment repo, app-of-apps, `apps/values.yaml` control surface, `ec deploy` → git commit → autosync) is only mentioned in passing prose.
3. **`ec` backend model is undocumented and `reference/environment.md` is wrong.** Three documented env vars no longer exist; the available commands/options change per backend; there is no `ec` command reference page.
4. **`uv`/`uvx` vs `venv`/`pip` drift.** Tutorials switched to `uv tool install`, but intro bullets, environment.sh fallbacks, and a few reference pages still teach `python -m venv`/`pip`.
5. **Removed/renamed `ibek` commands persist in docs.** `ibek build-startup` (now `ibek runtime generate`/`generate2`), `ibek ibek-schema`/`ioc-schema`, and the `ioc.boot.yaml` filename convention are stale across how-tos and tutorials.
6. **Removed `ec deploy-local` podman workflow.** `how-to/debug.md` is built on a deleted podman/busybox implementation; current `deploy-local` is Helm-on-Kubernetes and only exists under the `K8S` backend.
7. **Helm-chart value-key drift.** Docs reference `base_image`/`prefix`/`helm/shared`/`loadBalancerIP` — current `ioc-instance` chart uses `image` under an `ioc-instance:` map, `.helm-shared/`, and `static_ip`.
8. **Retired example repos and dead links.** `p45-services`/`p45-deployment`, `blxxi-template`, `bl38p`, and various missing-hyphen GHCR/package paths 404; the canonical public example is now `example-services` / `t01` / `bl01t`.

---

## Part 1 — Public docs (epics-containers.github.io)

### Tutorials

#### `docs/tutorials/launch_example.md` — wrong Channel Access port [critical, outdated-command]
- **Location:** line 41, `export EPICS_CA_ADDR_LIST=127.0.0.1:5094`
- **Issue:** The example-services compose project exposes CA on loopback at `EPICS_CA_SERVER_PORT=9064`; `5094` is neither the gateway port (9064) nor the CA default (5064). The following `caget BL01T-DI-CAM-01:DET:Acquire_RBV` cannot connect.
- **Fix:** Change line 41 to `export EPICS_CA_ADDR_LIST=127.0.0.1:9064`. Also fix the duplicate `5094` in `example-services/README.md:45,50`.
- **Evidence:** `launch_example.md:41`; `example-services/.env:3` (`EPICS_CA_SERVER_PORT=9064`); `example-services/services/gateway/compose.yml` (binds `127.0.0.1:9064` UDP+TCP); `example-services/environment.sh:44`.

#### `docs/tutorials/add_k8s_ioc.md` — unwritten stub [major, missing-content]
- **Location:** whole page; ends with `TODO: WIP` at line 9
- **Issue:** Published in the tutorials toctree (`tutorials.md:25`) right after the K8s setup tutorials, but contains only intro prose and a `TODO`. It is the Kubernetes counterpart of the 454-line `create_ioc.md` and covers the workflow the current implementation centres on (`.ioc_template`, `ibek pattern` vendoring, `ec deploy`).
- **Fix:** Write against shipped templates: copy `template/services/.ioc_template` → `services/<instance>`, set `ioc-instance.image` (currently `REPLACE_WITH_IMAGE_URI`), edit `config/ioc.yaml` entities + `description`, optionally `ibek pattern add ... services/<instance>`, let pre-commit hooks run, then `ec deploy <service> [<version>]`. Until written, mark as draft with a `{Warning}` admonition (as in `support_module.md:3-5`) or remove from the toctree.
- **Evidence:** `add_k8s_ioc.md:1-9`; `tutorials.md:25`; `services-template-helm/template/services/.ioc_template/`; `.pre-commit-config.yaml:44,66`; `edge-containers-cli/.../cli.py:93-105`.

#### `docs/tutorials/setup_k8s_new_beamline.md` — stale copier prompt walkthrough [major, outdated-command]
- **Location:** prompt walkthrough at lines 32-60 (local) and 64-92 (DLS/Pollux)
- **Issue:** Three prompts shown no longer exist in `services-template-helm/copier.yml`: `Apply cluster specific details.` (`cluster_type`), `The GitHub organisation that will contain this repo.` (`github_org`), and `Remote URI of the services repository.` (`repo_uri`). Current prompts: `domain`, `description`, `location`, `cluster_name`, `cluster_namespace`, `git_platform`, then conditional `dls_technical_area` (gitlab only), `gateway` (only when `location` starts with `bl`), `athena_services`, the `auth/numtracker/tiled` cascade, `instrument`, `logging_url`.
- **Fix:** Regenerate the walkthrough from current `copier.yml`. For the `t03` example with no athena services: `domain`, `description`, `location`, `cluster_name`, `cluster_namespace`, `git_platform`, `athena_services` (blank), `logging_url` — note the gateway prompt does NOT appear for `t03` (not `bl*`). Add a note that `repo_uri`/`cluster_type` (still consumed by `environment.sh.jinja:20,38`) are no longer prompted.
- **Evidence:** `setup_k8s_new_beamline.md:48-50,54-57` (and dup at :80-89); `services-template-helm/copier.yml`.

#### `docs/tutorials/setup_k8s_new_beamline.md` — example values.yaml/ioc.yaml pinned at 4.x [major, outdated-concept]
- **Location:** values.yaml block lines 164-166; ioc.yaml block line 173
- **Issue:** Pins ec-helm-charts schema at `4.1.3`, image `ioc-template-example-runtime:4.1.0`, and ibek schema at `4.1.0`. Current shared schema `$ref`s ec-helm-charts `5.4.6`, depends on `ioc-instance` chart `5.5.0`, and latest ec-helm-charts release is `5.6.1`.
- **Fix:** Bump to current 5.x: line 164 → `.../ec-helm-charts/releases/download/5.6.1/ioc-instance.schema.json`; update line 166 image tag; update line 173 ibek schema URL. Keep the absolute release-pinned URL style (do not switch to the template's relative `../../.helm-shared/values.schema.json`, which only resolves inside a generated repo).
- **Evidence:** `setup_k8s_new_beamline.md:164,166,173`; `services-template-helm/template/.helm-shared/values.schema.json:16`; `.helm-shared/Chart.yaml`.

#### `docs/tutorials/setup_k8s_new_beamline.md` — ioc.yaml uses remote pinned schema [minor, outdated-concept]
- **Location:** ioc.yaml block, line 173
- **Issue:** Declares a remote per-release ibek schema at `ioc-template-example/4.1.0`. The current skeleton uses a per-instance relative schema `$schema=../ioc.schema.json`, generated by `ibek pattern schema` / the `ibek-ioc-schema` pre-commit hook.
- **Fix:** Change line 173 to `# yaml-language-server: $schema=../ioc.schema.json`; add a sentence noting `ioc.schema.json` is generated per-instance (base IOC schema + vendored pattern entity models). Leave the values.yaml ec-helm-charts schema example as-is.
- **Evidence:** `setup_k8s_new_beamline.md:173`; `services-template-helm/template/services/.ioc_template/config/ioc.yaml:1`; `README.md.jinja:51-55`; `.pre-commit-config.yaml:34-44`.

#### `docs/tutorials/setup_k8s_new_beamline.md` — `epic-opis` typo [minor, outdated-command]
- **Location:** line 148, `ec -v deploy epic-opis 2024.9.1`
- **Issue:** Should be `epics-opis` (matches line 134/147 and the canonical chart name). No `epic-opis` service exists.
- **Fix:** Change `epic-opis` → `epics-opis`.
- **Evidence:** `setup_k8s_new_beamline.md:134,147,148`; `ec-helm-charts/Charts/epics-opis/Chart.yaml:2`.

#### `docs/tutorials/setup_k8s_new_beamline.md` — stale venv fallback note [nit, inconsistency]
- **Location:** lines 122-126 (`uv tool install edge-containers-cli` then `source ./environment.sh`)
- **Issue:** The doc correctly uses `uv tool install`, but the generated `environment.sh` prints a stale `pip install edge-containers-cli` error when `ec` is missing. The durable fix is in `services-template-helm/template/environment.sh.jinja:28` (out of this repo).
- **Fix:** Optionally add a one-line note that if `environment.sh` reports the venv/pip message, the recommended install is `uv tool install edge-containers-cli`.
- **Evidence:** `setup_k8s_new_beamline.md:122-126`; `setup_workstation.md:256`; `services-template-helm/template/environment.sh.jinja:27-29`.

#### `docs/tutorials/generic_ioc.md` — `.build.yml` vs `.install.yml` [major, inconsistency]
- **Location:** lines 223, 268, 272 (`.build.yml`) vs line 277 command (`.install.yml`) and line 283 schema
- **Issue:** Prose names the support recipe `<module>.build.yml` / `lakeshore340.build.yml`, but the creating command and schema use `.install.yml`. The real ibek-support convention is `*.install.yml`; no `*.build.yml` files exist anywhere. A reader would create a wrongly-named file.
- **Fix:** Replace the three `.build.yml` references with `.install.yml` (lines 223/268/272). The command and schema are already correct.
- **Evidence:** `generic_ioc.md:223,268,272,277,283`; `debug_generic_ioc.md:29,135`; `find /workspaces -name '*.build.yml'` → none.

#### `docs/tutorials/generic_ioc.md` — stale entities link [minor, outdated-concept]
- **Location:** lines 331-335 (link to ibek `entities` explanation, "currently out of date")
- **Issue:** The linked page documents removed commands `ibek ibek-schema`, `ibek ioc-schema`, `ibek build-startup` and superseded filename conventions. Pointing readers there propagates stale guidance.
- **Fix:** Drop reliance on the link until the upstream page is fixed; the tutorial's inline summary stands alone. If retained, keep the "out of date" warning.
- **Evidence:** `generic_ioc.md:331-335`; `ibek/docs/explanations/entities.rst:250,256,263-264`.

#### `docs/tutorials/generic_ioc.md` — bl00t/BL00T deviation [nit, inconsistency]
- **Location:** lines 520, 523, 524, 552, 577 (`bl00t`/`BL00T`) vs line 677 (`bl01t`)
- **Issue:** The example IOC instance uses `bl00t`/`BL00T` while the rest of the series uses `bl01t`/`t01`/`BL01T`. Isolated to this file.
- **Fix:** Replace `bl00t-ea-test-01` → `bl01t-ea-test-01` and `BL00T-EA-TEST-01` → `BL01T-EA-TEST-01`.
- **Evidence:** `generic_ioc.md:520,523,524,552,577,677`.

#### `docs/tutorials/dev_container2.md` — auto port forwarding requires manual override [major, inconsistency]
- **Location:** "Auto Port Forwarding" section, lines 43-72; admonition lines 45-47
- **Issue:** Presents auto-forwarding as default and says `remote.autoForwardPorts` must be enabled, but the shipped devcontainer hard-codes `"remote.autoForwardPorts": false` and never sets `autoForwardPortsSource`. With the shipped config the described behaviour does not happen, and the doc never says how to override.
- **Fix:** State the shipped value is `false`; give explicit steps to set `"remote.autoForwardPorts": true` and `"remote.autoForwardPortsSource": "process"` in VSCode settings (or the devcontainer settings block).
- **Evidence:** `dev_container2.md:45-57`; `ioc-adsimdetector/.devcontainer/devcontainer.json:58`; `ioc-template/template/.devcontainer/devcontainer.json`.

#### `docs/tutorials/dev_container2.md` — `/epics/opis` should be `/epics/opi` [minor, wrong-path]
- **Location:** line 97
- **Issue:** States the opi folder mounts at `/epics/opis` (plural); the bind mount target is `/epics/opi` (singular).
- **Fix:** Change `/epics/opis` → `/epics/opi`.
- **Evidence:** `dev_container2.md:97`; `ioc-template/template/.devcontainer/devcontainer.json:77`; `dev_container.md:264`.

#### `docs/tutorials/dev_container.md` — missing hyphen in opi mount path [minor, wrong-path]
- **Location:** Developer Container Layout table, line 265 (`${localWorkspaceFolder}/opi/autogenerated`)
- **Issue:** Missing hyphen; actual mount is `opi/auto-generated`.
- **Fix:** Change `opi/autogenerated` → `opi/auto-generated`.
- **Evidence:** `dev_container.md:264-266`; `ioc-template/template/.devcontainer/devcontainer.json:77`, `initializeCommand:12`, `opi/phoebus-launch.sh:19,52`.

#### `docs/tutorials/dev_container.md` — compose-only relaunch ignores Kubernetes path [minor, inconsistency]
- **Location:** "Types of Changes", lines 18-20, 25-27, 46 (`docker compose restart <ioc-name>`)
- **Issue:** Section says it covers Kubernetes IOCs but gives only compose relaunch commands. For Helm there is no `compose.yml`/`docker compose restart`; redeploy is `ec deploy`, restart is `ec restart`.
- **Fix:** Scope compose instructions to the local/compose path, then add the Helm peer: edit `values.yaml` + `config/ioc.yaml`, git commit + tag, `ec deploy <service> <version>` (or `ec restart <service>`). Apply to both type-1 and type-2 steps.
- **Evidence:** `dev_container.md:18-20,25-27,46`; `edge-containers-cli/.../k8s_commands.py:67-75,100-107`; `argo_commands.py:154,232`.

#### `docs/tutorials/create_ioc.md` — broken `start.sh` link [minor, broken-link]
- **Location:** line 119
- **Issue:** Links `.../ioc-template/blob/main/ioc/start.sh`, but the file is at `template/ioc/start.sh`. Line 24 already uses the correct path.
- **Fix:** Change to `.../blob/main/template/ioc/start.sh`.
- **Evidence:** `create_ioc.md:119,24`; `find /workspaces/ioc-template -name start.sh` → only `template/ioc/start.sh`.

#### `docs/tutorials/create_ioc.md` — contradictory release tag [minor, inconsistency]
- **Location:** line 325 (`releases/tag/2024.2.2`) vs lines 214/332 (`releases/download/2024.12.2/...`)
- **Issue:** The prose equates the `2024.2.2` release page with the `2024.12.2` schema asset — two different tags for the same asset.
- **Fix:** Change line 325 to `releases/tag/2024.12.2`.
- **Evidence:** `create_ioc.md:325,326-329,214,332`.

#### `docs/tutorials/ioc_changes1.md` — stale workspace dir name [minor, wrong-path]
- **Location:** line 54 (`/workspaces/bl01t/services/bl01t-ea-cam-01/config`)
- **Issue:** Uses `bl01t` workspace dir; line 12 and the rest use `t01-services`. Only the workspace segment is wrong.
- **Fix:** Change to `/workspaces/t01-services/services/bl01t-ea-cam-01/config`.
- **Evidence:** `ioc_changes1.md:54,12,57,80`.

#### `docs/tutorials/create_beamline.md` — stale copier version in transcript [minor, outdated-concept]
- **Location:** line 70 (`Copying from template version 3.5.0`)
- **Issue:** services-template-compose latest is `4.1.3`; the pasted transcript is stale.
- **Fix:** Update to `4.1.3` or genericise to `X.Y.Z`.
- **Evidence:** `create_beamline.md:70`; `gh api .../services-template-compose/releases/latest` → `4.1.3`.

#### `docs/tutorials/setup_workstation.md` — intro bullet still requires venv [minor, inconsistency]
- **Location:** line 9 (`- Python 3.10 or later + a Python virtual environment`)
- **Issue:** The body installs CLI tools via `uv tool install` and says there is no venv to create/activate. The bullet contradicts this and omits `uv`.
- **Fix:** Change line 9 to drop the venv requirement and add a `uv` bullet, e.g. "Python 3.10 or later (uv can also install this for you)" + "uv, to install the Python CLI tools (copier, ec)". Optionally revisit the stale step at line 82.
- **Evidence:** `setup_workstation.md:9,226-227,255-256,259`.

#### `docs/tutorials/deploy_example.md` — stale illustrative image tag [minor, outdated-concept]
- **Location:** line 104 (`ioc-template-example-runtime:3.5.1`)
- **Issue:** The reader "may have noticed" tag is stale; current example-services use `:4.4.6` and ioc-template latest is `4.6.0`.
- **Fix:** Reword to `:<version>`, or update to a current tag (e.g. `4.4.6`).
- **Evidence:** `deploy_example.md:104`; `example-services/services/bl01t-ea-test-01/compose.yml:9`.

#### `docs/tutorials/rtems_ioc.md` — broken cross-reference [major, broken-link]
- **Location:** line 267 (`linux IOCs in --local_deploy_ioc--.`)
- **Issue:** Invalid `--...--` syntax and a non-existent `local_deploy_ioc` anchor; `ec deploy-local` for linux IOCs is not covered in any tutorial.
- **Fix:** Drop the dangling sentence; end the bullet at "...to kubernetes as a beta version." Do not redirect to `deploy_example` (it does not cover `deploy-local`).
- **Evidence:** `rtems_ioc.md:267,264,265,277`; no `local_deploy_ioc` anchor in `docs/`.

#### `docs/tutorials/rtems_ioc.md` — removed RTEMS env-var names [major, outdated-command]
- **Location:** values.yaml env block lines 146-157; env table lines 170-179
- **Issue:** Lists removed vars `K8S_IOC_ADDRESS`, `RTEMS_VME_CONSOLE_ADDR`, `RTEMS_VME_CONSOLE_PORT`, `RTEMS_VME_AUTO_REBOOT`, `RTEMS_VME_AUTO_PAUSE`. Current rtems-proxy uses `RTEMS_IOC_IP` and a single `RTEMS_CONSOLE` (host:port), plus required `RTEMS_IOC_NETMASK`/`RTEMS_IOC_GATEWAY`/`RTEMS_NFS_IP`/`RTEMS_TFTP_IP`.
- **Fix:** Rewrite block + table per `rtems-proxy/.../globals.py` and `configure.py`: `K8S_IOC_ADDRESS`→`RTEMS_IOC_IP`; merge console addr/port into `RTEMS_CONSOLE` (`host:port`); drop auto-reboot/auto-pause; add the beamline-level vars. Also fix the YAML over-indentation of each `value:`.
- **Evidence:** `rtems_ioc.md:146-179`; `rtems-proxy/src/rtems_proxy/globals.py:81,84,57-72`; `configure.py:46-55`; `telnet.py:52`.

#### `docs/tutorials/rtems_ioc.md` — old flat Helm values schema [major, outdated-concept] — WON'T FIX (for now): entangled with the rtems env-var/image-name findings; deferred to the full rtems refresh.
- **Location:** values.yaml blocks lines 140-158 and 250-253
- **Issue:** Uses top-level `base_image:`, `env:`, `nfsv2TftpClaim:`. Current `ioc-instance` chart has no `base_image`; `image`/`env`/`nfsv2TftpClaim` must nest under `ioc-instance:`. The top-level schema has `additionalProperties: false`, so the doc fails validation.
- **Fix:** Nest under `ioc-instance:` and use `image` not `base_image`. Note `nfsv2TftpClaim` is referenced by the template but missing from the chart schema — maintainers should add it.
- **Evidence:** `rtems_ioc.md:141,143,253`; `ec-helm-charts/Charts/ioc-instance/values.yaml:16,23,92`; `ioc-instance.schema.json:116,350,353`; `example.values.yaml:5`.

#### `docs/tutorials/rtems_ioc.md` — Chart.yaml name-edit step obsolete [major, outdated-concept]
- **Location:** "Creating an RTEMS IOC Instance", lines 182-190
- **Issue:** Tells the user to edit `Chart.yaml` `name`/description. The per-instance `Chart.yaml` is a symlink to the shared `.helm-shared/Chart.yaml` (`name: ec-service`); IOC identity comes from the service folder name (`.Release.Name`) and `IOC_NAME`. Editing the symlink silently diverges the chart.
- **Fix:** Delete the step; add a note that the IOC name comes from the folder created by the earlier `cp -r`, and `Chart.yaml` is a shared symlink that must not be edited per-instance.
- **Evidence:** `rtems_ioc.md:182-190,112`; `services-template-helm/template/services/.ioc_template/Chart.yaml` (symlink); `ec-helm-charts/.../templates/_statefulset.tpl:31`.

#### `docs/tutorials/rtems_ioc.md` — malformed base-image names [minor, wrong-path]
- **Location:** lines 128-131 and 141
- **Issue:** Missing hyphen (`ioc-templateruntime`/`ioc-templatedeveloper`) and wrong extension (`-rtems-` instead of `-rtems-beatnik-`).
- **Fix:** Correct to `ioc-template-runtime`, `ioc-template-developer`, `ioc-template-rtems-beatnik-runtime`, `ioc-template-rtems-beatnik-developer`; update line 141 accordingly.
- **Evidence:** `rtems_ioc.md:128-131,141`; `ioc-template/.../workflows/build.yml.jinja:22,26,80,102`.

#### `docs/tutorials/rtems_ioc.md` — `deploy-local` without backend [minor, outdated-command]
- **Location:** lines 275-277 (`ec deploy-local services/bl01t-ea-test-02`)
- **Issue:** Default backend is ARGOCD, which drops `deploy-local` (only implemented for K8S). The documented command fails as an unknown subcommand.
- **Fix:** Use `ec -b K8S deploy-local ...` or `export EC_CLI_BACKEND=K8S` earlier, or switch to the ArgoCD `ec deploy` workflow. Same fix at `how-to/debug.md:26,31`.
- **Evidence:** `rtems_ioc.md:277`; `edge-containers-cli/.../__main__.py:18`; `k8s_commands.py:77`; `commands.py:131-137`; `backend.py:58-66`; `cli.py:361-367`.

#### `docs/tutorials/rtems_ioc.md` — malformed caput/caget commands [minor, outdated-command]
- **Location:** lines 310-311 (`caput get ...`, `caget get ...`)
- **Issue:** Stray `get` positional arg; commands would error.
- **Fix:** `caput bl01t-ea-test-02:B 13` and `caget bl01t-ea-test-02:SUM`.
- **Evidence:** `rtems_ioc.md:309-311`; `setup_k8s_new_beamline.md:284-290`.

#### `docs/tutorials/rtems_ioc.md` — `bl01t` beamline vs `t01-services` [minor, inconsistency]
- **Location:** lines 22-25, 105-108, 111, 276
- **Issue:** Refers to the `bl01t` beamline created in `create_beamline`, but that tutorial now creates `t01-services` (domain `t01`). `cd bl01t` is wrong.
- **Fix:** Update references to the `t01` beamline and change both `cd bl01t` → `cd t01-services`. Fold into the page's pending out-of-date refresh.
- **Evidence:** `rtems_ioc.md:22-25,105-106,111,276`; `create_beamline.md:20,65-66,85`.

#### `docs/tutorials/rtems_setup.md` — `loadBalancerIP` not user-settable [major, outdated-command] — WON'T FIX (for now): deferred to the full rtems refresh; leave the rtems pages untouched.
- **Location:** line 48 ("Change the `loadBalancerIP` value")
- **Issue:** The nfsv2-tftp chart exposes only `static_ip` (mapped internally to `loadBalancerIP`). Setting `loadBalancerIP` has no effect.
- **Fix:** Change to "Change the `static_ip` value in `values.yaml`".
- **Evidence:** `rtems_setup.md:48`; `ec-helm-charts/Charts/nfsv2-tftp/values.yaml:12`; `templates/deploy.yaml:106`.

#### `docs/tutorials/rtems_setup.md` — stale beamline name + nonexistent `services/nfsv2-tftp` [major, outdated-concept]
- **Location:** lines 39-48, 64-81
- **Issue:** (1) Says `create_beamline` made beamline `bl01t`, but it now makes `t01-services`. (2) Claims the template ships `services/nfsv2-tftp` and runs `helm upgrade --install ... services/nfsv2-tftp`, but neither current template ships that folder (services-template-helm has no nfsv2-tftp; services-template-compose has no `services/` dir). The chart now lives in `ec-helm-charts/Charts/nfsv2-tftp`.
- **Fix:** Reconcile to `t01`/`t01-services`; point at the `ec-helm-charts` nfsv2-tftp chart and show how it is added to a services repo today (e.g. `i04-services/services/nfsv2-tftp`); update deploy commands. Drop the per-service Chart.yaml name-edit concern (service charts keep their own Chart.yaml).
- **Evidence:** `rtems_setup.md:40,41,47,79-80`; `create_beamline.md:20,47,50`; `ls services-template-helm/template/services/`; `find /workspaces -iname '*nfsv2*'`.

#### `docs/tutorials/support_module.md` — `ibek dev support` is a stub [nit, outdated-concept]
- **Location:** line 19
- **Issue:** Points at `ibek dev support` as a future feature; it is wired into the CLI but raises `NotImplementedError`, so trying it crashes rather than doing the manual symlink.
- **Fix:** Note `ibek dev support` is currently a stub; the manual `ln -s` step remains the only supported approach.
- **Evidence:** `support_module.md:4,18-19`; `ibek/src/ibek/dev_cmds/commands.py:57-69`.

### How-to

#### `docs/how-to/debug.md` — built on removed podman `deploy-local` [critical, outdated-command]
- **Location:** lines 26, 31-47, 58-86
- **Issue:** The page shows a fabricated `ec -v deploy-local` podman/busybox transcript and a "copy the podman run command, add `--entrypoint bash`" technique. Current `deploy-local` requires a `Chart.yaml` and deploys via `helm package`/`helm upgrade --install`; no podman/busybox/`--restart`/`--entrypoint` code exists.
- **Fix:** Rewrite for Kubernetes/Helm: document `ec logs`/`ec logs -p`, `ec ps`, `ec exec`, `ec attach`, and note `deploy-local` now packages+installs a Helm chart. Alternatively document local debugging via the developer container (`ibek dev instance`). Delete the podman transcript and copy-the-command instructions.
- **Evidence:** `debug.md:26,44,58-62`; `edge-containers-cli/.../definitions.py:5-8`; `helm.py:55-66,82-124,127-134`; `cli.py:56,179,241`; `k8s_commands.py:47,82,89`.

#### `docs/how-to/copier_update.md` — beamline `copier update` missing `--trust` [critical, outdated-command]
- **Location:** line 33 (`copier update -r VERSION_NUMBER .`)
- **Issue:** services-template-helm now ships `_migrations` (v4.0.3b3 symlink, v6.0.0 vendoring). In copier 9.x, `copier update` against a template with migrations and no `--trust` raises `UnsafeTemplateError` and aborts. The generic-IOC commands on the same page already use `--trust`.
- **Fix:** Add `--trust`: `copier update -r VERSION_NUMBER --trust .`. The beamline `copier copy` (line 75) does NOT need `--trust` (no `_tasks`/`_jinja_extensions`, copy mode skips migrations).
- **Evidence:** `copier_update.md:33,51,69,75`; `services-template-helm/copier.yml:9-72`; copier `_main.py` `_check_unsafe`.

#### `docs/how-to/ibek-support.md` — removed `build-startup` command [critical, outdated-command]
- **Location:** lines 20-21 / 25 (`ibek build-startup config/ioc.boot.yaml ../../../ibek-defs/*/*.yaml`)
- **Issue:** No `build-startup` command exists; startup/db generation moved to `ibek runtime generate`/`generate2`. The instance file is `ioc.yaml` (not `ioc.boot.yaml`), and support files match `*ibek.support.yaml`.
- **Fix:** Replace with `ibek runtime generate config/ioc.yaml ../../../ibek-defs/*/*ibek.support.yaml` (single instance) or `ibek runtime generate2 config --definitions ...`. Do NOT rename `ibek-defs` (default `IBEK_DEFS` is still `<EPICS_ROOT>/ibek-defs`). Update prose `ioc.boot.yaml`→`ioc.yaml`.
- **Evidence:** `ibek-support.md:20-21`; `ibek/.../runtime_cmds/commands.py:23-90,112-131`; `globals.py:54,114`.

#### `docs/how-to/ibek-support.md` — false "msi invocations script" note [major, outdated-concept]
- **Location:** lines 36-37
- **Issue:** States ibek "generates a script of msi invocations instead of a substitution file" and "this will be changed". ibek already writes a real `ioc.subst` substitution file, expanded by msi at boot.
- **Fix:** Delete the paragraph.
- **Evidence:** `ibek-support.md:36-37`; `ibek/.../runtime_cmds/commands.py:228-229`; `gen_scripts.py:27`; `ioc.subst.jinja`.

#### `docs/how-to/ibek-support.md` — stale `ibek-defs` repo name [minor, terminology]
- **Location:** lines 1, 7-9, 16-17, 25, 31, 34
- **Issue:** Mixed naming: H1 says "ibek-support" but body refers to "ibek-defs" and clones `git@github.com:epics-containers/ibek-defs.git`. The repo was renamed to `ibek-support` (301 redirect); ioc-template wires the submodule as `ibek-support`.
- **Fix:** Replace `ibek-defs` references with `ibek-support`; use the actual naming convention `<module>/<module>.ibek.support.yaml`. (Old URL still redirects, hence minor.)
- **Evidence:** `ibek-support.md:1,7-9,16-17,25,31`; `ioc-template/copier.yml:19`; rename confirmed via `gh api repos/epics-containers/ibek-defs`.

#### `docs/how-to/builder2ibek.md` — DLS-only install path obsolete [major, outdated-concept]
- **Location:** lines 14-17 (`/dls_sw/work/python3/ec-venv/bin/builder2ibek`, "until a new python app distribution mechanism is in place")
- **Issue:** builder2ibek is now on PyPI (v2.1.0); the DLS-only path and caveat are outdated.
- **Fix:** Replace with `pip install builder2ibek` (or `uvx builder2ibek`); remove the caveat and DLS path. Optionally link to the builder2ibek docs.
- **Evidence:** `builder2ibek.md:14-17`; `builder2ibek/README.md:3,14`; `pyproject.toml:39-40`; PyPI v2.1.0.

#### `docs/how-to/builder2ibek.md` — no usage example / subcommands [minor, missing-content]
- **Location:** lines 11-12 (prose-only)
- **Issue:** builder2ibek is a multi-command CLI; conversion is `builder2ibek xml2yaml`. The page never mentions any subcommand.
- **Fix:** Add `builder2ibek xml2yaml <ioc.xml> --yaml <out.yaml>` and mention `beamline2yaml`, `autosave`, `migrate-autosave`, `db-compare`, `reconvert`.
- **Evidence:** `builder2ibek.md:11-12`; `builder2ibek/src/builder2ibek/__main__.py:12,34-50,53,66,82,137,169`.

#### `docs/how-to/copier_update.md` — wrong templates symlink target [minor, wrong-path] — FIXED (PR pending)
- **Location:** line 40 (`points at ../../include/ioc/templates`)
- **Issue:** No such path exists; templates symlinks point at `../../.helm-shared/templates`.
- **Fix:** Change to `../../.helm-shared/templates`.
- **Evidence:** `copier_update.md:40`; `readlink services-template-helm/template/services/.ioc_template/templates`.

### Explanations

#### `docs/explanations/repositories.md` — retired p45 example links 404 [major, broken-link]
- **Location:** lines 51-56 ("### p45-services")
- **Issue:** Links `epics-containers/p45-services` and `p45-deployment`, both HTTP 404. The canonical public example is `t01`/`example-services`.
- **Fix:** Rename the subsection to `example-services`; point to `https://github.com/epics-containers/example-services`. For the deployment sentence, do NOT substitute a `p45-deployment`-style URL (none exists publicly); drop it or reference `deployment-template-argocd`.
- **Evidence:** `repositories.md:51,54,56`; curl 404s for p45-services/p45-deployment; 200 for example-services; t01-services 301→example-services.

#### `docs/explanations/introduction.md` — broken Generic IOC package link + non-pullable tag [major, broken-link]
- **Location:** line 42 (`.../pkgs/container/ioc-adaravisruntime`, image `ioc-adaravis-runtime:2024.2.2`)
- **Issue:** URL is missing the hyphen (404); the displayed tag `2024.2.2` was never published as a runtime image (manifest 404). Stray trailing space in link text.
- **Fix:** URL → `.../pkgs/container/ioc-adaravis-runtime`; update the image to a published tag (e.g. `v2.3ec1` or a current calendar tag); remove the trailing space.
- **Evidence:** `introduction.md:42`; curl results; `i21-services/services/bl21i-di-cam-01/values.yaml:4`.

#### `docs/explanations/introduction.md` — incomplete config-folder list [major, missing-content]
- **Location:** "generic-iocs" section, lines 57-65
- **Issue:** Lists only `ioc.yaml`, `st.cmd`/`ioc.subst`, `start.sh`. Modern instances also place runtime-support inputs in `config/` (`*.proto`/`*.protocol`, extra `*.db`/`*.template`, `*.ibek.support.yaml`) — vendored via `ibek pattern add` (pinned in `runtime-lock.yaml`) or hand-authored — copied into runtime search paths at boot by `ibek runtime place-files`. Does not state that `config/` IS the ConfigMap (size-bounded, ~1 MiB) or that `runtime-lock.yaml`/`ioc.schema.json` sit at the instance root.
- **Fix:** Add a runtime-support bullet (vendored + local `*.ibek.support.yaml`, optional `runtime.yaml` overlay); note `config/` is the ConfigMap at `/epics/ioc/config`, self-contained per ADR 0004; note the lock/schema are siblings of `config/`. Cross-link a vendoring how-to.
- **Evidence:** `introduction.md:57-65`; `ioc-template/template/ioc/start.sh:64,80-82`; `ibek/.../runtime_cmds/commands.py:74,134-157`; `pattern_cmds/vendor.py:44-58`; `README.md.jinja:19-67`; `ibek ADR 0004`.

#### `docs/explanations/autosave.md` — wrong `.req` filenames [major, outdated-concept]
- **Location:** lines 107 and 128
- **Issue:** Says the MSI-expanded files are `autosave_positions.sav.req` and `autosave_settings.req`. ibek generates symmetric `autosave_positions.req` / `autosave_settings.req` (no `.sav.req`); `.sav` applies only to restore files.
- **Fix:** Change `autosave_positions.sav.req` → `autosave_positions.req` on lines 107 and 128 (and remove the stray trailing `z` on line 128).
- **Evidence:** `autosave.md:107,128,64-65,69,85,46-47`; `ibek/.../runtime_cmds/autosave.py:60,75-76,85`.

#### `docs/explanations/autosave.md` — output paths /epics/runtime vs /epics/autosave [major, outdated-concept]
- **Location:** "Runtime behaviour", lines 117-128; pre-init snippet line 38
- **Issue:** Implies expanded `.req` files live in `/epics/autosave`. Actually they are written to `RUNTIME_OUTPUT` (`/epics/runtime`); `/epics/autosave` is only the MSI include (`-I`) path. The current recipe emits both `set_requestfile_path("/epics","autosave")` and `set_requestfile_path("/epics","runtime")`, but the pre-init snippet has only the autosave line.
- **Fix:** Clarify `.req` files go to `/epics/runtime` with `/epics/autosave` as the `-I` path; add the missing `set_requestfile_path("/epics","runtime")` line.
- **Evidence:** `autosave.md:38,117-128`; `ioc-adaravis/ibek-support/autosave/autosave.ibek.support.yaml:62-63`; `ibek/.../autosave.py:76,84-85`; `globals.py:42-44,67-69`.

#### `docs/explanations/autosave.md` — misattributed `asSetFilename` line [minor, inconsistency]
- **Location:** line 48
- **Issue:** The pre-init snippet ends with `asSetFilename $(PVLOGGING)/src/access.acf`, which is emitted by the pvlogging module, not autosave.
- **Fix:** Remove the line, or annotate that it comes from pvlogging when both modules are enabled.
- **Evidence:** `autosave.md:48`; `autosave.ibek.support.yaml:59-76`; `pvlogging.ibek.support.yaml:30,47`.

#### `docs/explanations/autosave.md` — BL45P vs BL47P [nit, inconsistency]
- **Location:** line 24 ("BL45P-MO-IOC-01") vs lines 28/40/53/55-57 (BL47P/p47)
- **Issue:** Prose example PV prefix disagrees with the YAML and all other references.
- **Fix:** Change line 24 to `BL47P-MO-IOC-01`.
- **Evidence:** `autosave.md:24,28,40,53,55-57`.

#### `docs/explanations/autosave.md` — stray trailing `z` [nit, other]
- **Location:** line 128 ("...in the startup script.z")
- **Issue:** Typo after the final period.
- **Fix:** Delete the trailing `z`.
- **Evidence:** `autosave.md:128` (od -c confirms).

#### `docs/explanations/epics_protocols.md` — mislabeled link [minor, broken-link]
- **Location:** line 17 (`[ioc-template](https://github.com/epics-containers/example-services)`)
- **Issue:** Link text says `ioc-template` and prose describes the developer container, but the URL points at example-services (already correctly linked in item 3).
- **Fix:** Change URL to `https://github.com/epics-containers/ioc-template`.
- **Evidence:** `epics_protocols.md:17,23`; devcontainer descriptions.

#### `docs/explanations/changes.md` — hard-coded ec/ibek versions [minor, outdated-concept]
- **Location:** line 39 ("at versions 3.4.0 and 2.0.0 respectively")
- **Issue:** ec is now 5.x, ibek 4.x; the numbers are stale by multiple major versions.
- **Fix:** Use current major lines (ec 5.x, ibek 4.x) or drop versions and point at the changelog.
- **Evidence:** `changes.md:39`; gh tags: edge-containers-cli 5.2.1, ibek 4.6.1.

#### `docs/explanations/introduction.md` — ibek "st.cmd and ioc.db" [nit, outdated-concept]
- **Location:** line 240
- **Issue:** Says ibek generates "st.cmd and ioc.db". ibek writes `st.cmd` and `ioc.subst`; `ioc.db` is produced by msi in start.sh. Contradicts lines 59-60.
- **Fix:** "...generating st.cmd and ioc.subst (which msi then expands into ioc.db)..." or use "st.cmd and ioc.subst".
- **Evidence:** `introduction.md:240,59-60`; `ibek/.../runtime_cmds/commands.py:222,229`; `ioc-template/template/ioc/start.sh:56,63-65`.

### Reference

#### `docs/reference/environment.md` — nonexistent env vars (Required/Optional) [critical, outdated-concept]
- **Location:** lines 27-79 (`EC_REGISTRY_MAPPING`, `EC_K8S_NAMESPACE`, `EC_CONTAINER_CLI`)
- **Issue:** These three vars do not exist in current edge-containers-cli. The deployment namespace is now `EC_TARGET`; container-engine selection is gone (ec wraps a backend, not a container CLI). The valid set (definitions.py `ENV`) is `EC_SERVICES_REPO`, `EC_TARGET`, `EC_LOGIN`, `EC_CLI_BACKEND`, `EC_VERBOSE`, `EC_DRYRUN`, `EC_DEBUG`, `EC_LOG_LEVEL`, `EC_LOG_URL`. The `EC_LOG_URL` placeholder is `{service_name}` (not `{ioc_name}`/`{ioc-name}`).
- **Fix:** Delete `EC_REGISTRY_MAPPING`/`EC_CONTAINER_CLI`; replace `EC_K8S_NAMESPACE` with `EC_TARGET` (K8S namespace, or ARGOCD `app-namespace/root-app`); add `EC_CLI_BACKEND` (default ARGOCD) and `EC_LOGIN`; keep `EC_SERVICES_REPO`/`EC_LOG_URL`/`EC_DEBUG`; document `EC_VERBOSE`/`EC_DRYRUN`/`EC_LOG_LEVEL`; correct the `EC_LOG_URL` placeholder to `{service_name}`. Mention `ec env`.
- **Evidence:** `environment.md:29-79`; `edge-containers-cli/.../definitions.py:19-28`; `__main__.py:18,56-57,123`; `argo_commands.py:190,383-390`; `k8s_commands.py:94`.

#### `docs/reference/environment.md` — wrong EC_LOG_URL placeholder [major, outdated-command]
- **Location:** lines 64, 68 (`{ioc-name}` / `{ioc_name}`)
- **Issue:** Code uses `.format(service_name=...)`; the only valid placeholder is `{service_name}`. The documented URL raises `KeyError`.
- **Fix:** Replace placeholders with `{service_name}` in both prose and example (`...q=pod_name%3A{service_name}*`).
- **Evidence:** `environment.md:64,68`; `k8s_commands.py:94`; `argo_commands.py:190`.

#### `docs/reference/environment.md` — old package name [major, outdated-concept]
- **Location:** lines 14, 84 (`epics-containers-cli`)
- **Issue:** Old package name; line 92 already uses `edge-containers-cli`.
- **Fix:** Replace `epics-containers-cli` with `edge-containers-cli` at 14 and 84; optionally align "pip installing" with `uv tool install`.
- **Evidence:** `environment.md:14,84,92`; `edge-containers-cli/pyproject.toml:6`; `changelog.md:51`.

#### `docs/reference/environment.md` — dead bl38p / blxxi-template links [major, broken-link]
- **Location:** lines 54-55, 85, 118-119, 123-125
- **Issue:** Links `epics-containers/bl38p/.../environment.sh` (×3) and names `blxxi-template`; both repos 404.
- **Fix:** Point `EC_SERVICES_REPO` example and the two `environment.sh` links at `example-services`; replace `blxxi-template` with `services-template-helm` (or services-template-compose).
- **Evidence:** `environment.md:54-55,85,118-125`; `gh repo view` NOT FOUND for bl38p/blxxi-template; example-services has `environment.sh`.

#### `docs/reference/ioc_helm_chart.md` — whole page stale [major, outdated-concept]
- **Location:** whole page (banner lines 3-5); blxxi-template, `base_image`, `prefix`, `helm/shared`, `templates/ioc.yaml`, `/workspaces/epics/ioc/config`
- **Issue:** Self-declared out of date. Points at retired `blxxi-template` (404). Documents `base_image`/`prefix` keys that do not exist; current values nest under `ioc-instance:` (mandatory `image`) with a `global:` map. References `helm/shared` (now `.helm-shared/`) and `templates/ioc.yaml` (now `.helm-shared/templates/ioc_instance.yaml`). Wrong config mount path. Omits the other ec-helm-charts charts and per-instance `ioc.schema.json`.
- **Fix:** Rewrite against ec-helm-charts/services-template-helm: explain `ioc-instance` is a library chart consumed by a per-domain `ec-service` chart via OCI dependency and `{{ include "ioc-instance" . }}`; values under `ioc-instance:` + `global:`; `.helm-shared/` layout with symlinks; correct mount path `/epics/ioc/config`; mention `ioc.schema.json`; list argocd-apps/epics-pvcs/epics-opis/carepeater/nfsv2-tftp.
- **Evidence:** `ioc_helm_chart.md:3-5,11-15,36,39,45,51,57`; blxxi-template 404; `ec-helm-charts/Charts/ioc-instance/values.yaml:16,23,29,37,52`; `services-template-helm/template/.helm-shared/*`; `i21-services/services/values.yaml:5`.

#### `docs/reference/ioc_helm_chart.md` — dead blxxi-template example link [major, broken-link]
- **Location:** lines 11-12, 14-16, 19
- **Issue:** Links `blxxi-template/.../services/blxxi-ea-ioc-01`; repo 404. Current equivalent is `example-services/.../services/bl01t-ea-test-01`.
- **Fix:** Replace link with `https://github.com/epics-containers/example-services/tree/main/services/bl01t-ea-test-01`; update prose repo/folder names.
- **Evidence:** `ioc_helm_chart.md:11-19`; `gh repo view blxxi-template` NOT FOUND; example-services `services/` listing.

#### `docs/reference/ioc_helm_chart.md` — `base_image`/`prefix` value keys [major, outdated-concept]
- **Location:** lines 39-49
- **Issue:** No top-level `base_image` key; image is `image` under `ioc-instance:`. `prefix` is only an optional override (defaulting to release name) setting `IOC_PREFIX`; record/PV prefixes are set in `config/ioc.yaml` entities.
- **Fix:** Replace `base_image` with `ioc-instance.image`; clarify `prefix` is an optional `IOC_PREFIX` override, and PV prefixes live in `config/ioc.yaml`.
- **Evidence:** `ioc_helm_chart.md:39,45-49`; `ec-helm-charts/.../values.yaml`; `_statefulset.tpl:283-284`; `i21-services/.../config/ioc.yaml:27`.

#### `docs/reference/ioc_helm_chart.md` — wrong file/path descriptions [major, wrong-path]
- **Location:** lines 51-58
- **Issue:** (1) Master template is `ioc_instance.yaml`, not `templates/ioc.yaml`. (2) Config mounts at `/epics/ioc/config`, not `/workspaces/epics/ioc/config`. (3) Config folder's primary content is `config/ioc.yaml` (+ optional `ioc.db`), not "st.cmd only"; st.cmd/ioc.subst are generated at runtime.
- **Fix:** `templates/ioc.yaml` → `templates/ioc_instance.yaml`; mount path → `/epics/ioc/config`; describe `config/ioc.yaml` + runtime generation via `ibek runtime generate2`.
- **Evidence:** `ioc_helm_chart.md:51,57,58`; `.helm-shared/templates/ioc_instance.yaml:1`; `ioc-template/template/ioc/start.sh:29,55-58,94`; `epics-base/Dockerfile:23,26`.

#### `docs/reference/ioc_helm_chart.md` — `helm/shared` path [minor, wrong-path]
- **Location:** line 36
- **Issue:** Repository defaults now live in `.helm-shared` (hidden, repo root), not `helm/shared`.
- **Fix:** `helm/shared` → `.helm-shared`. (Same stale path at `reference/k8s_resources.md:21`.)
- **Evidence:** `ioc_helm_chart.md:36`; `services-template-helm/template/.helm-shared/`; `ci_verify.sh:128`.

#### `docs/reference/ioc_helm_chart.md` — broken start.sh link [minor, broken-link]
- **Location:** line 69 (link def `[this bash script]`)
- **Issue:** Points at `.../ioc-template/blob/main/ioc/start.sh` (404); file is at `template/ioc/start.sh`.
- **Fix:** `.../blob/main/template/ioc/start.sh`.
- **Evidence:** `ioc_helm_chart.md:63,69`; `copier.yml:12`; curl 404 vs 200.

#### `docs/reference/k8s_resources.md` — Deployment vs StatefulSet [major, outdated-concept]
- **Location:** lines 31-37
- **Issue:** Lists `Deployment` as the key resource and links the Deployment concept page. The `ioc-instance` chart produces a StatefulSet; the K8S backend manages statefulsets.
- **Fix:** Replace `Deployment` with `StatefulSet`; change the link to the StatefulSet concept page.
- **Evidence:** `k8s_resources.md:33-36`; `ec-helm-charts/.../templates/_statefulset.tpl:29`; `k8s_commands.py:112,119,139`.

#### `docs/reference/k8s_resources.md` — stale `ec template` example [major, outdated-concept]
- **Location:** lines 14-22
- **Issue:** Uses nonexistent `bl01t-ea-ioc-01`; obsolete `helm-ioc-lib` and `helm/shared/values.yaml` paths. Also `ec template` is dropped under the default ARGOCD backend.
- **Fix:** Use a real K8S/helm services repo + instance; note `ec template` requires `EC_CLI_BACKEND=K8S`; replace `helm-ioc-lib` with `.helm-shared/templates` + the `ioc-instance` library chart from OCI; replace `helm/shared/values.yaml` with global `services/values.yaml`.
- **Evidence:** `k8s_resources.md:15,18-22`; example-services `services/` listing; `i21-services/.helm-shared/Chart.yaml`; `__main__.py:18`; `argo_commands.py` (no `template`); `k8s_commands.py:123`.

#### `docs/reference/helm.md` — WIP stub / stale claim [minor→major, missing-content]
- **Location:** line 6, line 8 ("## TODO this is WIP"), lines 10-15
- **Issue:** Unfinished stub. Only sets `EC_CLI_BACKEND=K8S` and runs `ec --help`. Documents none of the K8S backend behaviour. Line 6's "replicates ArgoCD's ability to track versions" is partly stale (K8S start/stop have no `--commit`, are scale-only, no git audit). No `HELM` backend exists.
- **Fix:** Document the real K8S backend: `EC_TARGET` is a namespace (vs ARGOCD `namespace/root-app`); `ec deploy <svc> [version]` shallow-clones `EC_SERVICES_REPO` at the tag and runs `helm upgrade --install services/<svc>`; `template`/`deploy-local` operate on local charts; start/stop = `kubectl scale statefulset --replicas=1/0`; `delete` = `helm delete`; attach/exec/restart/logs use kubectl. Note Helm is internal to the K8S backend, not a backend value. Temper the line 6 claim.
- **Evidence:** `helm.md:6,8,10-15`; `definitions.py:5-8,21`; `k8s_commands.py:54-58,60-80,109-134,245`; `helm.py:76-80,115`; `argo_commands.py:33-35`.

#### `docs/reference/troubleshooting.md` — duplicated CA port in settings.ini [minor, inconsistency]
- **Location:** line 24 (`127.0.0.1:5064 127.0.0.1:5064`)
- **Issue:** Duplicates 5064; the bash example (line 17) uses `5064 5065`, and the PVA line (25) correctly uses `5075 5076`.
- **Fix:** Change second entry to `127.0.0.1:5065`.
- **Evidence:** `troubleshooting.md:17,21,24,25`.

#### `docs/reference/glossary.md` — only 3 entries, omits core nouns [major, missing-content]
- **Location:** lines 1-32
- **Issue:** Only `services repository`, `edge-containers-cli`, `ibek`. Omits the two most-used nouns — `Generic IOC` (~190) and `IOC instance` (~211) — and `support module` (~139), `ibek-defs/ibek-support` (~76), `ConfigMap`, `developer/runtime container`, `deployment repository`.
- **Fix:** Add entries (each with a MyST `(name)=` anchor) for at least `Generic IOC`, `IOC instance`, `support module`, `ibek-defs/ibek-support`, `ConfigMap`, reusing wording from `introduction.md:44-55`.
- **Evidence:** `glossary.md:4-5,14-15,22-23`; `introduction.md:38,44-55,68`; grep counts.

#### `docs/reference/glossary.md` — garbled edge-containers-cli entry [major, outdated-concept]
- **Location:** lines 15-19 ("features for and monitoring and managing and IOC instances")
- **Issue:** Grammatically garbled and IOC-only scope; ec now manages general services (the reason for the rename). Inconsistent with the adjacent services-repository entry.
- **Fix:** Rewrite, e.g. "...simple commands to deploy, monitor and manage IOC instances and other services within a [](services-repo). It is a thin wrapper around git, kubectl, helm and argocd, and supports multiple backends (default ARGOCD, plus K8S and DEMO)." Keep "The entry point is `ec`."
- **Evidence:** `glossary.md:7,17`; `changelog.md:51`; `definitions.py:5-8`; `__main__.py:18`; `edge-containers-cli/README.md:11-12`.

#### `docs/reference/glossary.md` — fix garbled sentence (grammar) [nit, other]
- **Location:** line 17
- **Issue:** "simple features for and monitoring and managing and IOC instances" — three misplaced "and"s.
- **Fix:** "It provides simple features for monitoring and managing IOC instances within a [](services-repo)." (Subsumed by the rewrite above; listed for completeness.)
- **Evidence:** `glossary.md:17`.

#### `docs/reference/glossary.md` — no `domain` entry [major, inconsistency]
- **Location:** whole glossary; `domain` used across repositories.md/environment.md/ioc_helm_chart.md
- **Issue:** `domain` is a core copier variable but is undefined and used interchangeably with "beamline" with no canonical anchor.
- **Fix:** Add `(domain)=` entry: a grouping of IOC instances/services deployed together; at DLS a beamline (e.g. i16) or accelerator technical area (e.g. rf, va); names the DOM-services/DOM-deployment repos. Standardise prose to use the glossary term.
- **Evidence:** `glossary.md:5,14,22`; `services-template-helm/copier.yml:78-84`; `deployment-template-argocd/copier.yml:8,11`; `new-domain.md:15`.

#### `docs/reference/glossary.md` — no `ConfigMap` entry [minor, missing-content]
- **Location:** whole glossary; term used at decisions/0003 and copier_update.md (as "configmap")
- **Issue:** ConfigMap is load-bearing (config/ → ConfigMap; ~1 MB limit forces substitution files per ADR 0003) but undefined and inconsistently capitalised.
- **Fix:** Add a `ConfigMap` entry; standardise capitalisation (fix `copier_update.md:40` "configmap"→"ConfigMap"); cross-link config/. Reconcile the mount-path disagreement separately.
- **Evidence:** `glossary.md:1-32`; `decisions/0003-use-substitution-files.md:48`; `copier_update.md:40`; conflicting mount paths in `ioc_helm_chart.md:57` vs `debug.md:73`.

#### `docs/reference/glossary.md` — ibek entry omits pattern vendoring [minor, outdated-concept / terminology]
- **Location:** lines 22-31
- **Issue:** Describes only pre-pattern roles; omits the `ibek pattern` group (add/update/check/restore/schema, `runtime-lock.yaml`, sha256 hashes) and `runtime generate2`/`place-files`. Also omits Definition/Entity terminology.
- **Fix:** Add a bullet for vendoring/verifying per-instance runtime support via `ibek pattern`; optionally note `generate2`/`place-files`. Confirm subcommand list against the installed ibek.
- **Evidence:** `glossary.md:22-31`; `ibek/.../__main__.py:34-38`; `pattern_cmds/commands.py:66,86,104,128,141`; `runtime_cmds/commands.py:24,94`.

### Landing / overview

#### `docs/index.md` — Materials link date mismatch [minor, inconsistency]
- **Location:** line 12 ("Nov 2023" → `images/epics-oxfordshire-nov-2024`)
- **Issue:** Link text says Nov 2023; the linked file is named nov-2024.
- **Fix:** Reconcile text and file name (confirm true date); if Nov 2024, change text to "Nov 2024".
- **Evidence:** `index.md:12`; `ls docs/images/`; git history (ca9b294, 6769eac).

#### `docs/overview.md` — services repos "deploy via ArgoCD" oversimplification [minor, inconsistency]
- **Location:** CI/CD theme, lines 21-24
- **Issue:** Says "Services repositories automatically deploy IOCs to Kubernetes clusters using ArgoCD." Services repos only build/test charts; ArgoCD watches a separate deployment repo (app-of-apps). Contradicts `introduction.md:190,206-212`.
- **Fix:** Introduce the deployment repo: "...A companion deployment repository records which IOC versions should run, and ArgoCD continuously reconciles the cluster to match it."
- **Evidence:** `overview.md:22-24`; `t01-deployment/apps.yaml:14-23`; `apps/values.yaml:3-9,16`; `t01-services/.github/workflows/verify.yml:16-18`; `introduction.md:190,206-212`.

---

## Part 2 — Internal docs (developer-guide)

### Explanations

#### `docs/explanations/templates.md` — Generic IOC copier command missing `--trust` [critical, outdated-command]
- **Location:** line 65 (`uvx copier copy https://github.com/epics-containers/ioc-template ioc-xxx`)
- **Issue:** ioc-template declares `_tasks` (git init, remote add, `git submodule add` of ibek-support). Without `--trust`, copier skips these tasks → generated repo lacks the ibek-support submodule → image build fails. Both ioc-template's README and the public tutorial already use `--trust`.
- **Fix:** Add `--trust`: `uvx copier copy --trust https://github.com/epics-containers/ioc-template ioc-xxx`.
- **Evidence:** `templates.md:64-66`; `ioc-template/copier.yml:16-21`; `ioc-template/README.md:10`; `generic_ioc.md:77`. (services-template-helm/deployment-template-argocd have no `_tasks`, so the fix is scoped to ioc-template.)

#### `docs/explanations/templates.md` — `.ioc-template` should be `.ioc_template` [major, wrong-path]
- **Location:** lines 28, 31
- **Issue:** Hyphenated `.ioc-template`; the shipped folder is `.ioc_template` (underscore). Literal copy fails. `how-tos/new-ioc.md:25` uses the correct name.
- **Fix:** Change both occurrences to `.ioc_template`.
- **Evidence:** `templates.md:28,31`; `ls services-template-helm/template/services/`; `new-ioc.md:25`.

#### `docs/explanations/templates.md` — incomplete default-services list [minor, missing-content]
- **Location:** lines 24-29
- **Issue:** Lists pvcs, opis, `.ioc_template`, "Optional DAQ services" but omits the always-created `{{ location }}-synoptic` service and the conditional `{{ domain }}-epics-gateways` (beamlines, `gateway` default true).
- **Fix:** Add bullets for `ixx-synoptic` (always created) and `ixx-epics-gateways` (beamlines when `gateway` enabled).
- **Evidence:** `templates.md:24-29`; `ls services-template-helm/template/services/`; `copier.yml:156-161`.

#### `docs/explanations/templates.md` — deployment block missing `module load uv` [nit, inconsistency]
- **Location:** lines 46-48 (and 64-66)
- **Issue:** The Services block (line 16) and the how-to use `module load uv` before `uvx copier copy`; the Deployment (and Generic IOC) blocks omit it.
- **Fix:** Prepend `module load uv` to the deployment block (and optionally the IOC block).
- **Evidence:** `templates.md:15-17,46-48,64-66`; `new-domain.md:29-30,73-74`.

#### `docs/explanations/templates.md` — Generic IOC section omits DLS-relevant copier vars [minor, missing-content]
- **Location:** Generic IOC Template section, lines 60-80
- **Issue:** Omits `--trust` (see critical above), the `rtems` bool (adds RTEMS-beatnik CI matrix entry), and `git_platform` (GitHub Actions vs GitLab kaniko CI).
- **Fix:** Add `--trust`; document `rtems` (DLS PowerPC RTEMS-beatnik) and `git_platform` effects on CI.
- **Evidence:** `templates.md:65,70`; `ioc-template/copier.yml`; `build.yml.jinja:17,20-22`.

#### `docs/explanations/argocd-accelerator.md` — `ec deploy` ≠ sync [major, outdated-concept]
- **Location:** "Synchronisation", line 43
- **Issue:** Lists `ec deploy` as a way to "trigger a sync". ARGOCD `ec deploy` only commits/pushes the version change then runs `argocd app get --refresh` ("Rely on argocd autosync"). There is no `argocd app sync` in the CLI. With auto-sync disabled during a run, `ec deploy` records desired state but does not deploy.
- **Fix:** Distinguish recording desired state from forcing sync: while auto-sync is disabled, use the Web UI "Sync" button (or `argocd app sync`); `ec deploy` only records the change.
- **Evidence:** `argocd-accelerator.md:38,40,42,43`; `argo_commands.py:88-104,154-183`; `git.py:39,53-56`; no `argocd app sync` in src.

#### `docs/explanations/argocd.md` — syncPolicy omits `selfHeal` [minor, inconsistency]
- **Location:** line 91 (`SyncPolicy: {Automated: {Prune: true}}`)
- **Issue:** The real root App sets `automated` with `prune: true` AND `selfHeal: true`. selfHeal (auto-revert out-of-band changes) is omitted.
- **Fix:** Show `syncPolicy: {automated: {prune: true, selfHeal: true}}` and add a sentence about selfHeal.
- **Evidence:** `argocd.md:91`; `t01-deployment/apps.yaml:20-23`; `deployment-template-argocd/template/apps.yaml.jinja:20-23`.

#### `docs/explanations/argocd.md` — absolute single-ArgoCD claims contradict accelerator [major, inconsistency]
- **Location:** lines 25, 27, 35, 83
- **Issue:** "a single instance of ArgoCD running in the Argus cluster" (25) and "only the Argus cluster has ArgoCD installed" (83) contradict `argocd-accelerator.md:19,21` (the accelerator runs its own ArgoCD on Hylas). The relationship is mixed (some secondary-network accelerator IOCs do use Argus).
- **Fix:** Qualify the absolute claims to describe beamlines/labs; cross-reference `argocd-accelerator.md`; clarify most accelerator IOCs use the separate Hylas instance while still living in the `accelerator` namespace.
- **Evidence:** `argocd.md:25,27,35,83`; `argocd-accelerator.md:19,21,38,51`.

#### `docs/explanations/ec-dls.md` — "frequent use of git submodules" overstated [minor/major, outdated-concept]
- **Location:** warning block, lines 81-87
- **Issue:** Services repos no longer carry a runtime-support submodule (v6.0.0 retired `ibek-runtime-streamdevice` in favour of `ibek pattern`). Remaining submodules: `ibek-support` (Generic IOC repos) and the optional `techui-support` (synoptic). "Frequent use" across the framework is inaccurate; the warning's position after the Services Repository table makes it especially misleading.
- **Fix:** Narrow the warning: scope submodules to Generic IOC repos (`ibek-support`) and the optional `techui-support`; note runtime support is now vendored per-instance via `ibek pattern`. Keep the HTTPS/SSH push guidance scoped to repos that actually have submodules.
- **Evidence:** `ec-dls.md:81-87,71-79`; `services-template-helm/copier.yml:38-71`; `ci_verify.sh:22-25`; `.pre-commit-config.yaml:20-23`; `ioc-template/copier.yml:19`.

#### `docs/explanations/ec-dls.md` — Deployment Repository "No CI" becoming stale [minor, outdated-concept]
- **Location:** line 114 ("Deployment Repository | No CI at present."); also `update-templates.md:61`
- **Issue:** deployment-template-argocd (and t01-deployment) now scaffold a GitHub Actions `verify.yml` calling `ci_verify.sh`, but the script is a stub (`# Todo`). The docs imply no CI infra exists.
- **Fix:** Note a CI workflow is scaffolded but currently a stub; keep the ArgoCD sentence. Align `update-templates.md:61` ("No CI yet" → "bash .github/workflows/ci_verify.sh (currently a stub)").
- **Evidence:** `ec-dls.md:114`; `update-templates.md:61`; `t01-deployment/.github/workflows/verify.yml:1-3,16`; `ci_verify.sh:1-3`.

### Tutorials

#### `docs/tutorials/delete-beamline.md` — wrong gateway service name [critical, outdated-command]
- **Location:** line 73 (`kubectl get svc t01-gateways`); prose lines 9, 56
- **Issue:** Deployed service is `t01-epics-gateways`. With `set -e`, the failing `kubectl get svc t01-gateways` aborts the script; the SSH tunnel forwards from a blank IP. Phoebus cannot connect.
- **Fix:** Change line 73 to `t01-epics-gateways`; update prose at 9/56. (Also fix `ixx-epics-opis`→`t01-epics-opis` at 9/74 — see next.)
- **Evidence:** `delete-beamline.md:73,9,56`; `t01-services/ec-setup.sh:10`; `t01-deployment/apps/values.yaml:40`; `epics-gateways/helm/templates/service.yaml:4`.

#### `docs/tutorials/delete-beamline.md` — placeholder `ixx-epics-opis` [critical, wrong-path]
- **Location:** line 74 (`kubectl get svc ixx-epics-opis`); prose lines 9, 56
- **Issue:** `ixx` is a `{{ domain }}` placeholder; the real service is `t01-epics-opis`. The query finds nothing; `opis` is empty; the OPI tunnel `-L 8099:$opis:80` fails.
- **Fix:** Change line 74 to `t01-epics-opis`; update prose at 9/56.
- **Evidence:** `delete-beamline.md:74,9,56,76`; `t01-deployment/apps/values.yaml:34`; `t01-services/services/t01-epics-opis`.

#### `docs/tutorials/example-beamline.md` — `ixx-epics-*` child app names [major, wrong-path]
- **Location:** lines 185, 186, 188, 207
- **Issue:** Names default child apps `ixx-epics-pvcs`/`ixx-epics-opis`; for t01 they are `t01-epics-pvcs`/`t01-epics-opis`. Line 207 already shows the root app as `<FEDID>/t01`, so the `ixx-` names are clearly wrong.
- **Fix:** Replace with `t01-epics-pvcs`/`t01-epics-opis` at 185/186/188/207. Leave any general naming-convention text as-is.
- **Evidence:** `example-beamline.md:185,186,188,207`; `t01-deployment/apps/values.yaml:33-34`; `t01-services/services/`.

#### `docs/tutorials/example-beamline.md` — `ec-setup.sh` should use `ec/user` module [major, outdated-concept]
- **Location:** "Setup the `ec` CLI for Your Personal Namespace", lines 254-268
- **Issue:** Tells the user to `module load ec/p47` then manually reassign `EC_SERVICES_REPO`/`EC_TARGET`. A purpose-built `ec/user` module now exists (sets `EC_TARGET=$USER/t01`, `EC_K8S_NAMESPACE=$USER`, `EC_BEAMLINE=t01`, derives `EC_SERVICES_REPO` from git origin, sets kube context, loads argus). The hand-rolled approach also leaves `EC_K8S_NAMESPACE`/`EC_BEAMLINE` at p47 values. (Note: the original `export`-inheritance concern is inaccurate — module env_vars are exported via Tcl `setenv`.)
- **Fix:** Replace the `ec-setup.sh` body with `module load ec/user`, matching `t01-services/ec-setup.sh`; remove the manual reassignments and the separate `module load argus`. Keep `cd t01-services` before sourcing so the module reads the correct git remote.
- **Evidence:** `example-beamline.md:256-268`; `deploy-tools-config/configuration/ec/user.yaml:7-29`, `p47.yaml:14-22`; `t01-services/ec-setup.sh`; `deploy-tools/.../modulefile:25`.

#### `docs/tutorials/example-beamline.md` — kubectl apply vs argocd app create [minor, inconsistency]
- **Location:** line 204 (`kubectl apply -f apps.yaml`); also `delete-beamline.md:28,38`
- **Issue:** The template/t01-deployment READMEs document `argocd app create --file apps.yaml`. kubectl works (apps.yaml is a valid Application CR) but diverges from the recommended CLI workflow and relies on direct K8s RBAC.
- **Fix:** Use `argocd app create --file apps.yaml` / `argocd app delete t01`, or add a note that `kubectl apply` is an equivalent way used here because the tutorial grants kubectl access via `module load argus`.
- **Evidence:** `example-beamline.md:204`; `delete-beamline.md:28,38`; `deployment-template-argocd/template/README.md.jinja:9`; `t01-deployment/README.md:9`, `apps.yaml:2,4`.

#### `docs/tutorials/example-beamline.md` — "added two IOCs in the deployment repository" misplaced [nit, other]
- **Location:** line 277
- **Issue:** States the IOCs were added to the deployment repository, but they were added to the services repo (t01-services); the deployment repo is updated later by `ec deploy` (line 310). Contradicts the next "empty list" expectation.
- **Fix:** Delete the sentence, or rephrase to reference the services repository.
- **Evidence:** `example-beamline.md:277,279,285-289,224-247,295-298,310`.

#### `docs/tutorials/example-beamline.md` — stale camera image tag [minor, inconsistency]
- **Location:** line 236 (`ioc-adsimdetector-runtime:2025.8.2`)
- **Issue:** example-services now pins the camera to `:2.11ec1` with a matching config schema; running a 2.11ec1 config under a 2025.8.2 image risks ibek validation failures. (motorsim `2025.8.2` is correct.)
- **Fix:** Change the camera image to `:2.11ec1`; leave motorsim. Better: avoid hardcoding tags that must track example-services.
- **Evidence:** `example-beamline.md:227-228,235,236`; `example-services/services/bl01t-di-cam-01/compose.yml:7`, `config/ioc.yaml:1`; commit fff8edf.

#### `docs/tutorials/phoebus.md` — stale gateway Chart/values + developer image [major, outdated-concept]
- **Location:** "Add an EPICS Gateway", lines 35-62
- **Issue:** Pins `epics-gateways version: 2025.7.4` and instructs using `epics-gateways-developer:2025.7.4`. Current template generates `version: 2026.4.1` and comments out the developer image (defaults to chart version), providing a `securityContext` instead.
- **Fix:** Update Chart version to `2026.4.1` (or version-agnostic); replace developer-image instructions with the current values.yaml shape (commented-out developer image + `securityContext`); drop the "use the developer image for debugging" advice. Keep `hostNetwork: false` as user-edit guidance.
- **Evidence:** `phoebus.md:44,51,54,59,61`; `services-template-helm/template/services/{{domain}}-epics-gateways/Chart.yaml:9`, `values.yaml:2-8`.

#### `docs/tutorials/phoebus.md` — wrong service names [major, wrong-path]
- **Location:** lines 83, 92, 94, 104, 108, 139, 154
- **Issue:** Uses `t01-gateways`, `ixx-epics-opis`, `ixx-epics-pvcs` — none exist. Real names: `t01-epics-gateways`, `t01-epics-opis`, `t01-epics-pvcs` (lines 33/72 already use the correct gateway name).
- **Fix:** `t01-gateways`→`t01-epics-gateways`; `ixx-epics-opis`→`t01-epics-opis`; `ixx-epics-pvcs`→`t01-epics-pvcs`. Keep the explicit generic production example (line 92) phrased generically.
- **Evidence:** `phoebus.md:83,92,94,104,108,139,154,33,72`; `t01-services/services/`; `t01-deployment/apps/values.yaml:33-40`.

#### `docs/tutorials/release-ioc.md` — wrong repo name `ec-helm-templates` [minor, terminology]
- **Location:** line 131 ("fixed in the 5.0.0 release of `ec-helm-templates`")
- **Issue:** No `ec-helm-templates` repo exists. The shared charts repo is `ec-helm-charts`; the behaviour is the `ioc-instance` chart's `rebootEveryCommit` value (default false). The `5.0.0` version is unverifiable.
- **Fix:** Reference the `ioc-instance` chart in `ec-helm-charts` and its `rebootEveryCommit` value (default false); phrase the version generically.
- **Evidence:** `release-ioc.md:131`; `ec-helm-charts/Charts/ioc-instance/values.yaml:55`, `_statefulset.tpl:38-39,275`.

#### `docs/tutorials/ec-cli.md` — stale verbose `ps` output (label selector) [minor, outdated-command]
- **Location:** line 18 (`argocd app list -l "ec_service=true" --app-namespace hgv27681 -o yaml`)
- **Issue:** The ARGOCD backend no longer applies a label selector; `_get_services` runs `argocd app list --app-namespace {ns} -o yaml`. The `ec_service` label is gone from source.
- **Fix:** Remove `-l "ec_service=true"` from the sample line.
- **Evidence:** `ec-cli.md:18`; `argo_commands.py:266`.

### How-tos

#### `docs/how-tos/new-ioc.md` — no runtime-support vendoring section [critical, missing-content]
- **Location:** "Edit the IOC Configuration", lines 48-54
- **Issue:** Tells engineers to supply only `config/ioc.yaml` (or hand-written st.cmd/ioc.subst). The current workflow requires vendoring runtime support into `config/` via `ibek pattern`, enforced by pre-commit (`ibek-ioc-schema`, `ibek-pattern-check`) and `ci_verify.sh` (loops `services/*/runtime-lock.yaml`). A StreamDevice IOC fails CI/pre-commit and lacks `ioc.schema.json` without it.
- **Fix:** Add a "Vendoring Runtime Support" section: `ibek pattern add [<library>:]<pattern>[@<tag>] services/<instance>`, `update`, `check`, `restore`; default libraries; DO-NOT-EDIT/sha256-pinned files (never hand-edit; CI fails on mismatch unless marked `DIRTY`); one-off editable `*.ibek.support.yaml` in config/. Cross-link the services-template-helm README "Vendoring runtime support".
- **Evidence:** `new-ioc.md:48-54`; `README.md.jinja:19-67`; `.pre-commit-config.yaml:58-73`; `ci_verify.sh:67-81`; `ibek/.../pattern_cmds/commands.py:66-141`, `sources.py:23-27`.

#### `docs/how-tos/new-ioc.md` — no deploy steps [minor, missing-content]
- **Location:** end of page (after the create_ioc.html link, line 55)
- **Issue:** Unlike `dev-c7-ioc.md` (which has "Deploy the New Instance"), it never says to commit/push the `make-new-ioc` branch, open an MR, or `ec deploy`. The reader can't get the IOC running from this guide alone.
- **Fix:** Add a "Deploy the New Instance" section (commit/push branch → optional `ec deploy <instance> make-new-ioc` → MR to main → after merge `ec deploy <instance> main`). Link to `git-workflow.md`/`release-ioc.md`.
- **Evidence:** `new-ioc.md:55`; `dev-c7-ioc.md:123-150`; `cli.py:93-105`; `git-workflow.md`; `release-ioc.md:57,100`.

#### `docs/how-tos/new-ioc.md` — unresolved editorial TODOs [nit, other]
- **Location:** "Naming and Granularity", lines 32-34
- **Issue:** Two `> TODO` blockquotes published in a user-facing page (EPICS naming convention reference; DNS-name renaming question).
- **Fix:** Remove both; replace the first with a link/summary of the naming convention, resolve or drop the second.
- **Evidence:** `new-ioc.md:28,32-34`.

#### `docs/how-tos/update-templates.md` — `./ci_verify` should be `./ci_verify.sh` [major, outdated-command]
- **Location:** line 60 (services-template-helm row)
- **Issue:** Local CI command given as `./ci_verify`; the script is `ci_verify.sh` (no extensionless file exists), so `./ci_verify` fails.
- **Fix:** Change to `./ci_verify.sh`.
- **Evidence:** `update-templates.md:60`; `services-template-helm/template/ci_verify.sh`; `verify.yml:18`; `.gitlab-ci.yml:16`.

#### `docs/how-tos/convert-ioc.md` — nonexistent `dbdiff` command [minor, outdated-command]
- **Location:** line 19 ("provides a `dbdiff` command")
- **Issue:** The command is `db-compare` (used two lines later at line 24); `dbdiff` does not exist.
- **Fix:** Change "dbdiff" → "db-compare".
- **Evidence:** `convert-ioc.md:19,24`; `builder2ibek/src/builder2ibek/__main__.py:137-138`.

#### `docs/how-tos/new-domain.md` — accelerator "ArgoCD not set up" stale [major, inconsistency]
- **Location:** warning lines 11-13; ArgoCD section lines 85-91
- **Issue:** Says ArgoCD is not set up for Acastus and the steps "will not currently work for the accelerator", contradicting `argocd-accelerator.md` (operational Hylas ArgoCD, live UI, working login + sync). The "Add Repositories to ArgoCD" section only describes the central (beamline) path.
- **Fix:** Remove the stale warning; add accelerator guidance (Hylas-hosted ArgoCD at `argocd-hylas.diamond.ac.uk`, primary network, auto-sync disabled during a run); cross-link `argocd-accelerator.md`.
- **Evidence:** `new-domain.md:13,85-91`; `argocd-accelerator.md:19,21,30-34,36-45`.

#### `docs/how-tos/new-domain.md` — "two default apps" omits gateways [minor, inconsistency]
- **Location:** line 93
- **Issue:** For beamlines (the page's main case), `gateway` defaults true, so apps/values.yaml emits a third app `ixx-epics-gateways`; the doc says only two.
- **Fix:** "...the default apps `ixx-epics-pvcs`, `ixx-epics-opis` and (for beamlines) `ixx-epics-gateways`..."; update/recaption the screenshot if needed.
- **Evidence:** `new-domain.md:93,91,11-13`; `deployment-template-argocd/template/apps/values.yaml.jinja:33-35`; `copier.yml:114-119`.

#### `docs/how-tos/webhooks.md` — 2 vs 3 minute poll interval [minor, inconsistency]
- **Location:** line 3 ("every 2 minutes")
- **Issue:** Contradicts `argocd.md:104` (3 minutes) and the deployment template README (3 minutes); ArgoCD default is 180s.
- **Fix:** Change to "every 3 minutes"; link to `argocd.md` to avoid future drift.
- **Evidence:** `webhooks.md:3`; `argocd.md:104,106`; `deployment-template-argocd/template/README.md.jinja:13`.

### Reference

#### `docs/reference/setup.md` — no EC_CLI_BACKEND / backend model [critical, missing-content]
- **Location:** whole page; "ec modules" lines 53-95
- **Issue:** Documents only the ArgoCD backend and never mentions `EC_CLI_BACKEND`. At DLS, services repos use K8S (e.g. i21: `EC_TARGET=i21-beamline`) and deployment repos use ARGOCD (e.g. t01: `EC_TARGET=hgv27681/t01`). The backend changes the command surface (K8S has attach/exec/template/deploy-local; ARGOCD drops them and keeps `--commit` on start/stop) and EC_TARGET format. setup.md's ArgoCD-login/error steps don't apply to K8S users.
- **Fix:** Add an "ec backends at DLS" subsection: `EC_CLI_BACKEND` selects behaviour; services repos use K8S, deployment repos ARGOCD; `EC_TARGET` is a namespace (K8S) vs `namespace/root-app` (ARGOCD); per-backend command/option differences; `ec --help` reflects the active backend. Cross-reference from workflow pages.
- **Evidence:** `setup.md:70,91`; `i21-services/environment.sh:16,18`; `t01-deployment/environment.sh:17,19`; `backend.py:58-66`; `k8s_commands.py:32-35,47,77,82,123`; `argo_commands.py:136-138,238,245`; `commands.py:115-164`; `__main__.py:29-30,116-129`.

#### `docs/reference/setup.md` — nonexistent docker-compose path [major, wrong-path]
- **Location:** line 43 (`export PATH=/dls_sw/apps/docker-compose/2.33.1/bin/:$PATH`)
- **Issue:** Version `2.33.1` is no longer installed (present: 2.40.3, 5.0.1, 5.1.1, 5.1.4). Prepending a nonexistent dir is a silent no-op; devcontainers can fail to start.
- **Fix:** Update to a present version, e.g. `/dls_sw/apps/docker-compose/5.1.4/bin/`. Ask DLS infra for a version-agnostic `latest` symlink (none exists today).
- **Evidence:** `setup.md:43`; `ls /dls_sw/apps/docker-compose/`.

#### `docs/reference/setup.md` — `ec ps` sample missing `label` column [minor, inconsistency]
- **Location:** lines 76-83 (and `tutorials/ec-cli.md:22-27`)
- **Issue:** Header `name | version | ready | deployed` omits the `label` column (schema is `{name, label, version, ready, deployed}`). Also stylistically stale (pipe table vs rich rounded-box table).
- **Fix:** Add the `label` column between name and version (default value `service`); optionally note the rich-table rendering. Regenerate both samples from a current ec build.
- **Evidence:** `setup.md:76-83`; `ec-cli.md:22-27`; `commands.py:22-30,173-189`; `k8s_commands.py:155-157,205`; `argo_commands.py:307-323`.

#### `docs/reference/glossary.md` — unfilled boilerplate template [critical/major, missing-content]
- **Location:** whole file (lines 1-56)
- **Issue:** Unmodified copier placeholder: only generic terms (API, Algorithm, Backend, Bug, CLI, Cloud Computing, Database, Deployment) + a "How to Use This Glossary" note. Defines none of the domain/DLS terms used across the guide (services repo, deployment repo, ec, ibek, Generic IOC, IOC instance, dev-c7/legacy IOC, redirector, BUILDER support module, ArgoCD root app, Argus/Pollux/Acastus/Hylas, `module load`, EC_SERVICES_REPO/EC_TARGET). Wired into the published nav (`mkdocs.yaml:39`).
- **Fix:** Replace the placeholder with real DLS/epics-containers entries (reuse the public definitions for shared terms; add DLS-specific jargon). Remove the generic entries and the "How to Use" note. Establish the public glossary as canonical for shared terms and either link to it or transclude.
- **Evidence:** `glossary.md:9-43,47-53`; `mkdocs.yaml:39`; `new-domain.md:15,17,18`; `dev-c7-ioc.md:1,11,33`; `ec-dls.md:79,120`; `argocd.md:25`; `argocd-accelerator.md:14,19,51`; `example-beamline.md:55`. (Reported once; see also the cross-cutting glossary finding in Part 3.)

#### `docs/reference/todo.md` — drifting TODO list [minor, missing-content]
- **Location:** lines 11-21
- **Issue:** Line 13 ("deploying a traditional IOC ... using dev-c7") is already covered by `dev-c7-ioc.md`. No item tracks the `ibek pattern` vendoring how-to. Line 10 (FastCS IOC deployment) is still undocumented. Line 12 (support-module conversion) is NOT covered (convert-ioc.md defers it), so it should stay.
- **Fix:** Remove line 13; keep line 12; add an "ibek pattern vendoring at DLS" how-to item; optionally cross-reference the FastCS "TBA" note (`ibek-legacy.md:86`).
- **Evidence:** `todo.md:10,12,13,20`; `dev-c7-ioc.md:1,33,88`; `convert-ioc.md:1,33`; `ibek-legacy.md:86`.

---

## Part 3 — Public/Internal consistency & completeness

### Terminology

#### "Services repository" named inconsistently (services repo / domain repo / beamline repo) [major, terminology]
- **Repo:** public
- **Issue:** The repo holding a domain's IOC-instance/service definitions is canonicalised as "services repository" (glossary anchor `(services-repo)=`) and used as the linked term in introduction.md/create_beamline.md/changelog.md/dev_container.md. But it is also called "domain repository/domain repo" (repositories.md:47,54; ioc_helm_chart.md:12,21; environment.md:17) and "beamline repo/repository" (changes.md:20,55,77; changelog.md:15; copier_update.md; k8s_resources.md:12; many tutorials). changelog.md:15 even equates "beamline repo (also known as services repo)". (Note: repositories.md uses "Services Repositories" and "domain repository", not literally "beamline repo".)
- **Fix:** Adopt "services repository" as canonical (matches the glossary anchor and the template names). Priority edits: repositories.md:47,54 ("domain repos"/"domain repository"→"services repository"); changes.md:20 table row "Beamline repo"→"Services repository" (and :55,:77); changelog.md:15 drop the parenthetical. Broader sweep across copier_update.md/k8s_resources.md/environment.md/ioc_helm_chart.md/tutorials recommended.
- **Evidence:** `glossary.md:4-5`; `repositories.md:19,38,44,47,54`; `changelog.md:15`; `changes.md:20`; template names in `changelog.md:19-20`, `copier_update.md:28`, `create_beamline.md:50`.

#### Inconsistent casing of "Generic IOC" / "IOC instance" [minor, terminology]
- **Repo:** public
- **Issue:** introduction.md:68 declares canonical terms "Generic IOC and IOC Instance", but casing is applied inconsistently (e.g. introduction.md:42 "Generic IOC image" vs :44 "generic IOC image"; :55 "IOC instance" vs :120 "IOC Instances"). Across docs: "Generic IOC" ~151 vs "generic IOC" ~39; "IOC Instance" ~57 vs "IOC instance" ~152. (Correction: repositories.md is consistently capitalised; the lowercase variants live in autosave.md/changes.md/copier_update.md.)
- **Fix:** Pick one casing per term, apply it across docs, and make introduction.md:68 state the chosen convention; document it in the glossary. At minimum reconcile the lines adjacent to :68 (the :42/:44 and :55/:120 mismatches).
- **Evidence:** `introduction.md:42,44,52,55,68,120,130`; grep counts; chart `name: ioc-instance`; ibek class `GenericIoc` (`entities.rst:36`).

### Duplication / divergence

#### Internal vs public glossary: stub with no shared terms [major→inconsistency / both]
- **Repo:** both (`topics/epics-containers/docs/reference/glossary.md` vs public `docs/reference/glossary.md`)
- **Issue:** The internal glossary is a never-populated template stub (generic CS terms only); the public glossary defines 3 framework terms. The two share no defined terms and different formats, so the internal doc set offers no project terminology and does not reuse/link the public glossary.
- **Fix:** Populate the internal glossary with real content. Make the public glossary the canonical source for shared framework terms (expand it). Internal then either links to the public glossary for shared terms and keeps only DLS-specific jargon, or transcludes public terms and adds DLS extensions. Remove the generic placeholder entries and the "How to Use" section in both stubs.
- **Evidence:** public `glossary.md:4-5,14-15,22-23`; internal `glossary.md:1,9-43,47-53`; `todo.md:3` ("first draft"); no cross-link in either direction.

### Missing pages / sections

#### Entire `ibek pattern` vendoring vocabulary absent from both doc trees [critical, missing-content / both]
- **Repo:** both
- **Issue:** A grep for `ibek pattern`, `runtime-lock`, `vendor`, `runtime support`, `runtime-support` returns zero hits in either tree. None of: pattern, pattern library, runtime support, vendoring, `runtime-lock.yaml`, per-instance `ioc.schema.json`, `DIRTY` lock entry, `ibek-runtime-streamdevice`/`ibek-runtime-support` is defined. The feature is shipped (ibek `pattern_cmds`, ADRs 0003/0004; services-template-helm v6.0.0 with pre-commit + ci_verify + Renovate). The only documentation is the services repo's own README. Note the per-instance `ioc.schema.json` is distinct from the long-documented build-time `ibek.ioc.schema.json`.
- **Fix:** Add glossary entries + at least one explanation page covering pattern, runtime support (vs build-time), `runtime-lock.yaml` (strict integrity, `DIRTY # <reason>` opt-out), per-instance `ioc.schema.json`, vendoring, and the `ibek pattern` commands. Explain it replaces the retired submodule+symlink approach (ADR 0004) and integrates with pre-commit/ci_verify/Renovate. Cross-link the services repo README rather than duplicating it.
- **Evidence:** public + internal `docs/` grep = 0; `ibek/.../pattern_cmds/commands.py:65-140`, `lock.py`, `vendor.py`, `globals.py:120`; ADRs 0003/0004; `services-template-helm/.../.pre-commit-config.yaml`, `ci_verify.sh`, `renovate.json`, `copier.yml` v6.0.0, `README.md.jinja:19-67`.

#### Public: new how-to page for `ibek pattern` vendoring [critical, missing-content]
- **Repo:** public, `docs/how-to/vendor-runtime-support.md` (NEW)
- **Issue:** No public how-to page documents the five subcommands, the `[library:]name[@version]` syntax, the `config/`-vendored file set vs instance-root `runtime-lock.yaml`/`ioc.schema.json`, the DO-NOT-EDIT headers, the strict per-branch sha256 check, the `DIRTY` opt-out, built-in libraries, or the `IBEK_PATTERN_LIBRARIES`/`IBEK_ALLOW_DIRTY`/`IBEK_SCHEMA_CACHE` env vars.
- **Fix:** Add `docs/how-to/vendor-runtime-support.md` (to the how-to TOC) documenting the syntax; the five commands from the repo root (e.g. `ibek pattern add ibek-runtime-streamdevice:lakeshore340@1.0.0 services/<instance>`); placement (`config/` is the ConfigMap payload; `runtime-lock.yaml`/`ioc.schema.json` at instance root); integrity policy + `DIRTY # <reason>`; built-in libraries + env vars; the DO-NOT-EDIT header; the Renovate flow (Renovate bumps the version string, maintainer runs `ibek pattern update`). Cross-link ADR 0004.
- **Evidence:** `docs/how-to/` listing (absent); `ibek/.../pattern_cmds/{commands,sources,lock,vendor,schema}.py`; ADR 0004; `services-template-helm` hooks/CI/renovate; `README.md.jinja:19-63`.

#### Public: new tutorial/reference page for the ArgoCD deployment model [critical, missing-content]
- **Repo:** public, `docs/tutorials/deploy_argocd.md` (NEW)
- **Issue:** No page covers the production CD path: deployment-repo layout (`apps.yaml` root Application + `apps/values.yaml` control surface), the app-of-apps indirection via the `argocd-apps` chart, the `deployment-template-argocd` copier template, the `EC_CLI_BACKEND=ARGOCD`/`EC_TARGET`/`EC_SERVICES_REPO` environment, and the `ec deploy` → git-commit → autosync flow. ArgoCD appears only in prose/WIP mentions.
- **Fix:** Add `docs/tutorials/deploy_argocd.md` (near setup_k8s_new_beamline / add_k8s_ioc): scaffold via `copier copy .../deployment-template-argocd`; explain `apps.yaml` (root App, source.path=apps, automated syncPolicy) and bootstrap (`argocd app create --file apps.yaml`); explain `apps/values.yaml` (project, destination, source pointing at the SERVICES repo, per-service `enabled/removed/targetRevision/labels`); the app-of-apps via `argocd-apps` OCI dependency; the environment.sh; and the deploy flow. Use t01-deployment as the worked example; complete/cross-link the WIP `helm.md`.
- **Evidence:** `find docs` (no ArgoCD deployment page); grep ZERO for "app of apps"/"apps.yaml"/"apps/values"; `t01-deployment/{apps.yaml,apps/values.yaml,apps/Chart.yaml,apps/templates/all_apps.yaml,environment.sh}`; `deployment-template-argocd/copier.yml`; `argo_commands.py:89-104,154-183`; `definitions.py:6-7,23`.

#### Public: new `ec` CLI reference page [major, missing-content]
- **Repo:** public, `docs/reference/ec_cli.md` (NEW)
- **Issue:** No page enumerates the `ec` command set or explains the backend-dependent command/option surface. The default backend is ARGOCD (no attach/exec/deploy-local/template; `deploy` lacks `--args`/`--wait`); K8S adds those commands but `start`/`stop` lack `--commit`; DEMO is in-memory. The `ec monitor` TUI and `textual serve "ec -b DEMO monitor"` demo are undocumented.
- **Fix:** Add `docs/reference/ec_cli.md` (auto-included via `reference/*`): global options + EC_* env equivalents; each command with syntax; the backend matrix; the `EC_TARGET` format difference; the `ec monitor` TUI and web demo. Note `--log-level`/`--log-url` are long-only, and the command set is enforced dynamically per backend.
- **Evidence:** `ls docs/reference/ec_cli.md` (absent); `cli.py:54-358`; `__main__.py:18,35-101`; `definitions.py:5-8`; `argo_commands.py:136-138`; `k8s_commands.py:32-35,47,77,82,123`; `backend.py:58-66`; `edge-containers-cli/README.md:30-38`.

#### Public: USB/DRA passthrough undocumented in ioc_helm_chart reference [minor, missing-content]
- **Repo:** public, `docs/reference/ioc_helm_chart.md` (NEW SECTION or sibling)
- **Issue:** The `ioc-instance` chart exposes two undocumented USB mechanisms: `usbDevices` (DRA, generates a ResourceClaimTemplate, requires K8s >=1.34 and `global.usbKey`, per-device selectors) and the DLS `usb-compat` NRI plugin (`runtimeClassName: usb-compat` / `podAnnotations: {usb-compat: enabled}`). Zero coverage in docs.
- **Fix:** Add a USB/hardware-passthrough subsection covering both mechanisms (as alternatives); reference the i21 Andor3 example (bl21i-ea-det-05, SDK-libs PVC, dataVolume.hostPath). Flag as advanced/site-specific.
- **Evidence:** `ioc_helm_chart.md:3-5,25-69`; `ec-helm-charts/Charts/ioc-instance/values.yaml:153,155`, `templates/_resourceclaimtemplate.tpl:7-9,22,26`, `ioc-instance.schema.json:283,310-335`; `i21-services/services/bl21i-ea-det-05/values.yaml`.

#### Public/internal: example beamline naming drift (p45 vs p47 vs t01) [minor, inconsistency / both]
- **Repo:** both
- **Issue:** public `repositories.md:51-56` says the DLS test/example beamline is `p45` (repos p45-services/p45-deployment), but `services_config.md:45` and `autosave.md:55-59` use `p47`, the tutorials use `t01`/`bl01t`, and the internal guide uses `p47` for training and `t01`/`bl01t` for the example. (Correction: `ec-dls.md` uses generic `ixx`/`ioc-*` naming and says public beamlines are "p45→p49", so it is consistent; `where.md` does NOT use p47.)
- **Fix:** Reconcile public `repositories.md:51-56` to the current canonical beamline (`p47`, or the `t01/bl01t` example), verifying the repos exist before linking. Minor: have `ec-dls.md` link to public `repositories.md` for the generic 3-repo/CI-CD model rather than duplicating it.
- **Evidence:** `repositories.md:53,54,56`; `services_config.md:45`; `autosave.md:55`; `create_beamline.md` (t01); internal `setup.md:69,74`, `example-beamline.md`; `ec-dls.md:67-127`.

#### Internal: git-workflow.md "Tagged Releases" lacks interim manual link [minor, missing-content]
- **Repo:** internal
- **Issue:** The "Tagged Releases" section flags the automated pipeline as "not yet set up" but describes only the future automated workflow, without pointing at the interim manual procedure (which exists in `release-ioc.md:88-101`, written in GitHub terms).
- **Fix:** Add a sentence linking to `release-ioc.md`'s deploy steps and note the GitLab equivalent (CalVer tag on main → GitLab Release → `ec deploy <ioc> <tag>`). Optionally add a reciprocal link.
- **Evidence:** `git-workflow.md:121-127,131`; `release-ioc.md:9,88-96,99-101`.

#### Internal: index.md broken "Setup a Kubernetes Cluster" link [major, broken-link]
- **Repo:** internal
- **Issue:** `index.md:11` links `.../tutorials/setup_kubernetes.html` (404). The public page is `tutorials/setup_k8s.html`. This is the "stop when you reach" onboarding marker, so the boundary is unreachable.
- **Fix:** Change the URL to `.../tutorials/setup_k8s.html` (link text is already correct).
- **Evidence:** internal `index.md:11`; public `setup_k8s.md:1,3`; built `setup_k8s.html`; no `setup_kubernetes.html`.

#### Internal: templates.md omits `.fastcs_ioc_template` / `.legacy_ioc_template` [major, wrong-path]
- **Repo:** internal
- **Issue:** Besides the `.ioc-template`→`.ioc_template` hyphen bug (Part 2), the page documents only one skeleton; the template ships three: `.ioc_template`, `.fastcs_ioc_template` (config/controller.yaml), `.legacy_ioc_template` (values.yaml only). Other internal docs already use the underscore forms.
- **Fix:** Fix the hyphen (lines 28/31) and add bullets for `.fastcs_ioc_template` and `.legacy_ioc_template`, verifying their config-file names.
- **Evidence:** internal `templates.md:28,31`; `ls services-template-helm/template/services/`; `new-ioc.md:25`, `dev-c7-ioc.md:21`, `example-beamline.md:225-226`.

#### Internal: new-ioc.md (topics path) — same vendoring gap [critical, missing-content]
- **Repo:** internal, `topics/epics-containers/docs/how-tos/new-ioc.md`
- **Issue:** Same gap as the developer-guide-root `new-ioc.md` (no vendoring section). A StreamDevice IOC has no documented path; engineers could hand-edit a DO-NOT-EDIT vendored file and break CI's sha256 check. The public create_ioc tutorial it cross-links does not cover vendoring either.
- **Fix:** Add a "Vendoring Runtime Support" section (commands, default libraries, DO-NOT-EDIT/sha256, `DIRTY`, one-off editable `*.ibek.support.yaml`). Cross-link the services-template-helm README as authoritative (do NOT rely on the public create_ioc tutorial).
- **Evidence:** `new-ioc.md:48-54`; grep 0 for `ibek pattern`/`runtime-lock`/`vendor` in internal docs; `README.md.jinja:19-67`; `.pre-commit-config.yaml:58-73`; `ci_verify.sh:67-81`; `pattern_cmds/commands.py:66-141`, `sources.py:23-27`; `create_ioc.md:117,214,327-332`.

---

## Appendix — New/rewritten pages suggested

New pages to create:

- [ ] **Public** `docs/how-to/vendor-runtime-support.md` — `ibek pattern` vendoring how-to (add/update/check/restore/schema, runtime-lock.yaml, DIRTY, libraries, env vars). [critical]
- [ ] **Public** `docs/tutorials/deploy_argocd.md` — ArgoCD deployment-repo tutorial (app-of-apps, apps.yaml, apps/values.yaml, ec deploy → autosync), worked with t01-deployment. [critical]
- [ ] **Public** `docs/reference/ec_cli.md` — `ec` command reference + backend matrix + TUI/web demo. [major]
- [ ] **Public** `docs/tutorials/add_k8s_ioc.md` — write the K8s IOC tutorial (currently a `TODO: WIP` stub). [major]

Pages requiring substantial rewrite:

- [ ] **Public** `docs/how-to/debug.md` — replace the removed podman `deploy-local` workflow with Kubernetes/Helm debugging. [critical]
- [ ] **Public** `docs/reference/environment.md` — rewrite env-var list against the current `ENV` enum; fix EC_LOG_URL placeholder + package name + dead links. [critical]
- [ ] **Public** `docs/how-to/ibek-support.md` — replace `build-startup`/`ioc.boot.yaml`, drop the false msi note, fix repo name. [critical]
- [x] **Public** `docs/reference/ioc_helm_chart.md` — DELETED for now (page was wholesale stale: blxxi-template 404, `base_image`/`prefix`/`helm/shared`). A fresh reference against ec-helm-charts/services-template-helm (image/global, .helm-shared, paths, other charts, ioc.schema.json, USB/DRA) can be written later. [major]
- [ ] **Public** `docs/reference/helm.md` — flesh out the K8S-backend deployment reference (replace WIP stub). [major]
- [ ] **Public** `docs/reference/k8s_resources.md` — StatefulSet (not Deployment); fix `ec template` example, paths, backend caveat. [major]
- [ ] **WON'T FIX (for now)** **Public** `docs/tutorials/rtems_ioc.md` + `rtems_setup.md` — refresh against current rtems-proxy env vars, nested `ioc-instance:` values, nfsv2-tftp chart source, and t01 beamline naming. [major] — deliberately deferred; leave the rtems pages untouched until the full rtems refresh is scheduled.
- [ ] **Public** `docs/reference/glossary.md` — add Generic IOC, IOC instance, domain, support module, ibek-defs/ibek-support, ConfigMap, ec backends, pattern vocabulary; fix the garbled ec entry. [major]
- [ ] **Internal** `topics/epics-containers/docs/reference/glossary.md` — replace the placeholder template with real DLS/epics-containers terms. [critical]
- [ ] **Internal** `topics/epics-containers/docs/reference/setup.md` — add the EC_CLI_BACKEND / ec-backend-at-DLS section; fix docker-compose path. [critical]
- [ ] **Internal** `topics/epics-containers/docs/how-tos/new-ioc.md` (both copies) — add runtime-support vendoring + deploy sections. [critical]
- [ ] **Internal** `topics/epics-containers/docs/explanations/templates.md` — fix `--trust`, `.ioc_template`, add skeletons/synoptic/gateway/rtems/git_platform. [major]
- [ ] **Internal** `topics/epics-containers/docs/explanations/argocd.md` + `argocd-accelerator.md` + `how-tos/new-domain.md` — reconcile the single-ArgoCD vs Hylas accelerator instance story. [major]
