import { buildCorsHeaders } from '../../_shared/cors.ts'

export interface StructuredError {
  code:
    | 'bad_request'
    | 'payload_too_large'
    | 'unauthorized'
    | 'forbidden'
    | 'method_not_allowed'
    | 'config_error'
    | 'timeout'
    | 'upstream_error'
    | 'rate_limited'
    | 'internal_error'
  message: string
  retryable: boolean
  requestId: string
  traceId: string
  idempotencyKey?: string
  error_family: 'client' | 'auth' | 'config' | 'timeout' | 'upstream' | 'rate_limit' | 'internal'
  upstream_status: number | null
  stage: string
  details?: unknown
}

export function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...buildCorsHeaders(req), 'Content-Type': 'application/json' },
  })
}

export function errorResponse(req: Request, error: StructuredError, status: number): Response {
  return jsonResponse(req, { success: false, error }, status)
}

function resolveErrorFamily(
  code: StructuredError['code'],
): StructuredError['error_family'] {
  switch (code) {
    case 'bad_request':
    case 'payload_too_large':
    case 'method_not_allowed':
      return 'client'
    case 'unauthorized':
    case 'forbidden':
      return 'auth'
    case 'config_error':
      return 'config'
    case 'timeout':
      return 'timeout'
    case 'upstream_error':
      return 'upstream'
    case 'rate_limited':
      return 'rate_limit'
    case 'internal_error':
      return 'internal'
  }
}

export function buildStructuredError({
  code,
  message,
  retryable,
  requestId,
  traceId,
  idempotencyKey,
  details,
  upstreamStatus = null,
  stage,
}: {
  code: StructuredError['code']
  message: string
  retryable: boolean
  requestId: string
  traceId: string
  idempotencyKey?: string
  details?: unknown
  upstreamStatus?: number | null
  stage: string
}): StructuredError {
  return {
    code,
    message,
    retryable,
    requestId,
    traceId,
    idempotencyKey,
    error_family: resolveErrorFamily(code),
    upstream_status: upstreamStatus,
    stage,
    details,
  }
}

export function buildAuditErrorDetails(
  error: StructuredError,
  extra: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    code: error.code,
    message: error.message,
    error_family: error.error_family,
    upstream_status: error.upstream_status,
    stage: error.stage,
    ...(error.details === undefined ? {} : { details: error.details }),
    ...extra,
  }
}