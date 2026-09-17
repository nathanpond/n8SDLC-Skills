---
name: n8-audit
description: Run project audits in the n8SDLC workflow — security, stability, performance, cleanup, authorization, 508 accessibility, test coverage, integration wiring, and documents-against-code. "/n8-audit security" runs one area, "/n8-audit" offers the suite. Uses stack-appropriate tooling (CodeQL, semgrep, dependency audits, fuzzing where applicable), verified findings with a shared severity rubric, fingerprinted idempotent re-runs, then asks which findings to file as GitHub issues. Use whenever the user says "n8-audit", "audit the project", "security review", "accessibility check", or during the final Audit milestone.
argument-hint: "[security | stability | performance | cleanup | authorization | 508 | tests | integration | docs | all]"
---

# /n8-audit — Project Audits

Run one or more audit passes and report what's actually true about the codebase. Audits exist to find problems — an audit that finds nothing should make that credible by showing what it checked, not just declare victory.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` (fingerprints, filing rules), `${CLAUDE_PLUGIN_ROOT}/reference/audit-checklists.md` (the section for each dimension being run — these carry the concern lists), and the stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/` ("Audit tooling" section). Check the Audit milestone description — `/n8-plan` records which areas deserve emphasis for this app. With no argument, offer the suite and let the user pick (defaulting to the emphasized areas plus security).

Set `R=$(gh repo view --json nameWithOwner --jq .nameWithOwner)` once; every `$R` below and in the checklists uses it. Scope is **codebase-wide**, not the pending diff — run on demand, typically before a release or when one instance of a problem suggests a whole class.

## Areas

