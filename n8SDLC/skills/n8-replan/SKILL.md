---
name: n8-replan
description: Reconcile stale n8SDLC milestone plans with reality after ad-hoc changes — e.g. auth swapped from Google to Okta mid-project, leaving M4+ plans with wrong implementation details or acceptance criteria. "/n8-replan" checks all planned-but-unexecuted milestones ("M4" or "M4,M5" to scope). Gathers evidence from the ad-hoc ledger, git history, and the codebase, proposes per-issue updates, and applies them on approval. Use whenever the user says "n8-replan", "the plan is stale", "we changed direction", "update the plan", or after any ad-hoc change that deviates from planned issues.
argument-hint: "[M4 | M4,M5 | *]"
---

# /n8-replan — Plan Reconciliation

Plans are snapshots. Ad-hoc changes between planning and execution (a swapped auth provider, a renamed service, a dropped feature) silently invalidate downstream milestones — execution would then faithfully build the wrong thing. This skill finds the drift and repairs the plan.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and `${CLAUDE_PLUGIN_ROOT}/reference/state.md`.

## 1. Scope

Targets: `M4`, `M4,M5`, or no argument / `*` = **all planned-but-unexecuted milestones**. Scope covers **milestone descriptions as well as issues** — every open milestone's description gets checked against the change, including the storyless Audit milestone, whose audit emphases go stale like anything else. Executed milestones are history — never rewrite their closed issues, and leave their descriptions alone too (note in the report if one now reads misleadingly); if drift means shipped work now needs changing, that's a *new* story or bug in a future milestone, not a retroactive edit.

## 2. Gather evidence — all three sources

1. **Ad-hoc ledger:** `## Ad-hoc` entries in `.n8/decisions.md` (the CLAUDE.md capture instruction from `/n8-init` feeds this). Each names the change and suspected affected milestones — the highest-signal source, including decisions made but not yet coded.
2. **Git history:** scan `git log` since the targeted milestones were planned (planning date ≈ their stories' creation dates) for commits outside milestone branches or otherwise touching areas the planned stories reference — renames, removals, dependency swaps, architectural moves.
3. **Codebase reality:** for each open story/subtask in scope, spot-check its concrete claims — named files, libraries, APIs, patterns — against the code as it exists now. A subtask that says "extend the GoogleAuthProvider" when the codebase has `OktaAuthProvider` is drift, found mechanically.

Use context7 (when available) to confirm current APIs for any technology the updated plan will reference — replanning onto stale docs just creates new drift.

## 3. Classify per issue

- **Stale how** — subtask implementation details reference things that no longer exist. Rewrite the subtask.
- **Stale what** — a story's AC assumes the old direction. Rewrite the AC (this changes the contract — call it out prominently).
- **Invalidated** — the story no longer makes sense at all. Close with `--reason "not planned"` and an explanatory comment (a "not planned" close is a human call — it happens only inside the user-approved change set). A **subtask** whose surviving content no longer needs prescribing is invalidated too — subtasks exist only where the *how* genuinely needs prescribing; don't rewrite one down to a one-liner.
- **Missing** — the change implies work no story covers (e.g. Okta tenant provisioning). Draft new stories/subtasks (duplicate-check first).
- **Re-wire** — dependency edges that changed with the above.

## 4. Propose, then apply

Present one change summary before touching anything — milestone-description edits included in the same summary, not approved separately: per issue — what changes and *which ad-hoc change caused it*; new issues in full; closures with reasons; a note where epic-level AC on the roadmap itself is affected (flag it — epic AC changes deserve the user's explicit eyes). Then, on approval, apply everything: edit bodies, close, create, attach sub-issues, re-wire dependencies, update milestone descriptions.

Leave an audit trail: comment on every modified issue ("Replanned 2026-08-27: auth moved Google → Okta, AC updated accordingly"), and log the replan (cause, issues touched) to `.n8/decisions.md`, landing the state edits per `reference/state.md`'s "Committing state changes". Mark the triggering ad-hoc ledger entries as reconciled (append `— reconciled by /n8-replan <date>`) so future drift checks don't re-flag them.

## 5. Report

Issues updated / created / closed per milestone, epic AC flags, ledger entries reconciled, and anything found that suggests deeper drift than the scope covered (recommend widening). Next step: usually `/n8-exec <next milestone>` — the plan is trustworthy again.
