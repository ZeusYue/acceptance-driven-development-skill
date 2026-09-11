# 使用 CC Switch 安装 ADD

这是可选的安装器说明，通用安装方式见[主 README](../README-zh.md#安装)。CC Switch 的界面名称和安装方式可能随版本变化；当前 ADD 修订尚未覆盖验证所有 CC Switch 或目标 Agent 版本。

## 添加仓库

在 CC Switch 中选择目标 Agent，打开其技能发现或仓库管理页面，添加：

```text
仓库 URL：https://github.com/ZeusYue/acceptance-driven-development-skill
分支：main
技能目录：skills/acceptance-driven-development
```

刷新发现结果，选择 `acceptance-driven-development`。本次修订只提供一个技能，其中包含引用文件和可选模板。按宿主要求新开或重新加载目标 Agent 会话。

安装器下载的是所选远程分支。公开的 `v3.0.0` 修订位于 `main`；未来尚未发布的开发快照可能需要手动安装本地技能目录。

## 如果显示未发现技能

检查仓库根 URL 和分支，再刷新发现结果；查看安装器提供的下载或扫描错误。仅凭数量为零，无法区分网络问题、目录结构问题和安装器问题。

如果安装器使用 GitHub 分支压缩包，请检查当前环境能否访问 [main 分支压缩包](https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip)。修复网络或代理设置后重试。仍然失败时，可按 README 手动安装，并报告安装器版本、完整错误和下载结果。

## Windows 符号链接错误

检查安装方式、目标位置和具体错误。改变存储位置不会赋予符号链接权限。开发人员模式或适当的权限调整可能允许创建链接，具体以安装器和 Windows 当前配置为准。

如果安装器提供复制方式，也可以使用。确保目标 Agent 只发现预期的一份 ADD，并在技能变化时更新该副本。

## 更新

整体替换或更新已安装的 ADD 目录，包含引用文件和资产。替换前另行保留本地定制，避免已退役的引用文件留在生效副本中。

原 `project-experience` 配套技能已不属于当前包。更新 ADD 不会删除单独安装的配套技能或已有项目记录。
