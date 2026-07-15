---
name: project-experience
description: Use when writing code, designing architecture, choosing dependencies, or implementing features — especially when the task involves technology or domains (C++, Qt, astronomy, desktop apps, image processing, scientific computing) where the author has prior project experience documented in the vault. Also use when the user mentions starting a new project or asks you to follow their coding style.
---

# Project Experience

## Overview

Read the project documentation library — a collection of structured project docs (tech stack, architecture, reusable patterns, known pitfalls, coding conventions) stored in any folder (Obsidian vault or plain directory). Before writing any code, mine these documents for constraints and patterns that generic AI assistants would miss.

**Core principle:** Past projects encode years of hard-won engineering judgment. A 3-minute read of their docs saves hours of repeating their mistakes.

## When to Use

```
New task received ──► Is it code/architecture/dependency related?
                              │
                    ┌─────────┴──────────┐
                    │ YES                │ NO → skip
                    ▼
             Run Phase 0.1: locate doc hub
                    │
              ┌─────┴──────┐
              ▼            ▼
     _exp_memory.md?    _exp_memory.md?
         YES              NO
          │                │
          ▼                ▼
  Phase 0.2: read    Phase 0.3: find
  cache & validate   project docs
          │                │
    ┌─────┴──────┐         ▼
    ▼            ▼    Phase 1–5 full
  Valid        Empty        │
  cache?       → treat      ▼
    │          as NO   Phase 6: save
    ▼            │     cache
 Phase 2         │        │
 (match          │        │
  cache)         │        │
    │            │        │
    └────────────┼────────┘
                 ▼
         Phase 4–5: briefing + apply
```

**Specific triggers:**
- User asks you to write, design, or implement code
- User mentions "new project", "refactor", "choose library"
- Task involves: C++, Qt, FITS, astronomy, desktop GUI, image processing, scientific computing
- User says "follow my style" or "similar to my other projects"
- You're about to make an architectural decision
- You're about to pick a dependency or library

**Skip when:**
- Task is purely conversational (answering questions, explaining concepts)
- Task is about editing markdown files, notes, or documentation
- Code task is trivial (single-line fix, typo, formatting)

## Phase 0: Locate the Document Hub — REQUIRED before all other phases

All project documents and the experience cache live under a single directory (`$DOC_HUB`), independent of code directories. Use **absolute paths only**.

### Step 0.1: Discover $DOC_HUB (three-tier, most reliable first)

