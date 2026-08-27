---
name: n8-init
description: Initialize a project for the n8SDLC workflow — the first command run in any new project. Inspects the folder for an existing shell project (offering to create one for .NET, TypeScript/Node, Python, Unity, or Flutter), creates the local git repo, wires the user-supplied GitHub remote, sets up baseline issue labels and templates, checks/seeds the wiki, enables GitHub security features on public repos, and recommends the context7 MCP. Use whenever the user says "n8-init", "initialize this project", "set up the SDLC", or starts the n8SDLC process in a fresh folder.
---

# /n8-init — Project Initialization

Set up everything the rest of the n8SDLC workflow depends on. Every step is idempotent — re-running init on a partially initialized project fills gaps and skips what's done, so check before creating throughout.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` (labels, templates, conventions) and `${CLAUDE_PLUGIN_ROOT}/reference/state.md` (.n8/ layout) before starting.

## 1. Preflight

- `gh auth status` — if not authenticated, stop and tell the user to run `gh auth login`. Nothing downstream works without it.
- `gh --version` — warn (don't block) below 2.94.0: sub-issue (`--parent`) and dependency (`--add-blocked-by`) flags need it; everything else works, hierarchy degrades to body conventions.
- If `.n8/config.yml` already exists, report what's already initialized and only perform missing steps.

## 2. Shell project

Inspect the folder for an existing project using the detection markers in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/*.md` (.NET, TypeScript, Python, Unity, Flutter).

- **Found:** confirm the detected stack with the user and record it. If it's a substantial existing codebase (not a fresh scaffold), recommend running `/n8-map` before `/n8-roadmap` so planning happens against a real map of what's there.
- **Not found:** ask what should be created — offer the five first-class stacks plus "something else". For a first-class stack, follow its reference file's Scaffold section. For anything else, ask enough questions (language, project shape, test framework) to scaffold sensibly with that ecosystem's standard generator.

Either way, wire the stack's **analyzers/linters into the build** from day one (the stack file's Tests/quality section names them) — build-time analysis is the always-on layer the audits lean on. Where rules get tuned down, the suppression config carries a one-line rationale per rule; audits treat unexplained suppressions as findings.

## 3. Git repo and remote

- `git init -b main` if not already a repo.
- If no `origin` remote: ask the user to supply a GitHub remote URL (they create the repo on GitHub themselves — don't create it for them). Add it, then verify access with `gh repo view`.
- Don't push yet; the initial push happens at the end.

## 3b. Existing-conventions scan (before mutating anything)

A project may already have a homegrown workflow — its own skills, commands, CLAUDE.md conventions, label taxonomy. Dropping n8SDLC on top without reconciling produces the worst of both: CLAUDE.md is always in context while skills load on invocation, so contradictory conventions don't lose to the plugin — they blend with it unpredictably. Scan before creating anything:

- `.claude/skills/`, `.claude/commands/`, `.claude/agents/`, hooks in settings — anything whose domain overlaps what n8SDLC owns (issue workflow, branching/PRs, planning, audits, releases, wiki).
- CLAUDE.md sections prescribing process in those domains.
- Existing labels (`gh label list`) vs. the n8SDLC set; existing milestones; existing `.github/ISSUE_TEMPLATE/`; other plugins' state directories (`.planning/` etc.).
- Project auto-memory entries that prescribe workflow.

Classify each overlapping item and present the list:

- **Complementary** — project-specific capability skills (a plugin-creator, a domain recipe, a deploy runbook): **keep**. These are exactly what `/n8-skill` produces; n8SDLC is their host, not their replacement.
- **Conflicting** — prescribes contradictory process in a domain n8SDLC now owns (its own issue/branch/close workflow, its own audit filing, its own planning loop).
- **Redundant** — fully covered by an n8SDLC skill with no contradiction.

Then resolve item by item with the user — never silently:

1. **Harvest before removing.** Homegrown skills usually encode hard-won project knowledge (tuned audit checklists, hot-path inventories, gotcha lists). Mine anything load-bearing into `.n8/memory/`, the wiki, or a kept project skill *before* deletion — deleting unharvested knowledge is the real cost of cleanup, not the files.
2. **Remove only what the user approves, via git** (`git rm` + commit) so every removal is one revert away. Offer sensible defaults (remove conflicting, keep complementary), but the user decides per item.
3. **Edit CLAUDE.md surgically:** replace the conflicting workflow sections with the n8SDLC section from step 8b; leave everything else (stack notes, invariants, domain guidance) untouched.
4. Flag stale workflow memories and offer to update them.

Touch nothing outside n8SDLC's domains — a project's unrelated skills, hooks, and docs are not yours to tidy.

## 4. Labels and issue templates

- Create the baseline label set from `reference/github.md` using `--force` (idempotent) — **but diff first on a repo that already has labels**: labels aren't git-tracked, so a `--force` overwrite of an existing label's color/description is silent, unrecoverable data loss against a possibly-curated taxonomy. Show the user any label whose existing color/description differs before overwriting it, never delete labels you didn't create, and on a repo with real issue history confirm before adding templates or creating milestones — their absence may be a choice.
- Generate the project's **`area:*` labels** from its actual top-level structure (mapped to directories, not teams — e.g. `area:web`, `area:api`, `area:db`, `area:ci`, `area:infra`, `area:docs`), confirm the set with the user, create them, and record it under `areas:` in `.n8/config.yml`. Every issue filed by the workflow carries exactly one.
- Write `.github/ISSUE_TEMPLATE/` templates for **epic**, **story**, and **bug** matching the body templates in `reference/github.md`, plus a `config.yml` with `blank_issues_enabled: false` — every issue arrives typed, whether filed by a human or an agent.

## 5. Wiki

- Check `gh repo view --json hasWikiEnabled,visibility`.
- Wiki **disabled** (typical for private repos): tell the user plainly, with how to enable it (repo Settings → Features → Wikis). Ask whether they want to use wikis at all.
  - Opted out → record `wiki: opted-out` in config. Every n8SDLC skill respects this and skips wiki work without re-asking.
- Wiki **enabled** and wanted: seed a hello-world wiki — clone `<repo>.wiki.git`, create a `Home.md` that honestly states the project is just initialized and the wiki will grow with it, push. (The wiki repo only exists after its first page; if cloning fails, create the first page via the web UI hint or `gh api` and tell the user.) Record `wiki: enabled`.

## 6. Security features (public repos)

Check visibility. For **public** repos, enable and verify:

- Dependabot alerts + security updates: `gh api -X PUT repos/$R/vulnerability-alerts` and `gh api -X PUT repos/$R/automated-security-fixes`; write a stack-appropriate `.github/dependabot.yml`.
- CodeQL default setup: `gh api -X PATCH repos/$R/code-scanning/default-setup -f state=configured` (fall back to committing a CodeQL workflow if default setup isn't available for the language).
- Secret scanning + push protection: `gh api -X PATCH repos/$R -f 'security_and_analysis[secret_scanning][status]=enabled' -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'`.
- Branch ruleset on `main`: require a PR and passing status checks before merge (fits the milestone-PR flow). Name the CI check requirement once CI exists; create the ruleset now with PR-required and note that the check requirement gets added by the CI milestone.
- Private vulnerability reporting: `gh api -X PUT repos/$R/private-vulnerability-reporting`, plus a `SECURITY.md` that routes external reporters through private reporting, never a public issue ("a public reproduction is a working exploit handed to everyone"). State honest response expectations rather than promising SLAs the user can't keep — ask what they can commit to.
- **Security-finding routing (the user decides):** ask how the project's *own* audit-found security findings get logged —
  - **`issues`** — public issues under the `security` label: a transparent register with full milestone/fingerprint/hierarchy integration. The right default for libraries and tools, where disclosure helps embedders assess risk.
  - **`advisories`** — **draft security advisories**: visible only to maintainers until published. The right choice for deployed services, where an open `sev:high` issue on a public repo advertises an exploit against running production.
  Record `security_findings: issues|advisories` in `.n8/config.yml` and write SECURITY.md's description of the register to match. On **private** repos the question is moot (issues are already maintainer-only) — record `issues` without asking.

For **private** repos, state honestly which of these need GitHub Advanced Security and skip them; still write `dependabot.yml` (works on private repos).

If any API call fails (permissions, plan limits), report exactly what the user must click in the GitHub UI instead — never silently skip.

## 7. context7 MCP (strong recommendation, not required)

Check whether context7 tools are available (look for `mcp__context7__*` via ToolSearch). If absent, strongly recommend it: the planning and execution skills use it to pull current documentation for frameworks and libraries, which materially improves plan quality. Suggest:

```
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

Record `context7: installed` or `declined` in config. Proceed either way.

## 8. Local state

Create `.n8/` per `reference/state.md`: `config.yml` (stack, wiki choice, repo, visibility, context7), an empty `decisions.md` with a header, and `memory/.gitkeep`.

## 8b. Ad-hoc change capture (CLAUDE.md)

Plans go stale when changes happen outside the n8SDLC commands — an ad-hoc conversation that swaps auth providers invalidates every downstream story that assumed the old one. Give future agent sessions a standing instruction to capture this: append to the project's `CLAUDE.md` (create it if absent):

```markdown
## n8SDLC project

This project is managed by the n8SDLC workflow (GitHub Issues = the plan; `/n8-stat` shows where things stand). If a change made in this session deviates from what planned issues assume — different library, provider, architecture, dropped/added scope, or amending a declared invariant below — do two things before finishing:
1. Append an `## Ad-hoc` entry to `.n8/decisions.md` (format documented in that file's header) naming the change, the why, and the milestones/issues likely affected.
2. Tell the user which future milestones may now have stale plans and suggest running `/n8-replan`.
```

Seed `decisions.md`'s header with the ad-hoc entry format from `reference/state.md` so sessions can follow it without the plugin installed.

## 9. Commit, push, report

Commit everything (`chore: initialize project via n8-init`) and push `main`. Then report a checklist of what was set up, what was skipped and why (honestly — e.g. "secret scanning unavailable on private repos"), and finish with the next step:

> Next: run `/n8-roadmap` and describe the overall goal of the app, its expected features, and acceptance criteria.
