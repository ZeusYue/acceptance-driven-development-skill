---
template: acceptance-criteria
schema: 2
cssclasses: ac-document
---

# {{Project Name}} Acceptance Criteria

> **Contract:** This file is the sole source of truth for accepted scope, AC IDs, verification state, evidence, user confirmation, deferral, and deprecation. Do not use a design or implementation plan as an acceptance-status tracker.

## 🎯 Project Goal

{{One sentence: what problem this solves and for whom}}

---

## 🧾 Acceptance Criteria

> **Table convention:** The `ac-document` style renders five-column AC tables with stable proportions across categories. `ID` and `Status` stay compact; other cells wrap normally. Keep each cell scannable: criterion, verification method, and expected result are each limited to two sentences. Put complete command output, benchmark data, screenshot notes, and manual feedback in **Verification Evidence Details** below, then cite `See AC-N evidence` from the table.

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
| AC-<next integer> | {{future work}} | [>] | {{deferral reason / revisit trigger}} | {{explicit user decision}} |

---

## Verification Evidence Details

> Add an entry only when evidence exceeds a scannable table cell. Evidence remains in this `AC.md`, so this file remains the sole acceptance record.

### AC-<id> - {{YYYY-MM-DD}}

- **Verification type:** AUTO / MANUAL
- **Command or steps:** {{complete command or exact manual steps}}
- **Expected:** {{expected result}}
- **Actual result:** {{complete output, benchmark data, screenshot note, or user feedback}}
- **Conclusion:** Pass / Fail / Awaiting manual verification

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

---

## 🔄 Change Log

| Date | Change | Affected ACs | Decision / Rationale |
|------|--------|--------------|----------------------|
| {{YYYY-MM-DD}} | Initial AC draft | AC-<next integer>… | {{approved design reference}} |

## Notes

- New top-level IDs are monotonic: `AC-<next integer>` is the current maximum numeric ID plus one; never renumber existing rows.
- AUTO rows contain executable commands. MANUAL rows contain exact user actions and expected outcomes.
- Do not put full logs, lengthy benchmark data, or step-by-step manual feedback in the five-column table. Keep a short conclusion there, cite `See AC-N evidence`, and record the detail in **Verification Evidence Details** in this file.
