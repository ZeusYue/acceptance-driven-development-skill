# ADD Implementation Planning and Execution

> Phase 4 execution rules; `AC.md` remains authoritative.

## Entry contract

Require AC Gate, approval, impact analysis, and mode announcement.

- **Mode A:** before code, identity-match one plan from approved AC/repository evidence.
- **Mode B:** do not create a plan file. Print one compact **Execution Map** in chat with exactly six top-level fields:
  `Target AC` | `Files` | `Implementation steps` | `Verification` | `Review` | `Commit`
  `Target AC`: ID/status/approach/attempt/guided state. `Files`: owned paths, worktree/branch/baseline/dirty index.
  `Implementation steps`: ordered scope. `Verification`: class/action/result/EVD. `Review`: checks/result.
  `Commit`: paths/message plus pending, hash, `COMMIT-BLOCKED`, `COMMIT-SKIPPED`, or `COMMIT-REVIEW-REQUIRED`.
- Users review design/AC, not plans; execute without asking for plan approval.

## Mode A plan contract

### Plan identity and re-entry

Plan status: `active`, `paused`, or `completed`. Inspect `plans/` first.
A plan matches only when `status: active`, root/worktree/branch match, `baseline_commit` is a `HEAD` ancestor, `target_acs` covers targets, and `approach_ref` identifies approval.
`scope_decision_ids` may be `[]` for legacy backlog/no DEC; it is not an implementation-approach identifier.
Reconcile/reuse it; never reopen `completed`.
Explicit restart matches paused plans by the same identity, AC, approach, and baseline.
If exactly one matches without conflict, reconcile it, clear `pause_reason`, and set it `active`; otherwise stop before code and never create a replacement.

With no match, copy the asset to `YYYY-MM-DD-<topic>-implementation.md` with the next unused suffix.
If multiple plans match or another active plan claims overlapping ACs, stop before code and reconcile one owner; do not select by modification time.
Non-Git uses `N/A` branch/baseline and exact root/worktree identity.

Every executable `PLAN-N` contains:

`Status | AC mapping | Depends on | Files | Interfaces | Steps | Test strategy | Verification | Review | Commit | Evidence`

Task status is `pending`, `in_progress`, `verified`, `blocked`, or evidence-backed `superseded`.
Record identity, baseline, `active_tasks`, targets, mapping, constraints. `approach_ref` uses design/D-N, approved-chat, or `legacy-approved-backlog:<AC IDs>`; DEC is insufficient.
Map every task/target AC. `active_tasks` has multiple IDs only for non-overlapping work.

Choose one test strategy per task:

| Strategy | Use when |
|---|---|
| `TEST-FIRST` | Deterministic behavior has a meaningful pre-implementation failing test. |
| `CHARACTERIZATION` | Capture existing behavior before a safe change. |
| `TEST-AFTER` | A meaningful test requires the edit first. |
| `MANUAL` | Human judgment is intrinsic; never downgrade executable AUTO. |

Self-check identity, approval, mappings, dependencies, parallel writes, and commit groups; fix, then start ready work.

## Execution loop

For each ready task or explicit parallel set:

1. Put selected `in_progress` tasks in `active_tasks`; normally one. Re-read mapping/files/interfaces/baseline; never overlap writes/state.
2. Apply `TEST-FIRST`, `CHARACTERIZATION`, or justified `TEST-AFTER`; `MANUAL` completes Agent checks.
3. Implement mapped scope; update discovered files, dependencies, commands, or minor steps.
4. Run verification and record evidence. Skipped/unavailable checks are not passes.
5. Independently review high-risk work when available, otherwise self-review. Complete Phase 4.8; blocks do not stop independent targets.
6. After implementation, Agent verification, and review pass, mark `verified` and remove from `active_tasks`; AC status is unchanged.
7. Checkpoint a complete AC/related group; defer when later tasks remain. Continue without user permission.

Material scope/behavior/solution change returns to Phase 3.5B; record in-scope corrections and continue.

## Delegation and review

Delegate self-contained mapped tasks with non-overlapping writes, artifacts, and commands; keep coupled tasks primary.
Record each delegate in `active_tasks`; parallel tasks cannot share files, generated output, commit groups, or mutable state.

Review risk, not task count. Require independent task review when available for security, data loss, concurrency, persistence, public contracts, migrations, or broad shared dependencies; otherwise use focused self-review.
Integrate and verify delegated work locally; acceptance updates stay primary.

