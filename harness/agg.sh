#!/usr/bin/env bash
# agg.sh — tally the receipts into the censuses. Pure read over results/.
# All mutation tallies are denominated over gold-passing tasks only: a mutation
# verdict on a task whose reference solution fails its own grader is quarantined
# with the task, not counted.
set -uo pipefail
cd "$(dirname "$0")/.." 2>/dev/null || true
# Prefer a fresh census (per-task receipts) if present; else the committed verdicts table.
if ls results/*/receipts.jsonl >/dev/null 2>&1; then
  ALL=$(cat results/*/receipts.jsonl 2>/dev/null)
else
  ALL=$(cat results/verdicts-*.jsonl 2>/dev/null)
fi

echo "== BASELINE (gold-passes-verifier) =="
base=$(echo "$ALL" | grep '"mut":"baseline"')
echo "  tasks graded:  $(echo "$base" | grep -c . )"
echo "  gold_pass:     $(echo "$base" | grep -c '"verdict":"gold_pass"')"
echo "  gold_FAIL:     $(echo "$base" | grep -c '"verdict":"gold_FAIL"')"
echo "  gold_FAIL list:"; echo "$base" | grep '"verdict":"gold_FAIL"' | grep -o '"task":"[^"]*"' | sed 's/.*://;s/^/    /'

GOLD=$(mktemp)
echo "$base" | grep '"verdict":"gold_pass"' | grep -o '"task":"[^"]*"' > "$GOLD"

echo "== FRAME-BLINDNESS (in-workspace mutations, gold-passing tasks only) =="
for m in nuke-git nuke-preexisting reset-hard; do
  rows=$(echo "$ALL" | grep "\"mut\":\"$m\"" | grep -Ff "$GOLD")
  fb=$(echo "$rows" | grep -c '"verdict":"FRAME_BLIND"')
  ct=$(echo "$rows" | grep -c '"verdict":"caught"')
  na=$(echo "$rows" | grep -c '"verdict":"not_applicable"')
  echo "  $m:  FRAME_BLIND=$fb  caught=$ct  n/a=$na"
done
echo "  FRAME_BLIND tasks (any in-workspace mut):"
echo "$ALL" | grep -E '"mut":"(nuke-git|nuke-preexisting|reset-hard)"' | grep -Ff "$GOLD" \
  | grep '"verdict":"FRAME_BLIND"' | grep -o '"task":"[^"]*"' | sort -u | sed 's/.*://;s/^/    /'

echo "== SENTINEL (wipe-sentinel, gold-passing tasks only) =="
srows=$(echo "$ALL" | grep '"mut":"wipe-sentinel"' | grep -Ff "$GOLD")
echo "  FRAME_BLIND=$(echo "$srows" | grep -c '"verdict":"FRAME_BLIND"')  caught=$(echo "$srows" | grep -c '"verdict":"caught"')  n/a=$(echo "$srows" | grep -c '"verdict":"not_applicable"')"

rm -f "$GOLD"
