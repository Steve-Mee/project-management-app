# Mirror Threat Model

## Purpose

This document records the threat model for Mirror across the Flutter client, Supabase gateway, cloud runner, local runner, Supabase data plane, and admin governance surfaces.

It is intended to support security review, operational readiness, and change approval for high-risk Mirror changes.

Use this together with:
- [architecture.md](architecture.md)
- [security.md](security.md)
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [feature-flags.md](feature-flags.md)

## Scope And Trust Boundaries

Mirror runtime spans these components:
- Flutter client UI, providers, and encrypted Hive cache
- Supabase Edge Function `mirror-gateway`
- Cloud runner `MirrorGatewayBackend` path
- Local runner `PrivateGrpcBackend` path
- Supabase Postgres tables and private Storage buckets
- Admin feature-flag management surfaces

Primary trust boundaries:
- user device to Supabase auth and API boundary
- client to `mirror-gateway`
- gateway to cloud or local runner upstream
- runner to Supabase Storage and audit/usage persistence
- admin users to feature-flag write surfaces

Architecture lock assumptions:
- `supabase/functions/mirror-gateway` is a thin proxy only and must not execute user compute
- compute runs only on approved runner services
- service secrets remain outside client artifacts
- Mirror-related data stores remain protected by RLS or equivalent owner scoping

## Assets To Protect

High-value assets:
- bearer JWTs and role claims
- runner service tokens and JWT verification secrets
- signed artifact URLs and stored patch/backups in `mirror-signed-inputs` and `mirror-backups`
- source patches, backups, and workspace content
- Mirror audit and usage records
- feature-flag state controlling Mirror availability or behavior
- premium and permission entitlements controlling cloud access

Security objectives:
- only authenticated and authorized users can launch Mirror workflows
- apply operations are attributable, replay-resistant, and auditable
- artifact access remains owner-scoped and short-lived
- admin-only controls cannot be exercised by standard users
- runner compromise has bounded blast radius through layered controls and rollback paths

## STRIDE Analysis

### Spoofing

Threats:
- attacker reuses or forges bearer tokens to call `mirror-gateway`
- attacker attempts to call runner endpoints directly without valid gateway-issued auth
- attacker manipulates project/task identifiers or route parameters to operate on another context
- attacker attempts admin feature-flag writes without required role claims

Current mitigations:
- gateway and runner boundaries require bearer JWT validation and fail closed when required auth secrets are absent
- cloud and local runner startup requires `MIRROR_SERVICE_TOKEN`, `MIRROR_JWT_SECRET`, and related JWT configuration before serving traffic
- feature-flag writes require Supabase RLS policies keyed on `auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'`
- admin UI additionally gates write access behind `manage_roles` or `manage_users` permission checks before presenting controls
- request schema validation rejects malformed identifiers and invalid payload structure before forwarding

Residual risk:
- stale or mis-rotated JWT keys could temporarily widen acceptance if operational rotation is not tightly controlled

### Tampering

Threats:
- attacker alters compile/apply payloads in transit or replays modified apply requests
- attacker tampers with signed artifacts or backup references
- attacker manipulates idempotency state to force duplicate or conflicting apply execution
- attacker mutates feature flags or Mirror audit records outside approved controls

Current mitigations:
- gateway request schema enforces prompt presence, 50,000-character prompt ceiling, workspace/file-count limits, and structured action/mode validation
- idempotency ledger records claim, processing, completion, expiry, and guarded finalization state for non-idempotent execution paths
- apply flow centralizes preview/apply consistency checks before final patch transport
- signed flow stores artifacts in private buckets with owner-prefixed paths and short-lived signed URLs
- Supabase RLS protects `feature_flags`, `mirror_usage_logs`, `mirror_apply_audit_events`, and related Mirror tables
- UUID foreign-key hardening and normalization triggers protect audit/usage tables from malformed context IDs

Residual risk:
- signed artifacts are still sensitive while their URLs are live, so leakage during the TTL window remains possible if endpoints, logs, or clients mishandle them

### Repudiation

Threats:
- user denies initiating an apply or feature-flag change
- operator cannot reconstruct which request caused an upstream failure or state mutation
- admin changes occur without enough identity or before/after state to support review

