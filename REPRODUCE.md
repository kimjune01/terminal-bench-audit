# Reproducing this audit

Every verdict re-derives from three things Terminal-Bench already ships: the task's
pinned image, its reference solution, and its grader. You do not need our results to
check us. You need Docker and the task set. An audit is a rerun.

## Setup

- Docker, on an **amd64** host (the task images are `linux/amd64`; on Apple Silicon they
  emulate slowly and some fail).
- The task set: `git clone https://github.com/harbor-framework/terminal-bench-2-1`
- This repo's `harness/` drives the official artifacts directly, replicating the runner:
  pull the pinned image, run `solution/solve.sh`, snapshot the filesystem, append a
  careless mutation, run `tests/test.sh`, read `/logs/verifier/reward.txt`.

## Reproduce one verdict (the flagship)

```bash
export TB2_DIR=/path/to/terminal-bench-2-1/tasks
bash harness/regrade.sh "$TB2_DIR/fix-git" nuke-git
```

This pulls `alexgshaw/fix-git@<digest>`, runs the reference solution that merges the
branch, appends `rm -rf .git`, runs the official grader, and prints the verdict. Expect
`FRAME_BLIND` with `reward 1`: the whole repository is gone and the merge is certified
complete. Then run it with `baseline` and with `reset-hard` to see the grader pass the
clean run and *catch* the one mutation that reaches a file it hashes. The contrast is the
finding.

## Reproduce a whole census

```bash
TB2_DIR=.../tasks PAR=6 bash harness/run_all.sh                 # baseline + destructive muts, 89 tasks
TB2_DIR=.../tasks PAR=6 MUTS="wipe-sentinel" bash harness/run_all.sh
bash harness/agg.sh                                             # tally both censuses
```

`run_all.sh` is resumable: a task/mutation with a committed verdict is skipped, so a
killed run continues where it stopped.

## What a receipt is (`results/<task>/<mutation>/`)

| file | what it pins |
|---|---|
| `image.digest` | the `sha256` of the graded image (tags move; digests do not) |
| `oracle_diff.txt` | the paths the reference solution touched: the frame |
| `deleted.txt` | the files the mutation removed (destructive muts) |
| `reward.txt` | `0` or `1`, exactly as the official grader wrote it |
| `receipt.json` | the one-line verdict, self-contained |
| `*.log` | solve and grader output; regenerated on rerun, not committed |

`receipts.jsonl` under each task is the append log; `CLAIMS.md` maps every number in the
write-up to the receipts and the command that regenerates it.

If a verdict does not reproduce, it is not a finding. Take the receipts, rerun the
commands, and check us.
