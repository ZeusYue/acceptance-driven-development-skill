# ADD Guardrails, Examples, and Extended Reference

> This file elaborates the operational rules in `../SKILL.md`. The main SKILL is authoritative when wording differs.

## Common Rationalizations

| Rationalization | Operational response |
|---|---|
| “It is only one line.” | Every code change still enters Phase 3.5; Phase 3.5A backlog work must use Mode A, while Phase 3.5B uses the mode selected by impact scope. |
| “I am debugging, not coding.” | A fix is a code change. Trace cause, then use the appropriate mode. |
| “The fix is obvious.” | Obvious fixes still need impact analysis and review. |
| “The user described it exactly.” | Description is not confirmation of the proposed behavioral approach. |
| “I will update AC later.” | Present proposed scope before approval, persist the approved AC delta before code, and update `[!]` to `[x]` immediately after specific user confirmation. |
| “Self-review is enough for a batch.” | Independent review is preferred; if unavailable, report all six self-review checks. |

## Compact Phase Map

| Phase | Observable result |
|---|---|
| 0 | `$DOC_HUB`, AC, and living project document located or created. |
| Gate 1 / 2 | Approved design then approved AC for greenfield work. |
| 1–3 | Status triage, dependency order, verification class. |
| 3.5A | Approved backlog impact analysis, then Mode A. |
| 3.5B | Change impact analysis, approval or fast lane, then Mode A/B. |
| 4 / 4.8 | Implementation and six-point review. |
| 5 | Fresh evidence and annotation-aware status update. |
| 6 | All AC outcomes settled, project document finalized, optional cache refresh. |

## Worked Examples

### Greenfield

```text
User: “Build a photo browser with ADD.”
Phase 0 → no AC
Gate 1 → design and user readiness
Gate 2 → AC draft and approval
Phase 1–3 → triage
Phase 3.5A → backlog impact analysis
Mode A → implement and review
Phase 5 → AUTO [x], MANUAL/BLOCKED [!]
Phase 6 → settle verification, finalize project doc
```

### Quality ACs

```text
User: “Add tests for this project.”
Phase 0 → AC-40..43 pending
Phase 1–3 → classify AUTO
Phase 3.5A → target list
Mode A → add tests, review batch
Phase 5 → run test command, mark [x] only on fresh pass
```

### Mid-development change

```text
User: “Tags cannot be deleted from images.”
Phase 3.5B → add next numeric AC and propose approach
User: “approved”
Mode B → implement, six-point self-review, mark [!] [manual]
User confirms test → mark [x]
```

## Extended Red Flags

| Signal | Required response |
|---|---|
| A code change has no relevant AC | Enter Phase 3.5B, propose a tracking AC, obtain the required confirmation, then persist it before code. |
| A user test is requested between AUTO items | Finish the batch and execute AUTO verification first. |
| An affected AUTO AC remains `[!] [affected]` | Re-run its verification command. |
| A MANUAL result fails | Record evidence, mark `[~]`, and repair approved scope through Phase 3.5A; changed scope returns to Phase 3.5B. |
| An approved behavior delta edits a target still marked `[x]` | Invalidate the stale pass: mark the edited target `[~]` before code; reserve `[!] [affected]` for unchanged contracts needing regression verification. |
| The user resumes a deferred `[>]` AC | For unchanged scope, record the decision, reactivate it as `[ ]` or `[~]`, and enter Phase 3.5A. For changed scope, keep `[>]` until Phase 3.5B approval, then atomically apply the edit and reactivate it before mode selection. |
| One Mode A AC is blocked | Record its block and continue independent pending/partial targets unless a shared prerequisite blocks the batch. |
| A feature fails three times | Stop patching; ask to redesign, continue with guidance, or defer. |
| Greenfield AC was written without approval | Delete/revise the draft and return to the proper gate. |
| Unrelated code was changed | Revert it or explicitly obtain a new AC scope. |

## Capability Map

```text
acceptance-driven-development
├── built-in design reference  conditional exploration and Design Decision Handoff
├── external planning tool   optional decomposition under Acceptance Mapping
├── review subagent          optional independent batch review
└── project-experience       optional prior-project briefing/cache
```

Missing optional capability means use the fallback described in the main SKILL; never block the core acceptance workflow.

The design reference is part of ADD rather than an optional host capability; load it only at the entries named in the main SKILL.
