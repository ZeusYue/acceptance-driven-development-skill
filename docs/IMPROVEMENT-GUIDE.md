# Skill Improvement Guide — 给未来的 Agent 和开发者

> 本文件记录 acceptance-driven-development Skill 的设计原则、已验证防线和版本演进。修改 Skill 前先阅读现行版本与长期原则。

## v2.7.1（2026-09-10）：连续激活、验收回填与代码回退

- 显式调用 ADD 且项目/目标已知时，同轮继续 Phase 0 与项目胶囊。有 AC 时恢复过渡 owner、活动计划、未完 Mode B 或经身份校验的最近完成交接；无 AC 时进入 Greenfield/重建路径。
- 同一用户消息中的验收反馈先结算，然后处理后续需求。“测试通过/全部通过”默认对应最近未结算 Manual Verification Handoff 的完整 MANUAL 批次；发出交接时给整批证据写入同一 `Last Verified` 时间戳，使聊天丢失后仍可重建范围。
- 已通过 `[x]` 跨轮持续有效；只在当前改动对可观察行为或验证路径存在具体影响点时重开，共享文件变化本身不扩大影响集。
- 代码回退使用独立条件 reference。放弃已实现新 AC 时先恢复并验证代码，再结为 `[-]`；保留需求时选择当前重做或恢复后明确延后。Mode A 来源复用原子 `supersedes_plan` 交接，Mode B 来源使用 `supersedes_plan: N/A` 并通过 AC 恢复状态和检查点定位。
- 运行时提示默认描述正向执行配方、产物结构和顺序。只对高频且高风险的纪律性失误保留必要的“不得/never”，避免用穷举负面例子稀释核心规则。

## v2.7.0（2026-09-04）：当前证据、项目胶囊与分层上下文

- 技能发现采用严格混合触发：持久项目创建和可识别项目内的行为/代码/配置/构建/部署/公共契约改动自动启用；普通问答、只读工作和无关一次性脚本须显式调用一次，作用域仅限当前连续工作单元。
- Activation Gate 位于 Phase 0 前；即使宿主误加载技能，也不得读取 Hub、全局缓存、项目胶囊或 AC。纯 Git 快照/提交和打包/哈希/tag/push/Release 属于交付操作，不新建 AC、不进入 Phase 3.5，也不改变现有验收/任务验证状态；只有实际项目改动重新进入 ADD。
- Schema 3 以 AC ID 为唯一键保存一行“当前验证证据”；新结果覆盖旧结果，`[x]` 必须对应当前 `PASS`，不再追加 EVD 历史、引用或归档。
- Mode B 验证失败经 Phase 3.5A 返回时保留原模式和目标独立尝试序列；MANUAL 等待使用 `state: pending-manual`，通过后写 `completed`。到上限前使用 `FAIL/state: failed`，到上限使用 `BLOCKED/state: blocked`，普通 `3/3` 不得经取消/拒绝恢复。
- 每个新 Agent/新会话定位 Hub 后只读一次 `_exp_memory.md`；每个独立 Mode A/Mode B 工作单元读取一次项目唯一胶囊 `_<ProjectName>_exp.md`，同一工作单元不重复读取。
- 项目胶囊最多 12 条扁平、困难、非显然、已验证经验；仅成功完成且非取代关闭的 Mode A 计划可更新经验与 `latest_completed_plan`，Mode B 不写。
- Mode A 计划新增六字段 `Agent Handoff`；最近完成计划必须匹配 worktree、branch 和 baseline 后才能用于交接。`user-cancelled` / `user-rejected` 暂停计划在显式重启前持有重叠 AC；获批取代先关闭旧 owner，再激活新计划。
- 日常上下文提取全部 AC 行，但只全文读取目标、受影响、未终结 AC 及其当前证据；模板、完整项目文档、旧计划和条件 reference 按需读取。
- Mode B 仅适用于一至两个方案确定、低风险目标；架构、依赖行为、并发、持久化、安全、迁移、公共契约和广泛共享组件强制 Mode A。
- `project-experience` 从普通编码路径退出；缓存缺失时显式研究只读降级，获批刷新只纳入 completed、非 superseded plan 支持的项目自产胶囊经验并排除全局播种项。ADD 自行读取全局缓存与项目胶囊。
- 罕见失败、阻塞、取消、拒绝、重设计和模式切换规则拆入条件恢复 reference，只在事件发生时加载。Mode A 转 Mode B 先持久化 `superseded-by-mode-b` 暂停 owner；重入时先幂等归一化计划任务所有权，再补齐 reset、恢复未完成 Mode B 或完成 ownership handback。
- 运行时预算保持严格：主技能不超过 3300 词，实施 reference 不超过 1900 词，条件恢复 reference 不超过 1300 词，典型实现加载不超过 6000 词，操作文件单行不超过 400 字符。

