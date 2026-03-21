# Mirror Apply Security Mode Integration Guide

## Overview

The `MirrorApplySecurityModeService` centralizes the decision logic for determining how patches should be delivered to the runner (signed vs. direct flow). This ensures both the cloud gateway backend and private gRPC backend make identical security decisions.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│   User Request (modify/apply patches)               │
└──────────────────┬──────────────────────────────────┘
                   │
                   ├─────────────────────────────────────────────┐
                   │                                             │
        ┌──────────▼─────────────┐                   ┌───────────▼─────────┐
        │  Cloud Gateway Backend  │                   │  Private gRPC       │
        │  (mirror_gateway.dart)  │                   │  (mirror_grpc.dart) │
        └──────────┬──────────────┘                   └───────────┬─────────┘
                   │ (both call)                                  │
                   │                                             │
                   │      ┌──────────────────────────────────────┘
                   │      │
        ┌──────────▼──────▼──────────────────────────┐
        │  MirrorApplySecurityModeService            │
        │  • determineApplySecurityMode()            │
        │  • logSecurityModeDecision()               │
        │  • buildApplySecurityModeFactors()         │
        └──────────┬───────────────────────────────┘
                   │
                   ├─────────────────────────────┐
                   │                             │
        ┌──────────▼─────────────┐   ┌──────────▼──────────┐
        │  Signed Flow            │   │  Direct Flow        │
        │  • Upload to Supabase   │   │  • Inline in body   │
        │  • Use signed URLs      │   │  • <100KB patches   │
        │  • Audit trail          │   │  • Fast response    │
        └─────────────────────────┘   └─────────────────────┘
```

## Decision Rules (Priority Order)

The service applies these rules in order:

1. **Explicit Policy** (Binding)
   - If `requireSignedApply=true`, force signed flow
   - This is a security binding decision (cannot be overridden)

2. **Cloud Mode + Large Patches** (Binding)
   - If `isCloudMode=true` AND `totalPatchBytes > 50KB`, force signed flow
   - Cloud deployments are more sensitive to audit exposure

3. **Low Trust Score** (Binding)
   - If `userTrustScore < 70`, force signed flow
   - Trust score is computed from apply success history and abuse patterns

4. **Audit Logging Enabled** (Non-Binding Preference)
   - If `auditLoggingEnabled=true` AND `totalPatchBytes > 50KB`, prefer signed flow
   - Audit trail benefits justify upload overhead

5. **Small Patches** (Non-Binding)
   - If `totalPatchBytes ≤ 100KB`, use direct flow (fast path)
   - Direct flow is suitable for small patches

6. **Default to Signed** (Non-Binding)
   - Large patches default to signed flow (secure path)
   - Ensures audit trail for significant changes

## Integration Checklist

### Step 1: Import the Service

```dart
// In your backend file (mirror_gateway.dart or mirror_grpc.dart)
import 'package:my_project_management_app/features/mirror/services/mirror_apply_security_mode_service.dart';
```

### Step 2: Get Security Mode at Apply Time

```dart
// In your apply endpoint/handler:

// Build factors from current context
final factors = buildApplySecurityModeFactors(
  totalPatchBytes: patchData.length,
  auditLoggingEnabled: auditConfig.isEnabled,
  mode: isCloudMode ? 'cloud' : 'private',
  requireSignedApply: profileData.policyRequireSignedApply,
  userTrustScore: await computeUserTrustScore(userId),
);

// Get decision
final decision = mirrorApplySecurityModeService.determineApplySecurityMode(factors);

// Log for observability
mirrorApplySecurityModeService.logSecurityModeDecision(
  sessionId,
  decision,
  factors,
);
```

### Step 3: Implement Flow Based on Decision

```dart
if (decision.mode == MirrorApplySecurityMode.signed) {
  // Signed flow: upload patch to Supabase storage, get signed URL
  final storageKey = await supabaseStorage.uploadPatch(patchData);
  final signedUrl = supabaseStorage.getSignedUrl(storageKey);
  
  return ApplyResponse(
    patchUrl: signedUrl,
    method: 'fetch_signed_url',
    requiresVerification: true,
  );
} else {
  // Direct flow: send patch inline in response
  return ApplyResponse(
    patchData: patchData,
    method: 'inline',
    requiresVerification: false,
  );
}
```

### Step 4: Handle Non-Binding Preferences

Non-binding decisions (rules 4–6) can be overridden by user request:

```dart
MirrorApplySecurityMode getApplyMode(
  ApplySecurityModeDecision decision,
  bool? userPreferredSignedMode,
) {
  // If decision is binding (security policy), cannot override
  if (decision.isSecurityBindingDecision) {
    return decision.mode;
  }
  
  // If user explicitly requested a mode, honor it
  if (userPreferredSignedMode != null) {
    return userPreferredSignedMode 
      ? MirrorApplySecurityMode.signed 
      : MirrorApplySecurityMode.direct;
  }
  
  // Fall back to service recommendation
  return decision.mode;
}
```

### Step 5: Testing Integration

For unit tests of your backend:

```dart
import 'package:my_project_management_app/features/mirror/services/mirror_apply_security_mode_service.dart';

test('cloud apply with large patches uses signed flow', () async {
  final factors = buildApplySecurityModeFactors(
    totalPatchBytes: 60 * 1024,
    auditLoggingEnabled: false,
    mode: 'cloud',
    requireSignedApply: false,
    userTrustScore: 100,
  );

  final decision = mirrorApplySecurityModeService.determineApplySecurityMode(factors);

  expect(decision.mode, MirrorApplySecurityMode.signed);
  expect(decision.isSecurityBindingDecision, true);
});
```

## Observability & Monitoring

The service emits structured logs:

```
Mirror apply security mode decision: sessionId=abc123, mode=signed, binding=true, 
patchBytes=60.0KB, cloudMode=true, trustScore=100 — Cloud mode + large patches (60.0KB) → signed flow
```

**Metrics to Track:**
- Frequency of each decision rule triggering
- Distribution of patch sizes by decision rule
- Override rate (user override vs. service recommendation)
- Latency impact of signed vs. direct flow in production

## Migration Strategy

### Phase 1: Cloud Gateway Backend
- Integrate `MirrorApplySecurityModeService` into `mirror_gateway_backend.dart`
- Add tests for decision rules in cloud context
- Deploy behind feature flag

### Phase 2: Private gRPC Backend
- Integrate same service into `mirror_grpc_backend.dart`
- Both backends now use identical logic
- No behavioral divergence possible

### Phase 3: Audit & Hardening
- Verify audit logs capture all signed applies
- Add admin dashboard for trust score trending
- Implement abuse detection for rapid trust score drops

## FAQ

**Q: Can a user override a binding decision?**
A: No. Binding decisions (explicit policy, cloud mode, low trust score) cannot be overridden.

**Q: What if the service crashes during apply?**
A: Fallback to most-conservative (signed) flow in error handlers.

**Q: How is `userTrustScore` computed?**
A: Recommend a dedicated compute service (out of scope here). Factors: apply success rate, apply frequency over time, presence of abuse patterns, security incident history.

**Q: Why is cloud mode more conservative (50KB threshold) than private (100KB)?**
A: Cloud deployments have broader audit surface; small overhead for signed flow is justified.

**Q: Can I disable the signed flow entirely?**
A: Only via feature flag for backward compatibility. Not recommended for production.