Current mitigations:
- Mirror usage and apply paths record audit/usage events with correlation IDs and context IDs
- local apply history is preserved in encrypted Hive for client resilience while server audit remains in Supabase-backed audit tables
- feature-flag changes are surfaced through analytics/audit views that record who changed what and when, including previous and next values
- operational runbook requires collecting request ID, trace ID, user ID, project ID, task ID, mode, and error family before escalation

Residual risk:
- local Hive audit history is resilience-focused and not a substitute for server-side audit evidence if the client device is lost or compromised

### Information Disclosure

Threats:
- signed URLs leak patches or backups to unintended parties
- client cache or local session data exposes sensitive Mirror state on-device
- gateway or runner logs capture raw prompts, patches, or secrets
- cross-tenant data access occurs through weak storage or table isolation

Current mitigations:
- `mirror-signed-inputs` and `mirror-backups` are private buckets with owner-scoped storage policies and short-lived signed URLs
- signed artifact URLs created by the current client flow default to 120-second TTL
- encrypted Hive is used for local resilience, including apply audit storage and cached state
- security guidance explicitly requires service tokens and JWT verification material to stay out of client artifacts
- upstream error sanitization limits what raw upstream response data is surfaced through gateway error details
- usage/audit relational hardening binds context IDs to valid project/task UUIDs

Residual risk:
- prompts and patches are inherently sensitive business data; operators must continue to treat logs, exported diagnostics, and screenshots as confidential material

### Denial Of Service

Threats:
- attacker floods compile or apply endpoints with expensive requests
- replay or stale-processing lock contention prevents legitimate execution
- runner workspace or storage buildup degrades service availability
- upstream instability cascades from runners to gateway and clients

Current mitigations:
- gateway exposes request rate limits, burst controls, weighted action budgets, timeouts, and circuit-breaker settings via environment configuration
- request schema enforces maximum file count and workspace-size boundaries before execution
- idempotency TTL and stale-claim recovery prevent permanent lockout from abandoned processing records
- SQL cleanup functions and required indexes support scheduled idempotency cleanup
- cloud and local runners schedule workspace cleanup and cap execution/workspace settings through environment knobs
- operational runbook defines timeout-spike, auth-surge, and circuit-breaker incident procedures with rollback order

Residual risk:
- sustained valid-but-expensive traffic can still pressure runner capacity; rate and quota tuning remains an operational responsibility, not a fully solved code path

### Elevation Of Privilege

Threats:
- standard user gains cloud Mirror access without entitlement
- standard user changes feature flags or other admin-only controls
- compromised client attempts to bypass UI guards and call privileged backend paths directly
- runner or gateway secrets are misconfigured and permit broader access than intended

Current mitigations:
- app policy gates Mirror behind permissions such as `use_mirror` and premium/cloud eligibility resolution
- cloud access checks are enforced beyond the UI through gateway/backend entitlement checks
- feature-flag writes are protected twice: client permission gating and Supabase RLS requiring admin role claims
- local runner requires auth guard to remain enabled and binds locally by default
- required runtime secrets are validated at startup; missing critical auth material prevents service startup

Residual risk:
- feature flags remain a high-leverage control plane. A compromised admin account can intentionally or accidentally widen exposure unless governance and approval practices are followed

## Known Mitigations

### Prompt Injection And Unsafe Inputs

Mitigations:
- gateway schema validation rejects empty prompts and caps prompt size at 50,000 characters
- request validation also enforces bounded file count and workspace bytes before forwarding
- gateway is a thin proxy only, reducing the attack surface inside the edge function itself
- structured error sanitization limits accidental reflection of unsafe upstream payloads back to clients

Limits:
- these controls reduce malformed and oversized input risk, but they do not eliminate logical prompt-injection risk in model-generated suggestions. Human review of apply output remains part of the trust model

### Artifact Leakage

Mitigations:
- signed apply flow stores payloads in private buckets only
- storage access is owner-scoped
- signed URLs are short-lived and currently default to 120 seconds in the client service
- cleanup function support exists for stale storage artifacts

Limits:
- leakage inside the TTL window remains possible through copied URLs, logs, or screen capture

### Privilege Escalation

