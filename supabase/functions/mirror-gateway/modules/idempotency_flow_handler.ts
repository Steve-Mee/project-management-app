// Idempotency claim orchestration for the Mirror gateway.
// Encapsulates hash building, claim storage, error handling, and early-exit resolution
// so that index.ts sees a single opaque result rather than managing 50+ lines of flow.

import { buildCorsHeaders } from '../../_shared/cors.ts'
import { buildStructuredError, errorResponse, type StructuredError } from './error_contract.ts'
import * as idempotencyHandler from './idempotency_handler.ts'
import * as auditLogger from './audit_logger.ts'
import * as middleware from './middleware.ts'
import type { MirrorComputeRequest } from './request_validator.ts'

type SupabaseClient = ReturnType<typeof middleware.buildSupabaseClientForRequest>

/** Returned from executeIdempotencyClaim. */
export type IdempotencyFlowResult =
  | { exit: true; response: Response }
  | { exit: false; hash: string }

/**
 * Run the full idempotency claim flow:
 *   hash → claim → storage-error handling → early-exit (replay / conflict / in_progress)
 *
 * Returns `{ exit: true, response }` when the caller should return immediately,
 * or `{ exit: false, hash }` to proceed with the request and pass the hash downstream.
 */
export async function executeIdempotencyClaim({
  req,
  supabase,
  userId,
  normalized,
  action,
  idempotencyKey,
  requestId,
  traceId,
  contextStartedAtMs,
}: {
  req: Request
  supabase: SupabaseClient
  userId: string
  normalized: MirrorComputeRequest
  action: 'compile' | 'apply'
  idempotencyKey: string
  requestId: string
  traceId: string
  contextStartedAtMs: number | null
}): Promise<IdempotencyFlowResult> {
  const hash = await idempotencyHandler.buildIdempotencyRequestHash(userId, action, normalized)

  let claim: idempotencyHandler.IdempotencyClaimResult
  try {
    claim = await idempotencyHandler.claimIdempotencyKey({
      supabase,
      userId,
      action,
      idempotencyKey,
      requestHash: hash,
      requestId,
    })
  } catch (error) {
    // Idempotency storage unavailable — fail safe
    if (error instanceof Error && error.message.startsWith('idempotency_')) {
      await auditLogger.writeMirrorUsageLogIfReady({
        supabase,
        userId,
        projectId: normalized.projectId,
        taskId: normalized.taskId,
        mode: normalized.mode,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: contextStartedAtMs,
      })
      return {
        exit: true,
        response: errorResponse(
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
        ),
      }
    }
    throw error
  }

  // Resolve early exits: replay, in_progress conflict, duplicate
  const earlyExit = idempotencyHandler.resolveIdempotencyEarlyExit(claim, action)
  if (earlyExit) {
    await auditLogger.writeMirrorUsageLogIfReady({
      supabase,
      userId,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
      mode: normalized.mode,
      action,
      status: earlyExit.usageStatus,
      requestId,
      idempotencyKey,
      startedAtMs: contextStartedAtMs,
    })

    if (earlyExit.isReplay) {
      return {
        exit: true,
        response: new Response(earlyExit.cachedBody, {
          status: earlyExit.cachedStatus,
          headers: {
            ...buildCorsHeaders(req),
            'Content-Type': earlyExit.cachedContentType,
            'x-request-id': requestId,
            'x-trace-id': traceId,
            'x-idempotency-key': idempotencyKey,
            'x-idempotency-replay': 'true',
          },
        }),
      }
    }

    return {
      exit: true,
      response: errorResponse(
        req,
        buildStructuredError({
          code: earlyExit.errorCode as StructuredError['code'],
          message: earlyExit.message,
          retryable: earlyExit.retryable,
          requestId,
          traceId,
          idempotencyKey,
          details: earlyExit.details,
          stage: 'idempotency',
        }),
        earlyExit.httpStatus,
      ),
    }
  }

  return { exit: false, hash }
}
