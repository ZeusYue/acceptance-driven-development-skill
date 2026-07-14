---
name: acceptance-driven-development
description: Use when building features, fixing bugs, or adding capabilities to a project that has an acceptance criteria document (AC.md) in its docs folder. Also use when the user says "implement this feature", "add X to the project", "fix this bug", or any task where completion should be measured against predefined verifiable criteria rather than "code compiles". Especially useful when previous development attempts left gaps because "done" was defined too loosely.
---

# Acceptance-Driven Development

Execute against a verifiable acceptance criteria checklist, looping until every criterion passes.

**Core principle:** Completion has two layers. Agent work is done when no `[ ]` or `[~]` remain — all items are either implemented (`[!]`/`[x]`), deferred (`[>]`), or deprecated (`[-]`). Project is complete when every item has a settled outcome: `[x]` (user-verified), `[>]` (explicitly deferred), or `[-]` (explicitly deprecated).

## 🚨 FIRST RULE — Check Before You Code

<EXTREMELY-IMPORTANT>
Before writing ANY code, in EVERY conversation turn: **Phase 3.5 first, then Phase 4.**

Phase 3.5 is the **single entry point** for all code changes:
- New feature / behavioral change → update AC → discuss → confirm → Phase 4
- Bug fix on existing AC → impact analysis → demote affected ACs → Phase 4 (fast lane, no discussion needed)
- Improvement to existing AC → check if behavioral change → if yes: update AC → discuss → confirm; if no: impact analysis → demote → Phase 4

Phase 3.5 is the only path to Phase 4. Every code change goes through Phase 3.5. **Before writing any code, announce which Phase 4 mode you're entering** (e.g., "Phase 4 Mode B — fix bug, 1 AC"). This is a structural guardrail — awareness of it does not create an exception.

**Transparency rule:** Every major phase entry and mode choice must be announced to the user in a one-line summary. The user supervises via these announcements — they are not optional narration.

| When | Announce |
|------|----------|
| Entering Phase 0 | `Phase 0 — Locating AC documents` |
| New project (Greenfield) | `Gate 1 — Design discussion` / `Gate 2 — AC creation` |
| Entering Phase 3.5 | `Phase 3.5 — Impact analysis: [brief change description]` |
| Entering Phase 4 | `Phase 4 Mode A — batch N items` or `Phase 4 Mode B — [change description], N AC` |
| Entering Phase 4.8 | `Phase 4.8 — [Mode A review subagent / Mode B self-review]` |
| Entering Phase 5 | `Phase 5 — Verify and mark` |
| Entering Phase 6 | `Phase 6 — Completion check` |

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

**Standalone by default:** ADD works independently with direct implementation. **Optional upgrade:** Install Superpowers skills for enhanced workflows — `brainstorming` for interactive design, `writing-plans` for structured task decomposition, `subagent-driven-development` for independent subagent execution, etc. If a Superpowers skill is available, ADD automatically uses it. If not, ADD proceeds with direct implementation — no errors, no blocking.

**Project docs structure:** All documents live under `$DOC_HUB/<ProjectName>/`. Templates are auto-created in `$DOC_HUB/` on first use:
- `$DOC_HUB/ac-template.md` — AC document template (format described inline in Gate 2 if missing)
- `$DOC_HUB/project-doc-template.md` — Project doc template
- `$DOC_HUB/project-index.md` — Project index (used by `project-experience`; auto-created when first project is added)

> No Obsidian required — `$DOC_HUB` is a plain directory. If you use Obsidian, set `$DOC_HUB` to your vault path to manage documents alongside your notes.

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

## Phase 0: Locate Document Hub

All project ACs, project docs, templates, and the experience cache live under a single **document hub** (`$DOC_HUB`). This is independent of code directories — the hub is shared across all projects, sessions, and windows.

**Step 0.1 — Discover $DOC_HUB via the cache anchor:**

