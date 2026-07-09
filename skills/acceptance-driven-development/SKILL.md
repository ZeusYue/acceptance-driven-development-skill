---
name: acceptance-driven-development
description: Use when building features, fixing bugs, or adding capabilities to a project that has an acceptance criteria document (AC.md) in its docs folder. Also use when the user says "implement this feature", "add X to the project", "fix this bug", or any task where completion should be measured against predefined verifiable criteria rather than "code compiles". Especially useful when previous development attempts left gaps because "done" was defined too loosely.
---

# Acceptance-Driven Development

Execute against a verifiable acceptance criteria checklist, looping until every criterion passes.

**Core principle:** If you can't verify it, you're not done. Only a checklist where every `[ ]` has become `[x]` or `[!]` is completion.

## 🚨 FIRST RULE — Check Before You Code

<EXTREMELY-IMPORTANT>
Before writing ANY code, in EVERY conversation turn: **Phase 3.5 first, then Phase 4.**

Phase 3.5 is the **single entry point** for all code changes:
- New feature / behavioral change → update AC → discuss → confirm → Phase 4
- Bug fix on existing AC → impact analysis → demote affected ACs → Phase 4 (fast lane, no discussion needed)
- Improvement to existing AC → check if behavioral change → if yes: update AC → discuss → confirm; if no: impact analysis → demote → Phase 4

There is no direct path to Phase 4. Every code change goes through Phase 3.5. **Before writing any code, announce which Phase 4 mode you're entering** (e.g., "Phase 4 Mode B — fix bug, 1 AC"). This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

| Rationalization | Reality |
|----------------|---------|
| "It's just one line of code" | One line still needs Phase 4 Mode B. |
| "I'm debugging, not coding" | The fix IS code. Debugging → fix → Phase 4. |
| "The fix is obvious" | Obvious fixes still need self-review. |
| "The user described the exact behavior" | Describing ≠ confirming your approach. |
| "I'll just fix it first, then update AC" | Code before AC = bypassing the process. Update AC first. |
| "This is too simple for the full process" | Phase 4 Mode B exists for exactly this case. |
| "Entering Phase 4 for a one-line fix is overkill" | Phase 4 Mode B is lightweight: implement → self-review → mark [!]. |
| "I can just self-review, subagent is overhead" | Prefer subagent (independent eyes catch what you missed). Self-review is acceptable for MANUAL-heavy projects. |
| "User said test passed, I'll update AC later" | User confirming test passed = update AC to `[x]` NOW. Not "later" — immediately. |

## Prerequisites

| Skill | Required for | Install |
|-------|-------------|---------|
| `brainstorming` | Gate 1 design, Phase 3.5 large changes | Superpowers pack |
| `writing-plans` | Phase 4 task decomposition | Superpowers pack |
| `subagent-driven-development` | Phase 4 task execution | Superpowers pack |
| `test-driven-development` | Phase 4 quality ACs | Superpowers pack |
| `verification-before-completion` | Phase 5 verification | Superpowers pack |
| `finishing-a-development-branch` | Phase 6 completion | Superpowers pack |
| `project-experience` | Phase 4 prior-project learning | Included in share kit |

**Graceful degradation:** Missing skill → engine continues but loses that capability. Tell the user what's missing. For brainstorming specifically: if unavailable, large changes (Phase 3.5) → ask user to describe requirements manually, then update AC.

**Project docs recommended** (the skill works without them, but they help):
- `projects/ac-template.md` — AC document template (format described inline in Gate 2 if missing)
- `projects/project-index.md` — Project index (used by `project-experience`; auto-created when first project is added)

> **Folder naming:** You can name the folder anything (`projects/`, `docs/`). The skill auto-discovers it by scanning for `AC.md` files. No Obsidian required.

## When to Use

```
User says "implement X" or "add Y feature"
              │
              ▼
     Does the project have AC.md?
              │
    ┌─────────┴──────────┐
    │ YES                │ NO → 🚨 Greenfield rule (Phase 0)
    ▼
 LOAD THIS SKILL
```

