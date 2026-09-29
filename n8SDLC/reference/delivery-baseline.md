# Delivery baseline

On a project that already builds, tests and deploys, M0 (infrastructure) and the CI milestone would mostly rebuild what exists. The baseline checks the project's existing delivery against the items those milestones would deliver, and records which are **established** (configured *and* demonstrated working). The roadmap then drops M0 and CI, or shrinks them to just the gaps.

`/n8-map` runs it on brownfield projects. `/n8-roadmap` runs it itself when no baseline exists but the repo shows delivery (`.github/workflows/` has files, or there's IaC or a deploy config).

## The items

Build the list from what the repo has, plus what n8SDLC expects of every project. This list is also the grain of `/n8-plan`'s *config-derived surface*, so two runs must produce the same one:

1. **One per `trigger → environment`**: each workflow trigger that puts a deployable somewhere, e.g. `push main → production` or `push tag v* → production (GitHub release)`.
2. **One per environment no trigger reaches**: an environment the project names (GitHub environments, IaC, deploy docs) that nothing deploys to.
3. **The merge gate**: what stops a red PR from merging.
4. **One environment gate per stage or production environment**: who or what may deploy there (approval, a protected branch, or a protected tag), plus a rollback path you can point to. Both halves are part of the one item.
5. **Day-one entries**: one per step in the chain under the `## CI` heading of `reference/stacks/<stack>.md` (the `stack:` in `.n8/config.yml`) that applies to the project. Never count setup or `install` (e.g. e2e only when the app has a UI). Plus two settings items for every project: **secret scanning** and **dependency updates**. Don't add entries from `## Tests / quality` that the CI chain doesn't name; a tool the chain doesn't run isn't a day-one entry.
6. **Invariant guards** are **not classified by `/n8-map`**. Invariants are declared at roadmap time. Record the guards you can see (a test or build setting that names an invariant) under `baseline.observed-guards:`. `/n8-roadmap` classifies them once the invariants are confirmed.

An environment n8SDLC expects but the project doesn't have (usually stage) is not a gap by default. Ask about it as a "not wanted?" question.

## Evidence: configured is not established

A workflow file shows intent, not that the workflow works. Each item needs the evidence below, run fresh. `R=$(gh repo view --json nameWithOwner --jq .nameWithOwner)` and `B=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)`. The last merged PR is `gh pr list --state merged --limit 20 --json number,mergedAt --jq 'max_by(.mergedAt).number'`; the list's default order is creation, not merge. "Latest run" means the most recent run of any conclusion, never the most recent success: a string of red runs after an old green is not established.

| Item | Configured | Demonstrated |
|---|---|---|
| `trigger → environment`, branch push | a workflow with `on: push: branches:` that deploys to that environment (an `environment:` key, or a deploy step naming it) | `gh run list --workflow <file> --branch $B --event push --limit 1 --json conclusion,createdAt,databaseId` → `success`. If the project uses GitHub deployments, also check `gh api "repos/$R/deployments?environment=<env>&per_page=1"` → its first status `state` is `success`. |
| `trigger → environment`, tag push | a workflow with `on: push: tags:` | `gh run list --workflow <file> --event push --limit 1 --json conclusion,createdAt,databaseId,headBranch`, **without `--branch`**: a tag run's `headBranch` is the tag name. Check that `headBranch` matches the tag pattern and the conclusion is `success`. For GitHub releases, also check that `gh release list --limit 1` shows that tag. |
| merge gate | `gh api repos/$R/rules/branches/$B` shows `pull_request` plus `required_status_checks` (only if that shows nothing, try legacy branch protection: `gh api repos/$R/branches/$B/protection`, where a 404 means none) | the most recently merged PR ran every required check and each passed: `gh pr list --state merged --limit 1 --json number` → `gh pr checks <n> --json name,bucket` |
| environment gate, branch-deployed | `gh api repos/$R/environments --jq '.environments[] \| {name, rules: [.protection_rules[].type]}'` shows reviewers, a wait timer, or a branch policy for that environment | configured is enough, because a gate is a setting, not a run. Rollback: a documented or scripted path you can point to, or the item is a gap. Look in README, CONTRIBUTING, `docs/`, the wiki, and `scripts/`: `grep -rniE 'rollback|roll back|revert|yank' --exclude-dir=.git --exclude-dir=node_modules .` |
| environment gate, tag-deployed | the environment's rules as above, **or** a tag ruleset restricting who may create matching tags: `gh api "repos/$R/rulesets?targets=tag"`, then `gh api repos/$R/rulesets/<id>` to read its conditions and bypass list | as above: configured, plus a rollback path |
| day-one entry (CI step) | a step in a CI workflow runs it. Match on the tool (`tsc --noEmit`, `eslint`, `vitest`), not the stack file's exact command line. | the check that runs the step passed where it runs: on the **most recently merged PR** (`gh pr checks <n>`) if the workflow triggers on `pull_request`, otherwise on the workflow's latest `$B` run. A workflow that runs only on PRs has no `$B` runs, and that's normal. A step that runs **only** in a tag or release workflow isn't a day-one entry the merge gate enforces: it's a gap ("<step> not in the PR gate"), whatever its release runs show. |
| secret scanning | `gh api repos/$R --jq .security_and_analysis` shows `secret_scanning` enabled (push protection too, on public repos) | configured is enough |
| dependency updates | Dependabot security updates enabled (same call), plus `.github/dependabot.yml` covering the package ecosystem and `github-actions` | configured is enough. Report the open Dependabot PR count and the oldest one's age in the confirmation (`gh pr list --author app/dependabot --state open --json number,createdAt`). `/n8-stat` and `/n8-audit` own the backlog; the baseline doesn't. |

Classify each item:

- **established**: configured and demonstrated. The evidence line records the command and its result.
- **gap**: missing, or configured but not demonstrated (latest run red, never run, or a deploy with no success). "Present but unproven" is honest, and it's still a gap: its story is to prove the item or fix it.
- **not wanted**: the user says the project deliberately lacks it (no stage environment, no formatter). Record it with the user's words, quoted, just as `DESCOPED:` does.

A gap entry can name more than one missing part of one item, e.g. "environment gate: production — no tag ruleset; no rollback path". It's still one item, and it becomes one story.

If the evidence run is older than 90 days, the item is still **established**, but show its age in the confirmation, because the user may know it has rotted.

While you're in the workflows, run the checks in `reference/github.md` → *GitHub Actions lessons* (unpinned `uses:`, floating downloads, and missing `permissions:`, which `grep -L '^permissions:' .github/workflows/*.y*ml` lists). Violations there are **concerns**, not gaps. They go through `/n8-map`'s concerns flow (or `/n8-file` when `/n8-roadmap` runs the baseline), at `sev:low`, or at `sev:medium` in a deploy path.

## Confirm, then record

Show the user one list: established items with their evidence, the gaps, and a "does this project deliberately not have these?" question for each gap that might be intentional. Their answer settles **not wanted** and can correct a classification. Then write the result to `.n8/config.yml`, using the `deployment:` and `ci:` shape in `reference/state.md`:

```yaml
deployment:
  targets: GitHub releases                 # the platform(s)
  environments:
    production: GitHub release per v* tag
  notes: tag-triggered release, artifacts attached
ci:
  provider: github-actions
  on_pr: [typecheck, lint, test]
  triggers:                                # one row per trigger → environment item
    - "push tag v* → production"
baseline:
  checked: 2026-09-29 @ 1a2b3c4            # date and the SHA of origin's default branch, not a local commit
  established:
    - "push tag v* → production: release.yml latest tag run success 2026-08-27 (run 331…, v0.1.0)"
    - "merge gate: ruleset requires ci; PR #21 ran it green"
  gaps:
    - "environment gate: production — no tag ruleset, no rollback path"
  not-wanted:
    - "stage environment — \"local CLI; releases go straight from a tag\""
  observed-guards:
    - "test/invariants.test.ts — zero runtime dependencies"
```

`deployment:` and `ci:` describe what the project **has**, so `/n8-roadmap` confirms them instead of asking again. `baseline:` is how established items stay out of M0, and it's a claim that `/n8-verify` re-checks.
