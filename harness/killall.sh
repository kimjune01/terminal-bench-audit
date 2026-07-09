#!/bin/bash
# Kill the degraded 2.0 pipeline (xargs + workers) only. Leaves the 2.1 chain alive
# (its cmdline uses bracketed patterns, so these pkills can't match it), so once
# regrade workers hit zero the chain auto-launches the clean 2.1 run.
pkill -9 -f "run_al[l].sh"
pkill -9 -f "xarg[s]"
pkill -9 -f "run_tas[k]"
pkill -9 -f "regrad[e].sh"
sleep 4
for c in $(docker ps -aq --filter name=tbaudit-); do docker rm -f "$c" >/dev/null 2>&1; done
echo "post-kill: regrade=$(pgrep -f "regrad[e].sh" | wc -l) xargs=$(pgrep -f "xarg[s]" | wc -l) containers=$(docker ps -aq --filter name=tbaudit- | wc -l)"
