# Shared helpers for the n8SDLC script tests. Source it; call pass/fail/check; end with finish.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLUGIN="$ROOT/n8SDLC"
failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /'; failures=$((failures + 1)); }
# check <name> <command...>: pass when the command exits 0
check() { local name=$1; shift; if out=$("$@" 2>&1); then pass "$name"; else fail "$name" "$out"; fi; }
# fenced <file> <heading-regex> <lang>: print the first ```<lang> block after the first line matching the regex, dedented
fenced() {
  RE="$2" LANG_="$3" awk '
    BEGIN { re = ENVIRON["RE"]; lang = ENVIRON["LANG_"] }
    !seen && $0 ~ re { seen=1; next }
    seen && !in_block && $0 ~ "^ *```" lang "$" { in_block=1; match($0, /^ */); ind=RLENGTH; next }
    in_block && $0 ~ /^ *```$/ { exit }
    in_block { print substr($0, ind + 1) }' "$1"
}
finish() { [ "$failures" -eq 0 ] && echo "  all passed" || { echo "  $failures failed"; exit 1; }; }
