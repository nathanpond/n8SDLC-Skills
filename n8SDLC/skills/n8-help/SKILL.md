---
name: n8-help
description: Show the n8SDLC command reference — every /n8-* command with a one-line summary, in workflow order. Use whenever the user says "n8-help", "what n8 commands are there", "how does n8SDLC work", or seems unsure which command exists for something.
---

# /n8-help — Command Reference

Print the reference below (as a markdown table or tight list — whichever renders better in context), adjusted honestly for the current project: if `.n8/config.yml` doesn't exist yet, lead with "this project isn't initialized — start with `/n8-init`."

Open and close with the one thing the user should remember:

> **Lost? `/n8-stat` always shows exactly where you are in the process and the suggested next command.** It's safe to run anytime — it only reads.

## The commands, in workflow order

| Command | What it does |
|---|---|
| `/n8-init` | First command. Sets up the project: shell scaffold, git + your GitHub remote, labels, templates, wiki, security features — and reconciles any pre-existing homegrown workflow. |
| `/n8-map` | (Existing codebases) Maps stack, architecture, conventions, and concerns into the wiki before planning; concerns become issues. |
| `/n8-roadmap` | You describe the goal and features; it builds epics and the milestone skeleton (M0 infrastructure → CI → features → Audit). |
| `/n8-plan M1` | Plans milestones in granular detail (`M1,M2`, `*`) — stories, subtasks, tests, dependencies — so execution never has to ask. |
| `/n8-replan` | Reconciles stale plans after ad-hoc changes (evidence: decision ledger, git history, codebase); proposes updates, applies on approval. |
| `/n8-exec M1` | Executes planned milestones autonomously (`M1,M2`, `*`): milestone branch + PR, tests passing, decisions logged, blockers marked and skipped. |
| `/n8-verify` | Verifies executed milestones against acceptance criteria (`--auto` agent-verifies; `--testplan` walks you through UAT). Passing verify is what closes a milestone. |
| `/n8-release` | Tags a verified commit on main, creates the GitHub release, and watches whatever the tag triggers (prod deploy, publish). Never runs unasked. |
| `/n8-audit` | Audit suite: security, authorization, stability, performance, cleanup, 508, tests, integration. Findings are verified, severity-rated, and filed on your approval. |
| `/n8-wiki` | Reconciles the whole wiki against the backlog and codebase. Honest tone; applies updates, then summarizes. |
| `/n8-stat` | **Where you are and what's next** — derived live from GitHub, with anything needing your attention (blockers, drift, failures) surfaced inline. |
| `/n8-file` | Quick capture: files a bug/task as a triaged-later issue in under a minute, without losing your place. |
| `/n8-debug` | Systematic debugging with a GitHub issue as the persistent brain — hypotheses, evidence, and eliminated dead ends survive context resets. |
| `/n8-skill` | Builds a project-specific skill into this repo's `.claude/skills/` (also suggested by planning when a pattern warrants one). |
| `/n8-help` | This reference. |

Keep the summaries to this table's altitude — the commands' own skills carry the detail. If the user asks "which one do I run now?", don't guess from the table: run the `/n8-stat` logic and answer from the project's actual state.
