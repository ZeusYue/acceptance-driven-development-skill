---
name: project-experience
description: Use when the user explicitly asks to compare or reuse lessons across projects, inspect another project's documented history, or refresh/rebuild the shared _exp_memory.md cache. Also use when ADD requests an approved global-cache refresh after project finalization. Do not use for ordinary coding, small changes, or routine ADD Mode A/Mode B execution.
---

# Project Experience

Research evidence-backed lessons across the shared project-document library and maintain its compact global cache.

**Boundary:** ADD reads `_exp_memory.md` once per new Agent/session and owns each `_<ProjectName>_exp.md` project capsule. This skill performs explicit cross-project research or an approved global-cache refresh; it does not author project documents, project capsules, AC state, or implementation plans.

## Use and skip

Use this skill when the user explicitly asks to:

- compare prior projects or find reusable cross-project lessons;
- investigate whether a past project solved a similar problem;
- refresh, rebuild, or audit `_exp_memory.md`;
- complete an ADD-approved global-cache refresh.

Skip it for ordinary implementation, architecture work inside one known project, Mode A/Mode B execution, small fixes, documentation edits, or a request already covered by the project's capsule. ADD remains functional when this skill is absent.

## Phase 0: Locate the shared document hub

All project documents and the global experience cache live under one shared document hub (`$DOC_HUB`), which may be an Obsidian vault or plain directory. Use canonical absolute paths with shell/filesystem tools; when a host accepts only workspace-relative vault paths, use that supported form without changing Hub identity.

1. Read `~/.add-hub`. A trimmed path naming an existing directory is authoritative.
2. If the pointer is missing or stale, search for `**/_exp_memory.md` under the user's home directory. Validate candidate parents by checking for hub templates and `<ProjectName>/AC.md` or `<ProjectName>/<ProjectName>.md` files.
3. If one candidate validates, use it and write `~/.add-hub`. If none or multiple remain, ask the user to choose a stable shared directory.
4. For a new hub, create the directory, create an empty `_exp_memory.md`, and write the pointer.

Cache presence helps fallback discovery but never overrides a valid pointer or proves Hub identity by itself.

## Phase 1: Choose the operation

### Explicit research

Read `$DOC_HUB/_exp_memory.md` once. A valid Schema 2 cache goes directly to matching. A missing or invalid cache may be rebuilt from project documents only when the user's request authorizes that work. Otherwise use a bounded, read-only fallback: inspect at most two directly matched project documents, report that cache-backed matching was unavailable, and do not write or block the research.

**Legacy cache fallback:** A cache without Schema 2 frontmatter remains readable when it has non-empty `Known Pitfalls` and `Reusable Patterns` sections. Match it by keywords, report that provenance metadata is unavailable, and do not rewrite it without an explicit refresh request.

Match structured tags against the requested technology, domain, and capability before free-text keywords. Return only the strongest matches in a bounded briefing:

```markdown
## Project Experience Briefing

### Relevant Pitfalls
- **pitfall** `[tags]` - strategy (Sources: ProjectA [completed])

### Relevant Patterns
- **pattern** `[tags]` - application (Sources: ProjectB [active])

### Coding Conventions
- convention `[tags]` - source
```

Include at most two pitfalls, two patterns, and two conventions. When no cache entry matches, say so; read the source project document only when a direct project match is available and the question requires more detail.

### Approved cache refresh

Keep `$DOC_HUB` fixed and preserve the old cache until replacement validates.

1. List `$DOC_HUB/*/*.md` and retain only files matching `<DirName>/<DirName>.md`.
2. Read frontmatter for every project document: project, tags, status, date, and modification time.
3. Match relevant projects by technology, domain, architecture, and reusable pattern.
4. Read at most two project documents fully. For others, target Tech Stack, Key Dependencies, Reusable Patterns, Technical Debt/Risks, Edge Cases, and Testing.
5. Read a matching `_<ProjectName>_exp.md` only for project-earned entries whose cited source plan exists, is `completed`, and has no `superseded-by-*` pause reason; exclude `_exp_memory.md` seeds so the cache cannot ingest itself.
6. Distill only evidence-backed pitfalls, patterns, and non-default conventions.
7. Render, validate, and atomically replace the global cache.

## Development-project evidence gate

A document with `status: 开发中`, `维护中`, `active`, or `maintained` may contribute only facts evidenced by code, configuration, tests, or a resolved incident. Planned features, guessed architecture, and unverified ideas never become global pitfalls or patterns. Record source status so readers can distinguish active from settled (`已完成`, `归档`, `completed`, or `archived`) projects.

## Global cache contract

Write Schema 2 frontmatter and keep the complete file under about 55 lines:

```markdown
---
cache_schema: 2
generated_at: YYYY-MM-DD
source_projects:
  - name: ProjectA
    status: completed
    document_mtime: YYYY-MM-DD
---

# Project Experience Cache

## Known Pitfalls
- **description** `[tags]`: symptom -> root cause -> fix (Sources: ProjectA [completed])

## Reusable Patterns
- **name** `[tags]`: problem -> mechanism (Sources: ProjectA [completed])

## Coding Conventions
- convention `[tags]` (Sources: ProjectA [completed])
```

Content rules:

- **Known Pitfalls:** actual difficult failures with symptom, root cause, fix, tags, and source status.
- **Reusable Patterns:** observed in at least two projects, or directly evidenced and broadly reusable across projects using the same stack.
- **Coding Conventions:** stable preferences that differ from common defaults.
- Merge entries only when root cause and solution principle match.
- Prefer pitfalls over patterns and patterns over conventions when enforcing the line cap.

## Atomic refresh

Write the complete candidate to `$DOC_HUB/_exp_memory.md.tmp`. Validate frontmatter, required headings, source metadata, and the line cap, then replace `_exp_memory.md` in one operation. On any failure, retain the old cache and report the problem. Never delete the old cache to request a refresh.

## Output

For research, return the bounded briefing and cite source projects. For refresh, report the cache path, source-project count, retained entry counts, and validation result. Do not dump complete project documents or repeat the full cache in chat.