**Triggers:** implement/fix/add requests; project has `AC.md`; user mentions "AC"/"acceptance criteria"/"done means"; previous "done" was wrong.

**Skip:** Pure research; trivial fixes (typo, formatting); user declines to create AC.

---

## Phase 0: Locate and Load

Find the project docs and AC document. **Always use absolute paths.**

**Step 0.1 — Locate the project docs root (try in order):**
1. Search home directory: `Glob pattern="**/.obsidian"` or `Glob pattern="**/AC.md"` from `~`
2. Check current directory as fast path: `Read ".obsidian/app.json"` or `Glob "projects/**/AC.md"`
3. Ask user: "Where are your project docs? (can be an Obsidian vault or any folder)"
4. If user has no folder yet: "I can create one. Which directory?" → create `<chosen>/projects/` → VAULT. New project → Greenfield rule handles the rest.

**Step 0.2 — Find AC:** First discover what projects exist: `Glob "**/AC.md" path="<VAULT>"`. If the user mentioned a specific project name, read that one. Otherwise, present the list to the user or infer from the current code directory.

**Step 0.3 — If AC not found:**
- New project → 🚨 Greenfield rule below
- Should exist but missing → ask user

**Pre-Greenfield check:** If the docs folder doesn't exist under VAULT, create it first. Templates are optional — the AC format is described inline in Gate 2.

**🚨 Greenfield rule:** No AC yet → two-gate process:

#### Gate 1: Design Document
1. Announce: "New project — no AC yet. Let's clarify the goals first."
2. **Climb the solution ladder** before designing — stop at the first rung that holds:
   1. Already in this codebase? (reuse existing code)
   2. Standard library does it?
   3. Platform native feature covers it?
   4. Already-installed dependency solves it?
   5. Only then: search for new external libraries or design custom.
3. Run `Skill("brainstorming")` — interactive, ask questions, present options (including ladder findings from step 2). Do NOT silently infer.
4. Save as `<VAULT>/projects/<ProjectName>/design.md`
5. Tell user to review
6. **HARD GATE: Wait for user to say they're ready for AC creation**

#### Gate 2: Acceptance Criteria
1. Draft AC table from approved design. **Format**: `| ID | Criterion | Status | How to Verify | Expected Result |` (5 columns). Use sequential numbering (AC-1, AC-2, ...). Group by category (Features/Performance/Compatibility/Quality) using table section headers. Include status summary, change log, and Backlog sections.
2. Present draft to user
3. **HARD GATE: Wait for approval**
4. Save as `<VAULT>/projects/<ProjectName>/AC.md`
5. Proceed to Phase 1

**Violation:** Writing AC without user approval → delete file, back to Gate 1.

---

## Phase 1: Parse and Triage

Read the AC table. For each row, read the status column:

| Mark | Meaning | Action |
|------|---------|--------|
| `[ ]` | Not implemented | → Phase 2 |
| `[~]` | Partially done | → Phase 2 with note |
| `[x]` | Verified passing | Skip |
| `[-]` | Deprecated | Skip |
| `[!]` | Implemented, awaiting user | → Phase 6 checklist |
| `[>]` | Deferred / backlog | Skip — not now, but don't forget. |

No `[ ]` items? → report completion (present `[!]` checklist if any).

## Phase 2: Sort by Dependency

| Priority | Category | Reason |
|----------|----------|--------|
| 1 | Features | Everything depends on features existing |
| 2 | Compatibility | Verify environments before optimizing |
| 3 | Performance | Can't measure without working code |
| 4 | Quality | Tests verify existing code; write last |

If AC table doesn't have explicit category labels, infer from AC content. Sort by AC-ID ascending within each category.

## Phase 3: Classify by Verifiability

For each `[ ]` AC, read the "How to Verify" column and classify:

| Class | Icon | Criteria | Action |
|-------|------|----------|--------|
| **AUTO** | ✅ | Programmable verification | Phase 4 implements, Phase 5 verifies |
| **MANUAL** | ⚠️ | GUI/visual judgment needed | Phase 4 implements → mark `[!]` at Phase 5 |
| **BLOCKED** | 🚫 | Environment unavailable | Mark `[!]` at Phase 5 with reason |

**AUTO → BLOCKED fallback:** Verification fails due to environment (compiler not found, DLL missing) → reclassify as BLOCKED. Do NOT loop.

---

## Phase 3.5: Mid-Development Requirement Changes (SINGLE ENTRY POINT)

**ALL code changes must go through Phase 3.5 first.** No direct path to Phase 4.

### Impact analysis (before any code change):

Before writing code, grep for callers of the function(s) you're about to modify. For each caller, check: which AC does it belong to? **Demote affected ACs** — if an affected AC is currently `[x]` or `[!]`, change its status to `[ ]` with a note: `⚠️ Affected by [AC-ID] change — needs re-verification`. After implementation and review, re-verify before restoring status.

### Behavioral changes (requires AC update + discussion):

**Requires Phase 3.5 full process:** Adding/removing/changing buttons, UI state, data display, filters, validation, interaction behavior, **performance optimization** (user-perceptible behavior change — "laggy → smooth" is a behavioral change, not cosmetic). **Improving an existing AC's behavior** also requires Phase 3.5 if the improvement changes how the feature works.

**Does NOT require AC update (fast lane — impact analysis only):** Pure cosmetic (color, font, spacing) with no user-perceptible behavior change, code refactoring preserving identical behavior, build/config changes, **bug fixes that restore the originally intended behavior**.

**Fast lane exit:** After impact analysis, announce `"Phase 4 Mode B — fix bug, N AC"` before writing code. Do NOT write code directly from Phase 3.5. The announcement is the gate into Phase 4.

**How to handle — depends on size:**

| Size | Criteria | Process |
|------|----------|---------|
| **Small** | A single change within an existing file (move a line, rename a method, change a threshold, disable a button) | Update AC → **propose approach in 1-2 sentences, ask user to confirm** → implement |
| **Medium** | Anything that touches multiple files, adds a new file, adds a new UI element, or changes the interaction flow | **Check for existing libraries/tools** → discuss approach with user → update AC → confirm → implement |
| **Large** | New subsystem, architectural change, or feature that restructures existing code | **Check for existing libraries/tools** → `Skill("brainstorming")` → update design doc → update AC → confirm → implement |

**Default to Medium when uncertain.** If a change could be Small or Medium, classify it as Medium. The cost of over-discussing (1 extra minute) is lower than the cost of wrong direction (hours of rework).

**Every size includes a discussion step.** After updating AC, present your proposed approach and wait for the user to say "approved"/"go ahead" before writing code.

**Solution check (Medium and Large):** Before designing a solution, climb this ladder — stop at the first rung that holds:

1. **Already in this codebase?** Search for existing helpers, utils, or patterns that do the same thing. Reuse before rewriting.
2. **Standard library does it?** Use it. Don't hand-roll what ships with the language.
3. **Platform native feature covers it?** (e.g., CSS over JS, DB constraint over app code)
4. **Already-installed dependency solves it?** Use it. Don't add new deps for what a few lines can do.
5. **Only then:** design a custom solution, or search for new external libraries.

Present findings to the user as part of the options discussion.

**🚨 HARD GATE: Wait for the user to explicitly say "approved"/"go ahead"/"confirm" before writing any code.** "The user described the problem" is not confirmation. "The user seems to want this" is not confirmation. The user must use an explicit approval word.

After user confirms → Phase 4 (1-2 related ACs → Mode B, 3+ → Mode A).

**Violation trap:** User says "just do X first, then follow ADD" or "it's a small optimization" → does NOT exempt. Any behavioral change, regardless of how the user phrases it, must update AC first.

