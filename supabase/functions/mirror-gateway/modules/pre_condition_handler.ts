// Pre-condition validation for Mirror gateway requests.
// Handles CORS preflight, HTTP method and route checks before any business logic runs.
// Returns a Response to short-circuit, or null to continue the handler chain.

import { buildCorsHeaders } from '../../_shared/cors.ts'
import { buildStructuredError, errorResponse } from './error_contract.ts'

export interface RequestIds {
  requestId: string
  traceId: string
  idempotencyKey: string
}

/**
 * Validate CORS preflight, HTTP method, and gateway route.
 * Returns a Response on failure/shortcircuit; null means "continue processing".
 */
export function validateRequestPreconditions(
  req: Request,
  action: 'compile' | 'apply' | null | undefined,
  ids: RequestIds,
): Response | null {
  // CORS preflight — always allow
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: buildCorsHeaders(req) })
  }

  // Method guard
  if (req.method !== 'POST') {
    return errorResponse(
      req,
      buildStructuredError({
        code: 'method_not_allowed',
        message: 'Method not allowed',
        retryable: false,
        requestId: ids.requestId,
        traceId: ids.traceId,
        idempotencyKey: ids.idempotencyKey,
        stage: 'request_validation',
      }),
      405,
    )
  }

  // Route guard
  if (!action) {
    return errorResponse(
      req,
      buildStructuredError({
        code: 'bad_request',
        message: 'Invalid route. Use /compile or /apply.',
        retryable: false,
        requestId: ids.requestId,
        traceId: ids.traceId,
        idempotencyKey: ids.idempotencyKey,
        stage: 'routing',
      }),
      400,
    )
  }

  return null
}
