# 验收驱动开发（ADD）v2.2

<p align="center">
  <strong>让编码 Agent 用清单和证据证明“真的完成了”。</strong><br>
  ADD 将 Agent 的代码输出变成验收标准、审查证据，以及能跨会话保留的项目经验。
</p>

<p align="center">
  <a href="./README.md">English</a> ·
  <a href="#一条请求看懂-add">先体验</a> ·
  <a href="#安装-add">安装</a> ·
  <a href="#cc-switch-显示识别到-0-个技能">CC Switch 帮助</a>
</p>

---

## 你的 Agent 说“完成了”。你并不相信。

你让 Agent 做一个功能。它写了代码，可能也能编译，然后很自信地说：**“完成了。”**

但你打开程序后发现：

- 一个按钮没有反应；
- 某个边缘情况没做；
- 需求被理解错了；
- 修复一个问题又破坏了别处；
- Agent 已经兴高采烈地进入下一个任务。

**编码 Agent 很乐观。它们产出代码的速度，通常快于证明结果满足你意图的速度。**

ADD 的目的就是补上这段差距：给 Agent 一个可见的契约，明确什么必须实现、什么必须检查、什么仍需要你的亲手确认。

---

## ADD 如何闭环

```text
你的想法
    │
    ▼
Agent 澄清需求 ─────────────────► 不再静默猜测
    │
    ▼
验收标准 AC.md ─────────────────► 你审阅要交付的契约
    │
    ▼
写代码前做影响分析 ─────────────► 保护已经可用的行为
    │
    ▼
实现 + 6 项审查 ────────────────► 代码写完不是出口
    │
    ▼
新鲜验证 / 你的测试 ────────────► [ ] → [!] → [x]
    │
    ▼
活项目文档 ─────────────────────► 下一个项目不再从零开始
```

实际规则很简单：

> 只要验收标准仍显示未实现、未验证、受阻或部分完成，Agent 就不能诚实地把功能称为“完成”。

---

## 使用 ADD 前后

| 没有 ADD | 使用 ADD |
|---|---|
| “能编译，所以完成。” | “AC-12 已运行验证命令，这是实际结果。” |
| Agent 猜你的意图。 | 行为变化先由你确认，再实现。 |
| 小修复悄悄破坏其他功能。 | 影响分析先标记受影响 AC，重新验证。 |
| GUI 功能没人真正点过就宣布完成。 | 它保持 `[!] [manual]`，直到有人按步骤测试。 |
| 同一个失败不断被打补丁。 | 失败三次后改为诊断、换方案、寻求指导或延期。 |
| 每个项目都从零开始。 | 项目文档和有证据的经验会进入下一次任务。 |

---

## 一条请求看懂 ADD

对 Agent 说：

```text
使用 ADD 构建一个照片浏览器。
```

新项目中，ADD 会提问、记录设计、起草验收标准，等待你批准后再开始实现。

已有项目中，可以说：

```text
使用 ADD 继续开发 ImageView。
```

要修改已有功能，可以说：

```text
给图片浏览器增加批量删除功能，使用 ADD。
```

你应看到阶段公告、受影响 AC、审查结果，以及新鲜命令输出或明确的用户测试清单。这就是核心：过程应当可观察，而不是神秘地“相信 Agent 做了”。

---

## 项目变大后，你得到什么

### 一张始终诚实的 AC 表

`AC.md` 是验收状态的单一事实来源。

| 标记 | 含义 |
|---|---|
| `[ ]` | 尚未实现 |
| `[~]` | 部分完成 |
| `[x]` | 本轮新鲜验证通过 |
| `[!] [manual]` | 已实现，等待人工验证 |
| `[!] [affected]` | 原本已通过，但受其他改动影响 |
| `[!] [blocked]` | 当前无法验证，已记录解除条件 |
| `[>]` | 用户明确推迟 |
| `[-]` | 用户明确废弃 |

### 一份开发中也有价值的项目记录

