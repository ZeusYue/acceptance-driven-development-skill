# Codex Adaptation Guide

## Installation

Copy the two skill folders into Codex's configured skills directory (commonly `~/.codex/skills/`):

```text
~/.codex/skills/acceptance-driven-development/
~/.codex/skills/project-experience/
```

Restart Codex and confirm that the skills are discoverable in the current host. The project-document hub is **not** a code-project folder: ADD discovers or creates it on first use through `~/.add-hub`.

## Current ADD Model

```text
~/.add-hub                         → absolute path to $DOC_HUB
$DOC_HUB/
  _exp_memory.md                   → optional cache, not Hub identity
  ac-template.md
  project-doc-template.md
  project-index.md
  <ProjectName>/AC.md
  <ProjectName>/<ProjectName>.md
```

An existing directory referenced by `~/.add-hub` remains the active Hub even if `_exp_memory.md` is missing. A missing cache triggers a full rebuild in that same Hub; it must not trigger a new Hub search.

## Capability Mapping

ADD describes capabilities, not mandatory tool names. In Codex, use the native tool available in the active host:

| ADD need | Codex-compatible behavior |
|----------|---------------------------|
| Read/edit files | Use the current file/shell editing tool; preserve UTF-8 and inspect the surrounding context first. |
| Enumerate files | Use the current host's native listing/search command. On Windows PowerShell, prefer `Get-ChildItem`; do not assume Unix `find` or `cat`. |
| Track multi-step work | Use the current plan/task mechanism when present; otherwise state the next checked step inline. |
| Independent batch review | Dispatch a review subagent only when the host exposes one **and** the current policy permits it. Otherwise perform and report the six-point self-review. |
| Invoke companion skills | Follow the host's skill-discovery mechanism. If a companion skill is unavailable, apply ADD's documented fallback instead of blocking. |

## Phase 0 in Codex

1. Read `~/.add-hub`.
2. If its trimmed path is an existing directory, use it as `$DOC_HUB`.
3. Only if the pointer is absent or invalid, search for `_exp_memory.md`; resolve ambiguity with the user before rewriting the pointer.
4. Check `_exp_memory.md` separately. It controls the experience-cache fast path, not the Hub identity.

## Phase 4.8 Review in Codex

For Mode A, prefer an independent review when the host and policy permit it. For Mode B, or when delegation is unavailable, report all six checks explicitly:

1. Wiring
2. Safety
3. Fidelity
4. State
5. Impact on other ACs
6. Framework-specific checks

## Cache Refresh

After a completed project, ADD may request: `Refresh the experience cache for the current $DOC_HUB.` `project-experience` then performs a forced rebuild, writes `_exp_memory.md.tmp`, validates it, and replaces the cache only after success. Never delete the cache merely to force a refresh.

## Quick Verification

Ask for a small implementation using ADD. A correct run announces Phase 0, then either:

- Phase 3.5A for already-approved `[ ]` / `[~]` backlog work, followed by Mode A; or
- Phase 3.5B for a mid-development change, followed by the appropriate confirmed Mode.
