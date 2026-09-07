---
name: n8-exec
description: Execute planned n8SDLC milestones autonomously — "/n8-exec M0" implements one milestone, "/n8-exec M1,M2" several in order, "/n8-exec *" all planned-but-unexecuted milestones. Works branch-per-milestone with a PR closing all stories, writes and passes the planned tests, logs every decision, and skips-and-marks blocked instead of asking questions. Use whenever the user says "n8-exec", "execute the milestone", "implement M1", or wants planned milestones built.
argument-hint: "M0 | M1,M2 | *"
---

# /n8-exec — Milestone Execution

Implement everything in the targeted milestones exactly as planned, autonomously. The user may be away for the entire run — plans were built so no questions are needed, and needing one anyway is a planning failure worth logging honestly.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md`, `${CLAUDE_PLUGIN_ROOT}/reference/state.md`, and the relevant stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/`.

**Capture command output, and verify the effect — not the exit code.** These return success and do nothing: a command whose output was suppressed, a flag the host doesn't support (it may fall back rather than error), a substitution whose pattern didn't match, a suite that collected zero tests. In an autonomous run the false success becomes the next step's input and compounds silently.

**Capture** every command that changes state — install, build, test, scripted edit, commit, push, merge — or whose output a later step uses. A bare read you are looking at right now needs no ceremony.

```sh
log=$(mktemp /tmp/n8-41-install.XXXXXX)        # 41 = story number, install = the verb
cmd > "$log" 2>&1; rc=$?
echo "rc=$rc log=$log"; [ -s "$log" ] || echo "EMPTY OUTPUT"; tail -20 "$log"
```

Each part is load-bearing:
- **`mktemp`** — unique per invocation, so a retry never truncates the previous attempt and two stories running the same verb never collide; the path is printed so the full log can be read later. Use it for snapshots too (`before=$(mktemp /tmp/n8-41-cfg.XXXXXX); cp <file> "$before"`) — a fixed snapshot name is overwritten by the next file's snapshot. Never glob for logs (`ls /tmp/n8-41-*`): zsh aborts that command on a no-match glob. Write the story number and verb literally — angle-bracket placeholders parse as redirections if pasted.
- **`rc` printed, not just stored** — shell variables and `set -o` options die at the end of every tool call. The number in the tool output is the record.
- **`tail -20` unconditionally, and the empty-output check** — never gate the read on `rc`. The failures this rule exists for exit 0; some print a tell-tale line (`up to date`, `0 tests`), some print nothing at all, and a snippet that reads the log only on failure is blind to both. `EMPTY OUTPUT` is expected from `sed -i`, `cp`, `mv` and `git add`; it is the alarm for install, build, test and push.
- A pipeline (`cmd 2>&1 | tee "$log" | tail -20`) returns `tail`'s status unless `set -o pipefail` is set in the **same** invocation; it is off in every fresh shell. Prefer the redirect form.

**Then assert the effect** — `rc=0` says the command ran; each block below asks what it did. Every block is one tool call, self-contained, because variables die between calls: `[ "" -eq 0 ]` is *true* in zsh, so a gate on an `rc` from an earlier call passes silently. Any alarm line a block prints ends the story's step: fix under Rule 3 if it is a blocker-class problem, otherwise re-run once with the log open, and if it recurs treat the story as blocked (§3).

*A scripted substitution* (captured like any state change). Snapshot first; anchor the pattern (`^port = 80$`, not `port = 80` — unanchored, `admin_port = 8080` becomes `admin_port = 808180`); after, two checks — `cmp` catches a pattern that never matched (`sed` exits 0 and greping for the same typo finds nothing), and re-running sed's own pattern catches a missing `/g` without the false alarm a plain `grep` gives when the old value is a substring of a neighbour. `sed -i` is `-i ''` on BSD/macOS and `-i` on GNU; the stack file says which. The last line prints `0` and exits 1 on success — read the number, not the exit.

```sh
before=$(mktemp /tmp/n8-41-cfg.XXXXXX); cp app.cfg "$before"
log=$(mktemp /tmp/n8-41-sed.XXXXXX); sed -i '' 's/^port = 80$/port = 8081/' app.cfg > "$log" 2>&1; rc=$?
echo "rc=$rc"; cmp -s "$before" app.cfg && echo "NOTHING CHANGED"
sed -n '/^port = 80$/p' app.cfg | grep -c .          # must print 0
```

*A dependency install.* A first install has no lockfile yet, so the snapshot may be empty; an install that leaves no lockfile at all is its own alarm. `git diff` would miss an untracked first lockfile and pass one that was already dirty. The pattern matches npm's `"pkg":`, yarn's `pkg@`, pnpm's `  pkg:` and Cargo's `name = "pkg"`, not `pkg-es`; the lockfile name comes from the stack file.

