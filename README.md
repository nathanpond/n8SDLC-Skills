# n8SDLC

A complete, reusable SDLC for building software with coding agents — packaged as a Claude Code plugin.

## Mission

Coding agents are excellent at *doing* and unreliable at *remembering, sequencing, and finishing*. n8SDLC closes that gap: it turns a project idea into a fully planned backlog on GitHub Issues, executes it autonomously milestone by milestone, and refuses to call anything done until it has been adversarially verified. Every decision is logged, every plan survives context resets and session changes, and when reality diverges from the plan — an architecture swap, a changed direction — the workflow detects the drift and repairs the plan instead of faithfully building the wrong thing.

Two convictions drive the design:

1. **GitHub is the only source of truth.** Plans live as issues (epics → stories → subtasks via native sub-issues), phases as milestones, order as dependencies. No parallel plan files to drift, no state directories to migrate. A small tracked `.n8/` folder holds only what GitHub can't: config answers, the decision log, memories.
2. **Never trust the agent's self-report.** Plans are written so execution needs to ask nothing; verification is done by a different pass that checks what actually exists (real files, real wiring, real behavior) against user-observable truths recorded at planning time — because "task completed" and "goal achieved" are different claims.

## Core features

- **Full lifecycle in 15 commands** — init, brownfield mapping, roadmap, granular planning, drift repair, autonomous execution, adversarial verification, releases, an 8-dimension audit suite, wiki upkeep, status, quick capture, persistent debugging, project-skill building, and help.
- **Autonomous execution that finishes** — milestone branches with one PR each, dependency-ordered stories, tests written and passing as part of every story, a deviation rulebook for discovered work (fix bugs and missing correctness automatically; stop only for architectural forks), and blockers that get labeled and skipped, never stalled on.
- **Structural verification** — every story carries a goal-backward "must-haves" contract (truths → artifacts → key links) that verification cashes with an exists/substantive/wired check; snapshots regenerated to make tests pass are treated as claims, not results. Verification closes milestones; nothing else does.
- **Drift detection and repair** — ad-hoc changes made in any session get captured to a ledger (via a CLAUDE.md instruction installed at init), surfaced by status and execution preflight, and repaired by `/n8-replan` using three evidence sources: the ledger, git history, and the codebase itself.
- **Fingerprinted, idempotent audits** — security, authorization, stability, performance, cleanup, 508 accessibility, test coverage, and integration wiring; findings carry severity and a stable fingerprint so re-runs produce deltas and detect regressions instead of filing duplicates. Security findings route to public issues or maintainer-only draft advisories, your call at init.
- **Honest by default** — the wiki reconciler and every report are bound to a no-overselling rule: planned is "planned", broken is stated, and performance claims need a measured number or they don't get written.
- **Battle-tested** — the conventions were mined from real projects (a 184-issue library backlog, a production audit suite, a shipped two-repo product) and the skills themselves were live-tested end to end on throwaway repos: planned, executed, verified, audited, drifted, replanned, and released for real, with every failure fixed back into the skills.

## Install

