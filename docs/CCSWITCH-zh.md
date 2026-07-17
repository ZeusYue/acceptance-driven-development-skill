# 使用 CC Switch 安装 ADD

本指南说明如何通过 [CC Switch](https://github.com/farion1231/cc-switch) 从官方仓库安装 ADD。简要版本请见[主 README](../README-zh.md)。

## 开始前

- 安装 CC Switch，并确认希望配置的 Agent 应用已在 CC Switch 中可用。
- ADD 有两个 Skill 目录，请同时安装：
  - `acceptance-driven-development`
  - `project-experience`
- 当前仓库已使用适合 CC Switch 的结构：可安装 Skill 位于 `skills/` 下。不要把 CC Switch 指向单独的 `SKILL.md` 文件。

## 添加仓库

1. 在 CC Switch 中选择目标 Agent 应用。
2. 打开 **Skills**。
3. 选择 **Repository Management**。
4. 选择 **Add Repository**（不同版本可能显示为等价的自定义仓库操作）。
5. 准确填写：

   - 所有者：`ZeusYue`
   - 仓库名：`acceptance-driven-development-skill`
   - 分支：`main`
   - 子目录：`skills`

6. 保存后刷新仓库列表。

## 安装 Skill

1. 在仓库列表中找到 `acceptance-driven-development`，点击 **Install**。
2. 找到 `project-experience`，点击 **Install**。
3. 重启所选 Agent 应用，或新开一个会话，让它重新发现已安装的 Skill。

CC Switch 会把 Skill 安装到目标应用已配置的 Skill 目录。安装成功后通常不需要再手动复制文件。

## 验证安装

在目标 Agent 中发送类似请求：

```text
使用 acceptance-driven-development 实现一个小功能。
```

正确的 ADD 运行会先宣告 **Phase 0 — Locating document hub**。如果是已有且已批准的 AC 条目，随后会宣告 **Phase 3.5A**；如果是项目中途新增改动，则会宣告 **Phase 3.5B**。

若 Agent 没有发现 Skill：

1. 确认仓库配置的子目录是 `skills`，而不是 `skills/acceptance-driven-development`。
2. 在 CC Switch 中刷新仓库列表。
3. 确认两个 Skill 都显示为已安装到所选 Agent 应用。
4. 重启 Agent 应用，并新开会话。
5. 若该宿主使用自定义 Skill 目录，请遵循它的官方目录说明，并改用主 README 中的手动安装方式。

## 更新到新版 ADD

1. 在 CC Switch 中打开 **Skills**。
2. 刷新仓库列表。
3. 对已安装的 ADD Skill 使用 **Update**；也可使用 **Update All** 更新全部已安装 Skill。
4. 重启目标 Agent 会话。

升级到 v2.0 时，请同时更新两个 ADD Skill。已有 `AC.md` 仍可继续使用；第一次刷新缓存前请阅读[迁移到 v2.0](../README-zh.md#迁移到-v20)。

## 卸载 ADD

对两个 Skill 使用 CC Switch 的卸载操作。它只会删除安装到 Agent 的 Skill 副本，**不会**删除你的 `$DOC_HUB`、`AC.md`、项目文档或 `~/.add-hub` 指针。

## 手动安装 fallback

如果 CC Switch 无法管理你的宿主，请按[主 README 的手动安装说明](../README-zh.md#方案二手动安装)复制两个 Skill 目录。
