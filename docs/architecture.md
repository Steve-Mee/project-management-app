# Architecture

## System Overview

The Project Management App is a Flutter client with Supabase-backed data, optional local storage, and a Mirror execution stack for compile/apply workflows.

Primary layers:

- Client: Flutter UI, Riverpod providers, offline cache, and Mirror editor flow
- Edge/API: Supabase Edge Functions including `mirror-gateway`
- Compute: cloud runner and local runner
- Data: Supabase Postgres, Supabase Storage, and encrypted Hive for client-side resilience

## Mirror Architecture Lock

The following rules are permanent unless explicitly changed by architecture decision record:

- `supabase/functions/mirror-gateway` is a thin proxy only.
- Compute executes only on cloud runner or local runner.
- `MirrorGatewayBackend` is the canonical cloud backend class.
- `PrivateGrpcBackend` is the canonical local backend class.
- `MirrorEditorScreen` remains UI-focused; orchestration and realtime are handled by dedicated services.

## Runtime Components

- `MirrorEditorScreen`: user interaction surface
- `MirrorEditorOrchestrationService`: compile and apply orchestration
- `MirrorEditorRunService`: run lifecycle and in-flight guards
- `MirrorEditorRealtimeController`: realtime stream subscription and dedup
- `MirrorGatewayBackend`: cloud path transport and error mapping
- `PrivateGrpcBackend`: local path transport
- `mirror-gateway`: auth validation, idempotency claim/finalization, forwarding
- Runner services: request execution, artifacts, diagnostics

## End-To-End Flow

1. User opens Mirror from task or project context.
2. Provider resolves entitlement and mode eligibility.
3. UI submits compile request through selected backend.
4. Mirror Gateway validates auth, applies idempotency controls, forwards request.
5. Runner executes compile/apply and returns structured result.
6. Session, artifacts, and audit state are persisted.
7. Realtime updates refresh UI state.

## Data Boundaries

- Session metadata and version tracking: `ai_sessions`
- Idempotency ledger: `mirror_request_idempotency`
- Audit trail: `mirror_apply_audit_events`
- Storage buckets: `mirror-signed-inputs`, `mirror-backups`

## Design Principles

- Explicit boundaries between UI, policy, transport, and compute
- Deterministic behavior via structured errors and idempotency
- Security-first defaults, fail closed on missing secrets
- Offline continuity with encrypted local cache and outbox replay
