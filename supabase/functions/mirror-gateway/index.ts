// Mirror Gateway - Thin Proxy
// Orchestration only. All concerns are delegated to isolated modules.
// Request flow: validate → auth → idempotency → rate limit → circuit breaker → forward → finalize

import { buildCorsHeaders } from '../_shared/cors.ts'
import { buildStructuredError, errorResponse } from './modules/error_contract.ts'
import {
  resolveActionFromPath,
  resolveIdempotencyKey,
  resolveRequestId,
  resolveTraceId,
} from './modules/routing_identity.ts'
import * as requestValidator from './modules/request_validator.ts'
import * as permissionHandler from './modules/permission_handler.ts'
import * as circuitBreakerHandler from './modules/circuit_breaker_handler.ts'
import * as resilienceHandler from './modules/resilience_handler.ts'
import * as rejectionHandler from './modules/rejection_handler.ts'
import * as middleware from './modules/middleware.ts'
import * as auditLogger from './modules/audit_logger.ts'
import * as telemetry from './modules/telemetry.ts'
import * as preConditionHandler from './modules/pre_condition_handler.ts'
import * as idempotencyFlowHandler from './modules/idempotency_flow_handler.ts'
import * as forwardOrchestrator from './modules/forward_orchestrator.ts'

declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
  env: {
    get: (key: string) => string | undefined
  }
}

// Persistent circuit breaker state (in-memory, per-function instance)
const circuitBreakerState: circuitBreakerHandler.CircuitBreakerState = {
  consecutiveFailures: 0,
  openUntilMs: null,
  halfOpenProbeActive: false,
}

console.info('mirror-gateway cold start: idempotency contract verified')

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  const requestId = resolveRequestId(req)
  const traceId = resolveTraceId(req, requestId)
  const idempotencyKey = resolveIdempotencyKey(req)
  const action = resolveActionFromPath(new URL(req.url).pathname)
  const ids = { requestId, traceId, idempotencyKey }

  // Track context for deferred error logging
  let contextUser: string | null = null
  let contextNormalized: requestValidator.MirrorComputeRequest | null = null
  let contextStartedAtMs: number | null = null

  // --- PRE-CONDITIONS: CORS preflight, method, route ---
  const preCheck = preConditionHandler.validateRequestPreconditions(req, action, ids)
  if (preCheck) return preCheck

  try {
    // === STEP 1: REQUEST VALIDATION ===
    const validationResult = await requestValidator.validateAndParseRequest(req)
    if ('kind' in validationResult) {
      return errorResponse(req, buildStructuredError(validationResult), validationResult.statusCode)
    }
    const normalized = validationResult.normalized
    contextNormalized = normalized
    contextStartedAtMs = Date.now()

    // === STEP 2: ENVIRONMENT + AUTHENTICATION ===
    const authHeader = req.headers.get('Authorization')
    const env = middleware.ensureGatewayEnv()
    if (!env.ok) {
      return errorResponse(
        req,
        buildStructuredError({
          code: 'internal_error',
          message: 'Supabase environment is not configured',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'configuration',
        }),
        500,
      )
    }
    const supabase = middleware.buildSupabaseClientForRequest({
      supabaseUrl: env.supabaseUrl,
      supabaseAnonKey: env.supabaseAnonKey,
      authHeader,
    })
    const authResult = await permissionHandler.performGatewayAuthCheck({
      supabase,
      authHeader,
      mode: normalized.mode,
      requestId,
    })
    if (!authResult.ok) {
      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: contextUser,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })
      return errorResponse(req, buildStructuredError(authResult.error), authResult.error.statusCode)
    }
    const user = authResult.user
    contextUser = user.id

    // === STEP 3: IDEMPOTENCY ===
    const idempotencyResult = await idempotencyFlowHandler.executeIdempotencyClaim({
      req,
      supabase,
      userId: user.id,
      normalized,
      action,
      idempotencyKey,
      requestId,
      traceId,
      contextStartedAtMs,
    })
    if (idempotencyResult.exit) return idempotencyResult.response
    const idempotencyRequestHash = idempotencyResult.hash

    // === STEP 4: RATE LIMIT ===
    const rateLimitCheck = await resilienceHandler.evaluateRateLimitDecision({
      supabase,
      userId: user.id,
      action,
      requestId,
      onDecision: telemetry.logRateLimitDecision,
    })
    if (!rateLimitCheck.allowed) {
      return rejectionHandler.handleRateLimitRejection({
        req, supabase, userId: user.id, normalized, action,
        requestId, traceId, idempotencyKey, idempotencyRequestHash,
        retryAfterSeconds: rateLimitCheck.retryAfterSeconds ?? 60,
        contextStartedAtMs,
      })
    }

    // === STEP 5: CIRCUIT BREAKER ===
    const cbDecision = resilienceHandler.evaluateCircuitBreakerDecision({
      state: circuitBreakerState,
      requestId,
      action,
      onDecision: telemetry.logCircuitBreakerDecision,
    })
    if (!cbDecision.allowed) {
      return rejectionHandler.handleCircuitBreakerRejection({
        req, supabase, userId: user.id, normalized, action,
        requestId, traceId, idempotencyKey, idempotencyRequestHash,
        retryAfterSeconds: cbDecision.retryAfterSeconds ?? 5,
        contextStartedAtMs,
      })
    }

    // === STEPS 6–10: FORWARD + FINALIZE ===
    return await forwardOrchestrator.executeForwardAndFinalize({
      req,
      supabase,
      userId: user.id,
      normalized,
      action,
      requestId,
      traceId,
      idempotencyKey,
      idempotencyRequestHash,
      circuitBreakerState,
      contextStartedAtMs,
    })

  } catch (error) {
    console.error('mirror-gateway unhandled error:', error)
    await auditLogger.writeMirrorUsageLogIfReady({
      supabase: null,
      userId: contextUser,
      projectId: contextNormalized?.projectId ?? null,
      taskId: contextNormalized?.taskId ?? null,
      mode: contextNormalized?.mode ?? null,
      action,
      status: 'failed',
      requestId,
      idempotencyKey,
      startedAtMs: contextStartedAtMs,
    })
    return new Response(
      JSON.stringify({
        success: false,
        error: { code: 'internal_error', message: 'Internal server error', requestId },
      }),
      {
        status: 500,
        headers: {
          ...buildCorsHeaders(req),
          'Content-Type': 'application/json',
          'x-request-id': requestId,
          'x-trace-id': traceId,
          'x-idempotency-key': idempotencyKey,
        },
      },
    )
  }
})
