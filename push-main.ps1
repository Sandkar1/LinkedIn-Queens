[CmdletBinding()]
param(
  [string]$Message = "Update Daily Games"
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)
  & git @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

function Test-StagedChanges {
  & git diff --cached --quiet
  if ($LASTEXITCODE -eq 0) {
    return $false
  }
  if ($LASTEXITCODE -eq 1) {
    return $true
  }
  throw 'Unable to check staged changes.'
}

if (-not (Test-Path -LiteralPath '.git')) {
  throw 'This script must be run from the repository root.'
}

$origin = (& git remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($origin)) {
  throw 'No origin remote is configured. Add one with: git remote add origin <repository-url>'
}

Invoke-Git @('switch', 'main')

if (-not (Test-StagedChanges)) {
  Invoke-Git @('add', '--all')
}

if (Test-StagedChanges) {
  Invoke-Git @('commit', '-m', $Message)
}

$remoteMain = & git ls-remote --heads origin main
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to reach origin.'
}
if ($remoteMain) {
  Invoke-Git @('pull', '--rebase', '--autostash', 'origin', 'main')
}

Invoke-Git @('push', '--set-upstream', 'origin', 'main')
Write-Host 'All files are committed and pushed to origin/main.' -ForegroundColor Green
