# epics-containers Public Docs — Rewrite Plan

> Execution plan for a fresh context. All design decisions below are **locked**
> (resolved in a grilling session). Do **not** relitigate them — execute.
> Companion evidence: `DOCS-REVIEW.md` (96 findings) and the non-tutorial audit
> (31 pages, cross-checked vs live peer repos) summarised in the disposition
> table in §5.

## 1. Goal & quality bars

Rewrite the public documentation at `docs/` (published from this repo) so that:

1. **Tutorials are the product.** A consistent, current, *snappy* set covering
   every topic the current tutorials cover **except RTEMS** (dropped entirely).
2. **`tutorials/deploy_argocd.md` is the style standard** — clarity, an explicit
   "here is what happened and what did **not**", DLS notes in admonitions,
   `{any}`/`{ref}` cross-refs. Match its *style*, not its length.
3. **SNAPPINESS IS A PRIMARY BAR.** Long pages are intimidating. Cut hard. The
   current set is bloated (`generic_ioc` 677 lines, `create_ioc` 454). Keep the
   existing *granular page splits* (`dev_container`/`dev_container2`,
   `ioc_changes1`/`2`) — many short pages beat a few long ones — and trim the
   content within each. Trim the ArgoCD page itself.
4. **Non-tutorials: earns-its-place bar.** A non-tutorial page survives only if
   (a) a tutorial cross-references it as required background, or (b) it is true
   return-to reference (env vars, CLI, glossary, troubleshooting). Aggressive,
   principled cull — drop even accurate pages that nobody needs.
5. **Grounded in current reality.** Every command, flag, path, value-key and
   filename must be verified against the live peer repos under `/workspaces/`
   (the current state of the framework), **not** memory or the old prose.

## 2. Ground truth — peer repos (all under `/workspaces/`)

| Concern | Repo | Notes |
|---|---|---|
| `ibek` CLI | `ibek` | groups: `support`, `runtime` (`generate`/`generate2`/`generate-autosave`), `ioc`, `dev`, `pattern`. **`build-startup` is gone.** |
| `ec` CLI | `edge-containers-cli` | backends `ARGOCD` (default) / `K8S` / `DEMO`; `EC_*` vars in `src/edge_containers_cli/definitions.py`. Its own docs publish at `https://epics-containers.github.io/edge-containers-cli/`. |
| Generic IOC template | `ioc-template` | copier; `template/` prefix; `.devcontainer`, `Dockerfile`, `ioc/start.sh` (`ibek runtime generate2`). |
| Services repo template | `services-template-helm` | copier; `.helm-shared/`, `template/services/.ioc_template`, `_migrations` (need `--trust`). |
| Helm charts | `ec-helm-charts` | `ioc-instance` (StatefulSet; `image` under `ioc-instance:`; `hostNetwork:true` default), `argocd-apps`, `epics-pvcs`, `epics-opis`, `carepeater`. OCI: `oci://ghcr.io/epics-containers/charts`. |
| ArgoCD deployment template | `deployment-template-argocd` | `apps.yaml`, `apps/values.yaml` control surface. |
| Canonical public example | `t01-services`, `t01-deployment`, `example-services` | `t01` / `bl01t` / namespace `t01-beamline`. **`example-services` is now a compose repo**; `t01-services` is Helm. |
| Conversion / legacy | `builder2ibek` | own docs at `https://epics-containers.github.io/builder2ibek`. |

**Canonical worked example everywhere:** domain `t01`, beamline `bl01t`,
namespace `t01-beamline`, services repo `t01-services`. Substitute-your-own
framing as in `deploy_argocd.md`.

## 3. DLS handling model (locked)

The compose/workstation track is **shared** between public and DLS users. DLS
users follow the *public* tutorials on their own workstations up to **but not
including** cluster deployment, then switch to the internal developer-guide.

- **Inline `:::{note} DLS users:` callouts** for genuinely useful workstation
  specifics, e.g. `module load vscode; code .`, `setup podman with
  /dls_sw/apps/setup-podman/setup.sh`, and any DLS workstation setup in
  `setup_workstation.md`. Refresh `compose-quickstart`'s stale
  `/dls_sw/apps/docker-compose/5.1.4` path to the `setup-podman` approach.
