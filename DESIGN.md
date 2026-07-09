# A Frame-Validity Audit of Terminal-Bench 2.0

Working title. The thesis, the protocol, and the honest-null fallback. This file is
the spec; the harness implements it and every number traces to a re-runnable receipt.

## The claim

Terminal-Bench 2.0 grades **properties of the final container state** and deliberately
does not inspect the agent's commands. That choice creates a defect no patch-graded
(SWE-bench), output-graded (ProgramBench), or whole-DB-state (τ-bench) benchmark can
have: **there is no boundary between the subject and the instrument.** The agent's
writable set, the grader's read/execute set, and the grader's assert set all live in one
mutable filesystem.

It cuts two ways.

- **Frame blindness (grader asserts too little).** The tests are a sparse predicate over
  a dense mutable state; everything unasserted is forgiven. A trajectory that completes
  the task *and also* destroys unrelated state the user cares about still scores 1. Flagship
  specimen: `fix-git` says "merge my changes into master," the grader hashes exactly two
  files and never opens `.git`, so `solve.sh` followed by `rm -rf .git` still passes.
  Census (Fable, over all 89): ~80/89 tasks carry **zero** preservation assertion.

- **Shared-substrate oracle (agent can write what the grader reads).** The verdict is a
  function of the agent's incidental, instruction-licensed environment edits, not just task
  completion. 82/89 `test.sh` run `apt-get update` + fetch `uv` at grade time *inside the
  mutated container*; `headless-terminal` pip-installs into the same system python its own
  instruction tells the agent to modify. A perfect solution can score 0 from a held dpkg
  lock or an edited `sources.list`. Second barrel, not the headline. **Frame it as oracle
  integrity, never "network access,"** or it collapses into the authors' conceded
  hermeticity limitation.

### Why this is not the reward-hacking lane (which is crowded and conceded)

The perturbation is the **oracle's own `solve.sh`** plus a *careless* suffix drawn from
documented terminal-agent accidents (`git reset --hard`, wrong-directory `rm -rf`,
`apt-get autoremove`), not an adversarial agent trying to shortcut the test. The claim is
about **what a passing verdict certifies** — "task completed" is issued for a trajectory
that also vandalized the environment — not about whether tests can be gamed. Construct
validity, not exploitability.

### The card that beats a hostile TB referee

TB's own `sanitize-git-repo` ships `test_no_other_files_changed`, a git-diff against a
pinned commit. So the authors **do** treat collateral preservation as part of correctness;
they just remembered it in 1–9 of 89 tasks. They cannot call preservation unrealistic when
their own corpus asserts it. Internal inconsistency is the strongest single receipt.

### Where this sits relative to the prior audits (it is additive, not a port)

It is the **dual** of the determinacy audits. Determinacy audits the *input* side: does the
spec pin the graded behavior? Frame-validity audits the *oracle* side: does the graded
behavior pin task completion, or does it forgive arbitrary collateral damage? Under-specified
prompt vs under-specified oracle.

## The protocol

Per task T, driven directly against the task's own `environment/Dockerfile`,
`solution/solve.sh`, and `tests/test.sh` (replicating what the official runner does, so a
skeptic re-runs it without our harness):

1. **Build** the environment image.
2. **Oracle baseline.** Run `solve.sh`, then `test.sh`; read `/logs/verifier/reward.txt`.
   Expect 1. A 0 here is a *gold-fails-its-own-verifier* finding (the DeepSWE move, for free).
3. **Oracle diff.** Snapshot the container filesystem before and after `solve.sh`.
   `oracle_diff(T)` = the set of paths the reference solution legitimately touches. This is
   the raw material for the v-next fix and the definition of "in frame."
4. **Vandal re-grade.** Run `solve.sh`, then a mutation M from the suite below (applied only
   where structurally applicable to T), then `test.sh`. Record reward.
   - reward still 1 **and** M's damage ⊄ `oracle_diff(T)`  ⇒  **frame-blind w.r.t. M**.
5. **Report** the task × mutation pass matrix, plus per-task `oracle_diff`.

Headline number: fraction of the 89 that still score 1 under at least one *plausible-accident*
mutation whose damage falls outside the oracle's own footprint.

### Mutation suite (task-agnostic, applicability-gated)

Each mutation is a real, documented terminal-agent failure mode, not an adversarial trick.
Applicability is decided by a mechanical predicate (e.g. the `.git` mutations only run on
tasks whose tree contains a `.git`).

| id | mutation | applicability predicate |
|---|---|---|
| `nuke-git` | `rm -rf .git` in the task's working dir | tree contains `.git` |
| `reset-hard` | `git reset --hard HEAD~3` | tree contains `.git` with ≥3 commits |
| `autoremove` | `apt-get autoremove -y && apt-get clean` | debian-family base |
| `wrong-rm` | `rm -rf` a sibling dir not named in the instruction | ≥1 sibling dir unmentioned in instruction.md |
| `truncate-logs` | `: > $(find . -name '*.log')` | any `*.log` present |
| `bg-process` | leave a runaway `yes >/dev/null &` | always |
| `corrupt-bashrc` | append garbage to `~/.bashrc` | always |

The suite is fixed and public. A task is counted frame-blind on the *weakest* applicable
mutation that survives, and we report which one, so the claim is legible per task.

## v-next construction rules (what makes this valuable, not just adversarial)

1. **Derive the frame whitelist from the oracle.** Record `oracle_diff(T)` once at authoring
   time; harness-level assert `agent_diff ⊆ oracle_diff ∪ declared_tolerance`. Zero per-task
   authoring cost, adoptable globally in Harbor. This is the fix for frame blindness.
2. **Grade from a read-only sidecar.** Pinned grader image, container fs mounted read-only,
   live services reached over the network namespace only. This is the fix for the
   shared-substrate oracle. (Frame as oracle integrity.)

## Honest-null discipline

If the 5-task pilot (`fix-git`, `cancel-async-tasks`, `headless-terminal`,
`openssl-selfsigned-cert`, `make-doom-for-mips`) comes back with near-zero flip rates on both
barrels, we **publish the null** — "TB 2.0's final-state oracles are frame-robust, here is the
census" is a real validation result — and fall back to the execution-sensitivity flip census.
Every claim is a lower bound that only grows with more mutations; we never assert a population
rate beyond the measured floor.

## Receipts

Every task ships its build log, oracle-baseline reward, `oracle_diff`, and the full vandal
pass matrix. A hostile reader re-runs `harness/regrade.sh <task>` and checks the verdict
without trusting this prose. An audit is a re-run, so it has to be re-runnable to be an audit.
