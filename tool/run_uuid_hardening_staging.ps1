param(
    [Parameter(Mandatory = $false)]
    [string]$DatabaseUrl = $env:STAGING_DATABASE_URL,

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "staging",

    [Parameter(Mandatory = $false)]
    [string]$EvidenceBaseDir = "docs/evidence/uuid-hardening",

    [Parameter(Mandatory = $false)]
    [string]$RemediationSqlFile,

    [Parameter(Mandatory = $false)]
    [switch]$RerunAfterRemediation
)

$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
    throw "No database URL provided. Set STAGING_DATABASE_URL or pass -DatabaseUrl."
}

$hasLocalPsql = $null -ne (Get-Command psql -ErrorAction SilentlyContinue)
$hasDocker = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)
$useDockerPsql = $false

if ($hasLocalPsql) {
    Write-Host "Using local psql client."
}
elseif ($hasDocker) {
    $useDockerPsql = $true
    Write-Host "Local psql not found; using Docker postgres image as psql runner."
}
else {
    throw "Neither local psql nor docker is available. Install psql or enable Docker."
}

function Invoke-PsqlFile {
    param(
        [string]$DbUrl,
        [string]$SqlFile
    )

    if (-not $useDockerPsql) {
        psql $DbUrl -v ON_ERROR_STOP=1 -f $SqlFile
        if ($LASTEXITCODE -ne 0) {
            throw "psql file execution failed (exit code $LASTEXITCODE): $SqlFile"
        }
        return
    }

    docker run --rm `
        -v "${PWD}:/workspace" `
        -w /workspace `
        postgres:16-alpine `
        psql $DbUrl -v ON_ERROR_STOP=1 -f $SqlFile
    if ($LASTEXITCODE -ne 0) {
        throw "docker psql file execution failed (exit code $LASTEXITCODE): $SqlFile"
    }
}

function Invoke-PsqlQuery {
    param(
        [string]$DbUrl,
        [string]$Query
    )

    if (-not $useDockerPsql) {
        psql $DbUrl -v ON_ERROR_STOP=1 -c $Query
        if ($LASTEXITCODE -ne 0) {
            throw "psql query execution failed (exit code $LASTEXITCODE)."
        }
        return
    }

    docker run --rm `
        -v "${PWD}:/workspace" `
        -w /workspace `
        postgres:16-alpine `
        psql $DbUrl -v ON_ERROR_STOP=1 -c $Query
    if ($LASTEXITCODE -ne 0) {
        throw "docker psql query execution failed (exit code $LASTEXITCODE)."
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $EvidenceBaseDir "$EnvironmentName/$timestamp"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$verificationSql = "supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql"

Write-Host "[1/4] Running UUID verification script..."
Invoke-PsqlFile -DbUrl $DatabaseUrl -SqlFile $verificationSql |
    Tee-Object -FilePath (Join-Path $outDir "01_verification_output.txt")

Write-Host "[2/4] Capturing migration issue trend..."
Invoke-PsqlQuery -DbUrl $DatabaseUrl -Query @"
SELECT source_table, issue_type, COUNT(*) AS issue_count
FROM public.mirror_context_fk_migration_issues
GROUP BY source_table, issue_type
ORDER BY source_table, issue_type;
"@ |
    Tee-Object -FilePath (Join-Path $outDir "02_issue_trend.txt")

Write-Host "[3/4] Capturing latest migration issue evidence rows..."
Invoke-PsqlQuery -DbUrl $DatabaseUrl -Query @"
SELECT *
FROM public.mirror_context_fk_migration_issues
ORDER BY detected_at DESC
LIMIT 200;
"@ |
    Tee-Object -FilePath (Join-Path $outDir "03_issue_latest200.txt")

if ($RerunAfterRemediation) {
    if ([string]::IsNullOrWhiteSpace($RemediationSqlFile)) {
        throw "-RerunAfterRemediation requires -RemediationSqlFile."
    }
    if (-not (Test-Path $RemediationSqlFile)) {
        throw "Remediation SQL file not found: $RemediationSqlFile"
    }

    Write-Host "[4/4] Executing remediation SQL and re-running verification..."
    Invoke-PsqlFile -DbUrl $DatabaseUrl -SqlFile $RemediationSqlFile |
        Tee-Object -FilePath (Join-Path $outDir "04_remediation_output.txt")

    Invoke-PsqlFile -DbUrl $DatabaseUrl -SqlFile $verificationSql |
        Tee-Object -FilePath (Join-Path $outDir "05_post_remediation_verification_output.txt")
}

Write-Host "Evidence folder: $outDir"
Write-Host "Done. Attach captured files in docs/mirror_uuid_hardening_execution_log.md and docs/mirror-production-readiness-checklist.md."