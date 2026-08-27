---
name: n8-release
description: Cut a release in an n8SDLC project — tag a verified commit on main, create the GitHub release with notes generated from merged PR titles, and trigger whatever the CI milestone wired to tags (production deploy, package publish). "/n8-release" proposes the next version; "/n8-release 1.2.0" or "/n8-release minor" pins it. Use whenever the user says "n8-release", "cut a release", "ship it", "tag a version", or accepts the release offer after /n8-verify closes a milestone.
argument-hint: "[X.Y.Z | major | minor | patch]"
---

# /n8-release — Cut a Release

Tag-on-main model: milestone PRs merge to `main` continuously; a release is *choosing a verified point on main and stamping it*. `main` at a release tag is exactly what shipped (`git checkout vX.Y.Z`), while dev/stage environments deploy from ordinary merges. This command never runs automatically — releases are outward-facing and effectively irreversible (deploy workflows pull tags, registries cache packages), so a human triggers it and confirms the final push.

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` and `${CLAUDE_PLUGIN_ROOT}/reference/state.md`. Check `.n8/config.yml` for the deployment/CI answers — they say what a tag *does* in this project.

## 1. Preconditions (hard stops — releases ship only verified work)

- Local `main` is current with `origin/main`, working tree clean, and the release target is its tip.
- Every milestone whose work is in this release is **verified-closed** (closed by `/n8-verify`, not by hand). An executed-but-unverified milestone in the range → stop and suggest `/n8-verify` first.
- CI is green on `main` (`gh run list --branch main` for the head SHA). No CI yet (pre-CI-milestone release) → run the full local suite as the gate and say so in the report.
- No open `confirmed` bugs against the released milestones.

## 2. Version

- Find the latest release (`gh release list --limit 1`, or `git tag --sort=-v:refname`). First release starts where the user says (commonly `v0.1.0`).
- Argument given → use it (`1.2.0`, or bump keyword applied to the latest). No argument → propose a semver bump from what actually shipped (breaking change → major, new capability → minor, fixes only → patch) and confirm with the user.
- If the stack carries a version in a file (`.csproj` `<Version>`, `package.json`, `pubspec.yaml`, `pyproject.toml`), bump it to match and land that through the normal PR flow before tagging — a tag whose code self-reports a different version is a small lie that compounds.

## 3. Confirm, then release

Show the user what's about to happen — version, target SHA, the milestones/PRs included, and **what the tag triggers** per the CI design (production deploy? package publish? nothing?) — and get an explicit go. Then check **who creates the release object**: read the tag-triggered workflow first. If it runs `gh release create` itself, your job is to push the tag and verify the workflow's release — running `gh release create` too would collide. Only when no workflow creates it do you run:

```bash
gh release create v<X.Y.Z> --title v<X.Y.Z> --generate-notes
```

Notes generate from merged PR titles (which carry their issue numbers — that's why). Either way, add a short human-written summary above the generated notes (`gh release edit`) when the release is user-facing: what this version *means*, in the same honest voice as the wiki. If CI attaches artifacts on tag, let it; verify they appear.

## 4. Watch what the tag set in motion

If a tag-triggered workflow exists (prod deploy, publish), watch it to completion (`gh run watch`). A release whose deploy failed is not shipped — report the failure plainly, and don't delete the tag to cover it; fix forward or let the user decide.

## 5. Record and report

- Log the release to `.n8/decisions.md` (version, SHA, milestones included, what was triggered).
- If the wiki is enabled, update Home's project-status section (honestly: "v1.2.0 shipped — covers M3–M4; M5 in progress"). A full reconcile stays `/n8-wiki`'s job.
- Report: release URL, notes summary, deploy/publish outcomes with real statuses, and the next step from `/n8-stat`'s logic.
