# Acceptance-Driven Development

> **The AI skill pack that makes sure "done" actually means done.**

---

## Why This Exists

You've told an AI agent to build something. It wrote a bunch of code, compiled, and said "done." But you open the app and half the features are missing, buttons don't work, and three other things broke mysteriously.

**"Done" shouldn't be a feeling. It should be a checklist with all boxes ticked.**

ADD (Acceptance-Driven Development) enforces exactly that — every feature, every fix, every improvement must pass through a verifiable acceptance criteria checklist before the agent is allowed to say "done."

---

## The Core Flow

```
You: "Build me a clock app with countdown timers"
         │
         ▼
   Agent asks clarifying questions (not silently guessing)
         │
         ▼
   Agent writes an Acceptance Criteria document (you review + approve)
         │
         ▼
   Agent implements EVERY item in batch, self-reviews each one
         │
         ▼
   Agent marks items [x] (verified) or [!] (needs your test)
         │
         ▼
   You test [!] items, confirm → agent marks [x]
         │
         ▼
   ANY [ ] still remaining? → Agent goes back and does more work
         │
         ▼
   ALL [x] → Project document auto-generated for future reference
         │
         ▼
   Closed loop: next project auto-learns from this one ✦
```

---

## What Makes This Different

| Without ADD | With ADD |
|-------------|----------|
| Agent says "done" when code compiles | Agent says "done" when every AC is `[x]` |
| Agent silently guesses your requirements | Agent asks questions, presents options, waits for confirmation |
| Agent skips self-review and hopes for the best | Agent self-reviews each change against a 5-item checklist |
| Changes break other features silently | Impact analysis demotes affected ACs before modifying code |
| 3 failed attempts → agent keeps patching forever | 3 failures → agent stops and asks if the approach is wrong |
| Bug fixes skip quality gates | Even one-line fixes go through review |

---

## Works With Your Agent, Whatever It Is

| Platform | Support |
|----------|:------:|
| Claude Code | ✅ Native |
| Codex CLI | ✅ Native (config tip in `codex-port/`) |
| Gemini CLI | ✅ Native |
| Copilot CLI | ✅ Native |
| Any SKILL.md-compatible agent | ✅ |

ADD uses the standard `SKILL.md` format. Copy it to your agent's skills directory and it works.

---

## How to Use It

### Starting something new
```
"I want to build a photo browser. Use ADD."
```
Agent brainstorms with you → writes acceptance criteria → you approve → builds everything.

### Picking up where you left off
```
"Continue developing my project"
```
Agent reads the AC table, finds remaining `[ ]` items, batch-processes all of them.

### Adding a feature mid-project
```
"Add a snooze button to the alarm"
```
Agent updates the AC FIRST, proposes an approach, waits for your confirmation, then implements. No silent feature creep.

### Fixing a bug
```
"This button crashes when I click it"
```
Agent greps callers, demotes affected ACs, fixes the root cause (not just the symptom), self-reviews.

---

## The 6 AC Statuses

| Mark | Meaning |
|------|---------|
| `[ ]` | Not implemented yet — agent will work on it |
| `[~]` | Partially done — known edge issues remain |
| `[x]` | Verified and passing |
| `[!]` | Implemented — needs your hands-on test |
| `[-]` | Deprecated |
| `[>]` | Deferred — good idea, not now. Has an upgrade trigger ("when user count > 1000") |

---

## 🔥 Level Up with Superpowers

ADD works standalone. But if you have the [Superpowers skill pack](https://github.com/anthropics/superpowers) installed, it gets significantly stronger:

| Superpowers skill | How ADD uses it |
|-------------------|-----------------|
| `brainstorming` | Deep interactive design discussions for new projects and large changes |
| `writing-plans` | Structured task decomposition for complex features |
| `subagent-driven-development` | Independent subagents execute each task with proper review |
| `test-driven-development` | Quality ACs force TDD workflows |
| `verification-before-completion` | Fresh verification output required before any `[x]` marker |
| `finishing-a-development-branch` | Clean branch completion after all ACs pass |

ADD works standalone with direct implementation. Install Superpowers anytime for upgraded workflows — interactive brainstorming, structured task decomposition, independent subagent execution. It's a one-click power boost, not a dependency.

---

## 🔗 The Experience Loop (Obsidian + project-experience)

ADD ships with a companion skill: `project-experience`.

When ADD finishes a project, it generates a project document (tech stack, architecture, reusable patterns, edge cases, pitfalls). When you start your NEXT project, `project-experience` reads all past project docs and extracts:

- **Your coding preferences** — "They always use QtConcurrent for async, not raw threads"
- **Pitfalls you've already solved** — "vcpkg path was hardcoded before, they fixed it with `$$PWD/bin`"
- **Reusable patterns** — "Generation Counter pattern appears in 3 projects"
- **Quality baseline** — "They target 70%+ test coverage on core algorithms"

This means each project makes every future project better. If you use Obsidian, Dataview auto-generates your project index. Don't use Obsidian? Any folder works — the skill auto-discovers your docs.

---

## Installation

### 1. Copy Skills
```
skills/acceptance-driven-development/  →  ~/.claude/skills/acceptance-driven-development/
skills/project-experience/             →  ~/.claude/skills/project-experience/
```
(Path varies by platform — see your agent's docs for the skills directory)

### 2. Copy Templates
Copy `projects/templates/` files into your project docs folder.

### 3. Restart your agent
Skills load on the next session.

### 4. Verify
Type `/skills` — you should see `acceptance-driven-development` and `project-experience`.

---

## Example Project

See `projects/AlarmClock/` for a complete worked example:
- `AC.md` — 22 acceptance criteria covering features, compatibility, performance, and quality
- `AlarmClock.md` — The project document that `project-experience` reads

---

## FAQ

**Q: Does this slow me down?**
A: The overhead is ~2 minutes per change (impact analysis + self-review). It saves hours of debugging and rework.

**Q: Do I need Superpowers?**
A: Not at all. ADD works great on its own — you get the full AC loop, self-review, and hard gates. Superpowers is an optional upgrade that adds brainstorming, structured planning, and subagent execution when you want them.

**Q: What if my agent skips the process?**
A: ADD has 6 hard gates (confirmation requirements, exit blockers, rationalization counters). If the agent still skips, asking "Did you go through Mode B?" is your last line of defense — and it works.

**Q: Does this work with non-code projects?**
A: ADD is designed for software development. The AC table structure works best for projects with verifiable behavior.

**Q: What about existing projects without AC docs?**
A: Phase 0 detects missing AC files and triggers the Greenfield process — brainstorming, design doc, AC creation.
