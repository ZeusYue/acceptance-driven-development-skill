[CmdletBinding()]
param(
    [string]$ReleaseRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Require-Match {
    param([string]$Path, [string]$Pattern, [string]$Message)
    $content = Get-Content -Raw -LiteralPath $Path -Encoding utf8
    if ($content -notmatch $Pattern) { $failures.Add($Message) }
}

function Require-NoMatch {
    param([string]$Path, [string]$Pattern, [string]$Message)
    $content = Get-Content -Raw -LiteralPath $Path -Encoding utf8
    if ($content -match $Pattern) { $failures.Add($Message) }
}

$add = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\SKILL.md'
$experience = Join-Path $ReleaseRoot 'skills\project-experience\SKILL.md'
$readme = Join-Path $ReleaseRoot 'README.md'
$readmeZh = Join-Path $ReleaseRoot 'README-zh.md'
$ccSwitchGuide = Join-Path $ReleaseRoot 'docs\CCSWITCH.md'
$ccSwitchGuideZh = Join-Path $ReleaseRoot 'docs\CCSWITCH-zh.md'
$acTemplate = Join-Path $ReleaseRoot 'projects\templates\ac-template.md'
$projectTemplate = Join-Path $ReleaseRoot 'projects\templates\project-doc-template.md'
$skillDirs = @(
    (Join-Path $ReleaseRoot 'skills\acceptance-driven-development\SKILL.md')
    (Join-Path $ReleaseRoot 'skills\project-experience\SKILL.md')
)

# Core workflow contracts retained from v2.0.
Require-Match $add '### Phase 3\.5A: Approved Backlog Entry' 'ADD must define a Phase 3.5A entry for approved backlog work.'
Require-Match $add '### Step 0\.4 — Living Project Document' 'ADD must define the living-project-document lifecycle.'
Require-Match $add 'project-doc-template\.md.*before creating or restructuring a project document' 'ADD must require template-first project-document creation.'
Require-Match $add 'finalize the existing project document' 'ADD must finalize an existing project document.'
Require-NoMatch $add '(?m)^- \*\*Yes\*\* → delete \$DOC_HUB/_exp_memory\.md' 'ADD must not delete the cache to request a refresh.'
Require-Match $experience 'Legacy cache fallback' 'project-experience must retain a legacy-cache fallback.'
Require-Match $experience 'cache_schema: 2' 'project-experience must define cache schema 2 metadata.'
Require-Match $experience 'Development-project evidence gate' 'project-experience must define active-project evidence rules.'
Require-Match $acTemplate 'AC-<next integer>' 'AC template must document the monotonic numeric ID scheme.'
Require-Match $projectTemplate '(?m)^tags:' 'Release project template must provide tags frontmatter.'
Require-Match $projectTemplate '(?m)^status:' 'Release project template must provide status frontmatter.'
Require-Match $projectTemplate '(?m)^date:' 'Release project template must provide date frontmatter.'
foreach ($skillFile in $skillDirs) { if (-not (Test-Path -LiteralPath $skillFile)) { $failures.Add("Missing discoverable skill file: $skillFile") } }

# v2.2 README narrative and CC Switch network contract.
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.2' 'English README must identify v2.2.'
Require-Match $readme '## Your agent said “done.” You disagree.' 'English README must open with the human problem story.'
Require-Match $readme '## How ADD closes the loop' 'English README must show the ADD closed loop.'
Require-Match $readme '## Before ADD / After ADD' 'English README must include before/after proof.'
Require-Match $readme '## Try ADD in 60 seconds' 'English README must include a 60-second experience before installation.'
Require-Match $readme '## Install ADD' 'English README must retain installation instructions.'
Require-Match $readme 'Skills → Discover Skills → Repository Management → Add Skill Repository' 'English README must use the actual CC Switch discovery path.'
Require-Match $readme 'Branch: main' 'English README must require branch main.'
Require-Match $readme 'Network and proxy' 'English README must include network/proxy diagnosis.'
Require-Match $readme '0 skills found in CC Switch' 'English README must include 0-skills troubleshooting.'
Require-NoMatch $readme 'Subdirectory:' 'English README must not require a Subdirectory field.'
Require-NoMatch $readme '\bmian\b' 'English README must reject the mistyped branch.'
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.2' 'Chinese README must identify v2.2.'
Require-Match $readmeZh '## 你的 Agent 说“完成了”。你并不相信。' 'Chinese README must open with the human problem story.'
Require-Match $readmeZh '## ADD 如何闭环' 'Chinese README must show the ADD closed loop.'
Require-Match $readmeZh '## 使用 ADD 前后' 'Chinese README must include before/after proof.'
Require-Match $readmeZh '## 一条请求看懂 ADD' 'Chinese README must include a 60-second experience before installation.'
Require-Match $readmeZh '技能 → 发现技能 → 仓库管理 → 添加技能仓库' 'Chinese README must use the actual CC Switch discovery path.'
Require-Match $readmeZh '分支：main' 'Chinese README must require branch main.'
Require-Match $readmeZh '网络与代理' 'Chinese README must include network/proxy diagnosis.'
Require-Match $readmeZh '## CC Switch 显示“识别到 0 个技能”' 'Chinese README must include 0-skills troubleshooting.'
Require-NoMatch $readmeZh '子目录：' 'Chinese README must not require a Subdirectory field.'
Require-NoMatch $readmeZh '\bmian\b' 'Chinese README must reject the mistyped branch.'
foreach ($guide in @($ccSwitchGuide, $ccSwitchGuideZh)) {
    if (-not (Test-Path -LiteralPath $guide)) { $failures.Add("Missing CC Switch guide: $guide"); continue }
    Require-Match $guide 'main' 'CC Switch guide must include branch main.'
    Require-Match $guide 'GitHub archive' 'CC Switch guide must include archive/network diagnosis.'
    Require-NoMatch $guide 'Subdirectory:' 'CC Switch guide must not require a Subdirectory field.'
    Require-NoMatch $guide '\bmian\b' 'CC Switch guide must not include the mistyped branch.'
}

# Portable release package: no private workstation paths.
$releaseFiles = Get-ChildItem -Recurse -File $ReleaseRoot | Where-Object { ($_.Extension -in '.md','.ps1','.txt' -or $_.Name -eq 'LICENSE') -and $_.FullName -notmatch '[\\/]tests[\\/]' }
$privatePath = $releaseFiles | Select-String -Pattern 'C:\\Users\\NINGMEI|claude\\_exp_memory\.md|expectedActiveCacheHash' -CaseSensitive:$false
if ($privatePath) { $failures.Add('Release files must not reference private workstation paths or cache hashes.') }
$oldIdentity = $releaseFiles | Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' } | Select-String -Pattern 'thunderzeus036-creator' -CaseSensitive:$false
if ($oldIdentity) { $failures.Add('Public release files must not retain the former GitHub username.') }

if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) contract check(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: release workflow contracts are consistent.' -ForegroundColor Green
