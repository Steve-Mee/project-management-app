// Request forwarding handler: upstream HTTP communication and response handling.
// Manages fetch timeout, failure classification, and response finalization.

import type { ForwardPayload } from './request_validator.ts'

type StructuredError = any // from error_contract.ts (avoid circular import)

export type UpstreamFailureClass =
  | 'request_timeout'
  | 'transport_error'
  | 'upstream_timeout'
  | 'upstream_rate_limited'
  | 'upstream_client_error'
  | 'upstream_server_error'
  | 'upstream_unknown_error'

export interface ForwardingResult {
  status: number
  body: string
  contentType: string
  failureClass?: UpstreamFailureClass
  retryable: boolean
}

/**
 * Get configured forward timeout in milliseconds.
 */
export function getForwardTimeoutMs(): number {
  const deno = (globalThis as any).Deno
  const raw = deno?.env?.get?.('MIRROR_FORWARD_TIMEOUT_MS')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed >= 1000) {
    return parsed
  }
  return 20000 // default: 20 seconds
}

/**
 * Get upstream endpoint URL for given mode and action.
 */
export function resolveForwardEndpoint(mode: 'private' | 'cloud', action: 'compile' | 'apply'): string {
  const deno = (globalThis as any).Deno
  if (mode === 'cloud') {
    const cloudGateway = deno?.env?.get?.('MIRROR_CLOUD_GATEWAY_URL')
    if (!cloudGateway) {
      throw new Error('MIRROR_CLOUD_GATEWAY_URL not configured')
    }
    return `${cloudGateway}/${action}`
  }

  // Private mode: local gRPC runner
  const localGateway = deno?.env?.get?.('MIRROR_LOCAL_GATEWAY_URL') ?? 'http://localhost:50051'
  return `${localGateway}/${action}`
}

/**
 * Classify upstream HTTP status code into failure category.
 */
export function classifyUpstreamStatusFailure(status: number): UpstreamFailureClass {
  if (status === 408 || status === 504) {
    return 'upstream_timeout'
  }

  if (status === 429) {
    return 'upstream_rate_limited'
  }

  if (status >= 400 && status < 500) {
    return 'upstream_client_error'
  }

  if (status >= 500) {
    return 'upstream_server_error'
  }

  return 'upstream_unknown_error'
}

/**
 * Redact sensitive strings (URLs, long values) for safe logging.
 */
function redactPotentialSecretString(value: string): string {
  const clipped = value.length > 2048 ? `${value.slice(0, 2048)}...[truncated]` : value
  if (clipped.startsWith('http://') || clipped.startsWith('https://')) {
    try {
      const parsed = new URL(clipped)
      return `${parsed.origin}${parsed.pathname}?[redacted]`
    } catch {
      const queryIndex = clipped.indexOf('?')
      return queryIndex >= 0 ? `${clipped.slice(0, queryIndex)}?[redacted]` : clipped
    }
  }
  return clipped
}

/**
 * Recursively redact sensitive keys for safe observability.
 */
export function redactForObservability(value: unknown, depth = 0): unknown {
  if (depth > 5) {
    return '[redacted-depth-limit]'
  }

  if (typeof value === 'string') {
    return redactPotentialSecretString(value)
  }

  if (Array.isArray(value)) {
    return value.map((entry) => redactForObservability(entry, depth + 1))
  }

  if (!value || typeof value !== 'object') {
    return value
  }

  const sensitiveKeyPattern = /(authorization|token|signed|secret|password|url)/i
  const output: Record<string, unknown> = {}
  for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
    output[key] = sensitiveKeyPattern.test(key) ? '[redacted]' : redactForObservability(nested, depth + 1)
  }
  return output
}

/**
 * Sanitize upstream response body for inclusion in error details.
 */
export function sanitizeUpstreamBodyForErrorDetails(upstreamBody: string): unknown {
  try {
    const parsed = JSON.parse(upstreamBody)
    return redactForObservability(parsed)
  } catch {
    return redactPotentialSecretString(upstreamBody)
  }
}

/**
 * Forward request to upstream runner and capture response.
 * Handles timeout, transport errors, and response parsing.
 */
export async function forwardToUpstream({
  targetUrl,
  payload,
  authHeader,
  requestId,
  traceId,
  idempotencyKey,
}: {
  targetUrl: string
  payload: ForwardPayload
  authHeader: string
  requestId: string
  traceId: string
  idempotencyKey: string
}): Promise<ForwardingResult> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), getForwardTimeoutMs())

  try {
    const upstreamResponse = await fetch(targetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authHeader,
        'x-user-id': payload.userId,
        'x-request-id': requestId,
        'x-trace-id': traceId,
        'x-idempotency-key': idempotencyKey,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    })

    const contentType = upstreamResponse.headers.get('content-type') ?? 'application/json'
    const responseBody = await upstreamResponse.text()

    const isSuccess = upstreamResponse.status >= 200 && upstreamResponse.status < 300

    return {
      status: upstreamResponse.status,
      body: responseBody,
      contentType,
      failureClass: isSuccess ? undefined : classifyUpstreamStatusFailure(upstreamResponse.status),
      retryable: isSuccess || upstreamResponse.status === 429 || upstreamResponse.status >= 500,
    }
  } catch (error) {
    clearTimeout(timeout)

    // Timeout error
    if (error instanceof DOMException && error.name === 'AbortError') {
      return {
        status: 504,
        body: JSON.stringify({
          error: {
            code: 'timeout',
            message: 'Upstream request timed out',
          },
        }),
        contentType: 'application/json',
        failureClass: 'request_timeout',
        retryable: true,
      }
    }

    // Network/transport error
    return {
      status: 502,
      body: JSON.stringify({
        error: {
          code: 'transport_error',
          message: 'Failed to reach upstream',
          details: String(error),
        },
      }),
      contentType: 'application/json',
      failureClass: 'transport_error',
      retryable: true,
    }
  } finally {
    clearTimeout(timeout)
  }
}

/**
 * Build response headers for forwarding result (CORS + request tracking).
 */
export function buildForwardResponseHeaders(
  requestId: string,
  traceId: string,
  idempotencyKey: string,
  isReplay = false,
  corsHeaders: Record<string, string> = {},
): Record<string, string> {
  return {
    ...corsHeaders,
    'x-request-id': requestId,
    'x-trace-id': traceId,
    'x-idempotency-key': idempotencyKey,
    ...(isReplay ? { 'x-idempotency-replay': 'true' } : {}),
  }
}
