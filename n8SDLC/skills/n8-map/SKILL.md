---
name: n8-map
description: Map an existing (brownfield) codebase before planning n8SDLC work on it — four parallel agents document the stack, architecture, conventions, and concerns directly into the wiki (or docs/), written prescriptively for future executors; concerns become triaged issues. Use whenever the user says "n8-map", "map the codebase", "analyze this existing project", "document what's here", or brings n8SDLC to a codebase that predates it.
---

# /n8-map — Codebase Mapping (Brownfield)

Roadmapping and planning assume you understand the codebase; on a project that predates n8SDLC, build that understanding once and write it down where every later skill can read it. Run after `/n8-init`, before `/n8-roadmap`, on any non-trivial existing codebase.

Read `${CLAUDE_PLUGIN_ROOT}/reference/state.md`. Output lands in the **wiki** (`wiki: enabled`) or `docs/codebase/` (wiki opted out; filenames `Stack.md`, `Integrations.md`, `Architecture.md`, `Structure.md`, `Conventions.md`, `Testing.md`, `Concerns.md`) — never a bespoke state directory.

The canonical time to run is after `/n8-init`, before `/n8-roadmap` — but mapping mid-project is legitimate (post-pivot, or docs drifted): everything below applies the same, except the closing suggestion, which should fit the project's actual stage (usually: read the filed concerns before the next `/n8-exec`).

## Four parallel mappers, writing directly to disk

