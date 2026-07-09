#!/usr/bin/env bash
# agg.sh — tally the receipts into the two censuses. Pure read over results/.
set -uo pipefail
cd "$(dirname "$0")/.." 2>/dev/null || true
# Prefer a fresh census (per-task receipts) if present; else the committed verdicts table.
if ls results/*/receipts.jsonl >/dev/null 2>&1; then
  ALL=$(cat results/*/receipts.jsonl 2>/dev/null)
else
  ALL=$(cat results/verdicts-*.jsonl 2>/dev/null)
fi
j() { grep -o "\"$1\":\"\?[^,\"}]*" | sed "s/\"$1\"://;s/\"//g"; }

echo "== BASELINE (gold-passes-verifier) =="
base=$(echo "$ALL" | grep '"mut":"baseline"')
echo "  tasks graded:  $(echo "$base" | grep -c . )"
echo "  gold_pass:     $(echo "$base" | grep -c '"verdict":"gold_pass"')"
echo "  gold_FAIL:     $(echo "$base" | grep -c '"verdict":"gold_FAIL"')"
echo "  gold_FAIL list:"; echo "$base" | grep '"verdict":"gold_FAIL"' | grep -o '"task":"[^"]*"' | sed 's/.*://;s/^/    /'

echo "== FRAME-BLINDNESS (destructive mutations on gold-passing tasks) =="
for m in nuke-git nuke-preexisting reset-hard; do
  rows=$(echo "$ALL" | grep "\"mut\":\"$m\"")
  fb=$(echo "$rows" | grep -c '"verdict":"FRAME_BLIND"')
  ct=$(echo "$rows" | grep -c '"verdict":"caught"')
  na=$(echo "$rows" | grep -c '"verdict":"not_applicable"')
  echo "  $m:  FRAME_BLIND=$fb  caught=$ct  n/a=$na"
done
echo "  FRAME_BLIND tasks (any destructive mut):"
echo "$ALL" | grep '"verdict":"FRAME_BLIND"' | grep -o '"task":"[^"]*"' | sed 's/.*://' | sort -u | sed 's/^/    /'
