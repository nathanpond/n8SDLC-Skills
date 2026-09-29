#!/usr/bin/env bash
# Runs every tests/test_*.sh. Exit 1 if any file fails.
cd "$(dirname "$0")" || exit 1
status=0
for t in test_*.sh; do
  echo "== $t"
  bash "$t" || status=1
done
[ $status -eq 0 ] && echo "ALL PASSED" || echo "FAILURES ABOVE"
exit $status
