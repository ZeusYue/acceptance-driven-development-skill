# ADD Failure Recovery and Cancellation

> Load only after a failed cycle, external block, interruption, cancellation/rejection, guided retry, material redesign, or mode switch. `AC.md` remains acceptance authority.

## Attempts and blocks

An attempt is one implementation → verification → review cycle ending in unexpected failure; several failed commands produce one event.
A shared failure increments each affected Mode B target once and each affected Mode A task once; mapped AC count never multiplies it. Expected `TEST-FIRST` red and `CHARACTERIZATION` observations do not count. Mode A counts per `PLAN-N`; Mode B counts per target AC.

Each Mode B target owns one `MB-YYYYMMDD-N` series. Scan current Recovery State cells, allocate the next unused number, and never share IDs between targets.
After each failed cycle before the limit, replace target current evidence with Type `EXECUTION`, Conclusion `FAIL`, the concise failure, and `series: MB-YYYYMMDD-N; approach_ref: <ref>; attempt: N; limit: 3|4; kind: normal|guided; state: failed` in Recovery State.
At the limit, use Conclusion `BLOCKED`, include the reason/unblock condition, and set `state: blocked`. Use Conclusion `RECOVERY STATE` only for non-verification transitions such as authorization, reset, cancellation, rejection, or resumption. Recovery state is never acceptance success.

After three consecutive failed cycles, Mode A removes the task from `active_tasks` and marks it `blocked`; Mode B marks the target `[!] [blocked]` and replaces its current evidence with Conclusion `BLOCKED`, the reason/unblock condition, and `state: blocked`.
Mark only dependent unsettled ACs and offer guidance, Phase 3.5B change, deferral, or deprecation. An AC with another ready path stays nonterminal; unrelated work continues. If another task freshly verifies every AC that required the blocked task, mark the old task `superseded` with evidence; otherwise it remains blocked.

An unavailable required environment/tool is an external block, not a failed cycle. Replace current evidence with Type/Conclusion `BLOCKED`, reason, and unblock condition.
Mode A removes the selected task from `active_tasks` and marks it `blocked` without incrementing; Mode B records `state: blocked` without incrementing. Continue independent work.
When the condition clears under the same approach, Mode A returns its task to `pending` with attempt/evidence unchanged. Mode B writes same-series `state: resumed`; Phase 3.5A imports its prior attempt/guided state rather than resetting it and retains Mode B.

## New Agent or session recovery

1. Use the project capsule already read once for this work unit, then scan plan frontmatter for matching `status: active` plans and paused `superseded-by-mode-b:<approach_ref>` owners with target-AC overlap. Reconcile one transition owner before normal active-plan selection; multiple owners stop before code. `user-cancelled` and `user-rejected` plans participate only after explicit restart.
2. Reconcile a `superseded-by-mode-b` owner against current AC evidence and Git.
   First complete its plan-side handoff idempotently: return unrelated `in_progress` tasks to `pending`, mark Mode-B-owned tasks `superseded` with current evidence, clear `active_tasks`, and set `approach_ref` from the pause marker.
   Then write a missing reset, recover an unfinished Mode B series, or perform ownership handback when Mode B is settled. Do not use latest-completed fallback or create a replacement first.
3. With one active plan, read its Agent Handoff, target task state, and Recovery State; then reconcile authoritative AC rows/current evidence, `git status`, recent local commits, diff, identity, and ancestry.
4. With no active or transition owner, read only Agent Handoff from the capsule's `latest_completed_plan`. If the pointer is missing or stale, scan `plans/` as a compatibility fallback. Never treat a completed plan as active.
5. Resume `in_progress` or ready `pending` work without repeating verified tasks, restoring acceptance from plan history, or re-requesting recorded approval.

Mode B has no persistent plan. Recover from the latest Git commit, target AC, current evidence, Recovery State, `approach_ref`, AC-linked design, and repository diff.
An unfinished `state: failed`, `authorized`, `reset`, or `resumed` series returns through Phase 3.5A in Mode B with its attempt state. `state: cancelled` or `state: rejected` never auto-resumes. If the approach cannot be reconstructed confidently, preserve AC scope/tree and return to Phase 3.5B for approach confirmation; never reset attempts because chat context was lost.

## Guidance and redesign

User guidance after a three-failure block authorizes one additional guided attempt. Reactivate the blocked AC as `[ ]` with no retained implementation or `[~]` when implementation remains.
Mode A returns its task to `pending`, preserves attempt 3, and records attempt 4/4. Mode B keeps the same series and replaces current evidence with `attempt: 4; limit: 4; kind: guided; state: authorized`.
If newly discovered risk or impact requires Mode B recovery to enter Mode A under the same approved approach, import the attempt state instead of granting three new tries; a failed guided cycle returns to blocked.

An approved material redesign changes `[!] [blocked]` to `[ ]` with no retained implementation or `[~]` when implementation remains. If selection remains Mode A, keep the sole active plan, update `approach_ref`, reset reusable blocked tasks to `pending` attempt 0, and supersede replaced tasks.
If selection moves Mode A to Mode B, stop new writes and every delegate, then wait for/drain results. The first persisted plan change sets `status: paused` and `pause_reason: superseded-by-mode-b:<approach_ref>` together; before that marker, do not change `approach_ref`, task states, or `active_tasks`.
After the marker, return unrelated `in_progress` tasks to `pending`, supersede Mode-B-owned tasks with current evidence, clear `active_tasks`, and update `approach_ref`; never run both modes concurrently.
Mode B then replaces current evidence with a new series, `attempt: 0; limit: 3; kind: normal; state: reset`. Ownership handback sets the old plan `completed` when all work is settled, otherwise `active` for remaining ready tasks.
The pause reason is durable transition intent; after interruption, apply the New Agent or session recovery order before code.

## Cancellation and rejection

On cancellation, stop new writes, propagate to every delegate, and wait for/drain results before reconciling the final tree.
Mode A clears `active_tasks`, returns interrupted tasks to `pending`, sets `status: paused` and `pause_reason: user-cancelled`, and preserves tree/index/commits. A `user-cancelled` or `user-rejected` plan never auto-resumes; explicit restart requires matching identity, scope, approach, and baseline.

For Mode B, preserve tree/commits and replace target current evidence with Type `EXECUTION`, Conclusion `RECOVERY STATE`, the current/new series, attempt/limit/kind, and `state: cancelled`; it has no plan or `active_tasks`. Explicit restart writes same-series `state: resumed` without resetting attempts.
Rejection after approval follows cancellation reconciliation but does not count as a failed cycle: Mode A uses `pause_reason: user-rejected`; Mode B records `state: rejected`. Either requires explicit restart; Mode B then writes `state: resumed` without resetting attempts. Pre-approval rejection leaves `AC.md` unchanged.
After approved AC persistence but before Agent code, keep new targets `[ ]` and edited/resumed targets at persisted `[~]`/`[ ]`. After code, only target ACs with retained Agent implementation not freshly accepted become `[~]`, even if code appears complete; untouched `[ ]` and `[!] [affected]` remain unchanged.

Report owned paths/commits. Revert/remove only Agent-owned work on explicit instruction. Explicit deferral/deprecation follows normal AC and scope-decision transitions.
