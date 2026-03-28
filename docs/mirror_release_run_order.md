# Mirror Release Run Order

Doel: minimale, betrouwbare volgorde om Workstream 10 execution-evidence en finale GO/NO-GO af te ronden.

Gebruik samen met:
- [mirror_execution_todo.md](mirror_execution_todo.md)
- [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md)
- [mirror-production-readiness-checklist.md](mirror-production-readiness-checklist.md)
- [mirror_go_no_go_snapshot.md](mirror_go_no_go_snapshot.md)
- [mirror_release_signoff_template.md](mirror_release_signoff_template.md)

## Stap 0: Startcondities

1. Bevestig target environment (staging of production).
2. Bevestig operator en change ticket.
3. Maak evidence map aan:
   - `docs/evidence/uuid-hardening/staging/<timestamp>/`

## Stap 1: UUID Verificatie Uitvoeren

1. Run verificatie via runbook of script.
2. Sla outputs op met canonieke namen:
   - `01_verification_output.txt`
   - `02_issue_trend.txt`
   - `03_issue_latest200.txt`
3. Controleer of output volledig leesbaar is en links bruikbaar zijn.

## Stap 2: Execution Log Invullen

Werk [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md) direct bij:

1. Run metadata (operator, UTC, ticket, release, evidence folder).
2. Resultaten van verificatiescript (`no_go_count`, null/orphan/mismatch, FK status).
3. Trend van `mirror_context_fk_migration_issues`.
4. Eventuele remediation + post-remediation rerun.
5. Voorlopige GO/NO-GO invullen.

## Stap 3: Checklist Aftikken

Werk [mirror-production-readiness-checklist.md](mirror-production-readiness-checklist.md) bij:

1. Database and migration gate.
2. Execution evidence (mandatory for GO).
3. Security/performance/observability/deployment gates die release-specifiek zijn.
4. Sign-off gate met approvers.

## Stap 4: Besluit Moment

1. Werk [mirror_release_signoff_template.md](mirror_release_signoff_template.md) volledig af.
2. Controleer [mirror_go_no_go_snapshot.md](mirror_go_no_go_snapshot.md):
   - komen blockers overeen met actuele status?
3. Leg finale beslissing vast:
   - GO als alle mandatory checks gehaald zijn.
   - NO-GO bij ontbrekende evidence of ontbrekende approvals.

## Stap 5: Afsluiting

1. Werk [mirror_execution_todo.md](mirror_execution_todo.md) stap 6 naar afgerond bij.
2. Voeg links naar evidence en ticket-comment toe in log/checklist/signoff.
3. Noteer korte closure-update in releasekanaal.

## Snelle Fail-Checks (Altijd NO-GO)

- `no_go_count` is niet 0.
- `ai_sessions` null/orphan/mismatch is niet 0 zonder expliciete acceptatie.
- Evidence files ontbreken of zijn niet herleidbaar.
- Backend/SRE/Security approval ontbreekt.
