---
name: n8-upgrade
description: Bring an existing n8SDLC project up to the installed plugin version. Compares the version recorded in .n8/config.yml with the plugin's own, shows what's new in between, checks every project-side artifact a newer version expects (the CLAUDE.md n8SDLC block, config keys, dependabot, labels, issue forms, the .n8/ layout), sweeps project memories for conventions the new version replaced, applies the fixes on approval, and records the new version. Use whenever the user says "n8-upgrade", "upgrade the project", "update n8SDLC in this project", after updating the plugin, or when the session-start notice reports a version mismatch.
---

# /n8-upgrade — Project Upgrade

A plugin update changes the skills immediately, but never touches what `/n8-init` wrote into a project: the `CLAUDE.md` block every session reads, config keys, repo files. This command closes that gap. It is idempotent. On a current project it confirms, in one line, that there's nothing to do.

Read `${CLAUDE_PLUGIN_ROOT}/reference/upgrades.md` (the per-version catalog), `${CLAUDE_PLUGIN_ROOT}/reference/state.md` (`.n8/` layout and the state-commit flow), and `/n8-init`'s §4 and §8b, which hold the canonical artifacts the catalog points at.

## 1. Versions

- Plugin: `version` in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.
- Project: `plugin_version:` in `.n8/config.yml`. If it's absent, the project predates version tracking: treat it as older than every catalog entry.
- No `.n8/config.yml` → the project isn't initialized, so stop and point at `/n8-init`.
- If the project's version is **newer** than the plugin, someone upgraded it with a newer plugin than yours. Change nothing: tell the user to update the plugin (`/plugin` → update n8sdlc, then restart), and stop.

## 2. What's new

Summarize, in a few lines, what changed for the user between the two versions: new commands, and behaviour they'll notice. Take this from the GitHub releases (`gh release list -R nathanpond/n8SDLC-Skills` and `gh release view <tag> -R nathanpond/n8SDLC-Skills`), not from memory. If those can't be read, use the catalog's entries and say that the release notes were unavailable. This is the one moment the user is paying attention to the plugin itself, so make it count, and keep it short.

## 3. Check

Run every catalog check for versions after the project's, oldest first. Then run the **baseline presence checks**, whatever the version, because partial inits are common:

- `CLAUDE.md` has a `## n8SDLC project` section. Compare its paragraphs with the current block in `/n8-init` §8b. Anything missing is a finding. Wording that differs from the canonical text but carries the same instruction is not a finding. Text the project added to the section (declared invariants live here) is never a finding and is never touched.
- `.n8/config.yml` has the keys `reference/state.md` lists as required for this stage (`stack`, `repo`, `wiki`, `context7`, `security_findings`, `areas`). A missing key is a question for the user, not a guess, and init's own step for that key says what to ask.
- `.n8/decisions.md` exists, and its header carries the ad-hoc entry format.
- Labels: every baseline label in `reference/github.md` exists (`gh label list --limit 200 --json name`). **Only missing ones count.** An existing label whose colour or description differs is the project's choice.
- `.github/ISSUE_TEMPLATE/` has the epic, story and bug forms and `config.yml`. Report a missing file. An edited one is the project's.

Security settings (Dependabot alerts, CodeQL, secret scanning, the ruleset) are **reported only, never changed here**. They're repo settings with a blast radius, and `/n8-init` §6 is where they get set deliberately. Name any that are missing and point at re-running init.

## 4. Memory sweep

Newer versions retire conventions that old memories still prescribe, and a memory that disagrees with a skill blends with it unpredictably, just as a conflicting `CLAUDE.md` does. Read `.n8/memory/*.md` and the project's auto-memory (`MEMORY.md` and the files it indexes, in the auto-memory directory named in your system prompt). Flag each entry that:

- tells a session to do something a catalog entry or a current skill now does differently (e.g. "watch CI with `gh run watch`", "background the dev server with `&`");
- refers to a command, label, or file that no longer exists; or
- duplicates what the updated `CLAUDE.md` block now says.

For each one, quote the entry, name what superseded it, and propose an edit or a deletion. Don't flag memories outside n8SDLC's domains (issue workflow, branching and PRs, planning, audits, releases, wiki, background work).

## 5. Propose, then apply

Show a single list: the findings from §3 and §4, each with its exact fix (a diff for file edits). Ask once. The user can accept all, pick items, or decline. Then:

- Apply the approved repo edits on one branch, and land it with the state-commit flow in `reference/state.md` (`n8/upgrade-state` → PR → squash-merge → fast-forward main). Labels are created directly (`gh label create`, never `--force` here).
- Edit approved auto-memory files in place. They're outside the repo, so tell the user which files changed.
- Set `plugin_version: <plugin version>` in `.n8/config.yml` in the same branch, **only if every catalog check now passes** (declined items count as failing). If anything is still outstanding, leave the version where it was, so the session-start notice keeps offering the upgrade, and list what's left. A recorded version is a claim that the project is current, so don't make it falsely.

## 6. Report

State what changed, what was declined, and what needs the user (security settings, unanswered config questions). If nothing needed doing: "Project is current with n8SDLC <version>." in one line, and still record the version if it wasn't recorded yet.

An upgrade doesn't change where the project stands in the workflow, so hand back to status:

> ➡ Next: /n8-stat

**End on the Next line.** The reply's final line is `➡ Next: /n8-stat`, alone on the line, with nothing after it. If upgrade items are still outstanding, the next command is `/n8-upgrade` instead, and the sentence above it says why.
