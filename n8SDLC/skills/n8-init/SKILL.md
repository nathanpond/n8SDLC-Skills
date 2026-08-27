---
name: n8-init
description: Initialize a project for the n8SDLC workflow — the first command run in any new project. Inspects the folder for an existing shell project (offering to create one for .NET, TypeScript/Node, Python, Unity, or Flutter), creates the local git repo, wires the user-supplied GitHub remote, sets up baseline issue labels and templates, checks/seeds the wiki, enables GitHub security features on public repos, and recommends the context7 MCP. Use whenever the user says "n8-init", "initialize this project", "set up the SDLC", or starts the n8SDLC process in a fresh folder.
---

# /n8-init — Project Initialization

Set up everything the rest of the n8SDLC workflow depends on. Every step is idempotent — re-running init on a partially initialized project fills gaps and skips what's done, so check before creating throughout.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` (labels, templates, conventions) and `${CLAUDE_PLUGIN_ROOT}/reference/state.md` (.n8/ layout) before starting.

## 1. Preflight

- `gh auth status` — if not authenticated, stop and tell the user to run `gh auth login`. Nothing downstream works without it.
- If `.n8/config.yml` already exists, report what's already initialized and only perform missing steps.

## 2. Shell project

Inspect the folder for an existing project using the detection markers in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/*.md` (.NET, TypeScript, Python, Unity, Flutter).

- **Found:** confirm the detected stack with the user and record it.
- **Not found:** ask what should be created — offer the five first-class stacks plus "something else". For a first-class stack, follow its reference file's Scaffold section. For anything else, ask enough questions (language, project shape, test framework) to scaffold sensibly with that ecosystem's standard generator.

## 3. Git repo and remote

- `git init -b main` if not already a repo.
- If no `origin` remote: ask the user to supply a GitHub remote URL (they create the repo on GitHub themselves — don't create it for them). Add it, then verify access with `gh repo view`.
- Don't push yet; the initial push happens at the end.

## 4. Labels and issue templates

- Create the baseline label set from `reference/github.md` using `--force` (idempotent).
- Write `.github/ISSUE_TEMPLATE/` templates for **epic**, **story**, and **bug** matching the body templates in `reference/github.md`, plus a `config.yml` with `blank_issues_enabled: true`.

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

This project is managed by the n8SDLC workflow (GitHub Issues = the plan; `/n8-stat` shows where things stand). If a change made in this session deviates from what planned issues assume — different library, provider, architecture, or dropped/added scope — do two things before finishing:
1. Append an `## Ad-hoc` entry to `.n8/decisions.md` (format documented in that file's header) naming the change, the why, and the milestones/issues likely affected.
2. Tell the user which future milestones may now have stale plans and suggest running `/n8-replan`.
```

Seed `decisions.md`'s header with the ad-hoc entry format from `reference/state.md` so sessions can follow it without the plugin installed.

## 9. Commit, push, report

Commit everything (`chore: initialize project via n8-init`) and push `main`. Then report a checklist of what was set up, what was skipped and why (honestly — e.g. "secret scanning unavailable on private repos"), and finish with the next step:

> Next: run `/n8-roadmap` and describe the overall goal of the app, its expected features, and acceptance criteria.