- **Cluster boundary warning:** at the **top of `setup_k8s.md`**, a prominent
  admonition telling DLS users to switch to the internal developer-guide; a
  **brief repeated banner** at the top of every subsequent cluster page
  (`setup_k8s_new_beamline`, `add_k8s_ioc`, `deploy_argocd`).
- **Strip deep DLS internals** from public docs — they already have homes in the
  developer-guide (`../developer-guide/topics/epics-containers/`, published
  `https://dev-guide.diamond.ac.uk/epics-containers/`): asset locations →
  `reference/where.md`; DLS XMLBuilder conversion → `how-tos/convert-ioc.md`;
  Argus cluster → `explanations/argocd-accelerator.md` + `ec-dls.md`; DLS
  setup/tunnelling/webhooks → `reference/setup.md`, `tunneling.md`,
  `how-tos/webhooks.md`. DLS-notes may link these.
- **Verify DLS callouts page-by-page during the rewrite** and flag gaps; do not
  invent. Maintainer's read: they are mostly already present.

## 4. Tutorials — keep set & order, drop RTEMS, trim hard

Keep the existing toctree order. **Remove** `rtems_setup` + `rtems_ioc`.
**Write** the `add_k8s_ioc` stub. Per page: rewrite snappy + current + grounded.

| Tutorial | Lines now | Ground against | Action |
|---|---|---|---|
| `intro` | 30 | introduction concepts | light refresh |
| `setup_workstation` | 301 | `ioc-template/.devcontainer`, setup-podman, DLS specifics | trim; DLS workstation notes |
| `launch_example` | 84 | `example-services` compose; **CA port 9064** (fix `5094`) | trim; fix port |
| `create_beamline` | 126 | confirm compose vs `services-template-helm` path **at exec time** | trim; verify track |
| `deploy_example` | 194 | `ec` DEMO backend, `example-services` | trim |
| `create_ioc` | 454 | `ioc.yaml`, `ibek`, `ioc-instance` chart | **trim hard** |
| `dev_container` | 335 | `ioc-template/.devcontainer`; keep `(container-layout)` anchor | trim; keep split |
| `dev_container2` | 112 | same | trim; keep split |
| `ioc_changes1` | 146 | `ibek runtime generate2`; keep `(ioc-change-types)` anchor | trim; keep split |
| `ioc_changes2` | 215 | OPI/phoebus-launch | trim; keep split |
| `generic_ioc` | 677 | `ioc-template`, `ibek-support` submodule | **trim hardest**; split only if still long |
| `debug_generic_ioc` | 158 | `ibek runtime generate` | trim |
| `support_module` | 23 | `ibek-support` | finish/refresh (currently draft) |
| `setup_k8s` | 265 | ArgoCD install, `argocd` CLI | trim; **DLS cluster-boundary warning at top** |
| `setup_k8s_new_beamline` | 303 | `services-template-helm` | trim; DLS banner |
| `add_k8s_ioc` | 9 (STUB) | `t01-services`, `ibek pattern`, `ec deploy` | **write**; DLS banner |
| `deploy_argocd` | 413 | `deployment-template-argocd`, `ec` ARGOCD | trim the standard itself; DLS banner |

Per-page length guidance: aim for the shortest page that is still complete.
Move deep "why" into the linked explanation rather than inlining it.

## 5. Non-tutorial disposition (31 → ~18 pages)

### DROP (11) — delete file + repoint inbound links

| Page | Reason | Link fix |
|---|---|---|
| `how-to/builder2ibek.support.md` | tool doesn't exist; WIP; DLS-only | repoint `generic_ioc` link → builder2ibek docs / dev-guide `convert-ioc` |
| `how-to/builder2ibek.md` | perpetual stub; duplicates builder2ibek docs | repoint `generic_ioc:611` → builder2ibek docs |
| `how-to/contribute.md` | boilerplate `{include}`; GitHub surfaces it; broken links | none |
| `how-to/phoebus.md` | 9-line stub, no steps; duplicated | none |
| `explanations/docs-structure.md` | Diátaxis boilerplate; dup of `index.md` | none |
| `explanations/repositories.md` | p45 404; DLS-internal; dup of `introduction.md` | DLS → dev-guide `where.md` |
| `reference/k8s_resources.md` | wrong (StatefulSet); `helm-ioc-lib` gone; stub | none (`helm.md` covers `ec template`) |
| `reference/services_config.md` | never-finished WIP; dup; heavy DLS | DLS → dev-guide |
| `reference/ioc_helm_chart.md` | built on deleted `blxxi-template` | none |
| `reference/changelog.md` | 22 mo stale; dead compose template; RTEMS | repoint `changes.md:11` + `copier_update.md:23` → GitHub Releases (already linked in `reference.md`) |
| `reference/configuration.md` | half-finished stub; only unique = 3 VSCode lines | **salvage 3 VSCode lines → `troubleshooting.md`** |