## v2.6.0（2026-08-11）：内置实施规划、恢复与安全检查点

- Mode A 必须创建或恢复一份持久计划；Mode B 只使用六字段聊天 Execution Map。两者都从已批准 AC 派生，且不拥有验收状态。
- 计划 schema 2 用 worktree、branch、baseline、target AC 与 `approach_ref` 识别活动计划；已完成计划永久保留，不覆盖、不重开。
- `active_tasks` 只包含 `in_progress` 任务；并行仅限文件、生成物、提交组和共享状态均不重叠的任务。
- 失败按完整“实现 → 验证 → 审查”周期计数；TEST-FIRST 预期红灯不计。v2.6.0 写入 AC EVD，v2.7.0 起改写该 AC 的当前证据行。
- 必需环境/工具不可用属于外部阻塞，不计失败周期；任务离开 `active_tasks`，独立工作继续。
- 取消或批准后拒绝先停止并汇总委派任务，再核对最终工作树；保留但未新鲜验收的实现必须是 `[~]`，两类暂停/恢复状态分别持久化。
- Mode A 转 Mode B 前结算 delegates 与旧任务所有权；Mode B 结算后，旧计划必须完成或恢复剩余工作，不能与 Mode B 并发。
- Agent 侧验证后默认创建 AC 范围本地检查点；不安全时使用 `COMMIT-BLOCKED`，用户禁用时使用 `COMMIT-SKIPPED`，绝不自动操作远端。
- 发行验证必须包含 AC/计划结构解析、直接约束技能文本的转换 fixtures、隔离 Git 场景、负面样本和运行时词数/长行预算。

## v2.5.0（2026-08-05）：ADD 与 Superpowers 解耦

- 将需求澄清、真实方案比较、一次设计批准和 Design Decision Handoff 内置为 `skills/acceptance-driven-development/references/design-exploration-and-handoff.md`，避免依赖宿主的 Skill-to-Skill 调度。
- 该 reference 不固定文档路径、不创建实施计划、不要求仓库提交、不选择 Mode A/B，也不跳转到其他方法论；仅由 ADD 在显式设计探索、Greenfield Gate 1、大型或真正含糊的 Phase 3.5B 中加载。
- 大型 Phase 3.5B 必须把设计与拟议 AC 变更一起提交一次合并批准，避免内置后产生重复 spec/AC 许可。
- ADD 删除对具名 Superpowers 技能的依赖；外部规划工具成为可选增强，无外部工具时仍由 ADD 的内置 Mode A/B 执行层拆解任务。
- 仓库与 CC Switch 应发现两个 Skill：`acceptance-driven-development` 与 `project-experience`；设计探索是 ADD 内部 reference，不是第三个 Skill。
- 本地卸载旧 Superpowers 时优先移出发现目录并保留可恢复备份，不改动无关技能。

## v2.4.2（2026-08-04）：AC 表格可读性与证据分层

