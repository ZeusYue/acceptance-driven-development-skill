# ADD Implementation Planning and Execution

> Read this reference whenever Phase 4 begins. `AC.md` remains authoritative; this reference controls only how approved work is decomposed, executed, reviewed, recovered, and checkpointed.

## Entry contract

Implementation starts only after the AC Contract Gate passes, the relevant scope is approved and persisted, impact analysis is complete, and Mode A or Mode B has been announced.

- **Mode A:** before code, copy `assets/implementation-plan-template.md` to `$DOC_HUB/<Project>/plans/YYYY-MM-DD-<topic>-implementation.md`. Fill it from the approved ACs and current repository evidence; never recreate it from memory.
- **Mode B:** do not create a plan file. Print one compact **Execution Map** in chat with exactly: `Target AC`, `Files`, `Implementation steps`, `Verification`, `Review`, and `Commit`.
- An external planning tool may mirror or help edit these artifacts, but ADD owns their required fields and lifecycle.
- The user reviews design and AC scope, not implementation plans. Self-check the artifact, report its path or map, and begin execution without asking for plan approval.

## Mode A plan contract

Create task-level units that an Agent can execute without rediscovering intent. Every `PLAN-N` contains:

`Status | AC mapping | Depends on | Files | Interfaces | Steps | Test strategy | Verification | Review | Commit | Evidence`

Use only `pending`, `in_progress`, `verified`, or `blocked` as task status. Record the repository baseline, current task, target ACs, acceptance mapping, constraints, and plan changes. A task may map to multiple tightly related ACs, and one AC may span tasks, but every task and every target AC must appear in the mapping.

Choose one test strategy per task:

| Strategy | Use when |
|---|---|
| `TEST-FIRST` | A deterministic behavior can be expressed as a failing test before implementation. |
| `CHARACTERIZATION` | Existing or legacy behavior must be captured before a safe change. |
| `TEST-AFTER` | Configuration, integration, documentation, or structure is only meaningfully testable after editing. |
| `MANUAL` | Human visual, physical, or judgment evidence is intrinsic. It never downgrades an executable AUTO AC. |

Before execution, self-check that target ACs are approved, all mappings and required task fields exist, dependencies are acyclic enough to execute, commands have expected results, write scopes do not overlap in parallel tasks, and commit groups are safe. Fix the plan in place, then start the first ready task.

## Execution loop

For each ready task:

1. Mark only that task `in_progress`; re-read its AC mapping, files, interfaces, and baseline.
2. Apply its test strategy. For `TEST-FIRST`, observe a relevant failure before implementation; for `CHARACTERIZATION`, capture current behavior; for `TEST-AFTER`, explain why a prior failing test is not meaningful; for `MANUAL`, complete all possible Agent-side checks.
3. Implement only the mapped scope. Update the living plan when discovered files, dependencies, commands, or non-material steps change.
4. Run the task verification and record concise evidence. Skipped or unavailable checks are not passes.
5. Review the completed AC group. Use an independent reviewer for high-risk work when available; otherwise perform an explicit self-review. Mode A still completes the whole-batch Phase 4.8 review.
6. Mark the task `verified` only after its implementation, Agent-side verification, and review pass. This never changes an AC status.
7. When this task completes a full AC or tightly related AC group, create the safe local Git checkpoint defined below. If the AC spans later tasks, defer its checkpoint until the group is complete. Continue to the next ready task without pausing for user permission.

A material change to accepted scope, externally visible behavior, or the approved solution returns to Phase 3.5B. A plan correction inside approved scope does not require user approval; record the change and continue.

## Delegation and review

Delegate only self-contained tasks with explicit AC mappings, non-overlapping write sets, expected artifacts, and verification commands. Keep tightly coupled tasks with the primary Agent. Parallel tasks must not edit the same file or shared generated output.

Review risk, not task count. Require an independent task review when the change affects security, data loss, concurrency, persistence, public contracts, migrations, or broad shared dependencies and a reviewer is available. Otherwise use focused self-review. Integrate delegated work, run its verification locally, and keep acceptance updates with the primary Agent.

