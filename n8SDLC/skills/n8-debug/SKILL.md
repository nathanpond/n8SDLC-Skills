---
name: n8-debug
description: Systematic debugging with a GitHub issue as the persistent investigation brain — hypotheses, evidence, and eliminated dead ends survive context resets and session changes. Use whenever the user says "n8-debug", "debug this", "why isn't this working", "track down this bug", or an investigation looks likely to outlive one session's context.
argument-hint: "<symptom, or an existing issue number>"
---

# /n8-debug — Persistent Debugging

A debugging session's most expensive asset is its **negative knowledge** — the hypotheses already disproven. It's invisible to git, and a context reset destroys it, so the investigation lives in a GitHub issue, not in the conversation. Given an issue number, resume it; given a symptom, duplicate-check (`gh issue list --state all --search "<two or three symptom words>" --json number,title,state` — an open hit is resumed as if its number had been given; a closed hit is referenced from the new issue's Symptoms) then file one: `f=$(mktemp /tmp/n8-debug-new.XXXXXX)`, write the body there (never into the project directory), `gh issue create --label bug --title "<symptom as a sentence>" --body-file "$f"`; add `confirmed` (`gh issue edit 57 --add-label confirmed`, 57 being the number `create` printed) once you have reproduced it once. Angle brackets in this file are prose placeholders; in a pasted command write the number. If the user's report lacks repro steps or when it started, ask before filing — Symptoms is immutable, so it has to be right. Closing rules and the "four Nevers" are in `${CLAUDE_PLUGIN_ROOT}/reference/github.md`.

## The issue as the brain

Write-discipline per section — **update the issue BEFORE acting, not after**: if context resets mid-action, the record shows what was about to happen.

- **Body — rewritten before each experiment.** Read the current body first (`b=$(mktemp /tmp/n8-debug-57-body.XXXXXX); gh issue view 57 --json body --jq .body > "$b"`), truncate at the focus heading and append the new one (`sed -i '' '/^## Current focus/,$d' "$b"` on macOS, `-i` on GNU, then `cat >> "$b"`) so Symptoms is never retyped, write it back with `gh issue edit 57 --body-file "$b"` — a `body.md` in the project directory gets committed by the next `git add -A` — an overwrite from memory is how Symptoms gets lost:
  ```markdown
  ## Symptoms            <- immutable once gathered: what happens, repro steps, when it started
  ## Current focus       <- overwritten each cycle:
  Hypothesis: <falsifiable statement>
  Testing via: <the experiment>
  Expecting: <result if true / if false>
  Next action: <exactly what happens next>
  ```
- **Comments — append-only, timestamped for free, each posted with `gh issue comment <n> --body "..."`:**
  - `Eliminated: <hypothesis> — per <Evidence comment URL>`
  - `Evidence: checked <thing> — found <result> — implies <what>` — carrying `rc=` and the relevant log lines pasted in, because `/tmp` is not the brain; a red/green pair is written `Evidence: red run …` / `Evidence: green run …`
  - `Correction: <experiment> was flawed because <why> — reopens <Eliminated URL>, voids <Evidence URL>` for each reopened elimination, followed by the Eliminated line quoted. `gh issue comment` prints the URL of every comment it posts; keep them, because a URL matches exactly where a retyped quote may not. A Correction is always followed, in the same step, by a Current-focus rewrite naming the reopened hypothesis as Next action.

**Resume after any reset:** `gh issue view <n> --json title,body,comments` — Symptoms say what's broken, Current focus says what was in flight, the Eliminated comments say **what not to retry — unless a later `Correction:` comment reopens them**. Continue from Next action.

## Investigation discipline

- **Hypotheses must be falsifiable.** "There's a race condition somewhere" is not a hypothesis; "the API call completes after unmount, causing a state update on an unmounted component" is — it names the mechanism and what would disprove it.
- **An experiment whose output you discarded proves nothing.** Capture every command an experiment's conclusion rests on:

  ```sh
  log=$(mktemp /tmp/n8-debug-57-throttle.XXXXXX)   # 57 = issue number, throttle = the experiment
  cmd > "$log" 2>&1; rc=$?          # cmd = the experiment; a pipeline needs sh -c 'set -o pipefail; …' or rc is the last stage's
  echo "rc=$rc log=$log"; [ -s "$log" ] || echo "EMPTY OUTPUT"; tail -20 "$log"
  ```

  `mktemp` so no iteration of a bisection overwrites the last — the loop is exactly where a silent failure hides, and the last iteration is not the interesting one. `rc` printed, because variables die at the end of the tool call. Write the issue number and experiment name literally — angle-bracket placeholders parse as redirections if pasted. `tail` unconditionally and the empty check, because a suppressed setup failure exits 0 and makes every later iteration test the *previous* state; reading the log only on failure is blind to that. Before reading any result, assert the experiment changed what you believe it changed — the dependency is in the lockfile diff, the file differs from its copy. The exit code says it ran, not that it worked.
- **When your method turns out to be wrong, re-open what that method eliminated.** A flawed check costs more than the step it ran on: every `Eliminated:` comment it produced is now unproven. Post a correction comment naming which eliminations are back in play — a wrongly eliminated candidate is negative knowledge working *against* you, and it is invisible precisely because the record says it was settled.
- **Prefer the experiment that splits the hypothesis space** — one test that differentiates several candidates beats four that each confirm a favorite.
- **Fix only when all four hold:** you understand the mechanism, you reproduce reliably, you have evidence (not theory), and you've ruled out the alternatives. "I think it might be X" is not grounds to act.
- **A fix that works for reasons you can't explain isn't a fix — it's luck.** Keep the issue open and keep digging until the mechanism is understood; say so honestly if the user wants to stop there.
- Every 30 minutes of a stuck path, ask: *if I started fresh right now, is this still the path I'd take?* Sunk cost drives more bad debugging than missing information does.
- When the bug is in code you wrote: the hardest admission is "I implemented this wrong" — not "requirements were unclear." Check your own change first.

## Closing

An investigation may conclude **works-as-designed** — that's a success, not a failure to find. Close the investigation issue with `--reason "not planned"` and the mechanism + evidence in the closing comment; closing your *own* user-requested investigation this way is the investigator's call and exempt from the "'not planned' is a human's call" Never (which protects other people's issues from unilateral triage).

Otherwise, fix with a **regression test that reproduces the bug**. Prove it red before the fix exists: write the test first and run it in the working tree through the capture snippet — it fails at the bug's assertion, with no worktree needed. If the fix is already written, `git status --short` must list its files (a committed fix makes the sequence below pass falsely); then `git worktree remove --force /tmp/n8-debug-57-redrun 2>/dev/null; git worktree add /tmp/n8-debug-57-redrun HEAD` gives the unfixed tree (`git stash` would leave a fix's *new* files in place); link dependencies (`ln -s "$PWD/node_modules" /tmp/n8-debug-57-redrun/node_modules`, `dotnet restore`, or the stack file's install step); `mkdir -p` the test's directory there and copy only the test file in; run it via `sh -c 'cd /tmp/n8-debug-57-redrun && <test command>'` through the snippet. **The red must be the bug's assertion failing** — `grep -qE "Cannot find module|MODULE_NOT_FOUND|ImportError|No such file" "$log" && echo "NOT A RED: resolution failure"`; a test that fails because it imports a file the fix added proves nothing, exactly as one that passes before the fix proves nothing; write it against the pre-existing entry point. Post `Evidence: red run …`, remove the worktree, run it green in the fixed tree through the same snippet, post `Evidence: green run …`. Then close through the working discipline in `${CLAUDE_PLUGIN_ROOT}/reference/github.md` (evidence in the closing comment: mechanism, fix, test). The Eliminated trail stays in the issue — it's the documentation of why the fix is the right one.
