---
name: n8-audit
description: Run project audits in the n8SDLC workflow — security, stability, performance, cleanup, authorization, 508 accessibility, and test coverage. "/n8-audit security" runs one area, "/n8-audit" offers the suite. Uses stack-appropriate tooling (CodeQL, semgrep, dependency audits, fuzzing where applicable), verified findings with a shared severity rubric, fingerprinted idempotent re-runs, then asks which findings to file as GitHub issues. Use whenever the user says "n8-audit", "audit the project", "security review", "accessibility check", or during the final Audit milestone.
argument-hint: "[security | stability | performance | cleanup | authorization | 508 | tests | all]"
---

# /n8-audit — Project Audits

Run one or more audit passes and report what's actually true about the codebase. Audits exist to find problems — an audit that finds nothing should make that credible by showing what it checked, not just declare victory.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` (fingerprints, filing rules), `${CLAUDE_PLUGIN_ROOT}/reference/audit-checklists.md` (the section for each dimension being run — these carry the concern lists), and the stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/` ("Audit tooling" section). Check the Audit milestone description — `/n8-plan` records which areas deserve emphasis for this app. With no argument, offer the suite and let the user pick (defaulting to the emphasized areas plus security).

Scope is **codebase-wide**, not the pending diff — run on demand, typically before a release or when one instance of a problem suggests a whole class.

## Areas

**security · authorization · stability · performance · cleanup · 508 · tests** — each has a concern checklist in `reference/audit-checklists.md`. Also audit **project invariants** (declared in the project's CLAUDE.md n8SDLC section, if any) as part of every run: suppressed warnings, disabled rules without rationale, and invariant drift are findings regardless of dimension.

## The contract (what makes audits comparable)

**Severity rubric** — one scale, applied everywhere and encoded as `sev:*` labels when filing:
- `sev:critical` — exploitable or destructive today with severe impact
- `sev:high` — exploitable, badly wrong, or actively misleading under realistic use today
- `sev:medium` — wrong (or costly) where a clean failure or correct result was owed; bites under growth
- `sev:low` — hardening, defense-in-depth, cosmetic

**Sweep with parallel agents, verify yourself.** For scope beyond a couple of files, fan out Explore agents — one concern per agent, each with a hard cap on findings. Then verify every agent claim before reporting: read the cited code, run the independent check (the checklists name them — trial-delete for dead code, computed contrast ratios, gate tests). Agent grep results are leads; reporting verified findings is what separates an audit from a bare grep.

**Evidence bar:** report a finding only if you can state a concrete failure — the input or situation that reaches it and what happens, including the path from the public entry point where relevant. "Could break" without a path is noise, and noise filed as issues is worse than a missed `sev:low`.

**Report structure** — always these three sections:
1. **Punch list**, grouped by severity (hot-path findings first for performance). Cap at the most impactful ≤15 unless the surface truly warrants more; footnote lower-priority items seen. Per finding:
   ```
   **[sev] file/path:NN — short title**
   - What: one line
   - Why it matters: one line, concrete consequence   (perf: "Cost shape:" · stability: "Failure mode:" · 508: add "WCAG/508:" criterion)
   - Fix: one line, concrete — cite an existing in-repo pattern when one applies
   ```
2. **What I checked and found clean** — specific ("ran the secret-shape regex over src/ (3,200 files); no matches outside documented dev config"), so clean areas are credible.
3. **Out of scope** — what this audit deliberately didn't cover, pointing at the adjacent audit that does.

Beyond findings, recommend the **permanent version** of anything that recurred: analyzers/linters wired into the build (with a rationale-per-rule suppression file for accepted noise), and executable gates — tests that enumerate the surface and fail on drift (e.g. a route-enumeration test asserting every endpoint carries an explicit auth decision). A gate test outlives any audit report.

## Findings → ask → file (fingerprinted)

1. **Report first** (structure above). Audits write no source and open no PRs — even a one-line fix gets filed; the human decides what is worked.
2. **Ask which findings to file.** For approved ones, follow `reference/github.md` filing rules: bulk-load prior audit issues, **three-way fingerprint dedupe** (open → comment new evidence; closed → reopen as regression; absent → file). New issues: specific titles ("PngDecoder: stride multiplied before bounds check", not "potential overflow in image handling"), `--body-file`, labels = audit area + `sev:*`, body = what/where/why-it-matters/evidence/suggested-fix + fingerprint, assigned to the **Audit milestone** (or an earlier open milestone if the user prefers the fix sooner). Wire dependencies if fixes must be ordered.
3. Fixes flow through the normal loop: `/n8-exec` the Audit milestone, then `/n8-verify` closes it.

First run on a project? Start narrow (one area, or one subsystem) — it's easier to tune the concern lists against ten issues than a hundred.