Requires the [`gh` CLI](https://cli.github.com) (2.94.0+), authenticated (`gh auth login`). The [context7 MCP](https://github.com/upstash/context7) is strongly recommended — planning uses it to check current docs before committing to libraries — but not required.

**Whole machine** (the commands become available in every project):

```bash
claude plugin marketplace add nathanpond/n8SDLC-Skills
claude plugin install n8sdlc@n8sdlc-skills
```

**Single project** (checked into the repo, so anyone opening it — human or agent — gets the plugin): add to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "n8sdlc-skills": {
      "source": { "source": "github", "repo": "nathanpond/n8SDLC-Skills" }
    }
  },
  "enabledPlugins": { "n8sdlc@n8sdlc-skills": true }
}
```

Claude Code will prompt to trust the marketplace on first use.

## Getting started

**New project:** create a repo on GitHub, make an empty local folder, then:

```
/n8-init        → answers a few setup questions, scaffolds the shell project, wires everything
/n8-roadmap     → describe the goal and features; get epics + a milestone skeleton
/n8-plan *      → deep Q&A now so execution never asks; full backlog created
/n8-exec *      → walk away; it builds, tests, and merges milestone by milestone
/n8-verify      → adversarial check against the plan's own truths; closes what passes
/n8-audit       → the audit suite, then /n8-exec the fixes
/n8-release     → tag a verified commit; ship
```

**Existing codebase:** same flow, but run `/n8-map` between init and roadmap — four parallel agents document the stack, architecture, conventions, and concerns (concerns become backlog issues), so planning happens against what's actually there. Init also scans for pre-existing homegrown workflows and reconciles them with your approval instead of clobbering them.

**Anytime:** `/n8-stat` shows exactly where you are and the next command — safe to run whenever you're lost. `/n8-help` lists everything. `/n8-file` captures a stray bug or idea in under a minute without derailing what you're doing.

## Command reference

| Command | One line |
|---|---|
| `/n8-init` | Set up everything: scaffold, git + remote, labels, templates, wiki, security features, conventions scan on brownfield repos. |
| `/n8-map` | Document an existing codebase (stack/architecture/conventions/concerns) before planning on it. |
| `/n8-roadmap` | Goal + features → epics and the milestone skeleton. |
| `/n8-plan` | Milestones → fully specified stories, subtasks, tests, dependencies (`M0`, `M1,M2`, `*`). |
| `/n8-replan` | Repair plans that drifted from reality; propose-then-apply. |
| `/n8-exec` | Execute planned milestones autonomously (`M0`, `M1,M2`, `*`). |
| `/n8-verify` | Adversarial verification against AC and must-haves (`--auto` / `--testplan`); closes milestones. |
| `/n8-audit` | Security, authorization, stability, performance, cleanup, 508, tests, integration — fingerprinted findings. |
| `/n8-release` | Tag a verified commit on main; notes from merged PRs; watch what the tag triggers. |
| `/n8-wiki` | Reconcile the whole wiki against backlog + code, honestly. |
| `/n8-stat` | Where you are, what needs attention, what to run next. |
| `/n8-file` | Capture a bug/idea as a triaged-later issue in under a minute. |
| `/n8-debug` | Systematic debugging with a GitHub issue as the persistent investigation brain. |
| `/n8-skill` | Build a project-specific skill into the repo's `.claude/skills/`. |
| `/n8-help` | This table, live, annotated with your project's current state. |

## How the workflow works

The lifecycle is a pipeline with hard gates:

```
init → (map) → roadmap → plan ⇄ replan → exec → verify → audit → release
                                  ↑______ drift detection ______↓
```

- **Planning front-loads every question.** Roadmap captures the goal, deployment targets, and a handful of project *invariants* (constraints no story may breach — enforced by guard tests where possible). Planning interrogates each milestone until an agent with no user access could build every story from its issue alone — vertical slices, testable acceptance criteria, a test plan per story, and recorded "Claude's Discretion" zones where you've delegated the call. M0 is always infrastructure, CI comes first, and an Audit milestone always sits last.
- **Execution is deliberately unattended.** A question during execution is treated as a planning failure. Real blockers get labeled (`blocked`, plus `needs-owner-action` when only you can resolve it), logged, and skipped; everything else proceeds. All work lands through milestone PRs gated on CI, and every judgment call is written to the decision log and shown to you afterward.
- **Done is earned twice.** Execution merging is not done; verification is — it re-derives what each story promised and checks the code, the wiring, and the running behavior, handing you a conversational test script only for what an agent genuinely can't check. Then the audit suite hunts what verification's story-by-story lens can't see (cross-cutting security, wiring orphans, coverage gaps), and its findings flow back through the same exec → verify loop.
- **Change is expected.** When any session — inside the workflow or not — changes something the plan assumed, the change gets logged to the drift ledger and `/n8-replan` rewrites the affected stories, closes invalidated ones, and adds what's newly missing, all proposed to you before anything is touched.
- **Releases are tags on main.** Milestone PRs merge continuously; a release stamps a verified commit, generates notes from the merged PRs, and triggers whatever your CI wired to tags. Never automatic.

Design decisions and their reasoning are recorded in [SPEC.md](SPEC.md) — including what was deliberately rejected, so the choices survive future re-litigation.

## License

[MIT](LICENSE) © 2026 Nathan Pond
