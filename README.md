# Acceptance-Driven Development (ADD)

<p align="center">
  <b>The AI skill pack that makes "done" a checklist, not a feeling.</b><br>
  Works with Claude Code · Codex CLI · Gemini CLI · Copilot CLI<br>
  <sub>English | <a href="README-zh.md">中文</a></sub>
</p>

## The Problem We've All Had

You ask an AI agent to build something. It writes code. It compiles. It says **"Done!"**

You open the app. Three features are missing. A button doesn't work. Something else broke mysteriously. And the agent has already moved on, cheerfully oblivious.

**AI agents are optimists. They ship code and call it complete. You're the one who discovers what's actually missing.**

We built ADD to fix this permanently.

---

## How It Works

```
YOUR IDEA
    │
    ▼
Agent asks clarifying questions ──► No silent guessing
    │
    ▼
Agent writes Acceptance Criteria ──► You review & approve
    │
    ▼
Agent builds EVERY item in batch ──► Self-reviews each one
    │
    ▼
[ ] → [!] → You test → [x] ──► Loop until nothing's [ ]
    │
    ▼
Project doc auto-generated ──► Next project learns from this one ✦
```

**Here's what actually happens:** The agent can't say "done" while any AC still shows `[ ]`. It can't skip self-review. It can't silently change your requirements. It can't patch the same bug 10 times without asking if the approach is wrong. Every line of code traces back to an AC item.

---

## Before ADD vs After ADD

| 😟 Before | 😎 After |
|-----------|----------|
| "Done" means code compiled | "Done" means every AC box is `[x]` |
| Agent assumes, you correct | Agent asks, you confirm, *then* builds |
| Agent says "I fixed it" — you test and find 3 more bugs | Agent self-reviews against 6 checks *before* showing you |
| Fixing one thing breaks another | Impact analysis demotes affected ACs before changing code |
| 3 failed attempts → agent keeps patching | 3 failures → agent stops and asks "wrong approach?" |
| Each project starts from scratch | `project-experience` learns from past projects; cache makes it ~15s |

---

## 60-Second Quick Start

### Load the skill (once per session)
```
/acceptance-driven-development
```

### Tell it what you want
```
"I want to build an alarm clock app with countdown timers."
```

### Agent handles the rest
- Asks you clarifying questions (not silent guessing)
- Writes an Acceptance Criteria document (you review and approve)
- Builds everything — batch mode, no interruptions
- Self-reviews each change against a 6-item checklist
- Marks items `[x]` (verified) or `[!]` (needs your test)
- Loops until nothing is `[ ]` — then generates your project documentation

### For existing projects
```
"Continue developing ImageView"
→ Agent reads your AC table, finds remaining [ ] items, batch-processes all of them
```

### Adding features mid-project
```
"Add a snooze button"
→ Agent updates AC FIRST, proposes approach, waits for your confirmation, THEN codes
```

---

## The 6 AC Statuses (Simple Markdown Table)

| Mark | Meaning |
|------|---------|
| `[ ]` | Not yet — agent will work on it |
| `[~]` | Partially done — known edge issues |
| `[x]` | Verified and passing |
| `[!]` | Implemented — needs your hands-on test |
| `[-]` | Deprecated |
| `[>]` | Deferred — user's decision to postpone. Agent skips entirely unless user asks |

Your entire project lives in one markdown file — a single source of truth that both you and the agent can read.

---

## 🔥 Optional: Install Superpowers for an Upgrade

