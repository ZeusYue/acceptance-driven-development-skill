[CmdletBinding()]
param(
    [string]$ReleaseRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ReleaseRoot)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($scriptPath)) { throw 'Cannot resolve validate-release.ps1 location.' }
    $ReleaseRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
$failures = [System.Collections.Generic.List[string]]::new()

function Require-Match {
    param([string]$Path, [string]$Pattern, [string]$Message)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing required file: $Path"); return }
    $content = Get-Content -Raw -LiteralPath $Path -Encoding utf8
    if ($content -notmatch $Pattern) { $failures.Add($Message) }
}

function Require-NoMatch {
    param([string]$Path, [string]$Pattern, [string]$Message)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing required file: $Path"); return }
    $content = Get-Content -Raw -LiteralPath $Path -Encoding utf8
    if ($content -match $Pattern) { $failures.Add($Message) }
}

$add = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\SKILL.md'
$designExploration = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\design-exploration-and-handoff.md'
$experience = Join-Path $ReleaseRoot 'skills\project-experience\SKILL.md'
$readme = Join-Path $ReleaseRoot 'README.md'
$readmeZh = Join-Path $ReleaseRoot 'README-zh.md'
$ccSwitchGuide = Join-Path $ReleaseRoot 'docs\CCSWITCH.md'
$ccSwitchGuideZh = Join-Path $ReleaseRoot 'docs\CCSWITCH-zh.md'
$acTemplate = Join-Path $ReleaseRoot 'projects\templates\ac-template.md'
$projectTemplate = Join-Path $ReleaseRoot 'projects\templates\project-doc-template.md'
$skillsRoot = Join-Path $ReleaseRoot 'skills'
$expectedSkillNames = @('acceptance-driven-development', 'project-experience')
$rootSkillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory)
$skillDirs = @($rootSkillDirs | ForEach-Object { Join-Path $_.FullName 'SKILL.md' })
$actualSkillNames = @($rootSkillDirs.Name | Sort-Object)
$skillNameDiff = @(Compare-Object ($expectedSkillNames | Sort-Object) $actualSkillNames)
if ($skillNameDiff.Count -gt 0) { $failures.Add("Discoverable skill directories must be exactly: $($expectedSkillNames -join ', ').") }

# Core workflow contracts retained from v2.0.
Require-Match $add '### Phase 3\.5A: Approved Backlog Entry' 'ADD must define a Phase 3.5A entry for approved backlog work.'
Require-Match $add '### Step 0\.4 — Living Project Document' 'ADD must define the living-project-document lifecycle.'
Require-Match $add 'project-doc-template\.md.*before creating or restructuring a project document' 'ADD must require template-first project-document creation.'
Require-Match $add 'finalize the existing project document' 'ADD must finalize an existing project document.'
Require-NoMatch $add '(?m)^- \*\*Yes\*\* → delete \$DOC_HUB/_exp_memory\.md' 'ADD must not delete the cache to request a refresh.'
Require-Match $experience 'Legacy cache fallback' 'project-experience must retain a legacy-cache fallback.'
Require-Match $experience 'cache_schema: 2' 'project-experience must define cache schema 2 metadata.'
Require-Match $experience 'Development-project evidence gate' 'project-experience must define active-project evidence rules.'
Require-Match $designExploration 'Design Decision Handoff' 'ADD design exploration must produce a bounded decision handoff.'
Require-Match $designExploration 'one final combined approval' 'Large Phase 3.5B design and AC scope must end with one final combined approval after incremental review.'
Require-Match $designExploration 'Do not present a complete design or any proposed AC row while a material decision remains unanswered' 'Design exploration must not skip unresolved material questions by drafting the whole design or AC delta.'
Require-Match $designExploration 'Present one section per turn' 'Design exploration must validate design sections incrementally.'
Require-Match $designExploration 'stable decision label such as `D-1`, `D-2`' 'Incremental design sections must remain individually addressable.'
Require-Match $designExploration 'present one proposed AC addition or edit per turn by default' 'Phase 3.5B must make each proposed AC independently reviewable.'
Require-Match $designExploration 'Batch multiple design sections or AC rows only when the user explicitly requests batch review' 'Batch design or AC review must be user-selected rather than the default.'
Require-Match $designExploration 'after every design section and proposed AC row is individually confirmed' 'Final Phase 3.5B approval must follow incremental design and AC review.'
Require-Match $designExploration 'Gate 1' 'ADD design exploration must preserve the Greenfield Gate 1 entry.'
Require-Match $designExploration 'Phase 3\.5B' 'ADD design exploration must preserve the large-change entry.'
Require-NoMatch $designExploration 'docs/superpowers|writing-plans|test-driven-development|using-superpowers' 'ADD design exploration must not depend on Superpowers paths or skills.'
Require-NoMatch $designExploration '(?i)commit the design|commit the spec|git commit' 'ADD design exploration must not force a Git commit.'
Require-Match $acTemplate 'AC-<next integer>' 'AC template must document the monotonic numeric ID scheme.'
Require-Match $projectTemplate '(?m)^tags:' 'Release project template must provide tags frontmatter.'
Require-Match $projectTemplate '(?m)^status:' 'Release project template must provide status frontmatter.'
Require-Match $projectTemplate '(?m)^date:' 'Release project template must provide date frontmatter.'
foreach ($skillFile in $skillDirs) {
    if (-not (Test-Path -LiteralPath $skillFile)) { $failures.Add("Missing discoverable skill file: $skillFile"); continue }
    $directoryName = Split-Path -Leaf (Split-Path -Parent $skillFile)
    Require-Match $skillFile "(?m)^name: $([regex]::Escape($directoryName))\r?$" "Skill frontmatter name must match directory: $directoryName"
}

