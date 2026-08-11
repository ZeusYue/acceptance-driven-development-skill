---
name: acceptance-driven-development
description: Use when building features, fixing bugs, adding capabilities, or explicitly exploring a design under ADD before AC creation or update. Use with a project's AC.md acceptance table when available; also use when the user says implement, add, fix, acceptance criteria, done means, or asks ADD to compare approaches.
---

# Acceptance-Driven Development

Execute code changes against explicit acceptance criteria, then loop until every criterion has a settled outcome.

**Completion layers:** Agent implementation work is done only when no `[ ]` or `[~]` remain. The project is complete only when every AC is `[x]`, `[>]`, or `[-]` — no `[ ]`, `[~]`, or `[!]`.

## 🚨 FIRST RULE — Check Before You Code

<EXTREMELY-IMPORTANT>
Every code change enters **Phase 3.5** before Phase 4. Announce the phase and the chosen implementation mode before editing code.

- Approved `[ ]` / `[~]` backlog → **Phase 3.5A** → Mode A.
- New feature or behavior change → **Phase 3.5B** → propose AC delta + approach → explicit approval → persist AC → Phase 4.
- Bug restoring intended behavior → **Phase 3.5B** impact analysis → fast lane; if no relevant AC exists, propose and confirm one before Phase 4.
- Refactor, build/config change, or pure cosmetic change → Phase 3.5B impact analysis → fast lane; untracked work also needs a confirmed tracking AC before Phase 4.

Describing a desired change is not approval of an approach. A fast-lane bug fix skips approach discussion, not impact analysis, review, or verification.
</EXTREMELY-IMPORTANT>

Announce: `Phase 0`, `Gate 1`, `Gate 2`, `Phase 3.5A` or `3.5B`, `Phase 4 Mode A` or `B`, `Phase 4.8`, `Phase 5`, and `Phase 6` when each begins.

For rationale, common rationalizations, worked scenarios, extended red flags, and the compact phase map, read `references/guardrails-and-examples.md`.

## Capabilities and Scope

ADD is self-contained: AC parsing, impact analysis, review, verification, and completion checks must work even without companion skills.

| Optional capability | Use when available | Fallback |
|---|---|---|
| External planning tool | Mirror or assist ADD's approved-scope plan | Use the built-in plan asset/reference; never use tool status as acceptance status. |
| Review subagent | Mode A independent review | Explicit self-review against all six checks. |
| `project-experience` | Reuse cross-project lessons | Read `$DOC_HUB/_exp_memory.md` directly when present. |

Check host capabilities before relying on a subagent or a specific file tool. Missing optional capabilities never block the core workflow.

Design exploration is built in. Explicit ADD exploration always reads `references/design-exploration-and-handoff.md`; also read it for Greenfield Gate 1 or a Large / genuinely ambiguous Phase 3.5B behavior change. Otherwise skip it for settled Small or Medium changes and all fast-lane work.

Use ADD for implementation, fixes, and behavior changes. Skip it for pure research, prose-only formatting/typos, or when the user declines an AC process. Code formatting or typo fixes still enter Phase 3.5B fast lane.

## Phase 0: Locate Hub, AC, and Project Document

All ACs, templates, project documents, and experience cache live in one document hub (`$DOC_HUB`), independent of code directories.

### Locate `$DOC_HUB`

1. Read `~/.add-hub`. If its trimmed path is an existing directory, it is the active hub.
2. If the pointer is missing/invalid, search for `_exp_memory.md` only to identify candidate parent directories. Validate candidates with hub evidence such as templates plus project `AC.md` / project-document directories; cache presence alone is insufficient.
3. Use one validated candidate; if none validates or multiple remain, ask the user to choose or confirm the hub.
4. After validation or user confirmation, write `~/.add-hub`. If only the pointer location is unwritable, report it and keep the validated hub for this session; if the hub itself cannot store required AC/plan artifacts, ask for a writable hub before code.
5. If no candidate exists, ask for a stable shared directory, create it and `_exp_memory.md` placeholder, then write `~/.add-hub`.

