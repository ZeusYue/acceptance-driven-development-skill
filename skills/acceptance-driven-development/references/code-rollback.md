# ADD Code Rollback

> Load when the user asks to revert code or undo an implemented ADD scope.

## Choose the rollback outcome

Identify whether the user is abandoning the approved scope or retaining the requirement while reverting implementation. A clear request authorizes that outcome; ask once when the intent is ambiguous. Capture the pre-rollback repository state and affected AC/plan identities before changing files.

An actual source restoration enters Phase 3.5B impact analysis. Persist the selected rollback outcome and concrete affected-AC set before code; a delivery-only Git operation remains outside the code-change path.

### Abandon scope

- To abandon a new AC before implementation, mark the new AC `[-]`, add one scope decision, and retain its stable ID.
- For an implemented new AC, restore code through the rollback plan, verify the restoration, then mark `[-]` and record the scope decision; keep it `[~]` while restoration remains.
- For a modified prior AC, restore its previous approved contract and re-verify it against the restored implementation. Replace current evidence rather than preserving the reverted result.
- Retire an unexecuted plan: mark its executable tasks `superseded` with the scope-decision locator, clear `active_tasks`, and set `status: completed` with `pause_reason: superseded-by-rollback:<decision-id>`. It does not update the project capsule or `latest_completed_plan`.

### Retain scope

When the user chooses to retain the requirement and reimplement now, return the target to `[ ]` when no implementation remains or `[~]` when partial implementation remains; the rollback plan continues through replacement implementation and normal acceptance.
When the user chooses to defer reimplementation, verify restoration, mark `[>]` with the scope decision, and complete the rollback plan so `latest_completed_plan` can advance.

## Executed rollback plan

An executed rollback uses a new Mode A plan, even when the file change is small, and maps every restored or retired AC. A Mode A source sets `supersedes_plan` to the reverted plan ID. Mode B has no persistent plan: use `supersedes_plan: N/A` and identify its source through the target AC, Recovery State, and checkpoint commit.

For a Mode A source:

1. Create the rollback plan as `paused`, with no active task, `pause_reason: awaiting-approved-supersession:<reverted-plan-id>`, and `supersedes_plan: <reverted-plan-id>`.
2. Persist the approved AC transitions and scope decision. A modified prior AC now contains its previous approved contract and current pending evidence.
3. Mark unfinished old tasks `superseded` with the rollback-plan locator, clear old `active_tasks`, and retain the old plan as `completed` with `pause_reason: superseded-by-approved-plan:<rollback-plan-id>`.
4. Activate only the prepared rollback plan, execute the code restoration, review it, and re-verify target and concretely affected ACs.

This order reuses standard approved-supersession recovery: the old plan owns work before step 3; the named rollback plan owns it afterward. A Mode B source activates its new rollback plan directly after AC persistence because no old plan owner exists.

## Completion and handoff

After the rollback plan is `completed` and its ACs are settled, set `latest_completed_plan` in the project capsule to the rollback plan path. Remove or merge project lessons invalidated by the reverted implementation; admit a new lesson only when the rollback exposed a difficult, reusable, verified cause or repair.

Keep AC and plan files for auditability. Current statuses, scope decisions, `supersedes_plan`, and the corrected capsule pointer identify what remains effective.
