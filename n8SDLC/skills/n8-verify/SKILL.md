---
name: n8-verify
description: Verify executed n8SDLC milestones against their acceptance criteria — "/n8-verify M1" (args and wildcard like /n8-exec; no args = all executed-but-unverified). "--auto" has the agent verify everything it can itself; "--testplan" produces manual test-plan steps for the user. Failures become bug issues with an offer to re-exec; passing verification is what closes a milestone. Use whenever the user says "n8-verify", "verify the milestone", "check the implementation", or asks whether executed work actually meets its AC.
argument-hint: "[M0 | M1,M2 | *] [--auto | --testplan]"
---

# /n8-verify — Milestone Verification

Verification is part of done: `/n8-exec` merges code, but only a passed verification closes a milestone. Be adversarial — you're checking the work, not defending it. An AC that "should" pass isn't verified until it's been exercised.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and `${CLAUDE_PLUGIN_ROOT}/reference/state.md`.

## 1. Resolve targets and mode

- Targets like `/n8-exec`: `M1`, `M1,M2`, `*`. No argument → all executed-but-unverified milestones (stories closed, milestone still open).
- A milestone that hasn't been executed can't be verified — say so and stop for that target.
- Modes: `--auto` = verify everything the agent can itself (default when the user just runs `/n8-verify`); `--testplan` = produce step-by-step manual test plans for the user to run instead.

## 2. Verify (per milestone)

Work story by story against acceptance criteria — the AC checkboxes are the contract. **Do not trust closing comments or summaries: they document what the executor *said* it did. You verify what actually exists.**

- **Cash the must-haves block first.** For each artifact it names, check three levels: *exists* → *substantive* (real implementation, not a stub — grep for `TODO|FIXME|placeholder|not implemented`, empty returns, missing exports) → *wired* (imported somewhere else AND referenced beyond the import line). Classify each: exists+substantive+wired = **VERIFIED**; unwired = **ORPHANED**; not substantive = **STUB**; absent = **MISSING**. Anything below VERIFIED fails its truth.
- **The verification record is a comment on each covered epic**: the truth table plus the evidence summary, posted before closing anything. It's what a future session reads to know verification actually happened.
- For AC whose proof *is* a CI/deploy run (workflow gates, release paths): re-fetching the run's conclusion **fresh from the Actions API** counts as evidence — the don't-trust rule targets prose claims, not API facts. Recreate red/green runs only when the history is absent or ambiguous.
- Run the full automated test suite; confirm the tests each story's test plan promised actually exist and pass. A green suite with missing promised tests is a failure.
- **A changed snapshot/golden is a claim, not a result.** If any snapshot, golden file, or recorded baseline was updated during execution, review the diff and confirm the new output is *correct* — a golden regenerated to make a test pass proves nothing. The verification record must say why the new output is right.
- **--auto:** exercise each AC directly where possible — run the app, hit the endpoints, drive the UI, inspect outputs. Prefer evidence over inspection: "I called it and observed X" beats "the code looks right". Where a story has no `Demo` (agent-verifiable by design), derive the checks from its AC and must-have truths.
- **--testplan:** produce manual test scenarios and run the UAT protocol below.

**Steps the agent can't verify** (real devices, third-party dashboards, payments, emails, deployment targets you can't reach): even under `--auto`, don't pretend — run the UAT protocol below on those steps. Milestone closure waits for the user's results.

## The UAT protocol (manual steps and --testplan)

The user performs UAT — **you prepare the environment and give instructions; you must not run the demo yourself and report the results back** (that's automated verification wearing a costume). Start whatever needs starting *before* handing over — dev server up, seed data in, URL ready.

- Build scenarios from each story's `Demo` script where one exists; derive from AC otherwise. Order them **by user journey, not by story or component**.
- One test at a time, plain conversational text: here's what should happen — does it? "yes"/"next" passes. Anything else is logged as a failure with **severity inferred from the user's own words** (crash/broken/fails → blocker; doesn't work/wrong/missing → major; slow/weird/minor → minor; spacing/color → cosmetic) — never ask them to rate severity.
- **Never fix during testing.** Log everything, finish the pass, then diagnose — mid-UAT fixes invalidate the session and lose findings.
- Internal changes get summarized verification ("all 47 tests pass") — the user checks what they'd encounter in normal use, not your source code.

## 3. Failures → bugs, offer re-exec

For each failed AC or defect found:

1. Duplicate-check, then file a `bug` issue in the **same milestone**, referencing the story. If you reproduced it (usually yes, you just found it), add `confirmed` and include repro steps.
2. Attach it as a sub-issue of the relevant story's epic.

Then offer to run a fix pass immediately (`/n8-exec` scoped to the new bugs on a fix branch). The milestone stays open until a re-verify passes.

## 4. Close and report

A milestone passes when: every AC is verified (agent-verified or user-approved manual steps), promised tests exist and pass, and no open `confirmed` bugs remain in it. Then close the milestone (`gh api -X PATCH repos/$R/milestones/<id> -f state=closed`).

**Epics close here too:** an epic whose children are all closed and whose epic-level AC the verification just proved gets its AC boxes ticked and is closed with the verification record as its closing evidence — otherwise every closed milestone drags an eternally open epic behind it. An epic with children in later milestones stays open.

When a closed milestone represents shippable value (feature milestones especially, and always the final one), **suggest `/n8-release`** — it handles version selection, tagging the verified commit on main, generated notes, and whatever the tag triggers (production deploy, publish). Never release unasked; the suggestion is the offer.

Report per milestone: verified AC count, evidence highlights, manual steps awaiting the user (if any), bugs filed, closed or still open and why — honestly; a milestone that limps through is reported as such. Suggest the next step: fix pass, remaining verifications, next `/n8-exec`, or `/n8-audit` if all feature milestones are done.
