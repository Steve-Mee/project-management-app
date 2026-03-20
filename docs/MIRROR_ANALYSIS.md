// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Implementation: Diepgaande Code Review & Architectuuranalyse

**Datum:** 20 maart 2026  
**Geanalyseerd door:** Senior Flutter/Supabase Architect (15+ jaren ervaring)  
**Scope:** Volledige Mirror feature (36 prompts) + integratie met bestaande app  
**Project:** https://github.com/Steve-Mee/project-management-app

---

## 1. Algemene beoordeling

### Sterke punten

1. **Architectuur Lock Pattern** ✅ - `mirror-gateway` is consequent een thin proxy. Alle compute gaat naar Fly.io cloud runners of lokale gRPC runners. Dit is een uitstekende designbeslissing.

2. **Security-first foundation** ✅ - Owner-scoped RLS op storage (`<auth.uid>/<projectId>/<taskId>/...`). Signed URL TTLs correct (~5 min). Multi-layer permission gating (permission + premium + entitlement).

3. **Offline-first implementatie** ✅ - Hive cache met encrypted box. Fallback strategieën goed. Cache invalidatie op auth/premium changes. Outbox replay met retry/circuit breaker.

4. **Idempotency & audit trail** ✅ - `mirror_request_idempotency` tabel met status tracking. Stale-claim recovery (300s threshold). `mirror_apply_audit_events` voor compliance.

5. **Apply safety rails** ✅ - Preview→apply fingerprint matching. Signed input + backup artifacts. UI risk confirmation. Diff preview in apply dialog.

6. **Realtime dedup** ✅ - `MirrorRealtimeEventSetDeduplicator` voorkomt broadcast duplicaten. FIFO-bounded set, configurable dedup.

7. **Integration pragmatic** ✅ - Deep links via `openMirrorFromTask`. Entry points in ProjectDetailsWidget/TaskCard. Consistent navigation flow.

8. **Feature flags & AB testing** ✅ - `mirror_enabled`, `mirror_private_mode_enabled`, `mirror_cloud_mode_enabled`, admin bypass. Team mode + runner mode variants via AB testing.

9. **Comprehensive test suite** ✅ - RLS contracts, security flow tests, realtime dedup tests, permission guards.

10. **Threat model documentation** ✅ - Uitstekende threat scenario's met mitigatie controls.

### Zwakke punten

1. **Over-engineered service laag** 🟡 - Te veel enkelvoudige verantwoordelijkheden:
   - `MirrorEditorOrchestrationService` 
   - `MirrorSecureApplyService`
   - `MirrorDiffService`
   - `MirrorRetryPolicy`
   - `MirrorObservabilityService`
   
   Dit voegt laagjes toe zonder grote waarde.

2. **Complexe Provider logic** 🟡 - `mirror_provider.dart` combineert feature flags, premium, AB-varianten, cache hydration, backend selectie. Veel dulpunten en dependencies moeilijk na te volgen.

3. **gRPC private mode underbaked** 🔴 - `PrivateGrpcBackend`:
   - gRPC channel creatie per call (resource leak op lange sessions)
   - TLS credentials weak in staging
   - Geen connection pooling
   - Geen deployment/startup guide
   - Beperkte tests voor happy path

4. **Incomplete production checklist** 🔴 - `docs/mirror-production-readiness-checklist.md` bevat veel `[ ]`:
   - Architecture ownership ADR ontbreekt
   - Database rollback procedures niet bewezen
   - Performance SLO baselines niet captured
   - Load test reports ontbreken

5. **Limited observability** 🟡 - `MirrorObservabilityService`:
   - Geen sampling/privacy controls
   - Geen circuit breaker metrics
   - Geen correlation ID propagation checks
   - Usage metering (`mirror_usage_logs`) write-path onduidelijk

6. **Offline cache edge cases** 🟡 - Premium invalidation weak.  Corruption detection ontbreekt. No warm-up. Race conditions op premium changes.

7. **Storage path validation** 🔴 - `_sanitizeStoragePath()` implementatie niet zichtbaar. Risk: directory traversal attacks?

8. **gRPC channel lifecycle** 🔴 - Channels created per call, never closed → FD exhaustion op lange sessions.

9. **Compile fingerprint not persisted** 🔴 - Result bevat fingerprint, maar waar wordt deze opgeslagen voor apply validation?

