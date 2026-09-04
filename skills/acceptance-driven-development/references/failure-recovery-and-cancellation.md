# ADD Failure Recovery and Cancellation

> Load after failure, block, interruption, cancellation/rejection, retry, redesign, or mode switch. `AC.md` remains authoritative.

## Attempts and blocks

An attempt is an implementation → verification → review cycle ending unexpectedly; its failed commands are one event.
A shared failure increments each affected Mode B target once and Mode A task once; AC count never multiplies it. Expected `TEST-FIRST` red and `CHARACTERIZATION` do not count. Mode A counts per `PLAN-N`; Mode B counts per target AC.

Each Mode B target with unfinished work owns one `MB-YYYYMMDD-N` series. Scan current Recovery State, allocate the next unused number, and never share series. PASS replaces the tuple with `completed`.
After each failed cycle before the limit, replace current evidence with `EXECUTION`, Conclusion `FAIL`, concise failure, and `series: MB-YYYYMMDD-N; approach_ref: <ref>; attempt: N; limit: 3|4; kind: normal|guided; state: failed`.
At the limit, use Conclusion `BLOCKED`, reason/unblock condition, and `state: blocked`. Use Conclusion `RECOVERY STATE` only for non-verification transitions, never acceptance success.
A Mode B MANUAL handoff creates or retains its series as `MANUAL / PENDING MANUAL / state: pending-manual`; failure uses `MANUAL`, advances normal series, or blocks guided series at 4/4 without increment.

After three consecutive failed cycles, Mode A removes the task from `active_tasks` as `blocked`; Mode B marks the target `[!] [blocked]` and replaces current evidence with `BLOCKED / state: blocked`.
Mark dependent unsettled ACs; continue independent work. If another task freshly verifies every AC that required the blocked task, mark the old task `superseded` with evidence; otherwise it remains blocked.

An unavailable required environment/tool is an external block, not a failed cycle; replace current evidence with Type/Conclusion `BLOCKED` plus reason/unblock condition.
Mode A removes the selected task from `active_tasks` and marks it `blocked` without incrementing; Mode B records `state: blocked` without incrementing. Continue independent work.
When the condition clears, first apply Phase 5's AC transition. Mode A deletes old BLOCKED evidence for `[ ]`, or writes `EXECUTION / PENDING IMPLEMENTATION / N/A` for retained `[~]`; only plan-task attempt/evidence stays unchanged. Return task to `pending`. Mode B replaces the row with same-series `state: resumed`; Phase 3.5A imports prior attempt/guided state and retains Mode B.

## New Agent or session recovery

1. Use the project capsule already read once. Scan plan frontmatter for active/paused `superseded-by-mode-b:<approach_ref>` or `awaiting-approved-supersession:<old-plan-id>` owners overlapping target ACs. Reconcile one; conflicts stop code. User-cancelled/rejected plans require explicit restart or named supersession.
2. Reconcile a `superseded-by-mode-b` owner against current AC evidence and Git.
   First complete its plan-side handoff idempotently: return unrelated `in_progress` tasks to `pending`, mark Mode-B-owned tasks `superseded` with current evidence, clear `active_tasks`, and set `approach_ref` from the pause marker.
   Then write a missing reset, recover an unfinished Mode B series, or perform ownership handback when Mode B is settled. Do not use latest-completed fallback or create a replacement first.
   For `awaiting-approved-supersession`, match `supersedes_plan`, the old paused/completed plan, and repository identity. If old is paused, complete its supersession write; if completed naming this replacement, activate it. Mismatch stops before code; never create a second replacement.
3. With one active plan, read Agent Handoff, target task state, and Recovery State; reconcile AC rows/current evidence, `git status`, recent local commits, diff, identity, and ancestry.
4. With no active or transition owner, read only Agent Handoff from the completed-plan pointer `latest_completed_plan` after checking `code_root`, `worktree_id`, `branch`, and `baseline_commit` against the repository.
   If pointer is missing or stale or mismatched, scan `plans/` as a compatibility fallback with the same check. Mismatched handoffs are historical context. Never treat a completed plan as active.
5. Resume `in_progress` or ready `pending` work without repeating verified tasks or re-requesting approval.

