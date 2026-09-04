---
template: acceptance-criteria
schema: 3
cssclasses: ac-document
---

# {{Project Name}} Acceptance Criteria

> **Contract:** This file is the sole source of truth for accepted scope, AC IDs, verification state, current evidence, acceptance confirmation, deferral, and deprecation. Do not use a design or implementation plan as an acceptance-status tracker.

## 🎯 Project Goal

{{One sentence: what problem this solves and for whom}}

---

## 🧾 Acceptance Criteria

> **Table convention:** The `ac-document` style renders five-column AC tables with stable proportions. Keep criterion, verification, and expected-result cells to two sentences each. How to Verify contains only a reusable command or concrete manual steps; keep results and evidence locations in **🧪 Current Verification Evidence**.

### Features

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{description}} | [ ] | {{command / test / UI action}} | {{what passing looks like}} |

### Performance

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{measurable requirement}} | [ ] | {{benchmark command}} | {{threshold}} |

### Compatibility

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{environment requirement}} | [ ] | {{environment + command}} | {{supported behavior}} |

### Quality

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{testability / reliability requirement}} | [ ] | {{test command}} | {{passing result}} |

### Backlog / Deferred

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{future work}} | [>] | {{reusable AUTO command or concrete MANUAL steps when resumed}} | {{observable pass result when resumed}} |

---

## 🧪 Current Verification Evidence

> AC ID is the unique key and may appear at most once. Update the existing row after each verification; do not append verification history.
> Keep the actual result to two sentences and store long output elsewhere with a stable path, report, screenshot, commit, or command locator.
> `[x]` requires a current `PASS` row. `[!]` and `[~]` retain the current manual, affected, blocked, failure, pending-implementation, or recovery state. An unverified `[ ]` or `[>]` row may have no evidence row.
> Mode B Recovery State uses exactly: `series: MB-YYYYMMDD-N; approach_ref: <ref>; attempt: N; limit: 3|4; kind: normal|guided; state: failed|blocked|authorized|reset|cancelled|rejected|resumed|pending-manual`.
> A successful Mode B result replaces that tuple with `completed`; series uniqueness applies to unfinished tuples still present in this table.

| AC ID | Last Verified | Type | Current Conclusion | Actual Result / Evidence Location | Recovery State |
|---|---|---|---|---|---|
| AC-<id> | {{YYYY-MM-DD HH:mm timezone or N/A}} | AUTO \| MANUAL \| REVIEW \| EXECUTION \| BLOCKED | PASS \| FAIL \| PENDING IMPLEMENTATION \| PENDING MANUAL \| AFFECTED \| BLOCKED \| RECOVERY STATE | {{concise result and stable locator, or N/A}} | {{exact Mode B tuple above, completed, or N/A}} |

---

## Status Annotation Convention

- `[ ]` not implemented; `[~]` partially implemented; `[x]` freshly verified passing; `[-]` deprecated; `[>]` explicitly deferred.
- An approved edit that invalidates PASS uses `[~]` with `EXECUTION / PENDING IMPLEMENTATION / N/A` evidence until implementation starts.
- `[!] [manual]` requires exact user verification steps and current `PENDING MANUAL` evidence.
- `[!] [affected]` requires re-verification and current `AFFECTED` evidence.
- `[!] [blocked]` records a reason, concrete unblock condition, and current `BLOCKED` evidence.

## 📊 Status Summary

> This is a derived view. Recompute every category after each batch of AC status changes.

| Category | Total | `[x]` | `[ ]` / `[~]` | `[!]` | `[>]` / `[-]` | Notes |
|----------|-------|-------|---------------|-------|---------------|-------|
| Features | | | | | | |
| Performance | | | | | | |
| Compatibility | | | | | | |
| Quality | | | | | | |
| Backlog / Deferred | | | | | | |

---

## 🧭 Scope Decision Log

> Add at most one row per user-approved scope batch. Scan existing IDs and choose the next unused numeric `N` for that date; never overwrite or reuse an ID. Record only acceptance-contract changes. For `[>]`, record the deferral reason and revisit trigger here while preserving the row's reusable verification contract.

| Date | Decision ID | AC Scope | Approved Scope Decision | Rationale |
|------|-------------|----------|-------------------------|-----------|
| {{YYYY-MM-DD}} | DEC-<YYYYMMDD>-<N> | AC-<id or range> | {{approved addition, edit, deferral, or deprecation}} | {{why the contract changed}} |

## Notes

- New top-level IDs are monotonic: `AC-<next integer>` is the current maximum numeric ID plus one; never renumber existing rows.
- AUTO rows contain executable commands. MANUAL rows contain exact user actions and expected outcomes.
- Do not put logs, benchmark data, screenshots, manual feedback, or evidence citations in the five-column acceptance table. Update the matching row in **🧪 Current Verification Evidence**.