10. **Error handling gaps** 🟡 - Error messages basic. Retry feedback ontbreekt. Permission revoke kills hele screen.

### Overall Score

**7.8/10**

**Reasoning:** 
- Architectuur + security fundamenteel **sterk**
- Execution heeft **gaps** in gRPC, profiling, observability
- Incomplete production checklist, test coverage
- Met fixes kan dit naar **8.5-9.0** gaan

---

## 2. Laag-voor-laag analyse

### 2.1 Supabase / Database laag ✅

#### Schema Design

**`ai_sessions`** table (20260310_create_ai_sessions_baseline.sql):
- PK: `id UUID`
- FK: `user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE` ✅
- Columns: `project_id`, `task_id`, `prompt`, `mode` (CHECK private|cloud), `status` (CHECK pending|running|completed|failed)
- `versions JSONB` - stores generated codes
- Indexes: `(user_id, project_id, task_id)`, `(updated_at DESC)` ✅
- Trigger: `trg_ai_sessions_set_updated_at` ✅

**`mirror_request_idempotency`** (via gateway code):
- PK: `idempotency_key + user_id`
- Fields: `request_hash`, `request_id`, `status`, `response_body`, `expires_at`
- Terminal finalize guard: `request_id + request_hash + status='processing'` ✅

**`mirror_apply_audit_events`**:
- Tracks apply operations for audit + compliance ✅

#### RLS Implementation ✅

Storage buckets (`mirror-signed-inputs`, `mirror-backups`):
```sql
TO authenticated
USING (bucket_id = 'mirror-signed-inputs' AND storage.foldername(name)[1] = auth.uid()::text)
```

**Issue found:** Geen expliciete SELECT/INSERT/UPDATE/DELETE policies op `ai_sessions` tabel! RLS enforced via token implicitly, but best practice → define explicit policies.

#### Recommendations

1. ✅ **Add explicit ai_sessions RLS policies**
2. ✅ **Storage cleanup robustness** - pg_cron conditional kan silent fail
3. ✅ **idempotency table documentation** - schema contract comments

---

### 2.2 Edge Functions & gRPC backend laag 🟡

#### Mirror Gateway (mirror-gateway/index.ts)

**Strengths:**
- Bearer auth enforcement ✅
- Idempotency ledger met status tracking ✅
- Stale recovery: >300s lingering `processing` claims detected
- Structured errors met `error_family` enum ✅
- Request correlation: `x-request-id`, `x-trace-id` ✅

**Gaps:**
- 🔴 **Idempotency finalize guard vague** - SQL guard niet getoond. Must be:
  ```sql
  UPDATE mirror_request_idempotency 
  SET status = 'completed', response_body = $1
  WHERE idempotency_key = $2 AND user_id = $3 
    AND request_id = $4 AND request_hash = $5 AND status = 'processing'
  ```

- 🟡 **Payload size guard missing** - Geen pre-check header validation
- 🟡 **No audit logging** - Requests moeten naar `mirror_apply_audit_events`
- 🟡 **hasCloudMirrorAccess() robustness** - Geen fallback als RPC timeout'ed

#### MirrorGatewayBackend

**Strengths:**
- Endpoint abstraction ✅
- useSecureApply enforceert fingerprint ✅
- Context budget service ✅
- Retry policy configurable ✅

**Gaps:**
- 🟡 **Endpoint resolution weak** - `_resolveCompileEndpoint()` niet shown
- 🔴 **Compile fingerprint not persisted** - Result heeft artifact path, maar waar opslaan?
- 🟡 **No request/trace ID generation** - Gateway expects downstream population

#### PrivateGrpcBackend 🔴

**Strengths:**
- TLS enforcement in production ✅

**Critical Gaps:**
- 🔴 **Channel leakage** - new channel per call, never shutdown:
  ```dart
  final channel = ClientChannel(host, port: port, options: ChannelOptions(credentials: credentials));
  final client = MirrorComputeServiceClient(channel);
  // NO: await channel.shutdown()
  ```
  **Impact:** FD exhaustion on long sessions.

- 🔴 **No deployment guide** - Local runner (port 50051) startup procedure undocumented
- 🟡 **Credentials hardcoded insecure** - Default `ChannelCredentials.insecure()` in staging/prod
- 🟡 **No connection pooling** - Each request = new gRPC connection

