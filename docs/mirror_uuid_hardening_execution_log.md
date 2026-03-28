# Mirror UUID Hardening Execution Log

## Purpose

This log captures environment evidence for Workstream 10 UUID hardening execution.

Use this together with:
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [mirror-production-readiness-checklist.md](mirror-production-readiness-checklist.md)
- [mirror-db-performance-baseline.md](mirror-db-performance-baseline.md)
- [../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql](../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql)

## Staging Quick-Start Entry

Use this prefilled block for the first staging run and replace every `<...>` value with real evidence.

Recommended runner command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1
```

Runner behavior:
- uses local `psql` when available
- otherwise falls back to Docker `postgres:16-alpine` automatically
- requires `STAGING_DATABASE_URL` or `-DatabaseUrl`

- Environment: staging
- Operator: <name>
- Date (UTC): <yyyy-mm-ddThh:mm:ssZ>
- Change ticket: <ticket-id>
- Related release: <release-tag>
- Evidence folder path: <docs/evidence/uuid-hardening/staging/yyyyMMdd-HHmmss>
- Verification script executed: [yes/no]
- no_go_count: <value>
- ai_sessions null/orphan/mismatch counters: <value/value/value>
- FK validation status: <all validated | list failures>
- migration issue trend: <stable | decreasing | increasing>
- remediation needed: <none | describe>
- post-remediation no_go_count: <value>
- GO/NO-GO: <GO | NO-GO>
- approvers: backend=<name>, sre=<name>, security=<name>
- evidence links: <sql-output-link>, <dashboard-link>, <ticket-comment-link>

### Local Preflight (2026-03-24)

- Context: voorbereidende run op ontwikkelmachine voorafgaand aan echte staging-executie.
- Resultaat:
	- `STAGING_DATABASE_URL`: niet gezet
	- lokale `psql`: niet beschikbaar
	- Docker: beschikbaar (`postgres:16-alpine` fallback mogelijk)
- Conclusie: daadwerkelijke verificatie-run is geblokkeerd totdat een geldige staging database URL beschikbaar is via `STAGING_DATABASE_URL` of `-DatabaseUrl`.
- Unblock one-liner (PowerShell):

```powershell
$env:STAGING_DATABASE_URL = '<staging-db-url>'; powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1
```

### Staging Run Attempt (2026-03-24)

- Command executed: `powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1 -DatabaseUrl '<provided>'`
- Outcome: failed at step `[1/4] Running UUID verification script...`
- Error: Docker client aanwezig, maar Docker Engine niet bereikbaar via `//./pipe/dockerDesktopLinuxEngine` (exit code 125)
- Local `psql`: niet beschikbaar (dus geen fallback zonder Docker Engine)
- Evidence folder created: `docs/evidence/uuid-hardening/staging/20260324-215217/`
- Next action: start Docker Desktop/Engine of installeer lokale `psql`, daarna script opnieuw uitvoeren.

### Workflow Note (2026-03-28)

- Staging execution stap is in deze ronde overgeslagen op expliciet verzoek.
- Deze skip verandert de release-eis niet: voor een formele GO moeten echte environment-uitvoer en evidence-bestanden nog steeds worden toegevoegd.
- Actieve vervolgstap is afronding van readiness-evidence zodra staging of production execution beschikbaar is.

## Run Metadata

- Environment: __________________________
- Operator: _____________________________
- Date (UTC): ___________________________
- Change ticket: ________________________
- Related release: ______________________
- Evidence folder path: __________________

Expected evidence files (recommended names):
- `01_verification_output.txt`
- `02_issue_trend.txt`
- `03_issue_latest200.txt`

## Step 1: Verification Script Output

Command:

```sql
\i supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql
```

Attach or paste:
- schema presence result set
- FK validation result set
- trigger/function presence result set
- NO-GO summary row
- file reference: ___________________________________________

Recorded values:
- no_go_count: __________________
- ai_sessions null uuid count: __________________
- ai_sessions orphan project count: __________________
- ai_sessions orphan task count: __________________
- ai_sessions task/project mismatch count: __________________
- ai_sessions project FK not validated count: __________________
- ai_sessions task FK not validated count: __________________

## Step 2: Migration Issues Review

Query:

```sql
SELECT source_table, issue_type, COUNT(*) AS issue_count
FROM public.mirror_context_fk_migration_issues
GROUP BY source_table, issue_type
ORDER BY source_table, issue_type;
```

Latest issue sample query:

```sql
SELECT *
FROM public.mirror_context_fk_migration_issues
ORDER BY detected_at DESC
LIMIT 200;
```

Recorded outcome:
- unexpected growth detected: [yes/no]
- if yes, summary: ___________________________________________
- file reference: ___________________________________________

## Step 3: Remediation (Only If Needed)

Executed remediation statements:
- [ ] none required
- [ ] project_uuid backfill from tasks
- [ ] constraint re-validation
- [ ] other (describe)

Statements executed (copy exact SQL and timestamp):

```sql
-- paste executed remediation SQL here
```

## Step 4: Post-Remediation Re-Run

- verification script re-run completed: [yes/no]
- post-remediation no_go_count: __________________
- remaining blockers: _____________________________

## Step 5: GO/NO-GO Decision

Decision:
- [ ] GO (all criteria met)
- [ ] NO-GO (blockers remain)

GO criteria check:
- [ ] no_go_count = 0
- [ ] ai_sessions null/orphan/mismatch counters are zero
- [ ] required FK constraints present and validated
- [ ] migration issue trend stable or decreasing

Approvals:
- Backend approver: __________________
- SRE approver: ______________________
- Security approver: _________________

Notes:
- _______________________________________________
- _______________________________________________
