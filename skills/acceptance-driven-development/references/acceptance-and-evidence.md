# Acceptance records and evidence

Use one authoritative acceptance record for a given scope. A plan describes how work proceeds; the acceptance record describes what must be true and what evidence supports it. Link between them instead of copying competing acceptance states. A new session should follow the current work record or handoff to the recorded path, URL, and criterion IDs, then confirm that the record matches the current repository and request. A useful record identity combines the project or repository identity, source path or URL, and covered scope; criterion IDs only need to be unique within that record.

## Create or change a record

Before creating a record, follow explicit paths/URLs and inspect project instructions, handoffs, acceptance/specification files, and issue references. Use the relevant project or subproject as the search boundary. A filename match alone does not establish authority. Reuse a clearly applicable record in its existing language and format; missing schema or incomplete content does not justify a parallel `AC.md`. If records overlap without clear authority, ask which one governs before writing.

A location explicitly declared in the user's request, prior authorization, or project instructions is sufficient for creating a needed record there, after checking for an existing equivalent. Do not request the same declaration again. If no authoritative record or declared location is found, ask the user to specify the path or URL. An inaccessible source remains unresolved, not absent. Do not silently create a file, select a default root `AC.md`, or invent another canonical location. A conversational draft and independent work can continue while the location is unresolved. Once established, record the source and save the locator in the work record or handoff.

The [acceptance template](../assets/ac-template.md) is an optional format, not permission to choose a location. A small task may keep its criteria in the conversation and need no file or new identifier.

Describe user-observable behavior or an engineering constraint, how it can be checked, and what counts as passing. One criterion can have several necessary checks. Scope the record to the actual request; an existing project without ADD documents does not need its entire requirements reconstructed before a fix.

A clear user request can establish a new or changed criterion. Record the request or agreed decision as its source. Before assigning an identifier, scan the selected record and nearby project records/issues for equivalent criteria and existing IDs; extend the existing criterion when it already covers the outcome, otherwise choose an unused identifier in that record's convention. Keep unresolved proposals distinct from accepted requirements. Preserve existing IDs and historical facts; repair harmless formatting without blocking work. Ask about a conflict when resolving it requires choosing between materially different requirements or discarding meaningful evidence. A new workflow does not require a wholesale migration of existing documents.

If an external authoritative record cannot be updated with the available access, keep a clearly labeled update in the conversation or existing work record, pointing to that source for reconciliation. Report the unsynchronized status. This does not authorize creating a replacement acceptance file or claiming the external record was changed.

## Status and evidence

Use the existing project's notation. For a new Markdown record, these markers are available:

| Mark | Meaning |
|---|---|
| `[ ]` | Not implemented. |
| `[~]` | Incomplete, failed, or being revised. |
| `[x]` | Supported by currently applicable passing evidence. |
| `[!]` | Awaiting a named check or blocked by a stated condition. |
| `[>]` | Explicitly deferred by the user. |
| `[-]` | Explicitly removed from the agreed scope. |

For `[!]`, identify whether a human decision, a regression check, or an external condition is pending. A test that cannot run is not a pass. An old pass becomes pending or incomplete when its criterion changes or a concrete implementation or verification dependency makes the evidence inapplicable. Explain that impact; a shared-file change alone does not invalidate unrelated criteria.

Keep reusable verification instructions separate from their latest result. A result identifies the check performed, actual outcome, relevant tested state and environment, and a stable evidence locator when available. Use code/build identity or a meaningful description of the tested working changes; a commit is not required. Keep long logs outside the acceptance record. Existing historical evidence may remain, but the current conclusion must be unambiguous. Update any maintained summaries with the result.

## Human feedback

Hand off only the part that requires human access or judgment. Include the criterion, prerequisites, concrete actions, expected observation, and what remains pending. Persist enough scope to recover a multi-session handoff.

Apply clear user feedback to its corresponding check promptly, including when the same message starts another task. A natural-language "all passed" can settle the latest unambiguous pending handoff; ask about scope if several handoffs are plausible. Record that it is user-reported evidence. Human confirmation of one portion does not stand in for missing checks on another portion. A failure returns the affected outcome to unfinished work; repair within the current authorization, or discuss the newly discovered requirement.