## Safe local Git checkpoints

After Agent-side verification and review, create a local commit for each complete AC or tightly related AC group in both modes. A MANUAL AC may be committed after all available Agent-side checks pass while its AC remains `[!] [manual]`.

1. Capture `git status --short`, the pre-existing staged diff, and any merge/rebase/cherry-pick state before editing; preserve the baseline in the plan or Execution Map.
2. Inspect the final diff and stage only Agent-owned paths or safely separable hunks for the current AC group. Never use broad staging such as `git add -A` when unrelated changes exist, and never alter or include pre-existing index entries.
3. Include the AC IDs in the commit message and record the commit hash in the plan or Execution Map evidence.
4. Never push, create or merge a PR, create a tag, or publish a release unless the user separately requests repository integration.

Do not commit unrelated pre-existing changes. If a target file already contains user changes and the Agent's hunks cannot be isolated with confidence, the index is pre-populated, or a merge/rebase/cherry-pick is active, do not commit that group; report `COMMIT-BLOCKED` with the affected paths/state and reason, preserve the verified working tree and index, and continue independent work. Use the same report when no Git repository or local commit capability exists. Honor an explicit user instruction not to commit and record `COMMIT-SKIPPED: user instruction`. A skipped or blocked commit is not an AC verification failure.

## Failure and recovery

Increment the task attempt count and record failure evidence after each failed implementation or verification attempt. In Mode A the counter belongs to one `PLAN-N`; in Mode B it belongs to the target AC. After three consecutive failures, mark the task `blocked` and its mapped unsettled AC `[!] [blocked]`, cite the failure EVD, and state the concrete unblock choices: approved user guidance, a Phase 3.5B approach change, or explicit deferral/deprecation. Stop tasks mapped to that blocked AC, but continue independent ready tasks unless the block affects a shared prerequisite or the entire batch.

At a new session or after interruption:

1. Re-read authoritative `AC.md`, then the active plan, `git status`, recent local commits, and the current diff.
2. Reconcile reality: `verified` requires recorded evidence and matching repository state; `in_progress` resumes from its evidence; `pending` remains queued; cleared blocks return to `pending` or `in_progress` with an explanation.
3. Do not repeat a verified task, restore acceptance status from plan history, or ask for approval already recorded in `AC.md`.
4. Resume the first ready task and follow the Mode A Continuation Rule.

Mode B has no persistent plan. Recover its approved approach from preserved conversation context, an AC-linked design decision, and the repository diff. If the approach cannot be reconstructed confidently, do not guess that a repair remains approved; return to Phase 3.5B for approach confirmation while preserving the AC scope and working tree.

User guidance after a three-failure block authorizes exactly one additional guided attempt; retain the prior attempt history and label the new attempt accordingly. If it fails, return to blocked. An approved material approach redesign starts a new task or Execution Map attempt series at zero and retains the old failure evidence.

If the user cancels active implementation, stop immediately and preserve the working tree, index, and existing local commits by default. Record the current task evidence; if Agent-owned partial implementation remains, mark its AC `[~]` and report the owned paths/commits. Revert or remove only Agent-owned work and only on explicit instruction. An explicit deferral or deprecation then follows the normal AC transition and scope-decision record.

## Completion and retention

When no task remains `pending` or `in_progress`, record final AC outcomes, evidence IDs, local commit hashes or `COMMIT-BLOCKED`, approved deviations, and technical debt. Keep the plan active while any `blocked` task maps to an unsettled AC. Set frontmatter to `completed` only when every task is `verified`, or when each remaining blocked task maps to an AC the user explicitly deferred or deprecated; AC completion still follows Phases 5 and 6. Permanently retain completed plans under the project `plans/` directory.

Update the living project document only with durable architecture, dependency, concurrency, persistence, build, or deployment facts. Do not copy task logs, attempt history, or routine commits into it.
