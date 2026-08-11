---
template: add-implementation-plan
schema: 1
project: {{Project Name}}
status: active
mode: A
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
code_root: {{code root}}
baseline_commit: {{commit hash or N/A}}
current_task: PLAN-1
target_acs:
  - AC-N
---

# {{Topic}} Implementation Plan

> This plan decomposes approved work. `AC.md` is the sole authority for scope, acceptance status, evidence, confirmation, deferral, and deprecation.

## Status Summary

| Task | AC mapping | Status | Depends on | Attempt | Commit group |
|------|------------|--------|------------|---------|--------------|
| PLAN-1 | AC-N | pending | none | 0 | {{group}} |

## Constraints

- {{approved scope and repository constraints}}
- Do not use plan status as AC status.
- Do not push, create or merge a PR, tag, or publish unless separately requested.

## Acceptance Mapping

| AC | Plan tasks | Verification |
|----|------------|--------------|
| AC-N | PLAN-1 | {{command or manual handoff}} |

## PLAN-1 - {{task outcome}}

- **Status:** pending
- **AC mapping:** AC-N
- **Depends on:** none
- **Files:** `{{path}}` - {{responsibility}}
- **Interfaces:** {{API, data flow, callback, or N/A}}
- **Steps:** {{ordered implementation steps}}
- **Test strategy:** TEST-FIRST | CHARACTERIZATION | TEST-AFTER | MANUAL - {{reason}}
- **Verification:** {{command or exact steps}}; expected: {{observable result}}
- **Review:** {{risk-driven reviewer or explicit self-review scope}}
- **Commit:** {{AC-scoped message and owned paths}}
- **Evidence:** pending

## Recovery State

- **Last safe commit:** {{hash or N/A}}
- **Working tree baseline:** {{clean or pre-existing paths}}
- **Blocked tasks:** N/A
- **Next ready task:** PLAN-1

## Final Record

- **Final AC outcomes:** pending
- **Evidence IDs:** pending
- **Local commits / COMMIT-BLOCKED:** pending
- **Approved deviations:** N/A
- **Technical debt:** N/A

## Plan Change Log

| Date | Task | Change | Reason |
|------|------|--------|--------|
| {{YYYY-MM-DD}} | PLAN-1 | Initial plan. | Approved AC scope persisted. |
