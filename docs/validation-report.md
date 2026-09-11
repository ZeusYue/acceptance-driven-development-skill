# Validation of the public workflow refactor

This report documents the pre-release evaluation of the public `v3.0.0` revision against commit `5148411` (v2.7.1). Validation took place on 2026-09-11 in Codex desktop on Windows with Python 3.13. Evaluating agents inherited the session's default model configuration; no model override was requested. Exact model/backend identification was not exposed by the evaluation calls.

The initial candidate used for the fifteen decision probes and six execution runs below had `SKILL.md` SHA-256 `fbc07add66c637eaef1ac83570ae406f96dddadd80df372c5b796186759fceb0`, with 878 entry-point words and 2,696 across its six installable files (whitespace-delimited). Later changes to acceptance discovery and location handling have separate validation below; the initial results do not certify those revisions. The original entry point contained 3,323 words. Size is a descriptive property, not a quality score.

The acceptance scope is to retain observable outcomes, truthful evidence, user scope and cancellation, and useful recovery while removing mandatory personal infrastructure and mechanical approvals, modes, and retry quotas. This is a change to the installable ADD package and its public documentation, not a migration of users' project records.

## Methods

The [decision probe](../tests/fixtures/decision-probe.md) supplies an authorized CSV-export task with a diagnosed sorting regression after three failed cycles, an existing acceptance record, unrelated backlog, and staged user edits. It is a written next-action exercise, not execution of code or a browser test.

Each condition uses five fresh subagent contexts: no ADD guidance, the original skill from the base commit, and the candidate skill. The scenario is identical. Original and candidate agents read their skill and relevant references. Controls receive no ADD guidance. Acting agents do not receive the scoring rubric or earlier responses. The parent reads every response for actual proposed actions. The complete responses remain in the development session; this report publishes excerpts and observations, not full transcripts.

Scoring examines whether the agent continues the authorized repair, checks the behavior and regression, keeps unrelated backlog outside scope, preserves user edits, and avoids unrequested publication or project finalization. Extra user decisions and workflow-only record changes are also noted. These small, repeated qualitative samples expose workflow effects; they do not establish general success rates, performance gains, or superiority over unguided agents.

Separate isolated fixtures exercise actual edits, tests, and acceptance records. Package validation checks file structure, metadata, and local links. Validator unit tests deliberately corrupt those structures to ensure failures are detected. Neither structural validation nor an agent's intended action certifies real project outcomes.

## Decision probe results

All fifteen responses were read individually. Each condition produced the same principal decision in all five samples.

| Condition | Continue the diagnosed repair without another user approval | Keep work scoped and preserve staged edits | Propose behavior/regression verification |
|---|---|---|---|
| No ADD guidance | 5 / 5 | 5 / 5 | 5 / 5 |
| Original v2.7.1 | 0 / 5 | 5 / 5 | 5 / 5, conditional on another approval |
| Candidate | 5 / 5 | 5 / 5 | 5 / 5 |

The original agents all marked the task blocked at the three-attempt boundary and requested a guided fourth attempt. One response asked, "May I use the identified array-copy repair for one guided fourth attempt?" All five also proposed recording `COMMIT-BLOCKED` because of the staged user edit, although no commit was requested. None proposed disturbing that edit.

A control response said, "The latest failure identifies a concrete repair, so I’ll continue despite the three unsuccessful cycles." A candidate response said, "The three failed cycles do not block another evidence-backed repair, and the preview deadline does not make failing sorting acceptable." Candidate responses retained the failing regression as current evidence until repaired and verified.

This probe supports removing the artificial retry gate and its associated state bookkeeping. It does not demonstrate that the candidate outperforms the no-ADD control, which also chose the desired action. Proposed browser checks in these responses were not executed.

## Execution and package results

Six additional fresh agents used the candidate on isolated repositories created by [prepare_scenario.py](../tests/prepare_scenario.py). They received the user prompt, prepared repository, and candidate skill, without the evaluation rubric or other runs. The parent inspected each final diff and acceptance record and independently reran the reported unit checks.