1. `Glob pattern="**/_exp_memory.md" path="~"` — search home directory for the experience cache anchor file
   - **Found** → `$DOC_HUB` = the directory containing `_exp_memory.md`. Skip to Step 0.2.
   - **Not found** → ask the user once: "I need a central directory to store acceptance criteria and project experience for ALL your projects. This directory will be shared across projects, so pick a stable location — don't put it inside a specific project folder. Suggested: ~/project-docs/ (just give me the path; I'll create the needed files there.)"
     → `$DOC_HUB` = user's answer. Create the directory. **Immediately create `$DOC_HUB/_exp_memory.md`** with `# Project Experience Cache\n\n> No completed projects yet.` so other sessions discover the hub immediately.

**Step 0.2 — Find project AC:**

`Glob pattern="$DOC_HUB/*/AC.md"` — lists all projects with AC documents. If the user mentioned a specific project name, read that one. Otherwise, present the list or infer from context.

**Step 0.3 — If AC not found:**
- New project → 🚨 Greenfield rule below
- Project exists but AC missing → ask user

**Note:** Templates (`ac-template.md`, `project-doc-template.md`) are auto-created in `$DOC_HUB/` on first use if missing. No Obsidian required — `$DOC_HUB` is a plain directory.

**🚨 Greenfield rule:** No AC yet → two-gate process:

#### Gate 1: Design Document
1. Announce: "New project — no AC yet. Let's clarify the goals first."
2. **Check experience cache:** Read `$DOC_HUB/_exp_memory.md` if it exists. Scan `Known Pitfalls` and `Reusable Patterns` for anything relevant to the new project's domain or tech stack. Mention relevant findings during design discussion.
3. **Climb the solution ladder** before designing — stop at the first rung that holds:
   1. Already in this codebase? (reuse existing code)
   2. Standard library does it?
   3. Platform native feature covers it?
   4. Already-installed dependency solves it?
   5. Only then: search for new external libraries or design custom.
4. Run `Skill("brainstorming")` — interactive: ask explicit questions, present options (including ladder findings from step 3). Every design decision requires user input.
5. Save as `$DOC_HUB/<ProjectName>/design.md`
6. Tell user to review
7. **HARD GATE: Wait for user to say they're ready for AC creation**

#### Gate 2: Acceptance Criteria
1. Draft AC table from approved design. **Format**: `| ID | Criterion | Status | How to Verify | Expected Result |` (5 columns). Use sequential numbering (AC-1, AC-2, ...). Group by category (Features/Performance/Compatibility/Quality) using table section headers. Include status summary, change log, and Backlog sections.
2. Present draft to user
3. **HARD GATE: Wait for approval**
4. Save as `$DOC_HUB/<ProjectName>/AC.md`
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
| `[!]` | Implemented, awaiting user | Present in Phase 6; user tests → mark `[x]` |
| `[>]` | Deferred / backlog | Skip. This is a user-facing marker — agent does NOT suggest implementing it unless the user explicitly requests it. |

No `[ ]` items? → the AC table is up to date. If the user requested a change, proceed to Phase 3.5. If just checking status, present the `[!]` checklist.

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

**AUTO classification requires an executable command in the "How to Verify" column** (e.g., `pytest`, `npm test`). Vague descriptions like "check it works" → classify as MANUAL.

**AUTO → BLOCKED fallback:** Verification fails due to environment (compiler not found, DLL missing) → reclassify as BLOCKED. Stop at first failure — record the reason, mark BLOCKED, continue to next item.

---

## Phase 3.5: Mid-Development Requirement Changes (SINGLE ENTRY POINT)

**ALL code changes enter through Phase 3.5.** Phase 3.5 is the only path to Phase 4.

### Impact analysis (before any code change):

Before writing code, grep for callers of the function(s) you're about to modify. For each caller, check: which AC does it belong to? **Demote affected ACs** — if an affected AC is currently `[x]` or `[!]`, change its status to `[ ]` with a note: `⚠️ Affected by [AC-ID] change — needs re-verification`. After implementation and review, re-verify before restoring status.

### Behavioral changes (requires AC update + discussion):

**Requires Phase 3.5 full process:** Adding/removing/changing buttons, UI state, data display, filters, validation, interaction behavior, **performance optimization** (user-perceptible behavior change — "laggy → smooth" is a behavioral change, not cosmetic). **Improving an existing AC's behavior** follows the standard Phase 3.5 process if the improvement changes how the feature works.