Pre-flight, in the project directory: `git status --porcelain` must be empty (a dirty tree makes the stamp a lie); `SHA=$(git rev-parse HEAD)`; `ROOT=$PWD`; with the wiki enabled, `W=$(mktemp -d /tmp/n8-map.XXXXXX); git clone "$(gh repo view --json url --jq .url).wiki.git" "$W" || { W=$ROOT/docs/codebase; mkdir -p "$W"; }` (an uninitialized wiki fails the clone; say so), otherwise `W=$ROOT/docs/codebase; mkdir -p "$W"`. Page filenames are the same in both destinations. Then fan out four `general-purpose` agents concurrently (**never `fork`** — a fork inherits this session's context, and the mappers must see only the code), each owning a focus and **writing its pages itself** — you receive only confirmations, never the content, so mapping a large repo doesn't consume the orchestrator's context. Each prompt carries, in full: the project root `$ROOT`; its table row; the writing contract below with `$SHA` substituted; for the concerns mapper the four `sev:*` values from `reference/github.md`'s label table; the absolute paths `$W/<Page>.md` it owns (the only files it may create or change); "overwrite an existing page; `/n8-wiki` reconciles hand edits"; "end every page with the literal last line `<!-- n8-map: $SHA -->`" with the SHA substituted; and the return format: *the absolute paths written, one per line, nothing else*. Mappers write pages only; the orchestrator commits and pushes `$W` once, after step 1 below. A mapper that returns fewer paths than assigned, or anything else, is re-run once; still short → stop and report before committing.

| Agent | Pages | Covers |
|---|---|---|
| stack | Stack, Integrations | languages, frameworks, versions, external services, env vars, how to build/run/test |
| architecture | Architecture, Structure | components and boundaries, data flow, key abstractions; directory map — "where do I put this?" |
| conventions | Conventions, Testing | naming, patterns, error handling, state management — with code examples; how tests are organized and run |
| concerns | Concerns | tech debt, known bugs, security risks, perf bottlenecks, fragile areas — each as Issue / Files / Impact / Severity / Fix approach / **Evidence**. `Severity:` is your proposal on the `sev:*` scale. `Evidence:` is `<cwd>$ <command> -> exit <n>, <one-line result> — confirms|refutes|inconclusive` or exactly `unverified` — never absent, so a reviewer can tell "ran it" from "forgot". The concerns mapper is the only one that runs tests |

Give every mapper the same writing contract — the output quality lives or dies on it:

- **You are writing for a future executor agent, not a reader.** File paths, not descriptions: `src/services/user.ts`, never "the user service".
- **Patterns over lists:** show *how* things are done here, with a short real code excerpt — not what merely exists.
- **Prescriptive, not observational:** "Use camelCase for functions" helps an executor write correct code; "some functions use camelCase" doesn't. Where the codebase is inconsistent, state the dominant pattern and note the exceptions.
- **Current state only — no temporal language.** What IS, never what was or what someone considered.
- **Running code** (concerns mapper only; the other three run nothing): only existing unit-test invocations that need no network, from the package directory the test belongs to, with the Bash tool's `timeout` set to 300000 — a timeout is `unverified`. Never install, build, start a server, or create or modify any file other than the pages you own; the rest of the tree must be exactly `$SHA` when you finish. If a test needs network or absent dependencies, or no existing test exercises the claim, record `unverified`.
- **Cite file path plus symbol, never a line number.** `applyElementSnapshots` in `src/foo.ts`, never `src/foo.ts:513` — the path, because a monorepo has ten `handler`s. These pages are read across the repository by agents who cannot tell a drifted number from a wrong claim, and a handful of stale citations discredits pages whose substance is sound. For an unnamed block, describe it — "the branch chain in `ApplyElementSnapshots` that dispatches by element type".
- **Claims about behaviour need the code read, not the symbol found.** "Validation blocks publishing" is a claim about what runs where; confirming the validator exists does not confirm it. Where you assert a mechanism, name the evidence you checked — an executor will follow these pages as instructions.

## Then, in the orchestrator

1. Every path under the project except the seven pages must be untouched: `git status --porcelain | grep -vE '^\?\? docs/codebase/(Stack|Integrations|Architecture|Structure|Conventions|Testing|Concerns)\.md$'` must print nothing (same filter on `git -C "$W" status --porcelain` in wiki mode) — a mapper that wrote elsewhere is named in the report. Then re-verify (step 2) *before* stamping and committing, so the verdict lands on the page. Stamp only the seven pages, byte-stable across runs, and stop if any is missing:
   ```sh
   miss=0
   for p in Stack Integrations Architecture Structure Conventions Testing Concerns; do
     f="$W/$p.md"; [ -s "$f" ] || { echo "MISSING $f"; miss=1; continue; }
     printf '%s\n\n<!-- n8-map: %s -->\n' "$(grep -vxE '<!-- n8-map: [0-9a-f]+ -->' "$f")" "$SHA" > "$f.tmp" && mv "$f.tmp" "$f"
   done
   [ "$miss" = 0 ] || { echo "STOP: page(s) missing"; exit 1; }
   ```
   (`for p in "$W"/*.md` would stamp `Home.md` and `_Sidebar.md` in a wiki clone.) The freshness check later is `git log <sha>..HEAD --stat`, and `/n8-wiki` reads the same line. Then, wiki mode: `git -C "$W" add -- Stack.md Integrations.md Architecture.md Structure.md Conventions.md Testing.md Concerns.md && git -C "$W" commit -m "n8-map @ $SHA" && git -C "$W" push` (`commit` exits 1 with nothing to commit — report it, don't push). Docs mode: the same `add --` of the seven files, landed through the branch-and-PR flow in `reference/state.md`, since direct pushes to `main` are rejected. Linking the pages from Home and `_Sidebar.md` is `/n8-wiki`'s job.
2. **Concerns become issues** — the one page the orchestrator does read (the confirmations-only rule covers the other six): for every concern at `Severity: sev:high` or above (the scale is the label table in `reference/github.md`): if the `<command>` segment of its `Evidence:` — between `$ ` and ` -> ` — starts with a test runner or `<pm> exec <runner>` and contains none of `; && || | > < $( \``, re-run it yourself from its `<cwd>`: `o=$(mktemp); (cd "$ROOT/<cwd>" && <command>) > "$o" 2>&1; rc=$?; tail -n 5 "$o"; echo "exit $rc"` with the Bash tool's `timeout` at 300000 (never `| tail`, which loses the exit code; test runners print source frames on failure, and the orchestrator reads five lines, not source); if it is `unverified` or the command fails that test, spawn one `general-purpose` verifier (never `fork`) with the concerns table row, `$ROOT`, the entry, the **Running code** bullet with `$SHA` substituted, a budget of twenty tool calls, and "return one line in the Evidence format; `unverified` if no existing test exercises it". Write the result into the entry's `Evidence:` before step 1 stamps and commits, then repeat the porcelain check. Trust the field for everything below high; then walk the page with the user; approved items are filed via the duplicate check in `${CLAUDE_PLUGIN_ROOT}/reference/github.md` with `needs-triage` (or their real type when obvious), an `area:*` label, and `sev:*` where the concern is a finding. This is how the map feeds the roadmap — existing debt competes for milestones alongside new features.
3. Report: pages written, concern count filed vs. deferred, and anything surprising enough that the user should read it before `/n8-roadmap`. Suggest `/n8-roadmap` as the next step — its epics should be planned *against* this map.
