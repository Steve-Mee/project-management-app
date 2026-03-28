# Mirror Handbook

Mirror is the in-app assisted coding and execution workflow for the Project Management App. It combines a Flutter editor experience, provider-managed access control, a thin proxy gateway, cloud or local runner execution, offline resilience, and audited apply flows.

This handbook is the single entry point for Mirror documentation. Use it to navigate the system from first-use guidance through architecture, security, operations, and incident recovery.

## Quick Start

1. Start with [usage.md](usage.md) for the user workflow and expected product behavior.
2. Read [architecture.md](architecture.md) for the runtime design, service boundaries, and architecture lock.
3. Review [security.md](security.md) for RLS, entitlement, signed artifact protection, and replay controls.
4. Use [operations.md](operations.md) for deployment, monitoring, rollback, and incident response.
5. Keep [troubleshooting.md](troubleshooting.md) available for diagnosis and recovery.

## Table Of Contents

### Core Guides

- [usage.md](usage.md)
- [architecture.md](architecture.md)
- [security.md](security.md)
- [mirror_threat_model.md](mirror_threat_model.md)
- [offline-first.md](offline-first.md)
- [operations.md](operations.md)
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [mirror_execution_todo.md](mirror_execution_todo.md)
- [mirror_orchestration_flowmap.md](mirror_orchestration_flowmap.md)
- [mirror_session_state_transitions.md](mirror_session_state_transitions.md)
- [production-readiness.md](production-readiness.md)
- [mirror-db-performance-baseline.md](mirror-db-performance-baseline.md)
- [mirror-production-readiness-checklist.md](mirror-production-readiness-checklist.md)
- [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md)
- [mirror_go_no_go_snapshot.md](mirror_go_no_go_snapshot.md)
- [mirror_release_signoff_template.md](mirror_release_signoff_template.md)
- [mirror_release_run_order.md](mirror_release_run_order.md)
- [mirror_operator_command_pack.md](mirror_operator_command_pack.md)

### Implementation References

- [contracts.md](contracts.md)
- [feature-flags.md](feature-flags.md)
- [glossary.md](glossary.md)

### Support And Recovery

- [troubleshooting.md](troubleshooting.md)

## Recommended Reading Paths

### For Users And Support

- [usage.md](usage.md)
- [troubleshooting.md](troubleshooting.md)
- [glossary.md](glossary.md)

### For Flutter And Backend Engineers

- [architecture.md](architecture.md)
- [contracts.md](contracts.md)
- [security.md](security.md)
- [mirror_threat_model.md](mirror_threat_model.md)
- [feature-flags.md](feature-flags.md)
- [offline-first.md](offline-first.md)

### For SRE And Release Owners

- [operations.md](operations.md)
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [mirror_execution_todo.md](mirror_execution_todo.md)
- [mirror_orchestration_flowmap.md](mirror_orchestration_flowmap.md)
- [mirror_session_state_transitions.md](mirror_session_state_transitions.md)
- [production-readiness.md](production-readiness.md)
- [mirror-db-performance-baseline.md](mirror-db-performance-baseline.md)
- [mirror-production-readiness-checklist.md](mirror-production-readiness-checklist.md)
- [mirror_uuid_hardening_execution_log.md](mirror_uuid_hardening_execution_log.md)
- [mirror_go_no_go_snapshot.md](mirror_go_no_go_snapshot.md)
- [mirror_release_signoff_template.md](mirror_release_signoff_template.md)
- [mirror_release_run_order.md](mirror_release_run_order.md)
- [mirror_operator_command_pack.md](mirror_operator_command_pack.md)
- [security.md](security.md)
- [mirror_threat_model.md](mirror_threat_model.md)
- [troubleshooting.md](troubleshooting.md)

## Documentation Conventions

- Use the canonical names `MirrorGatewayBackend`, `PrivateGrpcBackend`, `mirror-signed-inputs`, and `mirror-backups`.
- Treat `supabase/functions/mirror-gateway` as a thin proxy only. Mirror compute runs on cloud or local runner services, never in the edge function.
- Use this handbook as the active reference. Historical material is retained under [archive/README.md](archive/README.md) for traceability only.

## Archive

The archive preserves historical source material, migration records, and review artifacts that are no longer part of the active handbook.

- [archive/README.md](archive/README.md) explains the archive structure and intended use.
- [archive/migration-map.md](archive/migration-map.md) records the old-to-new document mapping from the reorganization.
- [archive/diffs/full-docs-handbook.diff](archive/diffs/full-docs-handbook.diff) and the other files under [archive/diffs](archive/diffs) are retained for historical review only and should not be treated as active documentation.

Last updated: 2026-03-22  
Version note: Mirror handbook index updated with DB baseline and production-readiness execution checklists.
