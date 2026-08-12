[CmdletBinding()]
param(
    [string]$ReleaseRoot,
    [switch]$RequireCleanWorktree
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

function Get-Utf8Lines {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing required file: $Path" }
    return @(Get-Content -LiteralPath $Path -Encoding utf8)
}

function Get-FrontMatter {
    param([string]$Path)
    $lines = @(Get-Utf8Lines $Path)
    $result = @{}
    $duplicateKeys = [System.Collections.Generic.List[string]]::new()
    if (($lines.Count -lt 3) -or ($lines[0].Trim() -ne '---')) {
        return [pscustomobject]@{ IsValid = $false; Values = $result; DuplicateKeys = @(); EndLine = -1 }
    }

    $endLine = -1
    for ($index = 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq '---') { $endLine = $index; break }
    }
    if ($endLine -lt 0) {
        return [pscustomobject]@{ IsValid = $false; Values = $result; DuplicateKeys = @(); EndLine = -1 }
    }

    for ($index = 1; $index -lt $endLine; $index++) {
        $line = $lines[$index]
        if ($line -match '^([A-Za-z][A-Za-z0-9_-]*):\s*(.*?)\s*$') {
            if ($result.ContainsKey($matches[1])) {
                if (-not $duplicateKeys.Contains($matches[1])) { $duplicateKeys.Add($matches[1]) }
            } else {
                $result[$matches[1]] = $matches[2].Trim('"', "'")
            }
        }
    }
    return [pscustomobject]@{ IsValid = $true; Values = $result; DuplicateKeys = @($duplicateKeys); EndLine = $endLine }
}

function Get-FrontMatterList {
    param([string]$Path, [string]$Key)
    $lines = @(Get-Utf8Lines $Path)
    $frontMatter = Get-FrontMatter $Path
    if (-not $frontMatter.IsValid) { return @() }
    $items = [System.Collections.Generic.List[string]]::new()
    $found = $false
    for ($index = 1; $index -lt $frontMatter.EndLine; $index++) {
        $line = $lines[$index]
        if (-not $found) {
            if ($line -match ('^' + [regex]::Escape($Key) + ':\s*(.*?)\s*$')) {
                $found = $true
                if (($matches[1] -eq '[]') -or (-not [string]::IsNullOrWhiteSpace($matches[1]))) { break }
            }
            continue
        }
        if ($line -match '^[A-Za-z][A-Za-z0-9_-]*:') { break }
        if ($line -match '^\s+-\s+(.+?)\s*$') { $items.Add($matches[1].Trim('"', "'")) }
    }
    return @($items)
}

function Get-FrontMatterListSyntaxErrors {
    param([string]$Path, [string]$Key)
    $lines = @(Get-Utf8Lines $Path)
    $frontMatter = Get-FrontMatter $Path
    if (-not $frontMatter.IsValid) { return @('invalid frontmatter') }
    $errors = [System.Collections.Generic.List[string]]::new()
    $found = $false
    for ($index = 1; $index -lt $frontMatter.EndLine; $index++) {
        $line = $lines[$index]
        if (-not $found) {
            if ($line -match ('^' + [regex]::Escape($Key) + ':\s*(.*?)\s*$')) {
                $found = $true
                $inline = $matches[1]
                if (($inline -ne '') -and ($inline -ne '[]')) { $errors.Add("line $($index + 1): inline value must be []") }
                if ($inline -eq '[]') { break }
            }
            continue
        }
        if ($line -match '^[A-Za-z][A-Za-z0-9_-]*:') { break }
        if ([string]::IsNullOrWhiteSpace($line) -or ($line -match '^\s*#')) { continue }
        if ($line -notmatch '^\s+-\s+\S.*$') { $errors.Add("line $($index + 1): expected a YAML list item") }
    }
    return @($errors)
}

function Split-MarkdownRow {
    param([string]$Line)
    $value = $Line.Trim()
    if ($value.StartsWith('|')) { $value = $value.Substring(1) }
    if ($value.EndsWith('|')) { $value = $value.Substring(0, $value.Length - 1) }
    return @([regex]::Split($value, '(?<!\\)\|') | ForEach-Object { ($_.Trim() -replace '\\[|]', '|') })
}

function Test-MarkdownSeparatorRow {
    param([string[]]$Cells)
    if ($Cells.Count -eq 0) { return $false }
    foreach ($cell in $Cells) {
        if ($cell -notmatch '^:?-{3,}:?$') { return $false }
    }
    return $true
}

function Get-SemanticHeadingTitle {
    param([string]$Title)
    if ($null -eq $Title) { return '' }
    return ([regex]::Replace($Title.Trim(), '^[^\p{L}\p{N}<]+', '')).Trim()
}

function Test-SemanticHeadingEquals {
    param([string]$Actual, [string]$Expected)
    return [string]::Equals((Get-SemanticHeadingTitle $Actual), $Expected, [StringComparison]::OrdinalIgnoreCase)
}

