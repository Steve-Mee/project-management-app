// Mirror Gateway - Thin Proxy (Refactored)
// Orchestration only. All middleware concerns are delegated to isolated modules.
// Request flow: validate → auth → idempotency → rate limit → circuit breaker → forward → finalize

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders } from '../_shared/cors.ts'

// Modules
import { buildStructuredError, errorResponse, buildAuditErrorDetails } from './modules/error_contract.ts'
import {
  resolveActionFromPath,
  resolveIdempotencyKey,
  resolveRequestId,
  resolveTraceId,
} from './modules/routing_identity.ts'
import * as requestValidator from './modules/request_validator.ts'
import * as authHandler from './modules/auth_handler.ts'
import * as idempotencyHandler from './modules/idempotency_handler.ts'
import * as rateLimiterHandler from './modules/rate_limiter_handler.ts'
import * as circuitBreakerHandler from './modules/circuit_breaker_handler.ts'
import * as auditLogger from './modules/audit_logger.ts'
import * as requestForwarding from './modules/request_forwarding.ts'

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

function logIdempotencyContractOnColdStart(): void {
  console.info('mirror-gateway cold start: idempotency contract verified')
}

function logRequestForwarded(details: {
  requestId: string
  traceId: string
  idempotencyKey: string
  action: string
  mode: string
  targetUrl: string
}): void {
  console.info('mirror-gateway forwarding request', details)
}

function logRateLimitDecision(details: {
  requestId: string
  action: string
  allowed: boolean
  reason?: string
}): void {
  console.info('mirror-gateway rate limit decision', details)
}

function logCircuitBreakerDecision(details: {
  requestId: string
  action: string
  allowed: boolean
  reason: string
}): void {
  console.info('mirror-gateway circuit breaker decision', details)
}

function logUpstreamFailure(details: {
  requestId: string
  failureClass: string
  status: number | null
  retryable: boolean
}): void {
  console.warn('mirror-gateway upstream failure', details)
}

