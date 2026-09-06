---
name: n8-skill
description: Build a project-specific skill inside the current n8SDLC project's .claude/skills/ — e.g. a plugin-creator skill for an app with a plugin system, a content-format skill, a deployment runbook. Run directly ("/n8-skill <idea>") or from /n8-plan's suggestions. Use whenever the user says "n8-skill", "build a skill for this project", "we need a skill that…", or approves a skill suggested during milestone planning.
argument-hint: "<what the skill should do>"
---

# /n8-skill — Project Skill Builder

Build a skill tailored to *this* project, into the project's own `.claude/skills/<name>/` (tracked in git, so it travels with the repo and works for any agent session on it). This is how the n8SDLC process grows project-specific capabilities — `/n8-plan` suggests candidates, this command builds them.

If the `skill-creator` skill is available in this session, use it to draft — but steps 1–5 below apply in full to what it produces: the grounding walk, the location and shape, the gate, the landing, the maintenance rules. Its own evals do not count as a cold-test pass.

## Essentials

**1. Capture intent.** From the user's description (or the plan suggestion): what should the skill enable, when should it trigger, what's the expected output? For a repetitive-task skill (the common case — "create a plugin", "add a content pack", "cut a release"), walk the project's actual code to ground it: real file paths, real interfaces, real conventions. If that code is not at HEAD yet — a skill `/n8-plan` suggested for a milestone not built, or a direct request ahead of the code — note the suggestion on the story (or in `.n8/decisions.md` when there is none) and run `/n8-skill` after that milestone is verified. A skill that describes the codebase as it is beats one that describes how codebases usually are. A skill that describes the codebase as it is beats one that describes how codebases usually are.

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
- Include one worked example with real project paths, the two reader-facing rules from step 5 (verify before following; fix in the same commit), and a **proof step**: a command whose output shows the artefact works, runnable from a fresh checkout after the stack's install step ("`npm test -- --grep PluginRegistry` lists the new plugin"). A skill with no proof step cannot be cold-tested.

**3. Cold-test it — a gate, not a step.** The skill is **not done** until a fresh agent has tried to follow it and reported back. Reading a skill cannot validate it: an author reads their own intent through the text, so the gaps close invisibly.

