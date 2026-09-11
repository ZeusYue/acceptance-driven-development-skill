[CmdletBinding()]
param(
    [string]$ReleaseRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$RequireCleanWorktree
)

$ErrorActionPreference = 'Stop'
$validatorArguments = @((Join-Path $PSScriptRoot 'validate_release.py'), '--root', $ReleaseRoot)
if ($RequireCleanWorktree) { $validatorArguments += '--require-clean-worktree' }
& python @validatorArguments
exit $LASTEXITCODE
