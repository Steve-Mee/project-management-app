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

Status legend:
- [ ] Not complete
- [x] Complete
- [n/a] Not applicable for this release

## Release Metadata

- Environment: __________________________
- Release owner: ________________________
- Backend approver: _____________________
- Flutter approver: _____________________
- SRE approver: _________________________
- Security approver: ____________________
- Change window: ________________________
- Rollback owner: _______________________

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

## 3. Security Gate

- [x] Thin-proxy gateway architecture preserved
- [x] Signed artifact flow still enforced where required
- [ ] RLS checks executed in target environment
- [ ] Storage policy checks executed in target environment
- [ ] Secret inventory reviewed for gateway and runner environments
- [ ] Secret rotation or overlap plan documented when secrets changed

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

## Notes

- This checklist is intentionally evidence-driven. Do not mark items complete without a concrete command result, SQL output, dashboard review, or named approver.
- If any item remains open, Task 4.5.5 stays open.

## Current Status

As of 2026-03-22, the repository-preparable portion of this checklist is complete. The remaining unchecked items require execution or approval in staging or production environments.