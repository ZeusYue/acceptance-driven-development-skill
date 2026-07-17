# 验收驱动开发（ADD）v2.0

<p align="center">
  <strong>把“能编译”变成清晰、可见、可验证的完成定义。</strong><br>
  用验收标准、影响分析、重新验证和项目经验，形成一个完整开发闭环。
</p>

<p align="center">
  <a href="./README.md">English</a> ·
  <a href="#安装-add">安装</a> ·
  <a href="#add-如何工作">工作流</a> ·
  <a href="#迁移到-v20">迁移 v2.0</a>
</p>

---

## ADD 解决什么问题

编码 Agent 很擅长产出改动，但“做完”的定义一旦模糊，常见问题就会反复出现：

- 代码写了，却没有运行验收命令；
- 新功能改坏了原本正常的行为；
- GUI 或人工检查在实现消息之后被遗忘；
- 同一个 bug 被连续修补，却从未重新审视方案；
- 已完成项目的经验无法带到下一个项目。

**ADD 是一个以验收标准表（`AC.md`）为核心的工作流 Skill。** 每条实现都关联到 AC，经过审查、验证，并获得清晰的状态结局。

> **v2.0 核心升级：** 更稳定的文档中枢发现、安全缓存刷新、明确的 Phase 3.5A 积压入口、更清晰的 `[!]` 验证注释，以及面向多种 Agent 的安装说明。

---

## 安装 ADD

请选择一种安装方式。请**同时安装两个 Skill**：`acceptance-driven-development` 是工作流引擎；`project-experience` 负责复用项目经验并刷新经验缓存。

### 方案一：CC Switch（推荐）

