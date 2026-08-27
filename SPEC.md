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
- **Project invariants**: declared during roadmap in the project CLAUDE.md; exec treats an apparent breach as a blocker; audits check them (unexplained suppressions are findings).
- **Stories**: sized to one session; every AC testable or the story splits; test plan names the specific proving tests. Epic AC patterns: "implemented or closed with the reason", docs-update obligation, invariants clause, tier-by-leverage children.
- **Verify**: changed snapshots/goldens are claims, not results — the diff must be argued correct. Verify offers (never auto-runs) `gh release create --generate-notes` when a closed milestone is shippable.
- **Init**: analyzers/linters wired into the build at scaffold time; SECURITY.md + private vulnerability reporting on public repos (public register for own findings, private channel for outside reporters).
- **`/n8-file`**: quick capture completing the capture → assess → execute ladder.
- **Skill maintenance**: project skills fixed in the same commit as the code change that invalidated them; cleanup audit catches residual drift.
- Deliberately *not* adopted: n8PDF's closed-world label taxonomy (spec's label list kept, severity axis added alongside), its no-milestones model, and per-issue linked branches (`gh issue develop`) — milestone branches remain the unit of work.
