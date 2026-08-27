# n8SDLC — Design Decisions

Decisions made 2026-08-27 while designing this skill suite. This is the record of *why* the skills work the way they do; change a decision here when changing the corresponding behavior.

## Packaging
- **Claude Code plugin** (`n8SDLC/` is the plugin; this repo is also its marketplace). Install once, `/n8-*` available in every project, updates propagate.

## Planning model
- **GitHub is the source of truth.** Epic → story → subtask via **native sub-issues**; native `blocked_by` dependencies. Body-text fallbacks (`Parent: #N`, `Blocked by: #N`) when the APIs are unavailable.
- Stories describe the **what** (AC + test plan); subtasks the **how** (only when prescribing is warranted).
- `.n8/` (tracked) holds only what doesn't fit GitHub: `config.yml` (stack, wiki choice, deployment/CI answers, context7), `decisions.md` (append-only), `memory/`.
- Milestones: `M0: Infrastructure` always first; CI early (usually M1); `M<N>: Audit` always last. Phases + definition of done live in the milestone description.
- Duplicate check before every issue; related-but-different → ask (extend AC vs new issue).

## Execution
- **Branch + PR per milestone**; commit per story; PR body `Closes #N` per story; merge gated on CI when it exists.
- Preconditions are hard stops: unplanned milestone, or earlier milestone unexecuted.
- Blockers (legitimately unsure + high cost of wrong): **skip, mark `blocked`, continue** with non-dependent work; surface all at the end. Low-cost calls are made and logged, not asked.
- All decisions logged to `.n8/decisions.md` and displayed after execution.

## Drift and replanning
- Ad-hoc changes between planning and execution are captured in a **drift ledger**: `## Ad-hoc` entries in `.n8/decisions.md`, written by any agent session via a CLAUDE.md instruction that `/n8-init` installs.
- Detection runs at **exec preflight** (minor implementation staleness → fix inline and log; AC/story-level drift → hard stop, recommend replan) and in **/n8-stat** (cheap ledger scan only).
- **/n8-replan** (targets like exec; default = all planned-but-unexecuted milestones) gathers evidence from the ledger **plus git history since planning plus codebase spot-checks**, then **proposes a full change set and applies on approval** (AC rewrites called out; epic-level AC changes flagged prominently). Executed milestones are never rewritten — drift affecting shipped work becomes new stories.
- Reconciled ledger entries are stamped (`— reconciled by /n8-replan <date>`) so they stop flagging.

## Verification
- Milestone args + wildcard, like exec; no args = executed-but-unverified.
- `--auto` (default) verifies all the agent can; `--testplan` yields manual steps. Un-verifiable items always become manual steps needing user approval.
- Failures → `bug` issues in the same milestone (`confirmed` = reproduced), offer immediate re-exec.
- **Verify closes milestones** — exec never does. Verification is part of done.

## Audits
- Areas: security, stability, performance, cleanup, authorization, 508.
- **Report first, then ask which findings to file** (into the Audit milestone by default).
- Tooling: GitHub-native (Dependabot, CodeQL, secret scanning + push protection, branch rulesets) + semgrep, fuzzing where applicable, and app-appropriate OSS tools.
- `/n8-plan`'s whole-project analysis records per-app audit emphases in the Audit milestone.

## Wiki
- Optional; opt-out recorded in config and respected everywhere.
- Reconcile pass **applies directly, then summarizes**.
- Voice: human, informational, honest by default — never oversell.

## Init
- User supplies the GitHub remote (init does not create repos).
- First-class stacks: .NET/C#, TypeScript/Node, Python, Unity, Dart/Flutter; generic path for others.
- Security features on public repos: Dependabot, CodeQL, secret scanning + push protection, branch rulesets. Private repos: honest note about what's unavailable.
- context7 MCP: strongly recommended, never required.

## Labels
Trimmed middle path (decided 2026-08-27 after the label-philosophy discussion): epic, feature, security, performance, bug, documentation, help wanted, question, confirmed, subtask, `blocked` (exec's skip-and-continue), `needs-triage` (quick capture), and `sev:critical/high/medium/low` (findings only — `feature` never carries severity: an absent capability isn't a measurable failure).
- **Dropped from the original spec list:** `duplicate`, `invalid`, `wontfix` — superseded by GitHub close reasons, which travel with the closed state; "not planned" closes remain a human-approved call.
- Rejected: n8PDF's full closed-world taxonomy (kept `bug`/`question`/`help wanted` for community conventions and familiarity).
- `confirmed` = bug reproduced.

