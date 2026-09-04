# ADD Implementation Planning and Execution

> Phase 4 execution rules; `AC.md` remains authoritative.

## Entry contract

Require AC Gate, approval, impact analysis, and mode announcement.

- **Mode A:** before code, identity-match one plan from approved AC/repository evidence.
- **Mode B:** use the canonical six-field chat-only Execution Map in the main skill; do not create a plan file.
- Users review design/AC, not plans; execute without asking for plan approval.

## Mode A plan contract

### Plan identity and re-entry

Plan status: `active`, `paused`, or `completed`. Inspect `plans/` first.
A plan matches only when `status: active`, root/worktree/branch match, `baseline_commit` is a `HEAD` ancestor, `target_acs` covers targets, and `approach_ref` identifies approval.
`scope_decision_ids` may be `[]` for legacy backlog/no DEC; it is not an implementation-approach identifier.
Reconcile/reuse it; never reopen `completed`.
Explicit restart matches paused plans by the same identity, AC, approach, and baseline.
If exactly one matches without conflict, reconcile it, clear `pause_reason`, and set it `active`; otherwise stop before code and never create a replacement.

Before creating a plan, scan paused plan frontmatter for target-AC overlap. A `user-cancelled` or `user-rejected` owner blocks replacement until explicit matched restart or an approved supersession reconciles that plan; never bypass it with a new plan.
A paused `superseded-by-mode-b:<approach_ref>` owner is transition state, not a user pause. Reconcile it through the recovery reference before selecting or creating any plan.

With no match, copy the asset to `YYYY-MM-DD-<topic>-implementation.md` with the next unused suffix.
If multiple plans match or another active plan claims overlapping ACs, stop before code and reconcile one owner; do not select by modification time.
Non-Git uses `N/A` branch/baseline and exact root/worktree identity.

Every executable `PLAN-N` contains:

`Status | AC mapping | Depends on | Files | Interfaces | Steps | Test strategy | Verification | Review | Commit | Evidence`

Task status is `pending`, `in_progress`, `verified`, `blocked`, or evidence-backed `superseded`.
Record identity, baseline, `active_tasks`, targets, mapping, constraints. `approach_ref` uses design/D-N, approved-chat, or `legacy-approved-backlog:<AC IDs>`; DEC is insufficient.
Map every task/target AC. `active_tasks` has multiple IDs only for non-overlapping work.

Every plan starts with **Agent Handoff** containing exactly `Goal`, `Implemented`, `Verification`, `Last safe commit`, `Unresolved`, and `Worktree notes`. Keep it concise and update it at task boundaries, pause, and completion. Record only project lessons that materially constrain this plan under Constraints; do not copy the capsule.

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

## Conditional recovery

On a failed cycle, external block, interrupted session, cancellation/rejection, guided retry, redesign, or mode switch, read and apply `failure-recovery-and-cancellation.md` before changing task or AC recovery state.

## Completion and retention

When no task is `pending`/`in_progress` and `active_tasks` is empty, record final AC outcomes, current evidence, commits/reports, approved deviations, and technical debt. Update Agent Handoff before changing plan status.
A `user-cancelled` or `user-rejected` plan remains paused until explicit matched restart. A `superseded-by-mode-b` plan participates automatically in recovery and follows ownership handback.
Otherwise keep it active while required blocked work maps to an unsettled AC. Set `completed` only when tasks are `verified`/`superseded`, or each remaining block maps to an explicitly deferred/deprecated AC; AC completion still follows Phases 5/6.
Permanently retain completed plans under the project `plans/` directory. Update the project capsule's `latest_completed_plan` after completion; add or merge lessons only when they meet the capsule admission rule.

Update the living project document only with durable architecture, dependency, concurrency, persistence, build, or deployment facts. Do not copy task logs, attempt history, or routine commits into it.