---

## Phase 4: Implement

Phase 4 has two modes. **Every code change must go through one of them.**

**Entering Phase 4:** Announce which mode you're using and why. E.g., "Phase 4 Mode B — fix bug, 1 AC" or "Phase 4 Mode A — batch 12 [ ] items". This creates a public commitment that makes it harder to skip steps.

**Rules for both modes:**
- **Impact re-verification:** Phase 3.5 already demoted affected ACs. In Phase 4.8, re-verify those ACs after implementation. Restore their status to `[x]` only if they pass.
- **Surgical changes:** Touch only what the AC requires. Every changed line must trace directly to the AC. Mention unrelated issues to the user — don't fix them.
- **Root cause before fixing:** Trace the full call chain before editing. Fix in the shared root, not in every caller.

### Mode A: Batch

When the skill first loads with multiple `[ ]` items remaining: process ALL of them sequentially.

**Mode A mandatory steps (execute in order, do not skip):**
1. **First: write all [ ] AC items to the table before any code.** No code before AC.
2. Implement all items sequentially. For interdependent items, implement them as a group.
3. **After all items are implemented** — Phase 4.8: dispatch ONE review subagent for the entire batch. Prefer subagent (independent eyes). Self-review is acceptable if subagent is unavailable or project is MANUAL-heavy. PASS → continue. FAIL → fix, re-review.

**Interdependent ACs:** If 2+ ACs share the same code change, implement them as one group. **Every group goes through the same batch review.**

Do NOT mark `[x]` here — Phase 5 handles that. Do NOT ask user between items.

**Stop when:** all items have completed steps 1-3 → Phase 5, or BLOCKED → record + continue, or CRITICAL failure → escalate.

For `[~]` items: review what's incomplete, implement the remaining part, then proceed as with `[ ]` items.

If AC table is large (30+ items): log a one-line progress update every 10 items (e.g., "Completed 10/30 items"). Do NOT pause or ask the user — continue processing. Only stop if context is approaching limits — then report which items are done and which remain; the session can resume from the AC table state.

### Mode B: Lightweight (user requests a specific change)

**Skip Phase 1-3.** Mode B does not need triage, sorting, or classification — those are for batch processing. Go directly from Phase 3.5 to implementation.

**Mode B mandatory steps (execute in order, do not skip):**
1. **Implement** the change
2. **Phase 4.8** — self-review against 5-item checklist (Wiring, Safety, Fidelity, State, Impact). PASS → continue. FAIL → fix, re-review.
3. **Mark `[!]`** in AC table (implemented, awaiting user verification)
4. Done. Do NOT re-scan other items. Do NOT enter batch mode.

Step 2 is not optional. Step 3 requires Step 2 to have passed. The user verifies in Phase 5 and marks `[x]`.

**Failure threshold:** If the same AC fails 3 times in a row (self-review FAIL or user rejects the fix), STOP. You're likely fixing symptoms, not root causes. Ask the user:

> "This feature has failed 3 times. The approach might be wrong. Want to switch approaches? (a) redesign via Phase 3.5, (b) try once more with guidance, (c) defer — mark [>]."

Wait for the user to decide before continuing.

**Execution methods (both modes):**
- New features (no code exists): `Skill("writing-plans")` → `Skill("subagent-driven-development")`
- Gaps/improvements (feature exists): direct implementation
- Test ACs (Quality): one test file per AC

**REQUIRED:** Load `Skill("project-experience")` on first Phase 4 entry of the session. Subsequent Mode B calls in the same session do NOT need to reload it.

**🚨 EXIT GATE: You cannot proceed to Phase 5 without completing Phase 4.8.** Implementing code is not done. Reviewing it is done. Proceed to Phase 4.8 now.

### Phase 4.8: Review

