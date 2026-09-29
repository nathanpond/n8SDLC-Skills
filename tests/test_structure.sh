# 0.7.0: manifests, references and docs stay consistent with each other.
source "$(dirname "$0")/lib.sh"
pv=$(python3 -c 'import json;print(json.load(open("'"$PLUGIN"'/.claude-plugin/plugin.json"))["version"])')
mv=$(python3 -c 'import json;print(json.load(open("'"$ROOT"'/.claude-plugin/marketplace.json"))["metadata"]["version"])')
[ "$pv" = "$mv" ] && pass "plugin.json and marketplace.json versions match ($pv)" || fail "plugin.json and marketplace.json versions match" "plugin $pv, marketplace $mv"
grep -q "^## $pv\$" "$PLUGIN/reference/upgrades.md" && pass "upgrades.md has an entry for $pv" || fail "upgrades.md has an entry for $pv" "each release that changes project-side setup adds one; a release that doesn't still adds '## $pv' saying 'no project-side changes'"

missing=$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./<>-]+' "$PLUGIN/skills" "$PLUGIN/reference" "$PLUGIN/hooks" \
  | sed 's/[.,)]*$//' | grep -v '<' | sort -u | while read -r p; do [ -e "${p/\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN}" ] || echo "$p"; done)
[ -z "$missing" ] && pass "every \${CLAUDE_PLUGIN_ROOT} path exists" || fail "every \${CLAUDE_PLUGIN_ROOT} path exists" "$missing"

for d in "$PLUGIN"/skills/*/; do
  s=$(basename "$d")
  [ "$s" = n8-help ] || grep -q "\`/$s" "$PLUGIN/skills/n8-help/SKILL.md" || fail "/$s is listed in /n8-help"
  grep -q "\`/$s" "$ROOT/README.md" || fail "/$s is listed in the README"
done
pass "skills are listed in /n8-help and the README (failures above if not)"

[ -x "$PLUGIN/hooks/version-check.sh" ] && pass "hook script is executable" || fail "hook script is executable"
if command -v claude >/dev/null; then check "claude plugin validate" claude plugin validate "$PLUGIN"
else echo "  skip claude plugin validate (claude CLI not on PATH)"; fi
finish
