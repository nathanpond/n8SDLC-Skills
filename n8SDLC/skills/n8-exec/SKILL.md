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
- **Not stale:** run a drift check on the targeted milestones — plans age, and executing a stale plan faithfully builds the wrong thing. Check (a) unreconciled `## Ad-hoc` entries in `.n8/decisions.md` naming these milestones or their subject areas, and (b) spot-check each story/subtask's concrete claims (files, libraries, providers) against the current codebase. Pure implementation-detail staleness (a renamed file, a moved module) → adjust inline, log the correction, proceed. Anything touching **AC or story validity** (e.g. auth provider swapped since planning) → hard stop for that milestone: report the drift and recommend `/n8-replan <M>`.

## 2. Per milestone

1. **Branch:** `milestone/m<N>-short-name` off up-to-date `main`.
2. **Order stories** by dependencies (native `blocked_by` plus body-line fallbacks). Within a story, follow its subtasks — they are the prescribed *how*; deviating from a subtask is a decision (log it, with why).
3. **Per story:**
   - Read it fully first (`gh issue view <n> --comments`), then **comment the plan before the code**: 2–5 bullets — approach and expected files. If AC are missing, derive them into this comment as a checklist; the definition of done gets written down before work starts.
   - Implement to satisfy every acceptance criterion; respect the project invariants in CLAUDE.md's n8SDLC section — a story that appears to require breaching one is a blocker (that's a conversation, not a judgment call). The story's **Claude's Discretion** section is the inverse: decisions the user explicitly delegated — improvise there freely and log the choice.
   - **You WILL discover work the plan missed — this is normal. What you may do about it depends on where it sits:**
     - *Inside this story's scope* (in code the story touches, needed for it to be correct/secure/complete): **Rule 1** — fix bugs (broken behavior, logic errors, races) + add a regression test. **Rule 2** — add missing critical functionality (input validation, error handling, authz on protected routes — requirements for basic correctness, not features). **Rule 3** — fix blockers (broken import, missing dep, build config). All three: fix automatically, log to the decision ledger with the rule tag.
     - **Rule 4 — architectural changes stop the story**: new table (not a new column), schema/PK changes, swapping libraries, changing API contracts, new infrastructure. That's the blocker path. **Genuinely unsure which rule applies → Rule 4.**
     - *Outside this story's scope*: a separate problem gets its own issue (`--label needs-triage`, body starting "Discovered while working #N."), cross-referenced in a comment — never fixed inline. That's silent scope creep.
   - **Auth gates are checkpoints, not failures:** a 401/"invalid API key"/login prompt means label the story `blocked` + `needs-owner-action` asking for exactly the credential needed — then, once provided, *you* run the automation. Secrets come from the user; automation comes from you. Never ask the user to run commands you can run yourself.
   - Write the tests named in the story's test plan and run the **full** suite — a story is done only when all tests pass, not just its own. Never finish by weakening the gate (suppressing warnings, skipping tests).
   - Commit per story with `Refs #N` in the body (never `Fixes`/`Closes` — closing keywords are silent no-ops off the default branch), push, then check off the AC boxes and comment completion **with evidence**: branch @ short SHA, what changed per AC, exact test results. Push before any close — a closed issue with no code on the remote is a lie.
4. **Log decisions as you go** to `.n8/decisions.md` (format in `reference/state.md`): any choice between alternatives, assumption, or plan deviation, with the why and the issue number. During autonomous runs this log is the user's only window into your judgment — err toward logging.
5. **PR:** open a PR from the milestone branch with a body listing `Closes #N` for every **completed** story (never partial ones). If CI exists, wait for it; merge only when green (fix failures — they're part of the milestone). If CI doesn't exist yet (e.g. during M0), run the full local test suite as the gate, merge, and say so in the report. **After the merge**, check `gh issue view <n> --json state` on every story touched but not finished — GitHub auto-closes linked issues on merge regardless of keywords; reopen any casualty with "Reopened: closed by the merge, not by completion. <what is left>".
6. **Do not close the milestone** — that's `/n8-verify`'s job. Issues close via the PR merge. Observe the four Nevers from `reference/github.md`: no closing what you didn't verify, no bulk closes, no touching issues you didn't create undirected, no "not planned" on your own initiative.

## 3. Blockers: skip, mark, continue

Ask nothing mid-run. When you legitimately don't know how to proceed **and the cost of guessing wrong is high** (schema shape, security posture, destructive/irreversible steps, external spend, breaching a declared project invariant):

1. Comment the specific question and the options you considered on the issue; add the `blocked` label — plus `needs-owner-action` when what it waits on is the user (access, credentials, a call only they can make), so the open-issue list reads honestly about what an agent can still act on.
2. Log it in `.n8/decisions.md` as a blocker entry.
3. Move on to work that doesn't depend on the blocked story. Dependents of a blocked story are blocked too — mark them, don't half-build them.

Low-cost ambiguities are not blockers: make the reasonable call and log it. If a milestone ends with blocked stories, complete the PR for what was finished and report the milestone as **partially executed** — never quietly done.

## 4. Report

After all targeted milestones:

- Per milestone: stories completed, PR link, test results (real numbers — if anything is failing or skipped, say so plainly).
- **Every decision made during execution**, from the decision log, displayed in full.
- Every blocker with its question and options, and which stories it holds up.
- Next step: `/n8-verify <targets>` — or, if blockers exist, answer them (comment on the issues or reply here) and re-run `/n8-exec` for the affected milestones.
