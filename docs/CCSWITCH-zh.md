# 使用 CC Switch 安装 ADD

请先通过[主 README](../README-zh.md)了解 ADD 的作用，再使用本指南安装。CC Switch 可以递归发现本仓库的两个 Skill；短暂显示 0 个技能也可能是 GitHub 分支压缩包下载或发现刷新失败。

## 添加仓库

1. 选择目标 Agent 应用；
2. 打开 **技能 → 发现技能 → 仓库管理 → 添加技能仓库**；
3. 填写：

   ```text
   仓库 URL：https://github.com/ZeusYue/acceptance-driven-development-skill
   分支：main
   ```

4. 保存仓库记录；
5. 回到**发现技能**并刷新。

可发现文件为：

```text
skills/acceptance-driven-development/SKILL.md
skills/project-experience/SKILL.md
```

请同时安装两个 Skill，然后在目标 Agent 中新开会话。

## 如果发现时显示 0 个技能

1. 确认仓库 URL 结尾为 `acceptance-driven-development-skill`；
2. 确认分支严格为 `main`；
3. 刷新“发现技能”，必要时重启 CC Switch；
4. 仓库记录无法修正时，删除后重新添加。

### GitHub archive、网络与代理

CC Switch 在扫描 `SKILL.md` 前，会下载所选分支的 GitHub archive。请先在浏览器中确认以下地址可访问：

```text
https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip
```

如果无法下载：

- 切换网络，或按自身环境配置系统 / CC Switch 网络代理；
- 网络或代理修改后重启 CC Switch；
- 再次刷新“发现技能”。

若 archive 可以下载、CC Switch 仍显示 0 个技能，不应首先怀疑仓库布局：当前 archive 已含两个有效 `SKILL.md`。可先用手动安装作为临时方案，并在 Issue 中提供 CC Switch 版本、截图和 archive 下载结果。

## Windows：创建符号链接失败

出现“`创建符号链接失败：……`”这类报错时，问题通常在本地安装权限或存储位置，而不是仓库发现。

1. 打开 CC Switch **设置**，将 **Skills 存储位置**改为 `~/.agents/skills`。
2. 如果 CC Switch 提供 Skill 同步方式，选择 **Copy / 复制**，不要选择符号链接方式。
3. 重启 CC Switch，刷新**发现技能**，再重新安装两个 Skill。
4. 如果必须使用符号链接，请以**管理员身份**启动 CC Switch，或启用 Windows 开发人员模式后重试。

修改存储位置或同步方式后，所选目标 Agent 的 Skill 可能需要重新安装。

## 更新或卸载

刷新发现结果后，分别更新两个 ADD Skill。卸载不会删除 `$DOC_HUB`、AC 文件、项目文档或 `~/.add-hub` 指针。
