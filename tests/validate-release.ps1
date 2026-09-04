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
    if ($frontMatter.Values['schema'] -ne '3') { Add-StructuralFailure $Path 'AC frontmatter schema must be 3' }
    if ($frontMatter.Values['cssclasses'] -ne 'ac-document') { Add-StructuralFailure $Path 'AC frontmatter cssclasses must be ac-document' }

    $document = Get-MarkdownDocument $Path
    if ($Language -eq 'en') {
        $requiredH2 = @('Project Goal','Acceptance Criteria','Current Verification Evidence','Status Annotation Convention','Status Summary','Scope Decision Log','Notes')
        $categories = @('Features','Performance','Compatibility','Quality','Backlog / Deferred')
        $acHeader = @('ID','Criterion','Status','How to Verify','Expected Result')
        $evidenceHeader = @('AC ID','Last Verified','Type','Current Conclusion','Actual Result / Evidence Location','Recovery State')
        $decisionHeader = @('Date','Decision ID','AC Scope','Approved Scope Decision','Rationale')
        $summaryTitle = 'Status Summary'
        $summaryHeader = @('Category','Total','`[x]`','`[ ]` / `[~]`','`[!]`','`[>]` / `[-]`','Notes')
        $summaryCategories = @('Features','Performance','Compatibility','Quality','Backlog / Deferred')
        $acIdPattern = '^AC-(?:\d+|<next integer>)$'
        $decisionScopePattern = '^AC-(?:<id or range>|\d+(?:\s*(?:,|、|;|；|~|～|–|—|-)\s*(?:AC-)?\d+)*)$'
    } else {
        $requiredH2 = @('项目目标','验收标准','当前验证证据','状态与注解约定','验收状态总览','范围决策记录','备注')
        $categories = @('功能类','性能类','兼容性类','质量类','延后 / 待办')
        $acHeader = @('ID','标准','状态','验证方式','预期结果')
        $evidenceHeader = @('AC ID','最近验证','类型','当前结论','实际结果 / 证据位置','恢复状态')
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
    $acStatuses = @{}
    $acCategoryById = @{}
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
                else {
                    $seenConcreteIds[$id] = $true
                    $acStatuses[$id] = $marker
                    $acCategoryById[$id] = $summaryCategories[$categories.IndexOf($category)]
                }
            }
            if ($marker -notmatch '^\[(?: |~|x|>|-)\]$|^\[!\]\s+\[(?:manual|affected|blocked)\]$') {
                Add-StructuralFailure $Path "Invalid AC status marker '$marker' at line $($row.Line)"
            }
            if ($row.Cells[3] -match '(?i)EVD-\d{8}-\d+|Evidence:\s*EVD-|证据：\s*EVD-') {
                Add-StructuralFailure $Path "How to Verify at line $($row.Line) must contain only reusable verification, not an evidence citation"
            }
        }
    }

    $evidenceTitle = if ($Language -eq 'en') { 'Current Verification Evidence' } else { '当前验证证据' }
    $content = Get-MarkdownSectionContent $document 2 $evidenceTitle
    if ($null -eq $content) { $content = '' }
    $evidenceTables = @($document.Tables | Where-Object { (Test-SemanticHeadingEquals $_.H2 $evidenceTitle) -and (Test-ExactCells $_.Header $evidenceHeader) })
    $evidenceRows = @{}
    $modeBSeriesOwners = @{}
    if ($evidenceTables.Count -ne 1) { Add-StructuralFailure $Path 'Current Verification Evidence must contain its fixed six-column table' }
    else {
        foreach ($row in $evidenceTables[0].Rows) {
            if ($row.Cells.Count -ne 6) { Add-StructuralFailure $Path "Current evidence row at line $($row.Line) must have six columns"; continue }
            $evidenceAc = $row.Cells[0]
            if ($evidenceAc -notmatch '^AC-(?:\d+|<id>|<编号>)$') { Add-StructuralFailure $Path "Invalid current-evidence AC ID '$evidenceAc' at line $($row.Line)"; continue }
            if ($evidenceAc -match '^AC-\d+$') {
                if ($evidenceRows.ContainsKey($evidenceAc)) { Add-StructuralFailure $Path "Duplicate current-evidence row for '$evidenceAc' at line $($row.Line)" }
                else { $evidenceRows[$evidenceAc] = $row }
                if (-not $seenConcreteIds.ContainsKey($evidenceAc)) { Add-StructuralFailure $Path "Current evidence references unknown AC '$evidenceAc' at line $($row.Line)" }
                if ($row.Cells[2] -notmatch '^(AUTO|MANUAL|REVIEW|EXECUTION|BLOCKED)$') { Add-StructuralFailure $Path "Invalid current-evidence type at line $($row.Line)" }
                if ($row.Cells[3] -notmatch '^(PASS|FAIL|PENDING IMPLEMENTATION|PENDING MANUAL|AFFECTED|BLOCKED|RECOVERY STATE)$') { Add-StructuralFailure $Path "Invalid current-evidence conclusion at line $($row.Line)" }
                $recovery = $row.Cells[5]
                $modeBPattern = '^series:\s*(?<series>MB-\d{8}-\d+);\s*approach_ref:\s*[^;]+;\s*attempt:\s*(?<attempt>\d+);\s*limit:\s*(?<limit>3|4);\s*kind:\s*(?<kind>normal|guided);\s*state:\s*(?<state>failed|blocked|authorized|reset|cancelled|rejected|resumed|pending-manual)$'
                $modeBMatch = [regex]::Match($recovery, $modeBPattern)
                if (($recovery -notin @('N/A','completed')) -and (-not $modeBMatch.Success)) {
                    Add-StructuralFailure $Path "Invalid Mode B Recovery State at line $($row.Line)"
                } elseif ($modeBMatch.Success) {
                    $series = $modeBMatch.Groups['series'].Value
                    $attempt = [int]$modeBMatch.Groups['attempt'].Value
                    $limit = [int]$modeBMatch.Groups['limit'].Value
                    $kind = $modeBMatch.Groups['kind'].Value
                    $state = $modeBMatch.Groups['state'].Value
                    $evidenceType = $row.Cells[2]
                    $conclusion = $row.Cells[3]
                    $acStatus = $acStatuses[$evidenceAc]
                    if ($modeBSeriesOwners.ContainsKey($series)) { Add-StructuralFailure $Path "Duplicate unfinished Mode B series '$series' for '$evidenceAc' and '$($modeBSeriesOwners[$series])'" }
                    else { $modeBSeriesOwners[$series] = $evidenceAc }
                    if ($attempt -gt $limit) { Add-StructuralFailure $Path "Mode B Recovery State attempt exceeds limit at line $($row.Line)" }
                    if (($kind -eq 'normal') -and ($limit -ne 3)) { Add-StructuralFailure $Path "Normal Mode B Recovery State must use limit 3 at line $($row.Line)" }
                    if (($kind -eq 'guided') -and (($attempt -ne 4) -or ($limit -ne 4))) { Add-StructuralFailure $Path "Guided Mode B Recovery State must use attempt 4 and limit 4 at line $($row.Line)" }
                    if (($kind -eq 'normal') -and ($state -in @('cancelled','rejected','resumed','pending-manual')) -and ($attempt -ge $limit)) {
                        Add-StructuralFailure $Path "Normal Mode B state $state requires an attempt below limit at line $($row.Line)"
                    }
                    switch ($state) {
                        'failed' {
                            if ($conclusion -ne 'FAIL') { Add-StructuralFailure $Path "Mode B state failed requires current conclusion 'FAIL' at line $($row.Line)" }
                            if ($evidenceType -notin @('EXECUTION','MANUAL')) { Add-StructuralFailure $Path "Mode B state failed requires current-evidence type 'EXECUTION' or 'MANUAL' at line $($row.Line)" }
                            if (($attempt -le 0) -or ($attempt -ge $limit)) { Add-StructuralFailure $Path "Mode B state failed requires a positive pre-limit attempt at line $($row.Line)" }
                            if ($acStatus -ne '[~]') { Add-StructuralFailure $Path "Mode B state failed requires AC status '[~]' at line $($row.Line)" }
                        }
                        'blocked' {
                            if ($conclusion -ne 'BLOCKED') { Add-StructuralFailure $Path "Mode B state blocked requires current conclusion 'BLOCKED' at line $($row.Line)" }
                            if ($evidenceType -notin @('EXECUTION','MANUAL','BLOCKED')) { Add-StructuralFailure $Path "Mode B state blocked requires current-evidence type 'EXECUTION', 'MANUAL', or 'BLOCKED' at line $($row.Line)" }
                            if (($evidenceType -in @('EXECUTION','MANUAL')) -and ($attempt -ne $limit)) { Add-StructuralFailure $Path "Mode B verification block requires attempt equal to limit at line $($row.Line)" }
                            if ($acStatus -ne '[!] [blocked]') { Add-StructuralFailure $Path "Mode B state blocked requires AC status '[!] [blocked]' at line $($row.Line)" }
                        }
                        'authorized' {
                            if ($conclusion -ne 'RECOVERY STATE') { Add-StructuralFailure $Path "Mode B state authorized requires current conclusion 'RECOVERY STATE' at line $($row.Line)" }
                            if ($evidenceType -ne 'EXECUTION') { Add-StructuralFailure $Path "Mode B state authorized requires current-evidence type 'EXECUTION' at line $($row.Line)" }
                            if (($kind -ne 'guided') -or ($attempt -ne 4) -or ($limit -ne 4)) { Add-StructuralFailure $Path "Mode B state authorized requires guided attempt 4/4 at line $($row.Line)" }
                            if ($acStatus -notin @('[ ]','[~]')) { Add-StructuralFailure $Path "Mode B state authorized requires AC status '[ ]' or '[~]' at line $($row.Line)" }
                        }
                        'reset' {
                            if ($conclusion -ne 'RECOVERY STATE') { Add-StructuralFailure $Path "Mode B state reset requires current conclusion 'RECOVERY STATE' at line $($row.Line)" }
                            if ($evidenceType -ne 'EXECUTION') { Add-StructuralFailure $Path "Mode B state reset requires current-evidence type 'EXECUTION' at line $($row.Line)" }
                            if (($kind -ne 'normal') -or ($attempt -ne 0) -or ($limit -ne 3)) { Add-StructuralFailure $Path "Mode B state reset requires attempt 0/3 with normal kind at line $($row.Line)" }
                            if ($acStatus -notin @('[ ]','[~]')) { Add-StructuralFailure $Path "Mode B state reset requires AC status '[ ]' or '[~]' at line $($row.Line)" }
                        }
                        'pending-manual' {
                            if ($conclusion -ne 'PENDING MANUAL') { Add-StructuralFailure $Path "Mode B state pending-manual requires current conclusion 'PENDING MANUAL' at line $($row.Line)" }
                            if ($evidenceType -ne 'MANUAL') { Add-StructuralFailure $Path "Mode B state pending-manual requires current-evidence type 'MANUAL' at line $($row.Line)" }
                            if ($acStatus -ne '[!] [manual]') { Add-StructuralFailure $Path "Mode B state pending-manual requires AC status '[!] [manual]' at line $($row.Line)" }
                        }
                        { $_ -in @('cancelled','rejected','resumed') } {
                            if ($conclusion -ne 'RECOVERY STATE') { Add-StructuralFailure $Path "Mode B state $state requires current conclusion 'RECOVERY STATE' at line $($row.Line)" }
                            if ($evidenceType -ne 'EXECUTION') { Add-StructuralFailure $Path "Mode B state $state requires current-evidence type 'EXECUTION' at line $($row.Line)" }
                            if ($acStatus -notin @('[ ]','[~]')) { Add-StructuralFailure $Path "Mode B state $state requires AC status '[ ]' or '[~]' at line $($row.Line)" }
                        }
                    }
                } elseif ($recovery -eq 'completed') {
                    if (($row.Cells[3] -ne 'PASS') -or ($row.Cells[2] -notin @('AUTO','MANUAL','REVIEW')) -or ($acStatuses[$evidenceAc] -notin @('[x]','[>]','[-]'))) {
                        Add-StructuralFailure $Path "Recovery State 'completed' requires settled PASS evidence at line $($row.Line)"
                    }
                } else {
                    $allowedTypes = switch ($row.Cells[3]) {
                        'PASS' { @('AUTO','MANUAL','REVIEW') }
                        'FAIL' { @('AUTO','MANUAL','REVIEW','EXECUTION') }
                        'PENDING IMPLEMENTATION' { @('EXECUTION') }
                        'PENDING MANUAL' { @('MANUAL') }
                        'AFFECTED' { @('REVIEW') }
                        'BLOCKED' { @('BLOCKED') }
                        'RECOVERY STATE' { @() }
                        default { @() }
                    }
                    if (($row.Cells[3] -eq 'PENDING IMPLEMENTATION') -and ($row.Cells[2] -ne 'EXECUTION')) {
                        Add-StructuralFailure $Path "PENDING IMPLEMENTATION requires current-evidence type 'EXECUTION' at line $($row.Line)"
                    } elseif ($allowedTypes -notcontains $row.Cells[2]) {
                        Add-StructuralFailure $Path "Conclusion '$($row.Cells[3])' is incompatible with type '$($row.Cells[2])' at line $($row.Line)"
                    }
                }
            }
        }
    }
    if ($content -match '(?m)^###\s+EVD-' -or $content -match 'EVD-<YYYYMMDD>-<N>') {
        Add-StructuralFailure $Path 'Schema 3 must not append legacy EVD event blocks'
    }
    foreach ($acId in $acStatuses.Keys) {
        $status = $acStatuses[$acId]
        $hasEvidence = $evidenceRows.ContainsKey($acId)
        $conclusion = if ($hasEvidence) { $evidenceRows[$acId].Cells[3] } else { $null }
        if ($status -eq '[ ]' -and $hasEvidence -and $conclusion -ne 'RECOVERY STATE') { Add-StructuralFailure $Path "Unimplemented AC '$acId' cannot have conclusion '$conclusion'" }
        if ($status -eq '[~]' -and $hasEvidence -and $conclusion -notin @('FAIL','PENDING IMPLEMENTATION','RECOVERY STATE')) { Add-StructuralFailure $Path "Partial AC '$acId' has incompatible conclusion '$conclusion'" }
        if ($conclusion -eq 'PENDING IMPLEMENTATION' -and ($status -ne '[~]')) { Add-StructuralFailure $Path "PENDING IMPLEMENTATION requires AC status '[~]'" }
        if ($status -eq '[x]' -and ((-not $hasEvidence) -or ($evidenceRows[$acId].Cells[3] -ne 'PASS'))) {
            Add-StructuralFailure $Path "Verified AC '$acId' requires one current PASS evidence row"
        }
        $requiredConclusion = switch ($status) {
            '[!] [manual]' { 'PENDING MANUAL' }
            '[!] [affected]' { 'AFFECTED' }
            '[!] [blocked]' { 'BLOCKED' }
            default { $null }
        }
        if ($requiredConclusion -and ((-not $hasEvidence) -or ($evidenceRows[$acId].Cells[3] -ne $requiredConclusion))) {
            Add-StructuralFailure $Path "AC '$acId' with status '$status' requires current conclusion '$requiredConclusion'"
        }
        if ($status -eq '[~]' -and (-not $hasEvidence)) {
            Add-StructuralFailure $Path "Partial AC '$acId' requires a current evidence row"
        }
    }

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
        $hasConcreteSummary = @($summaryTables[0].Rows | Where-Object { $_.Cells.Count -eq 7 -and ($_.Cells[1..5] -join '') -match '\d' }).Count -gt 0
        if (($seenConcreteIds.Count -gt 0) -and (-not $hasConcreteSummary)) {
            Add-StructuralFailure $Path 'Status Summary must be populated when concrete AC rows exist'
        } elseif ($hasConcreteSummary -and $seenConcreteIds.Count -gt 0) {
            $summaryByCategory = @{}
            foreach ($row in $summaryTables[0].Rows) { if ($row.Cells.Count -eq 7) { $summaryByCategory[$row.Cells[0]] = $row.Cells } }
            foreach ($summaryCategory in $summaryCategories) {
                $categoryIds = @($acCategoryById.Keys | Where-Object { $acCategoryById[$_] -eq $summaryCategory })
                $expected = @(
                    $categoryIds.Count,
                    @($categoryIds | Where-Object { $acStatuses[$_] -eq '[x]' }).Count,
                    @($categoryIds | Where-Object { $acStatuses[$_] -in @('[ ]','[~]') }).Count,
                    @($categoryIds | Where-Object { $acStatuses[$_] -match '^\[!\]' }).Count,
                    @($categoryIds | Where-Object { $acStatuses[$_] -in @('[>]','[-]') }).Count
                )
                if (-not $summaryByCategory.ContainsKey($summaryCategory)) { continue }
                $cells = $summaryByCategory[$summaryCategory]
                for ($index = 0; $index -lt $expected.Count; $index++) {
                    if ($cells[$index + 1] -notmatch '^\d+$' -or [int]$cells[$index + 1] -ne $expected[$index]) {
                        Add-StructuralFailure $Path "Status Summary '$summaryCategory' column $($index + 1) is $($cells[$index + 1]); expected $($expected[$index])"
                    }
                }
            }
        }
    }

}

