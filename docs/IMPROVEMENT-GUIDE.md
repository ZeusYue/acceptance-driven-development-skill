# Improving ADD

ADD should improve the user's actual result while leaving capable agents room to choose how to achieve it. Evaluate a proposed rule by the decisions it changes, the failures it prevents, and the burden it creates.

## Preserve the core

- Completion is grounded in observable acceptance criteria and evidence relevant to the current implementation.
- User intent, existing authorization, and scope decisions determine the work. Implementation choices can usually remain with the agent.
- Failed, blocked, unverified, and user-validated outcomes are represented honestly. A plan, commit, or passing build cannot substitute for acceptance.
- The agent repairs regressions it introduces and continues independent work when one part is blocked.
- Recovery reconciles records with the actual workspace, preserves user changes, and respects cancellation and deferral.

The runtime entry point is [SKILL.md](../skills/acceptance-driven-development/SKILL.md). Its linked references provide conditional detail; templates are optional starting points. This maintainer guide is not an additional runtime protocol.

## Keep the workflow proportional

Choose guidance that helps the model make a useful decision. Use concrete conditions such as uncertain behavior, broad dependencies, costly rollback, unavailable prerequisites, and long-lived work. Criterion counts and entry routes are poor proxies for complexity.

Before adding a requirement, identify the observed failure. Consider whether the remedy is a clearer outcome, a better tool, a targeted reference, a test, or removal of a conflicting instruction. Explain consequential constraints once, close to the decision they govern. Read supporting references only when relevant.

The current refactor intentionally removes mandatory document hubs, global-cache reads, numbered phase gates, Mode A/B protocols, fixed retry quotas, and automatic commit requirements. Any future proposal to introduce comparable machinery should demonstrate a benefit under representative tasks and account for its cost on simple work.

Public runtime instructions must be usable without the maintainer's filesystem, personal tools, or companion skills. Host permissions and repository policies still apply. A host-specific integration may describe verified capabilities, but it should not create a second copy of the ADD workflow.

## Evaluate behavior

Use a reproducible task or a realistic fixture to expose the problem before revising guidance. Compare the current skill, the proposed revision, and a no-ADD control under the same task and tool conditions. Give each run a fresh context. For behavior shaping, repeat samples to observe variability instead of treating one response as proof.

Choose scenarios relevant to the changed rule. Useful coverage includes:

| Scenario | What to observe |
|---|---|
| A localized repair with no AC file | Implements and verifies without unnecessary setup or repeated authorization. |
| A clear new feature | Uses the user's scope, handles ordinary design choices, and completes the feature. |
| An unresolved product choice | Asks a focused question about a material decision and continues independent work. |
| A shared-component regression | Covers affected behavior and repairs regressions introduced by the change. |
| Several failed diagnoses with new evidence | Revises the hypothesis and continues while a useful next step exists. |
| An unavailable dependency | Identifies the actual blocker, avoids unsupported claims, and completes independent work. |
| UI checks with browser tools available | Uses available evidence; distinguishes what still needs user judgment. |
| Cancellation followed by a new session | Reconciles workspace state and preserves the cancellation. |
| A mixed validation handoff | Maps user feedback to the checks actually handed off, preserving unresolved checks. |
| A maintenance request in a project with a large backlog | Completes the requested scope without absorbing unrelated backlog. |

Score concrete behavior: goal completion, regression handling, scope fidelity, evidence quality, recovery correctness, unnecessary questions, document churn, tool cost, and user effort. Read the outputs and inspect artifacts; keyword matches can mistake quoted instructions for compliant behavior.

Record the model, host, tool access, skill revision, scenario, expected result, observed result, and limitations. Distinguish an agent's written next-step choice from a task actually executed. Limited simulated scenarios can reveal a defect or support a wording change, but cannot establish broad performance gains or host compatibility.

## Validate the package

Run from the repository root with Python 3.10+:

```sh
python tests/validate_release.py
python -m unittest discover -s tests -p "test_*.py"
```

These checks cover package integrity and the validator's behavior. Keep the validator focused on concrete packaging contracts such as required files and resolvable local links. Avoid turning every sentence of the skill into a required string: that rewards preserving wording and makes substantive improvement harder.

When a change affects behavior, run the relevant agent scenarios as well. Report exactly what was exercised and what remains untested. A successful static check is not a behavioral result.

## Keep public materials consistent

Changes may affect the entry point, conditional references, optional assets, both READMEs, installer notes, and evaluation scenarios. Update the relevant surfaces together. Remove obsolete references from the package when they no longer have callers, while preserving users' project records and valid historical evidence.

The installable unit is the complete `skills/acceptance-driven-development/` directory. Keep release tooling and maintainer notes outside it. Document version-specific integration behavior only when it is known, and keep published release claims separate from work on an upcoming revision.

For migration from 2.x, preserve acceptance IDs, meaning, evidence, and scope decisions. Historical phase labels and attempt counters can remain as history; they do not impose the retired execution protocol. Do not require users to convert unrelated project documents to continue ordinary development.

Before publishing a release, review the final diff, run the relevant checks, and describe the resulting behavior and migration impact. Commit, push, tag, and publish according to the maintainer's release authorization and repository process.
