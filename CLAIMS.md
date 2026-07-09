# Claims and receipts

Each row is a claim in the write-up, the command that regenerates it, and the receipt that
backs it. Numbers are Terminal-Bench 2.1 unless noted. `$TB2_DIR` is a
`terminal-bench-2-1/tasks` clone. See `REPRODUCE.md` for setup.

## Axis 1 — frame-blindness (oracle side)

| claim | regenerate | receipt |
|---|---|---|
| `fix-git` passes after `rm -rf .git` (flagship) | `bash harness/regrade.sh $TB2_DIR/fix-git nuke-git` | `results/fix-git/nuke-git/` — reward 1, verdict FRAME_BLIND, `image.digest` pinned |
| ...and the grader *can* catch damage | `bash harness/regrade.sh $TB2_DIR/fix-git reset-hard` | `results/fix-git/reset-hard/` — reward 0, verdict caught |
| 41 of 83 gold-passing tasks frame-blind | `PAR=6 bash harness/run_all.sh && bash harness/agg.sh` | `results/*/{nuke-git,nuke-preexisting,reset-hard}/receipt.json` |
| `nuke-preexisting` 36 frame-blind / 28 caught | (above) | verdict field per receipt |
| `nuke-git` 6 / 6; `reset-hard` 6 / 6 | (above) | verdict field per receipt |
| baseline gold-pass 83 / 89 | (above) | `results/*/baseline/reward.txt` |
| 6 gold-fails: `query-optimize`, `crack-7z-hash`, `sqlite-with-gcov`, `build-cython-ext`, `caffe-cifar-10`, `compile-compcert` | (above) | `results/<task>/baseline/` verdict gold_FAIL — [gap: classify harness-limit vs real] |

## Sentinel — unambiguous off-task destruction

| claim | regenerate | receipt |
|---|---|---|
| 84 of 89 tasks pass after wiping planted user assets (`~/.tbaudit-user-assets`: a second repo, an SSH key, a data file): all 83 gold-passing tasks, so among gradeable tasks it is total. The 84th is `sqlite-with-gcov`, a gold-fail that flipped to passing on this rerun (rerun-unstable); the other 5 non-passers are the remaining gold-fails | `MUTS="wipe-sentinel" PAR=6 bash harness/run_all.sh` | `verdicts-2.1.jsonl` rows `"mut":"wipe-sentinel"`, verdict FRAME_BLIND |

## Axis 2 — determinacy (spec side)

Cold-read candidates on 2.1, pending adjudication with the determinacy auditor
(the SWE-bench Pro / DeepSWE tool). Each is a task whose instruction does not pin the value
the hidden test asserts.

Full cold-read over 89 tasks (three Sonnet scanners). Strong first, then lower-confidence.

| task | class | the pinned thing the prose leaves open |
|---|---|---|
| `mteb-leaderboard` | temporal | "best model as of August 2025" but the test pins exactly `GritLM/GritLM-7B`; no leaderboard snapshot ships in the sandbox |
| `query-optimize` | airtight | "as efficient as possible" but graded at `median_s <= 1.05 * golden`, the golden invisible; 2.1 rewrote this task and it stays underdetermined *and* gold-failing |
| `sqlite-db-truncate` | airtight | "recover as many rows as possible" but graded at `score > 6` (>=7 of 8), a bar the prose never states |
| `count-dataset-tokens` | misdetermined | pins `79586`; "science domain" is silently `{chemistry,biology,physics}` and only two fields are summed, neither stated, each changing the integer |
| `fix-git` | misdetermined | dual-axis with the frame finding: "merge into master" leaves the conflict-resolution strategy open, but the test asserts exact MD5s of the merged files (low confidence, repo diff not inspected offline) |
| `bn-fit-modify` | prose-plural | "perform a causal intervention on Y" but the test pins the do-calculus mutilated-graph convention (drop edges into Y, keep out of Y), never spelled out |
| `merge-diff-arc-agi-task` | prose-plural | ARC induction admits multiple rules consistent with the visible examples; graded on one hidden generalization (low confidence, genre-intrinsic) |
| `sparql-university` | prose-plural | EU-membership is an external undated fact absent from the graph (low confidence, common knowledge) |

Note `fix-git` appears on both axes: the grader forgives `rm -rf .git` (frame) and the prose
underdetermines the merged bytes it hashes (determinacy). `query-optimize` appears on both the
gold-fail list and here.

Adjudicate: `github.com/kimjune01/determinacy` over `$TB2_DIR`, two-family construct-and-refute,
report the floor. [gap: run and record.]

---

Every row above is a rerun, not a claim to trust. If a verdict does not reproduce from the
pinned image and the official grader, it is not a finding.
