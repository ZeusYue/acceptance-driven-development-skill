# ADD AC Contract and Plan Boundary

> `SKILL.md` contains the executable gate. This reference defines the schema, migration, and plan details behind it.

## AC authority

`AC.md` owns accepted scope, AC IDs, acceptance status, verification evidence, acceptance confirmation, deferral, and deprecation. A design document or conversation may retain the approved implementation approach; a project document records durable facts; an implementation plan decomposes work. None of them **ever replaces AC.md** as the acceptance or status tracker; a plan never replaces AC.md.

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

Keep each five-column row scannable. Put only the criterion, reusable verification action, status, expected result, and a concise evidence citation in the table. Move full logs, lengthy benchmark samples, screenshot descriptions, and step-by-step user feedback to the template's **🧪 Verification Evidence Details** section in the same `AC.md`. Append `Evidence: EVD-YYYYMMDD-N` (or its localized equivalent) to the How to Verify cell after the reusable command/steps; never replace that verification contract with evidence. This preserves `AC.md` authority without turning the status table into a log archive.

One EVD event represents one verification batch and may reference multiple ACs. Always include verification time, related ACs, type, scope, command/steps, expected and actual results, exit status, attachment, conclusion, and status update. Use `N/A` rather than dropping fields. Keep the result concise and put long raw output in `<details>`.

The **🧭 Scope Decision Log** records only user-approved acceptance-contract additions, edits, deferrals, and deprecations. Write at most one row per approved scope batch with date, stable decision ID, AC scope, approved decision, and rationale. Implementation notes, tests, evidence, ordinary status transitions, plan changes, and commits do not belong there.

The optional `assets/ac-document-tables.css` gives Obsidian AC tables stable column proportions and normal wrapping when the document has `cssclasses: ac-document`. Copy and enable it only with user consent. Other Markdown hosts ignore the class but retain the evidence structure.

## Existing-document migration

Existing AC documents may use localized headers, older category ranges, a legacy change log, and older valid evidence entries. These legacy forms alone do not fail the gate. Preserve their IDs, requirements, valid verification evidence, verified states, and document language unless a separately approved migration says otherwise. If a missing section or ambiguous row needs semantic interpretation, stop, report the gap, and obtain user confirmation before editing. Do not silently convert an old document merely to make it look like the new template.

## Proposal and persistence boundary

New or changed scope remains a proposed AC delta outside authoritative `AC.md` until the required approval or fast-lane confirmation. Rejection or cancellation leaves `AC.md` unchanged. After approval, persist the accepted row additions/edits and affected markers before mode selection, planning, or code. A new target starts `[ ]`; an edited target previously marked `[x]` becomes `[~]` when its criterion, verification, or expected result changes, because the new contract is not yet implemented and freshly verified. Use `[!] [affected]` for verified behavior whose contract did not change but needs regression verification. Existing-project reconstruction follows the same unsaved-draft → approval → persist sequence.

When a user explicitly resumes an unchanged `[>]` criterion, record the decision and reactivate it as `[ ]` if untouched or `[~]` if partial implementation remains, then enter Phase 3.5A. If the requested scope differs from the deferred contract, keep the authoritative row `[>]` until the Phase 3.5B delta is approved; then atomically apply the edit and reactivate it as `[ ]` or `[~]` before mode selection.

## Plans are derived, never authoritative

Mode A copies the built-in implementation-plan asset after approval and before code; Mode B writes only the six-field Execution Map in chat. An external planning tool may assist, but it does not change this boundary. See `implementation-planning-and-execution.md` for the task schema, execution loop, recovery, and local checkpoint rules. Every persistent plan includes an **Acceptance Mapping** table:

| Plan task | AC IDs | Implementation scope | Verification action |
|---|---|---|---|
| {{task}} | AC-N | {{files / behavior}} | {{command or manual handoff}} |

Plan checkboxes record execution progress only. They do not change AC status, replace AC evidence, or justify a completion claim. Update `AC.md` immediately when implementation, verification, user confirmation, deferral, or deprecation changes its authoritative state.

## Manual Verification Handoff

For every `[!] [manual]` row, present a user-facing table with AC ID, what changed, prerequisites, exact steps, expected result, and a reply form such as `AC-45 passed` or `AC-45 failed: <observation>`. Derive these fields from the approved AC row; do not create a substitute contract only in chat. On failure, record evidence and mark `[~]`; same-scope repair returns through Phase 3.5A, while a material scope/behavior/approach change needs a Phase 3.5B proposal. Do not use a generic “please test” request. AUTO and affected AUTO rows still require their executable commands.
