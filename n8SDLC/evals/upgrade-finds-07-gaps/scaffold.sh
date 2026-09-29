HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../_fixture.sh" 0.6.0
cp "$HERE/../_claude_md_pre07.md" CLAUDE.md
git add -A && git commit -qm "tallyho on n8SDLC 0.6.0"
