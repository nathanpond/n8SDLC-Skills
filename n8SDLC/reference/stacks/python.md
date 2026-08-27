# Stack: Python

## Detect
`pyproject.toml`, `requirements.txt`, `setup.py`, `uv.lock`, `poetry.lock`.

## Scaffold
Prefer `uv` (fall back to poetry if the user asks, or plain venv+pip if neither is installed):

```bash
uv init <name> --package        # or --app for a simple app layout
uv add --dev pytest ruff mypy
```

Ask which shape: CLI, API service (FastAPI default), library, data/script project. Use `src/` layout for packages. Python version pinned in `pyproject.toml` / `.python-version`.

## Tests / quality
- Test: `uv run pytest`
- Lint/format: `uv run ruff check` and `uv run ruff format --check`
- Types: `uv run mypy .` (strictness per user preference)

## CI (GitHub Actions)
`astral-sh/setup-uv` → `uv sync` → ruff → mypy → pytest. Deploy per roadmap answers.

## Audit tooling
- Dependencies: `pip-audit` (or `uv run pip-audit`), Dependabot
- Static analysis: CodeQL (python), Semgrep (`semgrep --config p/python`), Bandit for security patterns
- Fuzzing (where applicable): Atheris for parsers/deserializers
