# ADD AC Contract and Plan Boundary

> `SKILL.md` contains the executable gate. This reference defines Schema 3, migration, and the plan boundary behind it.

## AC authority

`AC.md` owns scope, IDs, acceptance status, current evidence, confirmation, deferral, and deprecation. Design retains approved approach, project documents retain durable facts, and plans decompose work. A plan never replaces AC.md.

## Schema 3 contract

A valid current AC document contains:

1. a Project Goal;
2. criteria organized into meaningful sections;
3. five semantic columns: ID, Criterion/标准, Status/状态, How to Verify/验证方式, Expected Result/预期结果;
4. valid primary markers `[ ]`, `[~]`, `[x]`, `[!]`, `[>]`, or `[-]`, with `[manual]`, `[affected]`, or `[blocked]` annotations when applicable;
5. a status summary, deferred/backlog area, **🧪 Current Verification Evidence** table, and **🧭 Scope Decision Log**.

MANUAL rows require concrete prerequisites/actions and an observable expected result. A vague check is not a valid verification contract. Use the hub template when it exists; otherwise copy the language-matching asset from `../assets/`. New top-level IDs use the current maximum numeric ID plus one.

## Current evidence

The six-column current-evidence table is keyed by AC ID:

| AC ID | Last Verified | Type | Current Conclusion | Actual Result / Evidence Location | Recovery State |
|---|---|---|---|---|---|

- Each concrete AC has at most one evidence row. New verification replaces that row; no EVD ID, citation, event block, archive, or reference count is created.
- How to Verify contains only the reusable command or concrete manual steps. Evidence results never replace or extend that contract.
- `[x]` requires current `PASS` evidence. `[!] [manual]`, `[!] [affected]`, and `[!] [blocked]` require matching `PENDING MANUAL`, `AFFECTED`, and `BLOCKED` conclusions.
- `[~]` retains its current failure, incomplete verification, Mode B recovery state, or `EXECUTION / PENDING IMPLEMENTATION / N/A` row for an approved edit that invalidated PASS. Unverified `[ ]` and `[>]` rows may omit evidence.
- Keep Actual Result / Evidence Location to two sentences. Store long command output, screenshots, benchmarks, and reports outside `AC.md`; retain only the concise result and stable locator.
- Mode B writes its target-specific series, `approach_ref`, attempt, limit, kind, and state into Recovery State. A later cycle overwrites the same AC row; success replaces the tuple with `completed`.

Status Summary is derived from all concrete AC rows. Recompute its category totals and status groups after each status batch.

The **🧭 Scope Decision Log** records only user-approved acceptance additions, edits, deferrals, and deprecations. Allocate the next collision-safe `DEC-YYYYMMDD-N`; write at most one row per approved scope batch. Implementation notes, tests, evidence updates, ordinary status transitions, plan changes, and commits do not belong there.

## Existing-document migration

Schema 2 documents with EVD history remain readable until migration is separately approved. Do not append Schema 3 rows into a Schema 2 document or silently delete legacy evidence.
Before the next evidence update, propose an atomic migration that preserves AC IDs, requirements, current status, reusable verification, the latest meaningful result per AC, language, and scope decisions while removing superseded EVD history.
If migration is declined, continue under the existing Schema 2 contract and report that its historical evidence can still grow.

Localized headers, older categories, and legacy change logs do not alone fail the gate. Stop for user confirmation whenever current meaning cannot be selected mechanically.

The optional `assets/ac-document-tables.css` gives Obsidian AC tables stable column proportions and normal wrapping when the document has `cssclasses: ac-document`.

## Proposal and persistence boundary

New or changed scope remains a proposed AC delta outside authoritative `AC.md` until approval or fast-lane confirmation. Rejection/cancellation before approval leaves `AC.md` unchanged. After approval, persist accepted additions/edits and affected markers before mode selection, planning, or code. Cancellation after persistence but before code keeps that approved contract.

A new target starts `[ ]`; an edited `[x]` target becomes `[~]`.
An approved redesign of `[!] [blocked]` starts a new attempt series and becomes `[ ]` with no retained implementation or `[~]` with retained implementation; replace the current blocking evidence with the approved recovery state.
Use `[!] [affected]` for verified behavior whose contract did not change but needs regression verification.

When a user resumes an unchanged `[>]`, record the decision and reactivate it as `[ ]` if untouched or `[~]` if partial implementation remains. Changed deferred scope stays `[>]` until the Phase 3.5B delta is approved.

## Plans are derived, never authoritative

Mode A copies the built-in implementation-plan asset after approval and before code; Mode B writes only the six-field Execution Map in chat. An external planning tool may assist but never changes this boundary. Every persistent plan includes an **Acceptance Mapping** table:

| Plan task | AC IDs | Implementation scope | Verification action |
|---|---|---|---|
| {{task}} | AC-N | {{files / behavior}} | {{command or manual handoff}} |

Plan status records execution progress only. Its final record references the `AC.md` path and target IDs without copying outcomes or evidence. Update `AC.md` whenever verification, user confirmation, deferral, or deprecation changes its authoritative state.

## Manual Verification Handoff

For every `[!] [manual]`, present AC ID, what changed, prerequisites, exact steps, expected result, and a reply form such as `AC-45 passed` or `AC-45 failed: <observation>`.
On pass, replace that AC's current-evidence row with the reported result and only then mark `[x]`.
On failure, replace current evidence, set `[~]`, and use Phase 3.5A for same-scope repair or Phase 3.5B for a material delta. AUTO and affected AUTO rows still require their executable commands.
