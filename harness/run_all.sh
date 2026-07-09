#!/usr/bin/env bash
# run_all.sh — baseline + destructive mutations over every TB2 task, in parallel.
# Baseline doubles as a gold-passes-its-own-verifier census (the DeepSWE move).
# Requires: docker, TB2_DIR pointing at a terminal-bench-2 clone. PAR = parallelism.
set -uo pipefail
TB2_DIR="${TB2_DIR:?set TB2_DIR}"; HERE="$(cd "$(dirname "$0")" && pwd)"
PAR="${PAR:-6}"
export MUTS="${MUTS:-baseline nuke-git reset-hard nuke-preexisting}"
export HERE TB2_DIR

run_task() {
  local t="$1"
  for m in $MUTS; do bash "$HERE/regrade.sh" "$TB2_DIR/$t" "$m" >/dev/null 2>&1 || true; done
  echo "done: $t" >&2
}
export -f run_task

ls -1 "$TB2_DIR" | while read -r t; do [ -f "$TB2_DIR/$t/task.toml" ] && echo "$t"; done \
  | xargs -P "$PAR" -I{} bash -c 'run_task "$@"' _ {}
echo "=== ALL DONE ===" >&2