function Get-MarkdownDocument {
    param([string]$Path)
    $lines = @(Get-Utf8Lines $Path)
    $headings = [System.Collections.Generic.List[object]]::new()
    $tables = [System.Collections.Generic.List[object]]::new()
    $visibleLines = [System.Collections.Generic.List[string]]::new()
    $visibleLineNumbers = [System.Collections.Generic.HashSet[int]]::new()
    $headingStack = @{}
    $fenceCharacter = $null
    $fenceLength = 0

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s{0,3}(`{3,}|~{3,})(.*)$') {
            $run = $matches[1]
            $remainder = $matches[2]
            $character = $run.Substring(0, 1)
            if ($null -eq $fenceCharacter) {
                $fenceCharacter = $character
                $fenceLength = $run.Length
            } elseif (($fenceCharacter -eq $character) -and ($run.Length -ge $fenceLength) -and [string]::IsNullOrWhiteSpace($remainder)) {
                $fenceCharacter = $null
                $fenceLength = 0
            }
            continue
        }
        if ($null -ne $fenceCharacter) { continue }
        $visibleLines.Add($lines[$index])
        [void]$visibleLineNumbers.Add($index + 1)

        if ($lines[$index] -match '^(#{1,6})\s+(.+?)\s*$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            $headingStack[$level] = $title
            foreach ($key in @($headingStack.Keys)) {
                if ([int]$key -gt $level) { $headingStack.Remove($key) }
            }
            $headings.Add([pscustomobject]@{ Level = $level; Title = $title; Line = $index + 1 })
        }

        if (($index + 1 -lt $lines.Count) -and $lines[$index].Trim().StartsWith('|')) {
            $header = @(Split-MarkdownRow $lines[$index])
            $separator = @(Split-MarkdownRow $lines[$index + 1])
            if (($header.Count -gt 0) -and ($header.Count -eq $separator.Count) -and (Test-MarkdownSeparatorRow $separator)) {
                $rows = [System.Collections.Generic.List[object]]::new()
                $rowIndex = $index + 2
                while (($rowIndex -lt $lines.Count) -and $lines[$rowIndex].Trim().StartsWith('|')) {
                    $cells = @(Split-MarkdownRow $lines[$rowIndex])
                    $rows.Add([pscustomobject]@{ Cells = $cells; Line = $rowIndex + 1 })
                    $rowIndex++
                }
                $tables.Add([pscustomobject]@{
                    Header = $header
                    Rows = @($rows)
                    Line = $index + 1
                    H2 = $(if ($headingStack.ContainsKey(2)) { $headingStack[2] } else { '' })
                    H3 = $(if ($headingStack.ContainsKey(3)) { $headingStack[3] } else { '' })
                })
                $index = $rowIndex - 1
            }
        }
    }
    return [pscustomobject]@{ Lines = $lines; VisibleLines = @($visibleLines); VisibleLineNumbers = $visibleLineNumbers; Headings = @($headings); Tables = @($tables) }
}

function Test-ExactCells {
    param([string[]]$Actual, [string[]]$Expected)
    if ($Actual.Count -ne $Expected.Count) { return $false }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($Actual[$index].Trim() -ne $Expected[$index]) { return $false }
    }
    return $true
}

function Add-StructuralFailure {
    param([string]$Path, [string]$Message)
    $failures.Add("$Message ($Path)")
}

function Get-MarkdownSectionContent {
    param([pscustomobject]$Document, [int]$Level, [string]$Title)
    $heading = @($Document.Headings | Where-Object { ($_.Level -eq $Level) -and (Test-SemanticHeadingEquals $_.Title $Title) } | Select-Object -First 1)
    if ($heading.Count -eq 0) { return $null }
    $startLine = $heading[0].Line + 1
    $endLine = $Document.Lines.Count
    foreach ($candidate in $Document.Headings) {
        if (($candidate.Line -gt $heading[0].Line) -and ($candidate.Level -le $Level)) {
            $endLine = $candidate.Line - 1
            break
        }
    }
    if ($endLine -lt $startLine) { return '' }
    $sectionLines = [System.Collections.Generic.List[string]]::new()
    for ($lineNumber = $startLine; $lineNumber -le $endLine; $lineNumber++) {
        if ($Document.VisibleLineNumbers.Contains($lineNumber)) { $sectionLines.Add($Document.Lines[$lineNumber - 1]) }
    }
    return (@($sectionLines) -join [Environment]::NewLine)
}

function Test-AcTemplateStructure {
    param([string]$Path, [ValidateSet('en','zh')][string]$Language)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing AC template: $Path"); return }
    $frontMatter = Get-FrontMatter $Path
    if (-not $frontMatter.IsValid) { Add-StructuralFailure $Path 'AC template must begin with closed YAML frontmatter'; return }
    if ($frontMatter.DuplicateKeys.Count -gt 0) { Add-StructuralFailure $Path "AC frontmatter contains duplicate keys: $($frontMatter.DuplicateKeys -join ', ')" }
    foreach ($field in @('template','schema','cssclasses')) {
        if (-not $frontMatter.Values.ContainsKey($field)) { Add-StructuralFailure $Path "AC frontmatter is missing '$field'" }
    }
    if ($frontMatter.Values['template'] -ne 'acceptance-criteria') { Add-StructuralFailure $Path 'AC frontmatter template must be acceptance-criteria' }
    if ($frontMatter.Values['schema'] -ne '2') { Add-StructuralFailure $Path 'AC frontmatter schema must be 2' }
    if ($frontMatter.Values['cssclasses'] -ne 'ac-document') { Add-StructuralFailure $Path 'AC frontmatter cssclasses must be ac-document' }

    $document = Get-MarkdownDocument $Path
    if ($Language -eq 'en') {
        $requiredH2 = @('Project Goal','Acceptance Criteria','Verification Evidence Details','Status Annotation Convention','Status Summary','Scope Decision Log','Notes')
        $categories = @('Features','Performance','Compatibility','Quality','Backlog / Deferred')
        $acHeader = @('ID','Criterion','Status','How to Verify','Expected Result')
        $evidenceFields = @('Verification time','Related ACs','Verification type','Verification scope','Command / Steps','Expected result','Actual result','Exit status','Evidence attachment','Conclusion','Status update')
        $decisionHeader = @('Date','Decision ID','AC Scope','Approved Scope Decision','Rationale')
        $summaryTitle = 'Status Summary'
        $summaryHeader = @('Category','Total','`[x]`','`[ ]` / `[~]`','`[!]`','`[>]` / `[-]`','Notes')
        $summaryCategories = @('Features','Performance','Compatibility','Quality','Backlog / Deferred')
        $acIdPattern = '^AC-(?:\d+|<next integer>)$'
        $decisionScopePattern = '^AC-(?:<id or range>|\d+(?:\s*(?:,|、|;|；|~|～|–|—|-)\s*(?:AC-)?\d+)*)$'
    } else {
        $requiredH2 = @('项目目标','验收标准','验证证据详情','状态与注解约定','验收状态总览','范围决策记录','备注')
        $categories = @('功能类','性能类','兼容性类','质量类','延后 / 待办')
        $acHeader = @('ID','标准','状态','验证方式','预期结果')
        $evidenceFields = @('验证时间','关联 AC','验证类型','验证范围','命令 / 步骤','预期结果','实际结果','退出状态','证据附件','结论','状态更新')
        $decisionHeader = @('日期','决策 ID','AC 范围','批准的范围决定','原因')
        $summaryTitle = '验收状态总览'
        $summaryHeader = @('类别','总计','`[x]`','`[ ]` / `[~]`','`[!]`','`[>]` / `[-]`','备注')
        $summaryCategories = @('功能','性能','兼容性','质量','延后 / 待办')
        $acIdPattern = '^AC-(?:\d+|<下一个整数>)$'
        $decisionScopePattern = '^AC-(?:<编号或范围>|\d+(?:\s*(?:,|、|;|；|~|～|–|—|-)\s*(?:AC-)?\d+)*)$'
    }

    foreach ($required in $requiredH2) {
        $found = @($document.Headings | Where-Object { ($_.Level -eq 2) -and (Test-SemanticHeadingEquals $_.Title $required) }).Count -gt 0
        if (-not $found) { Add-StructuralFailure $Path "AC template is missing required level-2 section '$required'" }
    }

    $seenConcreteIds = @{}
    foreach ($category in $categories) {
        $acceptanceTitle = if ($Language -eq 'en') { 'Acceptance Criteria' } else { '验收标准' }
        $categoryTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 $acceptanceTitle) -and (Test-SemanticHeadingEquals $_.H3 $category) })
        if ($categoryTables.Count -ne 1) {
            Add-StructuralFailure $Path "Category '$category' must contain exactly one five-column AC table"
            continue
        }
        if (-not (Test-ExactCells $categoryTables[0].Header $acHeader)) {
            Add-StructuralFailure $Path "Category '$category' has an invalid AC table header"
            continue
        }
        foreach ($row in $categoryTables[0].Rows) {
            if ($row.Cells.Count -ne 5) { Add-StructuralFailure $Path "AC row at line $($row.Line) must have five columns"; continue }
            $id = $row.Cells[0]
            $marker = $row.Cells[2]
            if ($id -notmatch $acIdPattern) { Add-StructuralFailure $Path "Invalid AC ID '$id' at line $($row.Line)" }
            if ($id -match '^AC-\d+$') {
                if ($seenConcreteIds.ContainsKey($id)) { Add-StructuralFailure $Path "Duplicate concrete AC ID '$id' at line $($row.Line)" }
                else { $seenConcreteIds[$id] = $true }
            }
            if ($marker -notmatch '^\[(?: |~|x|>|-)\]$|^\[!\]\s+\[(?:manual|affected|blocked)\]$') {
                Add-StructuralFailure $Path "Invalid AC status marker '$marker' at line $($row.Line)"
            }
        }
    }

    $evidenceTitle = if ($Language -eq 'en') { 'Verification Evidence Details' } else { '验证证据详情' }
    $content = Get-MarkdownSectionContent $document 2 $evidenceTitle
    if ($null -eq $content) { $content = '' }
    foreach ($field in $evidenceFields) {
        $labelPattern = '(?m)^-\s+\*\*' + [regex]::Escape($field) + '(?:：|:)\*\*'
        if ($content -notmatch $labelPattern) { Add-StructuralFailure $Path "EVD schema is missing fixed field '$field'" }
    }
    $evidenceHeadings = @()
    # Scope level-3 headings by the exact evidence section boundaries instead of accepting fenced or similarly named text.
    $evidenceH2 = @($document.Headings | Where-Object { ($_.Level -eq 2) -and (Test-SemanticHeadingEquals $_.Title $evidenceTitle) } | Select-Object -First 1)
    $nextH2Line = $document.Lines.Count + 1
    if ($evidenceH2.Count -eq 1) {
        $nextH2 = @($document.Headings | Where-Object { ($_.Level -eq 2) -and ($_.Line -gt $evidenceH2[0].Line) } | Select-Object -First 1)
        if ($nextH2.Count -eq 1) { $nextH2Line = $nextH2[0].Line }
        $evidenceHeadings = @($document.Headings | Where-Object { ($_.Level -eq 3) -and ($_.Line -gt $evidenceH2[0].Line) -and ($_.Line -lt $nextH2Line) })
    } else { $evidenceHeadings = @() }
    $seenEvidenceIds = @{}
    $hasPlaceholder = $false
    foreach ($heading in $evidenceHeadings) {
        $title = Get-SemanticHeadingTitle $heading.Title
        if ($title -match '^EVD-<YYYYMMDD>-<N>(?:\s+-\s+.+)?$') { $hasPlaceholder = $true; continue }
        if ($title -notmatch '^(EVD-\d{8}-\d+)(?:\s+-\s+.+)?$') { Add-StructuralFailure $Path "Invalid EVD heading '$title' at line $($heading.Line)"; continue }
        $evidenceId = $matches[1]
        if ($seenEvidenceIds.ContainsKey($evidenceId)) { Add-StructuralFailure $Path "Duplicate concrete EVD ID '$evidenceId' at line $($heading.Line)" }
        else { $seenEvidenceIds[$evidenceId] = $true }
    }
    if (-not $hasPlaceholder) { Add-StructuralFailure $Path 'EVD section must define the stable EVD-<YYYYMMDD>-<N> heading' }

    $decisionTitle = if ($Language -eq 'en') { 'Scope Decision Log' } else { '范围决策记录' }
    $decisionTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 $decisionTitle) -and (Test-ExactCells $_.Header $decisionHeader) })
    if ($decisionTables.Count -ne 1) { Add-StructuralFailure $Path 'Scope Decision section must contain its fixed five-column table' }
    else {
        $seenDecisionIds = @{}
        foreach ($row in $decisionTables[0].Rows) {
            if ($row.Cells.Count -ne 5) { Add-StructuralFailure $Path "Scope Decision row at line $($row.Line) must have five columns"; continue }
            if ($row.Cells | Where-Object { [string]::IsNullOrWhiteSpace($_) }) { Add-StructuralFailure $Path "Scope Decision row at line $($row.Line) must not contain empty fields" }
            if ($row.Cells[0] -notmatch '^(?:\{\{YYYY-MM-DD\}\}|\d{4}-\d{2}-\d{2})$') { Add-StructuralFailure $Path "Invalid Scope Decision date at line $($row.Line)" }
            if ($row.Cells[1] -notmatch '^DEC-(?:<YYYYMMDD>-<N>|\d{8}-\d+)$') { Add-StructuralFailure $Path "Invalid Scope Decision ID at line $($row.Line)" }
            if ($row.Cells[2] -notmatch $decisionScopePattern) { Add-StructuralFailure $Path "Invalid Scope Decision AC scope at line $($row.Line)" }
            if ($row.Cells[1] -match '^DEC-\d{8}-\d+$') {
                $decisionDate = $row.Cells[0] -replace '-', ''
                $idDate = ([regex]::Match($row.Cells[1], '^DEC-(\d{8})-')).Groups[1].Value
                if (($row.Cells[0] -match '^\d{4}-\d{2}-\d{2}$') -and ($decisionDate -ne $idDate)) { Add-StructuralFailure $Path "Scope Decision date and ID date differ at line $($row.Line)" }
                if ($seenDecisionIds.ContainsKey($row.Cells[1])) { Add-StructuralFailure $Path "Duplicate Scope Decision ID '$($row.Cells[1])' at line $($row.Line)" }
                else { $seenDecisionIds[$row.Cells[1]] = $true }
            }
        }
    }

    $summaryTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 $summaryTitle) -and (Test-ExactCells $_.Header $summaryHeader) })
    if ($summaryTables.Count -ne 1) { Add-StructuralFailure $Path 'Status Summary must contain its fixed seven-column table' }
    else {
        $actualSummaryCategories = @($summaryTables[0].Rows | ForEach-Object { $_.Cells[0] })
        foreach ($summaryCategory in $summaryCategories) {
            if ($actualSummaryCategories -notcontains $summaryCategory) { Add-StructuralFailure $Path "Status Summary is missing category '$summaryCategory'" }
        }
    }

    $conclusionLabel = if ($Language -eq 'en') { 'Conclusion' } else { '结论' }
    if ($content -notmatch ('(?m)^-\s+\*\*' + $conclusionLabel + '(?:：|:)\*\*\s+PASS \| FAIL \| PENDING MANUAL \| BLOCKED \| RECOVERY STATE\s*$')) {
        Add-StructuralFailure $Path 'EVD Conclusion must include the fixed RECOVERY STATE outcome'
    }
}

function Test-ImplementationPlanStructure {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing implementation plan template: $Path"); return }
    $frontMatter = Get-FrontMatter $Path
    if (-not $frontMatter.IsValid) { Add-StructuralFailure $Path 'Plan template must begin with closed YAML frontmatter'; return }
    if ($frontMatter.DuplicateKeys.Count -gt 0) { Add-StructuralFailure $Path "Plan frontmatter contains duplicate keys: $($frontMatter.DuplicateKeys -join ', ')" }
    $requiredFields = @('template','schema','plan_id','project','status','pause_reason','mode','created','updated','code_root','worktree_id','branch','baseline_commit','active_tasks','target_acs','approach_ref','scope_decision_ids')
    foreach ($field in $requiredFields) {
        if (-not $frontMatter.Values.ContainsKey($field)) { Add-StructuralFailure $Path "Plan frontmatter is missing identity/recovery field '$field'" }
    }
    if ($frontMatter.Values['template'] -ne 'add-implementation-plan') { Add-StructuralFailure $Path 'Plan frontmatter template must be add-implementation-plan' }
    if ($frontMatter.Values['schema'] -ne '2') { Add-StructuralFailure $Path 'Plan frontmatter schema must be 2' }
    if ($frontMatter.Values['status'] -ne 'active') { Add-StructuralFailure $Path 'A new persistent plan template must start with status: active' }
    if ($frontMatter.Values['mode'] -ne 'A') { Add-StructuralFailure $Path 'Persistent plan template must use Mode A' }
    if ($frontMatter.Values['active_tasks'] -ne '[]') { Add-StructuralFailure $Path 'A new plan must start with active_tasks: [] until PLAN-1 becomes in_progress' }
    foreach ($field in @('plan_id','project','status','pause_reason','created','updated','code_root','worktree_id','branch','baseline_commit','approach_ref')) {
        if ($frontMatter.Values.ContainsKey($field) -and [string]::IsNullOrWhiteSpace($frontMatter.Values[$field])) { Add-StructuralFailure $Path "Plan frontmatter field '$field' must not be empty" }
    }
    $targetAcIds = @(Get-FrontMatterList $Path 'target_acs')
    foreach ($syntaxError in @(Get-FrontMatterListSyntaxErrors $Path 'target_acs')) { Add-StructuralFailure $Path "Plan target_acs has invalid YAML list syntax at $syntaxError" }
    if ($targetAcIds.Count -lt 1) { Add-StructuralFailure $Path 'Plan target_acs must contain at least one AC ID' }
    $seenTargetAcIds = @{}
    foreach ($targetAcId in $targetAcIds) {
        if ($targetAcId -notmatch '^AC-(?:\d+|N)$') { Add-StructuralFailure $Path "Plan target_acs contains invalid ID '$targetAcId'"; continue }
        if ($seenTargetAcIds.ContainsKey($targetAcId)) { Add-StructuralFailure $Path "Plan target_acs contains duplicate ID '$targetAcId'" }
        else { $seenTargetAcIds[$targetAcId] = $true }
    }
    $scopeDecisionIds = @(Get-FrontMatterList $Path 'scope_decision_ids')
    foreach ($syntaxError in @(Get-FrontMatterListSyntaxErrors $Path 'scope_decision_ids')) { Add-StructuralFailure $Path "Plan scope_decision_ids has invalid YAML list syntax at $syntaxError" }
    $scopeDecisionInline = $frontMatter.Values['scope_decision_ids']
    if (($scopeDecisionInline -ne '[]') -and (-not [string]::IsNullOrWhiteSpace($scopeDecisionInline))) {
        Add-StructuralFailure $Path 'Plan scope_decision_ids must be [] or a YAML list of concrete DEC IDs'
    }
    $seenScopeDecisionIds = @{}
    foreach ($scopeDecisionId in $scopeDecisionIds) {
        if ($scopeDecisionId -notmatch '^DEC-\d{8}-\d+$') { Add-StructuralFailure $Path "Plan scope_decision_ids contains invalid ID '$scopeDecisionId'"; continue }
        if ($seenScopeDecisionIds.ContainsKey($scopeDecisionId)) { Add-StructuralFailure $Path "Plan scope_decision_ids contains duplicate ID '$scopeDecisionId'" }
        else { $seenScopeDecisionIds[$scopeDecisionId] = $true }
    }

    $document = Get-MarkdownDocument $Path
    $mappingHeader = @('Plan task','AC IDs','Implementation scope','Verification action')
    $mappingTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 'Acceptance Mapping') -and (Test-ExactCells $_.Header $mappingHeader) })
    if ($mappingTables.Count -ne 1) { Add-StructuralFailure $Path "Acceptance Mapping must use columns '$($mappingHeader -join ' | ')'" }

    $summaryHeader = @('Task','AC mapping','Status','Depends on','Attempt','Commit group')
    $summaryTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 'Status Summary') -and (Test-ExactCells $_.Header $summaryHeader) })
    if ($summaryTables.Count -ne 1) { Add-StructuralFailure $Path 'Plan Status Summary must use the fixed six-column task schema' }
    elseif (($summaryTables[0].Rows.Count -lt 1) -or ($summaryTables[0].Rows[0].Cells[0] -ne 'PLAN-1') -or ($summaryTables[0].Rows[0].Cells[2] -ne 'pending')) {
        Add-StructuralFailure $Path 'A new plan must expose PLAN-1 as pending before it enters active_tasks'
    }

    if (($summaryTables.Count -eq 1) -and ($mappingTables.Count -eq 1)) {
        $summaryIds = [System.Collections.Generic.List[string]]::new()
        foreach ($row in $summaryTables[0].Rows) {
            if ($row.Cells.Count -ne 6) { Add-StructuralFailure $Path "Plan summary row at line $($row.Line) must have six columns"; continue }
            $taskId = $row.Cells[0]
            if ($taskId -notmatch '^PLAN-\d+$') { Add-StructuralFailure $Path "Invalid plan task ID '$taskId' at line $($row.Line)"; continue }
            if ($summaryIds.Contains($taskId)) { Add-StructuralFailure $Path "Duplicate plan task ID '$taskId' at line $($row.Line)" }
            else { $summaryIds.Add($taskId) }
            if ($row.Cells[2] -notmatch '^(pending|in_progress|verified|blocked|superseded)$') { Add-StructuralFailure $Path "Invalid task status '$($row.Cells[2])' at line $($row.Line)" }
            if ($row.Cells[4] -notmatch '^\d+$') { Add-StructuralFailure $Path "Task attempt must be a non-negative integer at line $($row.Line)" }
        }

        $mappedIds = [System.Collections.Generic.List[string]]::new()
        $mappedAcIds = [System.Collections.Generic.List[string]]::new()
        foreach ($row in $mappingTables[0].Rows) {
            if ($row.Cells.Count -ne 4) { Add-StructuralFailure $Path "Acceptance Mapping row at line $($row.Line) must have four columns"; continue }
            $taskId = $row.Cells[0]
            if (-not $summaryIds.Contains($taskId)) { Add-StructuralFailure $Path "Acceptance Mapping references unknown task '$taskId' at line $($row.Line)" }
            else { $mappedIds.Add($taskId) }
            if ($row.Cells[1] -notmatch '^AC-(?:\d+|N)(?:\s*(?:,|、|;|；)\s*AC-(?:\d+|N))*$') {
                Add-StructuralFailure $Path "Acceptance Mapping row at line $($row.Line) has malformed AC IDs"
            } else {
                foreach ($match in [regex]::Matches($row.Cells[1], 'AC-(?:\d+|N)')) {
                    if (-not $mappedAcIds.Contains($match.Value)) { $mappedAcIds.Add($match.Value) }
                }
            }
            if ([string]::IsNullOrWhiteSpace($row.Cells[2]) -or [string]::IsNullOrWhiteSpace($row.Cells[3])) { Add-StructuralFailure $Path "Acceptance Mapping row at line $($row.Line) must include implementation scope and verification action" }
        }
        foreach ($taskId in $summaryIds) {
            if (-not $mappedIds.Contains($taskId)) { Add-StructuralFailure $Path "Plan task '$taskId' is missing from Acceptance Mapping" }
            $taskHeading = @($document.Headings | Where-Object {
                ($_.Level -eq 2) -and ((Get-SemanticHeadingTitle $_.Title) -match ('^' + [regex]::Escape($taskId) + '(?:\s+-\s+.+)?$'))
            })
            if ($taskHeading.Count -ne 1) { Add-StructuralFailure $Path "Plan task '$taskId' must have exactly one matching level-2 task section"; continue }
            $taskSection = Get-MarkdownSectionContent $document 2 (Get-SemanticHeadingTitle $taskHeading[0].Title)
            $summaryStatus = ($summaryTables[0].Rows | Where-Object { $_.Cells[0] -eq $taskId } | Select-Object -First 1).Cells[2]
            if ($taskSection -notmatch ('(?m)^-\s+\*\*Status:\*\*\s+' + [regex]::Escape($summaryStatus) + '\s*$')) {
                Add-StructuralFailure $Path "Plan task '$taskId' detail status must match Status Summary"
            }
            foreach ($field in @('AC mapping','Depends on','Files','Interfaces','Steps','Test strategy','Verification','Review','Commit','Evidence')) {
                if ($taskSection -notmatch ('(?m)^-\s+\*\*' + [regex]::Escape($field) + ':\*\*')) { Add-StructuralFailure $Path "Plan task '$taskId' detail is missing '$field'" }
            }
        }
        foreach ($targetAcId in $targetAcIds) {
            if (($targetAcId -match '^AC-(?:\d+|N)$') -and (-not $mappedAcIds.Contains($targetAcId))) { Add-StructuralFailure $Path "Plan target AC '$targetAcId' is missing from Acceptance Mapping" }
        }
        foreach ($mappedAcId in $mappedAcIds) {
            if (-not $targetAcIds.Contains($mappedAcId)) { Add-StructuralFailure $Path "Acceptance Mapping AC '$mappedAcId' is missing from target_acs" }
        }
    }

    $content = $document.VisibleLines -join [Environment]::NewLine
    foreach ($field in @('Last safe commit','Working tree baseline','Blocked tasks','Next ready tasks')) {
        if ($content -notmatch ('(?m)^-\s+\*\*' + [regex]::Escape($field) + ':\*\*')) { Add-StructuralFailure $Path "Recovery State is missing '$field'" }
    }
    if ($content -notmatch '(?m)^-\s+\*\*Active tasks:\*\*\s+N/A\s*$') { Add-StructuralFailure $Path 'A new plan Recovery State must start with Active tasks: N/A' }
    if ($content -notmatch '(?m)^-\s+\*\*Local commits / COMMIT-BLOCKED / COMMIT-SKIPPED / COMMIT-REVIEW-REQUIRED:\*\*') { Add-StructuralFailure $Path 'Plan Final Record must represent every checkpoint outcome' }
}

function Get-SemanticParagraphs {
    param([string]$Path)
    $content = Get-Content -Raw -LiteralPath $Path -Encoding utf8
    return @([regex]::Split($content, '(?:\r?\n){2,}') | ForEach-Object {
        (($_ -replace '\r?\n', ' ') -replace '\s+', ' ').Trim()
    } | Where-Object { $_ })
}

function Require-ClauseTerms {
    param([string]$Path, [string[]]$Terms, [string]$Message)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing required file: $Path"); return }
    $matched = $false
    foreach ($paragraph in @(Get-SemanticParagraphs $Path)) {
        $allTerms = $true
        foreach ($term in $Terms) {
            if ($paragraph.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -lt 0) { $allTerms = $false; break }
        }
        if ($allTerms) { $matched = $true; break }
    }
    if (-not $matched) { $failures.Add($Message) }
}

function Get-Level2Section {
    param([string]$Path, [string]$TitlePrefix)
    $lines = @(Get-Utf8Lines $Path)
    $start = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^##\s+(.+?)\s*$') {
            if ($matches[1].StartsWith($TitlePrefix, [StringComparison]::OrdinalIgnoreCase)) { $start = $index + 1; break }
        }
    }
    if ($start -lt 0) { return $null }
    $section = [System.Collections.Generic.List[string]]::new()
    for ($index = $start; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^##\s+') { break }
        $section.Add($lines[$index])
    }
    return ($section -join [Environment]::NewLine)
}

function Test-ReadmeExecutionSection {
    param([string]$Path, [ValidateSet('en','zh')][string]$Language)
    $section = Get-Level2Section $Path 'v2.6.0'
    if ($null -eq $section) { Add-StructuralFailure $Path 'README must contain a level-2 v2.6.0 execution section'; return }
    if ($Language -eq 'en') {
        $termGroups = @(
            @('Mode A','persistent plan','completed plans','never overwritten'),
            @('Mode B','six-field','Execution Map','status','attempts','repository baseline','evidence','commit outcome'),
            @('TEST-FIRST','CHARACTERIZATION','TEST-AFTER','MANUAL'),
            @('parallel','non-overlapping','cancellation','delegates'),
            @('three failed','affected work','shared prerequisite'),
            @('local commits','index','hooks','working tree','remotes'),
            @('AC.md','only acceptance-status authority')
        )
    } else {
        $termGroups = @(
            @('Mode A','持久计划','已完成计划','不会被覆盖'),
            @('Mode B','六字段','Execution Map','状态','尝试次数','仓库基线','证据','提交结果'),
            @('TEST-FIRST','CHARACTERIZATION','TEST-AFTER','MANUAL'),
            @('并行','写入范围不重叠','取消','委派任务'),
            @('连续三个','受影响工作','共享前置条件'),
            @('本地提交','index','hooks','工作树','远端'),
            @('AC.md','唯一验收状态权威')
        )
    }
    foreach ($terms in $termGroups) {
        $missing = @($terms | Where-Object { $section.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -lt 0 })
        if ($missing.Count -gt 0) { Add-StructuralFailure $Path "v2.6.0 execution section is missing linked contract terms: $($missing -join ', ')" }
    }
}

function Test-ModeBContract {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing Mode B contract reference: $Path"); return }
    $document = Get-MarkdownDocument $Path
    $lines = @($document.VisibleLines)
    $topFields = @('Target AC','Files','Implementation steps','Verification','Review','Commit')
    $schemaLines = @($lines | Where-Object { $_ -match '^\s*`Target AC`\s*\|' })
    if ($schemaLines.Count -ne 1) { Add-StructuralFailure $Path 'Mode B must define exactly one canonical Execution Map schema line'; return }
    $found = @([regex]::Matches($schemaLines[0], '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value })
    if (-not (Test-ExactCells @($found) $topFields)) {
        Add-StructuralFailure $Path "Mode B must expose exactly six ordered top-level Execution Map fields: $($topFields -join ', ')"
    }

    Require-ClauseTerms $Path @('Target AC','status','attempt') 'Mode B Target AC must retain status and attempt state.'
    Require-ClauseTerms $Path @('Files','repository','baseline') 'Mode B Files must retain the repository baseline.'
    Require-ClauseTerms $Path @('Verification','evidence') 'Mode B Verification must retain verification evidence.'
    Require-ClauseTerms $Path @('Commit','hash','COMMIT-BLOCKED','COMMIT-SKIPPED','COMMIT-REVIEW-REQUIRED') 'Mode B Commit must retain every checkpoint outcome.'
}

function Test-WorkflowTransitionFixtures {
    param([string]$Path, [hashtable]$SourceMap)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing workflow transition fixtures: $Path"); return }
    try {
        $parsedCases = Get-Content -Raw -LiteralPath $Path -Encoding utf8 | ConvertFrom-Json
        if ($parsedCases -is [array]) { $cases = @($parsedCases) } else { $cases = @($parsedCases) }
    }
    catch {
        $failures.Add("Workflow transition fixtures are invalid JSON: $($_.Exception.Message)")
        return
    }
    $requiredScenarios = @('blocked-redesign','pre-approval-cancel','post-persistence-cancel','delegate-cancel','active-plan-reentry','paused-plan-restart','active-plan-conflict','manual-pass','mode-b-recovery','mode-b-cancel-restart','test-first-red','blocked-subset-review','blocked-alternate-path','guided-retry-status','mode-a-redesign-plan','guided-mode-transition','external-environment-block','cleared-environment-block','mode-a-to-b-handoff','post-approval-rejection')
    $actualScenarios = @($cases | ForEach-Object { $_.scenario })
    foreach ($scenario in $requiredScenarios) {
        if (@($actualScenarios | Where-Object { $_ -eq $scenario }).Count -lt 1) { $failures.Add("Workflow fixtures must define at least one '$scenario' contract case.") }
    }

    foreach ($case in $cases) {
        $terms = @($case.requiredTerms)
        if ([string]::IsNullOrWhiteSpace([string]$case.name) -or [string]::IsNullOrWhiteSpace([string]$case.source) -or ($terms.Count -eq 0) -or [string]::IsNullOrWhiteSpace([string]$case.requiredPattern)) {
            $failures.Add('Every workflow fixture needs name, source, non-empty requiredTerms, and requiredPattern.')
            continue
        }
        if (-not $SourceMap.ContainsKey([string]$case.source)) {
            $failures.Add("Workflow fixture '$($case.name)' uses unknown source '$($case.source)'.")
            continue
        }
        Require-ClauseTerms $SourceMap[[string]$case.source] $terms "Workflow contract fixture failed: $($case.name)"
        $sourceContent = Get-Content -Raw -LiteralPath $SourceMap[[string]$case.source] -Encoding utf8
        if ($sourceContent -notmatch [string]$case.requiredPattern) { $failures.Add("Workflow transition relation failed: $($case.name)") }
        foreach ($pattern in @($case.forbiddenPatterns)) {
            if ((-not [string]::IsNullOrWhiteSpace([string]$pattern)) -and ($sourceContent -match [string]$pattern)) {
                $failures.Add("Workflow fixture '$($case.name)' matched forbidden pattern '$pattern'.")
            }
        }
    }
}

$add = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\SKILL.md'
$designExploration = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\design-exploration-and-handoff.md'
$experience = Join-Path $ReleaseRoot 'skills\project-experience\SKILL.md'
$readme = Join-Path $ReleaseRoot 'README.md'
$readmeZh = Join-Path $ReleaseRoot 'README-zh.md'
$ccSwitchGuide = Join-Path $ReleaseRoot 'docs\CCSWITCH.md'
$ccSwitchGuideZh = Join-Path $ReleaseRoot 'docs\CCSWITCH-zh.md'
$codexGuide = Join-Path $ReleaseRoot 'codex-port\CODEX-ADAPTATION.md'
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

function Get-CheckpointPolicyDecision {
    param(
        [string[]]$BaselineStatus,
        [string[]]$BaselineStaged,
        [string]$TargetPath,
        [bool]$OperationActive,
        [bool]$RiskyHook
    )
    if ($OperationActive -or $RiskyHook -or ($BaselineStaged.Count -gt 0)) { return 'COMMIT-BLOCKED' }
    if (@($BaselineStatus | Where-Object { $_ -match ([regex]::Escape($TargetPath) + '$') }).Count -gt 0) { return 'COMMIT-BLOCKED' }
    return 'ALLOW'
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
    $originalGitEnvironment = @{}
    foreach ($item in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'GIT_*' })) {
        $originalGitEnvironment[$item.Name] = $item.Value
    }
    try {
        foreach ($item in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'GIT_*' })) {
            Remove-Item -LiteralPath ("Env:" + $item.Name)
        }
        $emptyConfig = Join-Path $testRoot 'empty.gitconfig'
        $emptyHooks = Join-Path $testRoot 'empty-hooks'
        $emptyTemplate = Join-Path $testRoot 'empty-template'
        New-Item -ItemType File -Path $emptyConfig | Out-Null
        New-Item -ItemType Directory -Path $emptyHooks,$emptyTemplate | Out-Null
        $env:GIT_CONFIG_NOSYSTEM = '1'
        $env:GIT_CONFIG_GLOBAL = $emptyConfig
        $env:GIT_CONFIG_SYSTEM = $emptyConfig
        $env:GIT_CONFIG_COUNT = '4'
        $env:GIT_CONFIG_KEY_0 = 'commit.gpgsign'
        $env:GIT_CONFIG_VALUE_0 = 'false'
        $env:GIT_CONFIG_KEY_1 = 'tag.gpgSign'
        $env:GIT_CONFIG_VALUE_1 = 'false'
        $env:GIT_CONFIG_KEY_2 = 'core.hooksPath'
        $env:GIT_CONFIG_VALUE_2 = $emptyHooks
        $env:GIT_CONFIG_KEY_3 = 'init.templateDir'
        $env:GIT_CONFIG_VALUE_3 = $emptyTemplate

        $clean = New-CheckpointTestRepository $testRoot 'clean'
        $cleanBaselineStatus = @((Invoke-TestGit $clean @('status', '--short')) | Where-Object { $_ })
        $cleanBaselineStaged = @((Invoke-TestGit $clean @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if ((Get-CheckpointPolicyDecision $cleanBaselineStatus $cleanBaselineStaged 'task.txt' $false $false) -ne 'ALLOW') {
            $FailureList.Add('Clean checkpoint policy must allow an isolated Agent-owned target.')
        }
        $configuredHooks = @((Invoke-TestGit $clean @('config', '--get', 'core.hooksPath')) | Where-Object { $_ })
        if (($configuredHooks.Count -ne 1) -or ([IO.Path]::GetFullPath($configuredHooks[0]) -ne [IO.Path]::GetFullPath($emptyHooks))) {
            $FailureList.Add('Temporary Git repositories must use the validator-owned empty hooks directory.')
        }
        Add-Content -LiteralPath (Join-Path $clean 'task.txt') -Value 'agent change' -Encoding utf8
        Invoke-TestGit $clean @('add', '--', 'task.txt') | Out-Null
        $cleanStaged = @((Invoke-TestGit $clean @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if (($cleanStaged.Count -ne 1) -or ($cleanStaged[0] -ne 'task.txt')) {
            $FailureList.Add('Clean checkpoint scenario must stage only the Agent-owned target.')
        }
        $preCommitStatus = @(Invoke-TestGit $clean @('status', '--short'))
        if (@($preCommitStatus | Where-Object { $_ -match 'task\.txt$' }).Count -ne 1) {
            $FailureList.Add('Clean checkpoint scenario must re-check repository status immediately before commit.')
        }
        Invoke-TestGit $clean @('commit', '--quiet', '-m', 'test: checkpoint AC-1') | Out-Null
        $committedPaths = @((Invoke-TestGit $clean @('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD')) | Where-Object { $_ })
        $postCommitStatus = @((Invoke-TestGit $clean @('status', '--short')) | Where-Object { $_ })
        if (($committedPaths.Count -ne 1) -or ($committedPaths[0] -ne 'task.txt') -or ($postCommitStatus.Count -ne 0)) {
            $FailureList.Add('Clean checkpoint scenario must inspect committed paths and working-tree status immediately after commit.')
        }

        $unrelated = New-CheckpointTestRepository $testRoot 'unrelated-dirty'
        Add-Content -LiteralPath (Join-Path $unrelated 'user.txt') -Value 'pre-existing user change' -Encoding utf8
        $unrelatedBaseline = @(Invoke-TestGit $unrelated @('status', '--short'))
        $unrelatedBaselineStaged = @((Invoke-TestGit $unrelated @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if ((Get-CheckpointPolicyDecision $unrelatedBaseline $unrelatedBaselineStaged 'task.txt' $false $false) -ne 'ALLOW') {
            $FailureList.Add('Unrelated dirty paths must not block an otherwise isolated target checkpoint.')
        }
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
        $targetBaselineStaged = @((Invoke-TestGit $targetDirty @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        if ((Get-CheckpointPolicyDecision $targetBaseline $targetBaselineStaged 'task.txt' $false $false) -ne 'COMMIT-BLOCKED') {
            $FailureList.Add('Target-pre-dirty checkpoint policy must return COMMIT-BLOCKED.')
        }

        $preStaged = New-CheckpointTestRepository $testRoot 'pre-staged-index'
        Add-Content -LiteralPath (Join-Path $preStaged 'user.txt') -Value 'pre-staged user change' -Encoding utf8
        Invoke-TestGit $preStaged @('add', '--', 'user.txt') | Out-Null
        $cachedBaseline = @((Invoke-TestGit $preStaged @('diff', '--cached', '--name-only')) | Where-Object { $_ })
        $preStagedStatus = @(Invoke-TestGit $preStaged @('status', '--short'))
        if ((Get-CheckpointPolicyDecision $preStagedStatus $cachedBaseline 'task.txt' $false $false) -ne 'COMMIT-BLOCKED') {
            $FailureList.Add('Pre-staged-index checkpoint policy must return COMMIT-BLOCKED.')
        }

        $operation = New-CheckpointTestRepository $testRoot 'operation-active'
        $gitDirectory = (Invoke-TestGit $operation @('rev-parse', '--git-dir') | Select-Object -First 1)
        if (-not [IO.Path]::IsPathRooted($gitDirectory)) { $gitDirectory = Join-Path $operation $gitDirectory }
        Set-Content -LiteralPath (Join-Path $gitDirectory 'MERGE_HEAD') -Value ('0' * 40) -Encoding ascii
        $operationActive = Test-Path -LiteralPath (Join-Path $gitDirectory 'MERGE_HEAD')
        if ((Get-CheckpointPolicyDecision @() @() 'task.txt' $operationActive $false) -ne 'COMMIT-BLOCKED') {
            $FailureList.Add('Active merge/rebase/cherry-pick policy must return COMMIT-BLOCKED.')
        }

        $hookRepository = New-CheckpointTestRepository $testRoot 'risky-hook'
        $riskyHooks = Join-Path $hookRepository 'risky-hooks'
        New-Item -ItemType Directory -Path $riskyHooks | Out-Null
        [IO.File]::WriteAllText((Join-Path $riskyHooks 'pre-commit'), "#!/bin/sh`necho side-effect > unrelated-hook-output.txt`n")
        $riskyHookDetected = @(Get-ChildItem -LiteralPath $riskyHooks -File | Where-Object { $_.Name -in 'pre-commit','prepare-commit-msg','commit-msg','post-commit' }).Count -gt 0
        if ((Get-CheckpointPolicyDecision @() @() 'task.txt' $false $riskyHookDetected) -ne 'COMMIT-BLOCKED') {
            $FailureList.Add('Unknown or risky active commit hook policy must return COMMIT-BLOCKED.')
        }

        $postHookRepository = New-CheckpointTestRepository $testRoot 'post-hook-detection'
        $postHooks = Join-Path $postHookRepository 'post-hooks'
        New-Item -ItemType Directory -Path $postHooks | Out-Null
        [IO.File]::WriteAllText((Join-Path $postHooks 'post-commit'), "#!/bin/sh`necho side-effect > hook-side-effect.txt`n")
        Add-Content -LiteralPath (Join-Path $postHookRepository 'task.txt') -Value 'agent change' -Encoding utf8
        Invoke-TestGit $postHookRepository @('add', '--', 'task.txt') | Out-Null
        Invoke-TestGit $postHookRepository @('-c', "core.hooksPath=$postHooks", 'commit', '--quiet', '-m', 'test: hook detection AC-1') | Out-Null
        $unexpectedPostCommitState = @((Invoke-TestGit $postHookRepository @('status', '--short')) | Where-Object { $_ })
        $postCommitDecision = if ($unexpectedPostCommitState.Count -gt 0) { 'COMMIT-REVIEW-REQUIRED' } else { 'OK' }
        if ($postCommitDecision -ne 'COMMIT-REVIEW-REQUIRED') {
            $FailureList.Add('Unexpected post-commit hook changes must produce COMMIT-REVIEW-REQUIRED.')
        }
    }
    catch {
        $FailureList.Add("Git checkpoint scenario failed: $($_.Exception.Message)")
    }
    finally {
        foreach ($item in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'GIT_*' })) {
            Remove-Item -LiteralPath ("Env:" + $item.Name)
        }
        foreach ($name in $originalGitEnvironment.Keys) {
            Set-Item -LiteralPath ("Env:" + $name) -Value $originalGitEnvironment[$name]
        }
        $resolvedRoot = [IO.Path]::GetFullPath($testRoot)
        if ($resolvedRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedRoot)) {
            Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
        }
    }
}

$gitMetadata = Join-Path $ReleaseRoot '.git'
if (Test-Path -LiteralPath $gitMetadata) {
    $releaseStatus = @((Invoke-TestGit $ReleaseRoot @('status', '--porcelain', '--untracked-files=all')) | Where-Object { $_ })
    if ($RequireCleanWorktree -and ($releaseStatus.Count -gt 0)) {
        $failures.Add("Release-only clean-worktree validation failed: $($releaseStatus -join ', ')")
    }
} elseif ($RequireCleanWorktree) {
    $failures.Add('Release-only clean-worktree validation requires ReleaseRoot to be a Git repository.')
}

# v2.3 README narrative, CC Switch network, and compressed-core contract.
Require-ClauseTerms $codexGuide @('Mode A','always creates/resumes','persistent','plans/*.md','never replace') 'Codex guide must not let host task UI replace the persistent Mode A plan.'
Require-ClauseTerms $codexGuide @('Mode B','chat-only','Execution Map') 'Codex guide must reserve chat-only planning for Mode B.'
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.6\.0' 'English README must identify v2.6.0.'
Require-Match $readme '## Your agent said “done.” You disagree.' 'English README must open with the human problem story.'
Require-Match $readme '## How ADD closes the loop' 'English README must show the ADD closed loop.'
Require-Match $readme '## Before ADD / After ADD' 'English README must include before/after proof.'
Require-Match $readme '## Try ADD in 60 seconds' 'English README must include a 60-second experience before installation.'
Require-Match $readme '## Install ADD' 'English README must retain installation instructions.'
Require-Match $readme 'AC Authority Restoration' 'English README must explain the v2.4 AC-authority change.'
Require-Match $readme 'Readable AC tables and evidence details' 'English README must explain the v2.4.2 table-readability change.'
Require-Match $readme 'Built-in ADD design exploration' 'English README must explain the v2.5.0 built-in design change.'
Require-ClauseTerms $readme @('Install ADD','recommended companion') 'English README must distinguish core ADD from its recommended companion.'
Require-ClauseTerms $readme @('complete','skills/acceptance-driven-development/','assets/','references/') 'English manual installation must preserve the complete ADD directory.'
Require-ClauseTerms $readme @('COMMIT-BLOCKED','COMMIT-SKIPPED','COMMIT-REVIEW-REQUIRED') 'English README must disclose every local checkpoint outcome.'
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
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.6\.0' 'Chinese README must identify v2.6.0.'
Require-Match $readmeZh '## 你的 Agent 说“完成了”。你并不相信。' 'Chinese README must open with the human problem story.'
Require-Match $readmeZh '## ADD 如何闭环' 'Chinese README must show the ADD closed loop.'
Require-Match $readmeZh '## 使用 ADD 前后' 'Chinese README must include before/after proof.'
Require-Match $readmeZh '## 一条请求看懂 ADD' 'Chinese README must include a 60-second experience before installation.'
Require-Match $readmeZh 'AC 权威恢复' 'Chinese README must explain the v2.4 AC-authority change.'
Require-Match $readmeZh 'AC 表格可读性与证据详情' 'Chinese README must explain the v2.4.2 table-readability change.'
Require-Match $readmeZh 'ADD 内置设计探索' 'Chinese README must explain the v2.5.0 built-in design change.'
Require-ClauseTerms $readmeZh @('请安装 ADD','推荐','配套 Skill') 'Chinese README must distinguish core ADD from its recommended companion.'
Require-ClauseTerms $readmeZh @('完整','skills/acceptance-driven-development/','assets/','references/') 'Chinese manual installation must preserve the complete ADD directory.'
Require-ClauseTerms $readmeZh @('COMMIT-BLOCKED','COMMIT-SKIPPED','COMMIT-REVIEW-REQUIRED') 'Chinese README must disclose every local checkpoint outcome.'
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
Test-ReadmeExecutionSection $readme 'en'
Test-ReadmeExecutionSection $readmeZh 'zh'
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
$textExtensions = @('.md','.ps1','.txt','.css','.json','.yml','.yaml','.toml','.ini','.cfg','.xml','.cmd','.bat','.sh')
$releaseFiles = Get-ChildItem -Recurse -File $ReleaseRoot | Where-Object {
    ($_.FullName -notmatch '[\\/]\.git[\\/]') -and ($_.Extension -in $textExtensions -or $_.Name -eq 'LICENSE')
}
$privatePatterns = @(
    ('[A-Z]:(?:\\{1,2}|/+)' + 'Users' + '(?:\\{1,2}|/+)(?!user(?:[\\/]|$)|<)[^\\/\s"''<>]+')
    ('/' + 'Users/' + '(?!user(?:/|$)|<)[^/\s"''<>]+')
    ('/' + 'home/' + '(?!user(?:/|$)|<)[^/\s"''<>]+')
    ('claude\\' + '_exp_memory\.md')
    ('expectedActive' + 'CacheHash')
)
$privatePath = $releaseFiles | Select-String -Pattern $privatePatterns -CaseSensitive:$false
if ($privatePath) { $failures.Add('Release files must not reference private workstation paths or cache hashes.') }
$formerGitHubIdentity = 'thunderzeus' + '036-creator'
$oldIdentity = $releaseFiles | Select-String -Pattern $formerGitHubIdentity -SimpleMatch -CaseSensitive:$false
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
$projectIndexTemplate = Join-Path $ReleaseRoot 'projects\templates\project-index.md'
$workflowFixtures = Join-Path $ReleaseRoot 'tests\fixtures\workflow-transitions.json'
$addLineCount = (Get-Content -LiteralPath $add -Encoding utf8).Count
$designExplorationLineCount = (Get-Content -LiteralPath $designExploration -Encoding utf8).Count
$implementationRefLineCount = (Get-Content -LiteralPath $implementationRef -Encoding utf8).Count
$acContractWordContent = Get-Content -Raw -LiteralPath $acContractRef -Encoding utf8
$addWordContent = Get-Content -Raw -LiteralPath $add -Encoding utf8
$implementationWordContent = Get-Content -Raw -LiteralPath $implementationRef -Encoding utf8
$addWordCount = [regex]::Matches($addWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$implementationRefWordCount = [regex]::Matches($implementationWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$mandatoryImplementationWordCount = $addWordCount + $implementationRefWordCount + [regex]::Matches($acContractWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$overlongOperationalLines = @(
    (Get-Content -LiteralPath $add -Encoding utf8)
    (Get-Content -LiteralPath $implementationRef -Encoding utf8)
) | Where-Object { $_.Length -gt 400 }
if ($addLineCount -gt 380) { $failures.Add("ADD main skill exceeds 380-line operational budget: $addLineCount") }
if ($designExplorationLineCount -gt 120) { $failures.Add("ADD design exploration exceeds 120-line conditional-reference budget: $designExplorationLineCount") }
if ($implementationRefLineCount -gt 140) { $failures.Add("ADD implementation reference exceeds 140-line conditional-reference budget: $implementationRefLineCount") }
if ($addWordCount -gt 3300) { $failures.Add("ADD main skill exceeds 3300-word operational budget: $addWordCount") }
if ($implementationRefWordCount -gt 1900) { $failures.Add("ADD implementation reference exceeds 1900-word conditional-reference budget: $implementationRefWordCount") }
if ($mandatoryImplementationWordCount -gt 6000) { $failures.Add("Typical implementation load exceeds 6000 words: $mandatoryImplementationWordCount") }
if ($overlongOperationalLines.Count -gt 0) { $failures.Add("ADD operational files contain $($overlongOperationalLines.Count) line(s) longer than 400 characters.") }
if (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'skills\acceptance-driven-development\IMPROVEMENT-GUIDE.md')) { $failures.Add('Maintainer improvement guide must not ship inside the runtime skill directory.') }
if (-not (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'docs\IMPROVEMENT-GUIDE.md'))) { $failures.Add('Maintainer improvement guide must remain available under docs/.') }
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
Require-ClauseTerms $add @('baseline validation fails','appropriate Phase 3.5 entry','before review') 'Baseline-validation fixes must not bypass Phase 3.5.'
Require-Match $add 'A repair within the approved AC and approach returns through Phase 3\.5A without reapproval' 'ADD must route same-scope AUTO repairs through approved backlog without duplicate approval.'
Require-Match $add 'Settle `\[~\]`: fix through the appropriate Phase 3\.5 entry' 'ADD must define the [~]-to-[x] completion transition without bypassing Phase 3.5.'
Require-Match $guardrailsRef 'Phase 3\.5A backlog work must use Mode A' 'Guardrails must preserve Mode A for approved backlog work.'
Require-NoMatch $guardrailsRef 'still enters Phase 3\.5 and Mode B' 'Guardrails must not route every one-line code change to Mode B.'
Require-Match $guardrailsRef 'A code change has no relevant AC' 'Guardrails must require a confirmed tracking AC for every code change.'
Require-Match $add 'Code formatting or typo fixes still enter Phase 3\.5B fast lane' 'ADD must not exempt code formatting or typo fixes from Phase 3.5.'
Require-Match $add 'After validation or user confirmation, write `~/.add-hub`' 'ADD must persist only a validated or confirmed fallback document-hub selection.'
Require-ClauseTerms $add @('final approval','save','AC.md','enter Phases 1–3') 'ADD must define the Gate 2 success transition.'
Require-Match $add 'Complete Phase 4\.8: fresh baseline validation' 'Mode A must require Phase 4.8 before Phase 5.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, re-run baseline validation, then review again' 'Review fixes must re-enter Phase 3.5 and rerun baseline validation.'
Require-Match $add 'changes batching/review only; changed AUTO follows AUTO' 'Mode B must preserve AUTO command verification.'
Require-ClauseTerms $add @('failed affected AUTO AC','either mode','regression','repair or defer') 'Affected AUTO regressions must require a user repair-or-defer decision.'
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
Require-ClauseTerms $add @('Stop the batch only','required approval','shared/batch-wide block','user rejection/cancellation','host/tool limit') 'ADD must define the bounded Mode A stop conditions.'
Require-ClauseTerms $add @('Three failed cycles','affected task','continue independent rows') 'ADD must continue independent Mode A work when one task is blocked.'
Require-Match $add 'No `\[ \]` or `\[~\]` items' 'ADD must not ignore a document containing only partial ACs.'
Require-Match $add 'unsaved five-column recovery draft' 'Existing-project AC reconstruction must remain a draft until approval.'
Require-ClauseTerms $add @('Rejection/cancellation','before approval','AC.md','unchanged') 'Pre-approval rejection must not persist unapproved scope.'
Require-ClauseTerms $add @('Cancellation after persistence','before code','new targets remain','[ ]','edited/resumed targets','persisted') 'Post-approval pre-code cancellation must preserve the approved AC contract.'
Require-ClauseTerms $add @('edited','[x]','criterion','verification','expected result','[~]') 'An approved behavior delta must invalidate a stale verified target before code.'
Require-Match $add 'change to `\[ \]` if untouched or `\[~\]` if partial implementation remains, then enter Phase 3\.5A' 'A resumed deferred AC must have an explicit transition back to executable backlog.'
Require-ClauseTerms $add @('resumed','[>]','target','[ ]','[~]','implementation remains') 'A changed-scope deferred AC must leave deferred status after Phase 3.5B approval.'
Require-Match $add 'do not write it first' 'Untracked fast-lane work must confirm its tracking AC before persistence.'
Require-Match $add 'A vague check fails this gate' 'Vague MANUAL criteria must fail the AC Contract Gate.'
Require-Match $add 'On `AC-N failed:' 'ADD must define a failed manual-verification transition.'
Require-Match $add 'only after explicit user confirmation of deferral or deprecation' 'ADD must not defer or deprecate partial ACs unilaterally.'
Require-ClauseTerms $add @('tracked bug','target','[x]','[~]') 'A known tracked bug must invalidate its formerly verified target AC.'
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
Require-ClauseTerms $add @('Append','Evidence: EVD-...','How to Verify','without replacing reusable commands/steps') 'ADD must specify where evidence citations live without destroying reusable verification commands.'
Require-Match $add 'task/AC reaches the three-attempt boundary' 'The AC verification classes must cover implementation-exhaustion blocks.'
Require-Match $add 'create a fixed EVD event.*append its citation.*only then mark `\[x\]`' 'Fresh AUTO success must persist evidence before acceptance completion.'
Require-ClauseTerms $add @('Explicitly confirmed deferral/deprecation','[>]','[-]','scope decision') 'Explicit deferral or deprecation must settle a blocked AC.'
Require-Match $implementationRef 'Status.*AC mapping.*Depends on.*Files.*Interfaces.*Steps.*Test strategy.*Verification.*Review.*Commit.*Evidence' 'Mode A tasks must contain the fixed Agent-oriented schema.'
Require-Match $implementationRef 'TEST-FIRST.*CHARACTERIZATION.*TEST-AFTER.*MANUAL' 'Implementation tasks must use the four approved test strategies.'
Require-Match $implementationRef 'without asking for plan approval' 'Plans must self-check and execute without user review.'
Require-Match $implementationRef 'three consecutive fail' 'Task failures must use the three-attempt boundary.'
Require-ClauseTerms $implementationRef @('Mode A counts per','PLAN-N','Mode B counts per target AC','Target AC') 'Failure counters must use explicit mode-specific units.'
Require-ClauseTerms $implementationRef @('three consecutive failed cycles','Mode A removes the task','blocked','Mode B marks the target AC','[!] [blocked]','EVD') 'The three-cycle boundary must define separate Mode A and Mode B block transitions.'
Require-Match $implementationRef 'Re-read authoritative `AC\.md`.*active plan.*`git status`.*recent local commits' 'Cross-session recovery must reconcile AC, plan, and Git evidence.'
Require-ClauseTerms $implementationRef @('Mode B has no persistent plan','series/attempt/guided/cancellation state','latest Mode B recovery EVD','approach_ref','repository diff') 'Mode B recovery must identify persisted series and approach sources.'
Require-ClauseTerms $implementationRef @('cannot be reconstructed confidently','preserve AC scope/tree','Phase 3.5B','approach confirmation') 'Mode B recovery must not guess a lost approved approach.'
Require-ClauseTerms $implementationRef @('three-failure block','one additional guided attempt','prior history') 'Guided recovery must retain its bounded extra attempt.'
Require-ClauseTerms $implementationRef @('approved material redesign','[!] [blocked]','[ ]','no retained implementation','[~]','implementation remains','reset EVD','new series ID','attempt: 0','state: reset') 'Failure recovery must define persisted redesign state and conditional AC transitions.'
Require-ClauseTerms $implementationRef @('On cancellation','every delegate','stop new writes','wait for/drain','preserve tree/index/commits') 'Cancellation must preserve user and repository state by default.'
Require-Match $implementationRef 'COMMIT-BLOCKED' 'Unsafe local commits must report COMMIT-BLOCKED.'
Require-Match $implementationRef 'stage only Agent-owned paths or safely separable hunks' 'Local commits must isolate Agent-owned changes.'
Require-Match $implementationRef 'Never use broad staging such as `git add -A`' 'Local commits must forbid broad staging with unrelated changes.'
Require-Match $implementationRef 'index is pre-populated.*merge/rebase/cherry-pick is active' 'Local commits must block on unsafe index or repository operation state.'
Require-Match $implementationRef 'COMMIT-SKIPPED: user instruction' 'Explicit user no-commit instructions must override automatic checkpoints.'
Require-ClauseTerms $implementationRef @('MANUAL','may commit','Agent checks','remaining','[!] [manual]') 'MANUAL work must permit a local checkpoint before user verification.'
Require-ClauseTerms $implementationRef @('Checkpoint','complete AC/related group','defer','later tasks remain') 'Local checkpoints must not split an incomplete AC across commits.'
Require-Match $implementationRef 'Permanently retain completed plans' 'Completed Mode A plans must be retained.'
Test-AcTemplateStructure $acAsset 'en'
Test-AcTemplateStructure $acAssetZh 'zh'
Test-AcTemplateStructure $acTemplate 'en'
Test-ImplementationPlanStructure $implementationPlanAsset
Test-ModeBContract $implementationRef
Test-WorkflowTransitionFixtures $workflowFixtures @{ add = $add; implementation = $implementationRef; plan = $implementationPlanAsset }
$exampleAcFiles = @(Get-ChildItem -LiteralPath (Join-Path $ReleaseRoot 'projects') -Recurse -File -Filter 'AC.md' | Where-Object { $_.FullName -notmatch '[\\/]templates[\\/]' })
foreach ($exampleAc in $exampleAcFiles) {
    $exampleLanguage = if ((Get-Content -Raw -LiteralPath $exampleAc.FullName -Encoding utf8) -match '验收标准') { 'zh' } else { 'en' }
    Test-AcTemplateStructure $exampleAc.FullName $exampleLanguage
}
if (-not (Test-Path -LiteralPath $projectIndexTemplate)) { $failures.Add('Missing manual project-index template.') }
elseif ((Get-FileHash -LiteralPath $projectIndexAsset -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $projectIndexTemplate -Algorithm SHA256).Hash) { $failures.Add('Installable and manual project-index templates must be identical.') }
foreach ($indexFile in @($projectIndexAsset, $projectIndexTemplate)) {
    Require-Match $indexFile 'FROM ""' 'Project index must discover project documents regardless of hub folder name.'
    Require-Match $indexFile 'template = "project-doc"' 'Project index must select project-document frontmatter.'
    Require-Match $indexFile 'contains\(tags, "项目"\).*contains\(tags, "project"\)' 'Project index must support the shipped Chinese tag and legacy English tag.'
    Require-Match $indexFile 'status = "开发中".*status = "维护中"' 'Project index active view must support shipped project statuses.'
}
Require-ClauseTerms $add @('project-index.md','Obsidian vault','user confirms','Dataview','available/enabled') 'ADD must seed the Dataview index only in a confirmed compatible Obsidian hub.'
Require-ClauseTerms $add @('document language','项目','project','开发中','active','已完成','completed','Do not mix') 'ADD project documents must support coherent Chinese and English metadata.'
Require-ClauseTerms $experience @('active','maintained','completed','archived','settled') 'Project experience must classify English project-document statuses.'
Require-ClauseTerms $experience @('Development-project evidence gate','active','maintained','evidenced') 'English active projects must use the same evidence gate.'
Require-ClauseTerms $projectDocAsset @('定义结构','英文','tags: [project]','active','maintained','completed','archived','不得混用') 'Project-document template must explain English localization without duplicating schemas.'

# Link deterministic transition fixtures to executable workflow clauses.
Require-ClauseTerms $add @('approved redesign','[!] [blocked]','[ ]','[~]','attempt series') 'Blocked redesign must define both retained and non-retained implementation transitions.'
Require-ClauseTerms $implementationRef @('On cancellation','delegate','wait for/drain','final tree') 'Cancellation must stop and settle delegates before reconciliation.'
Require-ClauseTerms $implementationRef @('only target ACs with retained Agent implementation','not freshly accepted','[~]','untouched','[!] [affected]','unchanged') 'Cancellation after implementation must update only targets with retained work.'
Require-ClauseTerms $implementationRef @('Clear','active_tasks','status: paused','pause_reason: user-cancelled','never auto-resumes','explicit restart') 'Cancelled Mode A plans must not resume automatically.'
Require-ClauseTerms $implementationRef @('explicit restart','paused plans','same identity','AC','approach','baseline','exactly one matches','set it `active`','never create a replacement') 'Explicit restart must safely reuse one matching paused plan instead of duplicating it.'
Require-ClauseTerms $implementationRef @('After approved AC persistence','before Agent code','new targets','[ ]','edited/resumed targets','persisted') 'Cancellation before code must preserve newly approved and edited AC states.'
Require-ClauseTerms $implementationRef @('plan matches','status: active','worktree','branch','baseline_commit','target_acs','approach_ref','Reuse') 'Active-plan re-entry must match identity, baseline, and approved approach before reuse.'
Require-ClauseTerms $implementationRef @('scope_decision_ids','may be','[]','legacy backlog','not an implementation-approach identifier') 'Legacy plans must allow no DEC without confusing scope decisions with approach identity.'
Require-ClauseTerms $add @('AC-N passed','EVD','[x]') 'MANUAL pass must persist an EVD before marking the AC verified.'
Require-ClauseTerms $implementationRef @('Expected','TEST-FIRST','red','do not count') 'An expected TEST-FIRST red result must not increment the failure counter.'
Require-NoMatch $implementationRef '(?i)expected.{0,80}TEST-FIRST.{0,80}red.{0,80}(?<!not )counts? as (?:a )?fail' 'ADD must not contain a contradictory rule that counts expected TEST-FIRST red as failure.'
Require-ClauseTerms $implementationRef @('Mode B re-enters','Mode A','import that state','three new tries') 'Mode B recovery must preserve guided-attempt state when escalating to Mode A.'
Require-ClauseTerms $implementationRef @('After every failed Mode B cycle','EXECUTION','Mode B series','approach_ref','attempt','limit','kind','state','recovery state') 'Each Mode B failure must persist complete series state in AC evidence.'
Require-ClauseTerms $implementationRef @('Each Mode B target AC','one series','scan every','next unused numeric','never share/reuse','shared failure','lists each target') 'Mode B series allocation must be collision-safe and target-specific.'
Require-ClauseTerms $implementationRef @('approved material redesign','EXECUTION','reset EVD','new series ID','approach_ref','attempt: 0','state: reset') 'Mode B redesign must persist its reset before interruption can restore old failures.'
Require-ClauseTerms $implementationRef @('User guidance','EXECUTION','same series','attempt: 4','limit: 4','kind: guided','state: authorized') 'Guided Mode B recovery must persist its one-extra-attempt boundary.'
Require-ClauseTerms $implementationRef @('User guidance','blocked AC','[ ]','no retained implementation','[~]','implementation remains','Mode A','pending','attempt 4/4') 'Guided recovery must reactivate both AC status branches without resetting Mode A attempts.'
Require-ClauseTerms $implementationRef @('Mode A remains selected','sole active plan','old failure evidence','update','approach_ref','pending','attempt 0','moves Mode A to Mode B','pause_reason: superseded-by-mode-b','never run both modes concurrently') 'Material redesign must preserve one Mode A owner or pause it before Mode B.'
Require-ClauseTerms $implementationRef @('For Mode B','EXECUTION','RECOVERY STATE','state: cancelled','no plan','active_tasks','explicit restart','state: resumed','without resetting attempts') 'Mode B cancellation must persist and explicitly resume recovery state.'
Require-ClauseTerms $implementationRef @('three consecutive failed cycles','Mode A removes the task','active_tasks','blocked') 'Blocked Mode A tasks must leave active_tasks.'
Require-ClauseTerms $implementationRef @('another task','freshly verifies every AC','old task','superseded','evidence','otherwise','remains blocked') 'An alternate verified path must settle or retain the original blocked task explicitly.'
Require-ClauseTerms $add @('failed affected AUTO AC','either mode','regression','repair or defer','Phase 3.5A','Phase 3.5B','explicit confirmation') 'Affected AUTO regressions need one mode-independent repair/deferral path.'
Require-ClauseTerms $add @('[ ]','[~]','latest EXECUTION EVD','state: cancelled','explicit restart','original mode/attempt state') 'Cancelled Mode B targets must not re-enter ordinary backlog automatically.'
Require-ClauseTerms $add @('[ ]','[~]','latest EXECUTION EVD','state: rejected','explicit restart','original mode/attempt state') 'Rejected Mode B targets must not re-enter ordinary backlog automatically.'
Require-ClauseTerms $implementationRef @('shared failure','Mode B target once','Mode A task once','never multiply') 'Shared failures must increment each affected counter only once per cycle.'
Require-ClauseTerms $implementationRef @('unavailable required environment/tool','external block','not a failed cycle','BLOCKED','active_tasks','without incrementing','independent work') 'External environment blocks must settle active task state without consuming a failed attempt.'
Require-ClauseTerms $implementationRef @('condition clears','same approach','Mode A','pending','attempt/evidence unchanged','Mode B','same-series','state: resumed','Phase 3.5A','imports','prior attempt/guided state','rather than resetting') 'Cleared environment blocks must restore executable task state without resetting Mode B history.'
Require-ClauseTerms $implementationRef @('moves Mode A to Mode B','stop new writes','delegate','wait for/drain','in_progress','pending','superseded','clear `active_tasks`','pause_reason: superseded-by-mode-b','ownership handback','completed','active') 'Mode A to Mode B redesign must settle delegates/tasks and deterministically hand back or close the old plan.'
Require-ClauseTerms $implementationRef @('Rejection of further execution after approval','does not count as a failed cycle','pause_reason: user-rejected','state: rejected','explicit restart','state: resumed','without resetting attempts') 'Post-approval rejection must persist a distinct recoverable state without consuming an attempt.'
Require-ClauseTerms $add @('implementation subset being settled','[!] [blocked]','independent target','Phase 5') 'Phase 4.8 must allow independent implemented targets to settle while another target remains blocked.'
Require-Match $implementationPlanAsset '(?m)^template: add-implementation-plan\r?$' 'Plan asset must declare its template type.'
Require-Match $implementationPlanAsset '(?m)^mode: A\r?$' 'Persistent plan asset must be Mode A only.'
Require-Match $implementationPlanAsset 'Acceptance Mapping' 'Plan asset must map tasks to AC IDs.'
Require-Match $implementationPlanAsset '(?s)Status:.*AC mapping:.*Depends on:.*Files:.*Interfaces:.*Steps:.*Test strategy:.*Verification:.*Review:.*Commit:.*Evidence:' 'Plan asset must include every required PLAN-N field.'
Require-ClauseTerms $implementationPlanAsset @('Task status','pending','in_progress','verified','blocked','superseded','active_tasks') 'Plan asset must define all task states and active_tasks membership.'
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
    Require-Match $englishTemplate 'Verification type:\*\* AUTO \| MANUAL \| AUTO \+ MANUAL \| EXECUTION \| REVIEW \| BLOCKED' 'English EVD schema must support execution and review recovery events.'
    Require-Match $englishTemplate 'Conclusion:\*\* PASS \| FAIL \| PENDING MANUAL \| BLOCKED \| RECOVERY STATE' 'English EVD schema must distinguish recovery state from acceptance outcomes.'
    Require-ClauseTerms $englishTemplate @('Status update','AC status transition','EXECUTION','Mode B','series','approach','attempt','limit','kind','state','N/A') 'English EVD Status update must support Mode B recovery metadata.'
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
Require-Match $acAssetZh '验证类型：\*\* AUTO \| MANUAL \| AUTO \+ MANUAL \| EXECUTION \| REVIEW \| BLOCKED' 'Chinese EVD schema must support execution and review recovery events.'
Require-Match $acAssetZh '结论：\*\* PASS \| FAIL \| PENDING MANUAL \| BLOCKED \| RECOVERY STATE' 'Chinese EVD schema must distinguish recovery state from acceptance outcomes.'
Require-ClauseTerms $acAssetZh @('状态更新','AC 状态变化','EXECUTION','Mode B','series','approach','attempt','limit','kind','state','N/A') 'Chinese EVD Status update must support Mode B recovery metadata.'
Require-Match $acAssetZh '字段无内容时写 `N/A`' 'Chinese AC template must retain empty EVD fields as N/A.'
Require-Match $acAssetZh '<details>' 'Chinese AC template must collapse long raw output.'
Require-Match $acAssetZh '## 🧭 范围决策记录' 'Chinese AC template must use the scope-decision icon.'
Require-Match $acAssetZh '在“验证方式”单元格的原命令/步骤后追加 `证据：EVD-YYYYMMDD-N`' 'Chinese AC template must place evidence citations after the reusable verification action.'
Require-Match $acAssetZh '日期.*决策 ID.*AC 范围.*批准的范围决定.*原因' 'Chinese AC template must define the scope-decision fields.'
Require-NoMatch $acAssetZh '(?m)^## .*变更记录\r?$' 'New Chinese AC template must not retain a change log.'
Require-Match $experience 'shared document hub' 'Project-experience metadata must refer to the shared document hub rather than a vault-only location.'
Require-Match $experience 'Obsidian vault or plain directory' 'Project-experience overview must support non-vault document hubs.'
Require-ClauseTerms $experience @('canonical absolute paths','workspace-relative vault paths','supported form','Hub identity') 'Project-experience path rules must be portable across host file APIs.'
Require-NoMatch $experience 'Always use absolute paths from `\$DOC_HUB`' 'Project-experience must not contradict host-compatible workspace-relative path handling.'
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
