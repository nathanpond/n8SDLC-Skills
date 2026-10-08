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
- Repeat until verification passes or max retries exhausted
- Clear context after each milestone completes
- Max 5 retries per milestone

**Flags:**
- `--max-retries=N` — Change retry limit (default 5)
- `--no-auto` — Skip the auto-retry loop; run exec+verify once per milestone and return for user decision
- `--no-clear` — Don't clear context between milestones

## Behavior

Parse arguments and resolve targets like `/n8-exec` (M0, M1,M2, or *).

**Per milestone:**

1. Run `/n8-exec <milestone>`
2. Clear context
3. Run `/n8-verify <milestone>`
4. **If --no-auto**, return for user input (go to step 6)
5. **If verification passed** (milestone closed), go to step 6
6. **If verification failed** (bugs filed), and retry count < max-retries:
   - Increment retry counter
   - Query GitHub for open `bug` + `confirmed` labels in the milestone (these are the filed failures)
   - Run `/n8-exec <milestone>` again (exec skips closed stories, only runs open bugs)
   - Clear context
   - Run `/n8-verify <milestone>` again
   - Go back to step 5
7. **If retry limit exhausted** or verification still fails:
   - Report milestone as failed after N retries
   - Display remaining bugs
   - Ask user: continue to next milestone, or pause for manual fix?
8. **If milestone passed**, clear context (unless --no-clear) and proceed to next milestone

**After all milestones:**
- Report summary: total milestones, passed/failed, total retries used, bugs still open
- Suggest next step: `/n8-audit` if all shippable, `/n8-release` if ready, or re-run failed milestones with `/n8-workflow`

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
- For each milestone, maintain a retry counter
- After verify completes, check its output for the closure status (look for "milestone closed" or check GitHub API)
- On failure: query for bugs, loop, and re-exec
- Clear context at defined breakpoints
- Return a summary report with retry counts and outcomes

**Do not ask the user questions during the run** — that's the point of auto-retry. If a milestone hits max-retries with open bugs, report it honestly and move forward (or pause if --no-auto). The user can then decide whether to investigate, fix manually, or re-run the workflow.

Report with the Next line:

> ➡ Next: /n8-audit

Or, if any milestones failed:

> ➡ Next: [ask user or suggest rerun with /n8-workflow M<failed>]
