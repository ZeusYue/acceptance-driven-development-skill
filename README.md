# Acceptance-Driven Development (ADD) v2.0

<p align="center">
  <strong>Turn “it compiles” into a visible, verifiable definition of done.</strong><br>
  Acceptance criteria, impact analysis, fresh verification, and project memory — in one workflow.
</p>

<p align="center">
  <a href="./README-zh.md">简体中文</a> ·
  <a href="#install-add">Install</a> ·
  <a href="#how-add-works">How it works</a> ·
  <a href="#migrating-to-v20">Migrate to v2.0</a>
</p>

---

## What ADD solves

Coding agents are fast at producing changes, but weak definitions of “done” create the familiar failure loop:

- Code was written, but no acceptance command was run.
- A follow-up feature silently changes a previously working behavior.
- A visual/manual check gets forgotten after the implementation message.
- The same bug is patched repeatedly because the approach was never reconsidered.
- Lessons from finished projects disappear before the next project starts.

**ADD is a workflow skill that keeps an acceptance-criteria table (`AC.md`) as the visible contract.** Every implementation path is tied to a criterion, reviewed, verified, and given a settled status.

> **v2.0 highlights:** stable document-hub discovery, safe cache refresh, explicit backlog entry via Phase 3.5A, clearer `[!]` verification annotations, and installation instructions for multiple agent hosts.

---

## Install ADD

Choose one installation path. **Install both skills**: `acceptance-driven-development` is the workflow engine; `project-experience` is the companion that reuses project knowledge and rebuilds the experience cache.

### Option 1 — CC Switch (recommended)

