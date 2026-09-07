---
name: n8-roadmap
description: Build the project roadmap at the start of an n8SDLC project — the user describes the overall goal, expected features, and acceptance criteria; the skill asks clarifying questions, creates epics as GitHub issues with epic-level AC, and lays out milestones (M0 infrastructure, early CI, feature milestones, final Audit). Use whenever the user says "n8-roadmap", "let's plan the roadmap", "here's what the app should do", or describes overall product goals after /n8-init.
---

# /n8-roadmap — Roadmap Planning

Turn the user's description of the app into epics and a milestone skeleton. This is deliberately coarse: epics carry acceptance criteria at the epic level only. Granular stories come later from `/n8-plan` — don't front-load that detail here.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and `${CLAUDE_PLUGIN_ROOT}/reference/state.md` first. Requires `/n8-init` to have run (`.n8/config.yml` exists); if not, say so and stop.

## 1. Listen, then interrogate

The user describes the overall goal, expected features, and acceptance criteria. Ask clarifying questions until you could defend the epic list to a skeptical PM — but only about what's genuinely open: when the user's description already answers a bullet below, confirm it in your summary rather than re-asking. A fully specified description still gets invariant confirmation, and the totalising question below whenever it fires. **Before creating anything**, draft every epic's acceptance criteria, then restate every answer — asked or inferred — together with the drafted epics (title and AC) and the milestone sequence with the epics whose bulk lands in each, in one message, and proceed on the user's OK; that is the confirmation, and it happens before any issue exists. Write `.n8/config.yml` and CLAUDE.md after the OK, before §2. Cover at minimum:

- Who uses this and what does success look like?
- Scope edges: what's explicitly *not* in v1?
- Non-functional needs that become epics or AC: auth, performance targets, accessibility (508), offline, data retention.
- **Infrastructure (feeds M0):** where will the application be deployed, and how? What environments exist (dev/stage/production) and where does each live? Databases, secrets, third-party services?
- **Totalising claims — ask before they become AC.** If the *user's* description says *full*, *complete*, *all*, *every*, *entire*, *comprehensive*, *any valid*, *100%*, *conformant*, *compliant*, or names a specification, ask verbatim, substituting the noun phrase that contains the trigger word for `<phrase>` and naming the tiers yourself if you know them: *"You said '<phrase>'. What do you take it to cover, and what do you explicitly not mean by it? Is that surface enumerable — a specification's element set, a list of endpoints, a set of pages? If the source has tiers (<list them, e.g. BPMN's Descriptive / Analytic / Common Executable>), which tier?"* For a totalising word in AC *you* drafted, ask in the restatement, opening with *"I've written '<phrase>' as AC."* — or replace the word with the set it stands for ("dev, stage and production each deploy from CI"), never delete the quantifier without writing out its extension. When parts of a claim land in different epics, ask the tier question once per part. "Not enumerable" keeps the same block with `source: not enumerable`, `tables: n/a`, the user's concrete examples in `covers:`, and the AC states those examples in place of the word. A surface the project itself defines ("every engine operation the API exposes") records `source: this project` and `locator: <path where /n8-plan will write the list>`. Otherwise you propose the defining document, its version, a locator, and the table(s) that list the tier's elements — open the locator (context7 or a fetch) and confirm those tables exist; if the locator won't open, write `tables: unverified (proposed: <tables>) — /n8-plan confirms before enumerating`; if it opens and the tables aren't there, propose again — and the user confirms them in the pre-creation restatement. Record the answer as a fenced block, this exact shape, so `/n8-plan` and `/n8-verify` can find it:

  ```
  coverage-claim:
    claim: <the user's phrase, verbatim>
    source: <defining document, version>
    locator: <URL or path a subagent can open>
    tier: <tier, or n/a>
    tables: <the table(s) listing this tier's elements; if tier is n/a, the list that defines the surface>
    covers: <this block's share, in the user's words where possible>
    not covered: <user's words, repeated verbatim in every block of the same claim; "none — user excluded nothing">
    remainder: <the other blocks on this block's own axis — an epic block names epics, a milestone block names milestones — or none>
  ```

  It goes after the last checkbox in the acceptance criteria of every epic that delivers part of it (carried forward when the epics are created in §2) and in the description of every milestone that delivers part of it, each block carrying only its own `covers:` and naming the rest in `remainder:`. Before the restatement, list the claim's parts in the user's words and place each in exactly one block's `covers:` or in `not covered:` — a part that fits neither is a question still to ask. `/n8-verify` reads the milestone's block, so a claim due in M3 never fails at M2. Milestone descriptions carrying a block are created with `-F description=@<file>` (form in `reference/github.md`), never inline. `/n8-plan` enumerates the source at that tier and maps stories to it; the enumeration itself is planning's job — never ask the user to produce it.
- **CI (feeds the CI milestone):** GitHub Actions unless the user specifies otherwise; where do dev/stage/production deployments go and what triggers them?
- **Project invariants:** load-bearing constraints no story may breach without an explicit conversation — e.g. dependency policy ("zero third-party packages in the core library"), a deliberately small public API surface, warnings-as-errors, data-residency rules. Propose candidates from what you've heard; the user confirms. Keep it to a handful — ten invariants means everything is sacred, which means nothing is. Record them in the project CLAUDE.md's n8SDLC section, each marked **test-enforced** or **honor-system**: wherever an invariant is expressible as a test or build setting (package count, public API snapshot, warnings-as-errors), an executable guard gets planned into M0/CI — at roadmap granularity that means **a line in the appropriate epic's acceptance criteria** — usually infra/CI, but a guard whose subject appears later (a storage-format fixture) belongs to that later epic; `/n8-plan` places the guard story in the milestone where its subject first exists; prose rules rot, while a guard test enforces forever and makes a deliberate breach visible in the diff. `/n8-exec` treats an apparent breach as a blocker; `/n8-audit` checks the honor-system ones and hunts weakened guards. Invariants are **amendable** — but changing one is a user decision and plan drift by definition, so it's logged as an ad-hoc ledger entry and picked up by `/n8-replan`.

Record deployment/CI answers in `.n8/config.yml` under `deployment:` and `ci:` — execution must never have to re-ask.

If the context7 MCP is available (skip the check entirely when config says `context7: declined`), use it to check current documentation for any frameworks/platforms the roadmap depends on before committing to them.

## 2. Create epics

For each major capability, create one epic issue (`epic` label) using the epic body template — goal, epic-level acceptance criteria, notes. Run the duplicate check from `reference/github.md` before each creation; on a related-but-different match, ask the user whether to extend the existing epic's AC or create a new one.

Cross-cutting concerns (infrastructure, CI, testing strategy) get their own epics too — they hold the M0/CI stories later.

## 3. Create milestones

Lay out the milestone sequence and create each via the API (duplicate-checked):

- **M0: Infrastructure** — always first. Scope from the deployment answers: environments, hosting, IaC if warranted, project plumbing.
- **CI milestone early** — usually M1: GitHub Actions pipelines for build/test/deploy to the stated targets.
- **Feature milestones** — group epics into coherent, shippable increments. Order by dependency and value.
- **M<N>: Audit** — always last: audit passes (`/n8-audit`) and approved finding fixes. It gets **no epic of its own** — audit findings attach to the epics they concern, or stand alone.

Every milestone description carries: goal; ordered phases (the epics' work in the order it lands, at epic granularity — `/n8-plan` re-slices them into stories; for the Audit milestone, the audit areas in order); the `coverage-claim` block for whatever this milestone delivers of a totalising claim; and definition of done (all issues closed, all tests passing, `/n8-verify` passed). Assign each epic to the milestone where the bulk of its work lands (stories get individually assigned during `/n8-plan`).

## 4. Commit and report

Append a `## /n8-roadmap — <date>` section to `.n8/decisions.md` naming the choices made (spec version, tiers, ordering, what was deferred), then land the run's state edits (`.n8/`, CLAUDE.md) per `reference/state.md`'s "Committing state changes" — a `n8/roadmap-state` branch and PR, since the ruleset blocks direct pushes to main.

Summarize: the epic list (numbers + titles), the milestone sequence with one-line goals, the recorded deployment/CI answers, and any open questions deferred to milestone planning. Say that the infrastructure milestone is planned first (and that `/n8-plan *` plans everything), then end:

> ➡ Next: /n8-plan M0

**End on the Next line.** The reply's final line is `➡ Next: /n8-plan M0` (an example — substitute the real command and arguments): one recommended command, alone on the line, nothing after it. The why and any alternatives go in the sentence above it, never appended to it. Claude Code's prompt suggestion reads the transcript; a bare, final, unambiguous command is what lets the user accept it with Tab.