After code compiles, **before** marking `[!]` or `[x]`. **Use the same mode as Phase 4** — Mode A batch execution → Mode A review. Mode B lightweight execution → Mode B review. Do not mix modes.

**Review checklist (5 items, for both modes):**
1. **Wiring** — events, callbacks, signal/slot connections correct? Targets alive?
2. **Safety** — null/nil/undefined handled? Edge cases (empty, zero, boundaries)?
3. **Fidelity** — code actually implements what AC describes?
4. **State** — after user interaction, internal state still consistent?
5. **Impact on other ACs** — did this change affect code other ACs depend on? (review the impact analysis from Phase 3.5)

**Mode A (batch):** When all items are implemented, dispatch ONE review subagent for the entire batch. The subagent receives: all AC descriptions, all changed files, and this 5-item checklist plus any relevant framework knowledge. The subagent's value is independence — it reviews without the implementer's context bias, catching mistakes the author missed.

**Recommended, not a hard gate:** The subagent review is the preferred path. But if the project is MANUAL-heavy (GUI app, no programmable verification), or the subagent can't be dispatched, self-review against the 5-item checklist is an acceptable substitute. Mark `[x]` only after review (subagent or self-review) passes.

**Mode B (lightweight):** Self-review inline against the 5-item checklist above.

PASS → one line. FAIL → file:line + severity (CRITICAL/HIGH/MEDIUM/LOW) + fix.

**Framework-specific (both modes):** Apply relevant section from `references/framework-review-checklist.md`.

---

## Phase 5: Verify and Mark

After ALL Phase 4 items are implemented, verify each one:

| AC classification | Action |
|-------------------|--------|
| **AUTO** | Run verification command from AC table. Match → mark `[x]`. Mismatch → mark `[ ]`, return to Phase 4. |
| **MANUAL** | Mark `[!]`. Note: `⚠️ Needs user verification: [what to test]` |
| **BLOCKED** | Mark `[!]`. Note: `🚫 BLOCKED: [reason]` |

**Mode B items** are marked `[!]` during Phase 4.8 — verify they are actually marked. If any Mode B item is still `[ ]`, it was missed — return to Phase 4 Mode B for that item. **Present all [!] items (both Mode A MANUAL/BLOCKED and Mode B) to the user** with specific verification instructions. After user confirms each item works → mark `[x]`.

**🚨 User confirmation is event-driven, not phase-locked.** The user may test and report back at any time — minutes or hours after you presented the `[!]` list. When the user says "test passed" / "works" / "looks good" — **immediately update the corresponding AC from `[!]` to `[x]`**. Do not defer. Do not wait for a "Phase 5 moment." The moment the user confirms is the moment you update. This applies regardless of what phase you think you're in.

**Iron rule:** Only mark `[x]` after FRESH verification in this turn. "Passed before" doesn't count. Applies to both modes.

After marking all items, proceed to Phase 6 to check completion.

---

## Phase 6: Complete (HARD GATE)

**Done when:** Every AC is `[x]`, `[!]`, `[~]`, `[-]`, or `[>]`. No `[ ]` remains.

```
Phase 5 →
  ├── Any AUTO [ ] remaining? → Phase 4 (MANDATORY)
  └── No [ ] items? → Complete. Present [!] checklist if any.
```

**🚨 NEVER exit with `[ ]` ACs remaining.** Before saying "done": re-read AC, count `[ ]`, any > 0 → back to Phase 4 Mode A (batch process all remaining items).

When `[!]` items exist, present them as a user checklist with specific instructions for each item.

**Project document:** After all `[!]` items are confirmed by the user and marked `[x]`, create a project document at `<VAULT>/projects/<ProjectName>/<ProjectName>.md`. Follow the project doc template structure: one-line overview, tech stack, architecture, core modules, edge cases, reusable patterns, technical debt, and overall assessment. This document is read by `project-experience` in future projects — without it, the experience loop is broken.

---

## Quick Reference

