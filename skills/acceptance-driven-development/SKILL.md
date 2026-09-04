---
name: acceptance-driven-development
description: Use when explicitly requested as ADD, acceptance criteria, or done conditions, or when creating or changing an identifiable persistent software project.
---

# Acceptance-Driven Development

Execute code changes against explicit acceptance criteria until each has a settled outcome.

**Completion:** implementation ends with no `[ ]`/`[~]`; project completion allows only `[x]`, `[>]`, or `[-]`.

## Activation Gate

Auto-activate only for creating or changing an identifiable persistent project. Otherwise one explicit invocation governs the current work unit, not unrelated work.

Without that invocation, questions, explanations, read-only/prose work, unrelated one-off scripts, and delivery-only Git/package/release operations fail. Only actual project changes enter Phase 3.5. On failure, stop before Phase 0; see the guardrails reference.

## 🚨 FIRST RULE — Check Before You Code

<EXTREMELY-IMPORTANT>
Every change governed by an active ADD work unit enters **Phase 3.5** before Phase 4. Announce the phase and implementation mode before editing code.

- Approved `[ ]` / `[~]` backlog → **Phase 3.5A** → Mode A.
- New feature or behavior change → **Phase 3.5B** → propose AC delta + approach → explicit approval → persist AC → Phase 4.
- Bug restoring intended behavior → **Phase 3.5B** impact analysis → fast lane; if no relevant AC exists, propose and confirm one before Phase 4.
- Refactor, build/config change, or pure cosmetic change → Phase 3.5B impact analysis → fast lane; untracked work also needs a confirmed tracking AC before Phase 4.

Describing a desired change is not approval of an approach. A fast-lane bug fix skips approach discussion, not impact analysis, review, or verification.
</EXTREMELY-IMPORTANT>

Announce each entered phase/gate using its heading. Read `references/guardrails-and-examples.md` only for rationale, pressure cases, examples, or the compact map.

## Capabilities and Scope

ADD is self-contained; external planning, review subagents, and `project-experience` research/cache refresh are optional. Plan status never replaces AC status.

Read `references/design-exploration-and-handoff.md` for explicit ADD exploration, Greenfield Gate 1, or a Large/genuinely ambiguous Phase 3.5B behavior change. Skip it for settled Small/Medium and fast-lane work.

Code formatting or typo fixes still enter Phase 3.5B fast lane.

## Phase 0: Locate Hub, Experience, AC, and Project Document

`$DOC_HUB`, outside code roots, holds ACs, templates, project documents, plans, and experience.

### Locate `$DOC_HUB`

1. Use the existing directory named by `~/.add-hub`.
2. If missing/invalid, find `_exp_memory.md`, read it once, and validate its parent using hub templates plus project `AC.md`/document directories. Cache presence alone is insufficient.
3. Use the sole validated candidate; otherwise ask the user to choose or confirm a hub.
4. After validation or user confirmation, write `~/.add-hub`. If only the pointer is unwritable, report it and continue this session; the hub itself must be writable before code.
5. With no candidate, ask for a stable shared directory, create it and an `_exp_memory.md` placeholder, then write the pointer.

### Experience entry and project capsule

After Hub location, each new Agent/session reads `$DOC_HUB/_exp_memory.md` once; step 2 fallback counts. Absence does not block ADD. Do not read it again in that session unless the user requests cross-project research or approves cache refresh.

Resolve the project and use `$DOC_HUB/<ProjectName>/_<ProjectName>_exp.md`, never a search-selected `*_exp.md`.
At the start of every independent ADD work unit, read that capsule once before impact analysis or planning. A Mode A batch or Mode B change is one unit; retries, verification, review, and continuation do not trigger another read.

If the capsule is absent, create it by copying the language-matching `assets/project-experience-capsule-template*.md`; never invent structure. Seed at most three relevant entries from the global cache already read this session, or none. Record its source cache revision; label seeds as `_exp_memory.md`, not project-verified facts.

The capsule is a flat list of at most 12 difficult, non-obvious, verified lessons, each titled and at most two sentences.
Project-earned lessons cite a completed source plan; initial seeds cite `_exp_memory.md`. Admit only reusable, verified investigation/diagnosis/trade-off/failure-repair guidance. Merge matching causes/solutions; exclude routine facts, counts, commits, and one-offs.
After initialization, Experience content changes only after a successfully completed, non-superseded Mode A plan; Mode B and unfinished plans never add lessons. Keep `latest_completed_plan: plans/<file>.md`, updated after each such plan even when no lesson changes. Never automatically re-seed an existing capsule.

### Locate AC, templates, and the AC Contract Gate

Use `$DOC_HUB/<ProjectName>/AC.md`; infer or present candidates only when the project is unknown. Copy missing templates from matching installed `assets/` files.
Seed `assets/project-index.md` only in an Obsidian vault after the user confirms Dataview is available/enabled. Offer the table CSS snippet there only with consent. Never recreate templates from memory.

### Step 0.3 — AC Contract Gate (before plan or code)

**`AC.md` is the sole source of truth** for accepted scope, AC IDs, acceptance status, verification evidence, acceptance confirmation, deferral, and deprecation.
A design document or conversation may retain an approved implementation approach; a plan only decomposes approved AC work and never owns acceptance state.

1. Read target `AC.md` before Gate 2, Phase 1, any external planning tool, or code. For current Schema 3 documents, do not also read the template.
2. Read `$DOC_HUB/ac-template.md` only when creating or migrating an AC, when schema metadata is missing, or when structural validation fails. Never recreate it from memory.
3. Validate Goal, meaningful sections, five semantic columns, markers, Status Summary, backlog, Current Verification Evidence, and Scope Decision Log. Localized equivalents are valid; Schema 2 remains readable until a separately approved migration.
4. Extract every AC table row. Fully read target, affected, and nonterminal rows plus their current-evidence rows. When targeted extraction is insufficient, read the complete AC document.
5. Gate 2 creates new AC from the full template. Malformed AC pauses plan/code; report gaps, preserve IDs/evidence/language, and ask before ambiguous migration.
6. **An external planning tool may start only after** this gate passes and relevant scope is approved. Every plan needs an **Acceptance Mapping** from tasks to AC IDs; plan state never changes AC status.
7. Keep five-column AC rows scannable. How to Verify contains only reusable commands or concrete manual steps. Replace the AC-keyed current-evidence row with concise results and stable locators; keep long output outside `AC.md`. Recompute Status Summary after every status batch.
8. MANUAL rows require concrete prerequisites/actions and an observable result. A vague check fails this gate; propose a clarified AC edit and obtain approval before plan/code.

### Step 0.4 — Living Project Document

**ADD owns project-document creation, update, and finalization; `project-experience` does not author them.**

Load the full project document only for first setup, material architecture/dependency/concurrency/persistence/build/deployment work, referenced facts, or low-frequency project finalization. When required but missing:

1. Read `$DOC_HUB/project-doc-template.md` before creating or restructuring a project document; populate verified facts from code → config → comments → README → history → labeled inference.
2. Match document language: Chinese `项目` with `开发中` / `维护中` / `已完成` / `归档`, or English `project` with `active` / `maintained` / `completed` / `archived`. Do not mix languages.
3. Label plans/uncertainty as `planned` or `⚠️ 无法确定`; update only for the material changes above.

### No AC: Greenfield gates

**Existing project but missing AC.md:** ask how to reconstruct scope; do not assume Greenfield. Build an unsaved five-column recovery draft, preserve evidence/uncertainty, and obtain approval before saving. Only projects without established code or scope enter Gates 1–2.

**Gate 1 — Design:** announce, use relevant experience already loaded, read `references/design-exploration-and-handoff.md`, complete its process, and obtain one design approval. Save `design.md`, then proceed to Gate 2 AC drafting without asking a separate permission.

**Gate 2 — Acceptance Criteria:** copy the full hub template, draft the approved design into five semantic columns, and allocate `AC-<next integer>` IDs. Present one proposed criterion per turn by default for confirmation/edit/split/merge/deferral; batch only on request. After all rows, wait for final approval, save `AC.md`, and enter Phases 1–3.

Use `references/change-design-guide.md` for sizing and the solution ladder.

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

No `[ ]` or `[~]` items: if the user requested a change, enter Phase 3.5B; otherwise present the annotation-aware `[!]` report. Approved remainder normally enters Phase 3.5A.
A `[~]` row with Mode B `state: failed`, or a `[ ]`/`[~]` row with `state: authorized`, `reset`, or `resumed`, returns through Phase 3.5A with its series and attempt state. `state: cancelled` or `state: rejected` waits for explicit restart and recovers its original mode/attempt state.

### Phase 2: Order

Order Features → Compatibility → Performance → Quality; infer missing categories and preserve AC ID order.

### Phase 3: Classify verification

| Class | Rule | Phase 5 result |
|---|---|---|
| AUTO | `How to Verify` has an executable command | Run command; `[x]` only on fresh pass. |
| MANUAL | UI/visual/human judgment with concrete AC steps and expected result | `[!] [manual]` with those exact steps. |
| BLOCKED | Environment unavailable, or a task/AC reaches the three-attempt boundary | `[!] [blocked]` with reason and concrete unblock condition. |

## Phase 3.5: Code-Change Entry (SINGLE ENTRY POINT)

### Phase 3.5A: Approved Backlog Entry

1. Announce `Phase 3.5A — Approved backlog impact analysis: N triaged ACs`.
2. Use the project capsule already read for this work unit, list target ACs, and trace relevant call paths.
3. Mark any affected `[x]` rows as `[!] [affected]` with `⚠️ Affected by AC-N implementation — needs re-verification`.
4. Initial triaged work always enters **Mode A**, even for one or two rows. Same-approach recovery of an unfinished Mode B series retains Mode B and its attempt state unless newly discovered impact meets a mandatory Mode A risk condition; it is not initial triage.

### Phase 3.5B: Mid-Development Requirement Changes

Use the project capsule already read for this work unit. Before approval, trace callers and present target ACs plus the proposed affected-AC list without mutating `AC.md`.

- **Behavior change:** apply relevant capsule lessons and classify size. For settled Small or Medium work, present the proposed AC delta with the approach and wait for explicit `approved` / `go ahead` / `confirm`.
  For Large or genuinely ambiguous work, read `references/design-exploration-and-handoff.md`, validate material questions, design sections, and proposed AC rows incrementally, then obtain one final combined approval for the consolidated design and AC delta.
- **Fast lane:** use only for original-behavior bug fixes, equivalent refactors, build/config changes, or pure cosmetics. If no relevant AC exists, propose the next numeric tracking AC and obtain quick confirmation; do not write it first.
- **Persistence boundary:**
  - Rejection/cancellation before approval leaves `AC.md` unchanged. After approval, atomically apply the approved delta before code; new targets start `[ ]`.
  - Cancellation after persistence but before code keeps the approved contract: new targets remain `[ ]`, while edited/resumed targets retain their persisted `[~]` or `[ ]` state.
  - An edited `[x]` target becomes `[~]` when its criterion, verification, or expected result changed. Replace stale PASS with Type `EXECUTION`, Conclusion `PENDING IMPLEMENTATION`, the approved delta locator, and Recovery State `N/A`.
  - A resumed `[>]` target becomes `[ ]` if untouched or `[~]` if implementation remains.
  - An approved redesign of `[!] [blocked]` starts a new attempt series and becomes `[ ]` with no retained implementation or `[~]` with retained implementation. Replace its blocking row with the new current recovery state.
  - Proposed affected non-target `[x]` rows become `[!] [affected]`. A tracked bug changes its target `[x]` to `[~]`; other tracked fast-lane work with unchanged accepted behavior marks target and affected `[x]` rows `[!] [affected]`.
- **Mode choice after Phase 3.5B persistence:** use Mode A for three or more related target ACs. One or two settled, low-risk targets may use Mode B. A material architecture, dependency relationship/behavior, concurrency, persistence, security, migration, public-contract, or broad shared-component change always uses Mode A regardless of AC count.

Physical-size uncertainty is Medium; genuine design ambiguity loads the design reference.

## Phase 4: Implement

Change only target scope; trace root cause and re-verify affected ACs.
Mode A reads `references/implementation-planning-and-execution.md` once when creating/recovering its plan. Routine Mode B uses the compact rules below. Read `references/failure-recovery-and-cancellation.md` only after a failed cycle, block, interruption, cancellation/rejection, guided retry, redesign, or mode switch. Load references fully only when targeted access is unavailable.

### Mode A: Batch

Use for Phase 3.5A, 3+ related Phase 3.5B targets, and every listed high-risk category.

1. List targets, then apply the reference's plan matching rules and reuse the sole match. Otherwise copy `assets/implementation-plan-template.md` to collision-safe `$DOC_HUB/<Project>/plans/YYYY-MM-DD-<topic>-implementation[-N].md`; never reopen a completed plan. Self-check and execute without asking for plan approval.
2. Run ready mapped tasks sequentially; parallelize only non-overlapping work.
3. Complete Phase 4.8: fresh baseline validation, then independent review when possible or explicit self-review; all checks pass before Phase 5.
4. Re-run affected AUTO ACs; hand off affected MANUAL ACs. Create a safe local AC-scoped checkpoint after Agent verification; never push unless separately requested. After three failed cycles for the same task, apply the reference's boundary.

**Mode A Continuation Rule:** A phase announcement or progress update is not a decision gate. While any target remains `[ ]` or `[~]`, continue ready tasks.
Do not stop after a plan task, ask whether to continue, or treat plan/subagent progress as acceptance completion. Three failed cycles block only the affected task and dependent ACs; continue independent rows.
Before a Phase 5 `[!] [manual]` handoff, finish every ready task that does not depend on that result. Stop the batch only when manual input is the next dependency, or for required approval, a shared/batch-wide block, user rejection/cancellation, or a real host/tool limit. Resume host/tool limits without reapproval.

### Mode B: Lightweight

Use only for a settled, low-risk Phase 3.5B change spanning one or two ACs: a behavior change is settled by approval; eligible fast-lane work is settled by impact analysis and, for untracked code, confirmation of its tracking AC.

1. Before code, print one **Execution Map** with exactly these top-level fields; do not create a persistent plan or ask for plan approval.

`Target AC` | `Files` | `Implementation steps` | `Verification` | `Review` | `Commit`

Target AC holds status/approach/attempt/guided state; Files holds owned paths and repository baseline; Verification holds class/action/result/evidence; Commit holds paths/message and pending, hash, `COMMIT-BLOCKED`, `COMMIT-SKIPPED`, or `COMMIT-REVIEW-REQUIRED`.
2. Implement, maintain the map, and complete Phase 4.8.
3. Apply Phase 3 classification: re-run affected AUTO; leave affected or changed MANUAL as `[!] [manual]` after review; send changed AUTO to Phase 5.
4. Create the same safe local AC-scoped checkpoint after Agent verification; never push unless separately requested. Apply the three-cycle failure boundary; user rejection uses the persisted rejection transition without incrementing it.

### Context and output budget

Announce phases briefly, summarize long output, and keep current evidence to two sentences. Record results only in their authoritative location; do not repeat unchanged AC lists.

## Phase 4.8: Review

Enter only after applicable baseline validation succeeds for the implementation subset being settled: build, type-check, lint, or relevant test. If baseline validation fails, return through the appropriate Phase 3.5 entry before review.
When another target is `[!] [blocked]`, review each implemented independent target and block impact; never claim the block passed Fidelity. Applicable checks must pass before independent targets enter Phase 5.

**Review checklist (6 items):**

1. Wiring — events/callbacks/connections and target lifetime.
2. Safety — nulls, empty/zero/boundary cases.
3. Fidelity — AC behavior is actually implemented.
4. State — interaction leaves consistent internal state.
5. Impact — affected ACs and shared dependencies rechecked.
6. Framework — apply `references/framework-review-checklist.md` when applicable.

Mode A prefers an independent reviewer; Mode B self-reviews inline. Output one result per item. FAIL must include file/line, severity, and fix; fix through the appropriate Phase 3.5 entry, re-run baseline validation, then review again.

## Phase 5: Verify and Mark

- **AUTO:** run the AC command and show command, expected result, actual result, and exit status; replace that AC's current-evidence row with the concise result and stable locator, then mark `[x]` only when its Current Conclusion is `PASS`. A successful Mode B target replaces its recovery tuple with `completed`.
- AUTO failure: replace current evidence and mark the target `[~]`. A repair within the approved AC and approach returns through Phase 3.5A without reapproval. An unfinished Mode B series retains Mode B and its attempt state; other repairs use Mode A. A material scope/behavior/approach change requires a proposed delta and Phase 3.5B approval.
- A failed affected AUTO AC in either mode is a regression: finish independent work and ask whether to repair or defer. Repair marks `[~]` and uses Phase 3.5A for approved scope, or Phase 3.5B for scope/behavior/approach changes. Deferral requires explicit confirmation before `[>]`.
- **MANUAL:** mark `[!] [manual]`, write `PENDING MANUAL`, and give exact steps. Mode B creates or retains its tuple as `state: pending-manual`. On `AC-N passed`, replace evidence with the reported `PASS`; Mode B writes `completed`; only then mark `[x]`.
- **BLOCKED:** mark `[!] [blocked]` with reason and unblock condition, including linked task evidence at the three-attempt boundary.
  When the condition clears, reclassify through Phase 3 and replace blocked evidence: use `[ ]` with no retained implementation or `[~]` when implementation remains, then enter Phase 3.5A with the attempt boundary preserved.
  A material new approach enters Phase 3.5B; verification-only work runs AUTO or the approved MANUAL handoff. Explicitly confirmed deferral/deprecation becomes `[>]`/`[-]` with a scope decision and affected-behavior handling.
- **Mode B:** changes batching/review only; changed AUTO follows AUTO, and changed MANUAL follows MANUAL.

### Manual Verification Handoff

For every `[!] [manual]`, output **Manual Verification Handoff** with `AC ID | What changed | Prerequisites | Exact steps | Expected result | Reply format`. Ask for replies such as `AC-45 passed` or `AC-45 failed: <observation>`; never replace it with a generic test request.

Derive the handoff from the approved MANUAL row. On `AC-N passed`, replace its current-evidence row and update the status. On `AC-N failed: <observation>`, replace current evidence, set `[~]`, and use Phase 3.5A; retain an unfinished Mode B series, otherwise use Mode A. A needed delta uses Phase 3.5B.

Split `[!]` reports by annotation; never ask a user to test `[blocked]`. Update a reported MANUAL pass immediately.

**Only mark `[x]` after FRESH verification in this turn.**

## Phase 6: Complete (HARD GATE)

1. Re-read AC. Unfinished Mode B follows Phase 1/3.5A with its mode/attempt: `failed` is `[~]`; `authorized`/`reset`/`resumed` is `[ ]` or `[~]`. Other triaged `[ ]` enters Mode A.
2. Settle `[~]`: fix through the appropriate Phase 3.5 entry, then Phases 4–5 to a freshly verified `[x]`; change to `[>]` or `[-]` only after explicit user confirmation of deferral or deprecation and after reverting partial code or preserving/re-verifying every affected nonterminal status.
3. Resolve `[!]`: user-test `[manual]`, re-run AUTO `[affected]`, and apply the Phase 5 unblock transition to `[blocked]` when its condition clears.
4. When only `[x]`, `[>]`, and `[-]` remain, perform low-frequency project finalization. Create or read the project document only through Step 0.4, then update durable facts, date, technical debt, review, and language-matching completion status.
5. After a non-superseded Mode A plan becomes `completed`, update `latest_completed_plan` and admit only qualifying difficult lessons to the project capsule. Ask separately whether to refresh the global cache; on approval, `project-experience` atomically validates and replaces `_exp_memory.md` through `_exp_memory.md.tmp`.

## References

- `references/change-design-guide.md` — change sizing, confirmation rules, solution ladder.
- `references/design-exploration-and-handoff.md` — conditional design exploration, one approval, and structured handoff.
- `references/guardrails-and-examples.md` — rationalizations, compact phase map, examples, extended red flags, optional-skill map.
- `references/framework-review-checklist.md` — framework-specific review checks.
- `references/ac-contract-and-plan-boundary.md` — AC schema, safe migration, plan boundary, and manual handoff.
- `references/implementation-planning-and-execution.md` — Mode A plan, Mode B map, task loop, review, and Git checkpoints.
- `references/failure-recovery-and-cancellation.md` — conditional failure, block, interruption, retry, redesign, and cancellation state machine.
