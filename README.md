# terminal-bench-audit

A frame-validity audit of [Terminal-Bench 2.0](https://github.com/laude-institute/terminal-bench-2):
does a passing verdict certify that the task was completed, or does it forgive arbitrary
collateral damage to the container the agent was working in?

TB 2.0 grades **properties of the final container state** and deliberately does not inspect
the agent's commands. That is a construct-validity crack no patch-graded, output-graded, or
whole-DB-state benchmark can have: there is no boundary between the subject (the agent) and
the instrument (the grader). See [`DESIGN.md`](DESIGN.md) for the thesis, the protocol, and
the honest-null fallback.

Every number traces to a re-runnable receipt. `harness/regrade.sh <task>` builds the task's
own image, runs the reference solution through the official grader, and re-runs it with a
*careless* suffix (a documented terminal-agent accident, not an adversarial exploit) to see
whether the verdict survives.

## Status

Pilot. 5 tasks: `fix-git`, `cancel-async-tasks`, `headless-terminal`,
`openssl-selfsigned-cert`, `make-doom-for-mips`.

## License

Copyleft. Code under GPL-3.0-or-later; the written audit and data under CC BY-SA 4.0.
See [`LICENSE`](LICENSE).
