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
$codex = Join-Path $ReleaseRoot 'codex-port\CODEX-ADAPTATION.md'
$template = Join-Path $ReleaseRoot 'projects\templates\ac-template.md'
$docs = Join-Path $ReleaseRoot 'docs'
$ccSwitchGuide = Join-Path $docs 'CCSWITCH.md'
$ccSwitchGuideZh = Join-Path $docs 'CCSWITCH-zh.md'

Require-Match $add '### Phase 3\.5A: Approved Backlog Entry' 'ADD must define a Phase 3.5A entry for approved backlog work.'
Require-Match $add 'Initial triaged AC work.*Mode A' 'Initial triaged AC work must route to Mode A.'
Require-NoMatch $add '(?m)^- \*\*Yes\*\* → delete \$DOC_HUB/_exp_memory\.md' 'ADD must not delete the cache to request a refresh.'
Require-Match $add '\[!\] \[manual\]' 'ADD must define the manual [!] annotation.'
Require-Match $add '\[!\] \[affected\]' 'ADD must define the affected [!] annotation.'
Require-Match $add '\[!\] \[blocked\]' 'ADD must define the blocked [!] annotation.'
Require-Match $experience 'directory exists.*pointer is valid' 'An existing pointer directory must remain valid when its cache is absent.'
Require-Match $experience 'Forced rebuild' 'project-experience must define a forced cache rebuild path.'
Require-Match $experience '_exp_memory\.md\.tmp' 'project-experience must write a temporary cache before replacement.'
Require-NoMatch $experience 'Delete and re-run project-experience to refresh' 'project-experience must not instruct users to delete cache files.'
Require-NoMatch $readme 'demot|demotion' 'English README must not describe the retired demotion model.'
Require-NoMatch $readmeZh '降级的\\s*AC|demoted AC' 'Chinese README must not describe the retired demotion model.'
Require-NoMatch $codex '<VAULT>/projects|find ~ -maxdepth|cat "<VAULT>' 'Codex adaptation must not contain obsolete Vault/projects or Unix-only commands.'
Require-Match $codex '\$DOC_HUB' 'Codex adaptation must use the document-hub model.'
Require-Match $template 'AC-<next integer>' 'AC template must document the monotonic numeric ID scheme.'
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.0' 'English README must identify the v2.0 release.'
Require-Match $readme '## Install ADD' 'English README must have a dedicated installation section.'
Require-Match $readme '### Option 1 — CC Switch' 'English README must describe CC Switch installation.'
Require-Match $readme 'Owner: `ZeusYue`' 'English README must include the CC Switch repository owner.'
Require-Match $readme 'Subdirectory: `skills`' 'English README must include the CC Switch skills subdirectory.'
Require-Match $readme '## First Run: Create or Reuse a Document Hub' 'English README must explain the first-run document hub.'
Require-Match $readme '## Migrating to v2\.0' 'English README must include migration guidance.'
Require-Match $readme '## Support and Contributions' 'English README must include support/contribution guidance.'
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.0' 'Chinese README must identify the v2.0 release.'
Require-Match $readmeZh '## 安装 ADD' 'Chinese README must have a dedicated installation section.'
Require-Match $readmeZh '### 方案一：CC Switch' 'Chinese README must describe CC Switch installation.'
Require-Match $readmeZh '所有者：`ZeusYue`' 'Chinese README must include the CC Switch repository owner.'
Require-Match $readmeZh '## 首次运行：创建或复用文档中枢' 'Chinese README must explain the first-run document hub.'
Require-Match $readmeZh '## 迁移到 v2\.0' 'Chinese README must include migration guidance.'
Require-Match $readmeZh '## 支持与贡献' 'Chinese README must include support/contribution guidance.'
if (-not (Test-Path -LiteralPath $ccSwitchGuide)) { $failures.Add('English CC Switch installation guide must exist.') }
if (-not (Test-Path -LiteralPath $ccSwitchGuideZh)) { $failures.Add('Chinese CC Switch installation guide must exist.') }
if (Test-Path -LiteralPath $ccSwitchGuide) {
    Require-Match $ccSwitchGuide 'Owner: `ZeusYue`' 'CC Switch guide must include the repository owner.'
    Require-Match $ccSwitchGuide 'Name: `acceptance-driven-development-skill`' 'CC Switch guide must include the repository name.'
    Require-Match $ccSwitchGuide 'Branch: `main`' 'CC Switch guide must include the release branch.'
    Require-Match $ccSwitchGuide 'Subdirectory: `skills`' 'CC Switch guide must include the skills subdirectory.'
}
$publicIdentityFiles = Get-ChildItem -Recurse -File $ReleaseRoot | Where-Object { ($_.Extension -in '.md','.ps1','.txt') -or $_.Name -eq 'LICENSE' } | Where-Object { $_.FullName -notmatch '[\\\\/]tests[\\\\/]' }
$oldIdentity = $publicIdentityFiles | Select-String -Pattern 'thunderzeus036-creator' -CaseSensitive:$false
if ($oldIdentity) { $failures.Add('Public release files must not retain the former GitHub username.') }

if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) contract check(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: release workflow contracts are consistent.' -ForegroundColor Green
