---
name: n8-stat
description: Show exactly where an n8SDLC project is in the process and the suggested next command. Derives status live from GitHub (labels, epics, milestones, PRs) and the repo — init → roadmap → plan → exec → verify → audit. Use whenever the user says "n8-stat", "where are we", "what's next", "project status", or seems unsure which n8SDLC command comes next.
---

# /n8-stat — Process Status

Tell the user exactly where they are and what to run next. Derive everything live from GitHub and the repo — never from stale notes. Keep it fast and honest: this command gets run constantly, so favor a tight readout over an essay.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` for conventions.

## Derive the stage

Check in order — the first missing thing marks the stage:

1. **Not initialized** — no `.n8/config.yml` (or no git repo / labels) → next: `/n8-init`
2. **No roadmap** — no `epic`-labeled issues or no milestones → next: `/n8-roadmap`
3. **Planning** — milestones exist but some have no stories → next: `/n8-plan <first unplanned>` (note `*` plans all)
4. **Executing** — planned milestones with open, unblocked stories and no merged milestone PR → next: `/n8-exec <first unexecuted>`
5. **Verifying** — milestones with all stories closed but still open → next: `/n8-verify <M>`
6. **Auditing** — only the Audit milestone remains → next: `/n8-audit`
7. **Releasable** — verified-closed shippable milestones with no release tag covering them (`gh release list` vs. milestone close dates) → next: `/n8-release`
8. **Done** — all milestones closed and released → suggest `/n8-wiki` for a final reconcile, and congratulate honestly.

Stages overlap in real projects (M1 verifying while M3 is unplanned) — report the full picture, then pick the single most useful next command (unblock before advancing: blocked issues and failed verifications outrank starting new work).

## Output format

```
## Project status — <repo>

Stage: <stage>

| Milestone | Planned | Executed | Verified | Notes |
|---|---|---|---|---|
| M0: Infrastructure | ✅ | ✅ | ✅ closed | |
| M1: Core API | ✅ 8 stories | 🔶 6/8 | — | 2 blocked |

⚠ Attention: <blocked issues with their questions; failed verifications; unmerged milestone PRs; open confirmed bugs; suspected plan drift; needs-triage pile-up (>5 untriaged captures)>

➡ Next: /n8-<command> — <one line on why>
```

The Attention section only appears when something needs the user. Blocked issues show their actual question inline — the user should be able to unblock straight from this readout without clicking through. List `needs-owner-action` issues first: those are, by definition, waiting on exactly the person reading this.

**Drift check (cheap, ledger-based):** scan `.n8/decisions.md` for `## Ad-hoc` entries not marked reconciled. Any that exist while planned-but-unexecuted milestones remain → Attention line naming the change and affected milestones, suggesting `/n8-replan <M>`. Don't deep-scan the codebase here — that's replan's job; stat stays fast.
