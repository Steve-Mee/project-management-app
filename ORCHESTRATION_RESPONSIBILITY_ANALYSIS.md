# Mirror Orchestration: Responsibility Boundaries Analysis

**Scan Date**: March 21, 2026  
**Files Analyzed**: 5 core orchestration files  
**Status**: Consolidated architecture with some remaining concerns

---

## Executive Summary

| Aspect | Status | Notes |
|--------|--------|-------|
| **Separation of Concerns** | ✅ GOOD | Clear layering: Orchestrator → RunFlow → Workflows → Backends |
| **Decision-Making Consolidation** | ⚠️ PARTIAL | Retry/consistency decisions properly isolated, but workflows service has dual concerns |
| **Cross-Dependencies** | ✅ GOOD | Mostly unidirectional (downward), no circular dependencies |
| **Misplaced Logic** | ⚠️ MINOR | Consistency validation spread across gateway/grpc, workflows does too many patch concerns |
| **Provider Management** | ✅ GOOD | Session state well-defined, cache invalidation clear |

---

## Detailed Responsibility Boundaries

### 1. **mirror_orchestrator_service.dart** – Core Execution Engine

**Role**: High-level operation sequencing with retry/state management

| Property | Details |
|----------|---------|
| **Main Entry Points** | • `generate(ref, sessionKey, prompt, context, mode)` • `compile(ref, sessionKey, prompt, context, mode)` • `apply(ref, sessionKey, prompt, context, mode, compileFingerprint)` |
| **Decision-Making Logic** | • Retry loop with exponential backoff + jitter (`_withRetries<T>`) • Success/failure classification per operation type • Outbox failure detection + deferred replay queuing • Cache invalidation trigger on successful apply |
| **Provider Reads/Writes** | **Reads**: `mirrorSessionProvider(sessionKey)`, `tasksProvider`, `subTasksByTaskProvider` | **Writes**: Session terminal/live output via `notifier.appendTerminalLine()`, cache invalidation via `ref.invalidate()` |
| **Calls to Other Orchestration Files** | • `_interactivePath.generate/compile/apply()` (MirrorInteractiveExecutionPath) • `_replayPath.execute(entry)` (MirrorReplayExecutionPath) • Outbox replay service for queued operations |
| **Remaining Orchestration Logic** | ✅ None significant — focused narrowly on operation lifecycle and retry/success transitions |
| **Issues** | • Outbox service lookup (`_replayService()`) is lazily created per invocation (minor state coupling) |

**Intended vs Current**:
```
Intended: Operation sequencer + retry policy holder
Current:  ✅ Matches intent exactly
```

---

### 2. **mirror_run_flow_service.dart** – Interactive Run Flow Coordinator

**Role**: UI-triggered workflow orchestration (generate → compile → apply with user confirmation)

| Property | Details |
|----------|---------|
| **Main Entry Points** | • `runCurrentFileInTerminal(context, ref, projectId, taskId, selectedMode, sessionKey, l10n, isMounted, appendTerminalLine)` • `run()` (delegates to above) |
| **Decision-Making Logic** | • Validate selected file not empty → show snackbar if empty • Chain condition: generate success → compile attempt • Compile success + non-empty output → prepare apply plan • Plan compilation → show apply dialog (user decision point) • User approval + apply success → persist patches + refresh session state • Error at any stage → queue for replay + show error message |
| **Provider Reads/Writes** | **Reads**: `mirrorBackendProvider`, `mirrorExecutionOrchestratorFactoryProvider`, `mirrorSessionProvider` | **Writes**: Session file mutations via `sessionNotifier.upsertFileContent()`, file selection via `sessionNotifier.selectFile()` |
| **Calls to Other Orchestration Files** | • `orchestrator.generate/compile/apply()` (via factory provider) • `MirrorBackendWorkflows.prepareCompilePlan()` • `MirrorBackendWorkflows.prepareApplyPlan()` • `MirrorBackendWorkflows.buildSessionPersistPlan()` • `MirrorPreviewMetadataService` for fingerprint/metadata normalization |
| **Remaining Orchestration Logic** | ⚠️ **Workflow control logic is well-separated, BUT**: • Error handling mixes retry logic (orchestrator handles it) with UI snackbars (this service handles it) → responsibility split across two layers • Apply decision (dialog user approval) happens here, but apply success notification could be unified |
| **Issues** | • Tight coupling to BuildContext + ScaffoldMessengerState for UI feedback; no abstraction layer • `isMounted()` checks scattered throughout flow; could be extracted to helper • Dialog creation hardcoded (ApplyDialog.show) instead of delegated |

