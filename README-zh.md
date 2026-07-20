# 验收驱动开发（ADD）v2.1

<p align="center">
  <strong>让编码 Agent 用证据证明改动有效，而不是只说“已经完成”。</strong><br>
  ADD 把每一次重要改动变成：验收契约、影响分析、审查和新鲜验证。
</p>

<p align="center">
  <a href="./README.md">English</a> ·
  <a href="#一条请求看懂-add">先看效果</a> ·
  <a href="#安装-add">安装</a> ·
  <a href="#cc-switch-显示识别到-0-个技能">排查 CC Switch</a>
</p>

---

## 为什么 ADD 会改变 Agent 开发

大多数 Agent 工作流追求“尽快产出代码”；ADD 追求的是：**什么时候才能有证据地说它真的完成了。**

| 没有 ADD | 使用 ADD |
|---|---|
| “已经实现。” | “AC-12 已执行 `ctest`，这是实际输出。” |
| 一个小修复悄悄破坏原有功能。 | 影响分析先把依赖的 AC 标为待重新验证。 |
| Agent 只在几轮对话内记得架构。 | 项目文档和经验缓存把已证实的经验带到下一个任务。 |
| GUI 功能没人真正点过就被宣布完成。 | 它保持 `[!] [manual]`，直到有人按指定步骤验证。 |
| 同一个 bug 被无限打补丁。 | 连续失败三次后，改为诊断、重设方案、寻求指导或延期。 |

ADD 不是测试框架，也不是项目管理工具。它是在你现有代码、测试、工具和判断之上增加的一层**开发工作流契约**。

---

## 一条请求看懂 ADD

对 Agent 说：

```text
给图片浏览器增加批量删除功能，使用 ADD。
```

一个正确的运行应让过程可见：

```text
Phase 3.5B — Impact analysis: bulk delete
→ 更新对应验收标准
→ 提出方案并等待批准
→ Phase 4 Mode B — 实现 1 条 AC
→ Phase 4.8 — 6 项审查
→ Phase 5 — 标为 [!] [manual] 并给出明确测试步骤
```

如果是已批准的积压 AC，Agent 应改为公告 **Phase 3.5A**，列出目标 AC，然后直接进入 Mode A；它不会要求你重复批准已经批准过的需求。

如果你看不到阶段公告、受影响 AC、审查结果或新鲜验证证据，就有具体问题可以追问，而不是只能模糊地怀疑 Agent 跳过了流程。

---

## ADD 带来什么

### 一张始终诚实的 AC 表

`AC.md` 是验收状态的单一事实来源。

| 标记 | 含义 |
|---|---|
| `[ ]` | 尚未实现 |
| `[~]` | 部分完成 |
| `[x]` | 本轮新鲜验证通过 |
| `[!] [manual]` | 已实现，等待人工验证 |
| `[!] [affected]` | 原本已通过，但受其他改动影响，需要重新验证 |
| `[!] [blocked]` | 当前无法验证，已记录原因和解除条件 |
| `[>]` | 用户明确推迟 |
| `[-]` | 用户明确废弃 |

### 可以跨会话存活的文档轨迹

```text
$DOC_HUB/<ProjectName>/
├── AC.md                  # 验收状态
├── design.md              # 新项目设计（如适用）
└── <ProjectName>.md       # 活项目架构与工程记录
```

ADD 创建和更新项目文档；`project-experience` 读取它、查找相关经验，并在后续把有证据的模式提炼到 `_exp_memory.md`。

### 对开发中项目也安全

开发中项目可以立刻记录真实代码、测试、已解决事故和架构决策。计划和不确定结论会保留可见标记，而不会过早变成“可复用经验”。

---

## ADD 如何工作

```text
已批准积压工作      → Phase 3.5A → Mode A → 审查 → 验证
开发中需求变更      → Phase 3.5B → 批准/快速通道 → Mode A 或 B → 验证
项目完成            → 定稿项目文档 → 可选的安全缓存刷新
```

