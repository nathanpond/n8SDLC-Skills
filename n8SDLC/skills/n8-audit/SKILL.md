---
name: n8-audit
description: Run project audits in the n8SDLC workflow — security, stability, performance, cleanup, authorization, and 508 accessibility. "/n8-audit security" runs one area, "/n8-audit" offers the suite. Uses stack-appropriate tooling (CodeQL, semgrep, dependency audits, fuzzing where applicable), reports findings by severity, then asks which to file as GitHub issues. Use whenever the user says "n8-audit", "audit the project", "security review", "accessibility check", or during the final Audit milestone.
argument-hint: "[security | stability | performance | cleanup | authorization | 508 | all]"
---

# /n8-audit — Project Audits

Run one or more audit passes and report what's actually true about the codebase. Audits exist to find problems — an audit that finds nothing should make that credible by showing what it checked, not just declare victory.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and the stack file in `${CLAUDE_PLUGIN_ROOT}/reference/stacks/` (each has an "Audit tooling" section). Check the Audit milestone description — `/n8-plan` records which areas deserve emphasis for this app. With no argument, offer the suite and let the user pick (defaulting to the emphasized areas plus security).

## Audit areas

- **security** — dependency vulnerabilities (stack tool + Dependabot alerts via `gh api repos/$R/dependabot/alerts`), CodeQL results (`gh api repos/$R/code-scanning/alerts`), Semgrep with stack rulesets, secret scanning alerts, injection/XSS/SSRF review of input handling, fuzzing of parsers/deserializers where applicable. Recommend app-specific OSS tools where they fit (e.g. ZAP for web APIs, trivy for containers) — recommend honestly, including setup cost.
- **authorization** — distinct from security scanning: map every endpoint/action to who may perform it; hunt missing checks, IDOR, privilege escalation, tenant leakage. Verify authz is enforced server-side, not just hidden in the UI.
- **stability** — error handling and recovery paths, unhandled rejections/exceptions, resource leaks, race conditions, retry/timeout behavior on external calls, graceful degradation.
- **performance** — hot paths, N+1 queries, unbounded growth, missing indexes/caching, bundle size (web), frame budget (Unity/Flutter). Measure where possible instead of eyeballing.
- **cleanup** — dead code, unused dependencies, TODOs, duplicated logic, inconsistent patterns, stale docs/config.
- **508** — accessibility against WCAG: semantics/labels, keyboard navigation, contrast, focus management. Use the stack's tooling (axe-core, Flutter guideline tests); flag what automated checks can't cover as manual test steps.

Where a scanner isn't installed (semgrep, etc.), offer to install it or run the nearest equivalent — note any coverage gap in the report.

## Findings → report → ask → file

1. Collect findings with: severity (critical/high/medium/low), location, evidence, and a concrete remediation.
2. **Report first.** Present findings grouped by severity. Include a "what was checked" section so clean areas are credible.
3. **Ask which to file.** For approved findings, duplicate-check then create issues — labeled with the audit area (`security`, `performance`, `bug`, etc.), body containing evidence and remediation, assigned to the **Audit milestone** (or an earlier open milestone if the user prefers the fix sooner). Wire dependencies if fixes must be ordered.
4. Fixes flow through the normal loop: `/n8-exec` the Audit milestone, then `/n8-verify` closes it.
