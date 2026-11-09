---
name: n8-workflow
description: Orchestrate full exec→verify→retry loops for multiple milestones autonomously — "/n8-workflow M0,M1" runs each milestone through complete cycles with automatic retry and clearing. Combines /n8-exec and /n8-verify with intelligent retry logic and context clearing to minimize token usage. Use whenever the user wants to build and verify multiple milestones end-to-end without manual intervention between cycles.
argument-hint: "M0,M1,M2 [--max-retries=5] [--no-auto] [--no-clear]"
---

# /n8-workflow — Multi-Milestone Orchestration with Auto-Retry

Execute and verify multiple milestones as a single orchestrated workflow. Each milestone runs through exec→verify→re-exec (if bugs found) loops automatically, clearing context between phases to minimize token usage.

**Default behavior (no flags):**
- Execute each milestone, then verify it
- If verification finds bugs: automatically re-execute the milestone (bugs already open, exec picks them up), then re-verify
- Repeat until verification passes, max retries are exhausted, every open bug waits on the owner (`blocked`/`needs-owner-action`), or a round makes no progress
- Clear context after each milestone completes
- Max 5 retries per milestone

**Flags:**
- `--max-retries=N` — Change retry limit (default 5)
- `--no-auto` — Skip the auto-retry loop; run exec+verify once per milestone and return for user decision
- `--no-clear` — Don't clear context between milestones

## Behavior

Parse arguments and resolve targets like `/n8-exec` (M0, M1,M2, or *). `$R` and each milestone's GitHub number `$N` are resolved as `/n8-verify` resolves them (the one-match assertion on the `M<x>:` title), never hand-typed.

**Per milestone:**

1. Run `/n8-exec <milestone>`
2. Clear context
3. Run `/n8-verify <milestone>`
4. **If verification passed** (milestone closed) → outcome **passed**; go to step 8.
5. **If `--no-auto`** → record the verify result as the outcome (**passed** or **failed after 0 retries**); go to step 8.
6. **Before each retry, check that one can change anything.** Retries are the run's whole cost; one that can't move the verdict is pure waste.
   - **Actionable work:** count the milestone's open `bug` and story issues — every open bug verify filed, `confirmed` or not — **excluding** anything labelled `blocked` or `needs-owner-action` (`/n8-exec` labels what it can't act on that way):
     ```sh
     gh api "repos/$R/issues?milestone=$N&state=open&per_page=100" --paginate --jq '.[] | select(.pull_request|not) | select(any(.labels[].name; IN("epic","spike","subtask")) | not) | select(any(.labels[].name; IN("blocked","needs-owner-action")) | not) | .number'
     ```
     Empty while verification still fails → outcome **blocked on owner**: stop the loop, don't retry. Carried `sev:medium`/`sev:low` bugs don't fail verification, so they never reach this check.
   - **Retry limit:** retry count = `--max-retries` → outcome **failed after N retries**; go to step 8.
7. **Retry:** increment the counter, record `git rev-parse origin/main` (after `git fetch origin`), then run `/n8-exec <milestone>` (it skips closed stories and works the open bugs) and clear context. **No-progress guard:** if exec reports nothing to execute, or `origin/main` hasn't moved since the recorded SHA, skip the re-verify — re-verifying an unchanged commit can't change the verdict — and stop with outcome **stalled**. Otherwise run `/n8-verify <milestone>`, clear context, and go back to step 4.
8. **Next milestone:** clear context (unless `--no-clear`) and carry on, whatever the outcome. Never stop to ask: `/n8-exec`'s own rules mark stories that depend on blocked work as blocked, so carrying on is safe, and everything goes in the summary.

**After all milestones**, report one row per milestone with its outcome and retries used:
- **passed** — the milestone closed.
- **blocked on owner** — each blocking issue (number, title) and the decision it needs, taken from its `blocked` comment.
- **stalled** — the round that made no progress, what exec reported, and the open bugs.
- **failed after N retries** — the bugs still open.

Then the Next line (below).

## Implementation

Use the `Workflow` tool to orchestrate this as a multi-agent pipeline:

- **Phase 1 (Exec):** Run `/n8-exec` on each milestone target
- **Phase 2 (Verify):** After each exec → verify with retry logic that:
  - Parses verify output for success/failure
  - Queries GitHub for filed bugs
  - Decides whether to retry or move forward
  - Conditionally runs `/n8-exec` again on the same milestone if bugs found
  - Loops until passes or max-retries hit
- **Phase 3 (Clearing):** Between milestones and after each cycle (unless --no-clear)

The workflow script must:
- Parse the arguments and flags at the start
- Build the milestone target list
- For each milestone, maintain a retry counter and the `origin/main` SHA from before the last exec
- After verify completes, check closure on the GitHub API (`gh api repos/$R/milestones/$N --jq .state`), not by parsing its prose
- On failure: run step 6's actionable-work query; empty → `blocked on owner`, otherwise re-exec, then apply the no-progress guard before re-verifying
- Clear context at defined breakpoints
- Return a summary report with retry counts and outcomes

**Do not ask the user questions during the run** — that's the point of auto-retry. Whatever a milestone's outcome, report it honestly and move on to the next. The user decides afterwards, from the summary.

Report with the Next line, picked by the worst outcome:

- All **passed** → `➡ Next: /n8-audit` (or `/n8-release` if the audit has already run)
- Any **blocked on owner** → the decision itself: `➡ Next: answer #<n> (<the decision>)`, or `/n8-replan M<x>` when the decision changes AC. Never point a blocked milestone at a `/n8-workflow` re-run: nothing it can do changes until the owner acts.
- Any **stalled** or **failed after N retries** → `➡ Next: /n8-debug` on the bug that kept failing, then `/n8-workflow M<x>`
