---
name: n8-exec
description: Execute planned n8SDLC milestones autonomously — "/n8-exec M0" implements one milestone, "/n8-exec M1,M2" several in order, "/n8-exec *" all planned-but-unexecuted milestones. Works branch-per-milestone with a PR closing all stories, writes and passes the planned tests, logs every decision, and skips-and-marks blocked instead of asking questions. Use whenever the user says "n8-exec", "execute the milestone", "implement M1", or wants planned milestones built.
argument-hint: "M0 | M1,M2 | *"
---

# /n8-exec — Milestone Execution

Implement everything in the targeted milestones exactly as planned, autonomously. The user may be away for the entire run — plans were built so no questions are needed, and needing one anyway is a planning failure worth logging honestly.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md`, `${CLAUDE_PLUGIN_ROOT}/reference/state.md`, and the relevant stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/`.

## 1. Preconditions (hard stops)

Resolve targets (`M0`, `M1,M2`, or `*` = all planned, unexecuted milestones), then verify **before touching any code**:

- **Planned:** every targeted milestone has stories. If not → tell the user which milestone is unplanned, suggest `/n8-plan <M>`, and stop.
- **In order:** every earlier milestone is already executed (its stories closed / milestone PR merged). If not → tell the user which milestone must run first and stop. Milestones build on each other; out-of-order execution produces integration debt.

## 2. Per milestone

1. **Branch:** `milestone/m<N>-short-name` off up-to-date `main`.
2. **Order stories** by dependencies (native `blocked_by` plus body-line fallbacks). Within a story, follow its subtasks — they are the prescribed *how*; deviating from a subtask is a decision (log it, with why).
3. **Per story:** implement to satisfy every acceptance criterion, write the tests named in its test plan, and run the full test suite — a story is done only when all tests pass, not just its own. Commit per story (`feat: <summary> (#N)`), comment a brief completion note on the issue, and check off its AC boxes.
4. **Log decisions as you go** to `.n8/decisions.md` (format in `reference/state.md`): any choice between alternatives, assumption, or plan deviation, with the why and the issue number. During autonomous runs this log is the user's only window into your judgment — err toward logging.
5. **PR:** open a PR from the milestone branch with a body listing `Closes #N` for every completed story. If CI exists, wait for it; merge only when green (fix failures — they're part of the milestone). If CI doesn't exist yet (e.g. during M0), run the full local test suite as the gate, merge, and say so in the report.
6. **Do not close the milestone** — that's `/n8-verify`'s job. Issues close via the PR merge.

## 3. Blockers: skip, mark, continue

Ask nothing mid-run. When you legitimately don't know how to proceed **and the cost of guessing wrong is high** (schema shape, security posture, destructive/irreversible steps, external spend):

1. Comment the specific question and the options you considered on the issue; add the `blocked` label.
2. Log it in `.n8/decisions.md` as a blocker entry.
3. Move on to work that doesn't depend on the blocked story. Dependents of a blocked story are blocked too — mark them, don't half-build them.

Low-cost ambiguities are not blockers: make the reasonable call and log it. If a milestone ends with blocked stories, complete the PR for what was finished and report the milestone as **partially executed** — never quietly done.

## 4. Report

After all targeted milestones:

- Per milestone: stories completed, PR link, test results (real numbers — if anything is failing or skipped, say so plainly).
- **Every decision made during execution**, from the decision log, displayed in full.
- Every blocker with its question and options, and which stories it holds up.
- Next step: `/n8-verify <targets>` — or, if blockers exist, answer them (comment on the issues or reply here) and re-run `/n8-exec` for the affected milestones.
