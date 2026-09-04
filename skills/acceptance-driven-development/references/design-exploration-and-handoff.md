# ADD Design Exploration and Handoff

> Read this reference only for explicit ADD design exploration, Greenfield Gate 1, or a Large / genuinely ambiguous Phase 3.5B behavior change. The main `SKILL.md` remains authoritative for workflow state and AC ownership.

## Boundary

- ADD owns workflow gates, `AC.md`, AC IDs and status, implementation mode, review, verification, and completion.
- Design exploration owns requirement clarification, meaningful alternatives, trade-offs, and the approved Design Decision Handoff.
- Use the active document hub and selected design-document path. Do not impose a repository layout.
- Do not create an implementation plan, edit code, select Mode A/B, or perform repository integration during exploration.
- Incremental confirmations are review checkpoints, not permission to persist `AC.md` or implement. After all checkpoints, one final approval covers the consolidated design; in Phase 3.5B it also covers the reviewed AC delta.

An explicit user request for ADD design exploration always loads this reference. Otherwise skip it for approved `[ ]` / `[~]` backlog, settled Small or Medium changes, original-behavior bug fixes, equivalent refactors, build/config changes, and pure cosmetics.

## Process

### 1. Establish context

Use the project capsule already read for this work unit, plus relevant project evidence: current `AC.md`, existing design decisions, code structure, and the project document only when needed. Do not re-read `_exp_memory.md` or invoke `project-experience` unless the user explicitly requests cross-project research. State the ADD entry context and separate known facts from unresolved decisions.

Do not ask for information that project evidence can establish.

### 2. Clarify material unknowns

Ask one question at a time. Ask only questions whose answers change scope, behavior, architecture, risk, or acceptance. Prefer concise options when trade-offs are clear.

Maintain an internal list of unresolved material decisions and ask the highest-impact one next. Project evidence may answer factual questions, but it must not be used to invent user preferences. Do not present a complete design or any proposed AC row while a material decision remains unanswered.

Stop when remaining details can safely be handled during implementation or expressed as AC verification details. One message may contain brief context plus one question; do not hide multiple decisions in a checklist or ask for blanket approval.

### 3. Explore the solution ladder

Stop at the first adequate level:

1. existing project code or patterns;
2. standard-library capability;
3. platform-native capability;
4. already-installed dependency;
5. new dependency or custom implementation.

Present two or three materially different approaches when a real choice exists. Ask the user to select or revise an approach before detailed design. If only one approach is credible, present it directly, explain why alternatives are not meaningful, and ask the user to confirm it before continuing.

### 4. Validate the design incrementally

Break the design into the smallest independently reviewable sections. Cover only relevant sections:

- goal and user-visible behavior;
- in-scope and out-of-scope boundaries;
- components, data flow, and state transitions;
- failure handling and recovery;
- compatibility, performance, security, or migration constraints;
- verification implications.

Give each section a stable decision label such as `D-1`, `D-2`, and preserve those labels in the final ledger.
Present one section per turn, scaled from a few sentences to at most 200-300 words when nuanced, then ask whether that section is correct or needs a specific change.
Do not continue to the next section until the user confirms or revises the current one. If a revision invalidates an earlier section, return to that section explicitly.

Lead with concrete behavior and trade-offs. Avoid unrelated refactoring and speculative future features. Do not compress independent UI, state, failure, and verification decisions into one approval checklist merely to reduce turns.

### 5. Review the proposed AC delta incrementally

Begin AC review only after every design section is confirmed.

- **Gate 1:** do not draft AC here. Gate 2 separately reviews and approves the actual AC draft.
- **Phase 3.5B:** present one proposed AC addition or edit per turn by default. Include its candidate ID, criterion, verification class and method, expected result, and affected existing ACs. Ask the user to confirm, edit, split, merge, or defer that row before presenting the next one.
- **Explicit exploration:** review AC implications only when the caller requested them; otherwise return them as non-authoritative implications.

Batch multiple design sections or AC rows only when the user explicitly requests batch review. Even in batch mode, preserve every `D-N` label and candidate AC ID so the user can revise one item independently. Nothing in this step changes authoritative `AC.md`.

### 6. Obtain final approval

- **Gate 1:** after incremental design validation, present a compact decision ledger and ask once for final design approval. Gate 2 separately owns the AC draft and approval.
- **Phase 3.5B:** after every design section and proposed AC row is individually confirmed, present the compact decision ledger plus the complete proposed AC delta and ask for one final combined approval to persist scope and enter implementation.
- **Explicit exploration:** ask once for final design approval, then return to the caller's requested ADD entry.

If the user requests changes, revise and ask again. If the user rejects or cancels, record rejection and stop.

### 7. Produce the Design Decision Handoff

After approval, output:

```text
Design Decision Handoff
Status: approved
ADD entry: Gate 1 | Phase 3.5B | explicit exploration
Goal:
In scope:
Out of scope:
Chosen approach:
Key decisions:
Rejected alternatives and reasons:
Affected existing AC candidates:
Approved AC delta: none at Gate 1 | <additions/edits for Phase 3.5B>
Verification implications:
Open questions: none | <items>
Continue in ADD: Gate 2 AC drafting | Phase 3.5B implementation entry | caller
```

Use existing AC IDs only when they exist. After approval, ADD must apply the approved AC delta and affected markers to authoritative `AC.md` before mode selection or code. Persist the approved design when the main workflow requests it.

## Quality check

Before continuing in ADD, confirm:

1. every material unknown was asked one at a time and resolved;
2. every relevant design section was individually confirmed;
3. every proposed Phase 3.5B AC row was individually confirmed unless the user explicitly requested batch review;
4. no unresolved placeholder is presented as a decision;
5. scope and chosen approach do not contradict each other;
6. rejected alternatives have concrete reasons;
7. AC changes describe behavior and verification, not implementation-task status;
8. the next ADD entry is explicit;
9. no code, plan status, implementation mode, authoritative AC content, or AC status changed before final approval.