## Naming
- Everything under `/n8-` including `/n8-audit` (spec's `/audit` renamed for namespace consistency).

## Conventions absorbed from prior projects (2026-08-27 assessment of AutoNate + n8PDF)
- **Fingerprints**: repeatable-process issues (audits) end with `<!-- fingerprint: rule|path|symbol -->`; re-runs bulk-load prior issues and three-way dedupe (open → comment, closed → reopen as regression, absent → file).
- **Working discipline** (all in reference/github.md): plan-comment on the issue before code; `Refs #N` never closing keywords in commits (no-ops off default branch); post-merge issue-state check + reopen for partial work (linked issues auto-close on merge); push-before-close; closing comments carry evidence (branch@SHA, AC checked, exact test counts); discovered work is filed (`needs-triage`, "Discovered while working #N"), never fixed inline; the four Nevers (no unverified closes, no bulk closes, no touching others' issues, no self-initiated "not planned").
- **Native gh flags** (`--parent`, `--add-blocked-by`, gh ≥ 2.94.0 with preflight warn) preferred over raw API; `--body-file` always; capability-probe rather than assume (issue types are org-only, unused).
- **Audit contract** (n8-audit + reference/audit-checklists.md): one severity rubric mapped to `sev:*`; parallel one-concern-per-agent sweeps with self-verification before reporting; evidence bar ("state the concrete failure and the path to it, or don't file"); three-section report (punch list ≤15 / checked-and-clean / out-of-scope); per-dimension checklists including the dead-code trial-delete rule, hot-path inventory (`.n8/memory/hot-paths.md`), computed-not-eyeballed contrast, WCAG criterion per 508 finding; recommend permanent versions of recurring concerns (analyzers with rationale'd suppressions, executable gate tests); **tests** added as a seventh audit dimension.
- **Project invariants** (strengthened 2026-08-27): declared during roadmap in the project CLAUDE.md — a handful, not a constitution — each marked **test-enforced** (an executable guard test/build setting, planned into M0/CI; deliberate breaches must touch the guard in the diff) or **honor-system** (audited by hand). Exec treats an apparent breach as a blocker; audits verify guards are unweakened. Amendable: changing an invariant is a user decision logged as an ad-hoc ledger entry → `/n8-replan` picks up the downstream drift.
- **Stories**: sized to one session; every AC testable or the story splits; test plan names the specific proving tests. Epic AC patterns: "implemented or closed with the reason", docs-update obligation, invariants clause, tier-by-leverage children.
- **Verify**: changed snapshots/goldens are claims, not results — the diff must be argued correct. Verify suggests `/n8-release` when a closed milestone is shippable.

## Releases (decided 2026-08-27)
- Dedicated **/n8-release** command, **tag-on-main model**: milestone PRs merge to main continuously; a release tags a verified commit on main (never a gitflow-style gated main — rejected for integration debt, broken `Closes #N`, and conflicts with the ruleset/verify/drift machinery). Dev/stage deploy from main merges; production deploys on release tags where CI defines it.
- Hard preconditions: contributing milestones verified-closed, CI green on main, no open confirmed bugs. Version files bumped to match the tag. Explicit user confirmation before tagging — releases never run unasked. Tag-triggered workflows are watched to completion; a failed deploy is reported, not hidden.
- **Init**: analyzers/linters wired into the build at scaffold time; SECURITY.md + private vulnerability reporting on public repos (private channel for outside reporters, never public issues).

## Conventions absorbed from HonestArcade (2026-08-27 assessment)
- **gh mechanics**: the *why* behind `--body-file` (heredocs mangle backticks/checklists; `--body-file -` is the sanctioned inline form); `gh pr comment --edit-last --create-if-none` for idempotent workflow comments; the race-proof CI-wait loop (`length > 1 and all(.bucket != "pending")`); habitual gh-output truncation; templates are for humans, skills write sections directly.
- **Actions lessons** (reference/github.md): `GITHUB_TOKEN` cannot write repo variables → commit such config; intent-matched concurrency groups; least-privilege permissions; CI defined once via `workflow_call`; `$GITHUB_STEP_SUMMARY` reporting; why-comments on load-bearing steps; shared-preview rules (expand-and-contract migrations, never share secrets between preview and production, green CI ≠ feature working).
- **Planning**: vertical slicing as an explicit rule; outcome-verb titles; the filing approval gate presents a compact `title — labels — outcome` table before batch-creating; **`spike` label** for time-boxed investigations closing with a decision comment + follow-up stories.
- **Labels**: **`area:*` axis adopted** — generated by init from the project's directory structure, exactly one per issue, recorded in config. **`needs-owner-action` adopted** — rides with `blocked` when the wait is on the user; /n8-stat lists these first. `size:*` labels **not** adopted (sizing stays prose: one session per story).
- **Init**: `blank_issues_enabled: false` (was true) — every issue arrives typed.
- **Dedup**: closed-match nuance — regression reopens/references; refiling a "not planned" close needs the user's say-so.
- **Rejected**: multi-repo support (user decision: one project, one repo — cross-repo linking rules, `gh label clone` propagation not adopted); Projects boards (still unused everywhere, labels+milestones suffice).
- Validations observed (no change needed): never-closed milestones ← verify-closes rule; convention drift between repos ← plugin packaging; one-issue-one-PR violations ← milestone-PR model; ad-hoc unfingerprinted audit filing ← fingerprint register.

## Ideas absorbed from Kata (2026-08-27 assessment — gem-mining only, complexity explicitly rejected)
- **Must-haves contract** (the core steal): stories carry a goal-backward block (user-observable truths → artifacts → key links); verify cashes it with the three-level check (exists/substantive/wired → VERIFIED/ORPHANED/STUB/MISSING) and never trusts closing-comment claims. "Task completion ≠ goal achievement."
- **Demo field**: concrete ~60-second user script on stories a human will verify; NOT mandatory — agent-verifiable stories omit it and `--auto` derives checks from AC/must-haves (user decision). "curl returns 200" is inspection; "tests pass" is a gate — neither is a demo.
- **Conversational UAT protocol** in verify: user performs UAT (agent prepares environment, never demos-and-reports); one test at a time, "here's what should happen — does it?"; severity inferred from the user's words, never asked; no fixing mid-session; journey-ordered scenarios seeded from Demo fields.
- **Deviation taxonomy** in exec: in-scope Rule 1 bugs / Rule 2 missing-critical / Rule 3 blockers auto-fix-and-log; Rule 4 architectural → blocker (unsure → Rule 4); out-of-scope still files-not-fixes (n8PDF rule preserved). Auth gates = `blocked`+`needs-owner-action` checkpoint; secrets from user, automation from agent.
- **Integration audit dimension**: existence ≠ integration — provides/consumes map, CONNECTED/IMPORTED_NOT_USED/ORPHANED, key_links cross-check.
- **Planning**: gray areas derived from the shape of the thing (SEE/CALL/RUN/ORGANIZED), founder/builder role split, deferred-ideas capture, **Claude's Discretion** section (recorded delegation = where exec may improvise); pre-filing self-check (key links owned, truths user-observable, scope backstops).
- **/n8-map** (new skill): brownfield mapping — four parallel agents write stack/architecture/conventions/concerns directly to the wiki (consumer-contract prompts: paths not descriptions, prescriptive, no temporal language); concerns → triaged issues; freshness = stamped commit SHA, not a staleness index.
- **/n8-debug** (new skill): GitHub issue as the debugging brain — body overwritten before each action (Current focus), comments append-only (Evidence / Eliminated); falsifiable hypotheses; four-condition act gate; "a fix you can't explain is luck."
- **Rejected**: all `.planning/` file state, phase numbering/doctor/migration, template overrides, model profiles, shadow issue system, worktree orchestration, agent-teams brainstorm machinery, quick-task second pipeline. Kata's one good spine — separate the agent that judges from the agent that did the work — is adopted as prompt text, not as machinery.

## Security-finding routing (decided 2026-08-27)
- **Init-time user choice**, `security_findings: issues | advisories` in `.n8/config.yml` (asked only on public repos — private-repo issues are already maintainer-only):
  - `issues` — public register under the `security` label; full milestone/fingerprint integration. Right for libraries/tools.
  - `advisories` — self-found security findings become **draft security advisories** (maintainer-only until published; the object GitHub's private vulnerability reporting feeds). Right for deployed services, where an open sev:high public issue advertises an exploit against production. Advisories carry the fingerprint, count toward the Audit milestone's done, and on fix are published plus a filed-and-closed public issue for register/dedupe continuity.
- Per-issue/per-label privacy on public-repo issues does not exist on GitHub — advisories are the only maintainer-only surface, which is why this is an object choice, not a label choice.
- Universal resolution rule: an accepted vulnerability is fixed with a regression test that builds the attack.
- **`/n8-file`**: quick capture completing the capture → assess → execute ladder.
- **Skill maintenance**: project skills fixed in the same commit as the code change that invalidated them; cleanup audit catches residual drift.
- Deliberately *not* adopted: n8PDF's closed-world label taxonomy (spec's label list kept, severity axis added alongside), its no-milestones model, and per-issue linked branches (`gh issue develop`) — milestone branches remain the unit of work.