## Safe local Git checkpoints

After Agent verification/review, commit each complete AC group. MANUAL may commit after Agent checks while remaining `[!] [manual]`.

1. Before editing, check `git status --short`, staged diff, and operations; record the plan/map baseline. A failed Git command is not clean.
2. Before staging, re-run status/index/operation checks and resolve active commit-related hooks, including configured `core.hooksPath`.
   Inspect executable `pre-commit`, `prepare-commit-msg`, `commit-msg`, and `post-commit`. Unreadable, unknown, remote/external, or unrelated-path side effects mean `COMMIT-BLOCKED` unless separately authorized.
3. Inspect final diff; stage only Agent-owned paths or safely separable hunks. Never use broad staging such as `git add -A` with unrelated changes or alter pre-existing index entries.
4. Before commit, re-check status, staged diff, preserved index, operations, and hooks; require an exact AC-group match.
5. Include AC IDs, record the hash, then inspect commit contents and new status/index.
   On unexpected hook changes or contents, stop further commits, preserve evidence, and report `COMMIT-REVIEW-REQUIRED`; never rewrite history automatically.
6. Never push, create or merge a PR, create a tag, or publish a release unless the user separately requests repository integration.

If user changes cannot be isolated, the index is pre-populated, or merge/rebase/cherry-pick is active, report `COMMIT-BLOCKED` with paths/state/reason; preserve tree/index and continue independent work.
Use it also without local Git/commit capability. Honor no-commit with `COMMIT-SKIPPED: user instruction`; neither outcome fails AC verification.

## Failure and recovery

An attempt is one implementation → verification → review cycle ending in unexpected failure; several failed commands produce one event. A shared failure increments each affected Mode B target once and each affected Mode A task once; mapped AC count must never multiply it.
Expected `TEST-FIRST` red and `CHARACTERIZATION` observations do not count. Mode A counts per `PLAN-N`; Mode B counts per target AC in `Target AC`.

Each Mode B target AC owns one series. Scan every `MB-YYYYMMDD-N` in `AC.md`; allocate the next unused numeric `N`, never share/reuse it. One shared failure EVD lists each target series.
After every failed Mode B cycle, persist an `EXECUTION` EVD with Conclusion `RECOVERY STATE` and keep its latest row citation. Status update: `Mode B series: MB-YYYYMMDD-N; approach_ref: ...; attempt: N; limit: 3|4; kind: normal|guided; state: failed|blocked|authorized|reset|cancelled|rejected|resumed`. Recovery state is not acceptance success.

After three consecutive failed cycles, Mode A removes the task from `active_tasks` and marks it `blocked`; Mode B marks the target AC `[!] [blocked]`. Mark only dependent unsettled ACs, cite the EVD, and offer guidance, Phase 3.5B change, deferral, or deprecation.
An AC with another ready path stays nonterminal; unrelated work continues. If another task freshly verifies every AC that required the blocked task, mark that old task `superseded` with evidence; otherwise it remains blocked. Stop only for a shared prerequisite or no ready target.

An unavailable required environment/tool is an external block, not a failed cycle. Persist a `BLOCKED` EVD with reason/unblock condition.
Mode A immediately removes the selected task from `active_tasks`, marks it `blocked` without incrementing, and marks only dependent unsettled ACs `[!] [blocked]`. Mode B persists `state: blocked` without incrementing. Continue independent work; keep the plan `active` while the block maps to an unsettled AC.
When that condition clears under the same approach, Mode A returns its task to `pending` with attempt/evidence unchanged. Mode B records same-series `state: resumed`; Phase 3.5A imports its prior attempt/guided state into the selected Mode A task rather than resetting it.

At a new session or after interruption:

1. Re-read authoritative `AC.md`, active plan, `git status`, recent local commits, and diff; validate identity, ancestry, and uniqueness.
2. Reconcile reality: `verified` needs evidence/tree; `active_tasks` are `in_progress`; resume interrupted work from evidence; keep `pending` queued; explain cleared blocks.
3. Never repeat verified work, restore acceptance from plan history, or re-request recorded approval. Resume the first ready task under Mode A Continuation.

