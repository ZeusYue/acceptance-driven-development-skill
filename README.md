# Acceptance-Driven Development (ADD)

<p align="center">
  <b>The AI skill pack that makes "done" a checklist, not a feeling.</b><br>
  Works with Claude Code · Codex CLI · Gemini CLI · Copilot CLI<br>
  <sub>[English](#the-problem-weve-all-had) | [中文](#我们共同遇到的问题)</sub>
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
| Agent says "I fixed it" — you test and find 3 more bugs | Agent self-reviews against 5 checks *before* showing you |
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

ADD ships with `project-experience` — a companion skill that reads your past project docs and extracts reusable patterns, known pitfalls, and coding conventions. First run scans all projects (~2 min) and generates an `exp_memory.md` cache. Every subsequent run hits the cache in ~15 seconds. ADD also reads the cache during feature design (Phase 3.5), so past project experience surfaces at every decision point.

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

### v1.2 — Unified Document Hub (2026-07-10)

- **`$DOC_HUB` centralized architecture**: all ACs, project docs, templates, and experience cache under one directory independent of code
- **`~/.exp_memory.md` anchor discovery**: auto-locate hub across sessions and windows — no repeated path prompts
- **Immediate placeholder**: `.exp_memory.md` created on first setup, not waiting for project completion — prevents parallel-session conflicts
- **Improved onboarding prompt**: explains purpose (shared across all projects), warns against project-specific paths
- **`memory.md` → `exp_memory.md`**: renamed to avoid name collisions with Claude's own memory files
- **6-item review checklist**: Framework-specific checks added as the 6th item (Wiring, Safety, Fidelity, State, Impact, Framework)
- **Mode B AC restoration**: explicitly restores ACs demoted by impact analysis after self-review
- **Phase 5 path split**: Mode A items (AUTO/MANUAL/BLOCKED) and Mode B items handled in separate clear paths
- **3-failure threshold for Mode A**: prevents infinite re-implementation loops on failing verifications
- **`[~]` settlement step**: partially-done items must be resolved (fix/defer/deprecate) before project doc generation
- **All paths use `$DOC_HUB`**: zero hardcoded `projects/` or `<VAULT>/<DOCS>` references remain

### v1.1 — Experience Cache & Quality Audit (2026-07-09)

- **Experience cache**: `project-experience` generates `exp_memory.md` — ~15s fast path after first scan
- **Cache-aware Phase 3.5 & Gate 1**: past project pitfalls surface at every decision point
- **Event-driven AC updates**: user confirms test → `[x]` immediately, no waiting
- **Transparency rule**: every phase/mode entry announced to user for supervision
- **12+ logic gaps fixed**, 16+ negative phrasings cleaned

### v1.0 — Initial Release (2026-07-03)

- Full 9-phase workflow, dual-mode implementation (batch/lightweight), 5-item self-review, hard-gate completion

---

# 验收驱动开发 (ADD)

<p align="center">
  <b>让"完成"变成一份清单，而不是一种感觉的 AI 技能包。</b><br>
  适用于 Claude Code · Codex CLI · Gemini CLI · Copilot CLI<br>
  <sub>[English](#the-problem-weve-all-had) | [中文](#我们共同遇到的问题)</sub>
</p>

## 我们共同遇到的问题

你让 AI 助手帮你构建一个功能。它写代码、编译通过，然后说**"搞定了！"**

你打开应用一看——三个功能没做，一个按钮不灵，还有别的东西莫名其妙坏了。而 AI 助手早已愉快地翻篇了，浑然不觉。

**AI 助手是天生的乐观派。它们只管交付代码就宣称完成，而你才是那个发现到底缺了什么的人。**

我们构建 ADD 就是为了从根本上解决这个问题。

---

## 它是如何工作的

```
你的想法
    │
    ▼
助手提出澄清性问题 ──► 绝不默默猜测
    │
    ▼
助手撰写验收标准 ──► 你来审核并批准
    │
    ▼
助手批量构建每一项 ──► 每完成一项都自查一遍
    │
    ▼
[ ] → [!] → 你测试 → [x] ──► 循环直到没有任何 [ ]
    │
    ▼
自动生成项目文档 ──► 下一个项目从中受益 ✦
```

**实际发生的事情是这样的：** 只要还有 AC 状态是 `[ ]`，助手就不能说"做完了"。它不能跳过自检，不能偷偷改你的需求，更不能对着同一个 bug 修了十次却不问你是不是思路本身就错了。每一行代码都能追溯到一条验收标准。

---

## 使用 ADD 之前 vs 之后

| 😟 之前 | 😎 之后 |
|-----------|----------|
| "完成" = 代码编译通过 | "完成" = 每一个 AC 复选框都是 `[x]` |
| 助手假设，你来纠正 | 助手询问，你确认，*然后*才开始构建 |
| 助手说"我修好了" —— 你一测又发现三个 bug | 助手在给你看之前，先按 5 项检查自查一遍 |
| 修一个东西，坏另一个 | 影响分析在改代码之前先降级受影响的 AC |
| 失败了 3 次 → 助手继续打补丁 | 3 次失败 → 助手停下来问"是不是方向错了？" |
| 每个项目从零开始 | `project-experience` 从过往项目中学习；缓存启动约 15 秒 |

---

## 60 秒快速上手

### 加载技能（每次会话一次）
```
/acceptance-driven-development
```

### 告诉它你想要什么
```
"我想做一个带倒计时功能的闹钟应用。"
```

### 剩下的交给助手
- 提出澄清性问题（而不是默默猜测）
- 撰写验收标准文档（你来审核批准）
- 批量构建所有内容 —— 不打断你
- 对每一项变更按 6 项清单自查
- 标记为 `[x]`（已验证）或 `[!]`（需要你手动测试）
- 循环直到没有任何 `[ ]` —— 然后自动生成项目文档

### 用于已有项目
```
"继续开发 ImageView"
→ 助手读取你的 AC 表格，找到剩余的 [ ] 项，批量处理全部
```

### 在项目中途添加功能
```
"加一个贪睡按钮"
→ 助手先更新 AC，提出方案，等你确认，然后才写代码
```

---

## 6 种 AC 状态（简易 Markdown 表格）

| 标记 | 含义 |
|------|---------|
| `[ ]` | 尚未开始 —— 助手会去做 |
| `[~]` | 部分完成 —— 已知边缘情况问题 |
| `[x]` | 已验证通过 |
| `[!]` | 已实现 —— 需要你亲手测试 |
| `[-]` | 已弃用 |
| `[>]` | 已推迟 —— 用户决定延后。助手完全跳过，除非用户要求 |

你的整个项目都存放在一个 Markdown 文件里 —— 一份你和助手都能读取的单一事实来源。

---

## 🔥 可选：安装 Superpowers 获得升级体验

ADD 单独使用已经非常出色。但如果你有 [Superpowers](https://github.com/obra/superpowers)，它会直接升维：

| Superpowers 技能 | ADD 解锁的能力 |
|-------------------|------------------|
| `brainstorming` | 新项目深度交互式设计讨论 |
| `writing-plans` | 结构化任务分解 |
| `subagent-driven-development` | 每个任务独立子代理执行 |
| `test-driven-development` | 高质量 AC 自动驱动 TDD |
| `verification-before-completion` | 标记 `[x]` 前强制重新验证 |
| `finishing-a-development-branch` | 干净利落地收尾分支 |

**可以这样理解：** 单独的 ADD 是一辆跑车。ADD + Superpowers 是同一辆车，但配了一支专业的维修团队。准备好了随时安装。

---

## 🔗 经验循环

ADD 自带 `project-experience` —— 一个配套技能，它能读取你过去的项目文档，提取可复用的模式、已知陷阱和编码惯例。首次运行会扫描所有项目（约 2 分钟）并生成 `exp_memory.md` 缓存。之后的每次运行只需约 15 秒命中缓存。ADD 在功能设计阶段也会读取缓存（阶段 3.5），因此过往项目经验会在每一个决策点浮现。

> "你在 3 个项目中用 Generation Counter 解决异步竞态条件 —— 我这次也会用。"
> "你用 `$$PWD/bin` 修复了 vcpkg 硬编码问题 —— 咱们一开始就这么做。"
> "你的质量基线是核心算法 70%+ 测试覆盖率。"

你每做一个项目，未来的每个项目都会变得更好。使用 Obsidian 可以自动索引（Dataview）。不用 Obsidian？任何文件夹都可以 —— 技能会自动发现你的文档。

---

## 适用于你的 AI 助手

| Claude Code | Codex CLI | Gemini CLI | Copilot CLI | 任何支持 SKILL.md 的助手 |
|:-----------:|:---------:|:----------:|:-----------:|:------------------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

标准 `SKILL.md` 格式。丢进去，重启，完事。

---

## 安装

```bash
skills/acceptance-driven-development/  →  ~/.claude/skills/acceptance-driven-development/
skills/project-experience/             →  ~/.claude/skills/project-experience/
projects/templates/                    →  你的项目文档文件夹/
```

重启你的助手。输入 `/skills` 验证。

**首次使用：** 每次编程会话开始时，用 `/acceptance-driven-development` 加载一次 ADD。规则在整个会话期间保持激活。如果助手跳过了某个步骤，只需说"阶段 3.5？"—— 它立马就回来了。新会话？再加载一次就好。

---

## 真实案例

参见 `projects/AlarmClock/`：
- `AC.md` —— 23 条验收标准（功能、性能、兼容性、质量）
- `AlarmClock.md` —— `project-experience` 会读取的项目文档

完全使用 ADD 构建。功能包括：定时闹钟、倒计时、窗口置顶、透明度滑块、点击穿透锁定模式、每日及仅工作日重复、贪睡、全屏闪烁通知、紧凑卡片模式。

---

## 常见问题

**Q：这会拖慢我的开发速度吗？**
A：每次变更大约额外花费 2 分钟。但它帮你省下的是数小时的调试和返工。我们在真实项目上已经测试了几个月。

**Q：我需要 Superpowers 吗？**
A：完全不需要。ADD 本身就是完整的。Superpowers 在你想要的时候提供可选的专业工作流。

**Q：推荐什么配置？**
A：作者日常使用的配置 —— 也是我们推荐的 —— 是 **ADD + Superpowers + Obsidian**。Superpowers 深化每一个阶段（头脑风暴、规划、子代理执行、TDD、验证），而 Obsidian 通过 wiki 链接和 Dataview 自动索引，为你的项目文档提供美观的仪表盘。当然，ADD 在任何文件夹结构和任何助手下都能完美运行。

**Q：我需要在每次对话中加载 ADD 吗？**
A：不需要 —— 在第一次会话开始时加载一次即可。助手会在该会话的剩余时间里记住规则。如果它跳过了某个步骤，只需说"阶段 3.5？"或"你自查过了吗？"—— 通常这就够了。当你开启一个全新的会话时，在开始时加载一次 ADD。可以理解为：这是拧钥匙点火，不是一直踩着油门。

**Q：如果助手跳过了流程怎么办？**
A：ADD 有 8 层防御机制。如果助手仍然设法跳过，问一句"你经过模式 B 了吗？"就是你的最后一道安全网。

**Q：非代码项目能用吗？**
A：ADD 最适合软件开发。AC 表格结构需要可验证、可测试的行为。

**Q：我的项目还没有 AC 文档怎么办？**
A：阶段 0 会检测到这一点并触发完整设置 —— 头脑风暴 → 设计文档 → AC 创建。大约需要 5 分钟。

---

## 更新日志

### v1.2 — 统一文档中心 (2026-07-10)

- **`$DOC_HUB` 集中化架构**：所有 AC、项目文档、模板和经验缓存都在一个独立于代码的目录下
- **`~/.exp_memory.md` 锚点发现**：跨会话和窗口自动定位文档中心 —— 不再重复询问路径
- **即时占位符**：`.exp_memory.md` 在首次设置时即创建，不等项目完成 —— 防止并行会话冲突
- **改进的引导提示**：解释用途（跨所有项目共享），警告不要使用项目特定路径
- **`memory.md` → `exp_memory.md`**：重命名以避免与 Claude 自身的 memory 文件冲突
- **6 项审查清单**：框架特定检查作为第 6 项加入（接线、安全、保真度、状态、影响、框架）
- **模式 B AC 恢复**：自检后显式恢复被影响分析降级的 AC
- **阶段 5 路径分离**：模式 A 项（AUTO/MANUAL/BLOCKED）和模式 B 项在独立的清晰路径中处理
- **模式 A 3 次失败阈值**：防止验证失败时无限重新实现循环
- **`[~]` 结算步骤**：部分完成的条目必须在项目文档生成前解决（修复/推迟/弃用）
- **所有路径使用 `$DOC_HUB`**：不再有任何硬编码的 `projects/` 或 `<VAULT>/<DOCS>` 引用

### v1.1 — 经验缓存与质量审查 (2026-07-09)

- **经验缓存**：`project-experience` 生成 `exp_memory.md` —— 首次扫描后约 15 秒快速路径
- **缓存感知的阶段 3.5 和关卡 1**：过往项目陷阱在每个决策点浮现
- **事件驱动的 AC 更新**：用户确认测试 → 立即标记 `[x]`，无需等待
- **透明规则**：每次进入阶段/模式时向用户宣告，方便监督
- **修复 12+ 逻辑漏洞**，清理 16+ 处负面措辞

### v1.0 — 初始发布 (2026-07-03)

- 完整 9 阶段工作流、双模式实现（批量/轻量）、5 项自检、硬关卡完成
