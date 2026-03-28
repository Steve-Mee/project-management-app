# Mirror Operator Command Pack

Alleen copy-paste commands voor Workstream 10 execution-evidence.

## 1) Preflight

```powershell
Get-Location
$env:STAGING_DATABASE_URL
Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
Get-Command docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
docker info --format "{{.ServerVersion}}"
```

## 2) DB URL instellen (als nog leeg)

```powershell
$env:STAGING_DATABASE_URL = '<staging-db-url>'
```

## 3) Eén-commando evidence run (aanbevolen)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1
```

## 4) Eén-commando evidence run met expliciete URL

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1 -DatabaseUrl '<staging-db-url>'
```

## 5) Handmatige evidence bundle (fallback)

```powershell
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutDir = "docs/evidence/uuid-hardening/staging/$Timestamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

psql $env:STAGING_DATABASE_URL -v ON_ERROR_STOP=1 `
  -f "supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql" `
  | Tee-Object -FilePath "$OutDir/01_verification_output.txt"

psql $env:STAGING_DATABASE_URL -v ON_ERROR_STOP=1 -c `
  "SELECT source_table, issue_type, COUNT(*) AS issue_count
   FROM public.mirror_context_fk_migration_issues
   GROUP BY source_table, issue_type
   ORDER BY source_table, issue_type;" `
  | Tee-Object -FilePath "$OutDir/02_issue_trend.txt"

psql $env:STAGING_DATABASE_URL -v ON_ERROR_STOP=1 -c `
  "SELECT *
   FROM public.mirror_context_fk_migration_issues
   ORDER BY detected_at DESC
   LIMIT 200;" `
  | Tee-Object -FilePath "$OutDir/03_issue_latest200.txt"

Write-Output "Evidence folder: $OutDir"
```

## 6) Optionele rerun na goedgekeurde remediation SQL

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1 `
  -RerunAfterRemediation `
  -RemediationSqlFile "supabase/verification/<approved_remediation_file>.sql"
```

## 7) Snelle fail checks

```powershell
Get-ChildItem "docs/evidence/uuid-hardening/staging" | Sort-Object Name -Descending | Select-Object -First 1
```

```powershell
$Latest = Get-ChildItem "docs/evidence/uuid-hardening/staging" | Sort-Object Name -Descending | Select-Object -First 1
Get-ChildItem $Latest.FullName | Select-Object Name, Length
```

## 8) Afronding docs (handmatig invullen)

- Werk `docs/mirror_uuid_hardening_execution_log.md` bij
- Werk `docs/mirror-production-readiness-checklist.md` bij
- Werk `docs/mirror_release_signoff_template.md` bij