ADD works great standalone. But if you have [Superpowers](https://github.com/obra/superpowers), it levels up:

| Superpowers Skill | What ADD Unlocks |
|-------------------|------------------|
| `brainstorming` | Deep interactive design sessions for new projects |
| `writing-plans` | Structured task decomposition |
| `subagent-driven-development` | Independent subagent execution per task |
| `test-driven-development` | Quality ACs automatically drive TDD |
| `verification-before-completion` | Mandatory fresh verification before `[x]` |
| `finishing-a-development-branch` | Clean branch wrap-up |

**Think of it like this:** ADD alone is a sports car. ADD + Superpowers is the same car with a professional pit crew. Install whenever you're ready.

---

## 🔗 The Experience Loop

ADD ships with `project-experience` — a companion skill that reads your past project docs and extracts reusable patterns, known pitfalls, and coding conventions. First run scans all projects (~2 min) and generates an `_exp_memory.md` cache. Every subsequent run hits the cache in ~15 seconds. ADD also reads the cache during feature design (Phase 3.5), so past project experience surfaces at every decision point.

> "You used Generation Counter in 3 projects for async race conditions — I'll use it here too."
> "You fixed vcpkg hardcoding with `$$PWD/bin` — let's do that from the start."
> "Your quality baseline is 70%+ test coverage on core algorithms."

Every project you build makes every future project better. Use Obsidian for auto-indexing (Dataview). Don't use Obsidian? Any folder works — the skill auto-discovers your documents.

---

## Works With Your Agent

| Claude Code | Codex CLI | Gemini CLI | Copilot CLI | Any SKILL.md agent |
|:-----------:|:---------:|:----------:|:-----------:|:------------------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

Standard `SKILL.md` format. Drop it in, restart, done.

---

## Installation

```bash
skills/acceptance-driven-development/  →  ~/.claude/skills/acceptance-driven-development/
skills/project-experience/             →  ~/.claude/skills/project-experience/
projects/templates/                    →  your-project-docs-folder/
```

Restart your agent. Type `/skills` to verify.

**First use:** At the start of each coding session, load ADD once with `/acceptance-driven-development`. The rules stay active for the entire session. If the agent ever skips a step, just say "Phase 3.5?" — that snaps it back. New session? Load once again.

---

## Real Example

See `projects/AlarmClock/`:
- `AC.md` — 23 acceptance criteria (features, performance, compatibility, quality)
- `AlarmClock.md` — Project doc that `project-experience` reads

Built entirely with ADD. Features: timed alarms, countdowns, always-on-top window, transparency slider, click-through lock mode, daily and weekday-only repeat, snooze, full-screen flash notifications, compact card mode.

---

## FAQ

**Q: Does this slow me down?**
A: ~2 minutes of overhead per change. It saves hours of debugging and rework. We've tested this on real projects for months.

**Q: Do I need Superpowers?**
A: Not at all. ADD is complete on its own. Superpowers adds optional professional workflows when you want them.

**Q: What's the recommended setup?**
A: The author's daily driver — and what we recommend — is **ADD + Superpowers + Obsidian**. Superpowers deepens every phase (brainstorming, planning, subagent execution, TDD, verification), while Obsidian gives you a beautiful dashboard for your project documents with wiki-links and Dataview auto-indexing. That said, ADD works perfectly with any folder structure and any agent.

**Q: Do I need to load ADD in every conversation?**
A: No — load it once at the start of your first session. The agent remembers the rules for the rest of that session. If it ever skips a step, just say "Phase 3.5?" or "Did you self-review?" — that's usually enough to snap it back. When you start a brand new session, load ADD once at the beginning. Think of it like turning on the ignition, not holding the accelerator.

**Q: What if the agent skips the process?**
A: ADD has 8 defensive layers. If the agent still manages to skip, asking "Did you go through Mode B?" is your final safety net.

**Q: What about non-code projects?**
A: ADD works best for software. The AC table structure needs verifiable, testable behavior.

**Q: My project doesn't have AC docs yet?**
A: Phase 0 detects this and triggers the full setup — brainstorming → design doc → AC creation. Takes about 5 minutes.

---

## Changelog

### v1.3 — Robustness Audit (2026-07-11)

- **`_exp_memory.md` renamed** (from `.exp_memory.md`): visible in Obsidian and file managers that hide dot-files
- **Two-layer completion refined**: agent work done = no `[ ]` or `[~]`; project complete = only `[x]` `[>]` `[-]` remain
- **Mode A + Mode B both restore demoted ACs**: impact-analysis demotions are re-verified and restored after implementation, not left for Phase 6 to catch
- **AUTO classification requires an executable command**: vague "check it works" descriptions are classified MANUAL instead
- **AUTO verification shows its work**: command, expected, and actual output presented before marking `[x]`
- **Self-review reports per-item**: Phase 4.8 PASS outputs one line per checklist item — no silent "PASS"
- **Experience cache validates content**: placeholder or empty caches trigger a full scan instead of a false hit
- **Cache merge/overflow rules defined**: explicit criteria for merging pitfalls, judging pattern generalizability, and priority when trimming to the size cap
- **20+ consistency fixes**: Mode A step count, demotion-restore exception, fast-lane confirmation wording, Phase 6 flow diagram, failure thresholds for both modes, regression handling, and more

### v1.2 — Unified Document Hub (2026-07-10)

- **`$DOC_HUB` centralized architecture**: all ACs, project docs, templates, and experience cache under one directory independent of code
- **`~/_exp_memory.md` anchor discovery**: auto-locate hub across sessions and windows — no repeated path prompts
- **Immediate placeholder**: `_exp_memory.md` created on first setup, not waiting for project completion — prevents parallel-session conflicts
- **Improved onboarding prompt**: explains purpose (shared across all projects), warns against project-specific paths
- **`memory.md` → `exp_memory.md`**: renamed to avoid name collisions with Claude's own memory files
- **6-item review checklist**: Framework-specific checks added as the 6th item (Wiring, Safety, Fidelity, State, Impact, Framework)
- **Mode B AC restoration**: explicitly restores ACs demoted by impact analysis after self-review
- **Phase 5 path split**: Mode A items (AUTO/MANUAL/BLOCKED) and Mode B items handled in separate clear paths
- **3-failure threshold for Mode A**: prevents infinite re-implementation loops on failing verifications
- **`[~]` settlement step**: partially-done items must be resolved (fix/defer/deprecate) before project doc generation
- **All paths use `$DOC_HUB`**: zero hardcoded `projects/` or `<VAULT>/<DOCS>` references remain

### v1.1 — Experience Cache & Quality Audit (2026-07-09)

- **Experience cache**: `project-experience` generates `_exp_memory.md` — ~15s fast path after first scan
- **Cache-aware Phase 3.5 & Gate 1**: past project pitfalls surface at every decision point
- **Event-driven AC updates**: user confirms test → `[x]` immediately, no waiting
- **Transparency rule**: every phase/mode entry announced to user for supervision
- **12+ logic gaps fixed**, 16+ negative phrasings cleaned

### v1.0 — Initial Release (2026-07-03)

- Full 9-phase workflow, dual-mode implementation (batch/lightweight), 6-item self-review, hard-gate completion
