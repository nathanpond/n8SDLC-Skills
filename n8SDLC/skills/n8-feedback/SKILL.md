---
name: n8-feedback
description: Feed a learning about the n8SDLC plugin itself back upstream — when a /n8-* skill's instructions failed, misled, were ambiguous, or missed something, package it as an issue on the plugin repo (nathanpond/n8SDLC-Skills), sanitized of all project specifics and shown to the user in full before anything is sent. Use whenever the user says "n8-feedback", "report that to the plugin", "file that upstream", or a skill defect surfaced during any n8SDLC run.
argument-hint: "<what the plugin got wrong or could do better>"
---

# /n8-feedback — Upstream a Learning

The skills improve only when field learnings reach the plugin repo — the live-test rounds fixed ~60 defects this way, and every project using n8SDLC finds more. This command packages one learning as an issue on **nathanpond/n8SDLC-Skills**.

Two absolutes, in tension order: **nothing is ever sent without the user approving the exact final text**, and the issue files under *the user's* GitHub account — their name is on it, which is one more reason the preview gate has no exceptions.

## 1. Capture the learning

Pin down: which skill or reference file, what its text says (quote the actual line — the skill files are public, quoting them leaks nothing), what happened instead, the workaround used, and a suggested fix if one is obvious. Classify it: **defect** (instruction wrong or a command fails as written), **gap** (a situation the skill is silent on), or **enhancement** (worked, but a better way exists).

## 2. Sanitize by construction

Write the draft for a public issue on someone else's repo from the first word — sanitization is how it's written, not a scrub afterward:

- Describe the defect in terms of the **skill's text and the situation shape**, never the project. "A story whose AC required demonstrating a CI failure" — not the story's actual title, repo, or domain.
- Strip and genericize: project/repo names → "the project"; file paths from the project → the *kind* of file ("a workflow file", "the storage module"); code, URLs, domains, business context, names of people or services → gone or generic.
- Error messages are allowed with repo/path fragments scrubbed. Environment facts (gh version, OS, stack family) are allowed — they're often the point.
- The test: a reader should learn nothing about the project except that it uses n8SDLC.

## 3. Dedup against the plugin repo

```bash
gh issue list -R nathanpond/n8SDLC-Skills --state all --search "<skill name> <keywords>" --json number,title,state
```

End the draft body with a fingerprint: `<!-- fingerprint: <skill>|<short-defect-slug> -->`. An **open** match → offer to add a confirmation comment with the new evidence instead of filing (the comment gets the same preview gate). A **closed** match → the fix may already be on `main`; check, and tell the user to update the plugin before refiling.

## 4. The preview gate

Show the user the **complete issue — title and body, verbatim, exactly as it will be posted** — and ask them explicitly to check it for secrets, proprietary details, or anything that identifies the project. They edit, redact, approve, or decline. Approval must be explicit and in this session; a past "yes" never carries forward.

**Declined is a fine outcome:** offer to save the learning to `.n8/memory/` instead, so the project itself still benefits even if upstream never hears about it.

## 5. File

```bash
gh issue create -R nathanpond/n8SDLC-Skills --title "<skill>: <specific problem>" \
  --label field-report --body-file "$SCRATCH/feedback.md"
```

Title convention mirrors the plugin's own: the skill name as the area (`n8-exec: post-merge state check misses …`). Reply with the issue URL, one line, and get back to whatever was in progress.
