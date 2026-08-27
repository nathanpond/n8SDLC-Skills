# Audit Concern Checklists

Per-dimension checklists for `/n8-audit`, distilled from audits that ran repeatedly on real codebases. Read the section for the dimension being run. These generalize across stacks — pair them with the stack file's "Audit tooling" section for concrete tools.

Every dimension shares the verification rule: **verify each finding yourself before reporting** — read the surrounding code, not just the pattern match; run the independent check where one exists. Agent grep results are leads, not findings.

## Security

- **CSRF:** every state-changing endpoint either requires a token or validates Origin/Referer. Pre-auth state-changing endpoints (login, signup) get extra scrutiny — that's the login-CSRF class, and `SameSite` on the auth cookie does NOT mitigate it (the cookie is set after the attack POSTs).
- **Secrets:** `grep -rn -E "(api[_-]?key|secret|password|token|connection[_-]?string)\s*[=:]\s*[\"']\w"` over source; filter test fixtures and documented dev-only config before reporting.
- **Injection:** raw SQL construction with interpolation (distinguish carefully from parameterized/interpolated-safe APIs — e.g. EF's `FromSqlRaw` vs `FromSqlInterpolated`); command construction; path traversal (canonical mitigation: canonicalize with the platform's full-path API, then boundary-check with StartsWith against the allowed root).
- **Deserialization** of untrusted input with polymorphic/type-resolving settings.
- **Open redirects:** any redirect target sourced from a request parameter.
- **Mass assignment:** request DTOs bound straight to entities with more settable fields than the endpoint intends.
- **Network/SSRF:** outbound requests whose URL derives from user input; missing allowlists on webhook/callback targets.
- **Untrusted file/input parsing:** for any parser of externally supplied bytes, ask what a hostile input *gets out of it* — memory, CPU, a crash, wrong output — and weight those findings above everything else. Fuzz where applicable.
- **Anonymous-endpoint sanity:** list everything reachable without auth; each must justify itself.
- **Resolution rule:** an accepted vulnerability is fixed *with a regression test that builds the attack* — the crafted input or request sequence becomes a permanent test. A security fix without its attack-as-test is unverified.

## Authorization (distinct from security scanning)

- **Coverage inventory:** map every endpoint/action to who may perform it; verify enforcement is server-side, not UI-hidden.
- **Gate-presence test:** if the project has (or can have) a test that enumerates routes at runtime and fails when an endpoint lacks an explicit auth decision, run it first — it must pass before the rest of the audit can be trusted, and a skipped/commented-out gate test is the top finding regardless of what else turns up. If no such test exists, recommend one; it converts this audit's main concern into a permanent CI gate.
- **Comment/code mismatch:** grep for "admin-only"/"internal" near route registrations; verify the gate actually matches the comment. This class recurs.
- **Grantable-but-inert vs. inert-but-enforced:** an action registered in the permission model that no endpoint enforces (admin grants it, gets nothing) — and the inverse, an endpoint gating on an action the model doesn't declare (every grant silently rejected: admin lockout).
- **Identifier plumbing:** the gate must read the id it authorizes from where the framework actually puts it (route token names match; actor id comes from the session/cookie, never from request body or query). A mismatched parameter name means the authorizer gets null and denies — or allows — silently.
- **"Scoped to actor" claims:** don't trust the method name — read the query. A `*ForUserAsync` that doesn't filter by user is exactly the bug this catches.
- **IDOR / tenant leakage:** list endpoints returning ids the actor can't see; cross-tenant reads via unscoped queries.

## Stability

- Fire-and-forget async (`async void`, unawaited tasks) — exceptions vanish or kill the process.
- **Background loop isolation:** a long-running worker's loop body must be inside a try/catch that logs and continues — otherwise one bad tick kills the service for the rest of the host's lifetime. Cancellation exceptions caught separately so shutdown stays graceful.
- Swallowed exceptions: `catch {}` on critical work is a finding; `catch { return null; }` in a parse-helper is fine. Judge by what's being swallowed, not the syntax.
- Resource leaks: undisposed connections/contexts; locks/semaphores acquired without finally.
- Races on shared mutable state; snapshot caches must build the new value fully, *then* assign.
- Missing timeouts and unbounded retries on external calls; sync-over-async on request paths.
- Cancellation propagation — with the inverse rule: cleanup/audit-trail paths that deliberately pass no token should say so in a comment.
- **Logging level discipline:** error paths logged as Info, expected paths logged as Error — both make alerting useless.
- **Missing analyzers are themselves a finding:** if the stack has async/reliability analyzers (see the stack file) not wired into the build, flag that — it's the always-on version of this audit.

## Performance

