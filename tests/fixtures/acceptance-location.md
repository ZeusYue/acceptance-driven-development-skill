# Acceptance location checks

These are three small, isolated documentation tasks. Use a fresh directory and
fresh agent context for each. Load the candidate ADD skill and give only that
case's starting files and user request. Do not show the acting agent the evaluator
expectations. No implementation, network service, or Git commit is required.

## Missing location

Starting file `README.md`:

```markdown
# CSV validator

A new command-line project. Implementation and acceptance records have not yet been created.
```

Request: "Set up the durable acceptance record for this new command-line CSV
validator. It must accept valid UTF-8 CSV, reject inputs missing the name or email
header, and return exit code 1 for invalid input. Do not implement the program yet."

## Declared location

Use the same starting README. Request: "Set up the durable acceptance record for
this new command-line CSV validator at docs/acceptance.md. It must accept valid
UTF-8 CSV, reject inputs missing the name or email header, and return exit code 1
for invalid input. Do not implement the program yet."

## Existing source

Starting `README.md` identifies `docs/requirements.md` as the authoritative
acceptance record. That file contains:

```markdown
# CSV validator acceptance

| ID | Condition | Status | Evidence |
|---|---|---|---|
| CSV-1 | Accept valid UTF-8 CSV. | Pending | Implementation not started. |
| CSV-2 | Require the name header. | Pending | Implementation not started. |
| CSV-3 | Exit with code 1 for invalid input. | Pending | Implementation not started. |
```

Request: "Update this project's acceptance conditions: input CSV must contain both
name and email headers. Preserve the other agreed requirements. Do not implement
the program yet."

## Evaluator expectations

- Missing: asks for the user's path/URL, creates no acceptance file, and does not
  declare a default location. A conversational draft is acceptable.
- Declared: creates `docs/acceptance.md` covering the three requirements without
  another location question; no duplicate AC or implementation.
- Existing: follows the README reference, updates CSV-2 in place, preserves the
  other IDs/requirements and pending state; no competing acceptance file.

Inspect actual files and the response. Do not score fixed phrases. The observed
follow-up run and its limits are in the [validation report](../../docs/validation-report.md).
