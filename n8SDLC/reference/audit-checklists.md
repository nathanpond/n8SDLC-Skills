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
- Stale *code comments* pointing at deleted/renamed code, in files no corpus document cites — `sev:high` when actively misleading. Documents, and comments inside files they cite, belong to the Docs area end to end.
- Duplicated helpers ripe for consolidation (the same 3-line accessor pasted across N files).
- TODO/FIXME/HACK triage — each is one of: real outstanding work (→ file an issue), stale (→ delete the comment), or acknowledged tradeoff with a reason (→ leave alone). Cap at the most concerning few.
- **Skill and memory drift** belongs to the **Docs** section below, which owns documents end to end — existence *and* behaviour. On a cleanup-only run, list stale citations you trip over as leads for a docs run (no severity here) and say the docs pass was not run.
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

## Docs (documents against code)

A wrong document in an agent-driven project is **executed**, not merely misread: the code is fine, nothing fails, and the cost lands on the next agent told to follow it. Findings here are places the description and the behaviour disagree.

**Corpus.** From the project root — the directory holding `.n8/`, which may sit below the git toplevel: `P=$(pwd); T=$(git rev-parse --show-toplevel); REL=${P#$T/}` (`REL` is `.` when they coincide). Print the corpus in the report so its omissions are visible. `D=$(mktemp -d /tmp/n8-wiki.XXXXXX); git clone "https://github.com/$R.wiki.git" "$D" || { rm -rf "$D"; D=; }` — a failed clone (git says `Repository not found`, never "404") leaves an empty directory that would otherwise join the corpus; skip the wiki with a note when `D` is empty or `gh repo view --json hasWikiEnabled --jq .hasWikiEnabled` is false. Then an **array** of the members that exist — zsh does not word-split a string variable, so a space-joined string is one nonexistent path: `corpus=(); for m in .claude/skills CLAUDE.md .n8/memory README.md CONTRIBUTING.md docs "$D"; do [ -e "$m" ] && corpus+=("$m"); done`. Report what that list omits — ADRs outside `docs/` and in-app help are outside it by construction, so a clean result does not cover them. Doc-comments that instruct ("call X before Y") inside any file a corpus document cites are in scope here, stale pointer or not; Cleanup owns comments in code no document cites.

**Mechanical sweeps** — leads, not findings; promote each through the evidence bar:

