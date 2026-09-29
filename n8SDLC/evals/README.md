# n8SDLC behaviour evals

Regression cases for skill *behaviour*, run with `claude plugin eval`. They cost API usage, so they run
locally before each release, not in CI. The free script tests live in `../../tests/` and run in CI.

```sh
cd n8SDLC
claude plugin eval . --scaffold --allow-tools Bash Edit Write --ablation none --max-cost-usd 10
claude plugin eval . --scaffold --allow-tools Bash --ablation none --case upgrade-*   # one area
```

- `--scaffold` is required: each case builds its fixture project with `scaffold.sh` (shared parts in `_fixture.sh`).
- `--ablation none`: these test the plugin's own skills, so a no-plugin arm has nothing to compare.
- Evals have no network, so anything that needs GitHub (the delivery baseline, milestone numbering) isn't
  covered here. Those need a live run against a fixture repo.

**Adding a case:** one directory per behaviour that broke or must not break, named for the behaviour
(`upgrade-finds-07-gaps`), tagged with the version it arrived in. Prefer a `tool_used`, `regex` or `file`
grader for anything checkable mechanically, and an `llm` grader only for judgement.

**Known local limitation (2026-09-30):** on the maintainer's machine, Bash-granting cases refuse to run,
because `~/.docker` holds Docker Desktop's install symlinks (`bin/`, `cli-plugins/`) and the eval sandbox
can't reliably exclude them. `DOCKER_CONFIG` doesn't change this. Until that's resolved, only
`hook-suggests-upgrade` runs locally. The Bash cases stay in the suite, ready for a machine or CI runner
without that store. Releases cover their behaviour with a live, read-only run instead.
