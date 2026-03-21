# Mirror Apply Security Mode: Integration Scenarios & Checklist

## Deployment Scenarios

### Scenario 1: Small User Workspace (Private Mode, High Trust)

**Context:**
- User running Mirror locally on private gRPC backend
- 5 tasks, patch size ~30 KB
- Audit logging disabled
- User trust score: 95 (excellent history)

**Decision Path:**
```
1. Rule 1: requireSignedApply = false ❌
2. Rule 2: isCloudMode = false ❌
3. Rule 3: userTrustScore (95) ≥ 70 ✓
4. Rule 5: totalPatchBytes (30KB) ≤ 100KB ✓

→ Mode: DIRECT (fast path)
→ Binding: NO (user can override)
→ Latency: ~100ms (no upload)
```

**You should implement:**
- Direct response with patch gzipped in request body
- No storage overhead
- Fast round-trip (ideal for LAN/localhost scenarios)

---

### Scenario 2: Cloud Deployment, Moderate Patches

**Context:**
- Corporate cloud deployment
- Patch size ~60 KB (multiple file changes)
- Audit logging enabled (compliance requirement)
- User trust score: 75 (normal activity)

**Decision Path:**
```
1. Rule 1: requireSignedApply = false ❌
2. Rule 2: isCloudMode = true ✓ && totalPatchBytes (60KB) > 50KB ✓

→ Mode: SIGNED (binding)
→ Binding: YES (cannot override)
→ Rationale: Cloud mode + large patches → strict audit trail required
→ Latency: ~500ms (upload to Supabase Storage + sign URL)
```

**You should implement:**
- Upload patch to `mirror-signed-inputs` bucket
- Generate signed URL (24h expiry recommended)
- Return URL to runner
- Audit log both upload and apply events
- Monitor storage quota to detect abuse

---

### Scenario 3: Rapid Iterations, Low Trust Score

**Context:**
- New user with limited apply history
- Patch size ~20 KB
- Private mode, no audit requirement
- Trust score: 35 (insufficient history)

**Decision Path:**
```
1. Rule 1: requireSignedApply = false ❌
2. Rule 2: isCloudMode = false ❌
3. Rule 3: userTrustScore (35) < 70 ✓

→ Mode: SIGNED (binding)
→ Binding: YES (security policy enforced)
→ Rationale: User trust score too low → require signed flow for safety
→ Latency: ~800ms (conservative path)
```

**You should implement:**
- Force signed flow regardless of patch size
- This builds trust history for future applies
- After ~10 successful applies, trust score increases
- User can see "your trust score improved, you can now use direct flow"

---

### Scenario 4: Policy Override (Enterprise Admin)

**Context:**
- Enterprise policy: all applies must be signed
- Patch size ~15 KB (normally would be direct)
- Cloud mode
- Policy: `requireSignedApply = true` (organizational mandate)

**Decision Path:**
```
1. Rule 1: requireSignedApply = true ✓

→ Mode: SIGNED (binding)
→ Binding: YES (explicit policy = strongest enforcement)
→ Rationale: User policy requires signed apply
```

**You should implement:**
- Read policy from user profile / Supabase `profiles(require_signed_apply)`
- Enforce binding decision, show user: "Your organization requires signed patches"
- Log as "policy-driven" decision for compliance audit

---

### Scenario 5: Fallback During Outage

**Context:**
- Supabase Storage experiencing intermittent failures
- Patch size ~75 KB (normally signed)
- User preference: use direct if storage unavailable

**Decision Path:**
```
Normal: SIGNED (rule applies)
Storage outage detected:
  → Try signed flow, fail gracefully
  → Check user preference: "allow_direct_on_storage_failure"
  → If true: downgrade to DIRECT (non-binding decision)
  → Warn user: "Using direct flow due to storage unavailability"
  → Log incident for observability
```

**You should implement:**
1. Wrap signed upload in try-catch
2. If upload fails AND `allow_direct_on_storage_failure` pref is set:
   ```dart
   try {
     await uploadToSignedStorage(patch);
   } on StorageException catch (e) {
     if (userPreferences.allowDirectOnStorageFailure) {
       logWarning('Storage unavailable, degrading to direct flow');
       return directFlowResponse(patch);
     }
     rethrow; // Fail if direct fallback not allowed
   }
   ```
3. Include incident metadata in audit log

---

## Implementation Checklist

### ✅ Phase 1: Service Creation (DONE)

- [x] Create `MirrorApplySecurityModeService` with decision rules
- [x] Create comprehensive unit tests (10+ test cases)
- [x] Verify zero compile errors with `flutter analyze`
- [x] Create integration guide documentation

### ⬜ Phase 2: Cloud Gateway Backend Integration (TODO)

- [ ] Import service in `mirror_gateway_backend.dart`
- [ ] Create `_getApplySecurityModeDecision()` method:
  ```dart
  Future<ApplySecurityModeDecision> _getApplySecurityModeDecision(
    String userId,
    int patchBytes,
  ) async {
    final userProfile = await supabase.getUserProfile(userId);
    final trustScore = await computeTrustScore(userId);
    
    final factors = buildApplySecurityModeFactors(
      totalPatchBytes: patchBytes,
      auditLoggingEnabled: auditConfig.isEnabled,
      mode: 'cloud',
      requireSignedApply: userProfile.requireSignedApply,
      userTrustScore: trustScore,
    );
    
    return mirrorApplySecurityModeService.determineApplySecurityMode(factors);
  }
  ```
- [ ] Modify apply() handler to call decision service
- [ ] Implement signed flow: upload → get signed URL → return to runner
- [ ] Implement direct flow: inline patch in response
- [ ] Add logging and metrics (decision, flow, latency)
- [ ] Add widget tests for decision coverage
- [ ] Test with feature flag `mirror_apply_security_mode_enabled`
- [ ] Deploy to staging, monitor error rates

