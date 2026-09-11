# Changelog

## [3.0.1] - 2026-09-11

- Clarify that `ac-template.md` is a structural example and that agents should
  write acceptance records in the user's and project's language.
- Refresh public README and installer notes for the patch release.

## [3.0.0] - 2026-09-11

Version 3 replaces the process-heavy ADD execution engine with a portable,
outcome-driven workflow for public use.

### Kept

- Observable acceptance criteria and evidence-backed status.
- Scope boundaries, regression checks, honest blocked/manual handoffs, and
  separation of acceptance from implementation progress.
- Risk-aware planning and review, safe handling of existing user changes,
  cancellation and rollback, and context-aware recovery.

### Changed

- Clear user requests authorize their stated outcome and ordinary implementation
  choices; only material product decisions or scope expansion require input.
- Planning, design, review, and verification depth follow uncertainty, impact,
  dependencies, reversibility, and whether work spans sessions.
- Acceptance discovery starts from the workspace, project instructions, and
  handoff paths/URLs/IDs. Existing authoritative records are reused. If no
  source or declared location exists, the agent asks before creating a durable
  record and never silently creates a default `AC.md`.
- Verification follows what available tools can actually observe. Relevant
  evidence can remain valid across turns until implementation or its assumptions
  change.
- The optional acceptance template is language-neutral in use: agents should
  write records in the user's or project's language rather than copy its English
  labels verbatim.

### Removed from the core package

- Numbered phases, Mode A/B, fixed retry quotas, and their recovery state machine.
- Mandatory `$DOC_HUB`, `~/.add-hub`, global cache, project capsule, and the
  `project-experience` companion skill.
- Mandatory Schema 3/Obsidian templates, framework-specific checklists, and
  AC-group commit requirements.

### Migration

Existing project acceptance records remain useful. Keep stable IDs, scope
decisions, valid evidence, cancellation, and deferral decisions. Historical
phase labels and attempt fields may remain as history, but they no longer control
execution. No bulk migration is required.

This release does not publish, install, or remove anything outside the repository
package. Host installation and runtime capabilities remain host-specific.
