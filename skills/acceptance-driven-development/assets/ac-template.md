---
template: acceptance-criteria
schema: 2
cssclasses: ac-document
---

# {{Project Name}} Acceptance Criteria

> **Contract:** This file is the sole source of truth for accepted scope, AC IDs, verification state, evidence, acceptance confirmation, deferral, and deprecation. Do not use a design or implementation plan as an acceptance-status tracker.

## 🎯 Project Goal

{{One sentence: what problem this solves and for whom}}

---

## 🧾 Acceptance Criteria

> **Table convention:** The `ac-document` style renders five-column AC tables with stable proportions across categories. `ID` and `Status` stay compact; other cells wrap normally. Keep each cell scannable: criterion, verification method, and expected result are each limited to two sentences. Put complete command output, benchmark data, screenshot notes, and manual feedback in **🧪 Verification Evidence Details** below, then append `Evidence: EVD-YYYYMMDD-N` to the How to Verify cell without replacing its reusable command/steps.

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

## 🧪 Verification Evidence Details

> Use one stable event ID per verification batch. One event may cover multiple ACs. Scan existing IDs and choose the next unused numeric `N` for that date; never overwrite or reuse an ID. Keep only the latest concise EVD citation in each AC row while retaining older events here. Use `N/A` instead of omitting a field, and place long raw output inside `<details>`. Use `RECOVERY STATE` only for `EXECUTION` authorization/reset/recovery events; it never means acceptance passed.

### EVD-<YYYYMMDD>-<N> - AC-<id or range>

- **Verification time:** {{YYYY-MM-DD HH:mm timezone}}
- **Related ACs:** AC-N
- **Verification type:** AUTO | MANUAL | AUTO + MANUAL | EXECUTION | REVIEW | BLOCKED
- **Verification scope:** {{files, behavior, environment, or N/A}}
- **Command / Steps:** {{complete command, exact manual steps, or N/A}}
- **Expected result:** {{observable pass condition}}
- **Actual result:** {{concise result}}
- **Exit status:** {{code, PASS/FAIL, or N/A}}
- **Evidence attachment:** {{screenshot, report, log path, or N/A}}
- **Conclusion:** PASS | FAIL | PENDING MANUAL | BLOCKED | RECOVERY STATE
- **Status update:** {{AC status transition; for EXECUTION, the fixed Mode B series/approach/attempt/limit/kind/state recovery record; or N/A}}

<details>
<summary>Raw output (optional)</summary>

```text
{{long output}}
```

</details>

---

## Status Annotation Convention

- `[ ]` not implemented; `[~]` partially implemented; `[x]` freshly verified passing; `[-]` deprecated; `[>]` explicitly deferred.
- `[!] [manual]` requires exact user verification steps.
- `[!] [affected]` requires re-verification after another change; AUTO rows re-run commands, MANUAL rows return to the user.
- `[!] [blocked]` records a reason and concrete unblock condition.

## 📊 Status Summary

| Category | Total | `[x]` | `[ ]` / `[~]` | `[!]` | `[>]` / `[-]` | Notes |
|----------|-------|-------|---------------|-------|---------------|-------|
| Features | | | | | | |
| Performance | | | | | | |
| Compatibility | | | | | | |
| Quality | | | | | | |
| Backlog / Deferred | | | | | | |

---

## 🧭 Scope Decision Log

> Add at most one row per user-approved scope batch. Scan existing IDs and choose the next unused numeric `N` for that date; never overwrite or reuse an ID. Record only acceptance-contract changes; do not record implementation details, tests, ordinary status transitions, evidence events, or commits. For `[>]`, record the deferral reason and revisit trigger here while preserving the row's reusable verification contract.

| Date | Decision ID | AC Scope | Approved Scope Decision | Rationale |
|------|-------------|----------|-------------------------|-----------|
| {{YYYY-MM-DD}} | DEC-<YYYYMMDD>-<N> | AC-<id or range> | {{approved addition, edit, deferral, or deprecation}} | {{why the contract changed}} |

## Notes

- New top-level IDs are monotonic: `AC-<next integer>` is the current maximum numeric ID plus one; never renumber existing rows.
- AUTO rows contain executable commands. MANUAL rows contain exact user actions and expected outcomes.
- Do not put full logs, lengthy benchmark data, or step-by-step manual feedback in the five-column table. Append its EVD ID to the How to Verify cell after the reusable command/steps, and record the detail in **🧪 Verification Evidence Details** in this file.