function Invoke-TestGit {
    param([string]$Repository, [string[]]$Arguments)
    $output = @(& git -C $Repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed in ${Repository}: $($output -join [Environment]::NewLine)" }
    return $output
}

function New-CheckpointTestRepository {
    param([string]$Parent, [string]$Name)
    $repository = Join-Path $Parent $Name
    New-Item -ItemType Directory -Path $repository -Force | Out-Null
    Invoke-TestGit $repository @('init', '--quiet') | Out-Null
    Invoke-TestGit $repository @('config', 'user.email', 'add-validator@example.invalid') | Out-Null
    Invoke-TestGit $repository @('config', 'user.name', 'ADD Validator') | Out-Null
    Set-Content -LiteralPath (Join-Path $repository 'task.txt') -Value 'baseline' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $repository 'user.txt') -Value 'baseline' -Encoding utf8
    Invoke-TestGit $repository @('add', '--', 'task.txt', 'user.txt') | Out-Null
    Invoke-TestGit $repository @('commit', '--quiet', '-m', 'baseline') | Out-Null
    return $repository
}

function Test-GitCheckpointIsolation {
    param([System.Collections.Generic.List[string]]$FailureList)
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $FailureList.Add('Git checkpoint scenarios require git on PATH.')
        return
    }

    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $testRoot = Join-Path $tempBase ("add-checkpoint-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    try {
        $clean = New-CheckpointTestRepository $testRoot 'clean'
        Add-Content -LiteralPath (Join-Path $clean 'task.txt') -Value 'agent change' -Encoding utf8
        Invoke-TestGit $clean @('add', '--', 'task.txt') | Out-Null
        $cleanStaged = @((Invoke-TestGit $clean @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if (($cleanStaged.Count -ne 1) -or ($cleanStaged[0] -ne 'task.txt')) {
            $FailureList.Add('Clean checkpoint scenario must stage only the Agent-owned target.')
        }

        $unrelated = New-CheckpointTestRepository $testRoot 'unrelated-dirty'
        Add-Content -LiteralPath (Join-Path $unrelated 'user.txt') -Value 'pre-existing user change' -Encoding utf8
        $unrelatedBaseline = @(Invoke-TestGit $unrelated @('status', '--short'))
        Add-Content -LiteralPath (Join-Path $unrelated 'task.txt') -Value 'agent change' -Encoding utf8
        Invoke-TestGit $unrelated @('add', '--', 'task.txt') | Out-Null
        $unrelatedStaged = @((Invoke-TestGit $unrelated @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        $unrelatedUnstaged = @((Invoke-TestGit $unrelated @('diff', '--name-only')) | Where-Object { $_ })
        if (($unrelatedBaseline -notmatch 'user\.txt') -or ($unrelatedStaged -notcontains 'task.txt') -or ($unrelatedStaged -contains 'user.txt') -or ($unrelatedUnstaged -notcontains 'user.txt')) {
            $FailureList.Add('Unrelated-dirty checkpoint scenario must preserve the user file outside the staged Agent change.')
        }

        $targetDirty = New-CheckpointTestRepository $testRoot 'target-pre-dirty'
        Add-Content -LiteralPath (Join-Path $targetDirty 'task.txt') -Value 'pre-existing user change' -Encoding utf8
        $targetBaseline = @(Invoke-TestGit $targetDirty @('status', '--short'))
        $targetWasDirty = @($targetBaseline | Where-Object { $_ -match 'task\.txt$' }).Count -gt 0
        if (-not $targetWasDirty) {
            $FailureList.Add('Target-pre-dirty checkpoint scenario must detect COMMIT-BLOCKED before Agent staging.')
        }

        $preStaged = New-CheckpointTestRepository $testRoot 'pre-staged-index'
        Add-Content -LiteralPath (Join-Path $preStaged 'user.txt') -Value 'pre-staged user change' -Encoding utf8
        Invoke-TestGit $preStaged @('add', '--', 'user.txt') | Out-Null
        $cachedBaseline = @((Invoke-TestGit $preStaged @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if ($cachedBaseline -notcontains 'user.txt') {
            $FailureList.Add('Pre-staged-index checkpoint scenario must detect COMMIT-BLOCKED before Agent staging.')
        }
    }
    catch {
        $FailureList.Add("Git checkpoint scenario failed: $($_.Exception.Message)")
    }
    finally {
        $resolvedRoot = [IO.Path]::GetFullPath($testRoot)
        if ($resolvedRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedRoot)) {
            Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
        }
    }
}

$gitMetadata = Join-Path $ReleaseRoot '.git'
if (Test-Path -LiteralPath $gitMetadata) {
    $untrackedReleaseFiles = @(& git -C $ReleaseRoot status --porcelain --untracked-files=all | Where-Object { $_.StartsWith('?? ') })
    if ($untrackedReleaseFiles.Count -gt 0) { $failures.Add("Release validation cannot pass with untracked files: $($untrackedReleaseFiles -join ', ')") }
}

# v2.3 README narrative, CC Switch network, and compressed-core contract.
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.5\.0' 'English README must identify v2.5.0.'
Require-Match $readme '## Your agent said “done.” You disagree.' 'English README must open with the human problem story.'
Require-Match $readme '## How ADD closes the loop' 'English README must show the ADD closed loop.'
Require-Match $readme '## Before ADD / After ADD' 'English README must include before/after proof.'
Require-Match $readme '## Try ADD in 60 seconds' 'English README must include a 60-second experience before installation.'
Require-Match $readme '## Install ADD' 'English README must retain installation instructions.'
Require-Match $readme 'AC Authority Restoration' 'English README must explain the v2.4 AC-authority change.'
Require-Match $readme 'Readable AC tables and evidence details' 'English README must explain the v2.4.2 table-readability change.'
Require-Match $readme 'Built-in ADD design exploration' 'English README must explain the v2.5.0 built-in design change.'
Require-Match $readme 'Install both skills' 'English README must instruct users to install both discoverable skills.'
Require-NoMatch $readme '(?m)^add-brainstorming\r?$|skills/add-brainstorming' 'English README must not install the retired standalone design skill.'
Require-Match $readme 'plans never own acceptance status' 'English README must keep plans subordinate to AC.md.'
Require-Match $readme 'Skills → Discover Skills → Repository Management → Add Skill Repository' 'English README must use the actual CC Switch discovery path.'
Require-Match $readme 'Branch: main' 'English README must require branch main.'
Require-Match $readme 'Network and proxy' 'English README must include network/proxy diagnosis.'
Require-Match $readme '0 skills found in CC Switch' 'English README must include 0-skills troubleshooting.'
Require-NoMatch $readme 'Subdirectory:' 'English README must not require a Subdirectory field.'
Require-NoMatch $readme '\bmian\b' 'English README must reject the mistyped branch.'
Require-Match $readme 'Failed to create symbolic link' 'English README must include Windows symbolic-link troubleshooting.'
Require-Match $readme '~/.agents/skills' 'English README must document the shared skills storage fallback.'
Require-Match $readme 'Prefer symbolic links when they work' 'English README must prefer symbolic links to avoid duplicate skills.'
Require-Match $readme 'Copy is only a temporary fallback' 'English README must limit Copy to a duplicate-prone fallback.'
Require-Match $readme 'changing storage alone does not grant symbolic-link permission' 'English README must distinguish storage location from sync permission.'
Require-Match $readme 'Copy synchronization method' 'English README must name the explicit Copy fallback setting.'
Require-NoMatch $readme 'prefer \*\*Copy\*\* instead' 'English README must not recommend Copy ahead of symbolic links.'
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.5\.0' 'Chinese README must identify v2.5.0.'
Require-Match $readmeZh '## 你的 Agent 说“完成了”。你并不相信。' 'Chinese README must open with the human problem story.'
Require-Match $readmeZh '## ADD 如何闭环' 'Chinese README must show the ADD closed loop.'
Require-Match $readmeZh '## 使用 ADD 前后' 'Chinese README must include before/after proof.'
Require-Match $readmeZh '## 一条请求看懂 ADD' 'Chinese README must include a 60-second experience before installation.'
Require-Match $readmeZh 'AC 权威恢复' 'Chinese README must explain the v2.4 AC-authority change.'
Require-Match $readmeZh 'AC 表格可读性与证据详情' 'Chinese README must explain the v2.4.2 table-readability change.'
Require-Match $readmeZh 'ADD 内置设计探索' 'Chinese README must explain the v2.5.0 built-in design change.'
Require-Match $readmeZh '请安装以下两个 Skill' 'Chinese README must instruct users to install both discoverable skills.'
Require-NoMatch $readmeZh '(?m)^add-brainstorming\r?$|skills/add-brainstorming' 'Chinese README must not install the retired standalone design skill.'
Require-Match $readmeZh '计划永远不拥有验收状态' 'Chinese README must keep plans subordinate to AC.md.'
Require-Match $readmeZh '技能 → 发现技能 → 仓库管理 → 添加技能仓库' 'Chinese README must use the actual CC Switch discovery path.'
Require-Match $readmeZh '分支：main' 'Chinese README must require branch main.'
Require-Match $readmeZh '网络与代理' 'Chinese README must include network/proxy diagnosis.'
Require-Match $readmeZh '## CC Switch 显示“识别到 0 个技能”' 'Chinese README must include 0-skills troubleshooting.'
Require-NoMatch $readmeZh '子目录：' 'Chinese README must not require a Subdirectory field.'
Require-NoMatch $readmeZh '\bmian\b' 'Chinese README must reject the mistyped branch.'
Require-Match $readmeZh '创建符号链接失败' 'Chinese README must include Windows symbolic-link troubleshooting.'
Require-Match $readmeZh '~/.agents/skills' 'Chinese README must document the shared skills storage fallback.'
Require-Match $readmeZh '符号链接可正常创建时应优先使用' 'Chinese README must prefer symbolic links to avoid duplicate skills.'
Require-Match $readmeZh 'Copy / 复制仅作为临时兜底' 'Chinese README must limit Copy to a duplicate-prone fallback.'
Require-Match $readmeZh '只修改存储位置不会授予符号链接权限' 'Chinese README must distinguish storage location from sync permission.'
Require-Match $readmeZh '同步方式改为 Copy' 'Chinese README must name the explicit Copy fallback setting.'
Require-NoMatch $readmeZh '优先选择 \*\*Copy / 复制\*\*' 'Chinese README must not recommend Copy ahead of symbolic links.'
foreach ($guide in @($ccSwitchGuide, $ccSwitchGuideZh)) {
    if (-not (Test-Path -LiteralPath $guide)) { $failures.Add("Missing CC Switch guide: $guide"); continue }
    Require-Match $guide 'main' 'CC Switch guide must include branch main.'
    Require-Match $guide 'GitHub archive' 'CC Switch guide must include archive/network diagnosis.'
    Require-NoMatch $guide 'Subdirectory:' 'CC Switch guide must not require a Subdirectory field.'
    Require-NoMatch $guide '\bmian\b' 'CC Switch guide must not include the mistyped branch.'
Require-Match $guide 'agents/skills|\.agents/skills' 'CC Switch guide must document a shared skills storage fallback.'
Require-Match $guide 'symbolic links when they work|符号链接可正常创建时应优先使用' 'CC Switch guides must prefer symbolic links when they work.'
Require-Match $guide 'temporary fallback|临时兜底' 'CC Switch guides must limit Copy to a fallback.'
Require-Match $guide 'changing storage alone does not grant symbolic-link permission|只修改存储位置不会授予符号链接权限' 'CC Switch guides must distinguish storage location from sync permission.'
Require-Match $guide 'Copy synchronization method|同步方式改为 Copy' 'CC Switch guides must name the explicit Copy fallback setting.'
Require-NoMatch $guide 'skills/add-brainstorming/SKILL\.md' 'CC Switch guides must not list the retired standalone design skill.'
Require-Match $guide 'both skills|两个 Skill' 'CC Switch guides must describe two discoverable skills.'
Require-NoMatch $guide 'all three skills|三个 Skill' 'CC Switch guides must not retain the temporary three-skill count.'
}

# Portable release package: no private workstation paths.
$releaseFiles = Get-ChildItem -Recurse -File $ReleaseRoot | Where-Object { ($_.Extension -in '.md','.ps1','.txt' -or $_.Name -eq 'LICENSE') -and $_.FullName -notmatch '[\\/]tests[\\/]' }
$privatePatterns = @(
    '[A-Z]:\\Users\\[^\\\s]+\\'
    '[A-Z]:/Users/[^/\s]+/'
    '/Users/[^/\s]+/'
    '/home/[^/\s]+/'
    'claude\\_exp_memory\.md'
    'expectedActiveCacheHash'
)
$privatePath = $releaseFiles | Select-String -Pattern $privatePatterns -CaseSensitive:$false
if ($privatePath) { $failures.Add('Release files must not reference private workstation paths or cache hashes.') }
$oldIdentity = $releaseFiles | Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' } | Select-String -Pattern 'thunderzeus036-creator' -CaseSensitive:$false
if ($oldIdentity) { $failures.Add('Public release files must not retain the former GitHub username.') }


# ADD core-skill compression contract.
$guardrailsRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\guardrails-and-examples.md'
$changeGuideRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\change-design-guide.md'
$frameworkReviewRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\framework-review-checklist.md'
$acContractRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\ac-contract-and-plan-boundary.md'
$implementationRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\implementation-planning-and-execution.md'
$acAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-template.md'
$acAssetZh = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-template-zh.md'
$implementationPlanAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\implementation-plan-template.md'
$acTableCss = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-document-tables.css'
$projectDocAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-doc-template.md'
$projectIndexAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-index.md'
$addLineCount = (Get-Content -LiteralPath $add -Encoding utf8).Count
$designExplorationLineCount = (Get-Content -LiteralPath $designExploration -Encoding utf8).Count
$implementationRefLineCount = (Get-Content -LiteralPath $implementationRef -Encoding utf8).Count
if ($addLineCount -gt 380) { $failures.Add("ADD main skill exceeds 380-line operational budget: $addLineCount") }
if ($designExplorationLineCount -gt 120) { $failures.Add("ADD design exploration exceeds 120-line conditional-reference budget: $designExplorationLineCount") }
if ($implementationRefLineCount -gt 140) { $failures.Add("ADD implementation reference exceeds 140-line conditional-reference budget: $implementationRefLineCount") }
foreach ($referenceFile in @($guardrailsRef, $changeGuideRef, $frameworkReviewRef, $acContractRef, $designExploration, $implementationRef)) {
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
Require-Match $add 'count approved target ACs after the persistence boundary' 'ADD must select implementation mode only after approved AC persistence.'
Require-NoMatch $add 'Mode choice after confirmed Phase 3\.5B' 'ADD must not require confirmation for every Phase 3.5B mode choice.'
Require-Match $add 'If baseline validation fails, return through the appropriate Phase 3\.5 entry to fix it before beginning Phase 4\.8 review' 'Baseline-validation fixes must not bypass Phase 3.5.'
Require-Match $add 'A repair within the approved AC and approach returns through Phase 3\.5A without reapproval' 'ADD must route same-scope AUTO repairs through approved backlog without duplicate approval.'
Require-Match $add 'Settle `\[~\]`: fix through the appropriate Phase 3\.5 entry' 'ADD must define the [~]-to-[x] completion transition without bypassing Phase 3.5.'
Require-Match $guardrailsRef 'Phase 3\.5A backlog work must use Mode A' 'Guardrails must preserve Mode A for approved backlog work.'
Require-NoMatch $guardrailsRef 'still enters Phase 3\.5 and Mode B' 'Guardrails must not route every one-line code change to Mode B.'
Require-Match $guardrailsRef 'A code change has no relevant AC' 'Guardrails must require a confirmed tracking AC for every code change.'
Require-Match $add 'Code formatting or typo fixes still enter Phase 3\.5B fast lane' 'ADD must not exempt code formatting or typo fixes from Phase 3.5.'
Require-Match $add 'After validation or user confirmation, write `~/.add-hub`' 'ADD must persist only a validated or confirmed fallback document-hub selection.'
Require-Match $add 'after approval save it and enter Phases 1–3' 'ADD must define the Gate 2 success transition.'
Require-Match $add 'Complete Phase 4\.8: fresh baseline validation' 'Mode A must require Phase 4.8 before Phase 5.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, re-run baseline validation, then review again' 'Review fixes must re-enter Phase 3.5 and rerun baseline validation.'
Require-Match $add 'changes batching/review only; changed AUTO follows AUTO' 'Mode B must preserve AUTO command verification.'
Require-Match $add 'failed affected AUTO AC after Mode B is a regression' 'Mode B regressions must require a user repair-or-defer decision.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, then Phases 4–5' 'A [~] fix must not bypass Phase 3.5.'
Require-Match $add 'if missing, create it through Step 0\.4 first' 'Phase 6 must create a missing project document before finalization.'
Require-Match $add 'references/framework-review-checklist\.md' 'ADD must retain the framework-review reference.'
foreach ($assetFile in @($acAsset, $acAssetZh, $acTableCss, $projectDocAsset, $projectIndexAsset, $implementationPlanAsset)) {
    if (-not (Test-Path -LiteralPath $assetFile)) { $failures.Add("Missing installable ADD asset: $assetFile") }
}
Require-Match $add 'AC Contract Gate' 'ADD must define an AC Contract Gate before planning or code.'
Require-Match $add 'AC.?md.? is the sole source of truth' 'ADD must make AC.md the sole acceptance/state authority.'
Require-Match $add 'external planning tool may start only after' 'ADD must prevent plans from preceding a valid AC.'
Require-Match $add 'Acceptance Mapping' 'ADD plans must map every task to AC IDs.'
Require-Match $add 'external planning tool' 'ADD must express planning as a generic optional capability.'
Require-NoMatch $add 'writing-plans|test-driven-development|verification-before-completion|finishing-a-development-branch|using-superpowers' 'ADD must not depend on named Superpowers skills.'
Require-Match $add 'references/design-exploration-and-handoff\.md' 'ADD must directly load its built-in design-exploration reference.'
Require-Match $add 'Present one proposed criterion per turn by default' 'Gate 2 must make each proposed AC independently reviewable.'
Require-Match $add 'validate material questions, design sections, and proposed AC rows incrementally' 'Large Phase 3.5B changes must use progressive design review.'
Require-NoMatch $add 'add-brainstorming' 'ADD must not depend on the retired standalone design skill.'
if (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'skills\brainstorming')) { $failures.Add('Legacy skills/brainstorming path must not remain in the ADD release.') }
if (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'skills\add-brainstorming')) { $failures.Add('Retired skills/add-brainstorming path must not remain in the ADD release.') }
Require-Match $add 'proceed to Gate 2 AC drafting without asking a separate permission' 'Gate 1 must not add a duplicate permission after design approval.'
Require-NoMatch $add 'wait for the user to approve AC creation' 'Gate 1 must not retain the old duplicate AC-creation permission.'
Require-Match $add 'Manual Verification Handoff' 'ADD must require a structured manual-verification handoff.'
Require-Match $add 'A phase announcement or progress update is not a decision gate' 'ADD must prevent progress updates from becoming pause gates.'
Require-Match $add 'Do not stop after a plan task' 'ADD must prevent plan-task pauses in active Mode A work.'
Require-Match $add 'Only stop the batch for an explicit ADD gate' 'ADD must define the bounded Mode A stop conditions.'
Require-Match $add 'A blocked AC stops only itself' 'ADD must continue independent Mode A work when one AC is blocked.'
Require-Match $add 'No `\[ \]` or `\[~\]` items' 'ADD must not ignore a document containing only partial ACs.'
Require-Match $add 'unsaved five-column recovery draft' 'Existing-project AC reconstruction must remain a draft until approval.'
Require-Match $add 'rejection/cancellation leaves `AC\.md` unchanged' 'Phase 3.5B rejection must not persist unapproved scope.'
Require-Match $add 'edited target whose previous `\[x\]` criterion, verification, or expected result changed becomes `\[~\]`' 'An approved behavior delta must invalidate a stale verified target before code.'
Require-Match $add 'change to `\[ \]` if untouched or `\[~\]` if partial implementation remains, then enter Phase 3\.5A' 'A resumed deferred AC must have an explicit transition back to executable backlog.'
Require-Match $add 'approved edit that resumes a `\[>\]` target changes it to `\[ \]` if untouched or `\[~\]` if partial implementation remains' 'A changed-scope deferred AC must leave deferred status after Phase 3.5B approval.'
Require-Match $add 'do not write it first' 'Untracked fast-lane work must confirm its tracking AC before persistence.'
Require-Match $add 'A vague check fails this gate' 'Vague MANUAL criteria must fail the AC Contract Gate.'
Require-Match $add 'On `AC-N failed:' 'ADD must define a failed manual-verification transition.'
Require-Match $add 'only after explicit user confirmation of deferral or deprecation' 'ADD must not defer or deprecate partial ACs unilaterally.'
Require-Match $add 'tracked fast-lane bug.*target `\[x\]` row to `\[~\]`' 'A known tracked bug must invalidate its formerly verified target AC.'
Require-Match $add 'When the condition clears, reclassify through Phase 3' 'Blocked ACs must define an unblock transition.'
Require-Match $changeGuideRef 'Never restore `\[x\]` from historical status alone' 'Deferral after code attempts must not fabricate a verified state.'
Require-Match $designExploration 'explicit user request for ADD design exploration always loads' 'Explicit ADD exploration must override normal reference skip rules.'
Require-Match $designExploration 'apply the approved AC delta.*before mode selection or code' 'Approved large-change scope must persist before implementation.'
Require-Match $add 'references/ac-contract-and-plan-boundary\.md' 'ADD must link its AC-contract reference.'
Require-Match $add 'references/implementation-planning-and-execution\.md' 'ADD must load its implementation planning and execution reference.'
Require-Match $add 'assets/implementation-plan-template\.md.*\$DOC_HUB/<Project>/plans/' 'Mode A must copy the installed plan asset before code.'
Require-Match $add 'Execution Map.*do not create a persistent plan' 'Mode B must use a chat-only Execution Map.'
Require-Match $add 'without asking for plan approval' 'ADD must not make users review implementation plans.'
Require-Match $add 'safe local AC-scoped checkpoint' 'Both implementation modes must create safe local checkpoints.'
Require-Match $add 'existing document may retain its legacy Change Log until a separately approved migration' 'The new scope-decision schema must not block unmigrated existing AC documents.'
Require-Match $add 'append `Evidence: EVD-\.\.\.`.*How to Verify cell without replacing' 'ADD must specify where evidence citations live without destroying reusable verification commands.'
Require-Match $add 'task/AC reaches the three-attempt boundary' 'The AC verification classes must cover implementation-exhaustion blocks.'
Require-Match $add 'create a fixed EVD event.*append its citation.*only then mark `\[x\]`' 'Fresh AUTO success must persist evidence before acceptance completion.'
Require-Match $add 'blocked AC may instead become `\[>\]` or `\[-\]`' 'Explicit deferral or deprecation must settle a blocked AC.'
Require-Match $implementationRef 'Target AC.*Files.*Implementation steps.*Verification.*Review.*Commit' 'Mode B Execution Map must contain all six fields.'
Require-Match $implementationRef 'Status.*AC mapping.*Depends on.*Files.*Interfaces.*Steps.*Test strategy.*Verification.*Review.*Commit.*Evidence' 'Mode A tasks must contain the fixed Agent-oriented schema.'
Require-Match $implementationRef 'TEST-FIRST.*CHARACTERIZATION.*TEST-AFTER.*MANUAL' 'Implementation tasks must use the four approved test strategies.'
Require-Match $implementationRef 'without asking for plan approval' 'Plans must self-check and execute without user review.'
Require-Match $implementationRef 'three consecutive fail' 'Task failures must use the three-attempt boundary.'
Require-Match $implementationRef 'Mode A the counter belongs to one `PLAN-N`; in Mode B it belongs to the target AC' 'Failure counters must use explicit mode-specific units.'
Require-Match $implementationRef 'mapped unsettled AC `\[!\] \[blocked\]`' 'Three failed attempts must create an authoritative blocked AC transition.'
Require-Match $implementationRef 'Re-read authoritative `AC\.md`.*active plan.*`git status`.*recent local commits' 'Cross-session recovery must reconcile AC, plan, and Git evidence.'
Require-Match $implementationRef 'Mode B has no persistent plan.*If the approach cannot be reconstructed confidently' 'Mode B recovery must not guess a lost approved approach.'
Require-Match $implementationRef 'exactly one additional guided attempt.*approved material approach redesign starts.*series at zero' 'Failure recovery must define guided and redesigned attempt counters.'
Require-Match $implementationRef 'user cancels active implementation.*preserve the working tree, index, and existing local commits' 'Cancellation must preserve user and repository state by default.'
Require-Match $implementationRef 'COMMIT-BLOCKED' 'Unsafe local commits must report COMMIT-BLOCKED.'
Require-Match $implementationRef 'stage only Agent-owned paths or safely separable hunks' 'Local commits must isolate Agent-owned changes.'
Require-Match $implementationRef 'Never use broad staging such as `git add -A`' 'Local commits must forbid broad staging with unrelated changes.'
Require-Match $implementationRef 'index is pre-populated.*merge/rebase/cherry-pick is active' 'Local commits must block on unsafe index or repository operation state.'
Require-Match $implementationRef 'COMMIT-SKIPPED: user instruction' 'Explicit user no-commit instructions must override automatic checkpoints.'
Require-Match $implementationRef 'A MANUAL AC may be committed after all available Agent-side checks pass' 'MANUAL work must permit a local checkpoint before user verification.'
Require-Match $implementationRef 'completes a full AC or tightly related AC group' 'Local checkpoints must not split an incomplete AC across commits.'
Require-Match $implementationRef 'Permanently retain completed plans' 'Completed Mode A plans must be retained.'
Require-Match $implementationPlanAsset '(?m)^template: add-implementation-plan\r?$' 'Plan asset must declare its template type.'
Require-Match $implementationPlanAsset '(?m)^mode: A\r?$' 'Persistent plan asset must be Mode A only.'
Require-Match $implementationPlanAsset 'Acceptance Mapping' 'Plan asset must map tasks to AC IDs.'
Require-Match $implementationPlanAsset '(?s)Status:.*AC mapping:.*Depends on:.*Files:.*Interfaces:.*Steps:.*Test strategy:.*Verification:.*Review:.*Commit:.*Evidence:' 'Plan asset must include every required PLAN-N field.'
Require-Match $implementationPlanAsset '(?s)Last safe commit.*Working tree baseline.*Blocked tasks.*Next ready task' 'Plan asset must include recovery fields.'
Require-Match $acAsset 'AC-<next integer>' 'English AC asset must require monotonic AC IDs.'
Require-Match $acAsset 'Status Summary' 'English AC asset must include a status summary.'
Require-Match $acAsset '(?m)^cssclasses: ac-document\r?$' 'English AC asset must opt into the readable-table style.'
Require-Match $acAsset 'Verification Evidence Details' 'English AC asset must keep lengthy evidence outside status-table cells.'
Require-Match $acAssetZh 'AC-<下一个整数>' 'Chinese AC asset must require monotonic AC IDs.'
Require-Match $acAssetZh '验收状态总览' 'Chinese AC asset must include a status summary.'
Require-Match $acAssetZh '(?m)^cssclasses: ac-document\r?$' 'Chinese AC asset must opt into the readable-table style.'
Require-Match $acAssetZh '验证证据详情' 'Chinese AC asset must keep lengthy evidence outside status-table cells.'
foreach ($englishTemplate in @($acAsset, $acTemplate)) {
    Require-Match $englishTemplate '## 🧪 Verification Evidence Details' 'Every English AC template must use the evidence icon.'
    Require-Match $englishTemplate 'EVD-<YYYYMMDD>-<N>' 'Every English AC template must define stable EVD IDs.'
    Require-Match $englishTemplate '(?s)Verification time:.*Related ACs:.*Verification type:.*Verification scope:.*Command / Steps:.*Expected result:.*Actual result:.*Exit status:.*Evidence attachment:.*Conclusion:.*Status update:' 'Every English AC template must define the fixed EVD fields.'
    Require-Match $englishTemplate 'Use `N/A` instead of omitting a field' 'Every English AC template must retain empty EVD fields as N/A.'
    Require-Match $englishTemplate '<details>' 'Every English AC template must collapse long raw output.'
    Require-Match $englishTemplate '## 🧭 Scope Decision Log' 'Every English AC template must use the scope-decision icon.'
    Require-Match $englishTemplate 'append `Evidence: EVD-YYYYMMDD-N` to the How to Verify cell without replacing' 'Every English AC template must place evidence citations after the reusable verification action.'
    Require-Match $englishTemplate 'Date.*Decision ID.*AC Scope.*Approved Scope Decision.*Rationale' 'Every English AC template must define the scope-decision fields.'
    Require-NoMatch $englishTemplate '(?m)^## .*Change Log\r?$' 'New English AC templates must not retain a Change Log.'
}
Require-Match $acAssetZh '## 🧪 验证证据详情' 'Chinese AC template must use the evidence icon.'
Require-Match $acAssetZh 'EVD-<YYYYMMDD>-<N>' 'Chinese AC template must define stable EVD IDs.'
Require-Match $acAssetZh '(?s)验证时间：.*关联 AC：.*验证类型：.*验证范围：.*命令 / 步骤：.*预期结果：.*实际结果：.*退出状态：.*证据附件：.*结论：.*状态更新：' 'Chinese AC template must define the fixed EVD fields.'
Require-Match $acAssetZh '字段无内容时写 `N/A`' 'Chinese AC template must retain empty EVD fields as N/A.'
Require-Match $acAssetZh '<details>' 'Chinese AC template must collapse long raw output.'
Require-Match $acAssetZh '## 🧭 范围决策记录' 'Chinese AC template must use the scope-decision icon.'
Require-Match $acAssetZh '在“验证方式”单元格的原命令/步骤后追加 `证据：EVD-YYYYMMDD-N`' 'Chinese AC template must place evidence citations after the reusable verification action.'
Require-Match $acAssetZh '日期.*决策 ID.*AC 范围.*批准的范围决定.*原因' 'Chinese AC template must define the scope-decision fields.'
Require-NoMatch $acAssetZh '(?m)^## .*变更记录\r?$' 'New Chinese AC template must not retain a change log.'
Require-Match $acTableCss 'table-layout:\s*fixed' 'AC table CSS must use a stable table layout.'
Require-Match $acTableCss 'overflow-wrap:\s*anywhere' 'AC table CSS must wrap long evidence text instead of clipping it.'
Require-Match $add 'Keep five-column AC rows scannable' 'ADD must keep long evidence out of five-column AC table cells.'
Require-Match $acContractRef 'never replaces AC\.md' 'AC contract reference must make plans subordinate to AC.md.'
Test-GitCheckpointIsolation $failures
if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) contract check(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: release workflow contracts are consistent.' -ForegroundColor Green
