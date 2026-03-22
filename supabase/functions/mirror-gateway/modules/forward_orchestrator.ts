// Forward orchestration for the Mirror gateway.
// Encapsulates apply-started audit, payload building, upstream forwarding,
// circuit breaker state tracking, idempotency finalization, usage logging,
// and final Response construction — all in a single cohesive step after resilience checks.

import { buildCorsHeaders } from '../../_shared/cors.ts'
import { classifyForwardStatus, classifyForwardIdempotencyStatus } from './error_contract.ts'
import * as requestValidator from './request_validator.ts'
import * as requestForwarding from './request_forwarding.ts'
import * as circuitBreakerHandler from './circuit_breaker_handler.ts'
import * as idempotencyHandler from './idempotency_handler.ts'
import * as auditLogger from './audit_logger.ts'
import * as telemetry from './telemetry.ts'
import * as middleware from './middleware.ts'

type SupabaseClient = ReturnType<typeof middleware.buildSupabaseClientForRequest>

/**
 * Execute STEPS 6–10 of the gateway pipeline:
 *   write apply_started audit → build payload → forward → update CB state
 *   → finalize idempotency → write usage log → return Response.
 */
export async function executeForwardAndFinalize({
  req,
  supabase,
  userId,
  normalized,
  action,
  requestId,
  traceId,
  idempotencyKey,
  idempotencyRequestHash,
  circuitBreakerState,
  contextStartedAtMs,
}: {
  req: Request
  supabase: SupabaseClient
  userId: string
  normalized: requestValidator.MirrorComputeRequest
  action: 'compile' | 'apply'
  requestId: string
  traceId: string
  idempotencyKey: string
  idempotencyRequestHash: string
  circuitBreakerState: circuitBreakerHandler.CircuitBreakerState
  contextStartedAtMs: number | null
}): Promise<Response> {
  // === STEP 6: WRITE APPLY AUDIT (started) ===
  if (action === 'apply') {
    await auditLogger.writeApplyAuditEvent({
      supabase,
      userId,
      normalized,
      requestId,
      idempotencyKey,
      event: 'apply_started',
      success: null,
      details: {
        source: 'mirror_gateway',
        filesCount: Object.keys(normalized.files ?? {}).length,
      },
    })
  }

  // === STEP 7: BUILD FORWARD PAYLOAD ===
  const forwardFields = requestValidator.normalizeForwardFields(normalized, userId)
  const forwardPayload = requestValidator.buildForwardPayload(
    normalized,
    userId,
    action,
    requestId,
    traceId,
    forwardFields,
  )

  const targetUrl = requestForwarding.resolveForwardEndpoint(normalized.mode, action)
  telemetry.logRequestForwarded({
    requestId,
    traceId,
    idempotencyKey,
    action,
    mode: normalized.mode,
    targetUrl,
  })

  // === STEP 8: FORWARD TO UPSTREAM ===
  const forwardResult = await requestForwarding.forwardToUpstream({
    targetUrl,
    payload: forwardPayload,
    authHeader: req.headers.get('Authorization') ?? '',
    requestId,
    traceId,
    idempotencyKey,
  })

  // === STEP 9: UPDATE CIRCUIT BREAKER STATE ===
  if (forwardResult.failureClass) {
    telemetry.logUpstreamFailure({
      requestId,
      failureClass: forwardResult.failureClass,
      status: forwardResult.status,
      retryable: forwardResult.retryable,
    })
    circuitBreakerHandler.registerUpstreamFailure(circuitBreakerState)
  } else {
    circuitBreakerHandler.registerUpstreamSuccess(circuitBreakerState)
  }

  // === STEP 10: FINALIZE IDEMPOTENCY + USAGE LOG ===
  try {
    await idempotencyHandler.finalizeIdempotencyKey({
      supabase,
      userId,
      action,
      idempotencyKey,
      requestId,
      requestHash: idempotencyRequestHash,
      status: classifyForwardIdempotencyStatus(forwardResult.status),
      responseStatus: forwardResult.status,
      responseBody: forwardResult.body,
      responseContentType: forwardResult.contentType,
    })
  } catch (err) {
    console.error('idempotency finalize failed:', err)
  }

  await auditLogger.writeMirrorUsageLogIfReady({
    supabase,
    userId,
    projectId: normalized.projectId,
    taskId: normalized.taskId,
    mode: normalized.mode,
    action,
    status: classifyForwardStatus(forwardResult.status),
    requestId,
    idempotencyKey,
    startedAtMs: contextStartedAtMs,
  })

  // === RETURN RESPONSE ===
  return new Response(forwardResult.body, {
    status: forwardResult.status,
    headers: {
      ...buildCorsHeaders(req),
      'Content-Type': forwardResult.contentType,
      ...requestForwarding.buildForwardResponseHeaders(requestId, traceId, idempotencyKey, false),
    },
  })
}