---

### 2.3 Dart/Flutter core & providers laag 🟡

#### mirror_provider.dart

**Strengths:**
- Clean state immutability via `copyWith()` ✅
- Access policy centralized ✅
- Fallback logic explicit ✅
- Offline mode hydration ✅

**Weaknesses:**
- 🟡 **Too many watched subscriptions** - Watching 7+ providers in `build()`:
  ```dart
  final mode = ref.watch(mirrorModeProvider);
  final isPremium = ref.watch(mirrorPremiumProvider).valueOrNull ?? false;
  final teamModeVariant = ref.watch(mirrorTeamModeVariantProvider).valueOrNull ?? 'solo';
  final runnerModeVariant = ref.watch(mirrorRunnerModeVariantProvider).valueOrNull ?? 'cloud';
  ```
  Any upstream change rebuilds entire mirror state. **Fix:** Use `select()` for targeted subscriptions.

- 🟡 **Premium refresh race condition** - Invalidate + read without guard
- 🔴 **No error boundary** - Can throw if policy denies both modes

#### mirror_entitlement_provider.dart

**Issue:** No refresh trigger on Stripe entitlement change. Must listen on `stripeCustomerProvider`.

#### mirror_feature_flag_provider.dart ✅

Good safety practices. Graceful fallback if offline.

#### mirror_offline_cache_provider.dart 🟡

**Issues:**
- 🟡 **Premium snapshot invalidation weak** - Doesn't force cloud mode off immediately on premium loss
- 🟡 **No rollback on bad data** - If Hive corrupted, entire mode falls back

#### Recommendations

1. ✅ Use `select()` for targeted subscriptions
2. ✅ Guard on rapid premium refresh  
3. ✅ Listen for Stripe entitlement changes
4. ✅ Explicit premium invalidation flag
5. ✅ Hive corruption detection

---

### 2.4 UI & UX laag 🔴

#### MirrorEditorScreen

**Strengths:**
- Permission guard with monitoring ✅
- Terminal setup with scroll control ✅
- Deep lifecycle management ✅
- Mode selector abstracted ✅

**Gaps:**
- 🔴 **Permission revoke kills screen** - Shows blank state. Better: disable run button, keep editor
- 🟡 **Error handling basic** - Hardcoded strings, no structured codes
- 🟡 **No compile/apply progress** - Only "starting", "running"
- 🟡 **Offline indicator missing** - Realtime down but user won't know
- 🔴 **Voice input not validated** - Sanitization missing
- 🟡 **Live output scroll stuck** - Terminal might not keep pace

#### apply_dialog.dart

Assume workflow: show diff → confirm → prepare artifacts → apply → update session

**Gaps:**
- 🟡 Can't see implementation. Unknown: error recovery, partial-file rollback, progress
- 🟡 No progress bar for large uploads

#### monaco_editor_host.dart

**Gaps:**
- 🔴 **No collaborative editing** - Team mode but no conflict resolution
- 🟡 **Editor state sync** - If broadcast arrives while typing, content shifts?

#### MirrorEditorRealtimeController

**Gaps:**
- 🟡 **Dedup maxSize hardcoded** - If > capacity, oldest drops. Make configurable
- 🟡 **No realtime auth validation** - Any user on project sees updates?
- 🟡 **Payload guard weak** - XSS vectors in `logs` field?

---

### 2.5 Security, permissions & premium checks 🟡

#### Permission Gating ✅

`hasPermissionProvider(AppPermissions.useMirror)` enforced at screen. Good.

#### Premium Gating

**Issues:**
- 🔴 **Premium non-authoritative** - Client-side hint only. If stale, user gets 403 later. Gateway RPC validates, but UX bad.
  **Fix:** Periodic refresh (weekly or critical path)

- 🟡 **No quota enforcement** - Even premium users can spam compiles. Add rate-limit (10/min).

#### Admin Bypass

**Issues:**
- 🟡 **Not logged** - No audit trail when admin uses bypass
- 🔴 **No expiry** - Admin bypass stays forever? Should have session TTL

---

### 2.6 Offline / Hive / caching laag

#### MirrorOfflineCache

**Strengths:**
- Encrypted via `EncryptedHiveBox` ✅
- Schema version + rollback ✅
- Per-user isolation ✅

