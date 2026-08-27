---
name: n8-plan
description: Plan n8SDLC milestones at a granular level — "/n8-plan M0" plans one milestone, "/n8-plan M1,M2" several, "/n8-plan *" all. Asks detailed questions up front, creates stories (the what, with acceptance criteria and test plans) as sub-issues of epics and subtasks (the how) under stories, wires dependencies, and afterwards analyzes the whole plan to suggest specialized audits and project-specific skills. Use whenever the user says "n8-plan", "plan milestone", "plan M1", or wants detailed milestone planning after /n8-roadmap.
argument-hint: "M0 | M1,M2 | *"
---

# /n8-plan — Milestone Planning

Plan milestones down to the level where execution needs to ask **nothing**. The bar: an agent with no access to the user must be able to implement every story from its issue alone. Any question you don't ask now becomes a blocker during `/n8-exec` — and an execution-time question is a planning failure.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md`, `${CLAUDE_PLUGIN_ROOT}/reference/state.md`, and the stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/` matching `.n8/config.yml`.

## 1. Resolve targets

Parse the argument: a single milestone (`M0`), a comma list (`M1,M2`), or `*` (all open milestones not yet planned — a milestone counts as planned when it has stories assigned). Match against actual milestone titles (`M0: …`). Requirements:

- `/n8-roadmap` must have run (epics + milestones exist); otherwise say so and stop.
- Plan milestones in order. If the user asks for M2 but M1 is unplanned, point it out and ask whether to proceed anyway — later plans usually depend on earlier decisions.

## 2. Interrogate per milestone

For each milestone, study its epics and phases, then ask everything execution would otherwise have to guess. Themes that recur:

- Concrete technology and library choices (verify current APIs/versions via context7 when available — plans built on stale docs produce broken code).
- Data models, API shapes, naming — anything with more than one defensible answer.
- UX decisions: flows, validation behavior, error states, empty states.
- Edge cases and failure handling: what should happen when X fails?
- Anything where being wrong is expensive to undo (schemas, auth model, public API surface).

Batch questions sensibly rather than dribbling them one at a time. Skip questions whose answers are already in `.n8/config.yml`, existing issues, or the codebase.

## 3. Create stories and subtasks

For each unit of work, run the duplicate check first (ask the user on related-but-different matches: extend existing AC or new issue?). Then:

- **Story** — `feature` (or `bug`/`security`/`performance`/`documentation`) label, story body template: the *what*, testable acceptance criteria, and a **test plan** naming the automated tests to write. Every story that changes behavior gets tests in its own scope — the milestone's definition of done includes all tests passing, so untested stories are incomplete stories. Assign to the milestone. Attach as a **sub-issue of its epic**.
- **Subtask** — `subtask` label, only where the *how* genuinely needs prescribing (specific files, patterns, gotchas, sequences). Attach as a sub-issue of its story. Don't manufacture subtasks for self-evident implementations.
- **Dependencies** — wire `blocked_by` relationships (native API, body-line fallback per `reference/github.md`) wherever order matters. Execution follows these strictly.
- Update the milestone description's phase list to reflect the final story set.

## 4. Whole-project analysis (after all targeted milestones are planned)

Step back and analyze the full plan for what the roadmap couldn't see:

- **Specialized audits:** does the app's functionality raise specific concerns — user-generated content (security/XSS), payments (authorization), public-facing UI (508), heavy data processing (performance)? Suggest which `/n8-audit` areas deserve emphasis and record them in the Audit milestone description.
- **Project-specific skills:** would a purpose-built skill pay for itself — e.g. a "plugin-creator" skill for an app with a plugin system, a content-format skill, a deployment runbook skill? Suggest candidates and offer to build approved ones now via `/n8-skill`.
- **Gaps:** cross-milestone integration risks, missing stories, test coverage holes. Fix with the user's approval.

Log notable planning decisions to `.n8/decisions.md`.

## 5. Report

Per milestone: story count, subtask count, dependency chains, test coverage summary. Then the analysis outcomes (audit emphases, suggested skills). Finish with the next step — more planning if milestones remain unplanned, otherwise:

> Next: run `/n8-exec M0` to execute (or `/n8-exec *` to run everything autonomously).