Mode B has no persistent plan. Recover from the latest Git commit, target AC, current evidence, Recovery State, `approach_ref`, and repository diff.
Unfinished `failed`, `authorized`, `reset`, or `resumed` returns through Phase 3.5A with its attempt state; `pending-manual` reissues the handoff. `cancelled`/`rejected` never auto-resumes. If the approach cannot be reconstructed confidently, preserve AC scope/tree and return to Phase 3.5B for approach confirmation; never reset attempts because chat context was lost.

## Guidance and redesign

User guidance after a three-failure block authorizes one additional guided attempt. Reactivate the blocked AC as `[ ]` with no retained implementation or `[~]` when implementation remains.
Mode A returns its task to `pending`, preserves attempt 3, and records attempt 4/4. Mode B keeps the same series and replaces current evidence with `attempt: 4; limit: 4; kind: guided; state: authorized`.
If newly discovered risk or impact requires Mode B recovery to enter Mode A under the same approved approach, import the attempt state instead of granting three new tries; a failed guided cycle returns to blocked.

When Mode B recovery is upgraded to Mode A under the same approved approach, create exactly one recovery task for each unfinished Mode B target series.
Set task Attempt from the AC row and store only that row's locator; re-read `approach_ref`, limit, kind, and series identity from AC.md before each cycle. A new task starts at `attempt: 0`, `limit: 3`, `kind: normal`. Never merge series, reset attempts, or copy the tuple into the plan.

An approved material redesign changes `[!] [blocked]` to `[ ]` with no retained implementation or `[~]` when implementation remains. If selection remains Mode A, keep the sole active plan, update `approach_ref`, reset reusable blocked tasks to `pending` attempt 0, and supersede replaced tasks.
If selection moves Mode A to Mode B, stop new writes and every delegate, then wait for/drain results.
The first persisted plan change sets `status: paused` and `pause_reason: superseded-by-mode-b:<approach_ref>` together; before that marker, do not change `approach_ref`, task states, or `active_tasks`.
After the marker, return unrelated `in_progress` tasks to `pending`, supersede Mode-B-owned tasks with current evidence, clear `active_tasks`, and update `approach_ref`; never run both modes concurrently.
Mode B then replaces current evidence with a new series, `attempt: 0; limit: 3; kind: normal; state: reset`. Ownership handback keeps the pause marker and sets old plan `completed` when work settles; otherwise it clears `pause_reason` and sets `active` for remaining tasks.

### Approved supersession of a paused plan

After a user-cancelled/rejected plan is approved for replacement, reserve a collision-safe path and persist `status: paused`, `pause_reason: awaiting-approved-supersession:<old-plan-id>`, and `supersedes_plan: <old-plan-id>`. Match repository identity and every unsettled target owned by the old plan.
Then mark the old executable tasks `superseded` with the replacement-plan locator, clear `active_tasks`, and persist `status: completed` plus `pause_reason: superseded-by-approved-plan:<new-plan-id>`. Finally activate the prepared replacement and clear its pause reason.
Before the old-plan write, it remains the sole owner. After that write, the named paused replacement is the sole owner and must be activated, not duplicated. A superseded plan is never reopened.

## Cancellation and rejection

On cancellation, stop new writes, notify every delegate, and wait for/drain results before reconciling the final tree.
Mode A clears `active_tasks`, returns interrupted tasks to `pending`, sets `status: paused` and `pause_reason: user-cancelled`, and preserves tree/index/commits. A `user-cancelled` or `user-rejected` plan never auto-resumes; explicit restart requires matching identity, scope, approach, and baseline.

For Mode B, preserve tree/commits. A series already blocked at its failure limit stays blocked; otherwise replace current evidence with `EXECUTION / RECOVERY STATE`, its tuple, and `state: cancelled`; no plan or `active_tasks` exists.
Explicit restart writes same-series `state: resumed` without resetting attempts; normal attempts must remain below 3, while an authorized guided series remains 4/4.
Rejection after approval does not count as a failed cycle: Mode A uses `pause_reason: user-rejected`; Mode B applies the same guard, otherwise records `state: rejected`, and explicit restart writes `state: resumed` without resetting attempts. Pre-approval rejection leaves `AC.md` unchanged.
After approved AC persistence but before Agent code, keep new targets `[ ]` and edited/resumed targets at persisted `[~]`/`[ ]`. After code, only target ACs with retained Agent implementation not freshly accepted become `[~]`; untouched `[ ]` and `[!] [affected]` remain unchanged.
