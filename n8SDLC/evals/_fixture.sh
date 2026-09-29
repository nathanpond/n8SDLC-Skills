# Sourced by each case's scaffold.sh (which runs in the empty eval workspace).
# Builds a small initialized n8SDLC project with git history and no remote. $1 = plugin_version to record ("" = none).
set -e
git init -q -b main
git config user.email eval@example.com; git config user.name eval
mkdir -p src test .n8/memory .github/workflows
cat > package.json <<'J'
{ "name": "tallyho", "version": "0.3.1", "type": "module",
  "scripts": { "test": "sleep 20 && echo 'tests passed'", "build": "echo built" } }
J
echo 'export const add = (a: number, b: number) => a + b;' > src/index.ts
cat > .github/workflows/ci.yml <<'J'
name: ci
on: [pull_request]
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: npm test
J
cat > .github/dependabot.yml <<'J'
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
J
{ echo "version: 1"; [ -n "$1" ] && echo "plugin_version: $1"
  printf 'stack: typescript\ninitialized: 2026-09-01\nwiki: opted-out\nrepo: example/tallyho\nvisibility: private\ncontext7: declined\nsecurity_findings: issues\nareas: [lib, ci, docs]\n'; } > .n8/config.yml
printf '# Decisions\n\nAd-hoc entry format: `## Ad-hoc — <date>` then Change / Why / Affects lines.\n' > .n8/decisions.md
touch .n8/memory/.gitkeep