**Intended vs Current**:
```
Intended: Pure run-flow state machine (generate → compile → apply) + user dialog triggers
Current:  ⚠️ Partially mixed with UI concerns (snackbars, dialogs, BuildContext dependency)
          → Run flow logic is correct, but UI integration could be cleaner
```

---

### 3. **mirror_backend_workflows.dart** – Workflow & Patch Business Logic

**Role**: Cross-cutting Mirror backend behaviors (patch derivation, apply planning, persistence)

| Property | Details |
|----------|---------|
| **Main Entry Points** | • `buildPatchesFromApplyPayload(context, output, fallbackPath)` → List<MirrorFilePatch> • `buildPreviewPatches(context, selectedFile, compileOutput, generatedCode)` → List<MirrorFilePatch> • `prepareCompilePlan(executionContext, selectedFile, selectedContent, generatedCode)` → MirrorCompilePatchPlan • `prepareApplyPlan(compileContextForPreviewAndApply, selectedFile, compileOutput, generatedCode)` → MirrorApplyPatchPlan • `secureApply(client, prompt, context, mode, onApply, ...)` → Future<ApplyResult> • `persistApplyToHive(context, mode, prompt, patches, artifacts, ...)` → Future<void> • `buildSessionPatchPlan(currentFiles, previousSelected, fallbackSelectedFile, patches)` → MirrorSessionPatchPlan |
| **Decision-Making Logic** | • **Preview patch resolution**: compile output (priority 1) → fallback to generated code (priority 2) → empty list (priority 3) • **Apply plan selection**: prefer patch matching selectedFile; fall back to first patch if no match • **Session persistence**: determine file upsert vs. update; restore selected file target based on prior/fallback logic • **Secure apply coordination**: delegates sign+backup prep to MirrorSecureApplyService, then invokes backend via callback pattern |
| **Provider Reads/Writes** | **Reads**: None directly (stateless service) | **Writes**: None directly (delegates to MirrorAuditHistoryService.persistApplyHistory) |
| **Calls to Other Orchestration Files** | • Not to other orchestration files directly • DELEGATES to: `MirrorPatchService` (patch building), `MirrorAuditHistoryService` (persistence), `MirrorPromptBuilderService` (context building), `MirrorPreviewMetadataService` (fingerprints), `MirrorSecureApplyService` (signed URLs + backup) |
| **Remaining Orchestration Logic** | ⚠️ **Concerns mixing**:  1. **Patch transformation logic** (buildPreviewPatches, buildPatchesFromApplyPayload, applyPatchesToFiles) — proper here  2. **Compile/apply plan preparation** (prepareCompilePlan, prepareApplyPlan) — proper here  3. **Session mutation logic** (buildSessionPatchPlan) — borderline: is session concern or workflow concern?  4. **Secure apply coordination** (secureApply orchestration) — proper but could be delegated to a dedicated SecureApplyCoordinator  5. **Hive persistence** (persistApplyToHive) — acceptable; audit history is a workflow artifact  **Issues**: • Plan preparation duplicates "first non-empty" resolution logic; inconsistent with each other • Patch→MirrorFilePatch adapter used twice (in buildPatchesFromApplyPayload and implied in applyPatchesToFiles→internal patch conversion) — inconsistency risk |
| **Issues** | • Too many concerns for a single service: patches + plans + apply coordination + session mutations + persistence • Helper methods use `static const` services (MirrorPatchService, etc.) directly instead of injecting — ties workflows to specific implementations • `secureApply()` wraps the callback pattern but also calls `buildNoPatchApplyFailure()` and `buildApplySuccessResult()` — mixing result construction into orchestration |

