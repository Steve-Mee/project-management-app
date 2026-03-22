# Mirror Secure Apply Backend Comparison

## Scope

Task 2.5 compared the apply-security behavior in:
- `lib/features/mirror/mirror_gateway_backend.dart`
- `lib/features/mirror/private_grpc_backend.dart`
- `lib/features/mirror/services/mirror_secure_apply_service.dart`
- `lib/features/mirror/services/mirror_backend_workflows.dart`

## Divergences Before Consolidation

### Gateway backend
- Had an explicit `useSecureApply` toggle with separate secure and non-secure branches.
- Re-ran preview compile and consistency validation inside the backend apply method.
- Used gateway-local structured error formatting for validation/config/consistency failures.
- Built patches, applied audit persistence, and handled no-patch failures inline.

### Private gRPC backend
- Always used signed secure-apply preparation.
- Re-ran preview compile and consistency validation inside the backend apply method.
- Used shared backend error formatting for validation/consistency failures.
- Built patches, applied audit persistence, and handled no-patch failures inline.
- Did not centralize direct-vs-signed apply mode decisions.

### Shared secure apply service
- Already owned backup ID generation, file-set fingerprinting, signed URL generation, and apply audit events.
- Did not provide retry handling for artifact uploads / signed URL generation.
- Was shared by both backends indirectly, but the surrounding apply orchestration still diverged.

## Consolidation Implemented

### Shared orchestration
`MirrorBackendWorkflows.executeApplyFlow(...)` now centralizes:
- preview compile preflight
- preview/apply consistency validation
- patch extraction for security-mode sizing
- direct vs signed mode selection via `MirrorApplySecurityModeService`
- signed artifact preparation via `MirrorSecureApplyService`
- final apply-output patch extraction
- signed-flow Hive audit persistence
- uniform validation/config/consistency failure shaping via the shared backend formatter

### Artifact retry behavior
`MirrorSecureApplyService` now wraps these artifact operations in a shared retry helper:
- signed-input upload
- backup upload
- signed-input signed URL creation
- backup signed URL creation

This gives both gateway and gRPC the same artifact failure semantics.

## State After Consolidation

### Gateway backend
- Delegates apply orchestration to `executeApplyFlow(...)`.
- Still owns HTTP transport, request tracing, retry policy, and response normalization.
- Uses shared backend error formatting for orchestration-level apply failures.

### Private gRPC backend
- Delegates apply orchestration to `executeApplyFlow(...)`.
- Still owns gRPC transport concerns and RPC error capture.
- Uses the same shared apply error formatter and security-mode decision path as gateway.

## Remaining Constraints

- Trust score computation is still not implemented elsewhere in the app. The backends therefore use constructor-configurable defaults.
- Existing broad gateway contract tests are partly stale relative to the already-modularized edge-function entrypoint and current UUID schema validation; they were not used as Task 2.5 completion criteria.

## Acceptance Mapping

- `2.5.1`: comparison document exists and records prior divergences.
- `2.5.2`: shared apply orchestration and artifact logic are centralized.
- `2.5.3`: upload / signed URL artifact retries and error shaping are unified.
- `2.5.4`: targeted security-mode + integration-contract tests cover direct/signed decision branches and shared backend wiring.
