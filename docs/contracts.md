# Contracts

## Contract Scope

This document defines the stable interfaces across client, edge, backend, database, and storage layers.

## Naming Map

Canonical names:

- Cloud backend class: `MirrorGatewayBackend`
- Local backend class: `PrivateGrpcBackend`
- Edge gateway function: `mirror-gateway`
- Storage buckets: `mirror-signed-inputs`, `mirror-backups`

Deprecated aliases must not be introduced in new code or documentation.

## API Contracts

### Compile

- Endpoint category: Mirror compile workflow
- Required metadata: request correlation IDs and mode context
- Expected result: structured compile output with diagnostics and machine-readable status

### Apply

- Endpoint category: Mirror apply workflow
- Required metadata: idempotency key and request identity
- Expected result: structured apply status, audit linkage, and backup references when applicable

## Idempotency Contract

- Claim record before upstream execution
- Detect and recover stale processing claims
- Finalize only for matching request identity and hash
- Replay cached response for already finalized key where contract allows

## Database Contracts

Primary tables:

- `ai_sessions`: session lifecycle and version state
- `mirror_request_idempotency`: replay protection ledger
- `mirror_apply_audit_events`: apply audit and fingerprints
- `feature_flags`: runtime gates and variant values

Minimum contract requirements:

- RLS enabled and validated
- Required indexes present for high-frequency lookup paths
- Migrations are additive-safe and rollback-documented

## Storage Contracts

- Private buckets only
- Canonical buckets: `mirror-signed-inputs`, `mirror-backups`
- Object path must be owner-prefixed by authenticated `auth.uid`
- Signed URLs are short-lived and object-scoped

## Backend Contract Rules

- Mirror Gateway does not execute compile/apply compute
- Runner services enforce quotas, request validation, and timeout boundaries
- Errors are structured and stable for client mapping

## Versioning Guidance

- Backward-compatible changes: additive fields and optional metadata
- Breaking changes: require versioned contract rollout and migration notes
- Contract tests must pass before release promotion
