# Mirror Production Readiness Checklist

Status legend:
- [ ] Not started
- [~] In progress
- [x] Done
- [!] Blocked external dependency

## 1. Architecture And Ownership

- [x] DB-first source of truth defined for `mirror_templates`.
- [x] Supabase bootstrap SQL no longer owns Mirror schema.
- [x] Mirror schema changes live in versioned migrations only.
- [ ] ADR for Mirror data ownership is linked from architecture docs.
- [x] Service boundaries documented for Edge Function vs runners.

## 2. Database And Migrations

- [x] `mirror_templates` migration includes RLS and deterministic seed sync.
- [x] Mirror audit table has retention and indexes.
- [x] Mirror storage hardening migration in place.
- [ ] Migration dry-run completed on staging copy.
- [ ] Rollback SQL documented for each new Mirror migration.
- [ ] Post-migration verification script added (table/policy/index assertions).

## 3. Security, Auth, And RLS

- [x] Edge Function enforces bearer auth and request idempotency.
- [x] Request body size guard enforced (max 512KB).
- [x] Apply payload normalization enforced for actor/artifact fields.
- [x] Storage policies restrict signed input/backup object access to owner path.
- [ ] Pen-test checklist run for signed URL leakage and replay scenarios.
- [ ] JWT/service-token rotation runbook tested end-to-end.

## 4. API Contracts

- [x] `/compile` and `/apply` routing explicit and validated.
- [x] Cloud backend contract-check for apply support added.
- [x] Local and cloud runners expose `Apply` method with compile-like signature.
- [x] Apply contract tests cover signed upload, metadata forwarding, audit flow.
- [ ] OpenAPI/proto contract artifact published for CI drift detection.
- [ ] Backward-compatibility matrix documented for client versions.

## 5. Flutter Client Behavior

- [x] Realtime updates debounced in editor (300ms).
- [x] Realtime filtering scoped by `task_id`, `project_id`, and `user_id`.
- [x] `PrivateGrpcBackend.generate` fully implemented.
- [x] Templates gallery no longer uses hardcoded defaults.
- [ ] Empty-state UX for template gallery validated when DB returns zero templates.
- [ ] Telemetry for editor apply failures includes actionable reason buckets.

## 6. Reliability And Performance

- [x] Apply history persistence capped (`updatedFiles` max 50 files / 100k chars).
- [x] Runner workspace cleanup job enabled.
- [ ] Load test executed for burst compile/apply traffic.
- [ ] P95 and P99 latency baselines captured and documented.
- [ ] Timeout/retry values validated under degraded network conditions.

## 7. Test Coverage

- [x] Mirror edge contract tests exist for compile/apply pathing.
- [x] Apply flow contract test added.
- [x] Premium precedence integration tests added (metadata vs subscriptions).
- [ ] Golden/widget tests for templates gallery DB-empty and DB-populated states.
- [ ] End-to-end staging smoke test script added to CI.
- [ ] Mutation or fault-injection test for audit write failures.

## 8. Observability And Operations

- [x] Audit events include consistent apply event constants.
- [x] Runner structured logs include request identifiers.
- [ ] Dashboard for compile/apply success, auth denials, and timeout rates.
- [ ] Alert thresholds defined for error spikes and elevated latency.
- [ ] On-call runbook covers incident triage for Mirror endpoints.
- [ ] Sentry breadcrumb mapping validated for Mirror editor flows.

## 9. Deployment And Rollout

- [ ] Staging rollout completed with migration + app + runner versions aligned.
- [ ] Feature flags prepared for controlled rollout and quick disable.
- [ ] Canary cohort enabled and monitored for 24h.
- [ ] Production rollout checklist signed by backend + mobile/web owners.
- [ ] Post-release verification completed (smoke tests + metrics checks).

## 10. Data Governance And Cleanup

- [x] Legacy bootstrap SQL marked as non-canonical for Mirror.
- [ ] Historical template records reviewed for conflicts before DB-first sync.
- [ ] Data retention policy approved for audit and session artifacts.
- [ ] GDPR/DSAR procedure validated for Mirror audit metadata.

## 11. Release Gate (Must Pass)

- [ ] No critical/high security findings open.
- [ ] All Mirror migrations applied and verified in staging.
- [ ] Contract and integration test suites green in CI.
- [ ] Rollback plan reviewed and tested.
- [ ] Product + engineering sign-off recorded.

## Sign-off

- Feature owner:
- Backend owner:
- Flutter owner:
- QA owner:
- Date:
- Release version/tag:
