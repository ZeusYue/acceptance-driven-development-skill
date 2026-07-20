---
name: acceptance-driven-development
description: Use when building features, fixing bugs, or adding capabilities that need a verifiable definition of done. Use with a project's AC.md acceptance table when available; also use when the user says implement, add, fix, acceptance criteria, or done means.
---

# Acceptance-Driven Development

Execute code changes against explicit acceptance criteria, then loop until every criterion has a settled outcome.

**Completion layers:** Agent implementation work is done only when no `[ ]` or `[~]` remain. The project is complete only when every AC is `[x]`, `[>]`, or `[-]` — no `[ ]`, `[~]`, or `[!]`.

## 🚨 FIRST RULE — Check Before You Code

<EXTREMELY-IMPORTANT>
Every code change enters **Phase 3.5** before Phase 4. Announce the phase and the chosen implementation mode before editing code.

- Approved `[ ]` / `[~]` backlog → **Phase 3.5A** → Mode A.
- New feature or behavior change → **Phase 3.5B** → update AC → discuss → explicit approval → Phase 4.
- Bug restoring intended behavior → **Phase 3.5B** impact analysis → fast lane → Phase 4.
- Refactor, build/config change, or pure cosmetic change → Phase 3.5B impact analysis → fast lane.

Describing a desired change is not approval of an approach. A fast-lane bug fix skips approach discussion, not impact analysis, review, or verification.
</EXTREMELY-IMPORTANT>

Announce: `Phase 0`, `Gate 1`, `Gate 2`, `Phase 3.5A` or `3.5B`, `Phase 4 Mode A` or `B`, `Phase 4.8`, `Phase 5`, and `Phase 6` when each begins.

For rationale, common rationalizations, worked scenarios, extended red flags, and the compact phase map, read `references/guardrails-and-examples.md`.

## Capabilities and Scope

ADD is self-contained: AC parsing, impact analysis, review, verification, and completion checks must work even without companion skills.

| Optional capability | Use when available | Fallback |
|---|---|---|
| `brainstorming` | Greenfield and large Phase 3.5B changes | Ask one requirement question at a time and record decisions. |
| `writing-plans` | New-feature decomposition | Write a concise file-by-file checklist. |
| Review subagent | Mode A independent review | Explicit self-review against all six checks. |
| `test-driven-development` | Behavior/quality work with runnable tests | Add the smallest relevant regression test first. |
| `project-experience` | Reuse cross-project lessons | Read `$DOC_HUB/_exp_memory.md` directly when present. |

Check host capabilities before relying on a subagent or a specific file tool. Missing optional capabilities never block the core workflow.

Use ADD for implementation, fixes, and behavior changes. Skip it for pure research, prose-only formatting/typos, or when the user declines an AC process. Code formatting or typo fixes still enter Phase 3.5B fast lane.

## Phase 0: Locate Hub, AC, and Project Document

All ACs, templates, project documents, and experience cache live in one document hub (`$DOC_HUB`), independent of code directories.

### Locate `$DOC_HUB`

1. Read `~/.add-hub`. If its trimmed path is an existing directory, it is the active hub.
2. If the pointer is missing/invalid, search for `_exp_memory.md`. If multiple hubs match, ask before choosing.
3. After an unambiguous or user-confirmed fallback choice, write `~/.add-hub`.
4. If none exists, ask for a stable shared directory, create it and `_exp_memory.md` placeholder, then write `~/.add-hub`.

Cache presence never determines hub identity. Use host-native file operations; do not require a literal `Glob` tool.

### Locate AC and templates

Find `$DOC_HUB/*/AC.md`. Use the named project when known; otherwise present or infer candidates. Ensure `$DOC_HUB/ac-template.md`, `$DOC_HUB/project-doc-template.md`, and `$DOC_HUB/project-index.md` exist when needed.

### Step 0.4 — Living Project Document

**ADD owns project-document creation, update, and finalization. `project-experience` reads/mines project documents; it does not author them.**

For an existing non-trivial project with code or `AC.md`, check for `$DOC_HUB/<ProjectName>/<ProjectName>.md` before the next substantial implementation batch. If missing:

1. Read `$DOC_HUB/project-doc-template.md` before creating or restructuring a project document.
2. Populate facts by evidence priority: code → config → comments → README → commit history → labeled inference.
3. Require frontmatter `tags`, `status`, and `date`; status: `开发中` / `维护中` / `已完成` / `归档`.
4. Record verified implementation facts now. Label plans and uncertainty as `planned` or `⚠️ 无法确定`.
5. Update only after meaningful architecture, dependency, concurrency, persistence, build, or deployment changes.

### No AC: Greenfield gates

**Existing project but missing AC.md:** ask the user how to recover or reconstruct its scope; do not treat it as Greenfield without confirmation. Only a project with no established code or scope enters Gates 1–2.

**Gate 1 — Design:** announce, read relevant cache, climb the solution ladder, discuss choices, save `design.md`, then wait for the user to approve AC creation.

**Gate 2 — Acceptance Criteria:** draft the approved-design AC table with `ID | Criterion | Status | How to Verify | Expected Result`; use new top-level IDs as `AC-<next integer>`; wait for approval before saving `AC.md`; after approval save it and enter Phases 1–3.

For detailed size classification and solution ladder, read `references/change-design-guide.md`.

## Phases 1–3: Triage, Order, Classify

### Phase 1: Parse statuses

| Mark | Action |
|---|---|
| `[ ]` | Implement. |
| `[~]` | Implement the known remainder. |
| `[x]` / `[-]` | Skip unless affected by the current change. |
| `[>]` | Skip unless the user explicitly requests it. |
| `[!] [manual]` | Present for user verification. |
| `[!] [affected]` | Re-verify; AUTO now, MANUAL with user. |
| `[!] [blocked]` | Show reason and unblock condition. |

No `[ ]` items: if the user requested a change, enter Phase 3.5B; otherwise present the annotation-aware `[!]` report.

### Phase 2: Order

Default order: Features → Compatibility → Performance → Quality. Infer category when absent; preserve AC ID order within a category.

### Phase 3: Classify verification

| Class | Rule | Phase 5 result |
|---|---|---|
| AUTO | `How to Verify` has an executable command | Run command; `[x]` only on fresh pass. |
| MANUAL | UI/visual/human judgment or vague check | `[!] [manual]` with exact steps. |
| BLOCKED | Environment unavailable | `[!] [blocked]` with reason and unblock condition. |

## Phase 3.5: Code-Change Entry (SINGLE ENTRY POINT)

### Phase 3.5A: Approved Backlog Entry

Use after Phases 1–3 for approved `[ ]` / `[~]` rows.

1. Announce `Phase 3.5A — Approved backlog impact analysis: N triaged ACs`.
2. List target ACs and trace relevant call paths.
3. Mark any affected `[x]` rows as `[!] [affected]` with `⚠️ Affected by AC-N implementation — needs re-verification`.
4. Initial triaged work always enters **Mode A**, even for one or two rows, preserving Phase 3 classification.

### Phase 3.5B: Mid-Development Requirement Changes

Before code, trace callers and mark affected verified ACs `[!] [affected]`.

- **Behavior change:** update AC, consult relevant experience cache, discuss the approach, and wait for explicit `approved` / `go ahead` / `confirm`.
- **Fast lane:** use only for original-behavior bug fixes, equivalent refactors, build/config changes, or pure cosmetics. If the buggy feature has no AC, add the next numeric AC, present it, and wait for quick confirmation.
- **Mode choice after Phase 3.5B:** approved behavior changes and eligible fast-lane work use Mode B for 1–2 related ACs, or Mode A for 3+.

Apply the detailed small/medium/large process and solution ladder in `references/change-design-guide.md`. When uncertain, treat the change as Medium.

## Phase 4: Implement

**Common rules:** change only what the target AC requires; trace root cause before editing; re-verify affected ACs; use direct experience-cache reading or `project-experience` when available.

### Mode A: Batch

Use for all Phase 3.5A work and Phase 3.5B work spanning 3+ related ACs.

1. List every target AC before code.
2. Implement sequentially; group interdependent ACs.
3. Complete Phase 4.8: fresh baseline validation, then one independent review when possible, otherwise explicit self-review; every check must pass before Phase 5.
4. Re-run affected AUTO ACs; affected MANUAL ACs remain `[!] [manual]`.
5. Continue to Phase 5. Stop and escalate after three failed attempts for the same AC.

### Mode B: Lightweight

Use only for a settled Phase 3.5B change spanning one or two ACs: a behavior change is settled by approval; eligible fast-lane work is settled by impact analysis (and by quick AC confirmation if its bug had no AC).

1. Implement.
2. Complete Phase 4.8 self-review.
3. Apply Phase 3 verification class to each changed AC; re-run affected AUTO ACs, while affected MANUAL ACs remain `[!] [manual]`.
4. Changed MANUAL criteria become `[!] [manual]` after review; changed AUTO criteria proceed to Phase 5 command verification.
5. Stop and ask for a new approach after three consecutive failures or user rejections.

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

- **AUTO:** run the AC command and show command, expected result, actual result, and exit status; only then mark `[x]`.
- AUTO failure: keep or return the target AC to `[ ]`, record evidence, then return through the appropriate Phase 3.5 entry before fixing: 3.5A for approved backlog, 3.5B for a current change.
- A failed affected AUTO AC after Mode B is a regression: present evidence and ask whether to repair through Phase 3.5B or defer it as `[>]` before another code edit.
- **MANUAL:** mark `[!] [manual]` and provide exact user steps.
- **BLOCKED:** mark `[!] [blocked]` with reason and unblock condition.
- **Mode B:** changes batching/review only; changed AUTO follows AUTO, and changed MANUAL follows MANUAL.

Split `[!]` reports by annotation. Never ask a user to test a `[blocked]` item. When a user reports a specific manual test passed, update that AC immediately.

**Only mark `[x]` after FRESH verification in this turn.**

## Phase 6: Complete (HARD GATE)

1. Re-read AC. Any remaining triaged `[ ]` returns through Phase 3.5A and Mode A.
2. Settle `[~]`: fix through the appropriate Phase 3.5 entry, then Phases 4–5 to a freshly verified `[x]`, defer as `[>]`, or deprecate as `[-]`.
3. Resolve `[!]`: user-test `[manual]`, re-run AUTO `[affected]`, and wait for unblock conditions on `[blocked]`.
4. When only `[x]`, `[>]`, and `[-]` remain, finalize the existing project document; if missing, create it through Step 0.4 first. Read the template, preserve evidence, set `status: 已完成`, update date, technical debt, and Agent self-review.
5. Ask whether to refresh experience cache. On approval request forced rebuild; do **not** delete old cache. `project-experience` writes `_exp_memory.md.tmp`, validates it, then replaces the cache.

## References

- `references/change-design-guide.md` — change sizing, confirmation rules, solution ladder.
- `references/guardrails-and-examples.md` — rationalizations, compact phase map, examples, extended red flags, optional-skill map.
- `references/framework-review-checklist.md` — framework-specific review checks.