**Does NOT require AC update (fast lane — impact analysis only):** Pure cosmetic (color, font, spacing) with no user-perceptible behavior change, code refactoring preserving identical behavior, build/config changes, **bug fixes that restore the originally intended behavior**.

**Fast lane exit:** After impact analysis, announce `"Phase 4 Mode B — fix bug, N AC"` before writing code. The announcement is the gate into Phase 4. **If the buggy feature has no AC entry** (e.g., it was built before ADD was adopted), append a one-line AC to the appropriate category section with the next sequential ID. Use the standard 5-column format. Present the new AC entry to the user: "I added AC-N: [description] to track this fix. OK to proceed?" Wait for confirmation before writing code. Then proceed with the fix.

**How to handle — depends on size:**

| Size | Criteria | Process |
|------|----------|---------|
| **Small** | A single change within an existing file (move a line, rename a method, change a threshold, disable a button) | Update AC → **propose approach in 1-2 sentences, ask user to confirm** → implement |
| **Medium** | Anything that touches multiple files, adds a new file, adds a new UI element, or changes the interaction flow | **Check for existing libraries/tools** → discuss approach with user → update AC → confirm → implement |
| **Large** | New subsystem, architectural change, or feature that restructures existing code | **Check for existing libraries/tools** → `Skill("brainstorming")` → update design doc → update AC → confirm → implement |

**Default to Medium when uncertain.** If a change could be Small or Medium, classify it as Medium. The cost of over-discussing (1 extra minute) is lower than the cost of wrong direction (hours of rework).

**Check experience cache (all sizes):** Before proposing an approach, read `$DOC_HUB/_exp_memory.md` (the global experience cache maintained by `project-experience`). Scan the `Known Pitfalls` and `Reusable Patterns` sections for anything relevant to the current change. This is a 2-second scan — don't re-load project-experience, just read the file. If you find a relevant pitfall or pattern, mention it when presenting your approach to the user.

**Every size includes a discussion step — except fast-lane bug fixes** (impact analysis → mode announcement → implement). After updating AC, present your proposed approach and wait for the user to say "approved"/"go ahead" before writing code.

**Solution check (Medium and Large):** Before designing a solution, climb this ladder — stop at the first rung that holds:

1. **Already in this codebase?** Search for existing helpers, utils, or patterns that do the same thing. Reuse before rewriting.
2. **Standard library does it?** Use it. Don't hand-roll what ships with the language.
3. **Platform native feature covers it?** (e.g., CSS over JS, DB constraint over app code)
4. **Already-installed dependency solves it?** Use it. Don't add new deps for what a few lines can do.
5. **Only then:** design a custom solution, or search for new external libraries.

Present findings to the user as part of the options discussion.

**🚨 HARD GATE: Wait for the user to explicitly say "approved"/"go ahead"/"confirm" before writing any code.** "The user described the problem" is not confirmation. "The user seems to want this" is not confirmation. The user must use an explicit approval word.

After user confirms → Phase 4 (1-2 related ACs → Mode B, 3+ → Mode A).

**Violation trap:** User says "just do X first, then follow ADD" or "it's a small optimization" → still requires Phase 3.5. Any behavioral change, regardless of how the user phrases it, must update AC first.

---

## Phase 4: Implement

Phase 4 has two modes. **Every code change must go through one of them.**

**Entering Phase 4:** Announce which mode you're using and why. E.g., "Phase 4 Mode B — fix bug, 1 AC" or "Phase 4 Mode A — batch 12 [ ] items". This creates a public commitment that makes it harder to skip steps.

**Rules for both modes:**
- **Impact re-verification:** Phase 3.5 already demoted affected ACs. In Phase 4.8, re-verify those ACs after implementation. Restore their status to `[x]` only if they pass.
- **Surgical changes:** Touch only what the AC requires. Every changed line must trace directly to the AC. Mention unrelated issues to the user — don't fix them.
- **Root cause before fixing:** Trace the full call chain before editing. Fix in the shared root, not in every caller.
- **Re-verify definition:** For AUTO items, re-run the verification command from the AC's "How to Verify" column. For MANUAL items, re-assess the feature against the criterion manually.

### Mode A: Batch

When the skill first loads with multiple `[ ]` items remaining: process ALL of them sequentially.

