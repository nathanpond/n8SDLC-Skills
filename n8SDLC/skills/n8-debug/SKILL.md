---
name: n8-debug
description: Systematic debugging with a GitHub issue as the persistent investigation brain — hypotheses, evidence, and eliminated dead ends survive context resets and session changes. Use whenever the user says "n8-debug", "debug this", "why isn't this working", "track down this bug", or an investigation looks likely to outlive one session's context.
argument-hint: "<symptom, or an existing issue number>"
---

# /n8-debug — Persistent Debugging

A debugging session's most expensive asset is its **negative knowledge** — the hypotheses already disproven. It's invisible to git, and a context reset destroys it, so the investigation lives in a GitHub issue, not in the conversation. Given an issue number, resume it; given a symptom, duplicate-check then file one (`bug` label, plus `confirmed` once reproduced).

## The issue as the brain

Write-discipline per section — **update the issue BEFORE acting, not after**: if context resets mid-action, the record shows what was about to happen.

- **Body — overwritten** via `gh issue edit --body-file` before every investigative action:
  ```markdown
  ## Symptoms            <- immutable once gathered: what happens, repro steps, when it started
  ## Current focus       <- overwritten each cycle:
  Hypothesis: <falsifiable statement>
  Testing via: <the experiment>
  Expecting: <result if true / if false>
  Next action: <exactly what happens next>
  ```
- **Comments — append-only, timestamped for free:**
  - `Eliminated: <hypothesis> — <the evidence that killed it>`
  - `Evidence: checked <thing> — found <result> — implies <what>`

**Resume after any reset:** `gh issue view <n> --json title,body,comments` — Symptoms say what's broken, Current focus says what was in flight, the Eliminated comments say **what not to retry**. Continue from Next action.

## Investigation discipline

- **Hypotheses must be falsifiable.** "There's a race condition somewhere" is not a hypothesis; "the API call completes after unmount, causing a state update on an unmounted component" is — it names the mechanism and what would disprove it.
- **Prefer the experiment that splits the hypothesis space** — one test that differentiates several candidates beats four that each confirm a favorite.
- **Fix only when all four hold:** you understand the mechanism, you reproduce reliably, you have evidence (not theory), and you've ruled out the alternatives. "I think it might be X" is not grounds to act.
- **A fix that works for reasons you can't explain isn't a fix — it's luck.** Keep the issue open and keep digging until the mechanism is understood; say so honestly if the user wants to stop there.
- Every 30 minutes of a stuck path, ask: *if I started fresh right now, is this still the path I'd take?* Sunk cost drives more bad debugging than missing information does.
- When the bug is in code you wrote: the hardest admission is "I implemented this wrong" — not "requirements were unclear." Check your own change first.

## Closing

Fix with a **regression test that reproduces the bug**, then close through the normal working discipline (evidence in the closing comment: mechanism, fix, test). The Eliminated trail stays in the issue — it's the documentation of why the fix is the right one.