```sh
lock=package-lock.json                                          # yarn.lock / pnpm-lock.yaml / Cargo.lock per stack
before=$(mktemp /tmp/n8-41-lock.XXXXXX); cp "$lock" "$before" 2>/dev/null || : > "$before"
log=$(mktemp /tmp/n8-41-install.XXXXXX); npm install left-pad > "$log" 2>&1; rc=$?
echo "rc=$rc log=$log"; [ -s "$log" ] || echo "EMPTY OUTPUT"; tail -20 "$log"
[ -f "$lock" ] || echo "NO LOCKFILE"
cmp -s "$before" "$lock" && echo "NOTHING CHANGED"
grep -qE -- '(^|[" /=])left-pad["@:]' "$lock" || echo "PKG NOT IN LOCKFILE"
```

*A test run.* The count line is often above the last 20 lines, and a suite that collected nothing exits 0 — so assert **both** `rc=0` and a non-zero passed count with no failed count, in the same call as the run. The regex covers jest (`Tests:` with a colon), vitest, pytest and dotnet's vstest runner; the stack file names other runners' lines.

```sh
log=$(mktemp /tmp/n8-41-test.XXXXXX); npm test > "$log" 2>&1; rc=$?
echo "rc=$rc log=$log"; [ -s "$log" ] || echo "EMPTY OUTPUT"; tail -20 "$log"
[ "${rc:-99}" -eq 0 ] || echo "SUITE FAILED rc=$rc"
grep -E 'Tests:? +.*[1-9][0-9]* passed|[1-9][0-9]* passed in|Passed: *[1-9]' "$log" || echo "NO PASSING COUNT"
grep -E '[1-9][0-9]* failed|Failed: *[1-9]' "$log" && echo "FAILURES IN SUITE"
```

*A merge or a flag.* Re-read the state — `gh pr view 41 --json state,mergeCommit`; the command's own success line is not evidence.

When a log is the evidence for a completion comment or a filed issue, paste the relevant lines *into* the comment — `/tmp` is volatile. When you discover your method was wrong, re-check what it already produced; catching the bug and repairing its history are separate obligations.

## 1. Preconditions (hard stops)

Resolve targets (`M0`, `M1,M2`, or `*` = all planned, unexecuted milestones — matching by `M<N>:` prefix). Under `*`, an open milestone skipped for having no stories must be **reported, not silently dropped** ("skipping M3 — unplanned; run /n8-plan M3"; the Audit milestone is exempt and expected to be storyless). Then verify **before touching any code**:

- **Planned:** every targeted milestone has stories. If not → tell the user which milestone is unplanned, suggest `/n8-plan <M>`, and stop.
- **In order:** every earlier milestone is already executed (its stories closed / milestone PR merged). If not → tell the user which milestone must run first and stop. Milestones build on each other; out-of-order execution produces integration debt.
- **Not stale:** run a drift check on the targeted milestones — plans age, and executing a stale plan faithfully builds the wrong thing. Check (a) unreconciled `## Ad-hoc` entries in `.n8/decisions.md` naming these milestones or their subject areas, and (b) spot-check each story/subtask's concrete claims (files, libraries, providers) against the current codebase. Pure implementation-detail staleness (a renamed file, a moved module) → adjust inline, log the correction, proceed. Anything touching **AC or story validity** (e.g. auth provider swapped since planning) → hard stop for that milestone: report the drift and recommend `/n8-replan <M>`.

## 2. Per milestone

1. **Branch:** `milestone/m<N>-short-name` off up-to-date `main`.
2. **Order stories** by dependencies (native `blocked_by` plus body-line fallbacks). Within a story, follow its subtasks — they are the prescribed *how*; deviating from a subtask is a decision (log it, with why).
3. **Per story:**
   - Read it fully first (`gh issue view <n> --json title,body,comments` — the plain `--comments` form has printed nothing outside a TTY on some gh versions), then **comment the plan before the code**: 2–5 bullets — approach and expected files. If AC are missing, derive them into this comment as a checklist; the definition of done gets written down before work starts.
   - Implement to satisfy every acceptance criterion; respect the project invariants in CLAUDE.md's n8SDLC section — a story that appears to require breaching one is a blocker (that's a conversation, not a judgment call). The story's **Claude's Discretion** section is the inverse: decisions the user explicitly delegated — improvise there freely and log the choice.
   - **You WILL discover work the plan missed — this is normal. What you may do about it depends on where it sits:**
     - *Inside this story's scope* (in code the story touches, needed for it to be correct/secure/complete): **Rule 1** — fix bugs (broken behavior, logic errors, races) + add a regression test. **Rule 2** — add missing critical functionality (input validation, error handling, authz on protected routes — requirements for basic correctness, not features). **Rule 3** — fix blockers (broken import, missing dep, build config). All three: fix automatically, log to the decision ledger with the rule tag.
     - **Rule 4 — architectural changes stop the story**: new table (not a new column), schema/PK changes, swapping libraries, changing API contracts, new infrastructure. That's the blocker path. **Genuinely unsure which rule applies → Rule 4.**
     - *Outside this story's scope*: a separate problem gets its own issue (`--label needs-triage`, body starting "Discovered while working #N."), cross-referenced in a comment — never fixed inline. That's silent scope creep.
   - **Auth gates are checkpoints, not failures:** a 401/"invalid API key"/login prompt means label the story `blocked` + `needs-owner-action` asking for exactly the credential needed — then, once provided, *you* run the automation. Secrets come from the user; automation comes from you. Never ask the user to run commands you can run yourself.
   - Write the tests named in the story's test plan and run the **full** suite — a story is done only when all tests pass, not just its own. Never finish by weakening the gate (suppressing warnings, skipping tests).
   - Commit per story with `Refs #N` in the body — when two stories change the same file inseparably, one commit may carry both `Refs` lines, noted in both completion comments (never `Fixes`/`Closes` in a commit — on the milestone branch they do nothing, and then the squash merge carries every commit body onto `main`, where they fire and close whatever they name, finished or not), push, then check off the AC boxes and comment completion **with evidence**: branch @ short SHA, what changed per AC, exact test results. Push before any close — a closed issue with no code on the remote is a lie.