- **The tester:** a `general-purpose` subagent — **never `fork`**, which inherits this session's context and so cannot fail the way a real reader fails.
- **Where:** a disposable worktree with the *uncommitted* skill copied in — a worktree is cut from HEAD, and on a first skill `.claude/` isn't at HEAD either, so create the directory before copying. From the repository root:
  ```sh
  W=/tmp/n8-cold-plugin-creator-1        # your skill's name; -2 for the second pass
  git worktree add "$W" HEAD && mkdir -p "$W/.claude" && cp -R .claude/skills "$W/.claude/"
  ```
  Before the `cp`, delete drafting artefacts from `.claude/skills/plugin-creator/` (skill-creator's eval files would hand the tester the answers). After it, `test -f "$W/.claude/skills/plugin-creator/SKILL.md" || echo "COPY FAILED"` — your skill's name in place of `plugin-creator`. Afterwards `git worktree remove --force "$W"`. The tester follows the skill against HEAD's code, so commit any code the skill describes before testing — for a post-landing fix that answers a code change, commit code and skill together, test, and amend. On macOS `/tmp` resolves to `/private/tmp`; `pwd -P` and `git worktree list` show the resolved form.
- **The prompt** carries `$W` (resolved with `pwd -P`), the skill's path inside it, the task, the build/run and install commands from the stack file (`${CLAUDE_PLUGIN_ROOT}/reference/stacks/<stack>.md`, for the `stack:` in `.n8/config.yml`) substituted in, and the fenced brief below — and no history. It states that every path read, written or run must be absolute and under `$W`, that the main checkout is off-limits, and that no git command may create or move a ref, push, or change config (`status`/`diff`/`log` are fine; a branch made in the worktree survives its removal). The tester's session is rooted in the main checkout, so CLAUDE.md and sibling skills reach it from there and the skill's *trigger* is not exercised by this gate — only its steps. The skill is its only *task* instruction.
- **The task:** one realistic task phrased from the skill's *description*, never from its steps — a task read off the steps will be one the steps cover.
- **The brief**, sent verbatim with the two commands substituted:
  ```
  Do the task using only the skill as instruction, in the worktree. Build or run what you produced with <build command> (run <install command> first if needed) and paste the full output whatever the outcome. Then run the skill's proof step and paste that output; if the skill names no proof step, or the proof produces no output, report STALL. List the paths of everything you created and every path you read or searched that the skill did not name. Class each finding STALL (could not proceed because of the skill), WRONG (the instruction produced the wrong result — quote it, show the failing output), GAP (had to discover it; the skill should have said it), or NIT (a stall caused by the environment — missing node_modules, a service you couldn't reach — or wording). A report with no build attempt is a failed test.
  ```
  You, not the tester, decide which unnamed paths are GAPs (CLAUDE.md and the stack file are not; the rest are dropped), and you re-run the build and the proof step yourself in `$W` before removing it — the pasted output is the tester's word, and the tester's word is not the evidence. A proof that produces no output when *you* run it is a STALL whatever the cause.
- **Acceptable run:** zero STALL, zero WRONG, at most five GAPs — on every run, including the last; a sixth GAP fails it. GAPs get fixed; they don't fail the run on their own.
- **Runs — at most two before landing or narrowing.** Run 1 with no finding but NITs lands as is (NITs are fixed without a re-test). Any GAP or WRONG fix gets run 2 in a fresh worktree (`…-2`); an acceptable run 2 lands after its GAPs are fixed, with no run 3. Run 2 with STALL or WRONG, or more than five GAPs, means the skill is unclear at a level rewriting won't fix: narrow its scope — to fewer steps, never to none — and give the narrowed skill one run (`…-3`); acceptable → fix its GAPs and land in the same commit; otherwise drop the skill and put all three reports on the planning story (or in `.n8/decisions.md` when there is none). After landing, a change to what a step instructs gets one run (`…-1` again) whose report goes in that change's commit; if it fails, narrow or remove that step — never revert to text the code change already invalidated — and the failed report goes in the commit that does so. Correcting an identifier the tester quoted as wrong gets none.
- **Record every run's report** in the body of the commit that lands the skill — the clean run is not the informative one.

**4. Land it.** Commit to the project (`chore: add <name> skill`). If planning suggested this skill for specific stories, comment the commit hash on those issues. Tell the user the trigger phrase.

**5. Keep it alive.** Skills grounded in real paths and symbols rot as the code moves. The **first two** rules belong in the generated skill's own body, addressed to whoever reads it next; the rest are for whoever maintains it.

- **Verify before following.** Treat each step as a claim that may have rotted; check that paths and symbols still match before acting on them.
- **Fix the skill in the same commit as the change that invalidated it.** "Later" won't happen.
- **Cite symbols, not line numbers.** `ApplyElementSnapshots` in `file.ext`, never `file.ext:513`. A line number in a code comment moves with what it describes; one in a skill points across the repository at a file that changes for unrelated reasons, with no compiler, test or reviewer linking the two. Where a range genuinely helps, say *what* it is rather than where — "the branch chain in `ApplyElementSnapshots` that dispatches by element type". Drift here is read as evidence the whole document is unmaintained, which poisons claims that are sound.
- **Edit corrections into the body at the point they apply — never append a changelog.** If a step is wrong, the step changes. Appending is what an audit pass naturally produces, and it yields a document asserting contradictory things about the same mechanism: the reader cannot tell which half is current, and the appendix is the half they are least likely to reach. A skill is a reference document, not a history — history belongs in the commit message. After correcting, read the document top-down once; anywhere the body and a correction disagree is a defect, not a record.
- **A shipped verification script matches symbols in context, not bare numbers** (a bare number also matches a line number or an issue number), and states what it does *not* cover.
- `/n8-audit docs` audits skills against the code as a standing sweep, but same-commit maintenance is what keeps drift from accumulating in the first place.