[CC Switch](https://github.com/farion1231/cc-switch) provides a graphical skill manager for Claude Code, Codex, OpenCode, Gemini CLI, and other supported agent applications.

1. Install and open CC Switch, then select the agent application you want to configure.
2. Open **Skills** → **Repository Management** → **Add Repository**.
3. Add this repository with these exact values:

   - Owner: `ZeusYue`
   - Name: `acceptance-driven-development-skill`
   - Branch: `main`
   - Subdirectory: `skills`

4. Refresh the repository list, then install:
   - `acceptance-driven-development`
   - `project-experience`
5. Restart or reload the target agent session.

For screenshots, updates, verification, and troubleshooting, see [the CC Switch installation guide](./docs/CCSWITCH.md).

### Option 2 — Manual installation

Copy **both directories** from this repository’s `skills/` folder into your agent’s skill directory:

```text
skills/
├── acceptance-driven-development/
└── project-experience/
```

| Agent host | Typical skills directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

For example, a Codex installation should end up as:

```text
~/.codex/skills/
├── acceptance-driven-development/
│   ├── SKILL.md
│   ├── IMPROVEMENT-GUIDE.md
│   └── references/
└── project-experience/
    └── SKILL.md
```

The exact discovery path can vary by host version or custom configuration. If your host documents a different skills directory, use the host-documented path and preserve the two folder names exactly.

### Option 3 — Download a release archive

Download the repository or a GitHub release archive, extract it, and follow **Option 2**. You do not need Obsidian, a Git repository, or Superpowers to run the ADD core workflow.

---

## First Run: Create or Reuse a Document Hub

ADD keeps acceptance criteria and project knowledge in one shared **document hub** (`$DOC_HUB`) that is separate from your code repositories.

On first use, ask your agent for an implementation using ADD. If no hub is configured, it will ask for a stable directory. A good answer is a location such as:

```text
~/project-docs/
```

ADD then writes `~/.add-hub`, a one-line pointer to that directory. The hub typically contains:

```text
$DOC_HUB/
├── _exp_memory.md                 # optional experience cache
├── ac-template.md
├── project-doc-template.md
├── project-index.md
└── <ProjectName>/
    ├── design.md                  # created for greenfield design work
    ├── AC.md                      # acceptance source of truth
    └── <ProjectName>.md           # completed project document
```

**Important:** `_exp_memory.md` is a cache, not the identity of the hub. If the cache is missing, ADD rebuilds it in the same `$DOC_HUB`; it does not silently choose a new document location.

---

## Your first request

### New project

```text
Build a photo browser with ADD.
```

ADD enters the two design gates:

1. clarify and save a design;
2. draft `AC.md`, let you approve it, then implement against it.

### Existing project with pending ACs

```text
Continue developing ImageView with ADD.
```

ADD reads the existing `AC.md`, classifies pending criteria, enters **Phase 3.5A**, and processes the approved backlog in Mode A.

### Mid-project change

```text
Add a snooze button. Use ADD.
```

ADD enters **Phase 3.5B**: it updates the AC first, proposes the approach, waits for your approval, then implements and verifies the change.

---

## How ADD works

### The two implementation entrances

| Entrance | Use it for | What happens next |
|---|---|---|
| **Phase 3.5A — Approved Backlog Entry** | Existing approved `[ ]` / `[~]` rows | Baseline impact analysis, then Mode A. No duplicate design approval. |
| **Phase 3.5B — Mid-Development Change** | New feature, behavior change, bug fix, or improvement | Impact analysis; AC update and approval when behavior changes; then Mode A or Mode B. |

This removes a common workflow loophole: the initial backlog is now explicitly inside the same code-change gate as mid-project changes.

### The six AC states

| Mark | Meaning |
|---|---|
| `[ ]` | Not implemented yet |
| `[~]` | Partially implemented; remaining work is known |
| `[x]` | Freshly verified passing |
| `[!] [manual]` | Implemented; waiting for a hands-on user check |
| `[!] [affected]` | Previously verified but affected by another change; requires fresh re-verification |
| `[!] [blocked]` | Verification cannot run yet; reason and unblock condition are recorded |
| `[>]` | Explicitly deferred by the user |
| `[-]` | Explicitly deprecated |

### Mode A and Mode B

- **Mode A — Batch:** all initial triaged AC work, or a confirmed change spanning three or more ACs. AUTO criteria run their verification commands before `[x]` is recorded.
- **Mode B — Lightweight:** a confirmed Phase 3.5B change spanning one or two ACs. It still requires implementation, the six-point review, impact re-verification, and a `[!] [manual]` handoff.

### The review and verification loop

Every implementation goes through:

```text
AC scope → impact analysis → implementation → 6-point review → fresh verification → status update
```

The review checks wiring, safety, fidelity, state consistency, impact on other ACs, and framework-specific risks. After three failed attempts on the same AC, ADD stops patching and asks whether to redesign, continue with guidance, or defer the item.

---

## Optional enhancements and host limits

ADD’s AC state machine, impact analysis, review checklist, and verification rules are core behavior. These optional capabilities improve the workflow when the current host provides them:

| Optional capability | What it adds | Fallback |
|---|---|---|
| `brainstorming` | Interactive design exploration | Ask and record requirements directly |
| `writing-plans` | File-by-file implementation plan | Write a concise implementation checklist |
| Subagents | Independent batch review | Explicit self-review against all six checks |
| `test-driven-development` | Test-first quality work | Add the smallest feasible regression test |
| `project-experience` | Reuse past project patterns and pitfalls | Proceed without cross-project briefing |

Hosts differ in skill discovery, file tools, and subagent policy. ADD checks available capabilities and continues with its documented fallback rather than blocking the core workflow.

---

## Migrating to v2.0

v2.0 is a workflow-contract release. Existing `AC.md` files remain usable.

1. **Keep your current `~/.add-hub` pointer.** A valid hub no longer depends on `_exp_memory.md` being present.
2. **Do not delete `_exp_memory.md` to refresh it.** Ask for “update experience cache” instead. The replacement is built as `_exp_memory.md.tmp` and applied only after validation succeeds.
3. **Annotate pending verification rows.** Use `[!] [manual]`, `[!] [affected]`, or `[!] [blocked]`.
4. **Use numeric IDs for new top-level criteria.** Add `AC-<next integer>`; do not renumber old rows. Existing historical IDs can remain unchanged.
5. **Install or update both skills.** `project-experience` is optional at runtime, but recommended for the complete experience loop.

---

## What is included

```text
skills/
├── acceptance-driven-development/
│   ├── SKILL.md
│   ├── IMPROVEMENT-GUIDE.md
│   └── references/framework-review-checklist.md
└── project-experience/
    └── SKILL.md

projects/
├── templates/
└── AlarmClock/                    # example AC and completed project document
```

- `acceptance-driven-development` — acceptance-driven implementation workflow
- `project-experience` — project-document mining and cache refresh workflow
- `projects/templates` — optional starter templates
- `projects/AlarmClock` — a worked example

---

## FAQ

**Do I need Obsidian?**
No. `$DOC_HUB` is a normal directory. Obsidian is optional and useful only if you want note navigation, backlinks, or Dataview views.

**Do I need Superpowers or subagents?**
No. ADD runs standalone. Optional skills and subagents deepen the workflow when available.

**Will ADD implement deferred `[>]` items?**
No. Deferred work is a user-facing decision and stays out of implementation unless you explicitly request it.

**Why not mark every completed item `[x]` immediately?**
`[x]` means fresh verification succeeded. Manual work and unavailable environments must remain visible as `[!]` until they have a valid outcome.

**Can I use ADD with an existing project?**
Yes. Create or import `AC.md` into the project’s `$DOC_HUB/<ProjectName>/` directory, then ask the agent to continue with ADD.

---

## Support and Contributions

- Report workflow gaps, unclear instructions, or host-specific installation issues through [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues).
- Contributions are welcome. Please update the relevant README(s), the improvement guide, and `tests/validate-release.ps1` whenever you change the workflow contract.
- For a substantial workflow change, add an explicit migration note and preserve a fallback for hosts without optional capabilities.

---

## v2.0 release notes

- Stable Hub pointer and safe, atomic experience-cache refresh.
- Explicit Phase 3.5A / 3.5B split.
- Annotation-aware `[!]` verification states.
- Monotonic AC IDs for new top-level criteria.
- Rewritten multi-agent installation guidance with a CC Switch path.
- Updated project attribution to **ZeusYue**.

Released under the [MIT License](./LICENSE). Copyright © 2026 ZeusYue.
