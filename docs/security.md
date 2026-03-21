# Security

## Security Model

Security enforcement is layered:

- Authentication: bearer JWT validation at gateway and backend boundaries
- Authorization: RLS and entitlement checks
- Storage isolation: owner-prefixed object paths in private buckets
- Replay protection: idempotency claims and guarded finalization
- Auditability: apply and usage events with correlation IDs

## RLS And Data Protection

Core controls:

- RLS enabled on Mirror-related tables including `ai_sessions`, `feature_flags`, and audit tables
- Storage policy enforces owner folder prefix with authenticated `auth.uid`
- Buckets are private and signed URL access is scoped and short-lived

Canonical storage resources:

- `mirror-signed-inputs`
- `mirror-backups`

## Entitlement And Access

- Feature usage is permission-gated in app policy (`use_mirror` and related permissions)
- Cloud path enforcement includes premium entitlement checks
- Admin write paths (for feature flags) require JWT role claims (`app_metadata.role == 'admin'`)

## Gateway Hardening

`mirror-gateway` responsibilities:

- Validate bearer auth and route-level input shape
- Enforce request limits and timeout controls
- Manage idempotency records for compile/apply
- Forward to compute upstream without executing user compute

## Replay And Idempotency

- Idempotency key claim is required for non-idempotent execution paths
- Stale processing claims are recoverable using threshold-based takeover
- Finalization is guarded by request identity and hash matching
- Replay conflicts return deterministic machine-readable errors

## Key Management And Secrets

- Keep service tokens out of client applications
- Rotate runner and JWT secrets with controlled overlap window
- Separate dev/staging/prod key material
- Fail closed when required runtime secrets are absent

## Threat Priorities

High-priority threat categories:

- Signed URL leakage
- Direct runner endpoint abuse
- Token misuse and stale key acceptance
- Replay attacks and stale idempotency lockout

Use [operations.md](operations.md) for incident response and [troubleshooting.md](troubleshooting.md) for diagnosis procedures.
