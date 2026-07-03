# Docs review — restart notes

Scratch/handoff notes for resuming the epics-containers documentation review
after time away. Not part of the published docs. Two independent workstreams.

---

## 1. Public docs rewrite — PR #243 (nearly done)

- Branch `docs-rewrite` on this repo (`epics-containers.github.io`), **PR #243**,
  marked **ready for review**. The full rewrite + a live per-page walkthrough of
  the **compose (t01)** track and the author track are done and pushed.
- The PR body carries an honest caveat: the **k8s / ArgoCD (t02)** track was
  statically grounded against the peer repos but **not executed on a cluster**.

**To finish:**
1. Check **CodeRabbit** has reviewed PR #243.
2. Address its comments (the `/pr-review-sweep` skill fans out + fixes one commit
   per finding, replies + resolves each thread).
3. **Merge.**
4. Optional follow-up: recapture the two `generic_ioc` release screenshots
   (`docs/images/simDetActions.png`, `simDetRelease.png`) — they still show the
   old repo name `ioc-adsimdetector`, since the tutorial repo was renamed to
   `ioc-adsim-demo`. Non-blocking.

---

## 2. Internal DLS developer-guide review — NOT STARTED

- **Repo:** `/workspaces/developer-guide` (Diamond GitLab:
  `gitlab.diamond.ac.uk/sscc-docs/developer-guide`). Our topic:
  `topics/epics-containers/`. Separate mkdocs-material site (techdocs-diamond
  plugin, GitLab-flow / MRs). **Not** the Sphinx public site.
- **Build/preview:** `mkdocs serve` from the developer-guide repo root (per its
  README). For just our topic, try `cd topics/epics-containers && mkdocs serve`
  (confirm).
- **Findings source of truth:** [`DOCS-REVIEW.md`](./DOCS-REVIEW.md) in *this*
  repo — 821-line static review of both doc sets. Internal findings are in
  **Part 2 (~L493-706)** + the internal items in **Part 3 (~L771-793)** +
  Appendix (~L816-821). Each finding has Location / Issue / Fix / Evidence.

**First thing:** branch `ec-git-workflow` has a committed-but-WIP addition to
`docs/explanations/git-workflow.md` — the "Shared Files That Affect Every IOC"
caution (commit `d087154`, pushed). **It still needs a maintainer review pass
before it is final.**

**Then** work the internal findings page-by-page (edit → `mkdocs` build clean →
one commit per page → MR), in priority order:

- **Critical:** `explanations/templates.md` (`--trust`, `.ioc-template` →
  `.ioc_template`) · `tutorials/delete-beamline.md` (service names →
  `t01-epics-*`) · `how-tos/new-ioc.md` (add `ibek pattern` vendoring section) ·
  `reference/setup.md` (add `EC_CLI_BACKEND` / backend-at-DLS; fix docker-compose
  path `2.33.1` → a present version) · `reference/glossary.md` (replace the
  unfilled copier boilerplate with real DLS terms).
- **Major:** reconcile the single-ArgoCD-on-Argus vs accelerator's-own-Hylas-ArgoCD
  story across `explanations/argocd.md` + `argocd-accelerator.md` +
  `how-tos/new-domain.md` · `tutorials/example-beamline.md` (`ixx-epics-*` →
  `t01-epics-*`, use `module load ec/user`, camera tag → `2.11ec1`) ·
  `tutorials/phoebus.md` (service names + stale gateway chart) ·
  `how-tos/update-templates.md` (`./ci_verify` → `./ci_verify.sh`) · `index.md`
  (`setup_kubernetes.html` → `setup_k8s.html`) · `templates.md` (add
  `.fastcs_ioc_template` / `.legacy_ioc_template`).
- **Minor/nit:** ec-dls submodule overstatement · `todo.md` drift · release-ioc
  `ec-helm-templates` → `ec-helm-charts` · ec-cli stale label selector ·
  convert-ioc `dbdiff` → `db-compare` · webhooks 2 → 3 min · argocd `selfHeal` ·
  git-workflow interim release link. (Exact lines in `DOCS-REVIEW.md`.)

**Cross-cutting (both trees):** the `ibek pattern` vendoring vocabulary is absent
from both doc sets; the internal glossary stub shares no terms with the public
one — make the public glossary canonical and link/transclude.

---

## Restarting with Claude Code

- Launch from **this** directory so the agent's memory auto-loads:
  `cd /workspaces/epics-containers.github.io && claude`, then say
  *"resume the internal docs review"*.
- Memory store (this machine/user only):
  `/root/.claude/projects/-workspaces-epics-containers-github-io/memory/` —
  key file `internal-docs-review.md`.
- On a **different machine/container** the memory won't be present — this file
  and `DOCS-REVIEW.md` (both committed here) are the durable handoff; point the
  agent at them.