logIdempotencyContractOnColdStart()

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  const requestId = resolveRequestId(req)
  const traceId = resolveTraceId(req, requestId)
  const idempotencyKey = resolveIdempotencyKey(req)
  const action = resolveActionFromPath(new URL(req.url).pathname)

  // Track context for deferred logging
  let contextUser: string | null = null
  let contextNormalized: requestValidator.MirrorComputeRequest | null = null
  let contextStartedAtMs: number | null = null

  // --- CORS PREFLIGHT ---
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: buildCorsHeaders(req) })
  }

  // --- METHOD VALIDATION ---
  if (req.method !== 'POST') {
    return errorResponse(
      req,
      buildStructuredError({
        code: 'method_not_allowed',
        message: 'Method not allowed',
        retryable: false,
        requestId,
        traceId,
        idempotencyKey,
        stage: 'request_validation',
      }),
      405,
    )
  }

  // --- ROUTE VALIDATION ---
  if (!action) {
    return errorResponse(
      req,
      buildStructuredError({
        code: 'bad_request',
        message: 'Invalid route. Use /compile or /apply.',
        retryable: false,
        requestId,
        traceId,
        idempotencyKey,
        stage: 'routing',
      }),
      400,
    )
  }

  try {
    // === STEP 1: REQUEST VALIDATION ===
    const validationResult = await requestValidator.validateAndParseRequest(req)
    if ('kind' in validationResult) {
      return errorResponse(req, buildStructuredError(validationResult), validationResult.statusCode)
    }

    const normalized = validationResult.normalized
    contextNormalized = normalized
    contextStartedAtMs = Date.now()

    // === STEP 2: AUTHENTICATION & PERMISSIONS ===
    const authHeader = req.headers.get('Authorization')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    if (!supabaseUrl || !supabaseAnonKey) {
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

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader ?? '' } },
    })

    const authResult = await authHandler.performFullAuthCheck(supabase, authHeader, normalized.mode, requestId)
    if ('kind' in authResult) {
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
      return errorResponse(req, buildStructuredError(authResult), authResult.statusCode)
    }

    const user = authResult.user
    contextUser = user.id

    // === STEP 3: IDEMPOTENCY CLAIM ===
    const idempotencyRequestHash = await idempotencyHandler.buildIdempotencyRequestHash(user.id, action, normalized)
    let idempotencyClaim: idempotencyHandler.IdempotencyClaimResult
    try {
      idempotencyClaim = await idempotencyHandler.claimIdempotencyKey({
        supabase,
        userId: user.id,
        action,
        idempotencyKey,
        requestHash: idempotencyRequestHash,
        requestId,
      })
    } catch (error) {
      if (error instanceof Error && error.message.startsWith('idempotency_')) {
        await auditLogger.writeMirrorUsageLogIfReady({
          supabase,
          userId: user.id,
          projectId: normalized.projectId,
          taskId: normalized.taskId,
          mode: normalized.mode,
          action,
          status: 'failed',
          requestId,
          idempotencyKey,
          startedAtMs: contextStartedAtMs,
        })
        return errorResponse(
          req,
          buildStructuredError({
            code: 'config_error',
            message: 'Idempotency storage is unavailable',
            retryable: false,
            requestId,
            traceId,
            idempotencyKey,
            details: error.message,
            stage: 'idempotency',
          }),
          500,
        )
      }
      throw error
    }

    // Handle idempotency results
    if (idempotencyClaim.kind === 'conflict') {
      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: user.id,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })
      return errorResponse(
        req,
        buildStructuredError({
          code: 'bad_request',
          message: 'Idempotency key reuse with different payload is not allowed',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          details: { action, priorRequestId: idempotencyClaim.record?.request_id },
          stage: 'idempotency',
        }),
        409,
      )
    }

    if (idempotencyClaim.kind === 'in_progress') {
      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: user.id,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })
      return errorResponse(
        req,
        buildStructuredError({
          code: 'bad_request',
          message: 'A request with this idempotency key is already processing',
          retryable: true,
          requestId,
          traceId,
          idempotencyKey,
          details: { action, priorRequestId: idempotencyClaim.record?.request_id },
          stage: 'idempotency',
        }),
        409,
      )
    }

    if (idempotencyClaim.kind === 'replay' && idempotencyClaim.record) {
      const cachedStatus = idempotencyClaim.record.response_status ?? 200
      const cachedBody =
        idempotencyClaim.record.response_body ??
        JSON.stringify({ success: false, error: 'idempotency_record_missing_response' })
      const cachedContentType = idempotencyClaim.record.response_content_type ?? 'application/json'

      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: user.id,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: cachedStatus >= 200 && cachedStatus < 400 ? 'success' : 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })

      return new Response(cachedBody, {
        status: cachedStatus,
        headers: {
          ...buildCorsHeaders(req),
          'Content-Type': cachedContentType,
          'x-request-id': requestId,
          'x-trace-id': traceId,
          'x-idempotency-key': idempotencyKey,
          'x-idempotency-replay': 'true',
        },
      })
    }

    // === STEP 4: RATE LIMIT CHECK ===
    const rateLimitCheck = await rateLimiterHandler.checkPerUserRateLimit(supabase, user.id, action)
    logRateLimitDecision({
      requestId,
      action,
      allowed: rateLimitCheck.allowed,
      reason: rateLimitCheck.reason,
    })

    if (!rateLimitCheck.allowed) {
      const retryAfterSeconds = rateLimitCheck.retryAfterSeconds ?? 60
      const rateLimitError = buildStructuredError({
        code: 'rate_limited',
        message: 'Mirror gateway rate limit exceeded',
        retryable: true,
        requestId,
        traceId,
        idempotencyKey,
        details: {
          reason: rateLimitCheck.reason,
          retryAfterSeconds,
        },
        stage: 'rate_limit',
      })

      try {
        await idempotencyHandler.finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: 429,
          responseBody: JSON.stringify({ success: false, error: rateLimitError }),
          responseContentType: 'application/json',
        })
      } catch (error) {
        console.error('idempotency finalize failed:', error)
      }

      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: user.id,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'rate_limited',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })

      return new Response(JSON.stringify({ success: false, error: rateLimitError }), {
        status: 429,
        headers: {
          ...buildCorsHeaders(req),
          'Content-Type': 'application/json',
          'Retry-After': String(retryAfterSeconds),
          'x-request-id': requestId,
          'x-trace-id': traceId,
          'x-idempotency-key': idempotencyKey,
        },
      })
    }

    // === STEP 5: CIRCUIT BREAKER CHECK ===
    const circuitBreakerDecision = circuitBreakerHandler.evaluateCircuitBreakerAllowance(circuitBreakerState)
    logCircuitBreakerDecision({
      requestId,
      action,
      allowed: circuitBreakerDecision.allowed,
      reason: circuitBreakerDecision.reason,
    })

    if (!circuitBreakerDecision.allowed) {
      const retryAfterSeconds = circuitBreakerDecision.retryAfterSeconds ?? 5
      const breakerError = buildStructuredError({
        code: 'upstream_error',
        message: 'Upstream temporarily unavailable (circuit breaker open)',
        retryable: true,
        requestId,
        traceId,
        idempotencyKey,
        details: { reason: 'circuit_breaker_open', retryAfterSeconds },
        stage: 'circuit_breaker',
      })

      try {
        await idempotencyHandler.finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: 503,
          responseBody: JSON.stringify({ success: false, error: breakerError }),
          responseContentType: 'application/json',
        })
      } catch (error) {
        console.error('idempotency finalize failed:', error)
      }

      if (action === 'apply') {
        await auditLogger.writeApplyAuditEvent({
          supabase,
          userId: user.id,
          normalized,
          requestId,
          idempotencyKey,
          event: 'apply_failed',
          success: false,
          details: buildAuditErrorDetails(breakerError),
        })
      }

      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId: user.id,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'upstream_error',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })

      return new Response(JSON.stringify({ success: false, error: breakerError }), {
        status: 503,
        headers: {
          ...buildCorsHeaders(req),
          'Content-Type': 'application/json',
          'Retry-After': String(retryAfterSeconds),
          'x-request-id': requestId,
          'x-trace-id': traceId,
          'x-idempotency-key': idempotencyKey,
        },
      })
    }

    // === STEP 6: WRITE APPLY AUDIT (started) ===
    if (action === 'apply') {
      await auditLogger.writeApplyAuditEvent({
        supabase,
        userId: user.id,
        normalized,
        requestId,
        idempotencyKey,
        event: 'apply_started',
        success: null,
        details: { source: 'mirror_gateway', filesCount: Object.keys(normalized.files ?? {}).length },
      })
    }

    // === STEP 7: BUILD FORWARD PAYLOAD ===
    const forwardFields = requestValidator.normalizeForwardFields(normalized, user.id)
    const forwardPayload = requestValidator.buildForwardPayload(
      normalized,
      user.id,
      action,
      requestId,
      traceId,
      forwardFields,
    )

    const targetUrl = requestForwarding.resolveForwardEndpoint(normalized.mode, action)
    logRequestForwarded({
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

    // === STEP 9: HANDLE UPSTREAM RESPONSE ===
    if (forwardResult.failureClass) {
      logUpstreamFailure({
        requestId,
        failureClass: forwardResult.failureClass,
        status: forwardResult.status,
        retryable: forwardResult.retryable,
      })
      circuitBreakerHandler.registerUpstreamFailure(circuitBreakerState)
    } else {
      circuitBreakerHandler.registerUpstreamSuccess(circuitBreakerState)
    }

    // === STEP 10: FINALIZE IDEMPOTENCY & LOG ===
    try {
      await idempotencyHandler.finalizeIdempotencyKey({
        supabase,
        userId: user.id,
        action,
        idempotencyKey,
        requestId,
        requestHash: idempotencyRequestHash,
        status: forwardResult.status >= 200 && forwardResult.status < 400 ? 'completed' : 'failed',
        responseStatus: forwardResult.status,
        responseBody: forwardResult.body,
        responseContentType: forwardResult.contentType,
      })
    } catch (error) {
      console.error('idempotency finalize failed:', error)
    }

    const usageStatus = forwardResult.status >= 200 && forwardResult.status < 400 ? 'success' : 'failed'
    await auditLogger.writeMirrorUsageLogIfReady({
      supabase,
      userId: user.id,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
      mode: normalized.mode,
      action,
      status: usageStatus,
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
        error: {
          code: 'internal_error',
          message: 'Internal server error',
          requestId,
        },
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