**Mode A mandatory steps (execute sequentially):**
1. **First: list all [ ] AC items to be implemented** — copy their IDs and descriptions into the conversation for tracking. No code before this list is established.
2. Implement all items sequentially. For interdependent items, implement them as a group.
3. **After all items are implemented** — Phase 4.8: dispatch ONE review subagent for the entire batch. Prefer subagent (independent eyes). Self-review is acceptable if subagent is unavailable or project is MANUAL-heavy. PASS → continue. FAIL → fix, re-review.
4. **Restore demoted ACs** — if Phase 3.5 impact analysis demoted any ACs from `[x]`/`[!]` to `[ ]`, re-verify them now. Restore to `[x]` if they still pass.

**Interdependent ACs:** If 2+ ACs share the same code change, implement them as one group. **Every group goes through the same batch review.**

Marking happens in Phase 5, not here. Process all items without pausing for user confirmation between them.

**Stop when:** all items have completed steps 1-2 → Phase 5, or BLOCKED → record + continue, or CRITICAL failure → escalate.

**Failure threshold:** If any AC (AUTO or MANUAL) fails verification or user testing 3 times in Mode A (Phase 5 marks it `[ ]`, back to Phase 4, re-implement, re-verify, still fails), STOP. The verification command or the approach is likely wrong. Present findings to the user before attempting a 4th time.

For `[~]` items: review what's incomplete, implement the remaining part, then proceed as with `[ ]` items.

If AC table is large (30+ items): log a one-line progress update every 10 items (e.g., "Completed 10/30 items"). Continue processing uninterrupted. Only stop if context is approaching limits — then report which items are done and which remain; the session can resume from the AC table state.

### Mode B: Lightweight (user requests a specific change)

**Skip Phases 1-3 (triage, sort, classify).** Phase 3.5 is still REQUIRED — it is the single entry point for all code changes. Go from Phase 3.5 to implementation.

**Mode B mandatory steps (execute sequentially):**
1. **Implement** the change
2. **Phase 4.8** — self-review against 6-item checklist (Wiring, Safety, Fidelity, State, Impact, Framework). PASS → continue. FAIL → fix, re-review.
3. **Restore demoted ACs** — if Phase 3.5 impact analysis demoted any ACs from `[x]`/`[!]` to `[ ]`, re-verify them now. Restore to `[x]` if they still pass. If re-verification fails, the change introduced a regression. Announce: "This change broke AC-N which previously passed. Options: (a) fix the regression now, (b) accept the tradeoff and mark AC-N as `[!]` with a note." Do not silently leave it as `[ ]`. These are already-implemented features that just needed re-validation after the change.
4. **Mark `[!]`** in AC table (implemented, awaiting user verification)
5. Done — this change only. Batch mode is for initial full scans, not for Mode B.

Step 1 → Step 2 → Step 3 → Step 4 — execute sequentially. Step 4 only after Step 2+3 pass. The user verifies in Phase 5 and marks `[x]`.

**Failure threshold:** If the same AC fails 3 times in a row (self-review FAIL or user rejects the fix), STOP. Shift to diagnosis mode — repeated failures indicate the approach, not the implementation, is wrong. Ask the user:

> "This feature has failed 3 times. The approach might be wrong. Want to switch approaches? (a) redesign via Phase 3.5, (b) try once more with guidance, (c) defer — mark [>]."

Wait for the user to decide before continuing. If deferring (option c), also revert demotion notes on affected ACs — restore them to their original `[x]`/`[!]` status since the change that would have affected them is being deferred.

**Execution methods (both modes):**
- New features (no code exists): `Skill("writing-plans")` → `Skill("subagent-driven-development")`
- Gaps/improvements (feature exists): direct implementation
- Test ACs (Quality): one test file per AC

**REQUIRED:** Load `Skill("project-experience")` on first Phase 4 entry of the session. Subsequent Mode B calls in the same session do NOT need to reload it. **If project-experience is not installed**, skip experience loading and proceed with direct implementation. Warn the user: "project-experience is not installed, skipping project experience loading. Install it to get cross-project experience reuse."

**🚨 EXIT GATE: Phase 5 opens only after Phase 4.8 completes for every item.** Code written ≠ code done. Code reviewed = code done. Go to Phase 4.8 now.

