# Planning, collaboration, and recovery

## Keep only useful execution state

For dependent or multi-session work, use an existing project plan or a concise [work record](../assets/work-record-template.md). Include the current authorized goal, its acceptance reference, completed and remaining work, relevant dependencies, verification locators, and next action. Add repository/worktree identity and existing user changes when needed for safe recovery. Routine local work needs no persistent plan.

Order work by dependencies, user priorities, risk reduction, and useful feedback. Maintain the plan as implementation knowledge changes. A different technical step within the same authorized outcome does not create a new approval gate. Record a material product or scope decision with the acceptance record, not solely in the execution plan.

Several disjoint tasks may have their own records. For overlapping work, establish who owns each change before editing; do not silently choose a plan by modification time or create a competing active record. When two agents may write the same new record concurrently, coordinate ownership through the repository or tracker before creating it. Historical plans provide context, not current authorization.

## Delegate and integrate

Delegate bounded work with clear outcomes and ownership when it saves time or improves confidence. Isolate writes or coordinate shared files, generated output, and commands. The integrating agent checks the actual results and verifies the combined change; a delegate's completion message alone is not acceptance evidence. Keep independent work moving while another task awaits input.

Follow project Git conventions. Preserve pre-existing working and staged changes; stage or revert only changes whose ownership is established. Before an agent-created commit, inspect the staged diff and configured hooks when hooks can alter files or run external actions; stop and report unexpected contents or side effects. A useful local checkpoint may aid recovery, but acceptance does not depend on a commit. A requested WIP snapshot remains unverified. Remote integration and publication follow the user's actual authorization and the host's permissions.

## Resume after interruption

Compare the latest user instruction, relevant record, actual repository/worktree, current diff, and available evidence. Determine what was implemented, what verification still applies, and what remains. If the context no longer matches, establish the intended current target before writing into it. Ask only when the mismatch cannot be resolved from available facts.

If the acceptance location is unresolved, preserve that fact and the locations already checked in the handoff; do not invent a path to complete the record.

Resume authorized ready work without redoing valid completed checks or asking again for the same approval. Retain useful failed hypotheses and observations; conversation loss neither validates unfinished work nor resets a cancellation. Keep unresolved attempts as concise diagnostic context rather than counters or mode-transfer protocols.

## Stop, cancel, or roll back

On cancellation, stop starting work and coordinate termination of outstanding delegates or background writers before reconciling the final state. Preserve the user's working changes and record retained implementation, unresolved verification, and the cancellation. Cancelled or rejected work requires a clear restart instruction; a new session is not one.

For rollback, distinguish undoing implementation from abandoning the requirement. Use the user's stated intent; ask when it is ambiguous. Identify the changes to restore, preserve unrelated edits, and check the restored behavior. Invalidate evidence tied to the undone implementation. Keep the requirement unfinished if it is still wanted; record explicit deferral or removal when that is the user's decision. A partial rollback remains incomplete. Avoid restoring a historic passing status without applicable evidence.

## Close the current work

Complete a work record when its authorized outcomes are verified or its remaining outcomes are explicitly handed off, cancelled, deferred, or removed. State which of these occurred; a closed execution record does not imply accepted outcomes. Record the actual next dependency for pending work. Unrelated backlog stays outside this decision, and project lifecycle changes require their own intended milestone or user request.

Update project documentation when this work changes durable facts. Add or correct a reusable lesson only when evidence supports a non-obvious cause, trade-off, or repair; include its applicability and source. Use the existing project knowledge location. No compulsory lesson, separate memory file, or global-cache refresh is part of completion.