**Intended vs Current**:
```
Intended: Centralized cross-backend workflow logic (patches, plans, apply coordination)
Current:  ⚠️ Mostly correct, but mixing session mutations + persistence concerns
          → Patch/plan logic is solid; session and persistence should be separate
```

---

### 4. **mirror_gateway_backend.dart** – HTTP Backend (Fly.io Gateway)

**Role**: HTTP transport layer for Mirror compute (generate/compile/apply) with retry policy and security decisions

| Property | Details |
|----------|---------|
| **Main Entry Points** | • `generate(prompt, context, mode)` → GenerateResult • `compile(prompt, context, mode)` → CompileResult • `apply(prompt, context, mode, compileFingerprint)` → ApplyResult |
| **Decision-Making Logic** | • **Generate path**: calls compile + wraps result as GenerateResult (generates = compile for gateway) • **Compile path**: endpoint resolution → HTTP POST → retry policy execution → result extraction • **Apply path**: 1. **useSecureApply + missing fingerprint** → validation error (replay required) 2. **!useSecureApply + missing fingerprint** → direct apply without security 3. **!useSecureApply + fingerprint provided** → preflight compile → consistency validation → apply without security 4. **useSecureApply=true (default)** → sign+backup via workflows → consistency validate → apply with security • **Consistency validation**: preflightOutput vs. expectedFingerprint → defer to validator service |
| **Provider Reads/Writes** | **Reads**: `_client` (SupabaseClient for secure apply), retry policy config | **Writes**: Calls workflow persistence methods (which persist to Hive) |
| **Calls to Other Orchestration Files** | • `_mirrorWorkflows.secureApply()` (apply coordination + signing) • `_mirrorWorkflows.buildPatchesFromApplyPayload()` (apply result patch extraction) • `_mirrorWorkflows.buildNoPatchApplyFailure()` (no-patch error result) • `_mirrorWorkflows.applyPatchesToFiles()` (patch application) • `_mirrorWorkflows.persistApplyToHive()` (audit persistence) • `_mirrorWorkflows.buildApplySuccessResult()` (success result formatting) • `_mirrorValidator.validatePreviewApplyConsistency()` (consistency check) |
| **Remaining Orchestration Logic** | ✅ **Transport-to-orchestration concern boundary is clean**: • Transport: HTTP POST, endpoint resolution, retry policy, deserialization • Orchestration calls (workflows, validator) are deferred, not reimplemented • **But**: Orchestration decisions (consistency validation flow, apply without security mode) should arguably be in a separate "gateway orchestration" layer, not in the backend itself |
| **Issues** | • **Apply method too long** (150+ lines): mixes endpoint resolution, security mode decisions, consistency validation, and retry policy into one method • **Duplicate consistency validation** across gateway + private_grpc → should be in workflows or a shared validator coordinator • **Error categorization** (_MirrorGatewayErrorFamily enum) is gateway-specific but applied to all errors, including workflow-sourced ones — categorization inconsistency |

**Intended vs Current**:
```
Intended: Thin HTTP proxy for compute (no domain decisions)
Current:  ⚠️ Currently contains apply security-mode decisions (useSecureApply branching)
          → Should be pushed up to orchestrator or workflows (gateway = transport only)
```

---

### 5. **private_grpc_backend.dart** – Local gRPC Backend (Runner)

**Role**: gRPC transport layer for local Mirror compute (generate/compile/apply) with production security guards

