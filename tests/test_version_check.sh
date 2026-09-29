# 0.7.0: the SessionStart hook suggests /n8-upgrade when the project's plugin_version differs.
source "$(dirname "$0")/lib.sh"
hook="$PLUGIN/hooks/version-check.sh"
plugin_version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" | head -n 1)
proj=$(mktemp -d); trap 'rm -rf "$proj"' EXIT
run() { CLAUDE_PROJECT_DIR=$proj CLAUDE_PLUGIN_ROOT=$PLUGIN sh "$hook"; }
msg() { run | python3 -c 'import json,sys; s=sys.stdin.read(); print(json.loads(s)["systemMessage"] if s.strip() else "")'; }
with_version() { mkdir -p "$proj/.n8"; printf 'stack: x\n%s\n' "$1" > "$proj/.n8/config.yml"; }

rm -rf "$proj/.n8"
[ -z "$(run)" ] && pass "silent outside an n8SDLC project" || fail "silent outside an n8SDLC project" "$(run)"

with_version ""
case "$(msg)" in *"hasn't recorded"*/n8-upgrade*) pass "unrecorded version suggests /n8-upgrade";; *) fail "unrecorded version suggests /n8-upgrade" "$(msg)";; esac

with_version "plugin_version: 0.0.1"
case "$(msg)" in *"updated to $plugin_version"*"set up for 0.0.1"*/n8-upgrade*) pass "older project suggests /n8-upgrade";; *) fail "older project suggests /n8-upgrade" "$(msg)";; esac

for v in "plugin_version: $plugin_version" "plugin_version: \"$plugin_version\"" "plugin_version: '$plugin_version'  # upgraded"; do
  with_version "$v"
  [ -z "$(run)" ] && pass "silent when current ($v)" || fail "silent when current ($v)" "$(run)"
done

with_version "plugin_version: 99.0.0"
case "$(msg)" in *"upgraded with n8SDLC 99.0.0"*"/plugin"*) pass "newer project says update the plugin";; *) fail "newer project says update the plugin" "$(msg)";; esac

with_version "plugin_version: 0.10.0"
if [ "$(printf '%s\n0.10.0\n' "$plugin_version" | sort -V | tail -n 1)" = "0.10.0" ]; then
  case "$(msg)" in *"upgraded with n8SDLC 0.10.0"*) pass "versions compare numerically (0.10.0 > $plugin_version)";; *) fail "versions compare numerically" "$(msg)";; esac
fi

with_version "plugin_version: 0.0.1"
run | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["hookSpecificOutput"]["hookEventName"]=="SessionStart"; assert "/n8-upgrade" in d["hookSpecificOutput"]["additionalContext"]' \
  && pass "output is valid SessionStart JSON with context for Claude" || fail "output is valid SessionStart JSON with context for Claude"

check "hooks.json is valid JSON" python3 -m json.tool "$PLUGIN/hooks/hooks.json"
finish
