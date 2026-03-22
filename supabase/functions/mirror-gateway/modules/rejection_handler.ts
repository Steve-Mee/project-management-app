// Rejection handlers for gateway middleware decisions.
// Extracted from index.ts to keep orchestration readable and compositional.

import { buildCorsHeaders } from '../../_shared/cors.ts'
import { buildStructuredError, buildAuditErrorDetails } from './error_contract.ts'
import * as idempotencyHandler from './idempotency_handler.ts'
import * as auditLogger from './audit_logger.ts'
import * as middleware from './middleware.ts'
import type { MirrorComputeRequest } from './request_validator.ts'

type SupabaseClient = ReturnType<typeof middleware.buildSupabaseClientForRequest>

export async function handleRateLimitRejection({
  req,
  supabase,
  userId,
  normalized,
  action,
  requestId,
  traceId,
  idempotencyKey,
  idempotencyRequestHash,
  retryAfterSeconds,
  contextStartedAtMs,
}: {
  req: Request
  supabase: SupabaseClient
  userId: string
  normalized: MirrorComputeRequest
  action: 'compile' | 'apply'
  requestId: string
  traceId: string
  idempotencyKey: string
  idempotencyRequestHash: string
  retryAfterSeconds: number
  contextStartedAtMs: number | null
}): Promise<Response> {
  const rateLimitError = buildStructuredError({
    code: 'rate_limited',
    message: 'Mirror gateway rate limit exceeded',
    retryable: true,
    requestId,
    traceId,
    idempotencyKey,
    details: { retryAfterSeconds },
    stage: 'rate_limit',
  })
  try {
    await idempotencyHandler.finalizeIdempotencyKey({
      supabase,
      userId,
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
    userId,
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

export async function handleCircuitBreakerRejection({
  req,
  supabase,
  userId,
  normalized,
  action,
  requestId,
  traceId,
  idempotencyKey,
  idempotencyRequestHash,
  retryAfterSeconds,
  contextStartedAtMs,
}: {
  req: Request
  supabase: SupabaseClient
  userId: string
  normalized: MirrorComputeRequest
  action: 'compile' | 'apply'
  requestId: string
  traceId: string
  idempotencyKey: string
  idempotencyRequestHash: string
  retryAfterSeconds: number
  contextStartedAtMs: number | null
}): Promise<Response> {
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
      userId,
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
      userId,
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
    userId,
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
