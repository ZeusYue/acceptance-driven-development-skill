# Skill Improvement Guide — 给未来的 Agent 和开发者

> 本文件记录 acceptance-driven-development Skill 的设计原则、已验证的防线、改进时的注意事项。如果你要修改这个 Skill，请先读完本文件。

---

## 这个 Skill 解决什么问题

Agent 开发代码时会跳过质量流程——自审、验证、标记。尤其在以下场景：
- **「简单」改动**：Agent 认为一行代码不需要流程
- **调试模式**：Agent 进入「分析→修复」快速路径后忘记流程
- **用户措辞**：Agent 把「用户描述了问题」等同于「用户确认了方案」
- **长会话**：上下文变长后，Skill 规则从 Agent 的注意力中「下沉」

Skill 的核心循环是：`AC 表有 [ ] → 做 → 验 → 标记 → 还有 [ ]？→ 继续`。所有防线都是围绕这个循环加固的，不是在核心上叠加新功能。

---

## 已验证的防线（不要轻易删除）

| 防线 | 位置 | 验证时间 | 为什么有效 |
|------|------|---------|-----------|
| `<EXTREMELY-IMPORTANT>` 标签 | FIRST RULE | 2026-07 | 比普通 Markdown 标题权重更高，参考 using-superpowers |
| 合理化借口表 | FIRST RULE | 2026-07 | Agent 会用每种理由跳过规则，提前封堵每种理由 |
| Phase 3.5 硬门禁（等确认） | Phase 3.5 出口 | 2026-07 | Agent 会把「用户描述了问题」等同于「确认」，硬门禁强制等待 |
| Phase 4 出口门禁 | Phase 4 末尾 | 2026-07 | Agent 会跳过 Phase 4.8 审查直接标记 [x] |
| Phase 5 Mode B 检查 | Phase 5 | 2026-07 | Mode B 项可能漏标 [x]，Phase 5 二次检查 |
| Phase 6 硬门禁 | Phase 6 | 2026-06 | Agent 会在有 [ ] 时说「基本完成了」 |
| Mode A/B 双模式 | Phase 4 | 2026-07 | Agent 对单个改动不愿走全量扫描，Mode B 解决这个问题 |
| 里程碑审查 | Mode B | 2026-07 | 长会话中多次轻量自审遗漏跨项交互，周期性深度审查兜底 |

---

## v2.3（2026-07-20）：主技能减重

### 主文件与参考文件的边界

- `SKILL.md` 是**操作脊柱**：只保留入口、状态机、硬门、实现模式、六项审查、新鲜验证、完成条件、活项目文档和缓存原子刷新。
- `references/guardrails-and-examples.md` 保存合理化封堵、紧凑阶段图、完整示例、扩展红旗和可选能力图。
- `references/change-design-guide.md` 保存变更规模、方案阶梯、行为变更/快速通道细节和三次失败后的选择。
- reference 可以解释和举例，但绝不能引入与主文件冲突的状态转换或例外。

### 减重原则

1. 不按“删规则”减重，而按“主文件只保留执行指令，解释移到 reference”减重。
2. 任何被移动的机制都要在 `SKILL.md` 有明确入口和 reference 路径。
3. 用发布测试约束主文件不超过 380 行，并断言 FIRST RULE、3.5A/3.5B、6 项审查、新鲜验证、活文档和缓存 `.tmp` 规则仍在主文件。
4. 压缩后优先用真实 ADD 会话验证 Agent 是否仍会宣告 Phase、等待批准、输出审查与验证证据；行数减少不等于流程有效。
5. 不得用 reference 改写主状态机：fast lane 必须能在影响分析后选择 Mode；Mode B 只改变批处理/审查方式，不能把 AUTO 降级为 MANUAL；基础验证、审查、AUTO 与 `[~]` 的失败/修复路径都必须重新经过合适的 Phase 3.5 入口。

## v2.2（2026-07-20）：问题优先叙事与网络诊断

### README 首屏原则

- 首屏先让读者认出“Agent 说完成、用户发现缺陷”的真实问题，再展示 ADD 的闭环、前后对比和 60 秒体验。
- Phase 3.5、Mode A/B、缓存 schema 等内部术语属于后半部分的可审计细节；不能替代对 ADD 整体价值的解释。
- 参考早期 README 的问题叙事、流程图、Before/After 和 Quick Start，但不能重新引入旧的 demotion、缓存删除或单文件项目模型。

### CC Switch 网络诊断

- v3.17 的源码会递归扫描仓库中的 `SKILL.md`；`skills/<skill-name>/SKILL.md` 是兼容布局，不应因为一次 0 结果就重构或复制目录。
- URL 与 `main` 分支已确认无误后，0 个技能可能表示 GitHub branch archive 下载或发现刷新暂时失败。
- 公共指南应提供 archive URL 验证、网络/代理、重启与刷新步骤；不能假定所有用户的代理配置相同。

