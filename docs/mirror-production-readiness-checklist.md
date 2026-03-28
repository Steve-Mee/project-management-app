# Mirror Production Readiness Checklist

## Purpose

This is the execution checklist for the remaining operator-owned portion of Task 4.5.5.

Unlike [production-readiness.md](production-readiness.md), which describes the readiness gate at a handbook level, this file is the release worksheet to complete during final sign-off.

Use this together with:
- [production-readiness.md](production-readiness.md)
- [operations.md](operations.md)
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [mirror_threat_model.md](mirror_threat_model.md)
- [mirror-db-performance-baseline.md](mirror-db-performance-baseline.md)
- [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md)

Status legend:
- [ ] Not complete
- [x] Complete
- [n/a] Not applicable for this release

## Release Metadata

- Environment: staging verification -> production rollout
- Release owner: TBD
- Backend approver: TBD
- Flutter approver: TBD
- SRE approver: TBD
- Security approver: TBD
- Change window: TBD
- Rollback owner: TBD

Prefill note (2026-03-28):
- Repository-level implementation and local test gates are complete.
- Remaining gates are execution or approval gates in staging/production.
- Use this sheet as the single signoff artifact during release window.

## 1. Code And Test Gate

- [x] `flutter analyze` is green in the workspace
- [x] Full Flutter regression suite is green
- [x] Deno gateway test suite is green
- [ ] Staging or production SQL contract scripts executed successfully

Evidence:
- Flutter tests: `613 passed, 0 failed`
- Deno tests: `38 passed, 0 failed`

## 2. Database And Migration Gate

- [ ] Latest Mirror migrations applied in target environment
- [ ] [../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql](../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql) executed
- [ ] FK validation status reviewed and accepted
- [ ] `mirror_context_fk_migration_issues` reviewed for residual rows
- [ ] Rollback path confirmed for any migration in this release

UUID evidence artifact:
- [ ] [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md) completed with SQL output and GO/NO-GO decision

### Execution Evidence (Mandatory For GO)

Use [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md) and confirm these fields are present:

- [ ] Environment, operator, UTC timestamp, change ticket, release reference
- [ ] Verification script execution captured (`20260322_mirror_context_fk_post_migration_verification.sql`)
- [ ] `no_go_count` recorded
- [ ] `ai_sessions` null/orphan/mismatch counters recorded
- [ ] FK validation status recorded
- [ ] `mirror_context_fk_migration_issues` trend recorded (stable/decreasing/increasing)
- [ ] Remediation statements captured with timestamps when applicable
- [ ] Post-remediation re-run result captured when remediation occurred
- [ ] Final GO/NO-GO decision recorded
- [ ] Backend, SRE, and Security approvers recorded
- [ ] Evidence links attached (SQL output, dashboards, ticket references)
- [ ] Evidence file set attached with canonical names (`01_verification_output.txt`, `02_issue_trend.txt`, `03_issue_latest200.txt`)

## 3. Security Gate

- [x] Thin-proxy gateway architecture preserved
- [x] Signed artifact flow still enforced where required
- [ ] RLS checks executed in target environment
- [ ] Storage policy checks executed in target environment
- [ ] Secret inventory reviewed for gateway and runner environments
- [ ] Secret rotation or overlap plan documented when secrets changed
- [ ] Private gRPC runtime endpoint validation recorded (host/port/TLS/source)
- [ ] Production private gRPC endpoint verified as non-loopback
- [ ] Production private gRPC transport verified as TLS-enabled

## 4. Performance Gate

- [x] Local client and gateway baseline captured
- [ ] Database runtime baseline executed from [mirror-db-performance-baseline.md](mirror-db-performance-baseline.md)
- [ ] Compile P95 validated against `<= 4s`
- [ ] Apply P95 validated against `<= 5s`
- [ ] No unacceptable query regression relative to pre-refactor baseline

## 5. Observability Gate

- [ ] Gateway dashboard reviewed
- [ ] Runner dashboard reviewed
- [ ] Replay queue and circuit-breaker dashboard reviewed
- [ ] Auth denial monitoring reviewed
- [ ] Alert routes verified with on-call ownership
- [ ] Request correlation can be followed across client, gateway, and runner

## 6. Deployment Gate

- [ ] Canary plan assigned with owner
- [ ] Abort criteria confirmed
- [ ] Rollback order confirmed
- [ ] Post-deploy smoke tests assigned
- [ ] Mirror compile/apply smoke tests executed in target environment

## 7. Sign-Off Gate

- [ ] Backend approval recorded
- [ ] Flutter approval recorded
- [ ] SRE approval recorded
- [ ] Security approval recorded
- [ ] Final GO for production rollout recorded

### Ready-To-Fill Signoff Block

Complete this block in the release window after execution evidence is attached.

- Final decision timestamp (UTC): __________________
- Final decision: [ ] GO  [ ] NO-GO
- Decision owner: __________________
- Backend approval reference: __________________
- Flutter approval reference: __________________
- SRE approval reference: __________________
- Security approval reference: __________________
- Linked evidence folder: __________________
- Ticket or release comment link: __________________

## Notes

- This checklist is intentionally evidence-driven. Do not mark items complete without a concrete command result, SQL output, dashboard review, or named approver.
- If any item remains open, Task 4.5.5 stays open.

## Current Status

As of 2026-03-22, the repository-preparable portion of this checklist is complete. The remaining unchecked items require execution or approval in staging or production environments.

Operational note (2026-03-24): staging DB URL is now available, but UUID verification execution remains blocked because Docker Engine (`dockerDesktopLinuxEngine`) is not running and local `psql` is not installed.

Operational note (2026-03-28): de staging-run stap is voor deze werksessie op verzoek overgeslagen; mandatory execution-evidence en approvals blijven ongewijzigd verplicht voor production GO.