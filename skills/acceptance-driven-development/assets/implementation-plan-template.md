---
template: add-implementation-plan
schema: 2
plan_id: {{stable project-date-topic ID}}
project: {{Project Name}}
status: active
pause_reason: N/A
mode: A
created: {{YYYY-MM-DD}}
updated: {{YYYY-MM-DD}}
code_root: {{code root}}
worktree_id: {{canonical worktree path or stable host identity}}
branch: {{branch or N/A}}
baseline_commit: {{commit hash or N/A}}
active_tasks: []
target_acs:
  - AC-N
approach_ref: {{design path + D-N, approved-chat label, or legacy-approved-backlog:AC-N}}
scope_decision_ids: []
---

# {{Topic}} Implementation Plan

> This plan decomposes approved work. `AC.md` is the sole authority for scope, acceptance status, evidence, confirmation, deferral, and deprecation.

## Agent Handoff

- **Goal:** {{current approved outcome}}
- **Implemented:** N/A
- **Verification:** N/A
- **Last safe commit:** {{baseline commit or N/A}}
- **Unresolved:** PLAN-1
- **Worktree notes:** {{clean baseline or pre-existing paths}}

## Status Summary

| Task | AC mapping | Status | Depends on | Attempt | Commit group |
|------|------------|--------|------------|---------|--------------|
| PLAN-1 | AC-N | pending | none | 0 | {{group}} |

## Constraints

- {{approved scope and repository constraints}}
- **Applied project lessons:** {{only lessons that materially constrain this plan, or N/A}}
- Do not use plan status as AC status.
- Task status is `pending`, `in_progress`, `verified`, `blocked`, or evidence-backed `superseded`; only `in_progress` tasks belong in `active_tasks`.
- Do not push, create or merge a PR, tag, or publish unless separately requested.

## Acceptance Mapping

| Plan task | AC IDs | Implementation scope | Verification action |
|-----------|--------|----------------------|---------------------|
| PLAN-1 | AC-N | {{files / behavior}} | {{command or manual handoff}} |

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
- **Active tasks:** N/A
- **Next ready tasks:** PLAN-1

## Final Record

- **Final AC outcomes:** pending
- **Current evidence:** pending
- **Project capsule update:** pending
- **Local commits / COMMIT-BLOCKED / COMMIT-SKIPPED / COMMIT-REVIEW-REQUIRED:** pending
- **Approved deviations:** N/A
- **Technical debt:** N/A

## Plan Change Log

| Date | Task | Change | Reason |
|------|------|--------|--------|
| {{YYYY-MM-DD}} | PLAN-1 | Initial plan. | Approved AC scope persisted. |
