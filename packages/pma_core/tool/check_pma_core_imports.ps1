# Fails if runtime pma_core source references app package imports.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'lib'

$violations = @()

Get-ChildItem -Path $target -Recurse -Filter '*.dart' | ForEach-Object {
  $content = Get-Content -Path $_.FullName -Raw
  if ($content.Contains('package:project_management_app/')) {
    $violations += $_.FullName
  }
}

if ($violations) {
  Write-Host 'Forbidden imports found in pma_core:' -ForegroundColor Red
  $violations | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
  exit 1
}

Write-Host 'OK: no forbidden app-package imports found in pma_core/lib.' -ForegroundColor Green
exit 0