```text
$DOC_HUB/<ProjectName>/
├── AC.md                  # 验收状态
├── design.md              # 必要时的已批准设计
└── <ProjectName>.md       # 活架构、风险、模式和证据记录
```

ADD 负责项目文档的创建和更新；`project-experience` 读取这些文档，再把跨项目、已证实的经验提炼成紧凑缓存。

### 需要时才深入的内部流程

你不需要先背 Phase 名称才能开始使用。等你想检查细节时：

- **Phase 3.5A** 表示“安全实现已批准积压项”；
- **Phase 3.5B** 表示“安全地新增、修复或改变行为”；
- **Mode A** 是批处理，**Mode B** 是已确认的小变更；
- 两种模式都不能跳过影响分析、审查和验证。

---

## 安装 ADD

请同时安装：

```text
acceptance-driven-development
project-experience
```

前者负责验收工作流；后者在宿主支持时提供跨项目经验。

### 方案一：CC Switch

1. 选择目标 Agent 应用；
2. 进入 **技能 → 发现技能 → 仓库管理 → 添加技能仓库**；
3. 填写：

   ```text
   仓库 URL：https://github.com/ZeusYue/acceptance-driven-development-skill
   分支：main
   ```

4. 回到**发现技能**；必要时刷新；
5. 安装：
   - `acceptance-driven-development`
   - `project-experience`
6. 在目标 Agent 中新开会话。

仓库已使用 CC Switch 递归扫描的结构：

```text
skills/
├── acceptance-driven-development/SKILL.md
└── project-experience/SKILL.md
```

详细说明见 [CC Switch 安装指南](./docs/CCSWITCH-zh.md)。

### CC Switch 显示“识别到 0 个技能”

URL 和分支都正确后，0 个技能仍可能只是一次临时的 **GitHub 分支压缩包下载或发现刷新失败**，不一定是仓库布局错误。

请依次检查：

1. 仓库 URL 是根地址，不是文件 URL 或 `tree/...` URL；
2. 分支严格是 `main`；
3. 回到“发现技能”刷新扫描；
4. 重启 CC Switch 后再次刷新；
5. 已保存的记录无法修正时，删除后用 `main` 重新添加。

#### 网络与代理

CC Switch 发现仓库时需要下载 GitHub 的分支压缩包。如果 GitHub 网络访问受限或不稳定，界面可能只显示 0 个技能，而没有展示下载失败的细节。

- 用浏览器打开以下地址，确认分支压缩包可下载：

  ```text
  https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip
  ```

- 无法下载时，请切换网络，或按你的环境配置系统 / CC Switch 的网络代理；
- 网络或代理改变后，重启 CC Switch，再刷新“发现技能”；
- 若压缩包可下载但仍显示 0 个技能，可先手动安装，并在 Issue 中提供 CC Switch 版本和截图。

### 方案二：手动安装

将 `skills/` 下的两个目录复制到 Agent 官方文档指定的 Skill 目录：

| Agent 宿主 | 常见 Skill 目录 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

---

## 首次运行：选择文档中枢

首次收到代码相关请求时，ADD 会询问一个稳定的共享目录。推荐回答：

```text
~/project-docs/
```

ADD 会写入 `~/.add-hub`，并将 AC、项目文档、模板和可选经验缓存保存在其中。Obsidian 有帮助，但不是必需条件。

---

## 迁移到 v2.2

现有 AC 表保持兼容。v2.2 新增：

- 问题优先的 README 与快速体验路径；
- 在 URL / 分支检查后的 CC Switch 网络与代理排障；
- 来自 v2.1 的活项目文档与 schema-2 缓存契约；
- 不含私人电脑路径的可移植发行验证。

不要通过删除 `_exp_memory.md` 刷新缓存；准备好时要求安全更新经验缓存。

---

## 支持与贡献

- 通过 [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues) 报告流程、文档或安装问题；
- 修改工作流契约时，请同步更新 Skill、template/reference、README 与 `tests/validate-release.ps1`。

使用 [MIT License](./LICENSE) 发布。Copyright © 2026 ZeusYue。