**security · authorization · stability · performance · cleanup · 508 · tests · integration · docs** — each has a concern checklist in `reference/audit-checklists.md`. `docs` audits the project's load-bearing prose — project skills, the wiki, `CLAUDE.md`, `.n8/memory/`, README/CONTRIBUTING and `docs/` — against what the code actually does; the checklist carries the reasoning. Its cold follow uses a `general-purpose` subagent (never `fork`, which inherits this session's context) in a discarded worktree, the one place an audit writes source. Also audit **project invariants** (declared in the project's CLAUDE.md n8SDLC section, if any) as part of every run: for test-enforced invariants, verify the guard test still exists, still runs, and hasn't been weakened or skipped; honor-system invariants get checked by hand. Suppressed warnings, disabled rules without rationale, and invariant drift are findings regardless of dimension. So are **open Dependabot PRs**, listed on every run: `gh pr list --author app/dependabot --state open --json number,title,createdAt,statusCheckRollup`. Each is a punch-list line whose fix is `merge #N` when its checks are green or "investigate red checks" when not — the audit merges nothing, and these are reported, never filed, since the PR is already the tracking artifact. Severity by content: a security update `sev:high`, a major bump of an action in the merge gate `sev:medium`, otherwise `sev:low`. An untriaged pile of these is how a stale pin stays stale after the bot has already found it.

## The contract (what makes audits comparable)

**Severity rubric** — one scale, applied everywhere and encoded as `sev:*` labels when filing:
- `sev:critical` — exploitable or destructive today with severe impact
- `sev:high` — exploitable, badly wrong, or actively misleading under realistic use today
- `sev:medium` — wrong (or costly) where a clean failure or correct result was owed; bites under growth
- `sev:low` — hardening, defense-in-depth, cosmetic

**Sweep with parallel agents, verify yourself.** For scope beyond a couple of files, fan out Explore agents — one concern per agent, each with a hard cap on findings (the docs cold follow is the exception: it needs an agent that can write). Then verify every agent claim before reporting: read the cited code, run the independent check (the checklists name them — trial-delete for dead code, computed contrast ratios, gate tests). Agent grep results are leads; reporting verified findings is what separates an audit from a bare grep.

**Evidence bar:** report a finding only if you can state a concrete failure — the input or situation that reaches it and what happens, including the path from the public entry point where relevant. "Could break" without a path is noise, and noise filed as issues is worse than a missed `sev:low`.

**Report structure** — always these three sections:
1. **Punch list**, grouped by severity (hot-path findings first for performance). Cap at the most impactful ≤15 unless the surface truly warrants more; footnote lower-priority items seen. Per finding:
   ```
   **[sev] file/path:NN — short title**        (docs findings cite `file/path › <heading or step N>` instead of `:NN` — a line number in a filed issue rots the moment the document is edited)
   - What: one line
   - Why it matters: one line, concrete consequence   (perf: "Cost shape:" · stability: "Failure mode:" · 508: add "WCAG/508:" criterion · docs: "Executed as:" — what a reader following this would do wrong)
   - Fix: one line, concrete — cite an existing in-repo pattern when one applies, after checking it against open findings the way the docs area checks exemplars
   ```
2. **What I checked and found clean** — specific ("ran the secret-shape regex over src/ (3,200 files); no matches outside documented dev config"), so clean areas are credible.
3. **Out of scope** — what this audit deliberately didn't cover, pointing at the adjacent audit that does.

Beyond findings, recommend the **permanent version** of anything that recurred: analyzers/linters wired into the build (with a rationale-per-rule suppression file for accepted noise), and executable gates — tests that enumerate the surface and fail on drift (e.g. a route-enumeration test asserting every endpoint carries an explicit auth decision). A gate test outlives any audit report.

## Findings → ask → file (fingerprinted)

1. **Report first** (structure above). Audits write no source and open no PRs — even a one-line fix gets filed; the human decides what is worked.
2. **Ask which findings to file.** For approved ones, follow `reference/github.md` filing rules: bulk-load prior audit issues, **three-way fingerprint dedupe** (open → comment new evidence; closed → reopen as regression; absent → file). New issues: specific titles ("PngDecoder: stride multiplied before bounds check", not "potential overflow in image handling"), `--body-file`, labels = `sev:*` plus the **closest baseline label** (`security` for security and authorization, `performance`, `bug` for stability/integration/tests/cleanup defects, `documentation` for the docs area, `508` findings carry `bug` plus the WCAG criterion in the body) — there are deliberately no per-area audit labels; the audit area travels in the fingerprint's rule-id and the report. Body = what/where/why-it-matters/evidence/suggested-fix + fingerprint, assigned to the **Audit milestone** (or an earlier open milestone if the user prefers the fix sooner). Wire dependencies if fixes must be ordered.

   **Security-finding routing:** check `security_findings` in `.n8/config.yml`. `issues` (default) → file as above. `advisories` → approved `security`-labeled findings become **draft security advisories** instead (`gh api -X POST repos/$R/security-advisories` with summary, description, severity) — maintainer-only until published. Put the fingerprint in the advisory description and dedupe against existing advisories (`gh api repos/$R/security-advisories`) as well as the issue register. Advisories live outside milestones, so list the open ones in the report and note them in the Audit milestone description — they are part of its definition of done. When a fix lands, publish the advisory **and file-and-close a public issue carrying the fingerprint**, so the register stays continuous and future re-runs dedupe correctly. Non-security findings route to issues regardless of this setting.
3. Fixes flow through the normal loop: `/n8-exec` the Audit milestone, then `/n8-verify` closes it. After filing, end the reply on the next step — another audit area if the suite is unfinished, otherwise executing the Audit milestone:

   > ➡ Next: /n8-exec M6

   **End on the Next line.** The reply's final line is `➡ Next: /n8-exec M6` (an example — substitute the real command and arguments): one recommended command, alone on the line, nothing after it. The why and any alternatives go in the sentence above it, never appended to it. Claude Code's prompt suggestion reads the transcript; a bare, final, unambiguous command is what lets the user accept it with Tab.

First run on a project? Start narrow (one area, or one subsystem) — it's easier to tune the concern lists against ten issues than a hundred.