4. **Log decisions as you go** to `.n8/decisions.md` (format in `reference/state.md`): any choice between alternatives, assumption, or plan deviation, with the why and the issue number. During autonomous runs this log is the user's only window into your judgment — err toward logging.
5. **PR:** `gh pr create --base main --title "<milestone title>" --body-file <f>` from the milestone branch (captured like every other state-changing command, as is the merge below), body `Closes #N` for every **completed** story (never partial ones). Then the gate:
   - `ls .github/workflows/ 2>/dev/null | grep -cE '\.ya?ml$'` — zero → no CI: run the full local suite as the gate, merge, and say so in the report. Non-zero → CI is configured (`.yaml` counts; a glob on `*.yml` misses it and aborts under zsh).
   - From the milestone branch's checkout, run the polling loop in `reference/github.md` → *Waiting on CI* — one tool call is one tick of up to ~100 s (22 s when checks are already done), and it ends by printing the check buckets as a set. Read the set, never `$?` (with `--json`, `gh` exits 0 on a red check; a typo'd PR number exits 1 — either way the code tells you nothing): all `pass`/`skipping` → merge; any `fail` → red; any `pending` → tick again; any `cancel` → re-run the workflow (`gh run rerun $(gh pr checks 41 --json link --jq '.[0].link | capture("/runs/(?<id>[0-9]+)").id')`), it is not a fix.
   - `[]` or `no checks reported` on the **third consecutive tick** (an empty set runs the full loop, so ≈5 minutes) with workflow files present → blocker "workflows exist but no check ran on this PR": CI is broken, or nothing triggers on pull requests, and the user says which. Never fall back to local tests in that case. A tick whose output shows only the first timestamp was killed by the tool timeout and doesn't count — if that happens twice running, pass `timeout: 300000` to the Bash tool for the ticks. Count ticks; the printed timestamps corroborate the clock.
   - Red: fix and push, at most **three** attempts; the fourth failure is a blocker. Still pending after ticks totalling **30 minutes** by their printed timestamps: blocker.
   - `gh pr merge <n> --squash --delete-branch`. Refused for a required review or protection rule → `blocked` + `needs-owner-action` naming the rule. Then assert `gh pr view <n> --json state,mergeCommit` shows `MERGED` with a commit, and `git fetch origin && git log origin/main -20 --format=%s | grep -qF "(#<n>)"` — a squash produces a new SHA, so match the PR number in the subject, not any SHA you pushed; `-20` because other PRs may have landed after yours.
   - The merge to `main` is the run's authorized irreversible step; §3's "irreversible steps" clause is about everything *else*.
   - **After the merge**, `gh issue view <n> --json state` on every story touched but not finished — GitHub closes issues *linked* to the PR on merge — PR-body keywords, the issue's Development-sidebar link to the branch, or a `Closes` that slipped into a commit body and rode the squash onto `main` — whether or not the work was finished; reopen any casualty with "Reopened: closed by the merge, not by completion. <what is left>".
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
- Next step: verification of the executed targets — or, if blockers exist, say so and ask the user to answer them (comment on the issues or reply here), in which case the Next line is `/n8-exec` for the affected milestones instead.

> ➡ Next: /n8-verify M1

**End on the Next line.** The reply's final line is `➡ Next: /n8-verify M1` (an example — substitute the real command and arguments): one recommended command, alone on the line, nothing after it. The why and any alternatives go in the sentence above it, never appended to it. Claude Code's prompt suggestion reads the transcript; a bare, final, unambiguous command is what lets the user accept it with Tab.
