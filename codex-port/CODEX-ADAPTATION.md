# Codex Adaptation Guide

## Installation

Copy the full ADD folder into `$CODEX_HOME/skills/` (default fallback: `~/.codex/skills/`), including its `assets/` and `references/`. `project-experience` is an optional companion for explicit cross-project research or global-cache refresh:

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
  project-index.md                 → optional; Obsidian + Dataview only
  <ProjectName>/AC.md
  <ProjectName>/_<ProjectName>_exp.md → bounded routine guidance
  <ProjectName>/<ProjectName>.md
  <ProjectName>/plans/*.md         → retained Mode A execution records
```

An existing directory referenced by `~/.add-hub` remains active even when `_exp_memory.md` is missing. ADD reads the global cache once per new Agent/session and does not rebuild it automatically. A missing project capsule is created by copying the language-matching ADD capsule template, then seeded with at most three relevant entries already read from that cache, or left empty.

## Implementation Modes in Codex

- **Mode A** selects the one active plan matching project, canonical worktree, branch, baseline ancestry, target ACs, and approved approach. It resumes that plan or creates a collision-safe new file from `assets/implementation-plan-template.md`; it never overwrites a completed plan. A paused `user-cancelled` or `user-rejected` plan keeps ownership of overlapping ACs and blocks a replacement until explicit matched restart or approved supersession.
- **Mode B** creates no plan file. Keep exactly six chat fields: `Target AC`, `Files`, `Implementation steps`, `Verification`, `Review`, and `Commit`, including status/attempt, repository baseline, evidence, and commit outcome. Persist each target's independent failure series in its AC-keyed current-evidence row so interruption never resets it.
- A failed Mode B verification returns through Phase 3.5A but retains Mode B and the same series. Before the limit, write conclusion `FAIL` with `state: failed`; at the limit, write conclusion `BLOCKED` with `state: blocked`. Use `RECOVERY STATE` only for non-verification transitions such as authorization, reset, cancellation, rejection, and resumption.
- Codex task-plan UI may mirror the ADD plan, but it never owns AC status. The user reviews design and AC scope, not the implementation plan.
- After Agent-side verification and review, create an AC-scoped local commit when safely isolated. Re-check Git state, hooks, staged content, final commit, and tree. Record a hash, `COMMIT-BLOCKED`, or `COMMIT-SKIPPED`; unexpected post-hook state is `COMMIT-REVIEW-REQUIRED`.
- Never push, create or merge a PR, tag, or publish unless the user separately asks for that repository operation.

## Capability Mapping

ADD describes capabilities, not mandatory tool names. In Codex, use the native tool available in the active host:

| ADD need | Codex-compatible behavior |
|----------|---------------------------|
| Read/edit files | Use the current file/shell editing tool; preserve UTF-8 and inspect the surrounding context first. |
| Enumerate files | Use the current host's native listing/search command. On Windows PowerShell, prefer `Get-ChildItem`; do not assume Unix `find` or `cat`. |
| Track multi-step work | Mode A always creates/resumes ADD's persistent `plans/*.md`; Codex plan/task UI may mirror it but never replace it. Mode B alone stays chat-only through its Execution Map. |
| Independent batch review | Dispatch a review subagent only when the host exposes one **and** the current policy permits it. Otherwise perform and report the six-point self-review. |
| Invoke companion skills | Follow the host's skill-discovery mechanism. If a companion skill is unavailable, apply ADD's documented fallback instead of blocking. |

## Phase 0 in Codex

1. Read `~/.add-hub`.
2. If its trimmed path is an existing directory, use it as `$DOC_HUB`.
3. Only if the pointer is absent or invalid, find `_exp_memory.md`, read it once, and validate its parent; resolve ambiguity before rewriting the pointer. This read satisfies the session-wide global-cache read.
4. Otherwise read `_exp_memory.md` once after Hub location. Do not read it again during that Agent/session.
5. Resolve the project and read its direct `_<ProjectName>_exp.md` path once per independent Mode A/Mode B work unit. Never select it by searching all capsules.
6. Seed `project-index.md` only when the Hub is an Obsidian vault with confirmed Dataview support.

## Context and handoff

- Extract every AC table row for triage and impact coverage; fully read only target, affected, and nonterminal rows plus their current evidence. Read all of `AC.md` when targeted extraction is insufficient.
- Read the AC template only for creation, migration, missing schema metadata, or structural failure. Do not load the full project document for routine changes.
- Every Mode A plan begins with `Agent Handoff`: `Goal`, `Implemented`, `Verification`, `Last safe commit`, `Unresolved`, and `Worktree notes`.
- A new Agent reads the project capsule, scans plan frontmatter, and restores exactly one matching active plan. With no active plan, it reads the handoff named by `latest_completed_plan` only after root/worktree/branch/baseline checks; stale or mismatched pointers permit an identity-checked compatibility scan of `plans/`.
- One or two settled targets use Mode B only when low-risk. Architecture, dependency behavior, concurrency, persistence, security, migration, public-contract, and broad shared-component changes require Mode A.
- Load `references/failure-recovery-and-cancellation.md` only after a failed cycle, external block, interruption, cancellation/rejection, guided retry, redesign, recovery ambiguity, or mode switch. It owns the detailed attempt-series and ownership transitions; ordinary implementation remains in the main skill and implementation reference. A paused `superseded-by-mode-b` owner participates automatically in recovery: first normalize its task ownership idempotently, then reconcile a missing reset, unfinished Mode B work, or ownership handback.

## Phase 4.8 Review in Codex

For Mode A, prefer an independent review when the host and policy permit it. For Mode B, or when delegation is unavailable, report all six checks explicitly:

1. Wiring
2. Safety
3. Fidelity
4. State
5. Impact on other ACs
6. Framework-specific checks

## Cache Refresh

Only after separate user approval, `project-experience` may refresh the global cache: it admits project-capsule entries backed by completed, non-superseded plans, excludes `_exp_memory.md` seeds, writes `_exp_memory.md.tmp`, validates it, and replaces the cache after success. Explicit research with a missing cache uses at most two directly matched project documents read-only. Ordinary Mode A/Mode B work does not invoke that skill.

## Quick Verification

Ask for a small implementation using ADD. A correct run announces Phase 0, then either:

- Phase 3.5A for already-approved `[ ]` / `[~]` backlog work, followed by Mode A; or
- Phase 3.5B for a mid-development change, followed by the appropriate confirmed Mode.

Mode A reports its plan path and continues without plan approval. Mode B prints its six-field Execution Map. Both produce fresh AC evidence and a hash, `COMMIT-BLOCKED`, `COMMIT-SKIPPED`, or `COMMIT-REVIEW-REQUIRED`; none pushes automatically.