function Test-AcSchema3NegativeCases {
    param([string]$TemplatePath)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $testRoot = Join-Path $tempBase ("add-ac-schema3-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    try {
        $base = Get-Content -Raw -LiteralPath $TemplatePath -Encoding utf8
        $base = $base.Replace('| AC-<next integer> | {{description}} | [ ] | {{command / test / UI action}} | {{what passing looks like}} |', '| AC-1 | The feature works. | [x] | Run test. | Test passes. |')
        $base = $base.Replace('| AC-<id> | {{YYYY-MM-DD HH:mm timezone or N/A}} | AUTO \| MANUAL \| REVIEW \| EXECUTION \| BLOCKED | PASS \| FAIL \| PENDING IMPLEMENTATION \| PENDING MANUAL \| AFFECTED \| BLOCKED \| RECOVERY STATE | {{concise result and stable locator, or N/A}} | {{exact Mode B tuple above, completed, or N/A}} |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |')
        $base = $base.Replace('| Features | | | | | | |', '| Features | 1 | 1 | 0 | 0 | 0 | |')
        foreach ($category in @('Performance','Compatibility','Quality','Backlog / Deferred')) {
            $base = $base.Replace("| $category | | | | | | |", "| $category | 0 | 0 | 0 | 0 | 0 | |")
        }

        $cases = @(
            @{ Name = 'blank concrete summary'; Expected = 'Status Summary must be populated when concrete AC rows exist'; Content = $base.Replace('| Features | 1 | 1 | 0 | 0 | 0 | |', '| Features | | | | | | |').Replace('| Performance | 0 | 0 | 0 | 0 | 0 | |', '| Performance | | | | | | |').Replace('| Compatibility | 0 | 0 | 0 | 0 | 0 | |', '| Compatibility | | | | | | |').Replace('| Quality | 0 | 0 | 0 | 0 | 0 | |', '| Quality | | | | | | |').Replace('| Backlog / Deferred | 0 | 0 | 0 | 0 | 0 | |', '| Backlog / Deferred | | | | | | |') },
            @{ Name = 'duplicate evidence'; Expected = 'Duplicate current-evidence row'; Content = $base.Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', "| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |`n| AC-1 | 2026-09-03 12:01 +08:00 | AUTO | PASS | Duplicate. | completed |") },
            @{ Name = 'missing pass evidence'; Expected = 'requires one current PASS evidence row'; Content = $base.Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '') },
            @{ Name = 'manual conclusion mismatch'; Expected = "requires current conclusion 'PENDING MANUAL'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [manual] | Inspect UI. | UI is correct. |') },
            @{ Name = 'pending implementation wrong type'; Expected = "PENDING IMPLEMENTATION requires current-evidence type 'EXECUTION'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PENDING IMPLEMENTATION | Approved edit. | N/A |') },
            @{ Name = 'pending implementation wrong status'; Expected = "PENDING IMPLEMENTATION requires AC status '[~]'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | PENDING IMPLEMENTATION | Approved edit. | N/A |') },
            @{ Name = 'arbitrary recovery state'; Expected = 'Invalid Mode B Recovery State'; Content = $base.Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed. | arbitrary |') },
            @{ Name = 'failed evidence marked completed'; Expected = "Recovery State 'completed' requires settled PASS evidence"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | completed |') },
            @{ Name = 'pending evidence marked completed'; Expected = "Recovery State 'completed' requires settled PASS evidence"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PENDING IMPLEMENTATION | Pending. | completed |') },
            @{ Name = 'unimplemented pass'; Expected = 'cannot have conclusion'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Stale pass. | N/A |') },
            @{ Name = 'partial blocked conclusion'; Expected = 'has incompatible conclusion'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | BLOCKED | BLOCKED | Blocked. | N/A |') },
            @{ Name = 'duplicate unfinished series'; Expected = 'Duplicate unfinished Mode B series'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', "| AC-1 | The feature works. | [~] | Run test. | Test passes. |`n| AC-2 | Another feature works. | [~] | Run test. | Test passes. |").Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', "| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |`n| AC-2 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |") },
            @{ Name = 'malformed Mode B recovery'; Expected = 'Invalid Mode B Recovery State'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-bad; attempt: 1 |') },
            @{ Name = 'blocked Mode B recovery conclusion'; Expected = "requires current conclusion 'BLOCKED'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [blocked] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Third failure. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 3; limit: 3; kind: normal; state: blocked |') },
            @{ Name = 'Mode B failure wrong type'; Expected = "state failed requires current-evidence type 'EXECUTION' or 'MANUAL'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | FAIL | Failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |') },
            @{ Name = 'Mode B failure wrong AC status'; Expected = 'Mode B state failed requires AC status'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |') },
            @{ Name = 'Mode B transition marked pass'; Expected = "state authorized requires current conclusion 'RECOVERY STATE'"; Content = $base.Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | PASS | Authorized. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 4; limit: 4; kind: guided; state: authorized |') },
            @{ Name = 'Mode B failed at limit'; Expected = 'state failed requires a positive pre-limit attempt'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Third failure. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 3; limit: 3; kind: normal; state: failed |') },
            @{ Name = 'Mode B execution blocked before limit'; Expected = 'verification block requires attempt equal to limit'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [blocked] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | BLOCKED | Premature block. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: blocked |') },
            @{ Name = 'Mode B blocked wrong AC status'; Expected = 'Mode B state blocked requires AC status'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | BLOCKED | BLOCKED | Environment unavailable. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: blocked |') },
            @{ Name = 'Mode B reset wrong attempt'; Expected = 'state reset requires attempt 0/3 with normal kind'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Reset. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: reset |') },
            @{ Name = 'Mode B transition terminal AC'; Expected = 'Mode B state reset requires AC status'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [>] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Reset. | series: MB-20260903-1; approach_ref: D-2; attempt: 0; limit: 3; kind: normal; state: reset |') },
            @{ Name = 'Mode B pending manual wrong type'; Expected = "state pending-manual requires current-evidence type 'MANUAL'"; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [manual] | Inspect UI. | UI is correct. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | PENDING MANUAL | Awaiting user. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: pending-manual |') },
            @{ Name = 'Mode B at-limit resume'; Expected = 'state resumed requires an attempt below limit'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Invalid resume. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 3; limit: 3; kind: normal; state: resumed |') },
            @{ Name = 'legacy EVD append'; Expected = 'must not append legacy EVD'; Content = $base.Replace('## Status Annotation Convention', "### EVD-20260903-1 - AC-1`n`nLegacy event.`n`n## Status Annotation Convention") },
            @{ Name = 'verification citation'; Expected = 'must contain only reusable verification'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [x] | Run test. Evidence: EVD-20260903-1 | Test passes. |') }
        )

        foreach ($case in $cases) {
            $path = Join-Path $testRoot (($case.Name -replace '[^a-z ]','' -replace ' ','-') + '.md')
            [IO.File]::WriteAllText($path, [string]$case.Content, [Text.UTF8Encoding]::new($false))
            $before = $failures.Count
            Test-AcTemplateStructure $path 'en'
            $added = @()
            if ($failures.Count -gt $before) { $added = @($failures.GetRange($before, $failures.Count - $before)) }
            $expectedPattern = [regex]::Escape([string]$case.Expected)
            if (-not ($added | Where-Object { $_ -match $expectedPattern })) {
                $failures.Add("Schema 3 negative fixture '$($case.Name)' did not produce '$($case.Expected)'.")
            }
            if ($added.Count -gt 0) { $failures.RemoveRange($before, $added.Count) }
        }

        $validCases = @(
            @{ Name = 'pre-limit failure'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | First failure. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |') },
            @{ Name = 'at-limit block'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [blocked] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | BLOCKED | Three failures; needs guidance. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 3; limit: 3; kind: normal; state: blocked |') },
            @{ Name = 'external block before limit'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [blocked] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | BLOCKED | BLOCKED | Required environment unavailable. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: blocked |') },
            @{ Name = 'guided authorization'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Guided attempt authorized. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 4; limit: 4; kind: guided; state: authorized |') },
            @{ Name = 'redesign reset'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | New approach approved. | series: MB-20260903-2; approach_ref: D-2; attempt: 0; limit: 3; kind: normal; state: reset |') },
            @{ Name = 'cancelled before code'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Cancelled before code. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 0; limit: 3; kind: normal; state: cancelled |') },
            @{ Name = 'rejected with retained work'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Rejected with retained work. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: rejected |') },
            @{ Name = 'same-series resumption'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [ ] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | RECOVERY STATE | Work resumed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: resumed |') },
            @{ Name = 'pending implementation'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Run test. | Test passes. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | PENDING IMPLEMENTATION | Approved edit persisted; implementation pending. | N/A |') },
            @{ Name = 'pending manual normal'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [manual] | Inspect UI. | UI is correct. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | MANUAL | PENDING MANUAL | Awaiting user. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: pending-manual |') },
            @{ Name = 'pending manual guided'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [manual] | Inspect UI. | UI is correct. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | MANUAL | PENDING MANUAL | Awaiting guided check. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 4; limit: 4; kind: guided; state: pending-manual |') },
            @{ Name = 'normal manual failure'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [~] | Inspect UI. | UI is correct. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | MANUAL | FAIL | User reported failure. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 2; limit: 3; kind: normal; state: failed |') },
            @{ Name = 'guided manual failure blocks'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', '| AC-1 | The feature works. | [!] [blocked] | Inspect UI. | UI is correct. |').Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | MANUAL | BLOCKED | Guided user check failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 4; limit: 4; kind: guided; state: blocked |') },
            @{ Name = 'manual pass closes series'; Content = $base.Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', '| AC-1 | 2026-09-03 12:00 +08:00 | MANUAL | PASS | User reported pass. | completed |') },
            @{ Name = 'distinct unfinished series'; Content = $base.Replace('| AC-1 | The feature works. | [x] | Run test. | Test passes. |', "| AC-1 | The feature works. | [~] | Run test. | Test passes. |`n| AC-2 | Another feature works. | [~] | Run test. | Test passes. |").Replace('| AC-1 | 2026-09-03 12:00 +08:00 | AUTO | PASS | Test passed; report/test.log. | completed |', "| AC-1 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-20260903-1; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |`n| AC-2 | 2026-09-03 12:00 +08:00 | EXECUTION | FAIL | Failed. | series: MB-20260903-2; approach_ref: approved-chat; attempt: 1; limit: 3; kind: normal; state: failed |").Replace('| Features | 1 | 1 | 0 | 0 | 0 | |', '| Features | 2 | 0 | 2 | 0 | 0 | |') }
        )
        foreach ($case in $validCases) {
            if ($case.Name -in @('at-limit block','external block before limit','pending manual normal','pending manual guided','guided manual failure blocks')) {
                $case.Content = $case.Content.Replace('| Features | 1 | 1 | 0 | 0 | 0 | |', '| Features | 1 | 0 | 0 | 1 | 0 | |')
            } elseif ($case.Name -notin @('distinct unfinished series','manual pass closes series')) {
                $case.Content = $case.Content.Replace('| Features | 1 | 1 | 0 | 0 | 0 | |', '| Features | 1 | 0 | 1 | 0 | 0 | |')
            }
        }
        foreach ($case in $validCases) {
            $path = Join-Path $testRoot ("valid-" + ($case.Name -replace '[^a-z ]','' -replace ' ','-') + '.md')
            [IO.File]::WriteAllText($path, [string]$case.Content, [Text.UTF8Encoding]::new($false))
            $before = $failures.Count
            Test-AcTemplateStructure $path 'en'
            if ($failures.Count -gt $before) {
                $added = @($failures.GetRange($before, $failures.Count - $before))
                $failures.RemoveRange($before, $added.Count)
                $failures.Add("Schema 3 positive fixture '$($case.Name)' failed: $($added -join '; ')")
            }
        }
    }
    finally {
        $resolvedRoot = [IO.Path]::GetFullPath($testRoot)
        if ($resolvedRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedRoot)) {
            Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
        }
    }
}

function Test-ImplementationPlanStructure {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { $failures.Add("Missing implementation plan template: $Path"); return }
    $frontMatter = Get-FrontMatter $Path
    if (-not $frontMatter.IsValid) { Add-StructuralFailure $Path 'Plan template must begin with closed YAML frontmatter'; return }
    if ($frontMatter.DuplicateKeys.Count -gt 0) { Add-StructuralFailure $Path "Plan frontmatter contains duplicate keys: $($frontMatter.DuplicateKeys -join ', ')" }
    $requiredFields = @('template','schema','plan_id','project','status','pause_reason','mode','created','updated','code_root','worktree_id','branch','baseline_commit','supersedes_plan','active_tasks','target_acs','approach_ref','scope_decision_ids')
    foreach ($field in $requiredFields) {
        if (-not $frontMatter.Values.ContainsKey($field)) { Add-StructuralFailure $Path "Plan frontmatter is missing identity/recovery field '$field'" }
    }
    if ($frontMatter.Values['template'] -ne 'add-implementation-plan') { Add-StructuralFailure $Path 'Plan frontmatter template must be add-implementation-plan' }
    if ($frontMatter.Values['schema'] -ne '2') { Add-StructuralFailure $Path 'Plan frontmatter schema must be 2' }
    if ($frontMatter.Values['status'] -ne 'active') { Add-StructuralFailure $Path 'A new persistent plan template must start with status: active' }
    if ($frontMatter.Values['mode'] -ne 'A') { Add-StructuralFailure $Path 'Persistent plan template must use Mode A' }
    if ($frontMatter.Values['active_tasks'] -ne '[]') { Add-StructuralFailure $Path 'A new plan must start with active_tasks: [] until PLAN-1 becomes in_progress' }
    foreach ($field in @('plan_id','project','status','pause_reason','created','updated','code_root','worktree_id','branch','baseline_commit','supersedes_plan','approach_ref')) {
        if ($frontMatter.Values.ContainsKey($field) -and [string]::IsNullOrWhiteSpace($frontMatter.Values[$field])) { Add-StructuralFailure $Path "Plan frontmatter field '$field' must not be empty" }
    }
    if ($frontMatter.Values['supersedes_plan'] -ne 'N/A') { Add-StructuralFailure $Path 'A new ordinary plan must start with supersedes_plan: N/A' }
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
    $handoff = Get-MarkdownSectionContent $document 2 'Agent Handoff'
    if ($null -eq $handoff) { Add-StructuralFailure $Path 'Plan template must contain Agent Handoff' }
    else {
        foreach ($field in @('Goal','Implemented','Verification','Last safe commit','Unresolved','Worktree notes')) {
            if ($handoff -notmatch ('(?m)^-\s+\*\*' + [regex]::Escape($field) + ':\*\*')) { Add-StructuralFailure $Path "Agent Handoff is missing '$field'" }
        }
    }
    foreach ($field in @('Last safe commit','Working tree baseline','Blocked tasks','Next ready tasks')) {
        if ($content -notmatch ('(?m)^-\s+\*\*' + [regex]::Escape($field) + ':\*\*')) { Add-StructuralFailure $Path "Recovery State is missing '$field'" }
    }
    if ($content -notmatch '(?m)^-\s+\*\*Active tasks:\*\*\s+N/A\s*$') { Add-StructuralFailure $Path 'A new plan Recovery State must start with Active tasks: N/A' }
    if ($content -notmatch '(?m)^-\s+\*\*Local commits / COMMIT-BLOCKED / COMMIT-SKIPPED / COMMIT-REVIEW-REQUIRED:\*\*') { Add-StructuralFailure $Path 'Plan Final Record must represent every checkpoint outcome' }
    if ($content -notmatch '(?m)^-\s+\*\*Acceptance record:\*\*\s+`AC\.md`') { Add-StructuralFailure $Path 'Plan Final Record must point to AC.md' }
    if ($content -match '(?m)^-\s+\*\*(?:Final AC outcomes|Current evidence):\*\*') { Add-StructuralFailure $Path 'Plan Final Record must not copy AC outcomes or current evidence' }
    if ($content -notmatch '(?m)^-\s+\*\*Project capsule update:\*\*') { Add-StructuralFailure $Path 'Plan Final Record must record the project-capsule update outcome' }
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

function Test-ReadmeContextSection {
    param([string]$Path, [ValidateSet('en','zh')][string]$Language)
    $section = Get-Level2Section $Path 'v2.7.0'
    if ($null -eq $section) { Add-StructuralFailure $Path 'README must contain a level-2 v2.7.0 context section'; return }
    if ($Language -eq 'en') {
        $termGroups = @(
            @('Schema 3','Current Verification Evidence','AC ID','at most one row','[x]','PASS'),
            @('new Agent/session','_exp_memory.md','once','Mode A','Mode B','_<ProjectName>_exp.md'),
            @('at most 12','difficult','non-obvious','verified lessons','completed Mode A','Mode B never writes'),
            @('Agent Handoff','plan frontmatter','active plan','latest completed plan'),
            @('low-risk','Architecture','dependency behavior','concurrency','persistence','security','migrations','public contracts','Mode A'),
            @('project-experience','ordinary coding','explicit cross-project research','global-cache refreshes')
        )
    } else {
        $termGroups = @(
            @('Schema 3','当前验证证据','AC ID','最多一行','[x]','PASS'),
            @('新 Agent/新会话','_exp_memory.md','只读一次','Mode A','Mode B','_<ProjectName>_exp.md'),
            @('最多 12 条','困难','非显然','已验证经验','completed','Mode B 永不写'),
            @('Agent Handoff','计划 frontmatter','活动计划','最近完成计划'),
            @('低风险','架构','依赖行为','并发','持久化','安全','迁移','公共契约','Mode A'),
            @('project-experience','普通编码','显式跨项目研究','全局缓存刷新')
        )
    }
    foreach ($terms in $termGroups) {
        $missing = @($terms | Where-Object { $section.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -lt 0 })
        if ($missing.Count -gt 0) { Add-StructuralFailure $Path "v2.7.0 context section is missing linked contract terms: $($missing -join ', ')" }
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
    $requiredScenarios = @('blocked-redesign','pre-approval-cancel','post-persistence-cancel','delegate-cancel','active-plan-reentry','paused-plan-restart','active-plan-conflict','manual-pass','mode-b-manual-pending','mode-b-recovery','mode-b-cancel-restart','test-first-red','blocked-subset-review','blocked-alternate-path','guided-retry-status','mode-a-redesign-plan','guided-mode-transition','external-environment-block','cleared-environment-block','mode-a-to-b-handoff','mode-a-to-b-interruption-recovery','post-approval-rejection','global-experience-session','project-capsule-work-unit','project-capsule-bootstrap','project-capsule-completion','project-capsule-seed-source','project-experience-explicit-only','agent-handoff-active-plan','agent-handoff-latest-completed','layered-ac-reading','conditional-template-reading','conditional-implementation-reference','mode-b-same-series-retry','mode-b-phase6-recovery','mode-b-blocked-conclusion','paused-plan-owner','risk-based-mode-selection','approved-plan-supersession','approved-plan-supersession-recovery','mode-b-to-a-attempt-import','manual-ready-work-drain','completed-plan-identity','missing-cache-read-only-fallback','capsule-refresh-provenance','project-level-auto-activation','explicit-nonproject-activation','activation-gate-early-exit','delivery-only-no-ac','delivery-change-reentry')
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
$improvementGuide = Join-Path $ReleaseRoot 'docs\IMPROVEMENT-GUIDE.md'
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
Require-ClauseTerms $add @('low-frequency project finalization','project document','durable facts','completion status') 'ADD must define low-frequency project-document finalization.'
Require-NoMatch $add '(?m)^- \*\*Yes\*\* → delete \$DOC_HUB/_exp_memory\.md' 'ADD must not delete the cache to request a refresh.'
Require-Match $experience 'Legacy cache fallback' 'project-experience must retain a legacy-cache fallback.'
Require-Match $experience 'cache_schema: 2' 'project-experience must define cache schema 2 metadata.'
Require-Match $experience 'Development-project evidence gate' 'project-experience must define active-project evidence rules.'
Require-ClauseTerms $experience @('explicitly asks','compare','across projects','refresh','_exp_memory.md') 'project-experience must be limited to explicit cross-project research and cache refresh.'
Require-ClauseTerms $experience @('Do not use','ordinary coding','small changes','Mode A/Mode B') 'project-experience must not trigger during routine ADD execution.'
Require-NoMatch $experience '(?m)^description: Use when writing code' 'project-experience metadata must not trigger on ordinary coding.'
Require-ClauseTerms $add @('new Agent/session','_exp_memory.md','once','Do not read it again') 'ADD must bound global experience reads to one per new Agent/session.'
Require-ClauseTerms $add @('$DOC_HUB/<ProjectName>/_<ProjectName>_exp.md','start of every independent ADD work unit','read','once') 'ADD must read the project-specific capsule once per work unit.'
Require-ClauseTerms $add @('capsule is absent','at most three','global cache already read','create') 'ADD must initialize a missing project capsule from the current session cache read.'
Require-ClauseTerms $add @('flat list','at most 12','difficult','non-obvious','verified lessons','source plan') 'ADD must keep project experience bounded and evidence-based.'
Require-ClauseTerms $add @('Experience content changes only after','successfully completed','non-superseded Mode A plan','Mode B','never add lessons') 'ADD must update project lessons only after successful Mode A plans.'
Require-ClauseTerms $add @('latest_completed_plan','updated after each such plan','no lesson changes') 'ADD must maintain the latest successful completed-plan pointer independently of lesson changes.'
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
Require-Match $codexGuide '## Activation in Codex' 'Codex guide must expose its activation boundary.'
Require-ClauseTerms $codexGuide @('Auto-activate ADD only','persistent project') 'Codex guide must preserve project-level automatic activation.'
Require-ClauseTerms $codexGuide @('explicit ADD invocation','current continuous work unit','exit before Phase 0') 'Codex guide must scope explicit activation and early exit.'
Require-ClauseTerms $codexGuide @('delivery-only','create no AC','WIP','Remote operations require an explicit request') 'Codex guide must preserve delivery-operation boundaries.'
Require-ClauseTerms $improvementGuide @('严格混合触发','当前连续工作单元') 'Maintainer guide must preserve mixed activation scope.'
Require-ClauseTerms $improvementGuide @('Activation Gate 位于 Phase 0 前','交付操作','不新建 AC','实际项目改动') 'Maintainer guide must preserve early-exit and delivery-operation boundaries.'
Require-ClauseTerms $improvementGuide @('WIP 快照','不能创建 AC','实际改动走 Phase 3.5') 'Maintainer principles must distinguish WIP delivery from actual changes.'
Require-Match $readme '# Acceptance-Driven Development \(ADD\) v2\.7\.0' 'English README must identify v2.7.0.'
Require-Match $readme 'A real project-level workflow for AI coding agents' 'English README must retain the project-level value proposition.'
Require-Match $readme '## Your agent said “done.” You disagree.' 'English README must open with the human problem story.'
Require-Match $readme '## How ADD closes the loop' 'English README must show the ADD closed loop.'
Require-Match $readme '## Before ADD / After ADD' 'English README must include before/after proof.'
Require-Match $readme '## A complete development engine, not a checklist bolted on at the end' 'English README must present the complete ADD capability set before installation.'
Require-Match $readme '## One workflow across different coding agents' 'English README must explain cross-agent portability.'
Require-Match $readme '(?s)(?:```mermaid.*?){3}' 'English README must retain at least three Mermaid diagrams.'
Require-Match $readme '## Try ADD in 60 seconds' 'English README must include a 60-second experience before installation.'
Require-NoMatch $readme 'On the first code-related request' 'English README must not imply that every code-related request activates ADD.'
Require-ClauseTerms $readme @('persistent project','invoke ADD once','unrelated one-off script','does not carry into unrelated work') 'English README must explain automatic and explicit activation boundaries.'
Require-ClauseTerms $readme @('delivery operations','do not create ACs','WIP snapshot','Activation Gate') 'English README must explain delivery-only and early-exit boundaries.'
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
Require-Match $readmeZh '# 验收驱动开发（ADD）v2\.7\.0' 'Chinese README must identify v2.7.0.'
Require-Match $readmeZh '真正的项目级 AI 开发工作流' 'Chinese README must retain the project-level value proposition.'
Require-Match $readmeZh '## 你的 Agent 说“完成了”。你并不相信。' 'Chinese README must open with the human problem story.'
Require-Match $readmeZh '## ADD 如何闭环' 'Chinese README must show the ADD closed loop.'
Require-Match $readmeZh '## 使用 ADD 前后' 'Chinese README must include before/after proof.'
Require-Match $readmeZh '## 不只是验收清单，而是一台完整的开发引擎' 'Chinese README must present the complete ADD capability set before installation.'
Require-Match $readmeZh '## 一套工作流，适配不同编码 Agent' 'Chinese README must explain cross-agent portability.'
Require-Match $readmeZh '(?s)(?:```mermaid.*?){3}' 'Chinese README must retain at least three Mermaid diagrams.'
Require-Match $readmeZh '## 一条请求看懂 ADD' 'Chinese README must include a 60-second experience before installation.'
Require-NoMatch $readmeZh '首次收到代码相关请求' 'Chinese README must not imply that every code-related request activates ADD.'
Require-ClauseTerms $readmeZh @('持久项目','显式调用 ADD 一次','无关的一次性脚本','不会延伸到后续无关任务') 'Chinese README must explain automatic and explicit activation boundaries.'
Require-ClauseTerms $readmeZh @('交付操作','不创建 AC','WIP 快照','Activation Gate') 'Chinese README must explain delivery-only and early-exit boundaries.'
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
Test-ReadmeContextSection $readme 'en'
Test-ReadmeContextSection $readmeZh 'zh'
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
$recoveryRef = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\references\failure-recovery-and-cancellation.md'
$acAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-template.md'
$acAssetZh = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-template-zh.md'
$implementationPlanAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\implementation-plan-template.md'
$acTableCss = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\ac-document-tables.css'
$projectDocAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-doc-template.md'
$projectCapsuleAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-experience-capsule-template.md'
$projectCapsuleAssetZh = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-experience-capsule-template-zh.md'
$projectIndexAsset = Join-Path $ReleaseRoot 'skills\acceptance-driven-development\assets\project-index.md'
$acTemplate = Join-Path $ReleaseRoot 'projects\templates\ac-template.md'
$acTableCssTemplate = Join-Path $ReleaseRoot 'projects\templates\ac-document-tables.css'
$projectDocTemplate = Join-Path $ReleaseRoot 'projects\templates\project-doc-template.md'
$projectIndexTemplate = Join-Path $ReleaseRoot 'projects\templates\project-index.md'
$workflowFixtures = Join-Path $ReleaseRoot 'tests\fixtures\workflow-transitions.json'
$addLineCount = (Get-Content -LiteralPath $add -Encoding utf8).Count
$designExplorationLineCount = (Get-Content -LiteralPath $designExploration -Encoding utf8).Count
$implementationRefLineCount = (Get-Content -LiteralPath $implementationRef -Encoding utf8).Count
$recoveryRefLineCount = (Get-Content -LiteralPath $recoveryRef -Encoding utf8).Count
$acContractWordContent = Get-Content -Raw -LiteralPath $acContractRef -Encoding utf8
$addWordContent = Get-Content -Raw -LiteralPath $add -Encoding utf8
$implementationWordContent = Get-Content -Raw -LiteralPath $implementationRef -Encoding utf8
$recoveryWordContent = Get-Content -Raw -LiteralPath $recoveryRef -Encoding utf8
$addWordCount = [regex]::Matches($addWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$implementationRefWordCount = [regex]::Matches($implementationWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$recoveryRefWordCount = [regex]::Matches($recoveryWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$mandatoryImplementationWordCount = $addWordCount + $implementationRefWordCount + [regex]::Matches($acContractWordContent, '\b[\p{L}\p{N}_-]+\b').Count
$overlongOperationalLines = @(
    (Get-Content -LiteralPath $add -Encoding utf8)
    (Get-Content -LiteralPath $implementationRef -Encoding utf8)
    (Get-Content -LiteralPath $recoveryRef -Encoding utf8)
) | Where-Object { $_.Length -gt 400 }
if ($addLineCount -gt 380) { $failures.Add("ADD main skill exceeds 380-line operational budget: $addLineCount") }
if ($designExplorationLineCount -gt 120) { $failures.Add("ADD design exploration exceeds 120-line conditional-reference budget: $designExplorationLineCount") }
if ($implementationRefLineCount -gt 140) { $failures.Add("ADD implementation reference exceeds 140-line conditional-reference budget: $implementationRefLineCount") }
if ($recoveryRefLineCount -gt 100) { $failures.Add("ADD recovery reference exceeds 100-line conditional-reference budget: $recoveryRefLineCount") }
if ($addWordCount -gt 3300) { $failures.Add("ADD main skill exceeds 3300-word operational budget: $addWordCount") }
if ($implementationRefWordCount -gt 1900) { $failures.Add("ADD implementation reference exceeds 1900-word conditional-reference budget: $implementationRefWordCount") }
if ($recoveryRefWordCount -gt 1300) { $failures.Add("ADD recovery reference exceeds 1300-word conditional-reference budget: $recoveryRefWordCount") }
if ($mandatoryImplementationWordCount -gt 6000) { $failures.Add("Typical implementation load exceeds 6000 words: $mandatoryImplementationWordCount") }
if ($overlongOperationalLines.Count -gt 0) { $failures.Add("ADD operational files contain $($overlongOperationalLines.Count) line(s) longer than 400 characters.") }
if (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'skills\acceptance-driven-development\IMPROVEMENT-GUIDE.md')) { $failures.Add('Maintainer improvement guide must not ship inside the runtime skill directory.') }
if (-not (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'docs\IMPROVEMENT-GUIDE.md'))) { $failures.Add('Maintainer improvement guide must remain available under docs/.') }
foreach ($referenceFile in @($guardrailsRef, $changeGuideRef, $frameworkReviewRef, $acContractRef, $designExploration, $implementationRef, $recoveryRef)) {
    if (-not (Test-Path -LiteralPath $referenceFile)) { $failures.Add("Missing ADD compression reference: $referenceFile") }
}
Require-Match $add 'FIRST RULE' 'ADD main skill must retain FIRST RULE.'
Require-ClauseTerms $add @('description: Use when','explicitly requested as ADD','acceptance criteria','done conditions','identifiable persistent software project') 'ADD discovery metadata must define only positive explicit and project-level triggers.'
Require-NoMatch $add 'description: Use when implementing features' 'ADD discovery metadata must not auto-activate for every generic feature request.'
Require-NoMatch $add '(?m)^description:.*questions|^description:.*read-only|^description:.*one-off|^description:.*Git/package/release' 'ADD discovery metadata must not include negative-scenario keywords that can cause host-level false activation.'
Require-Match $add '## Activation Gate' 'ADD must expose the activation gate before Phase 0.'
Require-ClauseTerms $add @('Auto-activate only','identifiable persistent project','explicit invocation','current work unit','not unrelated work') 'ADD must retain the mixed automatic/explicit activation boundary.'
Require-ClauseTerms $add @('Without that invocation','questions','read-only/prose work','unrelated one-off scripts','delivery-only Git/package/release operations','stop before Phase 0') 'ADD must exit excluded requests before project context loading.'
Require-ClauseTerms $add @('Only actual project changes enter Phase 3.5') 'Delivery operations must re-enter ADD only for actual project changes.'
Require-Match $add 'Phase 3\.5A: Approved Backlog Entry' 'ADD main skill must retain Phase 3.5A.'
Require-Match $add 'Phase 3\.5B: Mid-Development Requirement Changes' 'ADD main skill must retain Phase 3.5B.'
Require-Match $add 'Review checklist \(6 items' 'ADD main skill must retain six-point review.'
Require-Match $add 'Only mark `\[x\]` after FRESH verification' 'ADD main skill must retain fresh verification.'
Require-Match $add 'Living Project Document' 'ADD main skill must retain living project-document lifecycle.'
Require-Match $add 'Existing project but missing AC\.md' 'ADD main skill must distinguish a missing AC in an existing project from Greenfield.'
Require-Match $add '_exp_memory\.md\.tmp' 'ADD main skill must retain atomic cache refresh.'
Require-Match $add 'references/guardrails-and-examples\.md' 'ADD main skill must point to guardrails/examples reference.'
Require-Match $add 'references/change-design-guide\.md' 'ADD main skill must point to change-design reference.'
Require-Match $add 'Mode choice after Phase 3\.5B persistence' 'ADD must select implementation mode only after approved AC persistence.'
Require-NoMatch $add 'Mode choice after confirmed Phase 3\.5B' 'ADD must not require confirmation for every Phase 3.5B mode choice.'
Require-ClauseTerms $add @('baseline validation fails','appropriate Phase 3.5 entry','before review') 'Baseline-validation fixes must not bypass Phase 3.5.'
Require-Match $add 'A repair within the approved AC and approach returns through Phase 3\.5A without reapproval' 'ADD must route same-scope AUTO repairs through approved backlog without duplicate approval.'
Require-Match $add 'Settle `\[~\]`: fix through the appropriate Phase 3\.5 entry' 'ADD must define the [~]-to-[x] completion transition without bypassing Phase 3.5.'
Require-Match $guardrailsRef 'Phase 3\.5A backlog work uses Mode A' 'Guardrails must preserve Mode A for approved backlog work.'
Require-NoMatch $guardrailsRef 'still enters Phase 3\.5 and Mode B' 'Guardrails must not route every one-line code change to Mode B.'
Require-Match $guardrailsRef 'A code change has no relevant AC' 'Guardrails must require a confirmed tracking AC for every in-scope code change.'
Require-ClauseTerms $guardrailsRef @('snapshot or package','delivery-only','Preserve current acceptance state','actual project changes') 'Guardrails must distinguish delivery operations from project changes.'
Require-ClauseTerms $guardrailsRef @('fails the Activation Gate','Stop before Phase 0','do not read the Hub','Handle normally') 'Guardrails must stop false activations before project context loading.'
Require-Match $add 'Code formatting or typo fixes still enter Phase 3\.5B fast lane' 'ADD must not exempt code formatting or typo fixes from Phase 3.5.'
Require-Match $add 'After validation or user confirmation, write `~/.add-hub`' 'ADD must persist only a validated or confirmed fallback document-hub selection.'
Require-ClauseTerms $add @('final approval','save','AC.md','enter Phases 1–3') 'ADD must define the Gate 2 success transition.'
Require-Match $add 'Complete Phase 4\.8: fresh baseline validation' 'Mode A must require Phase 4.8 before Phase 5.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, re-run baseline validation, then review again' 'Review fixes must re-enter Phase 3.5 and rerun baseline validation.'
Require-Match $add 'changes batching/review only; changed AUTO follows AUTO' 'Mode B must preserve AUTO command verification.'
Require-ClauseTerms $add @('failed affected AUTO AC','either mode','regression','repair or defer') 'Affected AUTO regressions must require a user repair-or-defer decision.'
Require-Match $add 'fix through the appropriate Phase 3\.5 entry, then Phases 4–5' 'A [~] fix must not bypass Phase 3.5.'
Require-ClauseTerms $add @('project finalization','Create or read','project document','Step 0.4') 'Phase 6 must use the project-document gate for finalization.'
Require-Match $add 'references/framework-review-checklist\.md' 'ADD must retain the framework-review reference.'
foreach ($assetFile in @($acAsset, $acAssetZh, $acTableCss, $projectDocAsset, $projectCapsuleAsset, $projectCapsuleAssetZh, $projectIndexAsset, $implementationPlanAsset)) {
    if (-not (Test-Path -LiteralPath $assetFile)) { $failures.Add("Missing installable ADD asset: $assetFile") }
}
foreach ($capsuleTemplate in @($projectCapsuleAsset, $projectCapsuleAssetZh)) {
    Require-ClauseTerms $capsuleTemplate @('template: add-project-experience','schema: 1','project:','source_cache_revision:','latest_completed_plan:','updated:') 'Project experience capsule templates must define stable metadata and the completed-plan pointer.'
}
Require-Match $projectCapsuleAsset '(?s)12.*no predefined categories.*two sentences.*Source:.*_exp_memory\.md' 'English project experience capsule template must define concise, flat, source-attributed entries.'
Require-Match $projectCapsuleAssetZh '(?s)12.*不设置预定义分类.*两句话.*来源：.*_exp_memory\.md' 'Chinese project experience capsule template must define concise, flat, source-attributed entries.'
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
Require-Match $add 'references/failure-recovery-and-cancellation\.md' 'ADD must route exceptional recovery through its conditional reference.'
Require-Match $add 'assets/implementation-plan-template\.md.*\$DOC_HUB/<Project>/plans/' 'Mode A must copy the installed plan asset before code.'
Require-Match $add 'Execution Map.*do not create a persistent plan' 'Mode B must use a chat-only Execution Map.'
Require-Match $add 'without asking for plan approval' 'ADD must not make users review implementation plans.'
Require-Match $add 'safe local AC-scoped checkpoint' 'Both implementation modes must create safe local checkpoints.'
Require-ClauseTerms $add @('Schema 2','readable','separately approved migration') 'Schema 3 must not silently rewrite unmigrated existing AC documents.'
Require-ClauseTerms $add @('How to Verify','only reusable commands','current-evidence row') 'ADD must keep reusable verification separate from current results.'
Require-Match $add 'task/AC reaches the three-attempt boundary' 'The AC verification classes must cover implementation-exhaustion blocks.'
Require-ClauseTerms $add @('AUTO','replace','current-evidence row','Current Conclusion','PASS','mark `[x]`') 'Fresh AUTO success must persist current evidence before acceptance completion.'
Require-ClauseTerms $add @('Explicitly confirmed deferral/deprecation','[>]','[-]','scope decision') 'Explicit deferral or deprecation must settle a blocked AC.'
Require-Match $implementationRef 'Status.*AC mapping.*Depends on.*Files.*Interfaces.*Steps.*Test strategy.*Verification.*Review.*Commit.*Evidence' 'Mode A tasks must contain the fixed Agent-oriented schema.'
Require-Match $implementationRef 'TEST-FIRST.*CHARACTERIZATION.*TEST-AFTER.*MANUAL' 'Implementation tasks must use the four approved test strategies.'
Require-Match $implementationRef 'without asking for plan approval' 'Plans must self-check and execute without user review.'
Require-Match $recoveryRef 'three consecutive fail' 'Task failures must use the three-attempt boundary.'
Require-ClauseTerms $recoveryRef @('Mode A counts per','PLAN-N','Mode B counts per target AC','target') 'Failure counters must use explicit mode-specific units.'
Require-ClauseTerms $recoveryRef @('three consecutive failed cycles','Mode A removes the task','Mode B marks the target','[!] [blocked]','current evidence') 'The three-cycle boundary must define separate Mode A and Mode B block transitions.'
Require-ClauseTerms $recoveryRef @('one active plan','Agent Handoff','current evidence','git status','recent local commits','diff','identity','ancestry') 'Cross-session recovery must reconcile AC, plan, and Git evidence.'
Require-ClauseTerms $recoveryRef @('completed-plan','code_root','worktree_id','branch','baseline_commit','mismatched','historical context') 'Completed-plan handoff must verify repository identity before it is read.'
Require-ClauseTerms $recoveryRef @('Mode B has no persistent plan','latest Git commit','target AC','current evidence','Recovery State','approach_ref','repository diff') 'Mode B recovery must identify persisted state and approach sources.'
Require-ClauseTerms $recoveryRef @('cannot be reconstructed confidently','preserve AC scope/tree','Phase 3.5B','approach confirmation') 'Mode B recovery must not guess a lost approved approach.'
Require-ClauseTerms $recoveryRef @('three-failure block','one additional guided attempt','same series','attempt: 4','limit: 4') 'Guided recovery must retain its bounded extra attempt.'
Require-ClauseTerms $recoveryRef @('approved material redesign','[!] [blocked]','[ ]','no retained implementation','[~]','implementation remains','new series','attempt: 0','state: reset') 'Failure recovery must define persisted redesign state and conditional AC transitions.'
Require-ClauseTerms $recoveryRef @('exactly one recovery task','each unfinished Mode B target series','task Attempt','row''s locator','re-read','limit','kind','series identity','new task','attempt: 0','Never merge','copy the tuple') 'Mode B to Mode A recovery must preserve target-specific attempt state without copying AC evidence.'
Require-ClauseTerms $recoveryRef @('approved for replacement','status: paused','awaiting-approved-supersession','supersedes_plan','every unsettled target','old executable tasks','superseded','status: completed','superseded-by-approved-plan','sole owner','never reopened') 'Approved supersession must preserve exactly one recoverable plan owner at every step.'
Require-ClauseTerms $recoveryRef @('On cancellation','every delegate','stop new writes','wait for/drain','preserves tree/index/commits') 'Cancellation must preserve user and repository state by default.'
Require-Match $implementationRef 'COMMIT-BLOCKED' 'Unsafe local commits must report COMMIT-BLOCKED.'
Require-Match $implementationRef 'stage only Agent-owned paths or safely separable hunks' 'Local commits must isolate Agent-owned changes.'
Require-Match $implementationRef 'Never use broad staging such as `git add -A`' 'Local commits must forbid broad staging with unrelated changes.'
Require-Match $implementationRef 'index is pre-populated.*merge/rebase/cherry-pick is active' 'Local commits must block on unsafe index or repository operation state.'
Require-ClauseTerms $experience @('bounded, read-only fallback','at most two','do not write or block') 'Missing experience cache must degrade to bounded read-only research.'
Require-ClauseTerms $experience @('project-earned entries','source plan exists','completed','superseded-by-*','exclude `_exp_memory.md` seeds') 'Cache refresh must use successful project-capsule sources without ingesting global seeds.'
Require-Match $implementationRef 'COMMIT-SKIPPED: user instruction' 'Explicit user no-commit instructions must override automatic checkpoints.'
Require-ClauseTerms $implementationRef @("ADD's verified checkpoints",'delivery-only snapshot','WIP','creates no AC','changes no AC/task verification state','explicit WIP branches in steps 4-5','actual source','configuration','release-structure','observable-behavior changes') 'Implementation reference must distinguish verified ADD checkpoints from user-requested WIP snapshots.'
Require-ClauseTerms $implementationRef @('verified checkpoint','exact AC-group match','WIP snapshot','exact user-requested path match','explicit WIP message') 'Checkpoint step 4 must branch between verified AC scope and user-requested WIP scope.'
Require-ClauseTerms $implementationRef @('Include AC IDs only for a verified checkpoint','WIP snapshot omits AC IDs','stays unverified') 'Checkpoint step 5 must not bind WIP snapshots to AC IDs or verification.'
Require-ClauseTerms $implementationRef @('MANUAL','may commit','Agent checks','remaining','[!] [manual]') 'MANUAL work must permit a local checkpoint before user verification.'
Require-ClauseTerms $implementationRef @('Checkpoint','complete AC/related group','defer','later tasks remain') 'Local checkpoints must not split an incomplete AC across commits.'
Require-Match $implementationRef 'Permanently retain completed plans' 'Completed Mode A plans must be retained.'
Test-AcTemplateStructure $acAsset 'en'
Test-AcTemplateStructure $acAssetZh 'zh'
Test-AcTemplateStructure $acTemplate 'en'
Test-AcSchema3NegativeCases $acAsset
Test-ImplementationPlanStructure $implementationPlanAsset
Test-ModeBContract $add
Test-WorkflowTransitionFixtures $workflowFixtures @{ add = $add; guardrails = $guardrailsRef; implementation = $implementationRef; recovery = $recoveryRef; plan = $implementationPlanAsset; experience = $experience }
$exampleAcFiles = @(Get-ChildItem -LiteralPath (Join-Path $ReleaseRoot 'projects') -Recurse -File -Filter 'AC.md' | Where-Object { $_.FullName -notmatch '[\\/]templates[\\/]' })
foreach ($exampleAc in $exampleAcFiles) {
    $exampleLanguage = if ((Get-Content -Raw -LiteralPath $exampleAc.FullName -Encoding utf8) -match '验收标准') { 'zh' } else { 'en' }
    Test-AcTemplateStructure $exampleAc.FullName $exampleLanguage
}
$templateMirrors = @(
    @{ Installable = $acAsset; Manual = $acTemplate; Name = 'ac-template' },
    @{ Installable = $acTableCss; Manual = $acTableCssTemplate; Name = 'ac-document-tables' },
    @{ Installable = $projectDocAsset; Manual = $projectDocTemplate; Name = 'project-doc-template' },
    @{ Installable = $projectIndexAsset; Manual = $projectIndexTemplate; Name = 'project-index' }
)
foreach ($mirror in $templateMirrors) {
    if (-not (Test-Path -LiteralPath $mirror.Manual)) { $failures.Add("Missing manual $($mirror.Name) template.") }
    elseif ((Get-FileHash -LiteralPath $mirror.Installable -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $mirror.Manual -Algorithm SHA256).Hash) {
        $failures.Add("Installable and manual $($mirror.Name) templates must be identical.")
    }
}
foreach ($indexFile in @($projectIndexAsset, $projectIndexTemplate)) {
    Require-Match $indexFile 'FROM ""' 'Project index must discover project documents regardless of hub folder name.'
    Require-Match $indexFile 'template = "project-doc"' 'Project index must select project-document frontmatter.'
    Require-Match $indexFile 'contains\(tags, "项目"\).*contains\(tags, "project"\)' 'Project index must support the shipped Chinese tag and legacy English tag.'
    Require-Match $indexFile 'status = "开发中".*status = "维护中"' 'Project index active view must support shipped project statuses.'
}
Require-ClauseTerms $add @('project-index.md','Obsidian vault','user confirms','Dataview','available/enabled') 'ADD must seed the Dataview index only in a confirmed compatible Obsidian hub.'
Require-ClauseTerms $add @('document language','项目','project','开发中','active','已完成','completed','Do not mix') 'ADD project documents must support coherent Chinese and English metadata.'
Require-ClauseTerms $experience @('active','maintained','completed','archived','settled') 'Project experience must classify English project-document statuses.'
Require-ClauseTerms $experience @('status: 开发中','维护中','active','maintained','evidenced by code') 'English active projects must use the same evidence gate.'
Require-ClauseTerms $projectDocAsset @('定义结构','英文','tags: [project]','active','maintained','completed','archived','不得混用') 'Project-document template must explain English localization without duplicating schemas.'

# Link deterministic transition fixtures to executable workflow clauses.
Require-ClauseTerms $add @('approved redesign','[!] [blocked]','[ ]','[~]','attempt series') 'Blocked redesign must define both retained and non-retained implementation transitions.'
Require-ClauseTerms $recoveryRef @('On cancellation','delegate','wait for/drain','final tree') 'Cancellation must stop and settle delegates before reconciliation.'
Require-ClauseTerms $recoveryRef @('only target ACs with retained Agent implementation','not freshly accepted','[~]','untouched','[!] [affected]','unchanged') 'Cancellation after implementation must update only targets with retained work.'
Require-ClauseTerms $recoveryRef @('Mode A clears','active_tasks','status: paused','pause_reason: user-cancelled','never auto-resumes','explicit restart') 'Cancelled Mode A plans must not resume automatically.'
Require-ClauseTerms $implementationRef @('explicit restart','paused plans','same identity','AC','approach','baseline','exactly one matches','set it `active`','never create a replacement') 'Explicit restart must safely reuse one matching paused plan instead of duplicating it.'
Require-ClauseTerms $recoveryRef @('After approved AC persistence','before Agent code','new targets','[ ]','edited/resumed targets','persisted') 'Cancellation before code must preserve newly approved and edited AC states.'
Require-ClauseTerms $implementationRef @('plan matches','status: active','worktree','branch','baseline_commit','target_acs','approach_ref','Reuse') 'Active-plan re-entry must match identity, baseline, and approved approach before reuse.'
Require-ClauseTerms $implementationRef @('scope_decision_ids','may be','[]','legacy backlog','not an implementation-approach identifier') 'Legacy plans must allow no DEC without confusing scope decisions with approach identity.'
Require-ClauseTerms $add @('MANUAL','state: pending-manual','AC-N passed','PASS','Mode B','completed','only then mark','[x]') 'MANUAL pass must persist evidence and close Mode B recovery before marking the AC verified.'
Require-ClauseTerms $recoveryRef @('MANUAL handoff','creates or retains','series','MANUAL / PENDING MANUAL / state: pending-manual','failure uses `MANUAL`','advances normal series','blocks guided series','4/4','without increment') 'Mode B manual verification must preserve and advance its bounded series.'
Require-ClauseTerms $recoveryRef @('Expected','TEST-FIRST','red','do not count') 'An expected TEST-FIRST red result must not increment the failure counter.'
Require-NoMatch $recoveryRef '(?i)expected.{0,80}TEST-FIRST.{0,80}red.{0,80}(?<!not )counts? as (?:a )?fail' 'ADD must not contain a contradictory rule that counts expected TEST-FIRST red as failure.'
Require-ClauseTerms $recoveryRef @('newly discovered risk or impact','Mode B recovery','enter Mode A','same approved approach','import the attempt state','three new tries') 'Mode B recovery must preserve attempt state when a discovered mandatory risk escalates it to Mode A.'
Require-ClauseTerms $recoveryRef @('failed cycle before the limit','current evidence','EXECUTION','FAIL','series:','approach_ref:','attempt:','limit:','kind:','state: failed') 'Each pre-limit Mode B failure must persist complete series state with FAIL evidence.'
Require-ClauseTerms $recoveryRef @('At the limit','Conclusion','BLOCKED','reason/unblock condition','state: blocked') 'A Mode B failure at the limit must persist schema-consistent blocked evidence.'
Require-ClauseTerms $implementationRef @('paused plan frontmatter','target-AC overlap','user-cancelled','user-rejected','blocks replacement','explicit matched restart','approved supersession','never bypass') 'A paused Mode A owner must block replacement-plan bypass.'
Require-ClauseTerms $recoveryRef @('Each Mode B target','one','series','Scan current Recovery State','next unused','never share') 'Mode B series allocation must be collision-safe and target-specific.'
Require-ClauseTerms $recoveryRef @('approved material redesign','Mode B then replaces current evidence','new series','approach_ref','attempt: 0','state: reset') 'Mode B redesign must persist its reset before interruption can restore old failures.'
Require-ClauseTerms $recoveryRef @('User guidance','same series','current evidence','attempt: 4','limit: 4','kind: guided','state: authorized') 'Guided Mode B recovery must persist its one-extra-attempt boundary.'
Require-ClauseTerms $recoveryRef @('User guidance','blocked AC','[ ]','no retained implementation','[~]','implementation remains','Mode A','pending','attempt 4/4') 'Guided recovery must reactivate both AC status branches without resetting Mode A attempts.'
Require-ClauseTerms $recoveryRef @('selection remains Mode A','sole active plan','update','approach_ref','pending','attempt 0','moves Mode A to Mode B','pause_reason: superseded-by-mode-b','never run both modes concurrently') 'Material redesign must preserve one Mode A owner or pause it before Mode B.'
Require-ClauseTerms $recoveryRef @('For Mode B','blocked at its failure limit','stays blocked','EXECUTION / RECOVERY STATE','state: cancelled','no plan','active_tasks','Explicit restart','state: resumed','normal attempts','below 3','authorized guided','4/4') 'Mode B cancellation must preserve the failure limit and explicitly resume only executable state.'
Require-ClauseTerms $recoveryRef @('three consecutive failed cycles','Mode A removes the task','active_tasks','blocked') 'Blocked Mode A tasks must leave active_tasks.'
Require-ClauseTerms $recoveryRef @('another task','freshly verifies every AC','old task','superseded','evidence','otherwise','remains blocked') 'An alternate verified path must settle or retain the original blocked task explicitly.'
Require-ClauseTerms $add @('failed affected AUTO AC','either mode','regression','repair or defer','Phase 3.5A','Phase 3.5B','explicit confirmation') 'Affected AUTO regressions need one mode-independent repair/deferral path.'
Require-ClauseTerms $add @('[~]','Mode B','state: failed','[ ]','state: authorized','reset','resumed','Phase 3.5A','series','attempt state') 'Executable unfinished Mode B states must recover only from their valid nonterminal AC markers.'
Require-ClauseTerms $add @('[ ]','[~]','state: cancelled','state: rejected','explicit restart','original mode/attempt state') 'Cancelled or rejected Mode B targets must not re-enter ordinary backlog automatically.'
Require-ClauseTerms $add @('Unfinished Mode B','Phase 1/3.5A','mode/attempt','failed','[~]','authorized','reset','resumed','[ ]','Other triaged','Mode A') 'Phase 6 must preserve Mode B recovery instead of routing every remaining empty marker to Mode A.'
Require-ClauseTerms $recoveryRef @('shared failure','Mode B target once','Mode A task once','never multiplies') 'Shared failures must increment each affected counter only once per cycle.'
Require-ClauseTerms $recoveryRef @('unavailable required environment/tool','external block','not a failed cycle','BLOCKED','active_tasks','without incrementing','independent work') 'External environment blocks must settle active task state without consuming a failed attempt.'
Require-ClauseTerms $recoveryRef @('condition clears','Phase 5','Mode A deletes old BLOCKED evidence','[ ]','PENDING IMPLEMENTATION','[~]','plan-task attempt/evidence','pending','Mode B','same-series','state: resumed','Phase 3.5A','imports') 'Cleared environment blocks must restore legal AC evidence and task state without resetting recovery history.'
Require-ClauseTerms $recoveryRef @('moves Mode A to Mode B','stop new writes','delegate','wait for/drain','first persisted plan change','status: paused','pause_reason: superseded-by-mode-b','before that marker','task states','active_tasks','After the marker','ownership handback','keeps the pause marker','completed','clears `pause_reason`','active') 'Mode A to Mode B redesign must persist transition ownership and clear transition intent only when active ownership returns.'
Require-ClauseTerms $recoveryRef @('superseded-by-mode-b','Reconcile','First complete','plan-side handoff','idempotently','in_progress','pending','Mode-B-owned','superseded','current evidence','clear `active_tasks`','approach_ref','pause marker','missing reset','unfinished Mode B','ownership handback','Do not use latest-completed fallback','create a replacement') 'Interrupted Mode A to Mode B transitions must idempotently normalize and reconcile one durable owner.'
Require-ClauseTerms $recoveryRef @('Rejection after approval','does not count as a failed cycle','state: rejected','Explicit restart','state: resumed','without resetting attempts') 'Post-approval rejection must persist a distinct recoverable state without consuming an attempt.'
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
Require-Match $acAsset 'Current Verification Evidence' 'English AC asset must keep current evidence outside status-table cells.'
Require-Match $acAssetZh 'AC-<下一个整数>' 'Chinese AC asset must require monotonic AC IDs.'
Require-Match $acAssetZh '验收状态总览' 'Chinese AC asset must include a status summary.'
Require-Match $acAssetZh '(?m)^cssclasses: ac-document\r?$' 'Chinese AC asset must opt into the readable-table style.'
Require-Match $acAssetZh '当前验证证据' 'Chinese AC asset must keep current evidence outside status-table cells.'
foreach ($englishTemplate in @($acAsset, $acTemplate)) {
    Require-Match $englishTemplate '## 🧪 Current Verification Evidence' 'Every English AC template must use the current-evidence icon and title.'
    Require-Match $englishTemplate 'AC ID.*Last Verified.*Type.*Current Conclusion.*Actual Result / Evidence Location.*Recovery State' 'Every English AC template must define the fixed current-evidence columns.'
    Require-ClauseTerms $englishTemplate @('AC ID','unique key','at most once','Update','do not append verification history') 'English current evidence must overwrite by AC ID.'
    Require-ClauseTerms $englishTemplate @('[x]','current','PASS','[!]','[~]','recovery state') 'English current evidence must link acceptance status to current conclusions.'
    Require-ClauseTerms $englishTemplate @('Mode B','series','approach','attempt','limit','kind','state') 'English current evidence must carry Mode B recovery metadata.'
    Require-Match $englishTemplate ([regex]::Escape('series: MB-YYYYMMDD-N; approach_ref: <ref>; attempt: N; limit: 3|4; kind: normal|guided; state: failed|blocked|authorized|reset|cancelled|rejected|resumed|pending-manual')) 'English current evidence must show the exact ordered Mode B Recovery State tuple.'
    Require-NoMatch $englishTemplate 'EVD-<YYYYMMDD>-<N>|Evidence:\s*EVD-' 'Schema 3 English templates must not retain EVD IDs or citations.'
    Require-Match $englishTemplate '## 🧭 Scope Decision Log' 'Every English AC template must use the scope-decision icon.'
    Require-ClauseTerms $englishTemplate @('How to Verify','only','reusable command','manual steps') 'English verification cells must retain only reusable actions.'
    Require-Match $englishTemplate 'Date.*Decision ID.*AC Scope.*Approved Scope Decision.*Rationale' 'Every English AC template must define the scope-decision fields.'
    Require-NoMatch $englishTemplate '(?m)^## .*Change Log\r?$' 'New English AC templates must not retain a Change Log.'
}
Require-Match $acAssetZh '## 🧪 当前验证证据' 'Chinese AC template must use the current-evidence icon and title.'
Require-Match $acAssetZh 'AC ID.*最近验证.*类型.*当前结论.*实际结果 / 证据位置.*恢复状态' 'Chinese AC template must define the fixed current-evidence columns.'
Require-ClauseTerms $acAssetZh @('AC ID','唯一键','最多','更新','不追加验证历史') 'Chinese current evidence must overwrite by AC ID.'
Require-ClauseTerms $acAssetZh @('[x]','当前','PASS','[!]','[~]','恢复状态') 'Chinese current evidence must link acceptance status to current conclusions.'
Require-ClauseTerms $acAssetZh @('Mode B','series','approach','attempt','limit','kind','state') 'Chinese current evidence must carry Mode B recovery metadata.'
Require-Match $acAssetZh ([regex]::Escape('series: MB-YYYYMMDD-N; approach_ref: <ref>; attempt: N; limit: 3|4; kind: normal|guided; state: failed|blocked|authorized|reset|cancelled|rejected|resumed|pending-manual')) 'Chinese current evidence must show the exact ordered Mode B Recovery State tuple.'
Require-NoMatch $acAssetZh 'EVD-<YYYYMMDD>-<N>|证据：\s*EVD-' 'Schema 3 Chinese templates must not retain EVD IDs or citations.'
Require-Match $acAssetZh '## 🧭 范围决策记录' 'Chinese AC template must use the scope-decision icon.'
Require-ClauseTerms $acAssetZh @('验证方式','只保留','可复用命令','人工步骤') 'Chinese verification cells must retain only reusable actions.'
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