```sh
grep -rnE '\.(md|ts|tsx|js|py|cs|go|rb|java|sh|dart|kt|swift|rs|sql|ya?ml|razor|cshtml):[0-9]+' "${corpus[@]}"   # line-number citations
grep -rniE '^#{1,6} *(corrections?|errata|addendum|changelog|update log)' "${corpus[@]}"
grep -rniE '\bcopy\b|model (it|this) (on|after)|follow the pattern in|use .* as (a|the) (template|example|exemplar)' "${corpus[@]}"
grep -rhoE '`[A-Za-z0-9_./-]+/[A-Za-z0-9_.-]+\.[a-z]{1,5}`' "${corpus[@]}" | tr -d '`' | sort -u | while read p; do [ -e "$p" ] || echo "MISSING: $p"; done   # every cited path that no longer exists (the coverage inverse; illustrative paths like src/foo.ts are leads to dismiss, not findings)
```

Never append `2>/dev/null` to a sweep: a missing corpus member must be visible, or an empty result reads as clean.

Then per skill, read its frontmatter `description` against the body: every trigger phrase in the description must correspond to a step the body carries; one that doesn't is a finding (an over-claiming description mis-triggers the skill).

**The independent check — the cold follow.** The docs equivalent of Cleanup's trial-delete: the one check here with a verdict. It applies to each skill that carries steps — a numbered list, or three or more imperative sentences in sequence; a reference-only skill gets the sweeps and the behavioural check but no follow, and the report says so. Order: skills named in an open story's body first — `gh issue list --state open --limit 200 --json number,body --jq '[.[] | select(.body | contains("<skill name>"))] | length'` (GitHub's search tokenises on `-` and `/`, so a `--search` phrase does not phrase-match) — then the rest alphabetically. Each skill is several tool calls (the worktree, the subagent, the removal), and variables die between calls, so write the literal skill name into each:

```sh
SKILL=plugin-creator; W=/tmp/n8-cold-$SKILL
git worktree remove --force "$W" 2>/dev/null; rm -rf "$W"                       # a leftover path, registered or not, makes add fail
git -C "$T" worktree add "$W" HEAD && mkdir -p "$W/$REL/.claude" && cp -R "$P/.claude/skills" "$W/$REL/.claude/"   # mkdir first: where .claude isn't at HEAD, cp would create .claude *as* the copy
# … spawn the follow (next paragraph) with $W/$REL as its project root, then: git worktree remove --force "$W"
```

The worktree holds HEAD's code and prose plus the working tree's skills; a skill that documents uncommitted code or an uncommitted CLAUDE.md edit will fail falsely — commit first. Spawn a `general-purpose` subagent (**never `fork`** — it inherits this session's context and cannot fail the way a real reader fails; not `Explore`, which cannot write and so cannot build what it produced). Its prompt carries `$W`, the skill's path inside it, one realistic task phrased from the skill's *description* (not its steps), the rule that every path it touches is absolute and under `$W`, and the brief: do the task there using only the skill as instruction; build or run what you produced and paste the output; stop after the task or twenty tool calls; report (1) every path read or searched that the skill did not name, (2) findings classed **STALL** (could not proceed *because of the skill*), **WRONG** (quoted instruction + failing output), **GAP** (had to discover it; the skill should have said it), **NIT** (anything that changes no outcome: wording, a stall caused by the environment or the call budget), at most ten. Afterwards `git worktree remove --force "$W"` — always needed, because the copied skills are untracked; a plain `remove` that succeeds means the copy never landed. **Verdict:** any STALL or WRONG fails the skill. Each STALL is a finding at `sev:medium` — "Executed as:" is the quoted instruction and where the tester stopped — after you confirm it isn't an environment stall; each WRONG at the severity of what an executor would have shipped, default `sev:high`, verified by re-running its quoted failing command yourself; GAPs and an access list longer than five unnamed paths roll into one `sev:low` aggregate finding per skill; NITs are footnoted. Re-reading the skill is not verification — in an agent-driven project the same lineage wrote it. "Audits write no source" means the working tree: the follow's worktree and the runnable-examples scratch checkout are both discarded.

**Behavioural claims.** Extract assertions of the shape *X does Y*, *when A then B*, *the system validates Z*, and read the implementing code for each. There are always more than can be checked, so prioritise in this order and say in the report where you stopped: (1) claims an open or planned story names as the method to follow — those are about to be executed; (2) claims about validation, authorization, persistence, or startup; (3) claims about code that changed after the document was last touched (`git log -1 --format=%cI -- <doc>` for the doc's last commit date — `git -C "$D" log -1 --format=%cI -- <page>` for a wiki page, since the clone is its own repo; an uncommitted document prints nothing, and `--since=""` then returns zero commits, so use today — then `git log --since=<that> -- <path>`; never the file's mtime, which git does not store and a fresh clone resets). Existence of the cited symbol is the floor, not the check: the defects this area exists for all pass an existence sweep.

**Exemplars.** A document instructing "copy X" inherits X's defects. Cross-reference each named exemplar against the project's open findings — `gh issue list --state open --limit 200 --json number,title,body,labels --jq '[.[] | select((.title + .body) | contains("<exemplar symbol>"))]'`, by symbol not path (search tokenises paths) and with no label filter, since a human-filed defect may carry no `bug`/`security` label at all (and `gh` ANDs comma-separated labels, so `--label bug,security` would match only issues carrying both); an exemplar carrying a known defect with no warning is a defect generator, severity that of the defect it propagates — re-rated under the rubric when the issue carries no `sev:*` label, as human-filed ones usually don't.

**Runnable examples** are checked by running them — on a disposable checkout or scratch database only. Failure modes here are destructive by nature (a documented step against a file that re-runs on every boot bricks startup for existing installs) and an audit writes no source: if an example cannot be run in isolation safely, report it as unverified rather than running it.

**Coverage.** The inverse half is the fourth sweep: every cited path that no longer exists. The forward half — live features no document names — takes the Integration area's enumeration (routes and UI entry points from the filesystem); on a docs-only run say that half was skipped.

**Severity.** Read the rubric's "today" as *when this document is next followed* — a document is a latent instruction, so one that would lead an executor to write an authorization defect carries that defect's severity, not `sev:low`. Rot with no behavioural consequence — a drifted line number beside a symbol that still resolves, a renamed path an executor would find on the first grep — is `sev:low`; a stale path that would send an executor to the wrong file is "actively misleading" and `sev:high`, and drifted citations are reported as **one aggregate finding per document** rather than one per citation, or they consume the punch-list cap on their own.

**Expect code defects too.** Checking whether a document's claims are true surfaces bugs the code audits miss — a revocation that stops running after first boot, a published event with no stream provisioned. File them in their own area, not folded into a documentation fix.

## Integration (wiring audit)

**Existence ≠ integration.** Individual stories can each pass while the system fails: a component exists but nothing imports it, an API exists but nothing calls it, a form renders but has no handler, data is written but never displayed. This is *the* failure mode of autonomous milestone execution — check connections, not existence.

- Build a provides/consumes map for the milestone's (or project's) exported surface, then classify each export: **CONNECTED** (imported elsewhere and referenced beyond the import line) / **IMPORTED_NOT_USED** / **ORPHANED** (zero imports).
- Enumerate API routes/endpoints from the filesystem and confirm each has at least one caller; enumerate UI entry points and confirm each reaches its backend.
- Chase the four link classes: exports → imports, APIs → consumers, forms → handlers, data writes → reads/display.
- Severity by class: an orphaned load-bearing artifact (a truth depends on it) is high; an unused convenience export is cleanup.
- Cross-reference the must-haves `key_links` from closed stories — every planned link should now be CONNECTED.

## Tests (coverage audit)

- Inventory what's covered vs. the app's actual high-value user journeys; identify missing coverage by priority, with the exact journey enumerated per gap.
- Track gaps as a **durable backlog with ids and status** (issues, per this workflow), not an ephemeral report.
- Promised-but-missing tests: stories whose test plans name tests that don't exist.
- Test quality: assertions that can't fail, snapshot/golden tests rubber-stamped without review, disabled/skipped tests with no linked issue.
- Prefer resilient selectors in e2e (role/label/text over CSS); fail e2e on unexpected console errors where the harness allows.
- Coverage asymmetries between local and CI environments are findings — a test that only runs on one machine protects nothing.