**Gaps:**
- 🔴 **No corruption detection** - If Hive corrupted, silently fallback
- 🟡 **Premium invalidation weak** - See 2.3
- 🟡 **No warm-up** - Cold start = all cache misses

#### MirrorTemplatesCache

**Gaps:**
- 🟡 **Unknown eviction policy** - How large? LRU? TTL?

---

### 2.7 Integrasi dengan bestaande app

#### Deep links

`openMirrorFromTask()` routes to MirrorEditorScreen.

**Gaps:**
- 🟡 **No 404 handling** - If projectId/taskId stale/deleted?
- 🟡 **No back navigation** - User can't easily navigate back after session

#### Legacy tasks cleanup

Mentioned but not found. What tasks are "legacy"?

#### App integration UX

**Gaps:**
- 🟡 **No Mirror editing indicator** - Task shows in-progress but can't distinguish Mirror vs manual
- 🟡 **No session picker** - If 3 Mirror sessions for same task, how to switch?

---

## 3. Concrete aanbevelingen

### 3.1 Critical fixes (Sprint 1)

#### A. Gateway idempotency finalize guard

**File:** `supabase/functions/mirror-gateway/index.ts`

Add explicit finalize SQL guard:
```typescript
// After runner success response:
const finalizeResult = await supabase.rpc('finalize_idempotency_key', {
  p_idempotency_key: idempotencyKey,
  p_user_id: userId,
  p_request_id: requestId,
  p_request_hash: requestHash,
  p_response_status: 200,
  p_response_body: JSON.stringify(runnerResponse),
});

if (!finalizeResult.data?.success) {
  return errorResponse(req, buildStructuredError({
    code: 'idempotency_update_conflict',
    message: 'Finalize guard failed: ownership or status mismatch',
    retryable: false,
    stage: 'gateway-finalize',
  }), 409);
}
```

#### B. gRPC channel lifecycle

**File:** `lib/features/mirror/private_grpc_backend.dart`

```dart
@override
Future<CompileResult> compile({...}) async {
  final channel = ClientChannel(host, port: port, options: ChannelOptions(credentials: credentials));
  try {
    final client = MirrorComputeServiceClient(channel);
    final response = await client.compile(...);
    return CompileResult(...);
  } finally {
    await channel.shutdown(); // ADD THIS
  }
}
```

#### C. Compile fingerprint persistence

**File:** `lib/features/mirror/mirror_gateway_backend.dart`

```dart
final result = await _postCompile(...);
if (result.success && result.serverVersionToken != null) {
  ref.read(mirrorSessionProvider(_sessionKey).notifier)
    .addVersion(GeneratedVersion(
      fingerprint: result.serverVersionToken!,
      timestamp: DateTime.now(),
      prompt: prompt,
    ));
}
```

---

### 3.2 Important improvements (Sprint 2-3)

#### A. Payload size guard

**File:** `supabase/functions/mirror-gateway/index.ts`

```typescript
const contentLength = req.headers.get('content-length');
if (contentLength && parseInt(contentLength) > 5 * 1024 * 1024) {
  return errorResponse(req, buildStructuredError({
    code: 'payload_too_large',
    message: 'Request payload exceeds 5 MB limit',
    retryable: false,
    stage: 'gateway-intake',
  }), 413);
}
```

#### B. Provider subscription optimization

**File:** `lib/core/providers/mirror_provider.dart`

```dart
final isPremium = ref.watch(
  mirrorPremiumProvider.select((async) => async.valueOrNull ?? false),
);
```

#### C. Voice input sanitization

**File:** `lib/features/mirror/mirror_editor_screen.dart`

```dart
void _handleVoiceInput(String transcript) {
  final sanitized = _sanitizePrompt(transcript);
  _sessionNotifier.updatePrompt(sanitized);
}

String _sanitizePrompt(String input) {
  return input
    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
    .trim()
    .substring(0, min(10000, input.length));
}
```

#### D. Rate limiting

**File:** `lib/features/mirror/services/mirror_rate_limiter.dart` (new)

```dart
class MirrorRateLimiter {
  static const int maxCompilePerMinute = 10;
  
  Future<bool> canCompile(String userId) async {
    // Check recent attempts, block if >= maxCompilePerMinute
  }
}
```

---

### 3.3 New documentation files

