---
name: n8-file
description: Quick-capture something as a GitHub issue in an n8SDLC project without losing your place — "/n8-file the export button double-fires on slow connections". One minute of anchoring, file with needs-triage, back to work. Use whenever the user says "n8-file", "file that", "capture this as an issue", "add that to the backlog", or mentions a bug/task mid-conversation that shouldn't be fixed right now.
argument-hint: "<one-line description of the bug or task>"
---

# /n8-file — Quick Capture

Capture the thing as an issue and get out. Be fast: do not start working on it, and do not investigate beyond finding the anchor. This is the entry point of the escalation ladder — capture (`needs-triage`) → assess (planning or an audit turns it into a real labeled story/finding) → execute (`/n8-exec`).

Read `${CLAUDE_PLUGIN_ROOT}/reference/github.md` conventions if not already loaded.

1. **Duplicate check:** `gh issue list --state all --search "<key terms>" --json number,title,state`. If one exists, comment on it rather than filing, and say which.
2. **Anchor it:** locate the relevant code so the issue has a real anchor — `path:lines` and the area/subsystem it sits in. A minute, not ten.
3. **File:** `gh issue create --title "<area>: <specific problem>" --body-file <tmpfile> --label needs-triage`. Body: what, where, why it matters, how it was noticed. Add `security` and a `sev:*` label only when the problem is clearly a reachable security finding.
4. **Reply with the issue number and URL. One line.** Then return to whatever was in progress.

Captured issues carry no milestone — the next `/n8-plan` (or `/n8-replan`) pass triages `needs-triage` issues into the plan, or the user promotes them directly.