### Phase 4.8: Review

After code compiles. Mode A marks in Phase 5, not here. Mode B marks `[!]` after review passes. **Match review mode to execution mode** — Mode A execution → Mode A review. Mode B execution → Mode B review.

**Review checklist (6 items, for both modes):**
1. **Wiring** — events, callbacks, signal/slot connections correct? Targets alive?
2. **Safety** — null/nil/undefined handled? Edge cases (empty, zero, boundaries)?
3. **Fidelity** — code actually implements what AC describes?
4. **State** — after user interaction, internal state still consistent?
5. **Impact on other ACs** — did this change affect code other ACs depend on? (review the impact analysis from Phase 3.5)
6. **Framework-specific** — consult `references/framework-review-checklist.md` for your tech stack (Qt/C++ signal/slot lifecycle, React stale closures, Django migration safety, Go error handling, etc.)

**Mode A (batch):** When all items are implemented, dispatch ONE review subagent for the entire batch. The subagent receives: all AC descriptions, all changed files, and this 6-item checklist plus any relevant framework knowledge. The subagent's value is independence — it reviews without the implementer's context bias, catching mistakes the author missed.

**Recommended, not a hard gate:** The subagent review is the preferred path. But if the project is MANUAL-heavy (GUI app, no programmable verification), or the subagent can't be dispatched, self-review against the 6-item checklist is an acceptable substitute. PASS → report, proceed to Phase 5 for marking. FAIL → fix.

**Mode B (lightweight):** Self-review inline against the 6-item checklist above.

PASS → output one line per checklist item (e.g., "1. Wiring: OK. 2. Safety: OK..."). FAIL → file:line + severity (CRITICAL/HIGH/MEDIUM/LOW) + fix.

**Framework-specific (both modes):** Apply relevant section from `references/framework-review-checklist.md`. If `references/framework-review-checklist.md` does not exist, skip item 6 and note "No framework checklist available".

---

## Phase 5: Verify and Mark

Two separate paths based on implementation mode:

**Path A — Mode A items** (classified in Phase 3 as AUTO/MANUAL/BLOCKED):

| Classification | Action |
|----------------|--------|
| **AUTO** | Run verification command from AC table. Present the verification output: command run, expected result, actual result. Only then mark `[x]`. Mismatch → mark `[ ]`, return to Phase 4. |
| **MANUAL** | Mark `[!]`. Note: `⚠️ Needs user verification: [what to test]` |
| **BLOCKED** | Mark `[!]`. Note: `🚫 BLOCKED: [reason]` |

**Path B — Mode B items** (skip Phase 1-3, no AUTO/MANUAL/BLOCKED classification):
- Verify they are marked `[!]` (should have been set in Phase 4.8 step 4).
- If any Mode B item is still `[ ]`, it was missed — mark it `[!]` now with a note: "Implemented but review marking was missed." Then proceed.
- All Mode B items require user verification — no AUTO marking allowed.

**Presentation:** Combine all `[!]` items from both paths into one checklist. Present to the user with specific verification instructions. After user confirms each item works → mark `[x]`.

**🚨 User confirmation is event-driven, not phase-locked.** The user may test and report back at any time — minutes or hours after you presented the `[!]` list. When the user says "test passed" / "works" / "looks good" — **immediately update the corresponding AC from `[!]` to `[x]`**. The moment the user confirms = the moment you update. This applies regardless of what phase you think you're in.

**Iron rule:** Only mark `[x]` after FRESH verification in this turn. "Passed before" doesn't count. Applies to both modes.

After marking all items, proceed to Phase 6 to check completion.

---

## Phase 6: Complete (HARD GATE)

**Agent work done when:** No `[ ]` remains. **Project complete (docs ready) when:** Every AC is `[x]`, `[>]`, or `[-]` — no `[ ]`, `[!]`, or `[~]`.

```
Phase 5 →
  ├── Any [ ] remaining? → Phase 4 (MANDATORY)
  └── No [ ] remaining? → [!] checklist → user test → [x]
                     → [~] items → settle: [x] / [>] / [-]
                     → All [x] [>] [-]? → project doc
```