- **Phase 3.5A**：处理已批准的 `[ ]` / `[~]`；
- **Phase 3.5B**：处理新功能、行为改变、bug 修复和改进；
- **Mode A**：处理首次分类后的工作和较大变更；
- **Mode B**：处理已确认的 1–2 条 AC 变更，但仍要做影响分析和 6 项审查；
- 刷新缓存不会删除旧文件：先写 `_exp_memory.md.tmp`，验证后才替换。

---

## 安装 ADD

请同时安装两个 Skill：

```text
acceptance-driven-development
project-experience
```

前者负责验收工作流；后者在宿主可用时为工作流提供跨项目经验。

### 方案一：CC Switch

以下步骤对应 CC Switch 的标准技能仓库添加流程：

1. 在 CC Switch 选择目标 Agent 应用；
2. 进入 **技能 → 发现技能 → 仓库管理 → 添加技能仓库**；
3. 填写：

   ```text
   仓库 URL：https://github.com/ZeusYue/acceptance-driven-development-skill
   分支：main
   ```

4. 添加仓库后，回到**发现技能**；必要时刷新扫描；
5. 安装：
   - `acceptance-driven-development`
   - `project-experience`
6. 在目标 Agent 中新开会话。

仓库已使用预期的扫描结构：

```text
skills/
├── acceptance-driven-development/SKILL.md
└── project-experience/SKILL.md
```

不要把 CC Switch 指向单独的 `SKILL.md` 文件。完整说明见 [CC Switch 安装指南](./docs/CCSWITCH-zh.md)。

### CC Switch 显示“识别到 0 个技能”

仓库已添加但显示 0 个技能时，按以下顺序检查：

1. **分支拼写**：必须严格是 `main`；
2. **仓库 URL**：应填写仓库根 URL，不应填写文件 URL 或 `tree/...` URL；
3. **刷新扫描**：添加后回到“发现技能”并刷新；
4. **重新添加仓库**：如果已保存的分支无法编辑，删除该仓库记录后用 `main` 重新添加；
5. **新会话**：安装后重启目标 Agent 或新开会话；
6. **版本与分支**：确认使用仓库最新发行分支，再诊断 Skill 布局。

### 方案二：手动安装

把 `skills/` 下的两个目录复制到 Agent 官方文档指定的 Skill 目录：

| Agent 宿主 | 常见 Skill 目录 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

以 Codex 为例：

```text
~/.codex/skills/
├── acceptance-driven-development/
│   ├── SKILL.md
│   └── references/
└── project-experience/
    └── SKILL.md
```

---

## 首次运行：选择文档中枢

首次收到代码相关请求时，ADD 会询问一个稳定的共享目录。推荐回答：

```text
~/project-docs/
```

它会写入 `~/.add-hub`，并将所有 AC、项目文档、模板与经验缓存保存在该中枢。Obsidian 是可选项，普通文件夹即可。

---

## 迁移到 v2.1

v2.1 保持所有 v2.0 AC 兼容，并新增：

- 开发中项目的活文档生命周期；
- 下一次用户确认刷新时使用的 schema-2 缓存元数据；
- 不依赖私人电脑路径的便携式发行测试；
- 适配真实 CC Switch URL + 分支表单的安装说明；
- 先解释价值、再进入安装步骤的 README 叙事。

既有缓存仍可读取。不要删除 `_exp_memory.md`；准备好时再要求安全更新经验缓存。

---

## 支持与贡献

- 通过 [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues) 报告流程缺口、文档问题或特定宿主的安装问题；
- 修改工作流时，请同时更新相关 Skill、reference/template 与 `tests/validate-release.ps1`；
- 保持发行测试可移植：不要把私人 Vault 路径、缓存哈希、用户名或机器专属假设写入发行包。

---

## v2.1 发行说明

- README 改为先展示收益和可观察的流程证据；
- CC Switch 安装改为当前真实的“URL + `main` 分支”表单；
- 新增“0 个技能”恢复路径；
- 将活项目文档与 schema-2 缓存契约纳入发行包；
- 保持 `skills/<skill>/SKILL.md` 的标准发现结构。

使用 [MIT License](./LICENSE) 发布。Copyright © 2026 ZeusYue。
