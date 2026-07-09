#!/usr/bin/env bash
# run_pilot.sh — baseline + applicable mutations over the 5 pilot tasks.
# Requires: docker, and TB2_DIR pointing at a terminal-bench-2 clone.
set -uo pipefail
TB2_DIR="${TB2_DIR:?set TB2_DIR to the terminal-bench-2 clone}"
HERE="$(cd "$(dirname "$0")" && pwd)"

PILOT=(fix-git cancel-async-tasks headless-terminal openssl-selfsigned-cert make-doom-for-mips)
MUTS=(baseline nuke-git reset-hard autoremove truncate-logs bg-process corrupt-bashrc)

for t in "${PILOT[@]}"; do
  for m in "${MUTS[@]}"; do
    bash "$HERE/regrade.sh" "$TB2_DIR/$t" "$m"
  done
done
echo "=== pilot matrix ===" >&2
find results -name receipts.jsonl -exec cat {} + 2>/dev/null
