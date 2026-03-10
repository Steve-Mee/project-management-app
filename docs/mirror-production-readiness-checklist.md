// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
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
- [ ] ADR for Mirror data ownership is linked from architecture docs. (Owner: Platform Architecture, Deadline: 2026-03-21)
- [x] Service boundaries documented for Mirror Gateway (thin proxy only) vs runners.
- [x] Architecture lock header present in all Mirror source files and docs (`mirror-gateway = thin proxy only`).
- [x] `docs/mirror-architecture.md` updated with locked naming (`MirrorGatewayBackend`, `mirror-gateway` folder, new service classes).

## 2. Database And Migrations

- [x] `mirror_templates` migration includes RLS and deterministic seed sync.
- [x] Mirror audit table has retention and indexes.
- [x] Mirror storage hardening migration in place.
- [ ] Migration dry-run completed on staging copy. (Owner: Data Engineering, Deadline: 2026-03-18)
- [ ] Rollback SQL documented for each new Mirror migration. (Owner: Data Engineering, Deadline: 2026-03-20)
- [ ] Post-migration verification script added (table/policy/index assertions). (Owner: Data Engineering, Deadline: 2026-03-22)

## 3. Security, Auth, And RLS

- [x] Mirror Gateway enforces bearer auth and request idempotency.
- [x] Request body size guard enforced (max 512KB).
- [x] Apply payload normalization enforced for actor/artifact fields.
- [x] Storage policies restrict signed input/backup object access to owner path.
- [x] Idempotency stale-claim takeover implemented: `processing` records older than 300 s are reclaimed rather than returning 409 conflict.
- [x] Idempotency finalize ownership guard: `finalizeIdempotencyKey` requires matching `request_id`, `request_hash`, and `status = processing`; returns conflict error on mismatch.
- [x] Expired idempotency records are reclaimed (not replayed or blocked) on any claim path.
- [ ] Pen-test checklist run for signed URL leakage and replay scenarios. (Owner: Security Engineering, Deadline: 2026-03-24)
- [ ] JWT/service-token rotation runbook tested end-to-end. (Owner: Security Engineering, Deadline: 2026-03-19)

## 4. API Contracts

- [x] `/compile` and `/apply` routing explicit and validated.
- [x] Cloud backend contract-check for apply support added.
- [x] Local and cloud runners expose `Apply` method with compile-like signature.
- [x] Apply contract tests cover signed upload, metadata forwarding, audit flow.
- [ ] OpenAPI/proto contract artifact published for CI drift detection. (Owner: Backend API, Deadline: 2026-03-25)
- [ ] Backward-compatibility matrix documented for client versions. (Owner: Backend API, Deadline: 2026-03-26)

## 5. Flutter Client Behavior

- [x] Realtime updates debounced in editor (300ms).
- [x] Realtime filtering scoped by `task_id`, `project_id`, and `user_id`.
- [x] `PrivateGrpcBackend.generate` fully implemented.
- [x] Templates gallery no longer uses hardcoded defaults.
- [x] `MirrorEditorScreen` reduced to pure UI: realtime subscription extracted to `MirrorEditorRealtimeController`, run lifecycle extracted to `MirrorEditorRunService`.
- [x] `MirrorRealtimeEventSetDeduplicator` moved to `mirror_realtime_service.dart` (canonical service module, not screen file).
- [x] Editor change-guard prevents mode/content mutations during active run (`_isRunInProgress`).
- [ ] Empty-state UX for template gallery validated when DB returns zero templates. (Owner: Flutter Client, Deadline: 2026-03-17)
- [ ] Telemetry for editor apply failures includes actionable reason buckets. (Owner: Flutter Client, Deadline: 2026-03-21)

## 6. Reliability And Performance

- [x] Apply history persistence capped (`updatedFiles` max 50 files / 100k chars).
- [x] Runner workspace cleanup job enabled.
- [ ] Load test executed for burst compile/apply traffic. (Owner: SRE, Deadline: 2026-03-27)
- [ ] P95 and P99 latency baselines captured and documented. (Owner: SRE, Deadline: 2026-03-28)
- [ ] Timeout/retry values validated under degraded network conditions. (Owner: SRE, Deadline: 2026-03-29)

## 7. Test Coverage

- [x] Mirror gateway contract tests exist for compile/apply pathing.
- [x] Apply flow contract test added.
- [x] Premium precedence integration tests added (metadata vs subscriptions).
- [ ] Golden/widget tests for templates gallery DB-empty and DB-populated states. (Owner: QA Automation, Deadline: 2026-03-20)
- [ ] End-to-end staging smoke test script added to CI. (Owner: QA Automation, Deadline: 2026-03-24)
- [ ] Mutation or fault-injection test for audit write failures. (Owner: QA Automation, Deadline: 2026-03-27)

## 8. Observability And Operations

- [x] Audit events include consistent apply event constants.
- [x] Runner structured logs include request identifiers.
- [ ] Dashboard for compile/apply success, auth denials, and timeout rates. (Owner: Observability, Deadline: 2026-03-22)
- [ ] Alert thresholds defined for error spikes and elevated latency. (Owner: Observability, Deadline: 2026-03-23)
- [ ] On-call runbook covers incident triage for Mirror endpoints. (Owner: SRE, Deadline: 2026-03-18)
- [ ] Sentry breadcrumb mapping validated for Mirror editor flows. (Owner: Flutter Client, Deadline: 2026-03-19)

## 9. Deployment And Rollout

- [ ] Staging rollout completed with migration + app + runner versions aligned. (Owner: Release Management, Deadline: 2026-03-30)
- [ ] Feature flags prepared for controlled rollout and quick disable. (Owner: Release Management, Deadline: 2026-03-26)
- [ ] Canary cohort enabled and monitored for 24h. (Owner: Release Management, Deadline: 2026-03-31)
- [ ] Production rollout checklist signed by backend + mobile/web owners. (Owner: Engineering Management, Deadline: 2026-04-01)
- [ ] Post-release verification completed (smoke tests + metrics checks). (Owner: Release Management, Deadline: 2026-04-02)

## 10. Data Governance And Cleanup

- [x] Legacy bootstrap SQL marked as non-canonical for Mirror.
- [ ] Historical template records reviewed for conflicts before DB-first sync. (Owner: Data Governance, Deadline: 2026-03-22)
- [ ] Data retention policy approved for audit and session artifacts. (Owner: Data Governance, Deadline: 2026-03-25)
- [ ] GDPR/DSAR procedure validated for Mirror audit metadata. (Owner: Compliance, Deadline: 2026-03-28)

## 11. Release Gate (Must Pass)

- [ ] No critical/high security findings open. (Owner: Security Engineering, Deadline: 2026-04-01)
- [ ] All Mirror migrations applied and verified in staging. (Owner: Data Engineering, Deadline: 2026-03-30)
- [ ] Contract and integration test suites green in CI. (Owner: QA Automation, Deadline: 2026-03-31)
- [ ] Rollback plan reviewed and tested. (Owner: SRE, Deadline: 2026-03-31)
- [ ] Product + engineering sign-off recorded. (Owner: Product Management, Deadline: 2026-04-02)

## Sign-off

- Feature owner: Mirror Product Lead (Nina Verhoef)
- Backend owner: Mirror Backend Lead (Arjan de Vries)
- Flutter owner: Mirror Flutter Lead (Sven Koster)
- QA owner: Mirror QA Lead (Laura Smit)
- Date: 2026-03-10
- Release version/tag: pending
