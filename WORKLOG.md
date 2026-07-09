# Worklog — terminal-bench-audit

Newest entries at the bottom. Timestamps are the author's local time.

## 2026-07-08

- **Framing settled.** Audit target: Terminal-Bench 2.0 (arXiv 2601.11868), 89 tasks.
  Reward-hacking / contamination / hermeticity lanes ruled out (crowded, conceded, or
  a different disease). Chosen thesis: **frame validity** — TB grades final container
  state with no boundary between subject and instrument. See `DESIGN.md`.
- **Recon.** 5 Sonnet subagents scanned all 89 tasks for determinacy candidates:
  ~9 defensible + ~5 soft, a Pro-like ~10–16% cold-read floor (not the headline;
  kept as a companion axis). Fable (adversarial) beat my two candidate angles
  (baseline-credit = likely null; execution-sensitivity = a DeepSWE port) and produced
  the frame-blindness thesis: 80/89 tasks carry zero preservation assertion;
  `fix-git` passes after `rm -rf .git`; TB's own `sanitize-git-repo` concedes the construct.
- **Repo scaffolded.** `DESIGN.md`, `README.md`, dual-copyleft `LICENSE`
  (GPL-3.0 code / CC BY-SA 4.0 prose), `harness/regrade.sh` + `mutations.sh` + `run_pilot.sh`.
  Harness replicates the official runner: pull pinned image, run `solve.sh`, snapshot
  `oracle_diff`, apply a careless mutation, run official `test.sh`, read reward.
- **Runner mechanics confirmed** from `openssl-selfsigned-cert`: each `task.toml` pins a
  public `docker_image`; runtime capped at `cpus=1, memory_mb=2048`; `test.sh` installs
  curl+uv at grade time inside the mutated container (shared-substrate confirmed).
- **EC2 provisioned** (images are amd64; local arm64 would emulate). us-west-2,
  c6i.2xlarge, Ubuntu 24.04, 200GB gp3, SSH locked to author IP. Instance `i-0e2bc6628cd36a389`.
  Keypair `~/.ssh/tbaudit-key-1783577847.pem`. Teardown target recorded in `/tmp/tbaudit-ec2.env`.
- **Snag:** SSH loop failed due to zsh not word-splitting a bare `$SSH` var; fixed by
  inlining the ssh invocation. (Not a network/sandbox block.)
- **Next:** SSH in, clone tb2 + rsync the harness, run the 5-task pilot
  (`fix-git`, `cancel-async-tasks`, `headless-terminal`, `openssl-selfsigned-cert`,
  `make-doom-for-mips`), report the vandal pass matrix. Publish the null if flips ~0.

## 2026-07-08 (pilot results)

- **Harness validated after 2 fixes.** (1) Staged only `solve.sh`, not the whole
  `solution/` dir — broke `headless-terminal` (its solve.sh reads `/solution/headless_terminal.py`);
  fixed by staging `solution/.` at `/solution/`. (2) `make-doom-for-mips` needs `clang`
  and is a heavyweight build/exec + persistent-process task; set aside for the frame audit
  (it is the execution-sensitivity axis anyway).
- **Thesis CONFIRMED on the flagship.** `fix-git`: baseline reward 1;
  **`rm -rf .git` after solve → reward 1 (FRAME-BLIND)**; `git reset --hard HEAD~3` → reward 0.
  The contrast is the finding: the grader hashes two files and forgives deletion of the
  entire repository, but reacts the instant damage hits one of its two hashed files.
- **Grader-is-sensitive controls (in-frame damage caught):** `fix-git` reset-hard → 0;
  `headless-terminal` corrupt-bashrc → 0 (bashrc sourcing is part of that task's spec).
  These prove the grader *can* catch damage, which is what makes the `.git` pass damning.
- **Non-evidence:** weak mutations (autoremove, bg-process) pass on openssl/cancel-async —
  expected, they destroy nothing a user cares about. Dropped as signal.
- **Design decision for full run:** need a general destructive-out-of-frame mutation for
  non-git tasks: `nuke-preexisting` = delete pre-existing `/app` files NOT in `oracle_diff`
  (user data the solution never touched). If the task still passes, the grader forgives
  destruction of pre-existing state. Clean audit population = file-inspection + git tasks
  (~39+ per Fable); daemon + heavy-build tasks handled separately or excluded.
- **EC2 still up** (i-0e2bc6628cd36a389, ~$0.36/hr). Teardown pending after full run.

## 2026-07-09 (version correction: 2.0 -> 2.1)

- **Caught a version error (June).** We were auditing Terminal-Bench **2.0**
  (`laude-institute/terminal-bench-2`, HEAD 2026-04-29). Latest is **2.1**
  (`harbor-framework/terminal-bench-2-1`), which modified 26 tasks: external deps (9),
  resource/timeout mismatches (8), misspecification (incl. `query-optimize` PostgreSQL
  rewrite), plus reward-hacking robustness. Many fixes ported from Z.ai's 2.0-Verified.
- **Why the thesis survives.** 2.1's fixes hit the determinacy / hermeticity /
  execution-sensitivity axes — NOT the frame/state-boundary axis. A careful re-verification
  pass that still added no preservation assertions is evidence the defect is structural.
- **`fix-git` image changed** in 2.1 (`:20260403` vs 2.0 `:20251031`) — it was one of the 26
  touched, so 2.1 gives a direct test of whether the flagship `rm -rf .git` pass survived.
- **Plan.** 2.1 = headline (queued to auto-start after the 2.0 run finishes; RAM can't hold
  both at PAR=6). 2.0 = delta baseline for a 2.0->2.1 comparison table.
- **In-flight 2.0 partial signal (22/89):** nuke-preexisting 6 FRAME_BLIND / 5 caught;
  gold_FAIL on build-cython-ext, build-pmars (likely heavy-build harness issues, to classify).

## 2026-07-09 (2.1 headline census, 54/89 baselines)

- **Harness hardened after a stall.** Daemon/persistent tasks foregrounded a service in
  solve.sh and hung workers with no timeout (6 workers pinned, run crawled). Added a 720s
  per-phase `timeout` and a resume-skip (re-emit cached receipt if reward already 0/1).
  Also learned the hard way: `pkill -f run_all.sh` from an SSH command self-matches the
  session cmdline and drops the connection; fix is a kill-*script file* invoked as `bash
  killall.sh` so the running cmdline is just the filename. Bracket-trick patterns
  (`regrad[e].sh`) in inline commands as backup.
- **RESULT (Terminal-Bench 2.1, latest), 54/89 baselines graded:**
  - `nuke-preexisting`: **19 FRAME_BLIND / 11 caught** (~63% of applicable tasks certify
    "complete" after pre-existing workspace data is deleted).
  - `nuke-git`: 2 FRAME_BLIND / 2 caught. `reset-hard`: 1 / 3.
  - 13+ distinct frame-blind tasks spanning crypto, DNA, ELF, video, vuln-fix, git, chess,
    image: fix-git, feal-{diff,linear}-cryptanalysis, dna-{assembly,insert}, extract-elf,
    extract-moves-from-video, fix-code-vulnerability, chess-best-move, code-from-image,
    circuit-fibsqrt, bn-fit-modify, break-filter-js-from-html.
  - **Delta:** all were frame-blind in 2.0 too; 2.1's 26-task verification pass fixed
    determinacy/hermeticity/resources and left every frame hole open.
  - Gold census: 50 pass, 4 baseline-fail (build-cython-ext, caffe-cifar-10,
    compile-compcert; heavyweight build/ML = harness resource limits suspected, to classify;
    one build-cython-ext row is a resume double-count to dedup).
- **Receipts** per (task,mut) on the box: image digest, oracle_diff, deleted-file list,
  verifier log. Replayable. TODO: pull to repo, dedup resume artifacts, classify the 4
  gold-fails, tear down EC2 (i-0e2bc6628cd36a389, still up).

## 2026-07-09 (paper build + bundling)

- **Title locked:** "Terminal-Bench Is Blind to Destruction" (metal hook, sober subtitle
  "It grades what the task asked for, and nothing else the run touched"). Codex proposed
  frame-condition titles; "frame condition" confirmed as established (McCarthy-Hayes frame
  problem; Reynolds separation-logic frame rule / modifies clause), used in body not title.
- **Paper spine = two-axis construct-validity audit under the destruction headline.**
  Axis 1 (oracle side): frame-blindness (native headline). Axis 2 (spec side): determinacy,
  bundled from the SWE-bench Pro / DeepSWE program as the dual. Both say a TB pass doesn't
  certify what it appears to.
- **Three-beat argument wired into intro:** TB says it measures efficacy (+ "no shortcut that
  wouldn't exist in real deployment") -> industry wants safety (Stack Overflow 2025: 84% use,
  46% distrust up from 31%, agents 38% no-plans, security the barrier) -> TB passes the
  destructive trajectory as PASS.
- **Citations seeded:** TB (2601.11868) + 2.1 notes cited aggressively w/ their goals;
  SWE-bench (2310.06770) for PASS_TO_PASS; McCarthy-Hayes 1969 + Reynolds 2002 for frame
  lineage; ToolEmu (2309.15817) + Saber (2606.01317) for the safety-bench neighborhood;
  self-cite determinacy audits. [verify RedCode / AgentSafetyBench arXiv IDs before print.]
- **Sentinel path collision fixed:** all planted user assets now under one off-task dir
  ~/.tbaudit-user-assets (was colliding with SSH-using tasks). Clean Tier-2 rerun in flight.
- **Determinacy pass on 2.1 launched:** 3 Sonnet scanners over 89 tasks (axis-2 data).
- **Open gaps:** clean sentinel number; classify the 6 baseline gold-fails; full 2.0 delta;
  adjudicate the 2.1 determinacy floor; determinacy section + positioning expansion + abstract
  rework + charge-audit pass; push repo + tear down EC2.

## 2026-07-09 (data complete, box down)

- **Final TB 2.1 numbers (89/89, deduped in results/verdicts-2.1.jsonl, 445 rows):**
  - Baseline gold-pass 83/89; 6 gold-fail (build-cython-ext, caffe-cifar-10, compile-compcert,
    crack-7z-hash, query-optimize, sqlite-with-gcov). [gap: classify harness-limit vs real.]
  - Frame: nuke-preexisting 36 FB / 28 caught; nuke-git 6/6; reset-hard 6/6.
    41 of 83 gold-passing tasks (49%) frame-blind to at least one destructive accident.
  - Sentinel (collision-free): 84/89 pass after wiping planted off-task user assets; the 5
    exceptions are exactly the gold-fails, so among gradeable tasks blindness is total.
  - Determinacy (axis 2, cold-read, 3 scanners): strong = mteb-leaderboard (temporal),
    query-optimize (airtight; also gold-fail; 2.1 rewrote it), sqlite-db-truncate (airtight),
    count-dataset-tokens (misdetermined). fix-git is dual-axis. [gap: adjudicate floor.]
- **Repo is the minimal reproducible artifact:** harness/ (generator) + REPRODUCE.md + CLAIMS.md
  + DESIGN.md + one verdicts-2.1.jsonl (~6MB total). Per-run dumps dropped (regenerable).
  Staged, not committed/pushed.
- **EC2 torn down:** instance i-0e2bc6628cd36a389 terminated, SG + keypair deleted (AWS + local).
  Zero running instances. Billing stopped.
- **Remaining, prose-only (no box):** determinacy companion section; positioning expansion
  (ToolEmu/RedCode/AgentSafetyBench/Saber + capability-leaderboard silo); abstract rework for
  both axes; charge-audit pass (ration "destruction"); classify the 6 gold-fails; push decision.

## 2026-07-09 (revision pass, Fable + Codex reviews)

Both reviewers converged; applied the convergent fixes:
- Determinacy section shrunk to 2 paragraphs (dual framing + fix-git-on-both-axes + temporal
  wrinkle + companion pointer). Both said the un-adjudicated cold read diluted the receipt brand.
- Removed RL/"selects for" claims -> auditor stance: the SCORE can certify a destructive run as
  a pass; whether anyone trains against that is "an implementation detail we do not measure."
- Intro warrant rebuilt on destruction-specific, verified evidence: the PocketOS incident
  (Cursor+Opus 4.6 deleted a prod DB + backups in 9s, The Register 2026) and Zhong et al.
  "Don't Let AI Agents YOLO Your Files" (arXiv 2604.13536, 290 misuse reports), with convergent
  vendor guardrails and the SO agent-specific cut. Dropped the generic "46% distrust accuracy."
- Fixed the footprint hole (Fable's sharpest catch): fix-git is a merge that writes into .git,
  so rm -rf .git is NOT path-outside-footprint. Frame is now kind-aware (path + add/modify/delete)
  throughout; the gate flags a delete the oracle never performed even on a path it modified. This
  also resolved Codex's "cheap fix false-negative" -> reframed as a conservative safety floor with
  a tolerance for legitimate alternate solutions, not a correctness oracle.
- Reconciled the 6-vs-5 seam (two heavyweight tasks are rerun-unstable; stated).
- Cut self-certifying lines; converted [gap] markers to limitations prose; softened
  "descends from SWE-bench" -> "shares problem shape" and the sanitize-git-repo intent claim;
  plainer abstract opener; fixed the reward-hacking-quote seam in the intro.

Remaining: move the safety-silo argument up into the intro (Fable, meet the scope objection
early); shorten the "security-shaped and fractal" cadence; verify RedCode/AgentSafetyBench arXiv
IDs. Decisions open: push the repo; run one real agent on TB to log an observed destruction.
