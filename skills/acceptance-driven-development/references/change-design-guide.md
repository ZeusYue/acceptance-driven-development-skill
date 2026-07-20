# ADD Change Design Guide

> This reference expands Phase 3.5B. The main `SKILL.md` retains the mandatory entry, impact analysis, approval, and fast-lane rules.

## Classify the change

| Size | Signals | Required path |
|---|---|---|
| Small | One existing file; local threshold/rename/line move | Update AC when behavior changes; propose approach in 1–2 sentences; explicit approval. |
| Medium | Multiple files, new file, new UI, interaction flow, or uncertainty | Check existing solution options; discuss approach; update AC; explicit approval. |
| Large | New subsystem, architectural restructuring, broad feature | Check solution options; use brainstorming when available; update design and AC; explicit approval. |

Default to Medium when uncertain. A fast-lane bug fix is the exception: it still needs impact analysis but no approach discussion when it restores original intent.

## Solution ladder

Before designing a Medium or Large solution, stop at the first rung that works:

1. Reuse code, helpers, utilities, or patterns already in the codebase.
2. Use the standard library.
3. Use a platform-native capability.
4. Use an already-installed dependency.
5. Only then design custom code or evaluate a new external dependency.

Present relevant findings with the approach. Read `$DOC_HUB/_exp_memory.md` when available and mention any directly relevant pitfall or reusable pattern.

## Approval boundary

Behavioral changes include buttons, UI state, displayed data, filters, validation, interaction flow, and user-perceptible performance changes. They require AC update, discussion, and explicit approval.

Fast-lane candidates preserve intended behavior: bug fixes, equivalent refactors, build/config changes, and pure cosmetics. If a fast-lane bug has no AC, create the next numeric AC and obtain quick confirmation that it is the correct tracking criterion.

## Failure boundary

After three failures for the same AC, stop implementation. Present evidence and ask whether to:

1. redesign through Phase 3.5B;
2. try once more with user guidance;
3. defer as `[>]`.

If a proposed change is deferred, remove only the `[affected]` annotations introduced by that change and restore original verified/pending status.
