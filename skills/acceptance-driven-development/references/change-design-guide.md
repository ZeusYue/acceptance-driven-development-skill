# ADD Change Design Guide

> This reference expands Phase 3.5B. The main `SKILL.md` retains the mandatory entry, impact analysis, approval, and fast-lane rules.

## Classify the change

| Size | Signals | Required path |
|---|---|---|
| Small | One existing file; local threshold/rename/line move | Update AC when behavior changes; propose approach in 1–2 sentences; explicit approval. |
| Medium | Multiple files, new file, new UI, interaction flow, or bounded uncertainty with no unresolved material design choice | Check existing solution options; present approach and proposed AC delta; explicit approval. |
| Large / ambiguous | New subsystem, architectural restructuring, broad feature, or unresolved alternatives that materially change behavior/architecture/risk | Read `design-exploration-and-handoff.md`; present design and proposed AC delta together; one combined approval. |

When only physical size is uncertain, default to Medium. Genuine design ambiguity takes the Large / ambiguous path regardless of file count. A fast-lane bug fix is the exception: it still needs impact analysis but no approach discussion when it restores original intent.

## Solution ladder

Before designing a Medium or Large solution, stop at the first rung that works:

1. Reuse code, helpers, utilities, or patterns already in the codebase.
2. Use the standard library.
3. Use a platform-native capability.
4. Use an already-installed dependency.
5. Only then design custom code or evaluate a new external dependency.

Present relevant findings with the approach. Read `$DOC_HUB/_exp_memory.md` when available and mention any directly relevant pitfall or reusable pattern.

## Approval boundary

Behavioral changes include buttons, UI state, displayed data, filters, validation, interaction flow, and user-perceptible performance changes. They require a proposed AC delta, discussion, and explicit approval before persistence.

Fast-lane candidates preserve intended behavior: bug fixes, equivalent refactors, build/config changes, and pure cosmetics. If fast-lane work has no relevant AC, propose the next numeric tracking AC and obtain quick confirmation before writing it.

## Failure boundary

In Mode A, count failed implementation → verification → review cycles per `PLAN-N`; in Mode B, count them per target AC. Expected `TEST-FIRST` red and `CHARACTERIZATION` observations do not count, and multiple failed checks in one cycle increment only once. After three consecutive failed cycles for that unit, stop its implementation, mark only mapped unsettled ACs that cannot proceed without it `[!] [blocked]`, continue independent work, present evidence, and ask whether to:

1. redesign through Phase 3.5B;
2. try once more with user guidance;
3. defer as `[>]`.

If a proposal is deferred before code, leave authoritative AC unchanged. If work is deferred after code attempts, first revert the attempted implementation and freshly verify affected ACs before restoring statuses; otherwise preserve their nonterminal/affected states. Never restore `[x]` from historical status alone.