**🚨 Exit condition: zero `[ ]` items.** Before saying "done": re-read AC, count `[ ]`. If any remain, check their notes:

- **Demotion note** (`⚠️ Affected by [AC-ID] change`) → this item was previously `[x]`/`[!]` and just needs re-verification. Re-verify now; restore to `[x]` if passing, or escalate if not.
- **No demotion note** → genuinely unimplemented. Process them: 1-2 items → Phase 4 Mode B; 3+ items → Phase 4 Mode A.

If zero `[!]` items exist, skip this step and proceed directly to `[~]` settling or project document.

**`[!]` → `[x]` loop:** When `[!]` items exist, present them as a user checklist with specific instructions. Wait for the user to test and confirm each one. After each confirmation → immediately mark `[x]`. Repeat until zero `[!]` remain.

**`[~]` → settle:** When `[~]` items exist, ask the user: fix remaining issues → `[x]`, or defer → `[>]`, or deprecate → `[-]`. Every item needs a settled outcome.

**Project document:** When every AC is `[x]`, `[>]`, or `[-]` — no `[ ]`, `[!]`, or `[~]` — create a project document at `$DOC_HUB/<ProjectName>/<ProjectName>.md`. Each item must have a settled outcome: verified done, explicitly deferred, or explicitly deprecated. Follow the project doc template structure: one-line overview, tech stack, architecture, core modules, edge cases, reusable patterns, technical debt, and overall assessment. This document is read by `project-experience` in future projects — without it, the experience loop is broken.

**Experience cache update:** After the project document is created, ask the user:

> "Project complete. Update the experience cache? Recommended — this writes today's pitfalls and reusable patterns into cache so future projects get a ~15s fast path instead of a full scan."

- **Yes** → delete `$DOC_HUB/_exp_memory.md` (so project-experience sees no cache and runs full extraction), then `Skill("project-experience")`. It will detect the missing cache, run Phase 1–5 across all projects (including the newly completed one), and save the updated cache. Tell the user: "Next project loads experience in ~15 seconds."
- **No** → completion is done. Remind the user they can update the cache later by saying "update experience cache".

---

## Quick Reference

| Phase | Action | Key |
|-------|--------|-----|
| 🚨 | **FIRST RULE** | ALL code changes → Phase 3.5 first. Phase 3.5 is the only path to Phase 4. |
| 0 | Locate doc hub + AC | Search ~/_exp_memory.md → $DOC_HUB. New project → Gate 1 (brainstorm) → Gate 2 (AC) |
| 1 | Triage statuses | `[ ]` `[~]` `[x]` `[-]` `[!]` `[>]` |
| 2 | Sort by dependency | Features→Compat→Perf→Quality. No labels? Infer from content |
| 3 | Classify verifiability | AUTO ✅ / MANUAL ⚠️ / BLOCKED 🚫 |
| 3.5 | Single entry point | Impact analysis + demote ACs. New feature → update+discuss. Bug fix → fast lane → Phase 4 |
| 4 | Implement | Mode A: batch all [ ] / Mode B: lightweight (user-requested change) |
| 4.8 | Review | Mode A: subagent / Mode B: self. 6-item checklist (Wiring + Safety + Fidelity + State + Impact + Framework) |
| 5 | Verify + mark | Path A: AUTO→cmd→`[x]`, MANUAL/BLOCKED→`[!]`. Path B: all Mode B items→user confirms→`[x]` |
| 6 | Complete | [ ] with demotion note? → re-verify. Genuine [ ] → Phase 4. Project doc when all `[x]` `[>]` `[-]` |

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
Phase 6: present [!] checklist → user tests → mark [x] → project doc → done
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
Phase 5: user verifies → mark [x] (event-driven, anytime user says "passed")
Phase 6: check if more [ ]/[!] remain; if all settled → project doc → done
```

---

## Red Flags — STOP

| Flag | Action |
|------|--------|
| About to write code not in AC table | Update AC first (Phase 3.5) |
| About to say "done" while any `[ ]` exists | Check notes: demotion → re-verify; genuine → Phase 4 |
| Demoted ACs (⚠️ Affected by...change) still `[ ]` after Mode B | Mode B step 3: restore them. Re-verify, mark [x] if passing |
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
