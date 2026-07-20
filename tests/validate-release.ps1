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

# v2.3 README narrative, CC Switch network, and compressed-core contract.
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.3' 'English README must identify v2.3.'
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
Require-Match $readme 'Failed to create symbolic link' 'English README must include Windows symbolic-link troubleshooting.'
Require-Match $readme '~/.agents/skills' 'English README must document the shared skills storage fallback.'
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.3' 'Chinese README must identify v2.3.'
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
Require-Match $readmeZh '创建符号链接失败' 'Chinese README must include Windows symbolic-link troubleshooting.'
Require-Match $readmeZh '~/.agents/skills' 'Chinese README must document the shared skills storage fallback.'
foreach ($guide in @($ccSwitchGuide, $ccSwitchGuideZh)) {
    if (-not (Test-Path -LiteralPath $guide)) { $failures.Add("Missing CC Switch guide: $guide"); continue }
    Require-Match $guide 'main' 'CC Switch guide must include branch main.'
    Require-Match $guide 'GitHub archive' 'CC Switch guide must include archive/network diagnosis.'
    Require-NoMatch $guide 'Subdirectory:' 'CC Switch guide must not require a Subdirectory field.'
    Require-NoMatch $guide '\bmian\b' 'CC Switch guide must not include the mistyped branch.'
Require-Match $guide 'agents/skills|\.agents/skills' 'CC Switch guide must document a shared skills storage fallback.'
}

# Portable release package: no private workstation paths.
$releaseFiles = Get-ChildItem -Recurse -File $ReleaseRoot | Where-Object { ($_.Extension -in '.md','.ps1','.txt' -or $_.Name -eq 'LICENSE') -and $_.FullName -notmatch '[\\/]tests[\\/]' }
$privatePath = $releaseFiles | Select-String -Pattern 'C:\\Users\\NINGMEI|claude\\_exp_memory\.md|expectedActiveCacheHash' -CaseSensitive:$false
if ($privatePath) { $failures.Add('Release files must not reference private workstation paths or cache hashes.') }
$oldIdentity = $releaseFiles | Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' } | Select-String -Pattern 'thunderzeus036-creator' -CaseSensitive:$false
if ($oldIdentity) { $failures.Add('Public release files must not retain the former GitHub username.') }


# ADD core-skill compression contract.
$guardrailsRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\guardrails-and-examples.md'
$changeGuideRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\change-design-guide.md'
$frameworkReviewRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\framework-review-checklist.md'
$addLineCount = (Get-Content -LiteralPath $add -Encoding utf8).Count
if ($addLineCount -gt 380) { $failures.Add("ADD main skill exceeds 380-line operational budget: $addLineCount") }
foreach ($referenceFile in @($guardrailsRef, $changeGuideRef, $frameworkReviewRef)) {
    if (-not (Test-Path -LiteralPath $referenceFile)) { $failures.Add("Missing ADD compression reference: $referenceFile") }
}
Require-Match $add 'FIRST RULE' 'ADD main skill must retain FIRST RULE.'
Require-Match $add 'Phase 3\.5A: Approved Backlog Entry' 'ADD main skill must retain Phase 3.5A.'
Require-Match $add 'Phase 3\.5B: Mid-Development Requirement Changes' 'ADD main skill must retain Phase 3.5B.'
Require-Match $add 'Review checklist \(6 items' 'ADD main skill must retain six-point review.'
Require-Match $add 'Only mark `\[x\]` after FRESH verification' 'ADD main skill must retain fresh verification.'
Require-Match $add 'Living Project Document' 'ADD main skill must retain living project-document lifecycle.'
Require-Match $add 'Existing project but missing AC\.md' 'ADD main skill must distinguish a missing AC in an existing project from Greenfield.'
Require-Match $add '_exp_memory\.md\.tmp' 'ADD main skill must retain atomic cache refresh.'
Require-Match $add 'references/guardrails-and-examples\.md' 'ADD main skill must point to guardrails/examples reference.'
Require-Match $add 'references/change-design-guide\.md' 'ADD main skill must point to change-design reference.'
Require-Match $add 'approved behavior changes and eligible fast-lane work' 'ADD must let eligible fast-lane work select an implementation mode without behavioral approval.'
Require-NoMatch $add 'Mode choice after confirmed Phase 3\.5B' 'ADD must not require confirmation for every Phase 3.5B mode choice.'
Require-Match $add 'If baseline validation fails, return through the appropriate Phase 3\.5 entry to fix it before beginning Phase 4\.8 review' 'Baseline-validation fixes must not bypass Phase 3.5.'
Require-Match $add 'return through the appropriate Phase 3\.5 entry before fixing' 'ADD must route AUTO failures through the appropriate Phase 3.5 entry.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, then Phases 4–5 to a freshly verified .\[x\]' 'ADD must define the [~]-to-[x] completion transition without bypassing Phase 3.5.'
Require-Match $guardrailsRef 'Phase 3\.5A backlog work must use Mode A' 'Guardrails must preserve Mode A for approved backlog work.'
Require-NoMatch $guardrailsRef 'still enters Phase 3\.5 and Mode B' 'Guardrails must not route every one-line code change to Mode B.'
Require-Match $guardrailsRef 'behavior change or untracked bug fix has no relevant AC' 'Guardrails must not require AC updates for every fast-lane code change.'
Require-Match $add 'Code formatting or typo fixes still enter Phase 3\.5B fast lane' 'ADD must not exempt code formatting or typo fixes from Phase 3.5.'
Require-Match $add 'After an unambiguous or user-confirmed fallback choice, write `~/.add-hub`' 'ADD must persist a fallback document-hub selection.'
Require-Match $add 'after approval save it and enter Phases 1–3' 'ADD must define the Gate 2 success transition.'
Require-Match $add 'Complete Phase 4\.8: fresh baseline validation' 'Mode A must require Phase 4.8 before Phase 5.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, re-run baseline validation, then review again' 'Review fixes must re-enter Phase 3.5 and rerun baseline validation.'
Require-Match $add 'changes batching/review only; changed AUTO follows AUTO' 'Mode B must preserve AUTO command verification.'
Require-Match $add 'failed affected AUTO AC after Mode B is a regression' 'Mode B regressions must require a user repair-or-defer decision.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, then Phases 4–5' 'A [~] fix must not bypass Phase 3.5.'
Require-Match $add 'if missing, create it through Step 0\.4 first' 'Phase 6 must create a missing project document before finalization.'
Require-Match $add 'references/framework-review-checklist\.md' 'ADD must retain the framework-review reference.'
if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) contract check(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: release workflow contracts are consistent.' -ForegroundColor Green
