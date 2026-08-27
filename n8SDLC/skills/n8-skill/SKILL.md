---
name: n8-skill
description: Build a project-specific skill inside the current n8SDLC project's .claude/skills/ — e.g. a plugin-creator skill for an app with a plugin system, a content-format skill, a deployment runbook. Run directly ("/n8-skill <idea>") or from /n8-plan's suggestions. Use whenever the user says "n8-skill", "build a skill for this project", "we need a skill that…", or approves a skill suggested during milestone planning.
argument-hint: "<what the skill should do>"
---

# /n8-skill — Project Skill Builder

Build a skill tailored to *this* project, into the project's own `.claude/skills/<name>/` (tracked in git, so it travels with the repo and works for any agent session on it). This is how the n8SDLC process grows project-specific capabilities — `/n8-plan` suggests candidates, this command builds them.

If the `skill-creator` skill is available in this session, invoke it and build within its process — it carries the full authoring-and-eval loop. Otherwise follow the essentials below.

## Essentials

**1. Capture intent.** From the user's description (or the plan suggestion): what should the skill enable, when should it trigger, what's the expected output? For a repetitive-task skill (the common case — "create a plugin", "add a content pack", "cut a release"), walk the project's actual code to ground it: real file paths, real interfaces, real conventions. A skill that describes the codebase as it is beats one that describes how codebases usually are.

**2. Write it.**

```
.claude/skills/<skill-name>/
├── SKILL.md            # frontmatter: name, description; body: the instructions
├── references/         # docs loaded as needed (interface specs, examples)
└── scripts/            # deterministic steps as runnable scripts
```

- The **description** is the trigger — say what it does *and* when to use it, concretely and a little pushily (models under-trigger skills).
- Keep SKILL.md focused (<500 lines); push detail into `references/`.
- Prefer imperative instructions that explain *why*, over walls of MUSTs.
- If every use of the skill would rewrite the same helper, write it once into `scripts/` and point the skill at it.
- Include one worked example with real project paths.

**3. Test it.** Exercise the skill on a realistic task (subagent if available, inline otherwise). Does following only the written instructions produce the right result? Fix what confused it.

**4. Land it.** Commit to the project (`chore: add <name> skill`). If planning suggested this skill for specific stories, comment on those issues that the skill now exists. Tell the user the trigger phrase.
