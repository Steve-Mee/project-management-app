// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Threat Model

## Purpose
Mirror processes user-authenticated compile/apply requests and temporary artifacts across client, Mirror Gateway, runner, and storage layers.

This document identifies high-risk threat scenarios and defines required controls, detection signals, and response actions.

## Scope
The threat model in this document covers:

- Signed input upload/download URLs
- Runner endpoint exposure (`/compile`, `/apply`)
- Token misuse across Mirror Gateway and runner boundaries
- Replay attacks on compile/apply requests
- Related storage and audit boundaries

## System Boundaries
### Trust Zones
- Client zone: authenticated app session and user-owned request payloads
- Gateway zone: Mirror Gateway `mirror-gateway` (thin proxy only)
- Runner zone: cloud/local runner services
- Storage zone: Supabase Storage buckets (`mirror-signed-inputs`, `mirror-backups`)
- Data zone: `ai_sessions` and `mirror_apply_audit_events`

### Security-Critical Assets
- Bearer JWTs and service tokens
- Signed URL tokens for object access
- Apply payloads and patch artifacts
- Backup artifacts and audit event records
- Idempotency keys and request identifiers

## Threat Scenarios

### 1. Signed URL Leakage Or Over-Permission
#### Attack
- Attacker obtains a valid signed URL from logs, crash reports, browser history, or proxy traces.
- URL is reused to read/write objects outside intended operation window.

#### Impact
- Unauthorized artifact access
- Exfiltration of source files or backups
- Potential overwrite of expected inputs

#### Required Controls
- Keep signed URL TTL short (default target: <= 5 minutes)
- Scope signed URLs to a single object path and method
- Enforce owner-prefixed object path contract: `<auth.uid>/<projectId>/<taskId>/...`
- Never log full signed URLs in app/edge/runner logs
- Use private buckets only; enforce RLS owner checks

#### Detection
- Spike in storage access outside normal compile/apply windows
- Repeated access from different IPs for the same signed URL window
- Failed owner-path policy checks in storage logs

#### Response
- Rotate storage signing key material per platform process
- Invalidate affected object paths and regenerate artifacts
- Review logging sinks for accidental URL exposure

### 2. Runner Endpoint Exposure
#### Attack
- Runner endpoints are exposed publicly or weakly protected.
- Attacker sends direct compile/apply requests bypassing edge policy.

#### Impact
- Unauthorized compute usage and cost amplification
- Potential execution of malicious payloads
- Bypass of standard auth, quota, and audit controls

#### Required Controls
- Require runner auth headers and JWT validation (`MIRROR_JWT_KEYS_BY_KID`)
- Keep runner endpoints behind allowlisted network boundaries where possible
- Fail closed when required runner secrets are missing
- Enforce request size/file-count/workspace-byte limits in gateway
- Maintain structured error responses without leaking internals

#### Detection
- Requests without expected request-id/idempotency headers
- Elevated unauthorized/forbidden runner responses
- Unusual compile/apply rate from unknown sources

#### Response
- Rotate runner secrets immediately
- Restrict ingress and re-validate firewall/allowlist settings
- Trigger incident triage for suspicious request patterns

### 3. Token Misuse (Bearer Or Service Tokens)
#### Attack
- Stolen bearer token or service token is reused from another environment/device.
- Token with stale key (`kid`) accepted due to weak rotation process.

#### Impact
- Unauthorized mirror operations under valid identity context
- Cross-tenant or cross-user artifact operations if policy checks fail

#### Required Controls
- Validate bearer auth at Mirror Gateway on every request
- Validate runner JWTs against active key map (`kid` aware)
- Keep service tokens out of client binaries and browser-visible channels
- Rotate keys with overlap window and monitored cutover
- Enforce environment separation for dev/staging/prod secrets

#### Detection
- Auth denials spiking after key rotation
- Requests with impossible geo/device patterns for a user
- Repeated token validation failures for unknown `kid`

#### Response
- Revoke and rotate compromised tokens/keys
- Force client re-authentication where needed
- Audit access logs and affected artifact paths

