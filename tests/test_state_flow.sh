# 0.7.0 (#12): the state-commit flow in reference/state.md never costs the user work.
source "$(dirname "$0")/lib.sh"
doc="$PLUGIN/reference/state.md"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fenced "$doc" '^## Committing state changes' sh > "$tmp/precheck.sh"
grep -q 'rev-list --count origin/main..main' "$tmp/precheck.sh" \
  && pass "state.md carries the unpushed-commit check" || fail "state.md carries the unpushed-commit check" "$(cat "$tmp/precheck.sh")"
grep -q 'git add -- <each state file' "$doc" && pass "state.md stages by path" || fail "state.md stages by path"
grep -q 'pull --ff-only origin main' "$doc" && pass "state.md resyncs with a fast-forward only" || fail "state.md resyncs with a fast-forward only"
bad=$(grep -rn 'reset --hard' "$PLUGIN/skills" "$PLUGIN/reference" | sed 's/Never fix it with `reset --hard`//' | grep 'reset --hard')
[ -z "$bad" ] && pass "no skill or reference instructs reset --hard" || fail "no skill or reference instructs reset --hard" "$bad"

# Behaviour, in a local remote/clone pair.
g() { git -c user.email=t@t -c user.name=t -c init.defaultBranch=main "$@"; }
g init -q --bare "$tmp/remote.git"
g clone -q "$tmp/remote.git" "$tmp/w" 2>/dev/null; cd "$tmp/w" || exit 1
g checkout -q -b main 2>/dev/null; echo a > a; g add a; g commit -qm base; g push -q origin main 2>/dev/null
echo wip > wip; g add wip; g commit -qm "user wip"
[ "$(bash "$tmp/precheck.sh" | tail -n 1)" = "1" ] && pass "precheck reports an unpushed commit" || fail "precheck reports an unpushed commit"
g reset -q --hard origin/main    # test setup only: back to a clean clone
[ "$(bash "$tmp/precheck.sh" | tail -n 1)" = "0" ] && pass "precheck passes on a clean clone" || fail "precheck passes on a clean clone"

echo user >> a; mkdir -p .n8; echo decision > .n8/decisions.md          # user's edit + the run's state edit
g switch -q -c n8/test-state origin/main && g add -- .n8/decisions.md && g commit -qm state && g push -q origin n8/test-state 2>/dev/null
[ "$(g show --name-only --format= HEAD)" = ".n8/decisions.md" ] && pass "state commit holds only the state file" || fail "state commit holds only the state file" "$(g show --stat HEAD)"
g clone -q -b main "$tmp/remote.git" "$tmp/m" 2>/dev/null
(cd "$tmp/m" && g merge -q --squash origin/n8/test-state >/dev/null && g commit -qm "state (#1)" && g push -q origin main 2>/dev/null)
g switch -q main && g pull -q --ff-only origin main \
  && pass "main fast-forwards to the squash merge" || fail "main fast-forwards to the squash merge"
[ "$(g status --porcelain)" = " M a" ] && pass "the user's uncommitted edit survives" || fail "the user's uncommitted edit survives" "$(g status --porcelain)"

echo diverge > b; g add b; g commit -qm "local"; (cd "$tmp/m" && echo x > c && g add c && g commit -qm other && g push -q origin main 2>/dev/null)
if g pull -q --ff-only origin main 2>/dev/null; then fail "ff-only refuses a diverged main"; else pass "ff-only refuses a diverged main"; fi
g log --format=%s | grep -qx local && pass "the refused pull kept the local commit" || fail "the refused pull kept the local commit"
finish
