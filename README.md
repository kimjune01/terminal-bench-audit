# terminal-bench-audit

A frame-validity audit of [Terminal-Bench 2.1](https://github.com/laude-institute/terminal-bench):
does a passing verdict certify that the task was completed, or does it forgive arbitrary
collateral damage to the container the agent was working in?

Terminal-Bench grades **properties of the final container state** and deliberately does not
inspect the agent's commands. It has the fail-to-pass half of SWE-bench's contract and no
pass-to-pass frame: no set of properties a passing solution must leave undisturbed. This
audit measures the gap with a model-free probe: run each task's own reference solution,
append a single careless accident (`rm -rf .git`, deleting files the solution never touched,
wiping planted off-task user assets), re-run the official grader, and read the verdict.
See [`DESIGN.md`](DESIGN.md) for the thesis and protocol.

## Results (Terminal-Bench 2.1, all 89 tasks)

- Baseline: 83 of 89 reference solutions pass their own grader; the 6 failures are
  quarantined, not counted as findings.
- **83 of 83 gold-passing tasks still pass after deleting planted off-task user assets**
  (a second git repository, an SSH private key, a customer-data file) that no task references.
- **41 of 83 (49%) survive at least one careless deletion inside the task's own workspace**
  (`rm -rf .git`, `git reset --hard HEAD~3`, or deleting pre-existing files outside the
  reference solution's footprint).

The write-up: [Terminal-Bench Is Blind to Destruction](https://june.kim/terminal-bench-frame).
[`CLAIMS.md`](CLAIMS.md) maps every number in it to the command that regenerates it and the
receipt that backs it. [`REPRODUCE.md`](REPRODUCE.md) is the setup.

## Reproduce a verdict

Every number traces to a re-runnable receipt. `harness/regrade.sh <task> <mutation>` pulls
the task's pinned image, runs the reference solution through the official grader, re-runs it
with a *careless* suffix (a documented terminal-agent accident, not an adversarial exploit),
and reads the reward. Receipts live under [`results/`](results/), one directory per task per
mutation: image digest, oracle footprint, deleted files, grader output, reward.

## License

Copyleft. Code under GPL-3.0-or-later; the written audit and data under CC BY-SA 4.0.
See [`LICENSE`](LICENSE).