- 五列 AC 表格使用可选的 Obsidian CSS 资产统一列比例并强制长文本换行。
- 表格只保存可扫描结论；完整日志、性能样本、截图说明和人工反馈写入同一份 `AC.md` 的“验证证据详情”。
- `AC.md` 仍是验收唯一事实来源，证据不会转移到实施计划或其他状态文档。
- 现有 AC 无需批量迁移；样式类和 CSS 均为兼容性增强。

## v2.4（2026-07-30）：AC 权威恢复

1. 任何压缩都不得移除模板读取、AC 结构验证、AC/计划权威边界或人工验收交接单。
2. AC 模板必须作为 `skills/acceptance-driven-development/assets/` 中的可安装资产交付；Hub 缺失时只允许复制资产，不允许凭记忆重建。
3. 任何外部计划工具只能在 AC Contract Gate 成功且范围已批准后运行；计划任务必须映射 AC-ID，计划勾选不得改变 AC 状态。
4. 对既有 AC 做迁移时，保留编号、证据、历史状态和语言；语义含糊时先询问用户。
5. 每个 `[!] [manual]` 都必须产生包含 AC-ID、前置条件、步骤、预期结果和回复格式的 Manual Verification Handoff。
6. Mode A 的进度公告、计划 Task 和子 Agent 调度都不是暂停关卡；目标 `[ ]` / `[~]` 未清空时必须连续推进，除非命中明确的 ADD 停止条件。

---

## 长期设计原则

### 触发与交付边界

自动触发必须由可观察的项目级信号支持，不能再使用泛化的“实现任何功能或 bug”描述。非项目请求允许用户显式启用，但只覆盖当前连续工作单元。交付操作改变仓库或产物状态，不等于改变验收合同；WIP 快照、打包或发布既不能创建 AC，也不能把未验证工作变成完成状态。若交付需要修改源码、构建配置、发行结构或用户可观察行为，仅这些实际改动走 Phase 3.5。

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
| `<EXTREMELY-IMPORTANT>` 标签 | FIRST RULE | 2026-07 | 比普通 Markdown 标题权重更高，用于保护唯一代码入口 |
| 合理化借口表 | FIRST RULE | 2026-07 | Agent 会用每种理由跳过规则，提前封堵每种理由 |
| Phase 3.5 硬门禁（等确认） | Phase 3.5 出口 | 2026-07 | Agent 会把「用户描述了问题」等同于「确认」，硬门禁强制等待 |
| Phase 4 出口门禁 | Phase 4 末尾 | 2026-07 | Agent 会跳过 Phase 4.8 审查直接标记 [x] |
| Phase 5 Mode B 检查 | Phase 5 | 2026-07 | Mode B 项可能漏标 [x]，Phase 5 二次检查 |
| Phase 6 硬门禁 | Phase 6 | 2026-06 | Agent 会在有 [ ] 时说「基本完成了」 |
| Mode A/B 双模式 | Phase 4 | 2026-07 | Agent 对单个改动不愿走全量扫描，Mode B 解决这个问题 |
| 风险驱动任务审查 + 批次审查 | Phase 4 / 4.8 | 2026-08 | 高风险任务优先独立审查，Mode A 仍保留最终六项批次审查 |

---

## v2.3（2026-07-20）：主技能减重

### 主文件与参考文件的边界

- `skills/acceptance-driven-development/SKILL.md` 是**操作脊柱**：只保留入口、状态机、硬门、实现模式、六项审查、新鲜验证、完成条件、活项目文档和缓存原子刷新。
- `skills/acceptance-driven-development/references/guardrails-and-examples.md` 保存合理化封堵、紧凑阶段图、完整示例、扩展红旗和可选能力图。
- `skills/acceptance-driven-development/references/change-design-guide.md` 保存变更规模、方案阶梯、行为变更/快速通道细节和三次失败后的选择。
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