### ⬜ Phase 3: Private gRPC Backend Integration (TODO)

- [ ] Import service in `mirror_grpc_backend.dart`
- [ ] Use identical decision logic as cloud backend
- [ ] Verify both backends produce identical decisions for same inputs
- [ ] Implement signed flow via gRPC stream of signed URL
- [ ] Implement direct flow via gRPC protobuf field `patch_data`
- [ ] Add e2e tests (private mode + both flows)
- [ ] Deploy alongside cloud backend

### ⬜ Phase 4: User Trust Score Computation (TODO)

- [ ] Create `UserTrustScoreService`:
  - Queries `mirror_apply_audit_events` for success rate
  - Tracks apply frequency (recent activity weight)
  - Detects abuse patterns (rapid failure, suspicious parallelism)
  - Stores computed score in `user_profiles(apply_trust_score)`
- [ ] Add cron job to recompute scores daily (off-peak)
- [ ] Add admin dashboard to view score trends
- [ ] Expose score to user: "Your apply trust score: 75/100"

### ⬜ Phase 5: Storage Fallback & Graceful Degradation (TODO)

- [ ] Add user preference: `allow_direct_on_storage_failure` (default=false)
- [ ] Implement storage availability check in gateway
- [ ] Fallback logic: if signed upload fails AND preference enabled, use direct
- [ ] Add incident logging and alerting
- [ ] Document fallback flow in troubleshooting guide

### ⬜ Phase 6: Audit & Hardening (TODO)

- [ ] Add column to `mirror_apply_audit_events`: `security_mode` (enum: signed/direct)
- [ ] Verify all signed applies are logged with storage key + signed URL
- [ ] Add admin view: filter applies by security mode, detect anomalies
- [ ] Implement alerting: "Unusual direct flow usage detected"
- [ ] Add RLS policy: only admins can query security mode decision logs
- [ ] Document compliance impact (SOC 2, ISO 27001)

### ⬜ Phase 7: Testing & Validation (TODO)

- [ ] Unit tests for all 6 decision rules ✓ (prebuilt)
- [ ] Integration tests: cloud gateway + signed flow
- [ ] Integration tests: cloud gateway + direct flow
- [ ] Integration tests: private backend + both flows
- [ ] E2E tests: full compile → apply → audit log flow
- [ ] Load test: patch upload throughput with signed URLs
- [ ] Failure test: storage outage → fallback to direct
- [ ] Compliance test: audit trail capture for all modes

---

## Observability Checklist

### Metrics to Track

```dart
// In your analytics/metrics service:

// Decision rule frequency
metrics.increment('mirror.apply.decision.rule_1_policy', factors.requireSignedApply ? 1 : 0);
metrics.increment('mirror.apply.decision.rule_2_cloud', isCloudMode ? 1 : 0);
metrics.increment('mirror.apply.decision.rule_3_trust', factors.userTrustScore < 70 ? 1 : 0);
metrics.increment('mirror.apply.decision.rule_4_audit', auditEnabled ? 1 : 0);
metrics.increment('mirror.apply.decision.rule_5_small', isPatchSmall ? 1 : 0);

// Distribution by mode
metrics.increment('mirror.apply.mode.signed', decision.mode == MirrorApplySecurityMode.signed ? 1 : 0);
metrics.increment('mirror.apply.mode.direct', decision.mode == MirrorApplySecurityMode.direct ? 1 : 0);

// Binding vs non-binding
metrics.increment('mirror.apply.binding_decision', decision.isSecurityBindingDecision ? 1 : 0);

// Latency by mode
final stopwatch = Stopwatch()..start();
final response = await applyPatch(decision);
metrics.recordValue('mirror.apply.latency_ms.${decision.mode.name}', stopwatch.elapsedMilliseconds);

// Override rate (user choice vs recommendation)
if (userRequestedMode != decision.mode) {
  metrics.increment('mirror.apply.override_count');
}
```

### Dashboards to Create

1. **Security Mode Decisions**: pie chart (signed vs direct), decision rules breakdown
2. **Patch Size Distribution**: histogram by security mode
3. **Trust Score Trends**: percentile distribution, outliers
4. **Apply Latency**: p50/p95/p99 by mode, trend over time
5. **Binding Decisions**: enforcement rate, policy trigger frequency

---

## Rollout Plan

### Week 1: Service & Unit Tests ✅
- Create service (`mirror_apply_security_mode_service.dart`)
- Comprehensive unit tests (10+ cases)
- Documentation

### Week 2: Cloud Gateway Integration
- Integrate into `mirror_gateway_backend.dart`
- Feature flag: `mirror_apply_security_mode_enabled`
- Deploy to staging, test signed + direct flows

### Week 3: Private Backend Integration
- Integrate into `mirror_grpc_backend.dart`
- Verify decision parity between backends
- E2E tests

### Week 4: Trust Score & Audit
- Implement trust score computation
- Audit logging for all modes
- Admin dashboard

### Month 2: Hardening & Production
- Storage fallback & graceful degradation
- Full compliance audit
- Performance tuning
- Production rollout (initially behind feature flag)

---

## Questions for Architecture Review

1. Is the 6-rule hierarchy correct, or should we reorder (e.g., cloud mode before policy)?
2. Should trust score be computed hourly or daily? Should it decay over time?
3. For fallback scenario, should direct flow be permanent or temporary (expire after 1 apply)?
4. Should we expose the decision rationale to the user in any UI warning/notice?
5. Any additional factors to consider (IP address, VPN, time-of-day, batch size)?