[CC Switch](https://github.com/farion1231/cc-switch) 是 Claude Code、Codex、OpenCode、Gemini CLI 等 Agent 应用的图形化管理器，可用于管理 Skill。

1. 安装并打开 CC Switch，选择你希望配置的 Agent 应用。
2. 打开 **Skills** → **Repository Management** → **Add Repository**。
3. 使用以下准确配置添加仓库：

   - 所有者：`ZeusYue`
   - 仓库名：`acceptance-driven-development-skill`
   - 分支：`main`
   - 子目录：`skills`

4. 刷新仓库列表，然后安装：
   - `acceptance-driven-development`
   - `project-experience`
5. 重启或重新加载目标 Agent 会话。

需要截图、更新方法、验证步骤和排错说明，请阅读 [CC Switch 安装指南](./docs/CCSWITCH-zh.md)。

### 方案二：手动安装

将本仓库 `skills/` 下的**两个目录**复制到 Agent 的 Skill 目录：

```text
skills/
├── acceptance-driven-development/
└── project-experience/
```

| Agent 宿主 | 常见 Skill 目录 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

例如，Codex 的最终目录应为：

```text
~/.codex/skills/
├── acceptance-driven-development/
│   ├── SKILL.md
│   ├── IMPROVEMENT-GUIDE.md
│   └── references/
└── project-experience/
    └── SKILL.md
```

不同版本或自定义配置可能使用不同的发现目录。如果你的 Agent 官方文档指定了其他 Skill 目录，应以官方目录为准，但保留这两个 Skill 文件夹的名称不变。

### 方案三：下载发行压缩包

下载仓库或 GitHub Release 压缩包，解压后按**方案二**复制即可。ADD 核心流程不依赖 Obsidian、Git 仓库或 Superpowers。

---

## 首次运行：创建或复用文档中枢

ADD 将验收标准和项目经验统一保存到一个共享的**文档中枢**（`$DOC_HUB`）中；它与代码仓库分离。

首次使用时，请让 Agent 使用 ADD 实现一个功能。如果尚未配置中枢，它会询问一个稳定的目录。推荐回答类似：

```text
~/project-docs/
```

随后 ADD 会写入 `~/.add-hub` —— 一个指向该目录的一行指针。典型结构如下：

```text
$DOC_HUB/
├── _exp_memory.md                 # 可选的经验缓存
├── ac-template.md
├── project-doc-template.md
├── project-index.md
└── <ProjectName>/
    ├── design.md                  # 新项目设计阶段创建
    ├── AC.md                      # 验收标准的单一事实来源
    └── <ProjectName>.md           # 已完成项目文档
```

**注意：** `_exp_memory.md` 是缓存，不是 Hub 身份。缓存缺失时，ADD 会在同一个 `$DOC_HUB` 内重建；不会静默换到其他文档位置。

---

## 第一次怎么使用

### 新项目

```text
使用 ADD 帮我构建一个照片浏览器。
```

ADD 会进入两个设计关卡：

1. 澄清并保存设计；
2. 起草 `AC.md`，等待你确认后按 AC 实现。

### 已有项目，AC 还有待办项

```text
使用 ADD 继续开发 ImageView。
```

ADD 会读取 `AC.md`，分类待完成条目，进入 **Phase 3.5A**，然后以 Mode A 处理已批准的积压工作。

### 项目中途新增改动

```text
增加一个贪睡按钮，使用 ADD。
```

ADD 会进入 **Phase 3.5B**：先更新 AC，提出方案，等待你的批准，再实现和验证。

---

## ADD 如何工作

### 两个实现入口

| 入口 | 适用场景 | 后续步骤 |
|---|---|---|
| **Phase 3.5A — 已批准积压入口** | 已批准的 `[ ]` / `[~]` 条目 | 做基线影响分析，然后进入 Mode A；不重复要求设计确认。 |
| **Phase 3.5B — 开发中需求变更** | 新功能、行为改变、bug 修复或改进 | 做影响分析；行为改变时更新 AC 并确认；随后进入 Mode A 或 Mode B。 |

这堵住了一个常见漏洞：首次处理积压 AC 时，也必须经过与中途改动相同的代码变更门禁。

### 8 种 AC 状态表达

| 标记 | 含义 |
|---|---|
| `[ ]` | 尚未实现 |
| `[~]` | 部分完成，剩余工作已知 |
| `[x]` | 本轮重新验证通过 |
| `[!] [manual]` | 已实现，等待用户亲手验证 |
| `[!] [affected]` | 曾通过验证，但受其他改动影响，需要重新验证 |
| `[!] [blocked]` | 当前无法验证，已记录原因和解除条件 |
| `[>]` | 用户明确推迟 |
| `[-]` | 用户明确废弃 |

### Mode A 与 Mode B

- **Mode A — 批处理：** 所有首次分类后的 AC 工作，或一个已确认变更涉及 3 条及以上 AC。AUTO 项在标记 `[x]` 前必须运行验证命令。
- **Mode B — 轻量模式：** 一个已确认的 Phase 3.5B 变更涉及 1–2 条 AC。仍然必须实现、执行 6 项审查、做影响再验证，并以 `[!] [manual]` 交给用户。

### 审查与验证闭环

每次实现都遵循：

```text
AC 范围 → 影响分析 → 实现 → 6 项审查 → 重新验证 → 更新状态
```

审查涵盖接线、安全性、保真度、状态一致性、对其他 AC 的影响和框架特定风险。若同一 AC 连续失败 3 次，ADD 会停止继续打补丁，要求你选择重新设计、带指导继续，或推迟该项。

---

## 可选增强与宿主差异

ADD 的 AC 状态机、影响分析、审查清单和验证规则是核心能力。当前宿主可提供下列可选增强：

| 可选能力 | 带来的增强 | 不可用时的 fallback |
|---|---|---|
| `brainstorming` | 深入交互式设计 | 直接逐项询问并记录需求 |
| `writing-plans` | 按文件拆分的实现计划 | 写出精简实现清单 |
| 子 Agent | 独立的批量审查 | 按 6 项清单显式自审 |
| `test-driven-development` | 测试优先的质量工作 | 添加最小可行回归测试 |
| `project-experience` | 复用历史模式和已知陷阱 | 无跨项目简报也可继续 |

不同宿主的 Skill 发现、文件工具和子 Agent 政策不同。ADD 会检查可用能力，并使用已记录的 fallback，而不是阻塞核心流程。

---

## 迁移到 v2.0

v2.0 是一次工作流契约升级；现有 `AC.md` 可以继续使用。

1. **保留现有 `~/.add-hub` 指针。** 只要 Hub 目录存在，就不再依赖 `_exp_memory.md` 是否存在。
2. **不要通过删除 `_exp_memory.md` 来刷新缓存。** 直接说“更新经验缓存”；系统会生成 `_exp_memory.md.tmp`，验证成功后才替换旧缓存。
3. **为待验证项添加注释。** 使用 `[!] [manual]`、`[!] [affected]` 或 `[!] [blocked]`。
4. **新顶级 AC 使用数字 ID。** 使用 `AC-<next integer>`，不要重编号旧条目。历史编号可以保留。
5. **更新两个 Skill。** `project-experience` 在运行时是可选项，但建议安装以启用完整经验闭环。

---

## 包含什么

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
└── AlarmClock/                    # 示例 AC 与完成后的项目文档
```

- `acceptance-driven-development` — 验收驱动实现工作流
- `project-experience` — 项目文档挖掘与缓存刷新工作流
- `projects/templates` — 可选的初始模板
- `projects/AlarmClock` — 完整示例

---

## 常见问题

**必须使用 Obsidian 吗？**
不需要。`$DOC_HUB` 就是普通目录。Obsidian 只在你希望获得笔记导航、反向链接或 Dataview 视图时才有帮助。

**必须安装 Superpowers 或使用子 Agent 吗？**
不需要。ADD 可独立运行；可选 Skill 和子 Agent 可用时会增强流程。

**ADD 会实现被推迟的 `[>]` 条目吗？**
不会。推迟是面向用户的决定，除非你明确要求，否则 ADD 不会实现它。

**为什么不能一实现就标 `[x]`？**
`[x]` 表示本轮重新验证已经通过。手工测试和环境受阻都必须以 `[!]` 保持可见，直到获得有效结局。

**可以用于已有项目吗？**
可以。把 `AC.md` 创建或导入到 `$DOC_HUB/<ProjectName>/`，再要求 Agent 使用 ADD 继续开发。

---

## 支持与贡献

- 请通过 [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues) 报告流程缺口、说明不清之处或特定 Agent 的安装问题。
- 欢迎贡献。修改工作流契约时，请同步更新相关 README、改进指南和 `tests/validate-release.ps1`。
- 对较大的流程改动，请增加明确的迁移说明，并保留缺少可选能力时的 fallback。

---

## v2.0 发行说明

- 稳定的 Hub 指针与安全、原子化的经验缓存刷新；
- 明确区分 Phase 3.5A / 3.5B；
- `[!]` 支持按注释分流验证；
- 新顶级 AC 使用单调递增 ID；
- 重写多 Agent 安装说明，并新增 CC Switch 路径；
- 项目署名更新为 **ZeusYue**。

使用 [MIT License](./LICENSE) 发布。Copyright © 2026 ZeusYue。
