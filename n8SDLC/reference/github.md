# GitHub Conventions (n8SDLC)

Shared conventions for every n8SDLC skill. All GitHub operations go through the `gh` CLI. Assume it is installed and authenticated; if `gh auth status` fails, stop and tell the user how to fix it (`gh auth login`) — do not attempt workarounds.

GitHub is the source of truth for all planning state. Before creating anything (label, milestone, issue), check whether it already exists — every operation in this workflow must be safe to re-run.

Set `R=$(gh repo view --json nameWithOwner --jq .nameWithOwner)` once and reuse it.

## Labels

The baseline label set, created/updated idempotently with:

```bash
gh label create "<name>" --color <hex> --description "<desc>" --force
```

| Label | Color | Description |
|---|---|---|
| epic | 3E4B9E | Large body of work; acceptance criteria at the epic level |
| feature | 1D76DB | Story: describes WHAT to build, with acceptance criteria |
| subtask | C5DEF5 | Technical implementation detail: describes HOW |
| bug | D73A4A | Something isn't working |
| confirmed | B60205 | Bug has been reproduced |
| blocked | D93F0B | Execution blocked pending a decision or dependency |
| security | EE0701 | Security-related work or finding |
| performance | F9D0C4 | Performance-related work or finding |
| documentation | 0075CA | Documentation work |
| duplicate | CFD3D7 | Duplicate of another issue |
| help wanted | 008672 | Extra attention is needed |
| invalid | E4E669 | Not a valid issue |
| question | D876E3 | Further information is requested |
| wontfix | FFFFFF | Will not be worked on |

## Issue hierarchy: epic → story → subtask

Use GitHub **native sub-issues** so progress rolls up in the UI:

- **Epic** (`epic` label): one per major capability. Body holds the goal and epic-level acceptance criteria. Stories are its sub-issues.
- **Story** (`feature`, `bug`, `security`, `performance`, or `documentation` label): describes the *what* with testable acceptance criteria and a test plan. Subtasks are its sub-issues.
- **Subtask** (`subtask` label): describes the *how* — specific implementation instructions. Only create subtasks when the implementation approach genuinely needs prescribing; a story with obvious implementation needs none.

Sub-issue API (needs the child's internal id, not its number):

```bash
CHILD_ID=$(gh api repos/$R/issues/$CHILD_NUM --jq .id)
gh api -X POST repos/$R/issues/$PARENT_NUM/sub_issues -F sub_issue_id=$CHILD_ID
gh api repos/$R/issues/$PARENT_NUM/sub_issues          # list children
```

**Fallback:** if the sub-issue endpoints are unavailable (older GHES, API changes), degrade gracefully: add a `- [ ] #<child>` task-list line to the parent body and a `Parent: #<parent>` line at the top of the child body. All skills must treat those body conventions as equivalent to native sub-issues when reading hierarchy.

## Dependencies (blocked by / blocks)

Prefer GitHub's native issue dependencies:

```bash
BLOCKER_ID=$(gh api repos/$R/issues/$BLOCKER_NUM --jq .id)
gh api -X POST repos/$R/issues/$NUM/dependencies/blocked_by -F issue_id=$BLOCKER_ID
```

**Fallback:** if the endpoint is unavailable, record `Blocked by: #N` / `Blocks: #N` lines in a `## Dependencies` section of the issue body. Skills reading dependency order must check both the API and these body lines.

## Milestones

- Naming: `M0: Infrastructure`, `M1: <Name>`, … final milestone is always `M<N>: Audit`.
- **M0 is always infrastructure setup** (deployment targets, environments, project plumbing).
- **CI comes early** — usually M1 or folded into M0 — covering dev/stage/production deployment via GitHub Actions unless the user chose otherwise.
- **Audit is always last**, holding audit passes and approved audit-finding fixes.
- The milestone description records: goal, ordered phases, and definition of done. Definition of done always includes: all issues closed, all automated tests written and passing, and `/n8-verify` passed.
- A milestone is **closed only by /n8-verify** (verification is part of done). `/n8-exec` never closes milestones.

```bash
gh api repos/$R/milestones --jq '.[].title'    # list (add -f state=all to include closed)
gh api -X POST repos/$R/milestones -f title="M1: Core API" -f description="..."
```

## Duplicate check — before creating ANY issue

1. Search: `gh issue list --state all --search "<keywords>"` (try a couple of keyword variants).
2. Exact or near-exact match → do not create. Report the existing issue.
3. Related but not the same → ask the user: extend the existing issue's acceptance criteria to cover this, or create a new issue linked to it? Never silently pick one.

## Issue body templates

**Epic:**
```markdown
## Goal
<one paragraph>

## Acceptance criteria (epic level)
- [ ] <criterion>

## Notes
<context, constraints, out-of-scope>
```

**Story:**
```markdown
## What
<what to build and why — no implementation detail>

## Acceptance criteria
- [ ] <testable criterion>

## Test plan
<automated tests to be written as part of this story; they must pass before the story is done>

## Dependencies
<Blocked by: #N lines, if the native API is unavailable>
```

**Subtask:**
```markdown
## How
<specific implementation instructions: files, APIs, patterns, gotchas>

## Done when
- [ ] <objective completion signal>
```

## Branch and PR conventions

- One branch per milestone: `milestone/m1-short-name`.
- Commit per story on that branch; reference the story number in the commit subject (`feat: user login (#12)`).
- One PR per milestone. The PR body lists `Closes #N` for every completed story so the merge closes them all. Merge only when CI is green (once CI exists).