| Phase | Action | Key |
|-------|--------|-----|
| 🚨 | **FIRST RULE** | ALL code changes → Phase 3.5 first. No direct path to Phase 4. |
| 0 | Locate docs + AC | Search → ask. New project → Gate 1 (brainstorm) → Gate 2 (AC) |
| 1 | Triage statuses | `[ ]` `[~]` `[x]` `[-]` `[!]` `[>]` |
| 2 | Sort by dependency | Features→Compat→Perf→Quality. No labels? Infer from content |
| 3 | Classify verifiability | AUTO ✅ / MANUAL ⚠️ / BLOCKED 🚫 |
| 3.5 | Single entry point | Impact analysis + demote ACs. New feature → update+discuss. Bug fix → fast lane → Phase 4 |
| 4 | Implement | Mode A: batch all [ ] / Mode B: lightweight (user-requested change) |
| 4.8 | Review | Mode A: subagent review / Mode B: self-review (Wiring + Safety + Fidelity + State + Impact) |
| 5 | Verify + mark | AUTO → command → `[x]` / MANUAL,BLOCKED → `[!]` / Mode B [!] → user confirms → `[x]` |
| 6 | Complete | `[ ]` exists? → Phase 4. Done when no `[ ]` |

---

## Examples

### Example 1: Greenfield (New Project)
```
User: "I want to build a photo browser"
Phase 0: No AC → Greenfield rule
Gate 1: search libraries → brainstorming → design.md → user reviews → ready for AC
Gate 2: draft ACs → user approves → AC.md
Phase 1-3: triage + sort + classify
Phase 4 Mode A: implement all AUTO items in batch
Phase 4.8 Mode A: one subagent reviews the batch → PASS
Phase 5: verify AUTO → [x], mark MANUAL/BLOCKED → [!]
Phase 6: present [!] checklist → done
```

### Example 2: Quality ACs (Tests)
```
User: "Add tests for this project"
Phase 0: AC found. AC-40~43 are [ ]
Phase 1-3: triage → sort → classify (all AUTO)
Phase 4 Mode A: create test files → one subagent reviews the batch → PASS
Phase 5: compile + run → 25/25 PASS → [x]
Phase 6: done
```

### Example 3: Mid-Development Change
```
User: "Tags can't be deleted from images — add that"
FIRST RULE: not in AC table → stop
Phase 3.5: add AC-33b → propose: "Add × button next to tag chips, confirm dialog on click"
         → user says "approved" → confirmed
Phase 4 Mode B: implement → self-review → PASS → mark [!]
Phase 5: user verifies → mark [x]
Phase 6: continue with remaining ACs
```

---

## Red Flags — STOP

| Flag | Action |
|------|--------|
| About to write code not in AC table | Update AC first (Phase 3.5) |
| About to say "done" while any `[ ]` exists | Re-read AC, back to Phase 4 |
| Same AC fails 3 times in a row | Stop patching. Ask user: switch approach, continue with guidance, or defer [>] |
| No `AC.md` and user declines | Abort |
| Greenfield: AC written without user seeing draft | Delete, back to Gate 1 |
| Asking user to test between AUTO items | Batch rule: finish all AUTO first |
| Agent modified code unrelated to the AC | Surgical change rule: revert unrelated changes, only keep what the AC requires |

## Integration with Superpowers

```
acceptance-driven-development
    ├── Skill("brainstorming")           ← Gate 1 + Phase 3.5 large changes
    ├── Skill("writing-plans")           ← Phase 4
    ├── Skill("subagent-driven-development") ← Phase 4
    ├── Skill("test-driven-development")      ← Phase 4 quality ACs
    ├── Skill("verification-before-completion") ← Phase 5
    ├── Skill("project-experience")           ← Phase 4 (REQUIRED)
    └── Skill("finishing-a-development-branch") ← Phase 6
```

## Reference Files

- `references/framework-review-checklist.md` — Qt/C++, React, Django, Go self-review items
