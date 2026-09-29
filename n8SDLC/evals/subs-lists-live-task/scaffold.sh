HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PV=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$HERE/../../.claude-plugin/plugin.json" | head -n 1)
source "$HERE/../_fixture.sh" "$PV"
cp "$HERE/../_claude_md_current.md" CLAUDE.md
git add -A && git commit -qm init