### 4. Replay Attacks (Compile/Apply)
#### Attack
- Attacker replays previously captured compile/apply request bodies.
- Duplicate apply operations are attempted to trigger unsafe repeated writes.

#### Impact
- Duplicate operations, unexpected state transitions
- Redundant or conflicting artifact updates
- Increased resource consumption

#### Required Controls
- Require idempotency keys for apply and propagate across edge/runner
- Persist idempotency claim state with TTL and terminal status
- Reject in-progress and already-finalized replay attempts deterministically
- Bind idempotency to operation + actor + project/task scope
- Record replay conflicts in audit/event logs
- Detect and recover stale `processing` claims (threshold: 300 s); take over via `resetIdempotencyKeyClaim` before forwarding
- Finalize guard: `finalizeIdempotencyKey` only succeeds when `request_id`, `request_hash`, AND `status = 'processing'` all match the active claim; returns `idempotency_update_conflict` on ownership mismatch

#### Detection
- Repeated idempotency key usage across short windows
- High conflict/in-progress replay response rates
- Unexpected duplicate apply event fingerprints

#### Response
- Increase replay monitoring sensitivity
- Block suspicious clients/IP ranges during active abuse
- Review idempotency TTL and claim/finalize race handling

### 5. Stale Idempotency Claim Hijacking
#### Attack
- A `processing` idempotency record is left in the table after a runner crash, network partition, or extended backpressure delay (record is never finalized).
- A subsequent legitimate request finds a non-expired record with the same key but a different request hash, triggering a false conflict that permanently blocks future requests for that key.
- Alternatively, a different request with the same key is returned `in_progress` indefinitely when the original processing request is already dead.

#### Impact
- Legitimate compile/apply requests are permanently blocked by orphaned in-progress records
- Denial of service for a specific user + project/task combination
- Ghost replay conflicts creating confusing error states in the client

#### Required Controls
- Treat `processing` records older than `IDEMPOTENCY_PROCESSING_STALE_SECONDS` (300 s) as stale and take them over via `resetIdempotencyKeyClaim`
- Evaluate staleness at every claim path: initial `SELECT`, race-condition re-`SELECT` after insert conflict
- Treat expired records (`expires_at <= now()`) as fully reclaimed regardless of status
- Different `request_hash` + expired/stale = reclaim; different hash + live = conflict (correct rejection)
- Finalize operation uses `request_id` + `request_hash` + `status = processing` guard to prevent foreign-claim finalization

#### Detection
- Elevated `idempotency_update_conflict:no_matching_processing_claim` error events in gateway logs
- Processing records older than stale threshold that were never finalized
- Repeated 409-conflict responses for requests that should be fresh

#### Response
- Investigate runner/network health for crash patterns that leave orphaned claims
- Review stale threshold and TTL values against observed P95 runner latency
- Alert on claim takeover rate exceeding baseline
| Threat | Primary Control Owner | Residual Risk | Escalation Path |
|---|---|---|---|
| Signed URL leakage | Security Engineering | Medium | Security on-call -> SRE |
| Runner exposure | SRE | Medium | SRE on-call -> Backend |
| Token misuse | Security Engineering | Medium | Security on-call -> Auth owner |
| Replay attacks | Backend API | Low/Medium | Backend on-call -> Security |
| Stale claim hijacking | Backend API | Low | Backend on-call -> SRE |

## Verification Checklist
- Signed URL TTL and path scoping validated in staging
- Runner direct-call denial tested from non-allowlisted path
- Key rotation runbook executed with active `kid` transition
- Replay test cases cover conflict, in-progress, and finalized states
- Storage logs and audit tables include request-id and idempotency correlation
- Stale claim recovery tested: verify that a `processing` record > 300 s old is reclaimed rather than returning 409 conflict
- Finalize ownership guard tested: verify that a `finalizeIdempotencyKey` call with wrong `request_id` or `request_hash` returns `idempotency_update_conflict` and does not update the record
- Expired record recovery tested: verify requests succeed after TTL expiry of a previously claims record

## Related Documents
- `docs/mirror-ops-runbook.md`
- `docs/mirror-bucket-contract.md`
- `docs/mirror-production-readiness-checklist.md`
- `docs/supabase-setup.md`

