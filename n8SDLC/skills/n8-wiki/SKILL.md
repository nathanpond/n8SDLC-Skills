---
name: n8-wiki
description: Reconcile the GitHub wiki with the backlog and codebase in an n8SDLC project — a full pass that updates stale pages, adds missing ones, and keeps the wiki honest about the real state of the project. Applies changes directly, then summarizes. Use whenever the user says "n8-wiki", "update the wiki", "sync the wiki", or the wiki has drifted from reality after milestones ship.
---

# /n8-wiki — Wiki Reconciliation

Do a full pass through the wiki and bring it in line with what the backlog and codebase actually say. Apply updates directly and summarize afterward — the wiki is low-risk to edit and the workflow is autonomous.

First check `.n8/config.yml`: if `wiki: opted-out` or the wiki is unavailable, say so and stop — this is fine, wikis are optional in n8SDLC. Read `${CLAUDE_PLUGIN_ROOT}/reference/state.md` for config conventions.

## Voice — read this before writing a word

The wiki is written for humans, by (apparently) a human: informational, plain, first-person-plural where natural. And it is **honest by default — never oversell**:

- A feature that's planned is "planned", not described as if it exists.
- A half-working area says so: "Search works for exact titles; fuzzy matching is planned (#42)."
- Known limitations, missing tests, and rough edges get stated, not omitted.
- No marketing adjectives ("blazing fast", "robust", "seamless"). If performance matters, state the measured number or nothing.

A reader should be able to trust every sentence. When in doubt between flattering and accurate, accurate wins.

## The pass

1. Clone the wiki: `git clone $(gh repo view --json url --jq .url).wiki.git` into the scratchpad.
2. Build the ground truth: open issues/milestones (what's planned vs done), closed milestones (what shipped), the codebase (what actually exists — spot-check claims against code, don't trust page prose), `.n8/decisions.md` (decisions worth documenting).
3. Reconcile every page: fix stale claims, dead references, described-but-removed features, wrong setup instructions (verify commands against the repo's actual scripts/config).
4. Add missing pages where a reader would need them — typically: Home (project state overview), Getting Started / local dev setup, Architecture (as-built, including notable decisions and their whys), and per-area pages as the app grows. Don't create pages for the sake of structure; an empty-ish wiki that's accurate beats a full one that isn't.
5. Keep Home's project-status section current: which milestones are done, in progress, and next.
6. Commit with a descriptive message and push.

## Report

Summarize what changed: pages updated (with the substantive corrections called out — especially claims that were wrong), pages added, anything found in the codebase that contradicted the backlog (surface that to the user; it may warrant an issue).
