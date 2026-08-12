# ADD AC Contract and Plan Boundary

> `SKILL.md` contains the executable gate. This reference defines the schema, migration, and plan details behind it.

## AC authority

`AC.md` owns scope, IDs, acceptance status/evidence/confirmation, deferral, and deprecation. Design retains approved approach, project documents retain durable facts, and plans decompose work. A plan never replaces AC.md.

## Schema-2 contract

A valid AC document contains:

1. a Project Goal;
2. criteria organized into meaningful sections (Features, Performance, Compatibility, Quality, or localized equivalents);
3. five semantic columns: ID, Criterion/标准, Status/状态, How to Verify/验证方式, Expected Result/预期结果;
4. valid primary markers `[ ]`, `[~]`, `[x]`, `[!]`, `[>]`, or `[-]`, with `[manual]`, `[affected]`, or `[blocked]` annotations when applicable;
5. a status summary, deferred/backlog area, and Verification Evidence Details; new documents also require `🧭 Scope Decision Log` (or a localized equivalent), while an existing document may retain its legacy change log until migration is separately approved.

MANUAL rows also require concrete prerequisites/actions and an observable expected result. A vague check is not a valid verification contract.

Use the hub template when it exists. If it does not, copy the language-matching asset from `../assets/`; never invent a partial table from memory. New top-level IDs use the current maximum numeric ID plus one. Do not renumber existing IDs.

## Table readability and evidence detail

Keep five-column rows scannable: criterion, status, reusable verification, expected result, and concise evidence citation only. Move logs, benchmarks, screenshots, and detailed feedback to **🧪 Verification Evidence Details**. Append `Evidence: EVD-YYYYMMDD-N` after reusable steps; never replace the verification contract.

One EVD may cover multiple ACs. Types are `AUTO`, `MANUAL`, `AUTO + MANUAL`, `EXECUTION`, `REVIEW`, or `BLOCKED`; use `EXECUTION` for failed cycles/recovery. Allocate the next unused `EVD-YYYYMMDD-N`, include every field with `N/A` as needed, put long output in `<details>`, and keep only the latest current-result citation in each row.

The **🧭 Scope Decision Log** records only user-approved acceptance-contract additions, edits, deferrals, and deprecations. Allocate `DEC-YYYYMMDD-N` with the next unused numeric `N` for that date; never overwrite or reuse one. Write at most one row per approved scope batch with date, stable decision ID, AC scope, approved decision, and rationale. Implementation notes, tests, evidence, ordinary status transitions, plan changes, and commits do not belong there. A deferred row preserves the reusable AUTO command or concrete MANUAL steps and expected result needed when resumed; put its deferral reason and revisit trigger in the scope-decision row, not in place of verification.

The optional `assets/ac-document-tables.css` gives Obsidian AC tables stable column proportions and normal wrapping when the document has `cssclasses: ac-document`. Copy and enable it only with user consent. Other Markdown hosts ignore the class but retain the evidence structure.

## Existing-document migration

Localized headers, older categories, legacy change logs, and valid old evidence do not alone fail the gate. Preserve IDs, requirements, evidence, verified states, and language unless migration is approved. Stop for user confirmation when semantic interpretation is needed; never silently restyle an old document.

## Proposal and persistence boundary

New or changed scope remains a proposed AC delta outside authoritative `AC.md` until approval or fast-lane confirmation. Rejection/cancellation before approval leaves `AC.md` unchanged. After approval, persist accepted additions/edits and affected markers before mode selection, planning, or code. Cancellation after persistence but before code keeps that approved contract: new targets remain `[ ]`, and edited/resumed targets retain their persisted `[~]` or `[ ]` state.

A new target starts `[ ]`; an edited target previously `[x]` becomes `[~]` when its criterion, verification, or expected result changes. An approved redesign of `[!] [blocked]` starts a new series and becomes `[ ]` when no implementation is retained or `[~]` when implementation remains; preserve the old failure EVD. Use `[!] [affected]` for verified behavior whose contract did not change but needs regression verification. Existing-project reconstruction follows the same unsaved-draft → approval → persist sequence.

When a user explicitly resumes an unchanged `[>]` criterion, record the decision and reactivate it as `[ ]` if untouched or `[~]` if partial implementation remains, then enter Phase 3.5A. If the requested scope differs from the deferred contract, keep the authoritative row `[>]` until the Phase 3.5B delta is approved; then atomically apply the edit and reactivate it as `[ ]` or `[~]` before mode selection.

## Plans are derived, never authoritative

Mode A copies the built-in implementation-plan asset after approval and before code; Mode B writes only the six-field Execution Map in chat. An external planning tool may assist, but it does not change this boundary. See `implementation-planning-and-execution.md` for the task schema, execution loop, recovery, and local checkpoint rules. Every persistent plan includes an **Acceptance Mapping** table:

| Plan task | AC IDs | Implementation scope | Verification action |
|---|---|---|---|
| {{task}} | AC-N | {{files / behavior}} | {{command or manual handoff}} |

Plan checkboxes record execution progress only. They do not change AC status, replace AC evidence, or justify a completion claim. Update `AC.md` immediately when implementation, verification, user confirmation, deferral, or deprecation changes its authoritative state.

## Manual Verification Handoff

For every `[!] [manual]` row, present a user-facing table with AC ID, what changed, prerequisites, exact steps, expected result, and a reply form such as `AC-45 passed` or `AC-45 failed: <observation>`. Derive these fields from the approved AC row; do not create a substitute contract only in chat. On pass, persist the user result in the next unused EVD, append its citation without replacing the reusable steps, and only then mark `[x]`. On failure, record evidence and mark `[~]`; same-scope repair returns through Phase 3.5A, while a material scope/behavior/approach change needs a Phase 3.5B proposal. Do not use a generic “please test” request. AUTO and affected AUTO rows still require their executable commands.