#### A. Local runner deployment

**File:** `docs/mirror-local-runner-deployment.md`

```markdown
# Mirror Local Runner Deployment

## Docker Compose Setup
...
## Port Configuration (default 50051)
...
## TLS Certificate Setup
...
```

#### B. Backend contracts

**File:** `docs/mirror-backend-contracts.md`

```markdown
# Mirror Backend Contracts

| Component | Type | Request | Response |
|---|---|---|---|
| MirrorGatewayBackend | HTTP | CompileRequest | CompileResponse |
| PrivateGrpcBackend | gRPC | mirror.v1.CompileRequest | mirror.v1.CompileResponse |
```

#### C. Security hardening

**File:** `docs/mirror-security-baseline.md`

```markdown
# Mirror Security Hardening Checklist

- [ ] Runner runs as non-root user
- [ ] seccomp/apparmor profiles enabled
- [ ] Readonly rootfs where possible
- [ ] Egress allowlist (no internet access)
- [ ] CPU/memory quotas enforced
- [ ] Key rotation: monthly or on compromise
```

---

### 3.4 New tests

#### A. gRPC channel shutdown test

**File:** `test/features/mirror/mirror_private_grpc_channel_lifecycle_test.dart`

```dart
test('channel is shut down after compile', () async {
  final backend = PrivateGrpcBackend();
  final result = await backend.compile(...);
  // Verify FD not leaked (via process FD count)
});
```

#### B. Idempotency finalize test

**File:** `test/supabase/mirror_idempotency_finalize_test.sql`

```sql
-- Test that finalize fails on ownership mismatch
SELECT * FROM finalize_idempotency_key(
  'test-key', 'user-1', 'req-1', 'hash-bad', 200, '{}', 'application/json'
);
-- Should return success=FALSE, conflict_reason='ownership_or_status_mismatch'
```

---

### 3.5 Code consolidations (Nice-to-have)

1. **Remove redundant entitlement wiring** - `mirror_entitlement_provider.dart` duplicates logic from `mirror_provider.dart`
2. **Consolidate observability** - Remove `MirrorObservabilityService` wrapper, call `AppLogger.event()` directly
3. **Unify retry logic** - One `RetryStrategy` instead of scattered retry handling

---

## 4. Production Readiness Matrix

| Layer | Component | Status | Blocker | Effort |
|---|---|---|---|---|
| Database | RLS policies explicit | 🟡 | Medium | Low |
| Database | pg_cron fallback | 🔴 | High | Low |
| Gateway | Payload size guard | 🟡 | Medium | Low |
| Gateway | Idempotency finalize | 🔴 | High | High |
| Gateway | Audit logging | 🔴 | High | Low |
| Backend | Compile fingerprint persist | 🔴 | High | Medium |
| Backend | gRPC channel shutdown | 🔴 | High | Low |
| Backend | Local runner docs | 🟡 | Medium | Low |
| Providers | Subscription optimization | 🟡 | Low | Low |
| Providers | Premium refresh guard | 🟡 | Medium | Low |
| UI | Permission revoke handling | 🟡 | Medium | Low |
| UI | Voice input sanitization | 🟡 | Medium | Low |
| UI | Error code mapping | 🟡 | Low | Medium |
| Offline | Corruption detection | 🟡 | Low | Low |
| Tests | gRPC lifecycle | 🔴 | High | Medium |
| Tests | idempotency finalize | 🔴 | High | Medium |
| Docs | Backend contracts | 🔴 | High | Low |
| Docs | Security hardening | 🔴 | High | Low |

---

## Summary

**Current Score: 7.8/10**

**Key Strengths:**
- ✅ Thin proxy gateway pattern
- ✅ RLS + security multi-layer
- ✅ Offline-first with Hive
- ✅ Idempotency implementation
- ✅ Apply safety rails

**Critical Gaps:**
- 🔴 gRPC channel leakage
- 🔴 Idempotency finalize guard unclear
- 🔴 Compile fingerprint not persisted
- 🔴 Local runner undocumented

**After Phase 1 (Critical): 8.5/10**  
**After Phase 2 (Important): 9.0/10**  
**After Phase 3 (Nice-to-have): 9.2/10**

**Recommendation:** Treat Critical fixes as release blockers. Important in next 2 sprints. This feature is production-grade with these fixes.