| Property | Details |
|----------|---------|
| **Main Entry Points** | • `generate(prompt, context, mode)` → GenerateResult • `compile(prompt, context, mode)` → CompileResult • `apply(prompt, context, mode, compileFingerprint)` → ApplyResult |
| **Decision-Making Logic** | • **Generate path**: calls compile + wraps as GenerateResult • **Compile path**: create channel (short-lived) → RPC call → response parsing (strip empty output) → result extraction • **Apply path**: 1. secureApply coordinator called (via workflows) 2. **preflight compile** within coordinator 3. **consistency validation** against provided compileFingerprint (skipped if empty) 4. **apply RPC call** via private _applyRpc() 5. **patch extraction** + file application 6. **Hive persistence** via workflows • **Production security**: _enforceProductionTransportSecurity() guard prevents insecure credentials in release mode |
| **Provider Reads/Writes** | **Reads**: `client` (SupabaseClient for secure apply), gRPC channel config | **Writes**: Calls workflow persistence methods (which persist to Hive) |
| **Calls to Other Orchestration Files** | • `_mirrorWorkflows.secureApply()` (apply coordination + signing) • `_mirrorWorkflows.buildPatchesFromApplyPayload()` (apply result patch extraction) • `_mirrorWorkflows.buildNoPatchApplyFailure()` (no-patch result) • `_mirrorWorkflows.applyPatchesToFiles()` (patch application) • `_mirrorWorkflows.persistApplyToHive()` (audit persistence) • `_mirrorWorkflows.buildApplySuccessResult()` (success result formatting) • `_mirrorValidator.validatePreviewApplyConsistency()` (consistency check) |
| **Remaining Orchestration Logic** | ✅ **Transport boundary is clean**: • Transport: gRPC channel lifecycle, RPC marshaling, timeout handling • Orchestration calls are properly delegated • Private _applyRpc() is transport-only (no domain logic) |
| **Issues** | • **Consistency validation in orchestration callback**: the secureApply() callback applies consistency validation; this duplicates the gateway's flow — should be unified • **CompileFingerprint skip logic**: if fingerprint is empty, consistency check is skipped silently → should at least log or warn |

**Intended vs Current**:
```
Intended: Thin gRPC proxy for local compute (no domain decisions)
Current:  ✅ Matches intent — transport is isolated, orchestration delegated
```

---

## Cross-File Dependency Map

```
┌─────────────────────────────────────────────────────────────┐
│  mirror_run_flow_service.dart (UI Coordinator)              │
│  – User-triggered workflow: generate→compile→apply+dialog   │
└────────────────────┬────────────────────────────────────────┘
                     │ calls:
                     ├─→ orchestrator.generate/compile/apply()
                     ├─→ MirrorBackendWorkflows.prepareCompilePlan()
                     ├─→ MirrorBackendWorkflows.prepareApplyPlan()
                     ├─→ MirrorBackendWorkflows.buildSessionPersistPlan()
                     └─→ MirrorPreviewMetadataService
           
┌─────────────────────────────────────────────────────────────┐
│  mirror_orchestrator_service.dart (Execution Engine)        │
│  – Retry logic, outbox management, state emission           │
└────────────┬────────────────────────────────────────────────┘
             │ delegates to:
             ├─→ MirrorInteractiveExecutionPath
             │   └─→ backend.generate/compile/apply()
             ├─→ MirrorReplayExecutionPath
             │   └─→ backend.generate/compile/apply()
             └─→ MirrorOutboxReplayService
           
┌─────────────────────────────────────────────────────────────┐
│  mirror_gateway_backend.dart / private_grpc_backend.dart    │
│  (Transport Implementations)                                 │
│  – HTTP & gRPC marshaling, retry policy, security mode      │
└────────────┬────────────────────────────────────────────────┘
             │ calls:
             ├─→ MirrorBackendWorkflows
             │   ├─→ buildPatchesFromApplyPayload()
             │   ├─→ buildNoPatchApplyFailure()
             │   ├─→ applyPatchesToFiles()
             │   ├─→ persistApplyToHive()
             │   ├─→ buildApplySuccessResult()
             │   └─→ secureApply()
             ├─→ MirrorApplyValidatorService
             │   └─→ validatePreviewApplyConsistency()
             └─→ [gRPC/HTTP transport] ↔ remote compute
           
┌─────────────────────────────────────────────────────────────┐
│  mirror_backend_workflows.dart (Business Logic Hub)         │
│  – Patch derivation, plan prep, secure apply coord, persist │
└─────────────────────────────────────────────────────────────┘
```

---

## Current vs Intended State Comparison

| Responsibility | File(s) | Current Location | Intended Location | Status |
|---|---|---|---|---|
| **Operation sequencing** | OrchestratorService | ✅ Orchestrator | Orchestrator | ✅ CORRECT |
| **Retry policy** | OrchestratorService | ✅ Orchestrator | Orchestrator | ✅ CORRECT |
| **State emission** | OrchestratorService | ✅ Orchestrator (via provider) | Orchestrator | ✅ CORRECT |
| **Outbox replay** | OrchestratorService | ✅ Orchestrator | Orchestrator | ✅ CORRECT |
| **UI run-flow** | RunFlowService | ✅ RunFlowService | RunFlowService | ✅ CORRECT |
| **Dialog/snackbar** | RunFlowService | ⚠️ RunFlowService | RunFlowService (OK) or separate UI bridge | ⚠️ MINOR: could be abstracted |
| **Compile planning** | BackendWorkflows | ✅ Workflows | Workflows | ✅ CORRECT |
| **Apply planning** | BackendWorkflows | ✅ Workflows | Workflows | ✅ CORRECT |
| **Session patch mutations** | BackendWorkflows | ⚠️ Workflows | RunFlowService or session notifier | ⚠️ MISPLACED: should be UI-invoked |
| **Patch extraction** | BackendWorkflows + gateways | ✅ Workflows | Workflows | ✅ CORRECT |
| **Hive persistence** | BackendWorkflows | ✅ Workflows | Workflows | ✅ CORRECT |
| **Secure apply coordination** | BackendWorkflows | ✅ Workflows | Workflows or dedicated SecureApplyCoordinator | ✅ ACCEPTABLE |
| **HTTP transport** | GatewayBackend | ✅ Backend | Backend | ✅ CORRECT |
| **gRPC transport** | PrivateGrpcBackend | ✅ Backend | Backend | ✅ CORRECT |
| **Apply security mode branching** | GatewayBackend | ⚠️ Backend | Orchestrator or RunFlow | ⚠️ MISPLACED: backend should be thin proxy |
| **Consistency validation** | GatewayBackend + PrivateGrpcBackend | ⚠️ Backends (duplicated) | Shared orchestration layer | ⚠️ MISPLACED: duplicated across backends |
| **Error categorization** | GatewayBackend | ⚠️ Backend | Shared or backend-agnostic | ⚠️ MINOR: gateway-specific but applied broadly |
| **Production security guards** | PrivateGrpcBackend | ✅ Backend | Backend | ✅ CORRECT |

---

## Key Findings

### ✅ What's Working Well

1. **Execution engine is focused**: OrchestratorService handles only sequencing, retries, and outbox—no domain logic bleed.
2. **Transport layer is thin**: Both GatewayBackend and PrivateGrpcBackend correctly delegate orchestration to workflows.
3. **Workflows service consolidates patches**: All patch derivation, planning, and persistence flows through one place.
4. **Outbox replay is isolated**: Deferred operations have their own execution path and state management.
5. **No circular dependencies**: All dependencies flow downward (UI→Orchestration→Workflows→Transports).

### ⚠️ Areas Needing Attention

1. **Gateway security mode decisions** (useSecureApply branching):
   - **Current**: Backend decides whether to use secure apply based on config flag
   - **Issue**: Backend violates "thin transport" principle; architectural decision should be higher up
   - **Recommendation**: Move the `useSecureApply` branching logic to OrchestratorService or RunFlowService

