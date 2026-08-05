# ADD Design Exploration and Handoff

> Read this reference only for explicit ADD design exploration, Greenfield Gate 1, or a Large / genuinely ambiguous Phase 3.5B behavior change. The main `SKILL.md` remains authoritative for workflow state and AC ownership.

## Boundary

- ADD owns workflow gates, `AC.md`, AC IDs and status, implementation mode, review, verification, and completion.
- Design exploration owns requirement clarification, meaningful alternatives, trade-offs, and the approved Design Decision Handoff.
- Use the active document hub and selected design-document path. Do not impose a repository layout.
- Do not create an implementation plan, edit code, select Mode A/B, or perform repository integration during exploration.
- One approval covers the complete design. In Phase 3.5B, present the proposed AC delta with that design so the same approval also confirms behavior scope.

An explicit user request for ADD design exploration always loads this reference. Otherwise skip it for approved `[ ]` / `[~]` backlog, settled Small or Medium changes, original-behavior bug fixes, equivalent refactors, build/config changes, and pure cosmetics.

## Process

### 1. Establish context

Read the relevant project document, current `AC.md` when present, existing design decisions, code structure, and directly relevant experience cache. State the ADD entry context and separate known facts from unresolved decisions.

Do not ask for information that project evidence can establish.

### 2. Clarify material unknowns

Ask one question at a time. Ask only questions whose answers change scope, behavior, architecture, risk, or acceptance. Prefer concise options when trade-offs are clear.

Stop when remaining details can safely be handled during implementation or expressed as AC verification details.

### 3. Explore the solution ladder

Stop at the first adequate level:

1. existing project code or patterns;
2. standard-library capability;
3. platform-native capability;
4. already-installed dependency;
5. new dependency or custom implementation.

Present two or three materially different approaches when a real choice exists. If only one approach is credible, present it directly and explain why alternatives are not meaningful.

### 4. Present one coherent design

Scale the response to the change and cover only relevant sections:

- goal and user-visible behavior;
- in-scope and out-of-scope boundaries;
- components, data flow, and state transitions;
- failure handling and recovery;
- compatibility, performance, security, or migration constraints;
- verification implications and likely AC changes.

Lead with the recommendation and concrete trade-offs. Avoid unrelated refactoring and speculative future features.

### 5. Obtain one approval

- **Gate 1:** present the complete design and ask once for design approval. Gate 2 separately owns the actual AC draft and approval.
- **Phase 3.5B:** attach the proposed AC additions or edits to the design and ask for one combined approval covering design and scope. Do not add another approach or spec-review permission before implementation.
- **Explicit exploration:** ask once for design approval, then return to the caller's requested ADD entry.

If the user requests changes, revise and ask again. If the user rejects or cancels, record rejection and stop.

### 6. Produce the Design Decision Handoff

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

1. no unresolved placeholder is presented as a decision;
2. scope and chosen approach do not contradict each other;
3. rejected alternatives have concrete reasons;
4. AC changes describe behavior and verification, not implementation-task status;
5. the next ADD entry is explicit;
6. no code, plan status, implementation mode, or AC status changed during exploration.
