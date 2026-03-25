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

- `MirrorEditorScreen`: user interaction surface only — no orchestration logic
- `MirrorRunFlowService`: UI-facing run wrapper; widget concerns, dialog display, terminal line mapping
- `MirrorApplyFlowCoordinator`: owns the full generate → compile → preview → approve → apply pipeline; no Flutter widgets or BuildContext
- `MirrorOrchestratorService`: wraps the active compute backend with retry and outbox replay resilience
- `MirrorBackendWorkflows`: pure stateless patch-building utility; deterministic transforms only, no side effects
- `MirrorApplyPostHooksService`: post-apply persistence hooks (timestamps, drafts); no provider invalidation
- `MirrorGatewayBackend`: cloud path transport and error mapping
- `PrivateGrpcBackend`: local path transport (config via `MirrorPrivateGrpcRuntimeConfig`)
- `mirror-gateway`: auth validation, idempotency claim/finalization, forwarding
- Runner services: request execution, artifacts, diagnostics

## Mirror Orchestration Ownership

Each Mirror service has a single ownership axis. Never mix.

| Service | Owns | Does NOT own |
|---|---|---|
| `MirrorRunFlowService` | Widget concerns, session reads, approval dialog, terminal lines | Backend calls, pipeline logic |
| `MirrorApplyFlowCoordinator` | generate→compile→preview→approve→apply pipeline | UI widgets, provider invalidation |
| `MirrorOrchestratorService` | Retry policy, outbox replay, circuit-breaker wrapping | Apply flow sequencing, UI |
| `MirrorBackendWorkflows` | Patch/plan construction (pure functions) | State, network, side effects |
| `MirrorApplyPostHooksService` | Post-apply persistence (timestamps, drafts) | Provider invalidation, backend calls |

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

## Mirror Mode Resolution Precedence

Mirror mode and variant hydration are resolved in deterministic order so async source timing cannot silently change the effective mode.

Resolution order:

1. Explicit requested mode (user intent)
2. Cached mode (offline continuity)
3. Feature-gate constraints (hard disable)
4. Premium entitlement and policy decision
5. Runner/team variant fallback

Hydration provenance is tracked in `MirrorState` via:

- `hydrationPhase`
- `modeSource`
- `premiumSource`
- `teamModeVariantSource`
- `runnerModeVariantSource`
- `hydrationReasonCode`
- `fallbackReason`

These fields are emitted through `mirror_mode_resolution` telemetry events and surfaced in debug diagnostics on the Mirror editor screen.

## Apply Security & Delivery Mode

The `MirrorApplySecurityModeService` centralizes the decision logic for patch delivery (signed vs. inline flow):

- **Signed Flow**: Patches uploaded to Supabase Storage with signed URLs; suitable for large patches, audit-sensitive contexts, and cloud deployments.
- **Direct (Inline) Flow**: Patches sent in request body; suitable for small patches (<100KB) and trusted users.

Decision factors include total patch size, audit logging status, cloud vs. private mode, explicit security policies, and user trust score.

See [Mirror Apply Security Mode Integration Guide](mirror_apply_security_mode_integration.md) for full details.
