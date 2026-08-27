# n8SDLC Skills

A reusable SDLC process for building projects with coding agents, packaged as a Claude Code plugin. GitHub Issues is the planning backbone (epics → stories → subtasks via native sub-issues, milestones, dependencies); a small tracked `.n8/` directory holds decisions and memory that don't fit GitHub.

## Install

```bash
claude plugin marketplace add nathanpond/n8SDLC-Skills
claude plugin install n8sdlc@n8sdlc-skills
```

## The workflow

| Command | What it does |
|---|---|
| `/n8-init` | First command. Shell project (or scaffold one), git repo + your GitHub remote, baseline labels + issue templates, wiki check/seed, security features (public repos), recommends context7 MCP. On projects with a pre-existing homegrown workflow: scans for conflicting skills/conventions, harvests their knowledge, and removes them only with per-item approval. |
| `/n8-map` | Brownfield mapping: four parallel agents document an existing codebase's stack, architecture, conventions, and concerns into the wiki — written prescriptively for future executors; concerns become triaged issues. Run before `/n8-roadmap` on codebases that predate n8SDLC. |
| `/n8-roadmap` | Describe the app's goal, features, and AC. Clarifying Q&A → epics (epic-level AC) + milestone skeleton: M0 Infrastructure always first, CI early, Audit always last. |
| `/n8-plan M0` | Granular milestone planning (`M1,M2`, `*` supported). Deep Q&A so execution never has to ask. Stories (the what + AC + test plans) under epics, subtasks (the how) under stories, dependencies wired. Post-analysis suggests specialized audits and project skills. |
| `/n8-exec M0` | Autonomous execution (`M1,M2`, `*` supported). Branch + PR per milestone, tests written and passing, every decision logged and reported. Blockers: skip, mark `blocked`, continue, surface at the end. Stops if targets are unplanned or out of order. |
| `/n8-replan` | Reconcile stale plans after ad-hoc changes (e.g. auth swapped Google → Okta after M0–M3 shipped). Gathers evidence from the ad-hoc ledger, git history, and codebase; proposes per-issue AC/subtask updates, closures, and new stories; applies on approval. Exec's preflight hard-stops on substantive drift and points here; `/n8-stat` flags unreconciled ad-hoc changes. |
| `/n8-verify` | Verify against AC (`--auto` agent-verifies everything it can; `--testplan` gives you manual steps). Un-verifiable steps become manual steps for your approval. Failures → confirmed bugs + offered re-exec. Passing verify is what closes a milestone. |
| `/n8-audit` | Audit suite: security, stability, performance, cleanup, authorization, 508, test coverage. Stack-appropriate tooling (CodeQL, semgrep, dependency audits, fuzzing where applicable), per-dimension concern checklists, a shared severity rubric, verified findings only. Reports findings, asks which to file — fingerprinted so re-runs dedupe, detect regressions, and produce deltas. Security findings route to public issues or maintainer-only draft advisories per the init-time choice. |
| `/n8-file` | Quick capture: file a bug/task as a `needs-triage` issue in under a minute (duplicate-checked, code-anchored) without losing your place. Triage happens at the next planning pass. |
| `/n8-debug` | Systematic debugging with a GitHub issue as the persistent brain — falsifiable hypotheses, appended evidence, and an "Eliminated" trail that survives context resets. Closes with a regression test that reproduces the bug. |
| `/n8-wiki` | Full reconcile of the wiki against backlog + codebase. Human, informational tone; honest by default, never oversells. Optional — respects opt-out. |
| `/n8-release` | Cut a release: tag a verified commit on main, GitHub release with notes generated from merged PR titles, and watch whatever the tag triggers (production deploy, publish). Hard preconditions: milestones verified-closed, CI green. Never runs unasked. |
| `/n8-stat` | Where you are in the process, live from GitHub, plus the suggested next command. |
| `/n8-skill` | Build a project-specific skill into the project's `.claude/skills/` (also offered by `/n8-plan`'s analysis). |
| `/n8-help` | The command reference — every command with a one-liner, and the reminder that `/n8-stat` always shows where you are. |

First-class stacks for init scaffolding: **.NET/C#, TypeScript/Node, Python, Unity, Dart/Flutter** (others handled generically).

Requires the `gh` CLI, authenticated. The context7 MCP is strongly recommended (planning/execution use it for current docs) but not required.

Design decisions behind all of this are recorded in [SPEC.md](SPEC.md).
