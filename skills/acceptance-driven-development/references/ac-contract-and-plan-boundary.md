# ADD AC Contract and Plan Boundary

> `SKILL.md` contains the executable gate. This reference defines the schema, migration, and plan details behind it.

## AC authority

`AC.md` owns accepted scope, AC IDs, status, verification evidence, user confirmation, deferral, and deprecation. A design document explains intent; a project document records evidence; an implementation plan decomposes work. A design document or implementation plan **never replaces AC.md** as the acceptance or status tracker.

## Schema-2 contract

A valid AC document contains:

1. a Project Goal;
2. criteria organized into meaningful sections (Features, Performance, Compatibility, Quality, or localized equivalents);
3. five semantic columns: ID, Criterion/标准, Status/状态, How to Verify/验证方式, Expected Result/预期结果;
4. valid primary markers `[ ]`, `[~]`, `[x]`, `[!]`, `[>]`, or `[-]`, with `[manual]`, `[affected]`, or `[blocked]` annotations when applicable;
5. a status summary, deferred/backlog area, and change log.

Use the hub template when it exists. If it does not, copy the language-matching asset from `../assets/`; never invent a partial table from memory. New top-level IDs use the current maximum numeric ID plus one. Do not renumber existing IDs.

## Existing-document migration

Existing AC documents may use localized headers and older category ranges. Preserve their IDs, requirements, verification evidence, status history, and document language. If a missing section or ambiguous row needs semantic interpretation, stop, report the gap, and obtain user confirmation before editing. Do not silently convert an old document merely to make it look like the new template.

## Plans are derived, never authoritative

`writing-plans` may decompose a valid, approved AC into files and work steps. Every plan includes an **Acceptance Mapping** table:

| Plan task | AC IDs | Implementation scope | Verification action |
|---|---|---|---|
| {{task}} | AC-N | {{files / behavior}} | {{command or manual handoff}} |

Plan checkboxes record execution progress only. They do not change AC status, replace AC evidence, or justify a completion claim. Update `AC.md` immediately when implementation, verification, user confirmation, deferral, or deprecation changes its authoritative state.

## Manual Verification Handoff

For every `[!] [manual]` row, present a user-facing table with AC ID, what changed, prerequisites, exact steps, expected result, and a reply form such as `AC-45 passed` or `AC-45 failed: <observation>`. Do not use a generic “please test” request. AUTO and affected AUTO rows still require their executable commands.