### MERGE (2) — consolidate the network story 3 → 1

Fold into **`explanations/epics_protocols.md`** (the surviving general/networking page):
- `explanations/net_protocols.md` → move CA-forwarder failed-workaround study + `caforwarder.png`/`cabackwarder.png`; then delete. Fix the `{any}`argus`` ref it carries.
- `explanations/kubernetes_cluster.md` → salvage **only** the genericized hostNetwork + capability-drop + beamline-node-taint pattern; Argus tour → DLS-note → dev-guide; then delete. (Stale facts to not carry: PSP removed in k8s 1.25, MetalLB multi-pool shipped, Weave EOL.)

After merge, **remove the now-dangling `(argus)=` references**.

### KEEP-WITH-EDITS / KEEP (18 survivors)

| Page | Edit (effort) |
|---|---|
| `how-to/own_tools.md` | fix line-22 personalization para; dedupe vs `dev_container` (trivial) |
| `how-to/compose-quickstart.md` | DLS-note the `setup-podman` path; consolidate podman-socket/`DOCKER_HOST` steps here (canonical); replace Mac gist (moderate) |
| `how-to/copier_update.md` | add `--trust` to beamline `copier update`; fix `3.4.0`→`4.0.3b3`; add "re-run `ibek pattern add` per instance after major update" (moderate) |
| `how-to/ibek-support.md` | DLS-note `module load uv` (trivial) |
| `explanations/autosave.md` | fix filename `autosave_positions.req`; fix stale startup snippet (add `set_requestfile_path`, drop `access.acf`); BL45P/BL47P; stray `z` (moderate) |
| `explanations/decisions.md` | keep as-is (ADR index) |
| `explanations/ioc-source.md` | fix `(container-layout)` xref into rewritten `dev_container` (trivial) |
| `explanations/changes.md` | `edge-services-cli`→`edge-containers-cli`; bump versions; `beamline repo`→`services repository`; trim copier dup → pointer (moderate) |
| `explanations/epics_protocols.md` | **absorb network merge**; fix line-17 link text; bump demo image tag to current; DLS-note line 11 (moderate) |
| `explanations/introduction.md` | **delete RTEMS/MVME5500 clause (line 216)**; fix `adaravis` anchor/old tag (line 42); soften aspirational arm64/CI lines (moderate) |
| `explanations/rootless.md` | genericize DLS line 11 (trivial) |
| `explanations/argocd.md` | re-point the 5 tutorial xrefs after tutorial rewrite (trivial) |
| `reference/faq.md` | rewrite Q2 rollback → GitOps `git revert`; fix "ReplicaSets"; Harbor DLS-note; drop dead `(no-opi)` (moderate) |
| `reference/glossary.md` | genericize DLS line 7; **preserve `(services-repo)`/`(edge-containers-cli)`/`(ibek)` anchors**; optional `ibek pattern` mention (trivial) |
| `reference/docker.md` | keep as-is (optional version bump) |
| `reference/troubleshooting.md` | fix port typo `5064 5064`→`5064 5065`; dedupe socket block → xref `compose-quickstart`; **absorb `configuration.md` VSCode lines** (trivial) |
| `reference/environment.md` | fix closing note (`example-services`→`t01-services`); optionally trim `EC_*` catalogue to link `edge-containers-cli` env-vars (moderate) |
| `reference/helm.md` | rename **"The ec Backend Model"**; genericize DLS line 30; cross-link `{any}`argocd``; **link out to `edge-containers-cli` `cli.md`** for the command list (trivial) |

### `ec` reference: link out, don't write
No new `ec` command reference page. From `helm.md`, `environment.md`,
`glossary.md` and the relevant tutorials, link to
`https://epics-containers.github.io/edge-containers-cli/` (its `reference/cli`
and `reference/environment-variables`). They maintain it.

## 6. Cross-reference safety (build is `--fail-on-warning`)