Cache presence never determines hub identity. Use host-native file operations; do not require a literal `Glob` tool.

### Locate AC, templates, and the AC Contract Gate

Find `$DOC_HUB/*/AC.md`. Use the named project when known; otherwise present or infer candidates. When a hub template is missing, seed it by copying the matching installed asset: `assets/ac-template.md` or `assets/ac-template-zh.md`, `assets/project-doc-template.md`, `assets/project-index.md`, and `assets/implementation-plan-template.md`. In an Obsidian vault, also offer `assets/ac-document-tables.css` as `.obsidian/snippets/ac-document-tables.css`; enable it only with the user's consent. Never recreate a template from memory.

### Step 0.3 — AC Contract Gate (before plan or code)

**`AC.md` is the sole source of truth** for accepted scope, AC IDs, acceptance status, verification evidence, acceptance confirmation, deferral, and deprecation. A design document or conversation may retain an approved implementation approach; a plan only decomposes approved AC work and never owns acceptance state.

1. Read `$DOC_HUB/ac-template.md` and, when it exists, the target `AC.md` before Gate 2, Phase 1, any external planning tool, or code.
2. Validate Goal, meaningful sections, five semantic columns, valid markers, Status Summary, deferred/backlog area, and Verification Evidence Details. New documents require a Scope Decision Log; an existing document may retain its legacy Change Log until a separately approved migration. Localized header equivalents are valid.
3. For a new project, Gate 2 copies the full hub template and fills it; do not invent a partial AC table.
4. For an existing malformed AC, pause before planning/code, report gaps, preserve IDs/evidence/language, and ask before ambiguous migration.
5. **An external planning tool may start only after** this gate passes and the relevant AC scope is approved/updated. Every plan must include an **Acceptance Mapping** from every task to AC IDs; plan checkboxes never update or replace AC status. ADD provides its own plan asset and execution reference when no external planning tool exists.
6. Keep five-column AC rows scannable: do not place full logs, lengthy benchmark data, screenshots, or step-by-step feedback in cells. Record that material as a fixed `EVD-YYYYMMDD-N` event under the template's Verification Evidence Details heading in the same `AC.md`, then append `Evidence: EVD-...` (or its localized equivalent) to the How to Verify cell without replacing its reusable command/steps.
7. Every MANUAL row must contain concrete prerequisites/actions and an observable expected result. A vague check fails this gate; clarify it as a proposed AC edit and obtain approval before planning or code.

Read `references/ac-contract-and-plan-boundary.md` for schema, migration, and handoff details.

### Step 0.4 — Living Project Document

**ADD owns project-document creation, update, and finalization. `project-experience` reads/mines project documents; it does not author them.**

For an existing non-trivial project with code or `AC.md`, check for `$DOC_HUB/<ProjectName>/<ProjectName>.md` before the next substantial implementation batch. If missing:

1. Read `$DOC_HUB/project-doc-template.md` before creating or restructuring a project document.
2. Populate facts by evidence priority: code → config → comments → README → commit history → labeled inference.
3. Require frontmatter `tags`, `status`, and `date`; status: `开发中` / `维护中` / `已完成` / `归档`.
4. Record verified implementation facts now. Label plans and uncertainty as `planned` or `⚠️ 无法确定`.
5. Update only after meaningful architecture, dependency, concurrency, persistence, build, or deployment changes.

### No AC: Greenfield gates

**Existing project but missing AC.md:** ask the user how to recover or reconstruct its scope; do not treat it as Greenfield without confirmation. Build an unsaved five-column recovery draft from the hub template, preserve evidence and uncertainty, then wait for explicit scope approval before saving `AC.md` and entering Phases 1–3. Only a project with no established code or scope enters Gates 1–2.

**Gate 1 — Design:** announce, read relevant cache and `references/design-exploration-and-handoff.md`, then follow its design process and obtain one design approval. Save `design.md`, then proceed to Gate 2 AC drafting without asking a separate permission merely to create the draft.

**Gate 2 — Acceptance Criteria:** read and copy the full hub `ac-template.md`, then draft the approved design into its five semantic columns; use new top-level IDs as `AC-<next integer>`. Present one proposed criterion per turn by default so the user can confirm, edit, split, merge, or defer it; batch only when the user explicitly requests batch review. After all rows are reviewed, wait for one final approval before saving `AC.md`; after approval save it and enter Phases 1–3.

For detailed size classification and solution ladder, read `references/change-design-guide.md`.

## Phases 1–3: Triage, Order, Classify

### Phase 1: Parse statuses

| Mark | Action |
|---|---|
| `[ ]` | Implement. |
| `[~]` | Implement the known remainder. |
| `[x]` / `[-]` | Skip unless affected by the current change. |
| `[>]` | Skip unless the user explicitly resumes it. For unchanged accepted scope, record that decision, change to `[ ]` if untouched or `[~]` if partial implementation remains, then enter Phase 3.5A. Changed scope enters Phase 3.5B and remains `[>]` until approval. |
| `[!] [manual]` | Present for user verification. |
| `[!] [affected]` | Re-verify; AUTO now, MANUAL with user. |
| `[!] [blocked]` | Show reason and unblock condition. |

No `[ ]` or `[~]` items: if the user requested a change, enter Phase 3.5B; otherwise present the annotation-aware `[!]` report. Any `[~]` row is approved remainder and must enter Phase 3.5A with `[ ]` rows.

### Phase 2: Order

Default order: Features → Compatibility → Performance → Quality. Infer category when absent; preserve AC ID order within a category.

### Phase 3: Classify verification

| Class | Rule | Phase 5 result |
|---|---|---|
| AUTO | `How to Verify` has an executable command | Run command; `[x]` only on fresh pass. |
| MANUAL | UI/visual/human judgment with concrete AC steps and expected result | `[!] [manual]` with those exact steps. |
| BLOCKED | Environment unavailable, or a task/AC reaches the three-attempt boundary | `[!] [blocked]` with reason and concrete unblock condition. |

## Phase 3.5: Code-Change Entry (SINGLE ENTRY POINT)

### Phase 3.5A: Approved Backlog Entry

Use after Phases 1–3 for approved `[ ]` / `[~]` rows.

1. Announce `Phase 3.5A — Approved backlog impact analysis: N triaged ACs`.
2. List target ACs and trace relevant call paths.
3. Mark any affected `[x]` rows as `[!] [affected]` with `⚠️ Affected by AC-N implementation — needs re-verification`.
4. Initial triaged work always enters **Mode A**, even for one or two rows, preserving Phase 3 classification.

### Phase 3.5B: Mid-Development Requirement Changes

Before approval, trace callers and present target ACs plus the proposed affected-AC list without mutating `AC.md`.

- **Behavior change:** consult relevant experience cache and classify size. For settled Small or Medium work, present the proposed AC delta with the approach and wait for explicit `approved` / `go ahead` / `confirm`. For Large or genuinely ambiguous work, read `references/design-exploration-and-handoff.md`, validate material questions, design sections, and proposed AC rows incrementally, then obtain one final combined approval for the consolidated design and AC delta.
- **Fast lane:** use only for original-behavior bug fixes, equivalent refactors, build/config changes, or pure cosmetics. If no relevant AC exists, propose the next numeric tracking AC and obtain quick confirmation; do not write it first.
- **Persistence boundary:** rejection/cancellation leaves `AC.md` unchanged. After approval/confirmation, atomically apply the approved AC delta before code: new targets start `[ ]`; any edited target whose previous `[x]` criterion, verification, or expected result changed becomes `[~]` with the approved-delta-pending evidence; an approved edit that resumes a `[>]` target changes it to `[ ]` if untouched or `[~]` if partial implementation remains; proposed affected non-target `[x]` rows become `[!] [affected]`. For an already-tracked fast-lane bug, record the contrary evidence and change its target `[x]` row to `[~]`; for other tracked fast-lane work whose accepted behavior is unchanged, mark target and affected `[x]` rows `[!] [affected]` after impact analysis.
- **Mode choice after Phase 3.5B:** count approved target ACs after the persistence boundary; use Mode B for 1–2 related ACs, or Mode A for 3+.

Apply the detailed small/medium/large process and solution ladder in `references/change-design-guide.md`. When only physical size is uncertain, treat the change as Medium; genuine design ambiguity always loads the design reference.

## Phase 4: Implement

**Before any code, read and follow `references/implementation-planning-and-execution.md`.** Change only what the target AC requires; trace root cause before editing; re-verify affected ACs; use direct experience-cache reading or `project-experience` when available.

### Mode A: Batch

Use for all Phase 3.5A work and Phase 3.5B work spanning 3+ related ACs.

1. List every target AC before code.
2. Before code, copy `assets/implementation-plan-template.md` to `$DOC_HUB/<Project>/plans/YYYY-MM-DD-<topic>-implementation.md`, fill and self-check it, then execute without asking for plan approval.
3. Implement its AC-mapped tasks sequentially; group interdependent ACs and maintain the plan inside approved scope.
4. Complete Phase 4.8: fresh baseline validation, then one independent review when possible, otherwise explicit self-review; every check must pass before Phase 5.
5. Re-run affected AUTO ACs; affected MANUAL ACs remain `[!] [manual]`. Create safe local AC-scoped checkpoints after Agent-side verification; never push unless separately requested.
6. Continue to Phase 5. Stop and escalate after three failed attempts for the same task.

**Mode A Continuation Rule:** A phase announcement or progress update is not a decision gate. While any target AC in the active batch remains `[ ]` or `[~]`, continue sequentially. Do not stop after a plan task, ask whether to continue, or treat plan/subagent progress as acceptance completion. A blocked AC stops only itself unless it blocks a shared prerequisite or every remaining target; continue independent `[ ]` / `[~]` rows. Only stop the batch for an explicit ADD gate: required approval, a necessary `[!] [manual]` handoff after batch work reaches Phase 5, a batch-wide block, the three-failure boundary, user rejection/cancellation, or a real host/tool limit. On a host/tool limit, state it and resume the same batch next turn without reapproval.

### Mode B: Lightweight

Use only for a settled Phase 3.5B change spanning one or two ACs: a behavior change is settled by approval; eligible fast-lane work is settled by impact analysis and, for any untracked code change, quick confirmation of its tracking AC.

1. Before code, print the reference's six-field **Execution Map** in chat; do not create a persistent plan or ask for plan approval.
2. Implement, maintain the map in chat, and complete Phase 4.8 self-review.
3. Apply Phase 3 verification class to each changed AC; re-run affected AUTO ACs, while affected MANUAL ACs remain `[!] [manual]`.
4. Changed MANUAL criteria become `[!] [manual]` after review; changed AUTO criteria proceed to Phase 5 command verification. Create the same safe local AC-scoped checkpoint after Agent-side verification; never push unless separately requested.
5. Stop the target AC and apply the failure boundary after three consecutive failed attempts for that AC, or after explicit user rejection.

## Phase 4.8: Review

Enter only after applicable baseline validation succeeds: build, type-check, lint, or relevant test. If baseline validation fails, return through the appropriate Phase 3.5 entry to fix it before beginning Phase 4.8 review.

**Review checklist (6 items):**

1. Wiring — events/callbacks/connections and target lifetime.
2. Safety — nulls, empty/zero/boundary cases.
3. Fidelity — AC behavior is actually implemented.
4. State — interaction leaves consistent internal state.
5. Impact — affected ACs and shared dependencies rechecked.
6. Framework — apply `references/framework-review-checklist.md` when applicable.

Mode A prefers an independent reviewer; Mode B self-reviews inline. Output one result per item. FAIL must include file/line, severity, and fix; fix through the appropriate Phase 3.5 entry, re-run baseline validation, then review again.

## Phase 5: Verify and Mark

- **AUTO:** run the AC command and show command, expected result, actual result, and exit status; create a fixed EVD event, append its citation to the How to Verify cell without replacing the command, and only then mark `[x]`.
- AUTO failure: record evidence and mark the target `[~]`. A repair within the approved AC and approach returns through Phase 3.5A without reapproval; a material scope/behavior/approach change requires a proposed delta and Phase 3.5B approval.
- A failed affected AUTO AC after Mode B is a regression: present evidence and ask whether to repair or defer. On repair, mark `[~]` and use Phase 3.5A for the approved scope, or Phase 3.5B if the repair changes scope/behavior/approach. Deferral requires explicit user confirmation before `[>]`.
- **MANUAL:** mark `[!] [manual]` and provide exact user steps.
- **BLOCKED:** mark `[!] [blocked]` with reason and unblock condition, including the linked task evidence when the three-attempt boundary caused it. When the condition clears, reclassify through Phase 3: approved guidance with implementation remaining becomes `[~]` and enters Phase 3.5A; a material new approach enters Phase 3.5B; restored verification-only work runs the AUTO command or issues the approved MANUAL handoff. After explicit confirmation, a blocked AC may instead become `[>]` or `[-]`; record the scope decision and preserve/re-verify affected behavior as Phase 6 requires.
- **Mode B:** changes batching/review only; changed AUTO follows AUTO, and changed MANUAL follows MANUAL.

### Manual Verification Handoff

For every `[!] [manual]`, output **Manual Verification Handoff** with `AC ID | What changed | Prerequisites | Exact steps | Expected result | Reply format`. Ask for replies such as `AC-45 passed` or `AC-45 failed: <observation>`; never replace it with a generic test request.

The handoff must derive from the approved MANUAL row; do not invent a replacement verification contract outside `AC.md`. On `AC-N failed: <observation>`, record the evidence, change that row to `[~]`, and repair through Phase 3.5A when scope/behavior/approach remains approved; otherwise propose the needed delta through Phase 3.5B.

Split `[!]` reports by annotation. Never ask a user to test a `[blocked]` item. When a user reports a specific manual test passed, update that AC immediately.

**Only mark `[x]` after FRESH verification in this turn.**

## Phase 6: Complete (HARD GATE)

1. Re-read AC. Any remaining triaged `[ ]` returns through Phase 3.5A and Mode A.
2. Settle `[~]`: fix through the appropriate Phase 3.5 entry, then Phases 4–5 to a freshly verified `[x]`; change to `[>]` or `[-]` only after explicit user confirmation of deferral or deprecation and after reverting partial code or preserving/re-verifying every affected nonterminal status.
3. Resolve `[!]`: user-test `[manual]`, re-run AUTO `[affected]`, and apply the Phase 5 unblock transition to `[blocked]` when its condition clears.
4. When only `[x]`, `[>]`, and `[-]` remain, finalize the existing project document; if missing, create it through Step 0.4 first. Read the template, preserve evidence, set `status: 已完成`, update date, technical debt, and Agent self-review.
5. Ask whether to refresh experience cache. On approval request forced rebuild; do **not** delete old cache. `project-experience` writes `_exp_memory.md.tmp`, validates it, then replaces the cache.

## References

- `references/change-design-guide.md` — change sizing, confirmation rules, solution ladder.
- `references/design-exploration-and-handoff.md` — conditional design exploration, one approval, and structured handoff.
- `references/guardrails-and-examples.md` — rationalizations, compact phase map, examples, extended red flags, optional-skill map.
- `references/framework-review-checklist.md` — framework-specific review checks.
- `references/ac-contract-and-plan-boundary.md` — AC schema, safe migration, plan boundary, and manual handoff.
- `references/implementation-planning-and-execution.md` — required Mode A plan, Mode B Execution Map, task loop, recovery, and local Git checkpoints.
