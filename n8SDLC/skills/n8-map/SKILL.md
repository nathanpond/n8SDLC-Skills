---
name: n8-map
description: Map an existing (brownfield) codebase before planning n8SDLC work on it — four parallel agents document the stack, architecture, conventions, and concerns directly into the wiki (or docs/), written prescriptively for future executors; concerns become triaged issues. Use whenever the user says "n8-map", "map the codebase", "analyze this existing project", "document what's here", or brings n8SDLC to a codebase that predates it.
---

# /n8-map — Codebase Mapping (Brownfield)

Roadmapping and planning assume you understand the codebase; on a project that predates n8SDLC, build that understanding once and write it down where every later skill can read it. Run after `/n8-init`, before `/n8-roadmap`, on any non-trivial existing codebase.

Read `${CLAUDE_PLUGIN_ROOT}/reference/state.md`. Output lands in the **wiki** (`wiki: enabled`) or `docs/codebase/` (wiki opted out) — never a bespoke state directory.

## Four parallel mappers, writing directly to disk

Fan out four agents concurrently, each owning a focus and **writing its pages itself** — you receive only confirmations, never the content. That's the point: mapping a large repo must not consume the orchestrator's context.

| Agent | Pages | Covers |
|---|---|---|
| stack | Stack, Integrations | languages, frameworks, versions, external services, env vars, how to build/run/test |
| architecture | Architecture, Structure | components and boundaries, data flow, key abstractions; directory map — "where do I put this?" |
| conventions | Conventions, Testing | naming, patterns, error handling, state management — with code examples; how tests are organized and run |
| concerns | Concerns | tech debt, known bugs, security risks, perf bottlenecks, fragile areas — each as Issue / Files / Impact / Fix approach |

Give every mapper the same writing contract — the output quality lives or dies on it:

- **You are writing for a future executor agent, not a reader.** File paths, not descriptions: `src/services/user.ts`, never "the user service".
- **Patterns over lists:** show *how* things are done here, with a short real code excerpt — not what merely exists.
- **Prescriptive, not observational:** "Use camelCase for functions" helps an executor write correct code; "some functions use camelCase" doesn't. Where the codebase is inconsistent, state the dominant pattern and note the exceptions.
- **Current state only — no temporal language.** What IS, never what was or what someone considered.

## Then, in the orchestrator

1. Stamp each page (or an index page) with the commit SHA it was generated from — the freshness check is `git log <sha>..HEAD --stat`, not a bespoke staleness index. `/n8-wiki` reconciles these pages like any others.
2. **Concerns become issues:** walk the Concerns page with the user; approved items are filed via the standard duplicate check with `needs-triage` (or their real type when obvious), an `area:*` label, and `sev:*` where the concern is a finding. This is how the map feeds the roadmap — existing debt competes for milestones alongside new features.
3. Report: pages written, concern count filed vs. deferred, and anything surprising enough that the user should read it before `/n8-roadmap`. Suggest `/n8-roadmap` as the next step — its epics should be planned *against* this map.