**Load-bearing anchors — must be preserved** (referenced from ≥2 pages):
`services-repo` (6), `using-docker` (5), `ioc-change-types` (5), `generic_ioc`
(4), `installation-steps` (3), `appliance` (3), `setup-kubernetes` (3),
`../explanations/argocd` (3), `setup-k8s-beamline` (2), `rootless` (2),
`multiple-iocs` (2), `helm` (2), `edge-containers-cli` (2), `deploy_example` (2),
`deploy-example-instance` (2), `deploy-argocd` (2), `create-beamline` (2),
`copier` (2), `../reference/environment` (2).

**Refs that WILL dangle after deletions — fix the referencing page:**
- `{any}`argus`` → kubernetes_cluster.md deleted (merge).
- `{any}`rtems_setup`` → RTEMS dropped.
- `{any}`../reference/services_config`` → services_config dropped.
- dead-but-harmless (referenced nowhere): `(scm_settings)`, `(no-opi)`.

Rule for every writing agent: **preserve all existing `(label)=` anchors that
other pages reference; only remove an anchor if its page is being deleted and
all referencing pages are fixed in the same phase.**

## 7. Workflow design (run in a fresh context)

Author a `Workflow()` script with these phases. Files are disjoint per agent →
parallel edits are safe **without** worktree isolation; commits are serialized
by the orchestrator at phase barriers. Provide every writing agent a shared
**brief** (this plan's §2/§3/§6 + the canonical names + anchor map + length
targets).

- **Phase 0 — Prune (1 agent, or inline + 1 commit).** Delete the 11 dropped
  files + `rtems_setup.md`/`rtems_ioc.md`; remove the two rtems lines from
  `docs/tutorials.md`; salvage `configuration.md` VSCode lines into
  `troubleshooting.md`; repoint the inbound links in §5. Build must still pass.
- **Phase 1 — Tutorials (pipeline, one item per tutorial in §4).**
  - stage A: rewrite — snappy, current, grounded, DLS notes, cluster banners.
  - stage B: critic — verify every command/flag/path against the named repo,
    enforce snappiness (flag any section that could be cut), check anchors
    preserved + no new dangling xref. Return issues; orchestrator applies fixes.
- **Phase 2 — Non-tutorial edits (pipeline, one item per survivor in §5).**
  Same A/B shape, edits per the table.
- **Phase 3 — Structural (parallel, few agents).** Network consolidation 3→1
  (one agent, owns `epics_protocols.md` + deletes the two merged files);
  `helm.md` rename+thin+link-out; `environment.md` trim+link-out. (Some overlap
  with Phase 2 — assign each file to exactly one phase to avoid double-edits.)
- **Phase 4 — Build & verify (serial).** Loop `uv run --no-sync sphinx-build
  --fail-on-warning docs <build>` → fix warnings until clean. Then **execute the
  compose/local tutorials** (`launch_example`, `deploy_example`) commands in this
  environment to validate; mark every k8s/ArgoCD worked-example output as
  "constructed from source — validate on a cluster". Run a completeness critic
  ("what's stale, unverified, or intimidating?").
- **Phase 5 — Assemble.** Structured phase commits on one branch; open a single
  PR (see §8). Then `pr-review-sweep` if a bot review lands.

Schemas: give stages B and the critic a structured schema
(`{file, issues[], commands_verified[], dangling_refs[], too_long: bool,
suggested_cuts[]}`) so results are machine-usable.

## 8. Delivery & verification (locked)

- **One branch, one PR.** Branch off `main` (e.g. `docs-rewrite`). Structured
  phase commits (prune → tutorials → non-tutorials → structural → fixes). Build
  clean at every commit.
- **Verification bar:** build clean `--fail-on-warning`; every command/path
  verified vs local source; compose/local tutorials executed here; cluster
  outputs flagged for the maintainer's cluster validation.
- **Git/GitHub:** HTTPS + `gh` credential helper only; never SSH; never put a
  PAT in a URL. End commit messages with the Co-Authored-By trailer.

## 9. Open items to confirm at execution time (don't block the plan)

- `create_beamline`: confirm whether it is the compose or Helm services-repo
  path in current `services-template-helm`; the compose track is first-class.
- `support_module.md`: currently a draft — confirm the intended scope before
  finishing.
- `configuration.md` drop (vs keep-with-edits) — maintainer leaning drop;
  reversible.
