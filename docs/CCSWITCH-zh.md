# 使用 CC Switch 安装 ADD

本指南对应 CC Switch 中“仓库 URL + 分支”的技能仓库添加流程。

## 开始前

- 使用仓库根地址，不要填写单独的 `SKILL.md` URL。
- 分支必须严格为 `main`。
- 当前仓库已提供可发现的结构：

  ```text
  skills/acceptance-driven-development/SKILL.md
  skills/project-experience/SKILL.md
  ```

- 发现后请同时安装两个 Skill。

## 添加仓库

1. 选择要配置的 Agent 应用；
2. 打开 **技能 → 发现技能 → 仓库管理 → 添加技能仓库**；
3. 填写：

   ```text
   仓库 URL：https://github.com/ZeusYue/acceptance-driven-development-skill
   分支：main
   ```

4. 保存仓库记录；
5. 回到**发现技能**，如列表未立即更新则刷新扫描。

## 安装与验证

1. 安装 `acceptance-driven-development`；
2. 安装 `project-experience`；
3. 在目标 Agent 中新开会话；
4. 发送：

   ```text
   使用 ADD 实现一个小功能。
   ```

正确运行会先公告 Phase 0。已有已批准积压项随后公告 Phase 3.5A；项目中途新增改动公告 Phase 3.5B。

## 如果 CC Switch 显示 0 个技能

请按以下顺序排查：

1. 确认保存的分支逐字是 `main`；
2. 确认仓库 URL 结尾是 `acceptance-driven-development-skill`，不是文件 URL，也不是 `tree/...` 页面；
3. 添加仓库后刷新“发现技能”；
4. 已保存的分支无法修改时，删除仓库记录后用 `main` 重新添加；
5. 安装成功后重启 CC Switch 和目标 Agent；
6. 只有 URL 与分支都确认无误后，才继续排查仓库布局。

## 更新或卸载

刷新仓库扫描后，分别更新两个 ADD Skill。卸载 Skill 不会删除 `$DOC_HUB`、AC 文件、项目文档或 `~/.add-hub` 指针。

手动安装目录请见[主 README](../README-zh.md#方案二手动安装)。
