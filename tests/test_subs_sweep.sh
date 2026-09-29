# 0.7.0: /n8-subs's OS sweep lists the session's live tool shells with their command, and nothing else.
# Runs the block exactly as written in the skill, under a fake parent named like `claude`.
source "$(dirname "$0")/lib.sh"
tmp=$(mktemp -d); trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$tmp"' EXIT
fenced "$PLUGIN/skills/n8-subs/SKILL.md" '^4\. \*\*The OS\*\*' bash > "$tmp/sweep.sh"
[ -s "$tmp/sweep.sh" ] || { fail "sweep block found in n8-subs SKILL.md"; finish; }
ln -s "$(command -v bash)" "$tmp/claude-harness"
cat > "$tmp/harness.sh" <<'H'
# Children of this (fake claude) process: a tool shell in the harness's shape, a fake MCP server, then the sweep itself.
bash -c ": shell-snapshots; eval 'sleep 30' < /dev/null && true" &
bash -c 'exec -a fake-mcp-server sleep 30' &
sleep 0.5
echo "--with"; bash -c "$(cat "$1")"
kill $(jobs -p); wait 2>/dev/null
echo "--without"; bash -c "$(cat "$1")"
H
out=$("$tmp/claude-harness" "$tmp/harness.sh" "$tmp/sweep.sh")
with=$(printf '%s\n' "$out" | sed -n '/^--with$/,/^--without$/p')
without=$(printf '%s\n' "$out" | sed -n '/^--without$/,$p')

printf '%s\n' "$with" | grep -qE '^SHELL pid=[0-9]+ up=[0-9:-]+ children=1  sleep 30$' \
  && pass "live tool shell listed with its command and one child" || fail "live tool shell listed with its command and one child" "$out"
[ "$(printf '%s\n' "$with" | grep -c '^SHELL')" -eq 1 ] \
  && pass "the sweep doesn't list its own shell" || fail "the sweep doesn't list its own shell" "$with"
printf '%s\n' "$with" | grep -q 'mcp' \
  && fail "MCP servers are filtered out" "$with" || pass "MCP servers are filtered out"
[ "$(printf '%s\n' "$without" | grep -c -E '^(SHELL|OTHER)')" -eq 0 ] \
  && pass "nothing listed once the shell has exited" || fail "nothing listed once the shell has exited" "$without"
finish