Mode B has no persistent plan. Recover series/attempt/guided/cancellation state from the latest Mode B recovery EVD, then approach from conversation, `approach_ref`, AC-linked design, and repository diff. Latest `state: cancelled` or `state: rejected` never auto-resumes.
If the approach cannot be reconstructed confidently, preserve AC scope/tree and return to Phase 3.5B for approach confirmation; never reset attempts because chat context was lost.

User guidance after a three-failure block authorizes one additional guided attempt. Reactivate the blocked AC as `[ ]` with no retained implementation or `[~]` when implementation remains.
Mode A returns its task to `pending`, preserves attempt 3, and records attempt 4/4. Mode B retains prior history and writes a same series `EXECUTION`/`RECOVERY STATE` EVD: `attempt: 4; limit: 4; kind: guided; state: authorized`.
If Mode B re-enters Phase 3.5A/Mode A, import that state into the selected plan instead of granting three new tries. A failed guided cycle returns to blocked.
An approved material redesign changes `[!] [blocked]` to `[ ]` with no retained implementation or `[~]` when implementation remains.
If Mode A remains selected, keep its sole active plan and old failure evidence; update `approach_ref`, reset reusable blocked tasks to `pending` attempt 0, supersede replaced tasks, and add mapped pending tasks.
If selection moves Mode A to Mode B, stop new writes and every delegate, then wait for/drain results. Return unrelated interrupted `in_progress` tasks to `pending`; mark Mode-B-owned/replaced tasks `superseded` with EVD evidence. Clear `active_tasks`, pause with `pause_reason: superseded-by-mode-b:<approach_ref>`, and never run both modes concurrently.
Mode B first persists an `EXECUTION`/`RECOVERY STATE` reset EVD with new series ID/`approach_ref`, `attempt: 0; limit: 3; kind: normal; state: reset`.
At its settled acceptance/deferral/deprecation outcome, ownership handback reconciles EVD/commit evidence. Set the old plan `completed` if all tasks are `verified`/`superseded` or remaining blocks map only to deferred/deprecated ACs; otherwise set it `active`, clear `pause_reason`, and continue ready tasks. This is the sole automatic paused-plan resume.

On cancellation, stop new writes, propagate to every delegate, and wait for/drain results before reconciling the final tree. For Mode A, clear `active_tasks`, return interrupted tasks to `pending` with evidence, set `status: paused` and `pause_reason: user-cancelled`, and preserve tree/index/commits.
A `user-cancelled` or `user-rejected` paused plan never auto-resumes; explicit restart reconciles and reactivates it without scope reapproval when scope/approach is unchanged. A `superseded-by-mode-b` plan follows the ownership handback rule above.
For Mode B, preserve tree/commits, persist an `EXECUTION` EVD with Conclusion `RECOVERY STATE`, current/new series, attempt/limit/kind, and `state: cancelled`, then cite it; it has no plan or `active_tasks`. Before writes, explicit restart records the same series as `state: resumed` without resetting attempts.
User rejection before approval leaves `AC.md` unchanged. Rejection of further execution after approval uses cancellation reconciliation but does not count as a failed cycle: Mode A pauses with `pause_reason: user-rejected`; Mode B persists `state: rejected`. Either needs explicit restart confirming unchanged scope/approach; Mode B records `state: resumed` without resetting attempts.
After approved AC persistence but before Agent code, keep new targets `[ ]` and edited/resumed targets at persisted `[~]`/`[ ]`. After code, only target ACs with retained Agent implementation not freshly accepted become `[~]`, even if code appears complete; untouched `[ ]` and `[!] [affected]` remain unchanged.
Report owned paths/commits. Revert/remove only Agent-owned work on explicit instruction. Explicit deferral/deprecation follows normal AC and scope-decision transitions.

## Completion and retention

When no task is `pending`/`in_progress` and `active_tasks` is empty, record final AC outcomes, EVDs, commits/reports, approved deviations, and technical debt.
A `user-cancelled` or `user-rejected` plan remains paused until explicit matched restart; a `superseded-by-mode-b` plan follows ownership handback. Otherwise keep it active while required blocked work maps to an unsettled AC. Set `completed` only when tasks are `verified`/`superseded`, or each remaining block maps to an explicitly deferred/deprecated AC; AC completion still follows Phases 5/6.
Permanently retain completed plans under the project `plans/` directory.

Update the living project document only with durable architecture, dependency, concurrency, persistence, build, or deployment facts. Do not copy task logs, attempt history, or routine commits into it.
