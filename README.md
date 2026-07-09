# Acceptance-Driven Development (ADD)

<p align="center">
  <b>The AI skill pack that makes "done" a checklist, not a feeling.</b><br>
  Works with Claude Code · Codex CLI · Gemini CLI · Copilot CLI
</p>

---

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
| Agent says "I fixed it" — you test and find 3 more bugs | Agent self-reviews against 5 checks *before* showing you |
| Fixing one thing breaks another | Impact analysis demotes affected ACs before changing code |
| 3 failed attempts → agent keeps patching | 3 failures → agent stops and asks "wrong approach?" |
| Each project starts from scratch | `project-experience` auto-learns from your past projects |

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
- Self-reviews each change against a 5-item checklist
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
| `[>]` | Deferred — good idea, not now. Has upgrade trigger ("when user count > 1000") |

Your entire project lives in one markdown file — a single source of truth that both you and the agent can read.

---

## 🔥 Optional: Install Superpowers for an Upgrade

ADD works great standalone. But if you have [Superpowers](https://github.com/anthropics/superpowers), it levels up:

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

ADD ships with `project-experience` — a companion skill that reads your past project docs and extracts:

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
- `AC.md` — 22 acceptance criteria (features, performance, compatibility, quality)
- `AlarmClock.md` — Project doc that `project-experience` reads

Built entirely with ADD. Features: timed alarms, countdowns, always-on-top window, transparency slider, click-through lock mode, daily repeat, snooze, full-screen flash notifications.

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
