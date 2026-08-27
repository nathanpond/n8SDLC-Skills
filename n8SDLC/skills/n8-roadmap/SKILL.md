---
name: n8-roadmap
description: Build the project roadmap at the start of an n8SDLC project — the user describes the overall goal, expected features, and acceptance criteria; the skill asks clarifying questions, creates epics as GitHub issues with epic-level AC, and lays out milestones (M0 infrastructure, early CI, feature milestones, final Audit). Use whenever the user says "n8-roadmap", "let's plan the roadmap", "here's what the app should do", or describes overall product goals after /n8-init.
---

# /n8-roadmap — Roadmap Planning

Turn the user's description of the app into epics and a milestone skeleton. This is deliberately coarse: epics carry acceptance criteria at the epic level only. Granular stories come later from `/n8-plan` — don't front-load that detail here.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and `${CLAUDE_PLUGIN_ROOT}/reference/state.md` first. Requires `/n8-init` to have run (`.n8/config.yml` exists); if not, say so and stop.

## 1. Listen, then interrogate

The user describes the overall goal, expected features, and acceptance criteria. Ask clarifying questions until you could defend the epic list to a skeptical PM — but only about what's genuinely open: when the user's description already answers a bullet below, confirm it in your summary rather than re-asking. A fully specified description can go straight to epics. Cover at minimum:

- Who uses this and what does success look like?
- Scope edges: what's explicitly *not* in v1?
- Non-functional needs that become epics or AC: auth, performance targets, accessibility (508), offline, data retention.
- **Infrastructure (feeds M0):** where will the application be deployed, and how? What environments exist (dev/stage/production) and where does each live? Databases, secrets, third-party services?
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
- **Feature milestones** — group epics into coherent, shippable increments. Order by dependency and value. Phases within each milestone go in the milestone description as an ordered list.
- **M<N>: Audit** — always last: audit passes (`/n8-audit`) and approved finding fixes. It gets **no epic of its own** — audit findings attach to the epics they concern, or stand alone.

Every milestone description carries: goal, ordered phases, and definition of done (all issues closed, all tests passing, `/n8-verify` passed). Assign each epic to the milestone where the bulk of its work lands (stories get individually assigned during `/n8-plan`).

## 4. Commit and report

Land the run's state edits (`.n8/`, CLAUDE.md) per `reference/state.md`'s "Committing state changes" — a `n8/roadmap-state` branch and PR, since the ruleset blocks direct pushes to main.

Summarize: the epic list (numbers + titles), the milestone sequence with one-line goals, the recorded deployment/CI answers, and any open questions deferred to milestone planning. Finish with:

> Next: run `/n8-plan M0` to plan the infrastructure milestone in detail (or `/n8-plan *` to plan everything).