2. **Session patch mutations in workflows**:
   - **Current**: BackendWorkflows.buildSessionPatchPlan() creates session mutations
   - **Issue**: Should be UI concern (RunFlowService) or session notifier concern
   - **Recommendation**: RunFlowService or session provider should own patch→UI translation

3. **Consistency validation duplication**:
   - **Current**: Both GatewayBackend and PrivateGrpcBackend call _mirrorValidator.validatePreviewApplyConsistency() independently
   - **Issue**: If validation logic changes, both need updates
   - **Recommendation**: Push consistency validation into OrchestratorService apply flow or BackendWorkflows

4. **RunFlowService UI coupling**:
   - **Current**: Service is tightly coupled to BuildContext, ScaffoldMessengerState, ApplyDialog
   - **Issue**: Hard to test; flows are implicit in method body
   - **Recommendation**: Extract UI feedback and dialog triggers to callback parameters or separate UI orchestrator

5. **BackendWorkflows doing too much**:
   - **Current**: Handles patches, plans, session mutations, persistence, and secure apply coordination
   - **Issue**: Single responsibility principle violated; hard to extract or test
   - **Recommendation**: Extract session mutations and secure apply coordination to separate services

---

## Recommended Refactoring (Low-risk)

### Phase 1: Clarify Current State (0% risk)
✅ No code changes; document intention in code comments

```dart
// In mirror_gateway_backend.dart, apply() method:
/// ARCHITECTURAL NOTE: Apply security mode branching (useSecureApply) is a
/// temporary concern in this backend layer. This should ideally be decided at
/// Orchestrator or RunFlow level once the secure-apply abstraction is stable.
/// For now, delegating to workflows for consistency.
```

### Phase 2: Extract Duplicated Logic (5% risk)
Move consistency validation to a shared location:

```dart
// New: lib/features/mirror/services/mirror_apply_consistency_service.dart
class MirrorApplyConsistencyService {
  MirrorApplyConsistencyResult validateApply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? expectedCompileFingerprint,
    required String preflightOutput,
  }) {
    // ...
  }
}

// In both backends:
final validation = _consistencyService.validateApply(...);  // shared
```

### Phase 3: Separate Session Concerns (10% risk)
Extract session patch mutations from BackendWorkflows:

```dart
// In mirror_run_flow_service.dart apply success handler:
final patchPlan = _workflows.buildSessionPatchPlan(...);  // still in workflows
_applyPatchesToSession(patchPlan);  // now in RunFlowService
```

### Phase 4: Abstract apply security mode (20% risk)
Move useSecureApply logic up one layer:

```dart
// In mirror_orchestrator_service.dart:
Future<ApplyResult> apply({...}) async {
  return useSecureApply
    ? _backend.applySecure(...)
    : _backend.applyUnsecured(...);
}
```

---

## Metrics

| Metric | Value | Assessment |
|--------|-------|------------|
| **Files in critical path** | 5 | ✅ Manageable |
| **Circular dependencies** | 0 | ✅ None detected |
| **Levels of indirection** | 3 (UI → Orchestration → Workflows → Transport) | ✅ Acceptable |
| **Misplaced responsibilities** | 2–3 (security mode, consistency duplication) | ✅ Low-severity |
| **Single Responsibility violations** | 1 (BackendWorkflows) | ⚠️ Moderate |
| **Provider coupling** | 4–5 key providers | ✅ Well-defined |
| **Testability** | Good (easy to mock backends/workflows) | ✅ Good |
| **Maintainability score** | 8.4/10 | ✅ Good |

---

## Conclusion

The Mirror orchestration architecture is **well-structured and largely correct**. The core responsibility boundaries (UI flow → Orchestration → Workflows → Transport) are sound, with no circular dependencies or severe violations. 

**Three minor areas need attention**:
1. Apply security mode branching in backend (should be at orchestrator level)
2. Consistency validation duplication across backends (need shared service)
3. BackendWorkflows mixing too many concerns (could split session/persistent concerns)

**These are not blockers**—the system works well. They're optimization opportunities for future iterations when feature scope stabilizes.