- 保留 `skills/<skill-name>/SKILL.md` 作为唯一的规范仓库结构；CC Switch 用正确的仓库根 URL 与 `main` 分支能够识别 ADD 与可选的 `project-experience` 配套 Skill，不需要复制或移动目录。
- CC Switch 仓库诊断顺序固定为：仓库 URL → 分支 `main` → 刷新“发现技能” → 重新添加仓库 → 新开 Agent 会话。不要在 URL 或分支未确认前重构仓库。
- 公共文档不得假设存在“子目录”输入项；不同界面只要支持仓库 URL 和分支，就应使用仓库根 URL 与 `main`。

### README 原则

1. 先展示 ADD 如何把“已实现”变成可观察的阶段、审查和验证证据，再进入安装。
2. 安装步骤必须告诉用户安装 `acceptance-driven-development`；`project-experience` 是显式跨项目研究/缓存刷新时才需要的可选配套，并说明设计探索已内置于 ADD。
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

- 保持仓库根目录的 `skills/` 作为可安装 Skill 集合；CC Switch 使用仓库根 URL 与 `main` 分支即可递归发现两个 Skill，不依赖子目录输入项。
- README 是 GitHub 产品首页；复杂的 CC Switch UI 步骤放入 `docs/CCSWITCH.md` 和 `docs/CCSWITCH-zh.md`，避免首页被平台细节淹没。
- 每次发行前运行 `tests/validate-release.ps1`。它必须验证 README 的安装路径、CC Switch 配置、迁移说明、旧用户名清理和核心工作流契约。

### 用户文档的边界

1. 明确区分“ADD 核心能力”“可选 Skill”“宿主能力”，不要声称所有 Agent 行为完全一致。
2. 手动安装文档要求复制 ADD；`project-experience` 可按需安装用于显式跨项目研究或缓存刷新。ADD 的内置 references 随 ADD 目录一起复制。
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

### 4. 审查力度必须和执行风险一致
Mode A 执行 → 每个 AC 组按风险局部审查，高风险任务在能力可用时独立审查，最后仍做 Phase 4.8 六项批次审查。Mode B 执行 → 六项内联自审。`qt-cpp-review` 等外部审查能力只是适用时的增强项，不得成为闭环依赖。

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
4. 修复后：更新权威 AC、Vault 观测说明、README 和验证器
   ↓
5. 运行默认与负面发行验证
   ↓
6. 在发行仓库提交
   ↓
7. 运行 clean-worktree 门禁；只从干净 tag 生成 Release 包
```

---

## 文件清单

| 文件 | 用途 | 修改频率 |
|------|------|---------|
| `skills/acceptance-driven-development/SKILL.md` | 主 Skill，Agent 加载时读取 | 高（每次发现问题都改） |
| `docs/IMPROVEMENT-GUIDE.md` | 本文件，给未来的改进者，不进入运行时 Skill | 低（设计原则稳定后很少改） |
| `skills/acceptance-driven-development/references/framework-review-checklist.md` | 框架自审清单 | 低（按需增加框架） |
| `skills/acceptance-driven-development/references/implementation-planning-and-execution.md` | Mode A/B 实施、计划所有权和 Git 检查点 | 中（执行边界变化时更新） |
| `skills/acceptance-driven-development/references/failure-recovery-and-cancellation.md` | 失败序列、阻塞、取消/拒绝、重设计与模式切换 | 中（恢复状态机变化时更新） |
| `skills/acceptance-driven-development/references/code-rollback.md` | 放弃范围、实现回退、计划取代和最近有效交接 | 低（回退合同变化时更新） |
| `skills/acceptance-driven-development/assets/implementation-plan-template.md` | Mode A 固定计划资产 | 低（schema 变化时更新） |
| Vault 笔记 `Acceptance-Driven-Development Skill.md` | 设计决策记录 | 中（每次重大改动同步） |
| 发行仓库根目录 | README、安装指南、测试和 Release 包的规范来源 | 中（每次发行同步） |