## v2.1（2026-07-20）：可发现性与 README 叙事

### CC Switch 发现规则

- 保留 `skills/<skill-name>/SKILL.md` 作为唯一的规范仓库结构；CC Switch 用正确的仓库根 URL 与 `main` 分支能够识别两个 ADD Skill，不需要复制或移动目录。
- CC Switch 仓库诊断顺序固定为：仓库 URL → 分支 `main` → 刷新“发现技能” → 重新添加仓库 → 新开 Agent 会话。不要在 URL 或分支未确认前重构仓库。
- 公共文档不得假设存在“子目录”输入项；不同界面只要支持仓库 URL 和分支，就应使用仓库根 URL 与 `main`。

### README 原则

1. 先展示 ADD 如何把“已实现”变成可观察的阶段、审查和验证证据，再进入安装。
2. 安装步骤必须告诉用户应看到的两个技能：`acceptance-driven-development` 与 `project-experience`。
3. “0 个技能”是一个独立、可搜索的排障入口，而不是藏在 FAQ 的一句话。
4. 发行测试必须可移植：不得引用私人 Vault、缓存哈希或工作站绝对路径。

## 2026-07-20：活项目文档与缓存 schema 2

### 责任边界

- **ADD** 是项目文档生命周期的拥有者：已有代码/AC 但缺 `<ProjectName>.md` 时按模板创建；重大架构变化后更新；所有 AC 结算后最终定稿。
- **project-experience** 只读取、匹配、提炼项目文档和缓存；它绝不负责生成项目文档，避免“从缓存推测代码事实”的循环。
- `AC.md` 是验收状态的单一事实来源；项目文档不能静默修改 AC 状态。

### 缓存 schema 2

- 下一次用户明确请求刷新时才写入 schema 2；本次技能升级不得修改现有 `_exp_memory.md`。
- schema 2 记录生成日期、来源项目、来源状态、文档修改时间、条目技术标签和来源状态。
- `开发中` / `维护中` 项目可以贡献由代码、配置、测试或已解决事故直接支持的经验；计划、猜测、未验证方案不能进入缓存。
- 旧缓存无 frontmatter 时仍可按关键词读取，但应提示缺少来源元数据；强制刷新后自然迁移到 schema 2。

### 维护原则

1. 全量提炼时，所有项目文档都做轻量信息抽取；仅最相关的两份全文深读。
2. 缓存快路径最多输出 2 条 pitfalls、2 条 patterns、2 条 conventions，避免缓存成为无关上下文噪音。
3. 项目文档模板必须含 `tags`、`status`、`date`，并要求开发中项目诚实标注未确定项。

## v2.0（2026-07-17）发行与安装契约

### 发行包结构

- 保持仓库根目录的 `skills/` 作为可安装 Skill 集合；这让 CC Switch 可以通过 `Owner=ZeusYue`、`Name=acceptance-driven-development-skill`、`Branch=main`、`Subdirectory=skills` 直接发现两个 Skill。
- README 是 GitHub 产品首页；复杂的 CC Switch UI 步骤放入 `docs/CCSWITCH.md` 和 `docs/CCSWITCH-zh.md`，避免首页被平台细节淹没。
- 每次发行前运行 `tests/validate-release.ps1`。它必须验证 README 的安装路径、CC Switch 配置、迁移说明、旧用户名清理和核心工作流契约。

### 用户文档的边界

1. 明确区分“ADD 核心能力”“可选 Skill”“宿主能力”，不要声称所有 Agent 行为完全一致。
2. 手动安装文档始终要求同时复制 ADD 和 project-experience；后者运行时可选，但完整体验推荐安装。
3. `$DOC_HUB`、`~/.add-hub`、缓存刷新和 v2.0 迁移规则属于首页必需信息；框架审查细节不应塞入 README。
4. GitHub 用户名、LICENSE 署名、远程链接和 CC Switch 配置必须同时更新，避免身份漂移。

## v1.5（2026-07-17）工作流契约加固

### 已修复的设计断点

| 断点 | 新规则 | 原因 |
|------|--------|------|
| Hub 指针依赖缓存文件 | 指针目录存在即有效；缓存是独立状态 | 刷新缓存时删除 `_exp_memory.md` 会把正确的 Hub 误判为失效 |
| 首次批处理绕过 Phase 3.5 | 已批准积压走 Phase 3.5A → Mode A | “所有代码先走 3.5”与“Phase 1–3 直接 Mode A”不再矛盾 |
| `[!]` 语义混杂 | `[manual]` / `[affected]` / `[blocked]` 注释 | Phase 6 能正确区分用户测试、回归验证和环境阻塞 |
| 可选技能被写成必装 | 核心流程 + optional enhancement + host capability 三层 | 缺少子 Agent 或外部 Skill 时不能阻塞 ADD |
| 缓存刷新删除旧文件 | 强制重建写 `_exp_memory.md.tmp`，验证后替换 | 刷新失败不丢失原缓存 |

