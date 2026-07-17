# {{Project Name}} Acceptance Criteria

> **ID rule:** Use one monotonic numeric sequence. Every new top-level criterion is `AC-<next integer>` (the current maximum numeric ID + 1). Never renumber existing rows; record requirement inserts in the Change Log.

## 🎯 Project Goal

<!-- One sentence: what problem does this solve, and who is it for -->

{{one-line goal}}

---

## 🧾 Acceptance Criteria

### Features

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{description}} | [ ] | {{command / test / UI action}} | {{what to see when passing}} |

### Performance

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{description}} | [ ] | {{executable benchmark command}} | {{measurable threshold}} |

### Compatibility

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{description}} | [ ] | {{environment + command}} | {{supported behavior}} |

### Quality

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{description}} | [ ] | {{test command}} | {{passing test result}} |

### Backlog / Deferred

| ID | Criterion | Status | How to Verify | Expected Result |
|----|-----------|--------|---------------|-----------------|
| AC-<next integer> | {{future work}} | [>] | {{why deferred / revisit trigger}} | {{explicit user decision}} |

---

## Status Annotation Convention

The primary marker remains one of `[ ]`, `[~]`, `[x]`, `[!]`, `[>]`, or `[-]`. When a row is `[!]`, add one annotation in the same Status cell or an adjacent note:

- `[!] [manual]` — implemented; waiting for the user's hands-on verification.
- `[!] [affected]` — a previously verified criterion affected by another change; AUTO items must be re-run, MANUAL items require fresh user verification.
- `[!] [blocked]` — verification is unavailable; include the reason and a concrete unblock condition.

---

## 📊 Status Summary

- `[ ]` Not implemented
- `[~]` Partially implemented
- `[x]` Freshly verified passing
- `[!] [manual]` Implemented; waiting for user verification
- `[!] [affected]` Needs re-verification because another change may affect it
- `[!] [blocked]` Cannot currently be verified; unblock condition recorded
- `[>]` Explicitly deferred by the user
- `[-]` Explicitly deprecated

---

## 🔄 Change Log

| Date | Change | Affected ACs | Decision / Rationale |
|------|--------|--------------|----------------------|
| {{YYYY-MM-DD}} | Initial AC draft | AC-1… | {{approved design reference}} |

---

## Notes

- AUTO rows require an executable command in **How to Verify**.
- MANUAL rows must describe the exact UI/action the user should check.
- Use `[>]` only after an explicit user decision; ADD does not silently implement deferred rows.
