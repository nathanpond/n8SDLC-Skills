# Project upgrades

What each plugin version changed **inside a project**: the files, config keys, and GitHub settings that `/n8-init` installs and that an already-initialized project doesn't get just by updating the plugin. `/n8-upgrade` reads this. Changes to skill behaviour alone take effect the moment the plugin updates, so they aren't listed here, with one exception: a new behaviour that expects something to be present in the project.

**Maintainers:** a release that changes anything init writes, or any convention a project stores (config keys, `decisions.md` header, labels, templates, the `CLAUDE.md` block), adds an entry here in the same commit. An entry names the check (how to tell whether a project already has it) and the fix. The checks are what `/n8-upgrade` runs, and version numbers only order them, because a project may have been hand-patched, half-upgraded, or never recorded a version.

The canonical text for every installed artifact lives where init defines it. This file points there and never keeps a second copy, since two copies drift.

---

## 0.7.0

- **`plugin_version:` in `.n8/config.yml`.** Check: the key exists. Fix: `/n8-upgrade` writes it last, after everything else passed. A project without it is treated as older than every entry, so every check below runs.
- **`CLAUDE.md` n8SDLC block: background-work paragraph.** Check: the `## n8SDLC project` section mentions `/n8-subs`. Fix: insert the paragraph from `/n8-init` §8b, before the `/n8-feedback` paragraph.

## 0.6.0

- **`dependabot.yml` covers GitHub Actions.** Check: `.github/dependabot.yml` has a `package-ecosystem: "github-actions"` entry. Fix: add it (weekly, directory `/`), leaving the other ecosystems as they are. Without it, pinned action majors go stale unnoticed. Skip the check if the project has no `.github/workflows/`, but say so, because the CI milestone will add workflows later.

## 0.2.0 (and unrecorded older projects)

- **`CLAUDE.md` n8SDLC block: `/n8-feedback` paragraph.** Check: the section mentions `/n8-feedback`. Fix: append the paragraph from `/n8-init` §8b.
- **Baseline for everything else** (labels, issue forms, `.n8/` layout, `decisions.md` header): no format changes since 0.1. `/n8-upgrade` still checks that each one is present, because a project initialized by a failed or partial init may be missing some.