### 修改这套规则时的约束

1. 不要让新的流程绕过 Phase 3.5A 或 Phase 3.5B；二者共同构成唯一入口。
2. 不要再将 `_exp_memory.md` 当成 `$DOC_HUB` 的身份标识。
3. 不要新增第七个主状态；先用 `[!]` 的标准注释表达验证子状态。
4. 每次修改状态机、Hub 发现或跨 Agent 指南，都要运行 `tests/validate-release.ps1` 并同步 README、Codex 适配文档和 Vault 设计记录。

## 改进时的原则

### 1. 加规则前，先确认问题不是执行层的
如果 Agent 不遵守规则，先检查：
- 规则是否在 Skill 的可见位置（越靠前越可能被读到）
- 规则是否有 `<EXTREMELY-IMPORTANT>` 标签
- 是否有对应的合理化借口封堵

如果以上都有但 Agent 仍然跳过，这是 **Agent 认知架构的根本限制**，不是 Skill 能解决的。加更多规则只会让 Skill 更长，加剧遗忘。

### 2. 不要在 Phase 3.5 的豁免列表里加太多例外
每加一个「不需要 Phase 3.5」的例外，Agent 就多一条合理化路径。「性能优化不需要 Phase 3.5」就是被加回来的——Agent 会扩大解释任何例外。

### 3. Mode B 的边界要清晰
Mode B 是轻量模式，上限是 2 条 AC——≥3 条升级为 Mode A。上限曾经是 3 条，实战发现 Agent 会把中型改动（3 条）塞进轻量模式，收紧后效果更好。

### 4. 审查模式必须和执行模式一致
Mode A 执行 → Mode A 审查（qt-cpp-review 子 Agent）。Mode B 执行 → Mode B 审查（自审）。混用会导致批量执行时审查力度不足。

### 5. 每个 Phase 之间必须有显式引导
Agent 会在两个 Phase 之间迷路。每个 Phase 的出口必须有明确的「下一步是什么」指令。不要假设 Agent 会自动按顺序执行。

---

## 上下文长度的影响

当对话变长时（>50 轮），以下现象会发生：
- Agent 开始跳过 Skill 规则，尤其是 Phase 3.5 的讨论+确认
- FIRST RULE 从 Agent 的注意力中「下沉」
- Agent 会把「用户描述了问题」等同于「确认方案」

**应对方式（不在 Skill 里加规则）：**
- 用户在 Agent 说「修好了」后追问「走了 Mode B 吗？」——这是最有效的防线
- 失败阈值（3 次修不过就停下来）——换方案比继续修补更高效
- 如果用户有代码分析工具（如 codebase-memory MCP 的 trace_path），影响分析可以用工具替代手动 grep，更精准地发现跨文件的间接调用
- 未来可以考虑在 CLAUDE.md 里加一条简短提醒，让每次对话开始时 Agent 都看到

---

## 改进 Skill 的工作流程

```
1. 发现问题（用户或 Agent 报告）
   ↓
2. 分析：是规则缺失、规则位置不好、还是 Agent 合理化？
   ↓
3. 选择修复方式：
   - 规则缺失 → 加规则
   - 位置不好 → 移到更靠前的位置
   - Agent 合理化 → 加借口封堵 + <EXTREMELY-IMPORTANT> 标签
   - 根本限制 → 不改 Skill，靠用户追问
   ↓
4. 修复后：更新 Vault 笔记的设计决策表（记录「为什么」）
   ↓
5. 同步分享包：cp SKILL.md → 桌面/自动化开发skill/
```

---

## 文件清单

| 文件 | 用途 | 修改频率 |
|------|------|---------|
| `SKILL.md` | 主 Skill，Agent 加载时读取 | 高（每次发现问题都改） |
| `IMPROVEMENT-GUIDE.md` | 本文件，给未来的改进者 | 低（设计原则稳定后很少改） |
| `references/framework-review-checklist.md` | 框架自审清单 | 低（按需增加框架） |
| `references/qt-cpp-review/` | Qt 官方审查技能 | 低（跟随 Qt 官方更新） |
| Vault 笔记 `Acceptance-Driven-Development Skill.md` | 设计决策记录 | 中（每次重大改动同步） |
| 分享包 `桌面/自动化开发skill/` | 给其他人用的安装包 | 中（每次改 SKILL.md 同步） |
