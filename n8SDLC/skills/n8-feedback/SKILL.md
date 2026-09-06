---
name: n8-feedback
description: Feed a learning about the n8SDLC plugin itself back upstream — when a /n8-* skill's instructions failed, misled, were ambiguous, or missed something, package it as an issue on the plugin repo (nathanpond/n8SDLC-Skills), sanitized of all project specifics and shown to the user in full before anything is sent. Use whenever the user says "n8-feedback", "report that to the plugin", "file that upstream", or a skill defect surfaced during any n8SDLC run.
argument-hint: "<what the plugin got wrong or could do better>"
---

# /n8-feedback — Upstream a Learning

The skills improve only when field learnings reach the plugin repo — the live-test rounds fixed ~60 defects this way, and every project using n8SDLC finds more. This command packages one learning as an issue on **nathanpond/n8SDLC-Skills**.

Two absolutes, in tension order: **nothing is ever sent without the user approving the exact final text**, and the issue files under *the user's* GitHub account — their name is on it, which is one more reason the preview gate has no exceptions.

## 1. Capture the learning

Pin down: which skill or reference file, what its text says (quote the actual line — the skill files are public, quoting them leaks nothing), what happened instead, the workaround used (or `none`), and a suggested fix if one is obvious. Classify it — precedence in this order: **defect** (instruction wrong, a command fails as written, or a check that showed green when the claim was false — including a "check" that would have shown the same thing either way — a defect even where the skill was also silent), **gap** (a situation the skill is silent on and no check misfired), or **enhancement** (worked, but a better way exists). An ambiguous instruction is a defect.

If the learning is a check that passed when it should have failed, name the **primary** mode by its bold short name in `${CLAUDE_PLUGIN_ROOT}/reference/verification.md`: of the modes that explain why the check the skill's text prescribed would have shown the same result had the claim been false, the one whose description names the mechanism most specifically; the others that apply are secondary, in list order. Written as `primary: proxy-enumeration` / `secondary: narrow-scope`. It lets the plugin fix the class, not the instance.

## 2. Sanitize by construction

Write the draft for a public issue on someone else's repo from the first word — sanitization is how it's written, not a scrub afterward:

- Describe the defect in terms of the **skill's text and the situation shape**, never the project. "A story whose AC required demonstrating a CI failure" — not the story's actual title, repo, or domain.
- Strip and genericize: project/repo names → "the project"; file paths from the project → the *kind* of file ("a workflow file", "the storage module"); code, URLs, domains, business context, names of people, companies and the project's own services → gone or generic. The CI provider, cloud platform, OS and tool versions stay — they are usually the point.
- Error messages are allowed with repo/path fragments scrubbed. Environment facts (gh version, OS, stack family) are allowed — they're often the point.
- The test: a reader should learn nothing about the project except that it uses n8SDLC. You cannot run it on your own draft, and the user shares the project's context — so hand the body alone to a fresh `general-purpose` subagent (never `fork`) with "Using only the text below — no tools, no knowledge of the host or of n8SDLC — list everything you can infer about the project, its people, or its stack", and put its answer in the preview. Any item on that list that is not a CI provider, cloud platform, OS, tool version or stack family is a leak: redact before showing the user. Their approval then covers secrets and intent.

Draft the body in one Bash call — `F=$(mktemp /tmp/n8-feedback.XXXXXX); cat > "$F" <<'EOF' … EOF; echo "$F" | tee /tmp/n8-feedback.path` — the printed path is what §5 uses, since the variable dies with this shell, and the Write tool refuses an existing file it hasn't read. The body has these bold-label sections in order — **Skill / step**; **Text** (the skill's actual line, quoted); **Situation shape**; **Expected**; **Workaround** (or `none`); **Classification** (the word and the rule that decided it); **Mode** (`primary: <name>` / `secondary: <names>`, or omitted when no check misfired); **Suggested fix**; **Environment** (OS, gh version, CI provider, and the plugin version — read `"version"` from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` with the Read tool; the variable is not exported to the shell) — ending with `<!-- fingerprint: <skill>|<slug> -->`, the slug being three to six hyphenated words naming the *defect*, not the situation (`merge-gate-zero-checks`, not `bpmn-milestone-ci`).

## 3. Dedup against the plugin repo

```bash
gh issue list -R nathanpond/n8SDLC-Skills --state all --search "<skill name>" --json number,title,state,body   # the list is short; judge titles, don't add keywords (they AND)
gh issue list -R nathanpond/n8SDLC-Skills --state all --search 'in:body "fingerprint: <skill>|<slug>"' --json number,title,state
```

Before trusting `[]` from the second, prove the search can hit: take any `fingerprint:` line from the first command's bodies (`--jq '.[].body' | grep -o 'fingerprint: [^ ]*' | head -1`) and run the second with it; `[]` there means the search is broken, not the tracker empty. A match is the **full** fingerprint, or a title naming the same skill *and* step; a hit on the skill prefix alone is a different defect in the same skill, not a match. An **open** match → offer a confirmation comment made of the draft's Situation shape, Mode and Environment sections plus "reproduces on <installed version>" (same preview gate). A **closed** match → `gh issue view <n> -R nathanpond/n8SDLC-Skills --json comments --jq '.comments[].body' | grep -oE 'Shipped in [0-9.]+' | tail -1` gives the version it shipped in (none found → treat as not shipped and refile). Compare that with the plugin version recorded in the body's Environment — the version the defect was *seen* on: seen-on older than shipped-in → tell the user to run `/plugin update`, and ask whether it reproduces on the current version before writing "reproduces on"; seen-on at or past it → refile, adding the line `Refiles #<n> (shipped in <v>; reproduces on <installed>)` above the fingerprint.

## 4. The preview gate

Show the user the **complete issue — title and body, verbatim, exactly as it will be posted** — and ask them explicitly to check it for secrets, proprietary details, or anything that identifies the project. They edit, redact, approve, or decline. Approval must be explicit and in this session; a past "yes" never carries forward.

**Declined is a fine outcome:** offer to save the learning to `.n8/memory/` instead, so the project itself still benefits even if upstream never hears about it.

## 5. File

```bash
gh issue create -R nathanpond/n8SDLC-Skills --title "<skill>: <specific problem>" \
  --label field-report --body-file "$(cat /tmp/n8-feedback.path)"   # or paste the path §2 printed; then rm both files
```

Title convention mirrors the plugin's own: the skill name as the area (`n8-exec: post-merge state check misses …`). Reply with the issue URL, one line, and get back to whatever was in progress.