(Expand `~` to the user's home directory — `$HOME` on Unix, `%USERPROFILE%` on Windows. Do not look for a literal `~` folder.)

1. **Read the pointer file** `~/.add-hub` — a one-line file whose content is the absolute path to `$DOC_HUB`.
   - **Exists** → read the path, then verify the directory exists AND contains `_exp_memory.md`. If both hold → `$DOC_HUB` = that path (trimmed), go to Step 0.2 (direct read, reliable across all agents). If the path is missing or has no `_exp_memory.md` → the pointer is stale; ignore it and fall through to tier 2 (which will rewrite `~/.add-hub`).
   - **Not found** → try tier 2.
2. **Fallback search** `Glob pattern="**/_exp_memory.md" path="~"` — the cache anchor.
   - **Found** → `$DOC_HUB` = the directory containing `_exp_memory.md`. If multiple match: prefer the directory that also contains project subfolders with `AC.md` or holds `ac-template.md`/`project-index.md`; if still ambiguous, ask the user which to use before proceeding. **Write `~/.add-hub`** with the chosen path so future sessions skip the search (never write the pointer from an ambiguous, unconfirmed match). Go to Step 0.2.
   - **Not found** → tier 3.
3. **Ask the user once:** "I need a central directory to store acceptance criteria and project experience for ALL your projects. This directory will be shared across projects, so pick a stable location — don't put it inside a specific project folder. Suggested: ~/project-docs/ (just give me the path; I'll create the needed files there.)"
   → `$DOC_HUB` = user's answer. Then perform ALL THREE actions in order (none optional):
   1. Create the directory `$DOC_HUB` if it doesn't exist.
   2. Create `$DOC_HUB/_exp_memory.md` with content `# Project Experience Cache\n\n> No completed projects yet.`
   3. **Write `~/.add-hub`** — a one-line file whose entire content is the absolute `$DOC_HUB` path. This is what lets every future session find the hub by a single direct read. Skipping this step means the next session has to ask the user again.

### Step 0.2: Check experience cache

Check if `$DOC_HUB/_exp_memory.md` exists:

- **YES (with real content)** → read it. Skip Phase 1 and 3, go directly to Phase 2. **Content validation:** if the file contains only the placeholder (`> No completed projects yet.`), or has no `## Known Pitfalls` / `## Reusable Patterns` heading, or those sections are empty → treat as NO (full cycle).
- **NO** → proceed with full Phase 1–5. After Phase 5, save the cache (see Phase 6).

### Step 0.3: Find project documents

Project docs live at `$DOC_HUB/<ProjectName>/<ProjectName>.md`.

`Glob pattern="$DOC_HUB/*/*.md"` lists all projects. If the user mentioned a specific project name, target that one. Otherwise scan all.
Filter results: keep only files matching `<DirName>/<DirName>.md` (the file named after its containing directory). Ignore AC.md, design.md, or other supplementary files — those are read separately when needed.
Store `$DOC_HUB` for all subsequent paths.

## Phase 1: Survey

Read the project index (`$DOC_HUB/project-index.md`) if it exists.

If Step 0.3 already produced the filtered project list, reuse it — skip the glob below. Otherwise run a direct file listing:

```
Glob pattern="$DOC_HUB/*/*.md"
```

Filter to project docs only: keep files matching `<DirName>/<DirName>.md` (named after their containing directory). Ignore `AC.md`, `design.md`, `ac-template.md`, `project-doc-template.md`, `project-index.md`.

From the survey, extract:
- How many projects exist (each subdirectory under `$DOC_HUB` with a `<Dir>/<Dir>.md` = one project)
- Their tags (languages, frameworks, domains) — read frontmatter of each project document found
- Their status (maintained, completed, archived)

This takes under 15 seconds.

## Phase 2: Match — Find Relevant Projects

**If reading from cache (Step 0.2 = YES):** scan the `Known Pitfalls`, `Reusable Patterns`, and `Coding Conventions` sections of `$DOC_HUB/_exp_memory.md`. Match entries to the current task by keywords and context. Skip the project-tag matching below. After matching → go to Phase 4 to synthesize the briefing from cache entries.

**If running full cycle (Step 0.2 = NO):** read the frontmatter tags of each project document and compare against the current task:

| Match dimension | How to check | Example |
|-----------------|-------------|---------|
| **Technology stack** | Same language, framework, build system | Qt + C++ task → match EgainMeasure, FitsCompare |
| **Domain** | Same industry, data format, problem type | FITS astronomy task → match both projects |
| **Architecture style** | Same pattern (MVC, pipeline, event-driven) | Desktop GUI → match Qt projects |
| **Pattern reuse** | Task needs a specific pattern | Async processing → check Generation Counter in both projects |

**Match threshold:** One dimension match = read that project. Two or more = mandatory deep read.

If zero matches across all dimensions, state this explicitly and proceed with generic best practices.

## Phase 3: Extract — Targeted Reading

**Read only the sections relevant to the current task** (targeted reading saves time and context):

| Current task needs... | Read these sections |
|----------------------|---------------------|
| Choose tech stack / dependencies | Tech Stack, Key Dependencies |
| Design architecture | Architecture, Data Flow, Core Modules |
| Write async/multi-threaded code | Reusable Patterns, Edge Cases & Defensive Design |
| Handle file I/O / external libraries | Edge Cases & Defensive Design, Key Dependencies |
| Avoid known pitfalls | Technical Debt & Risks (especially ✅ resolved items) |
| Write tests | Testing |
| Set up build config | Configuration, Quick Start |
| Match author's coding style | Architecture, Core Modules, Overall Assessment |
| Export/report generation | Key Business Flows |
| Cross-project consistency | Related Projects |

**Constraint:** Read at most 2 project documents fully. For additional projects, extract only the Reusable Patterns and Technical Debt sections.

## Phase 4: Synthesize — Write the Experience Briefing

Compose a briefing and output it to the conversation. It serves as a persistent reference for the rest of the session:

```markdown
## Project Experience Briefing

### Matched Projects
- [[Project A]] — match: Qt + C++ + domain X
- [[Project B]] — match: Qt + C++ + domain Y

### Coding Preferences
1. [preference 1] — evidence: Project A Architecture, Project B Core Modules
2. [preference 2] — evidence: [source]

### Pitfalls to Avoid
| Pitfall | Status | Source | Strategy |
|---------|--------|--------|----------|
| ... | ✅/⚠️ | ... | ... |

### Reusable Patterns
1. **[pattern name]** — [one line] — applies to: [X]
2. ...

### Quality Baseline
- Code organization: [inferred]
- Error handling: [inferred]
- Test coverage: [inferred]
```

**When reading from cache (Step 0.2 = YES), use this simpler briefing format** — the cache already has distilled entries, no project names needed:

```markdown
## Project Experience Briefing (from cache)

### Relevant Pitfalls
- **pitfall**: strategy to avoid (from cached experience)

### Relevant Patterns
- **pattern**: how to apply (from cached experience)

### Coding Conventions
- convention (from cached experience)
```

## Phase 5: Apply

The briefing is your constraint system. For every subsequent decision:

1. **Choose a library** → check Pitfalls to Avoid
2. **Design a module** → check Reusable Patterns
3. **Write boilerplate** → check Coding Preferences
4. **In doubt** → cache mode: first re-read `$DOC_HUB/_exp_memory.md`; if still unclear, locate the project documents sourcing that entry and read `$DOC_HUB/<ProjectName>/<ProjectName>.md`. If source projects can't be identified, state uncertainty explicitly.

**Reference the briefing explicitly in your responses:**

> "I see you used Generation Counter in Project A and Project B for async race conditions — I'll use the same approach here."

## Phase 6: Save Experience Cache

After completing the full extraction cycle (Phases 1–5), save the distilled experience to `$DOC_HUB/_exp_memory.md`:

```markdown
# Project Experience Cache

> Auto-generated from completed projects. Delete and re-run project-experience to refresh.

## Known Pitfalls
<!-- Actual bugs that took >10min to fix. Merge duplicates across projects. -->

- **brief description**: symptom → root cause → fix (ProjectA, ProjectB)

## Reusable Patterns
<!-- Patterns appearing in ≥2 projects, or single-project patterns highly generalizable. -->

- **Pattern Name**: what it solves → how it works (ProjectA, ProjectB)

## Coding Conventions
<!-- Cross-project stable preferences. Only conventions that differ from defaults. -->

- convention description
```

**Content rules:**
- **Known Pitfalls**: Only bugs you actually encountered and spent time fixing. Include symptom, root cause, and fix. Merge two pitfalls when they share the same root cause AND the same fix pattern. If root cause differs but symptom is similar → keep separate. If root cause is same but fix differs per context → keep separate with cross-references.
- **Reusable Patterns**: Only patterns observed in ≥2 projects, or highly generalizable single-project patterns. A single-project pattern qualifies as highly generalizable only if it would apply to any project in the same language/framework. Ask: "Would this pattern be useful in a completely different domain app using the same tech stack?" Exclude project-specific glue code. Include what problem it solves and how it works.
- **Coding Conventions**: Only preferences stable across projects. List only conventions that differ from common defaults — skip universal ones.
- **Hard cap**: Keep the entire file under ~40 lines. If exceeding, apply in order: (1) Merge pitfalls with identical fix patterns even if symptoms differ. (2) Drop single-project patterns not meeting the generalizable test. (3) Drop conventions already common practice. (4) Drop least frequently applicable entries (count projects that exhibited the pattern/pitfall). Priority to keep: pitfalls > patterns > conventions.

**This cache is read by future invocations** — if it exists, Phase 1 and Phase 3 are skipped (see Step 0.2). When new projects are completed, the user can delete this file and re-run project-experience (triggered by ADD Phase 6). Cache regeneration is manual-only — project completion is a human judgment call.

## Quick Reference

| Phase | Action | Time |
|-------|--------|------|
| 0. Locate | Read ~/.add-hub → fallback glob `**/_exp_memory.md` → ask user | 2s |
| 0.2 Cache | Check $DOC_HUB/_exp_memory.md → skip Phase 1+3 if exists | 2s |
| 0.3 Find | Glob $DOC_HUB/*/*.md, filter to `<DirName>/<DirName>.md` | 3s |
| 1. Survey | Read index + read project docs via $DOC_HUB | 10s |
| 2. Match | Compare tags vs task (or cache entries vs task) | 5s |
| 3. Extract | Read targeted sections from 1-2 project docs | 30-60s |
| 4. Synthesize | Write briefing to context | 30s |
| 5. Apply | Reference briefing in all subsequent decisions | Ongoing |
| 6. Save | Write briefing to $DOC_HUB/_exp_memory.md (first run only) | 10s |

**Total overhead: ~2 minutes (first run) / ~15 seconds (cache hit).**

## Common Mistakes

| Mistake | Why it happens | Fix |
|---------|---------------|-----|
| Using relative paths | Working directory may be anywhere | Always use absolute paths from `$DOC_HUB` |
| Skipping Phase 0 | "I already know where the docs are" | Always run Step 0.1: read `~/.add-hub` → fallback glob `**/_exp_memory.md` → ask user. |
| Not writing the briefing | "I'll remember what I read" | Without a written briefing, lessons fade within 10 message turns. Write it down. |
| Ignoring ✅ resolved items | "That's already fixed, not relevant" | Resolved items show exactly what patterns to use INSTEAD. |
| Reading entire project docs | "More context is better" | Trust the section mapping table. Targeted reading is faster and cleaner. |
| Not citing sources | "The author knows their own projects" | Citations show your reasoning is evidence-based, not generic advice. |
| Skipping cache check | "I'll just run the full cycle" | Always check `$DOC_HUB/_exp_memory.md` first. Cache hit saves 2 minutes. |
