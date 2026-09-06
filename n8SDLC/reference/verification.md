# Verification (n8SDLC)

Background for the n8SDLC skills — the reasoning behind the gates in `/n8-plan`, `/n8-exec`, `/n8-verify`, `/n8-audit` and `/n8-skill`, each of which carries its own commands — and the run-time vocabulary `/n8-feedback` uses to name the mode of a defect in which a check passed when the claim was false — by the bold short name below.

Two rules; the second is worthless without the first.

1. **Never destroy evidence you might need.** A check cannot find what was discarded before it ran. You cannot know in advance which output will matter — the whole failure class is that the thing that mattered was unanticipated. Suppression applies to what you *read*, never to what is *written*; each skill names which commands this covers.
2. **A check is only evidence if its result would differ when the thing is broken.** Ask what the check would show if the claim were false. If the answer is "the same thing", nothing was checked.

Where it is cheap, don't reason about rule 2 — demonstrate it. Watch the check fail once against a state known to be broken: the test run against the pre-change build, the command run without suppression, the document handed to a reader who can genuinely fail to follow it. **A check never seen to fail is not known to be a check.**

## How checks lose discriminating power

1. **existence-for-behaviour** — Existence stands in for behaviour. The symbol resolves, the file is there; what it *does* is untested. Existence checks pass on every false claim about behaviour — this is the mode that makes careful people confident.
2. **positive-half-only** — Only the positive half is asserted. Passes against code that does the thing unconditionally. The discriminating evidence is the complement: what should *not* have happened, or what should have *stopped*.
3. **report-not-effect** — The report is checked instead of the effect. Exit codes, success messages, a script's own summary line. A command's self-report is authored by the command.
4. **discarded-channel** — The output that would have shown the failure went to `/dev/null`, was truncated unread, or was filtered for the expected string. See rule 1.
5. **shared-context** — The checker shares the author's context. Self-review, or testing a document in the session that wrote it. The check inherits precisely the assumptions that produced the defect, so it cannot fail. The remedy is a fresh context — a subagent with no history of the work — not more care.
6. **proxy-enumeration** — The enumeration source is a proxy for the real surface. Reads as a complete survey while being structurally incapable of finding what the proxy omits. Applies to any list that defines scope: a UI palette standing in for a specification, a check list standing in for "is CI configured".
7. **narrow-scope** — The result's scope is narrower than the confidence it conveys. A partial check reporting a global-sounding green.

## Corollaries

- **A green carries only the coverage of the check.** Any mechanical guard states what it does *not* cover, so its result is not read as broader assurance than it is.
- **When your method turns out to be wrong, re-check what that method already produced.** Catching the bug and repairing its history are separate obligations.
- **A false green costs more than a red.** It becomes the next step's input and compounds silently in whatever direction the run is already going, and it gets written up with confidence. A visible failure stops; a false success survives review, because the transcript shows a command, a clean exit, and a plausible next step. This is what justifies the cost of everything above.

## Where to spend it

Where a false green **travels**: a later step builds on the result, or the result is reported to someone as assurance. In practice — autonomous runs, filed findings, and documents an agent will later read as instruction. A check whose only consumer is you, right now, looking at the thing, needs no ceremony. The skills convert this into bright-line rules ("every command that changes state", "every new skill") so it is never re-derived per command.

## Guarding the guard

"I considered whether this check discriminates" is exactly as unfalsifiable as "I read it back and it looks right." A gate produces an **artifact** — the observed red, the printed conflict, the named uncovered scope, the fresh reader's critique — never an assertion of diligence. **A gate whose output is the author saying yes is mode 5, `shared-context`**, and does not count.
