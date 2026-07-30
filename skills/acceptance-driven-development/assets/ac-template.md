---
template: acceptance-criteria
schema: 2
---

# {{Project Name}} Acceptance Criteria

> **Contract:** This file is the sole source of truth for accepted scope, AC IDs, verification state, evidence, user confirmation, deferral, and deprecation. Do not use a design or implementation plan as an acceptance-status tracker.

## 🎯 Project Goal

{{One sentence: what problem this solves and for whom}}

---

## 🧾 Acceptance Criteria

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