| Scenario and change artifact | Observed result |
|---|---|
| [Staged user edit](../tests/results/fixture-changes/staged-user-edit.patch) | Fixed the off-by-one error; 4 tests passed. The original staged binary diff's SHA-256 was identical before and after. The code fix remained unstaged and no commit was created. |
| [Resumed backlog](../tests/results/fixture-changes/resumed-backlog.patch) | Fixed count labels; 3 tests passed, including existing export behavior. AC-3 received current evidence; AC-2 remained backlog. |
| [Cancelled work](../tests/results/fixture-changes/cancelled-work.patch) | Fixed capitalization/whitespace handling; 2 tests passed. Analytics remained disabled. The cancelled work record and retained design had identical SHA-256 values before and after. |
| [Mixed verification](../tests/results/fixture-changes/mixed-verification.patch) | Completed both independent client changes; 6 tests passed. Staging remained blocked and actual screen-reader acceptance remained pending, each with concrete handoff steps. Generated markup tests were not presented as browser or screen-reader evidence. |
| [Stale configuration evidence](../tests/results/fixture-changes/stale-config-evidence.patch) | Preserved the user's configured default of 20 and the existing implementation. Updated the outdated test expectation, ran 4 passing tests, and refreshed acceptance evidence. Independent checks confirmed default 20 and explicit limits 5 and 25. |
| [Unresolved product boundary](../tests/results/fixture-changes/product-boundary.patch) | Implemented independent CSV serialization/file output; 11 tests passed, including round trips and actual file output. Columns must be explicitly supplied. The public field policy and final download integration remained pending a product decision, and the agent asked that specific question. |

All six runs met their scenario's observable expectations. For mixed verification and the product boundary, an honest partial handoff was the expected result; the full requested feature was not claimed complete. The separate `small-fix` and `productive-recovery` execution scenarios were not run by agents in this session. The decision probes covered the productive-retry decision, while staged-user-edit exercised the small-fix behavior with an additional constraint.

The patches contain only synthetic fixture changes. They are relative to each prepared starting worktree: the staged-user-edit patch excludes the already-staged wording, and the stale-config-evidence patch excludes the user's already-present config edit. No real project data or personal filesystem paths are included. These artifacts aid inspection; they are not a second implementation shipped inside the skill.

Final checks:

- `python tests/validate_release.py`: passed, covering required files, skill frontmatter, relative links/anchors, and installable-package boundaries.
- `python -m unittest discover -s tests -p 'test_*.py' -v`: 25 tests ran; 24 passed and 1 symlink test was skipped because the Windows account could not create symbolic links. These tests also confirm the eight fixture starting states and isolation from globally configured Git hooks.
- The skill-creator frontmatter validator passed with its PyYAML dependency installed only in a temporary validation directory. ADD and the repository's own validator do not require PyYAML.
- `git diff --check`: passed after normalizing two documentation files' mixed line endings.
- An independent static review of the skill, references, templates, READMEs, and maintainer guide reported no actionable contradictions.

## Limits

Execution scenarios used small Python fixtures and one candidate run each, not production applications or all three conditions. No real browser flow, staging service, screen reader, external issue tracker, multi-agent cancellation race, or host migration was exercised. The tools ran on Windows only; portable implementation is not proof of Linux/macOS or installer compatibility. Symlink handling has an unexecuted platform-dependent test here. The results support the specific changes observed and do not establish a broad reliability guarantee or model-performance comparison.

## Follow-up: acceptance location must be found or declared

On 2026-09-11 the maintainer chose to keep workspace/instruction/handoff discovery
without a global document hub. When no authoritative source or previously declared
location is found, the agent must ask the user for a path or URL instead of silently
creating a default AC. A prior user/project declaration remains effective even if
the file does not exist yet. An inaccessible source is unresolved, not absent.

This revision's `SKILL.md` SHA-256 is
`55145d806aa318e4b803427ccbd32f35e809bcdc985f66d46aaf8f9f67ea3c9d`.
It has 1,003 entry-point words and 3,179 across the six installable files.
The references, templates, and both READMEs follow the same location rule.

Three fresh agents acted on the isolated projects in
[acceptance-location.md](../tests/fixtures/acceptance-location.md), receiving only
their starting files, request, and candidate skill. Each case ran once. The parent
inspected the actual files and responses:

| Case | Observed outcome |
|---|---|
| No record or location declaration | Asked the user for a path/URL; only the original README remained. No default AC was created or declared. |
| User declared docs/acceptance.md, file absent | Created that file without a second location question. Criteria covered the requested behavior and remained unimplemented; no other files were added. |
| README pointed to docs/requirements.md | Updated CSV-2 in that record, preserving CSV-1, CSV-3, and pending status. No competing AC or implementation was created. |

Package/link validation and the Git whitespace check passed after these edits.
The earlier full refactor behavior results remain attached to their original
revision above. This follow-up does not rerun them or establish reliability for
ambiguous candidates, unreachable external sources, or concurrent record creation.