Mitigations:
- JWT validation is required at gateway and runner boundaries
- RLS protects feature flags, audit, usage, and idempotency tables
- entitlement checks gate cloud access and Mirror usage before privileged actions complete
- local runner auth guard cannot be disabled in the supported configuration

Limits:
- secret rotation discipline and claim issuance remain operational dependencies; code cannot compensate for compromised identity infrastructure

### Admin Bypass

Mitigations:
- feature-flag admin surface is permission-gated in the client
- Supabase RLS is the authoritative write barrier for `feature_flags`
- audit views preserve who changed which flag and the previous/next state
- failed admin writes surface safe denial without mutating persisted state

Limits:
- governance still depends on admin account hygiene and review discipline for high-risk flag changes

## Residual Risks

### Cloud Runner Compromise

Risk:
- the cloud runner remains a concentrated execution surface. A vulnerability there could expose in-flight workspaces, artifacts, or execution metadata

Why accepted now:
- architecture keeps compute out of the edge function
- local runner remains available as a defense-in-depth and fallback path
- service startup requires explicit auth and artifact configuration
- rollback, canary, and secret-rotation procedures are documented operationally

Follow-up:
- continue narrowing runner privileges, keep secrets rotated with overlap windows, and review network exposure during each deployment

### State Hydration Races

Risk:
- async hydration order could otherwise flip effective Mirror mode or entitlement state, leading to incorrect policy application

Why accepted now:
- generation-guarded hydration, explicit provenance fields, fallback reasons, and tests reduce the likelihood of silent mode drift
- degraded states are surfaced rather than hidden

Follow-up:
- retain regression coverage around hydration precedence and stale-cache fallback whenever mode-resolution logic changes

### Template Staleness

Risk:
- cached or stale template content could mislead users into applying outdated scaffolding or assumptions

Why accepted now:
- stale fallback is explicitly represented in provider state
- UI shows stale-warning messaging when fallback templates are used
- template loading remains bounded and refreshable by the user

Follow-up:
- continue monitoring template freshness telemetry and tighten invalidation if stale usage becomes common

## Admin Governance

### Control Owners

Feature-flag changes are reserved for admins.

Authoritative controls:
- Supabase RLS requires JWT `app_metadata.role == 'admin'` for `INSERT`, `UPDATE`, and `DELETE` on `public.feature_flags`
- client admin surfaces additionally require `manage_roles` or `manage_users` permissions before exposing write controls

Operational expectation:
- routine support staff may inspect flag state, but only approved admins should perform mutations

### Audit Requirements

Every high-risk configuration change should answer:
- who made the change
- when it was made
- which flag changed
- previous enabled/value state
- resulting enabled/value state
- rollout or incident reference if applicable

Current audit path:
- feature-flag changes are visible through the admin audit view backed by analytics events
- Mirror apply and usage paths separately record operational audit evidence for compile/apply activity

### Approval Process For High-Risk Changes

Treat these as high risk:
- enabling or disabling `mirror_enabled`
- widening cloud access or premium-gated behavior
- changing flags that alter apply security posture, rollout audience, or admin-only functionality

Required process:
1. document intended change, owner, rollback plan, and affected environments
2. verify current flag state and recent audit history
3. obtain approval from the responsible engineering owner and security/release owner
4. execute change during an observable window with smoke-test ownership assigned
5. confirm audit entry, product behavior, and rollback readiness immediately after mutation

Emergency path:
- a single approved admin may disable a risky feature during an incident, but must attach the incident reference and complete retrospective review afterward

## Review Triggers

Update this threat model when any of the following changes:
- gateway request schema or idempotency semantics
- runner authentication, binding, or storage behavior
- signed artifact TTL or bucket policy
- feature-flag write controls or admin roles
- premium or permission gating for Mirror launch or cloud access
- new compute surfaces, external integrations, or admin workflows

## Security Sign-Off Checklist

Before marking a security-sensitive Mirror change complete, confirm:
- STRIDE impact was reviewed for all touched components
- RLS or equivalent storage isolation was validated for any new data path
- auth and secret requirements were verified in runtime config
- audit evidence exists for privileged actions and apply operations
- residual risks were either reduced or explicitly accepted by owners