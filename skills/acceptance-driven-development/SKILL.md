---
name: acceptance-driven-development
description: Use when creating or changing a software project, or when the user explicitly requests ADD, acceptance criteria, or verifiable done conditions.
---

# Acceptance-Driven Development

Drive the current authorized work to observable, verified outcomes. Match planning, review, and record keeping to the work. Implementation progress is not acceptance evidence.

## Scope and authorization

Apply automatically to project development, including fixes and configuration changes. For discussion, audits, or design requests, provide that requested deliverable; mentioning ADD does not authorize implementation. Explanations and delivery-only operations do not start a development workflow.

A clear request authorizes its stated outcome and necessary ordinary implementation choices. Derive acceptance criteria from that request without asking the user to approve the transcription. Ask when missing information changes a material product decision, expands scope, or authorizes consequences not already covered. Explain the concrete decision and recommendation; continue independent authorized work while it is pending. Honor the user's chosen discussion style and existing authorization across turns.

## Establish the current target

Use the request, relevant project instructions, existing acceptance records, and actual code to identify:

- the outcome and observable passing conditions;
- the constraints and existing behavior this change must preserve;
- the checks that can demonstrate those conditions.

Read the relevant context before editing, including current changes and any applicable handoff. Resolve conflicting requirements without presenting inferred preferences as agreed scope. A request to fix one issue does not authorize the rest of the backlog.

For new and resumed work, locate the acceptance source through the request, project instructions, and handoff paths, URLs, issue references, or criterion IDs. When needed, search bounded project locations for acceptance/specification files, skipping dependencies and generated output. Reuse a record only when its authority and scope are clear. A location already declared by the user or project instructions remains valid; do not ask again merely because the file has not been created. If neither an authoritative record nor a declared location can be found, ask the user to specify the acceptance path or URL before creating a durable record. Never silently create one or declare a default canonical location. Resolve conflicting candidates before writing to them; independent work and conversational drafts can continue.

The acceptance source may be an issue, specification, tests with documented expectations, or `AC.md`. Preserve established identifiers and useful evidence. Before adding a record or criterion, check for an equivalent requirement; extend that record instead of duplicating it. A small task can keep its criteria in the conversation. No particular directory, template, memory service, or other skill is required. Read [acceptance and evidence](references/acceptance-and-evidence.md) when creating or updating a durable record or handling acceptance feedback.

## Choose enough structure

| Work characteristics | Useful support |
|---|---|
| Clear, local, easy to verify | Implement with focused verification and review; a brief explanation is enough. |
| Several dependent steps or likely to span sessions | Keep a concise plan mapped to outcomes and an up-to-date handoff. |
| Material design uncertainty or broad consequences | Resolve important trade-offs, assess failure and recovery, and strengthen verification and independent review. |

Use judgment about dependencies, uncertainty, reversibility, and impact. AC count and file count do not determine the workflow. Security, concurrency, data migration, and public contracts warrant particular care even for a small diff. Read [design decisions](references/design-decisions.md) when meaningful alternatives or unclear scope need discussion; read [planning and recovery](references/planning-and-recovery.md) for multi-session work, delegation, interruption, cancellation, or rollback.

## Implement, verify, reconcile

1. Identify relevant behavior and dependencies; determine what the change could invalidate. Inspect only as widely as needed to understand the impact.
2. Implement the authorized outcome. Adapt technical steps as evidence develops. Update a plan when it helps execution; a derived plan needs no separate approval.
3. Run checks that demonstrate the acceptance conditions and affected behavior. Use existing checks where sufficient; add meaningful regression coverage when it protects behavior. Formatting-only edits may need only an appropriate formatter or diff check.
4. Review the actual change for fidelity to the request, failure cases, state consistency, and effects on dependencies. Use independent review when available and valuable for the risk. Verify integrated delegated work before accepting it.
5. Record the result against the current target. Fix defects and regressions introduced by this work within its authorized scope, then repeat the affected checks. Continue ready work until the target is complete or a real dependency prevents further progress.

Repeated failure calls for a better diagnosis: review assumptions, reduce the reproduction, change the experiment, or seek independent analysis. Continue when new evidence supports a reasonable next step. Pause the affected work when further attempts cannot make useful progress without missing input, unavailable capabilities, additional authorization, or resources beyond the available budget; state the concrete condition. There is no fixed retry allowance.

## Evidence and delivery

Choose verification by what the available tools can actually observe. UI behavior can be verified through interaction tools; user preference or an inaccessible user environment may require a human. Complete the checks you can perform before handing off the remainder with prerequisites, actions, and expected results.

A successful build proves a build, not every requested behavior. Report pass only with evidence covering the claimed outcome. Include the check, relevant tested state or environment, actual result, and any limitation. A valid result can satisfy several checks and survive a conversation turn; rerun when relevant code, configuration, dependencies, environment, or assumptions change. Historical success cannot establish a changed outcome.

Keep acceptance status separate from task progress and commits. Distinguish verified, incomplete, awaiting human judgment, and blocked results. Deferral or removal of an agreed requirement needs a user decision; it is not a way to clear unfinished work.

Finish all independent work within the current target before handing off a real dependency. Report what changed, supporting verification, and any unresolved outcome with its next action. Completing this request does not complete the project's backlog or change its lifecycle status. Follow the user's and repository's Git and delivery conventions; this skill does not require commits or grant permission to publish.
