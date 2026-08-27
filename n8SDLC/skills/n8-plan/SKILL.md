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

First, sweep `needs-triage` issues (quick captures from `/n8-file` and discovered-work filings): for each, propose with the user whether it becomes a story in a targeted milestone, folds into an existing issue's AC, or waits. Triage is planning's job — captures shouldn't accumulate.

When planning M0 or the CI milestone, check the project invariants in CLAUDE.md: every invariant marked test-enforced needs a story creating its **executable guard** (a test or build setting that fails when the invariant is breached — package-count test, public-API snapshot, warnings-as-errors). If a guard story is missing, add it and update the invariant's marking once it lands.

For each milestone, study its epics and phases, then ask everything execution would otherwise have to guess. Themes that recur:

- Concrete technology and library choices (verify current APIs/versions via context7 when available — plans built on stale docs produce broken code).
- Data models, API shapes, naming — anything with more than one defensible answer.
- UX decisions: flows, validation behavior, error states, empty states.
- Edge cases and failure handling: what should happen when X fails?
- Anything where being wrong is expensive to undo (schemas, auth model, public API surface).

Batch questions sensibly rather than dribbling them one at a time. Skip questions whose answers are already in `.n8/config.yml`, existing issues, or the codebase.

## 3. Create stories and subtasks

**Present the breakdown before creating anything.** Show a compact review artifact — one line per issue: `title — labels — one-line outcome`, marking which are epics/spikes and what depends on what. Enough to judge the slicing without reading full bodies. On the user's go, create the batch and report the numbers with links. Never create issues speculatively mid-discussion, and never skip the gate because the plan seems obvious.

For each unit of work, run the duplicate check first (ask the user on related-but-different matches: extend existing AC or new issue?). Then:

- **Story** — `feature` (or `bug`/`security`/`performance`/`documentation`) label plus exactly one `area:*` label, story body template: the *what*, testable acceptance criteria, and a **test plan** naming the specific automated tests that will prove it. If an AC cannot be written as something testable, the story is too vague — split it or ask; if the work genuinely can't be demonstrated by a test, the story must say so explicitly and state how it will be checked instead. **Slice vertically, not horizontally**: one story per shippable slice cut through every layer together ("show the games list end to end" beats table + endpoint + component as three stories), because only the vertical slice can be verified on its own — and per-story verification is how `/n8-verify` works. Size stories so one fits in a single working session — oversized stories are where autonomous execution stalls. Titles are outcomes phrased as verbs ("Serve the games list from the DB", not "Games API"). Every story that changes behavior gets tests in its own scope — the milestone's definition of done includes all tests passing, so untested stories are incomplete stories. Assign to the milestone. Attach as a **sub-issue of its epic**.
- **Spike** — when planning hits a question that can't be answered by asking the user or reading docs (a technology choice needing a prototype, an unknown integration), don't guess and don't stall: file a `spike`-labeled issue, time-boxed, sequenced before the stories that depend on its answer. A spike closes with a **decision comment** and follow-up stories, never with code.
- **Subtask** — `subtask` label, only where the *how* genuinely needs prescribing (specific files, patterns, gotchas, sequences). Attach as a sub-issue of its story. Don't manufacture subtasks for self-evident implementations.
- **Dependencies** — wire `blocked_by` relationships (native flags, body-line fallback per `reference/github.md`) wherever order matters; ordering lives in the graph, not in prose. Execution follows these strictly.
- **Epic AC patterns** worth using where they fit: "each child implemented *or closed with the reason it will not be*" (so an epic can complete honestly without every idea surviving); a docs/wiki-update obligation tied to children landing; an explicit "nothing here weakens the project invariants" clause. For epics with many candidate children, tier them by leverage (highest return → hygiene), one line of justification per child — it makes descoping decisions legible later.
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