- **Maintain a hot-path inventory** in `.n8/memory/hot-paths.md`: the endpoints/functions hit on every mount, navigation, poll, or agent turn. Weight findings on hot paths above everything; report them in their own section. Grow the inventory each run.
- N+1 queries (per-item awaits in loops → batch with a set-based query); load-all-then-filter; missing indexes — and the inverse, indexes no query uses (they cost on every write).
- Per-request fetches of slow-changing data → snapshot cache with TTL + explicit invalidation on the mutating paths.
- Unbounded materialization: list endpoints without a clamped page size.
- Client-side amplifiers: aggressive refetch-on-focus, sub-30s polling, chatty per-row requests.
- **Name the canonical in-repo remediation** when one exists ("see X for the pattern") — a fix pointing at proven code in the same repo gets applied; an abstract fix gets debated.
- False-positive discipline: per-item awaits inside startup/migration/background paths usually don't matter — skip them.
- Findings state the **cost shape** ("O(N) per call where N = distinct permissions"), not just "slow".

## Cleanup

- **Dead-code claims require the trial-delete proof.** Grep lies: multi-line/destructured imports, DI registration, reflection-based discovery, dynamic import-by-name, and stale incremental-build caches all defeat it. A passing build *with the candidate still present* proves nothing. The only real verification: move the file aside, clear incremental caches, full rebuild — if that passes, it's genuinely unused. If in doubt, demote (remove the export/public) instead of deleting; a real consumer surfaces immediately.
- Symbol names that are unique strings are grep-safe; path fragments that overlap English words are not.
- Files that shouldn't be in source control: check `git ls-files`, not just the working tree.
- Stale comments and docs pointing at deleted/renamed code — High severity when actively misleading, because they cause bugs.
- Duplicated helpers ripe for consolidation (the same 3-line accessor pasted across N files).
- TODO/FIXME/HACK triage — each is one of: real outstanding work (→ file an issue), stale (→ delete the comment), or acknowledged tradeoff with a reason (→ leave alone). Cap at the most concerning few.
- **Skill and memory drift:** project skills (`.claude/skills/`) and memory files whose cited paths/symbols/claims no longer match the code. Stale guidance drives bad future sessions; flagging it is itself cleanup. Also flag the inverse — live features the skills don't document.
- **Invariant suppressions:** warning-suppression pragmas, disabled analyzer rules without a rationale, weakened build strictness.
- Output includes a **suggested git operations** section — copy-pasteable `git rm --cached`/`.gitignore` commands, staged for the user to review, never run by the audit.

## 508 / Accessibility

Frame it as catching **escapes from the framework's baseline**: a good component library ships focus traps and ARIA wiring, so audit the places code bypasses it — raw clickable `<div>`s, icon-only glyphs without accessible names, custom widgets that don't forward keyboard events.

- Text alternatives; form fields wired through the framework's label/error props (which carry `aria-describedby`/`aria-invalid`) rather than a stray colored text node.
- **Contrast: compute the ratio, don't eyeball it** — cite the computed number against 4.5:1 / 3:1. If theming is user/admin-configurable, check the highest-traffic default combinations; a configurable theme is a contrast liability.
- Color never the sole signal for status — require a glyph, label, or position cue too.
- Keyboard: tab reachability, visible focus, logical order, skip link. Detection lead: `grep -rn "onClick"` filtered to non-interactive elements.
- Focus management: modals return focus; **route changes move focus to the new page's heading** — otherwise screen-reader users are stranded mid-DOM; toasts don't steal it.
- Live regions for async/streaming content; `aria-busy` during loads.
- Data tables: real header cells, sort state announced, captions.
- Motion: respect `prefers-reduced-motion`; no sub-3Hz flashing; auto-dismiss ≥ 5s.
- Every finding cites its **WCAG success criterion** (e.g. "WCAG 1.1.1 / 508 §501"). Default to WCAG 2.0 AA (the 508 floor) and note where 2.1/2.2 criteria are cheap to adopt.
- Out of scope, say so explicitly: VPAT/procurement docs (a compliance artifact derived from the audit, not the audit), and non-HTML deliverables.

## Tests (coverage audit)

- Inventory what's covered vs. the app's actual high-value user journeys; identify missing coverage by priority, with the exact journey enumerated per gap.
- Track gaps as a **durable backlog with ids and status** (issues, per this workflow), not an ephemeral report.
- Promised-but-missing tests: stories whose test plans name tests that don't exist.
- Test quality: assertions that can't fail, snapshot/golden tests rubber-stamped without review, disabled/skipped tests with no linked issue.
- Prefer resilient selectors in e2e (role/label/text over CSS); fail e2e on unexpected console errors where the harness allows.
- Coverage asymmetries between local and CI environments are findings — a test that only runs on one machine protects nothing.
