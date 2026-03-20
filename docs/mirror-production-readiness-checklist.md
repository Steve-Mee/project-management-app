// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Production Readiness Checklist

Use this checklist as the release gate for Mirror production changes.

Status legend:
- [ ] Not complete
- [x] Complete

Release metadata:
- Release version/tag:
- Change window:
- Incident commander for rollout:
- Primary approvers (Backend, Flutter, SRE, Security):

## 1. Architecture Lock And Ownership

- [ ] `mirror-gateway` remains a thin proxy only (no compute logic introduced).
- [ ] Compute paths are limited to cloud runner and local runner implementations.
- [ ] `docs/mirror-architecture.md` reflects current service boundaries and naming.
- [ ] Data ownership is DB-first and all schema changes are migration-driven.
- [ ] Architectural Decision Record (ADR) for Mirror ownership is linked and current.

Evidence:
- PR/commit links:
- ADR link:

## 2. Database, Migration, And Rollback Safety

- [ ] All new Mirror migrations were applied successfully in staging.
- [ ] Migration rollback SQL exists for each migration touching Mirror tables or policies.
- [ ] Post-migration verification confirms expected tables, indexes, and RLS policies.
- [ ] Seed synchronization for `mirror_templates` is deterministic and repeatable.
- [ ] Retention and index strategy for `mirror_apply_audit_events` is validated.

Verification commands:
- `supabase db push --linked`
- `supabase migration list`

Evidence:
- Staging migration run ID:
- Rollback script location:
- Verification output link:

## 3. Security And Access Controls

- [ ] Gateway enforces bearer auth for compile/apply routes.
- [ ] Idempotency claim and finalize ownership checks are enforced and tested.
- [ ] Request size guard is active (max payload enforced).
- [ ] Storage object paths are owner-prefixed (`<auth.uid>/...`) and policy-conformant.
- [ ] JWT key rotation procedure has been executed in staging in the last 30 days.
- [ ] Service token scope is least-privilege and not shared outside runner/gateway runtime.
- [ ] Security checklist for replay/signed-URL leakage scenarios is complete.

Evidence:
- Security test report:
- Key-rotation validation date:

## 4. API And Contract Stability

- [ ] `/compile` and `/apply` routes are validated end-to-end.
- [ ] Request correlation headers are propagated (`x-request-id`, `x-trace-id`).
- [ ] Structured error responses include actionable machine-readable codes.
- [ ] Runner contract compatibility matrix is documented for supported client versions.
- [ ] Contract artifacts (OpenAPI/proto/schema snapshots) are published for CI drift checks.

Evidence:
- Contract test run URL:
- Contract artifact path:

## 5. Client And UX Readiness

- [ ] Mirror editor run lifecycle prevents conflicting edits during in-flight operations.
- [ ] Realtime dedup/filtering behavior is verified for project/task/user scope.
- [ ] Template gallery handles empty and populated states without fallback regressions.
- [ ] User-facing error messages map to actionable categories (auth, timeout, quota, runner).
- [ ] Offline/degraded-network behavior is validated for compile/apply flows.

Evidence:
- Widget/integration test links:
- UX validation notes:

## 6. Reliability, Performance, And Capacity

- [ ] Retry policy and circuit-breaker behavior are documented and implemented.
- [ ] Timeout values are explicitly configured and validated under degraded conditions.
- [ ] P50/P95/P99 latency baselines are captured for compile and apply.
- [ ] Burst-load and soak tests are completed for expected concurrency.
- [ ] Runner cleanup and workspace quota protections are active.

Targets reference:
- Must meet `docs/mirror-production-slos.md` SLI/SLO targets.

Evidence:
- Load test report:
- Latency baseline dashboard link:

## 7. Test And Quality Gates

- [ ] `flutter analyze` is clean for app code paths impacted by Mirror changes.
- [ ] Mirror contract tests for gateway compile/apply are green.
- [ ] Integration tests cover premium/entitlement precedence and failure paths.
- [ ] At least one staging smoke run validates compile + apply + audit event creation.
- [ ] Fault-injection test exists for at least one dependency failure mode (runner/audit/storage).

Verification commands:
- `flutter analyze`
- `flutter test test/features/mirror/mirror_gateway_contract_test.dart`

Evidence:
- CI workflow links:
- Staging smoke test log:

## 8. Observability And Alerting

- [ ] Dashboards include request volume, success rate, latency percentiles, timeout rate, auth denials.
- [ ] Alerts exist for error-rate spikes, sustained latency breach, and availability burn-rate.
- [ ] Logs include request and trace correlation IDs across client/gateway/runner.
- [ ] On-call runbook is up to date and linked from pager policy.
- [ ] Sentry/breadcrumb correlation is validated for primary editor flows.

Evidence:
- Dashboard links:
- Alert policy links:
- On-call runbook link:

## 9. Deployment And Rollout Controls

- [ ] Staging deploy used production-like config and passed smoke checks.
- [ ] Rollout plan includes canary scope, abort criteria, and owner responsibilities.
- [ ] Feature flags provide fast kill-switch behavior for high-risk paths.
- [ ] Rollback to previous app/gateway/runner version has been tested.
- [ ] Post-deploy verification completed within 30 minutes after production release.

Evidence:
- Deployment ticket:
- Canary report:
- Rollback rehearsal log:

## 10. Compliance, Data Governance, And Retention

- [ ] Data retention windows are configured for audit/session artifacts.
- [ ] DSAR/GDPR process for Mirror metadata is documented and validated.
- [ ] PII handling in logs/telemetry is reviewed and compliant.
- [ ] Backup and restoration controls for Mirror-critical data are tested.

Evidence:
- Compliance review reference:
- Retention job verification:

## 11. Final Go/No-Go Gate

All items below must be checked before production release:

- [ ] No open Critical/High severity security findings.
- [ ] No open P0/P1 reliability defects tied to compile/apply.
- [ ] SLO dashboard shows release-week compliance trend.
- [ ] Required stakeholders approved release in writing.

Approvals:
- Backend owner:
- Flutter owner:
- SRE owner:
- Security owner:
- Product owner:
- Approval timestamp:
