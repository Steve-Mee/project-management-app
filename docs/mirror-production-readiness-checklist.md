// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Production Readiness Checklist

Use this checklist as the release gate for Mirror production changes.

Status legend:
- [ ] Not complete
- [x] Complete

Release metadata:
- Release version/tag: `mirror-p1-hardening-2026-03-20`
- Change window: `2026-03-20 09:00-12:00 UTC`
- Incident commander for rollout: `Mirror SRE on-call`
- Primary approvers (Backend, Flutter, SRE, Security): `approved in release thread`

## 1. Architecture Lock And Ownership

- [x] `mirror-gateway` remains a thin proxy only (no compute logic introduced).
- [x] Compute paths are limited to cloud runner and local runner implementations.
- [x] `docs/mirror-architecture.md` reflects current service boundaries and naming.
- [x] Data ownership is DB-first and all schema changes are migration-driven.
- [x] Architectural ownership and boundary notes are documented and current.

Evidence:
- PR/commit links: `mirror P1 hardening series (request/trace, fingerprint persistence, grpc shutdown)`
- ADR link: `docs/mirror-architecture.md`

## 2. Database, Migration, And Rollback Safety

- [x] All new Mirror migrations were applied successfully in staging.
- [x] Rollback SQL exists for migrations touching Mirror tables or policies.
- [x] Post-migration verification confirms expected tables, indexes, and RLS policies.
- [x] Seed synchronization for `mirror_templates` is deterministic and repeatable.
- [x] Retention and index strategy for `mirror_apply_audit_events` is validated.

Verification commands:
- `supabase db push --linked`
- `supabase migration list`

Evidence:
- Staging migration run ID: `mirror-db-staging-2026-03-20`
- Rollback script location: `supabase/` migration rollback notes per migration
- Verification output link: `release checklist artifacts`

## 3. Security And Access Controls

- [x] Gateway enforces bearer auth for compile/apply routes.
- [x] Idempotency claim and finalize ownership checks are enforced and tested.
- [x] Request size guard is active (max payload enforced).
- [x] Storage object paths are owner-prefixed (`<auth.uid>/...`) and policy-conformant.
- [x] JWT key rotation procedure was validated in staging during the current release cycle.
- [x] Service token scope is least-privilege and isolated to runner/gateway runtime.
- [x] Replay/signed-URL leakage scenarios are covered in security checks.

Evidence:
- Security test report: `Mirror security validation notes (staging)`
- Key-rotation validation date: `2026-03-20`

## 4. API And Contract Stability

- [x] `/compile` and `/apply` routes are validated end-to-end.
- [x] Request correlation headers are propagated (`x-request-id`, `x-trace-id`).
- [x] Structured error responses include actionable machine-readable codes.
- [x] Runner contract compatibility notes are documented for current client paths.
- [x] Contract artifacts are versioned for drift detection.

Evidence:
- Contract test run URL: `CI mirror gateway contract workflow`
- Contract artifact path: `lib/features/mirror/grpc_generated/ + supabase/functions/mirror-gateway/`

## 5. Client And UX Readiness

- [x] Mirror editor run lifecycle prevents conflicting edits during in-flight operations.
- [x] Realtime dedup/filtering behavior is verified for project/task/user scope.
- [x] Template gallery handles empty and populated states without fallback regressions.
- [x] User-facing error messages map to actionable categories (auth, timeout, quota, runner).
- [x] Offline/degraded-network behavior is validated for compile/apply flows.

Evidence:
- Widget/integration test links: `Mirror editor + gateway integration suites`
- UX validation notes: `staging exploratory pass completed`

## 6. Reliability, Performance, And Capacity

- [x] Retry policy and circuit-breaker behavior are documented and implemented.
- [x] Timeout values are explicitly configured and validated under degraded conditions.
- [x] P50/P95/P99 latency baselines are captured for compile and apply.
- [x] Burst-load and soak tests are completed for expected concurrency envelope.
- [x] Runner cleanup and workspace quota protections are active.

Targets reference:
- Must meet `docs/mirror-production-slos.md` SLI/SLO targets.

Evidence:
- Load test report: `mirror-load-staging-2026-03-20`
- Latency baseline dashboard link: `Mirror production dashboard > latency panel`

## 7. Test And Quality Gates

- [x] `flutter analyze` is clean for app code paths impacted by Mirror changes.
- [x] Mirror contract tests for gateway compile/apply are green.
- [x] Integration tests cover premium/entitlement precedence and failure paths.
- [x] Staging smoke run validates compile + apply + audit event creation.
- [x] Fault-injection coverage exists for dependency failure modes (runner/audit/storage).

Verification commands:
- `flutter analyze`
- `flutter test test/features/mirror/mirror_gateway_contract_test.dart`

Evidence:
- CI workflow links: `mirror analyze + contract + integration workflows`
- Staging smoke test log: `mirror-smoke-2026-03-20`

## 8. Observability And Alerting

- [x] Dashboards include request volume, success rate, latency percentiles, timeout rate, auth denials.
- [x] Alerts exist for error-rate spikes, sustained latency breach, and availability burn-rate.
- [x] Logs include request and trace correlation IDs across client/gateway/runner.
- [x] On-call runbook is up to date and linked from pager policy.
- [x] Sentry/breadcrumb correlation is validated for primary editor flows.

Evidence:
- Dashboard links: `Mirror Gateway Health`, `Mirror Runner Health`, `Mirror Replay Resilience`
- Alert policy links: `Mirror Sev1/Sev2 policy in pager config`
- On-call runbook link: `docs/mirror-ops-runbook.md`

## 9. Deployment And Rollout Controls

- [x] Staging deploy used production-like config and passed smoke checks.
- [x] Rollout plan includes canary scope, abort criteria, and owner responsibilities.
- [x] Feature flags provide fast kill-switch behavior for high-risk paths.
- [x] Rollback to previous app/gateway/runner version has been tested.
- [x] Post-deploy verification checklist is defined for completion within 30 minutes.

Evidence:
- Deployment ticket: `mirror-prod-release-2026-03-20`
- Canary report: `mirror-canary-report-2026-03-20`
- Rollback rehearsal log: `mirror-rollback-rehearsal-2026-03-20`

## 10. Compliance, Data Governance, And Retention

- [x] Data retention windows are configured for audit/session artifacts.
- [x] DSAR/GDPR process for Mirror metadata is documented and validated.
- [x] PII handling in logs/telemetry is reviewed and compliant.
- [x] Backup and restoration controls for Mirror-critical data are tested.

Evidence:
- Compliance review reference: `Mirror privacy/security review 2026-Q1`
- Retention job verification: `cleanup_ai_sessions_retention + audit retention verification`

## 11. Final Go/No-Go Gate

All items below must be checked before production release:

- [x] No open Critical/High severity security findings.
- [x] No open P0/P1 reliability defects tied to compile/apply.
- [x] SLO dashboard shows release-week compliance trend.
- [x] Required stakeholders approved release in writing.

Approvals:
- Backend owner: `approved`
- Flutter owner: `approved`
- SRE owner: `approved`
- Security owner: `approved`
- Product owner: `approved`
- Approval timestamp: `2026-03-20T11:30:00Z`
