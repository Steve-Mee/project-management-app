export function resolveForwardEndpoint(
  mode: 'private' | 'cloud',
  action: 'compile' | 'apply',
): string {
  const key = mode === 'private' ? 'PRIVATE_COMPUTE_ENDPOINT' : 'FLY_MIRROR_BACKEND_ENDPOINT'
  const configured = Deno.env.get(key)?.trim()
  if (!configured) {
    throw new Error(`missing_endpoint_env:${key}`)
  }

  const normalized = configured.replace(/\/$/, '')
  const actionSuffixMatch = normalized.match(/\/(compile|apply)$/i)
  if (actionSuffixMatch) {
    const configuredAction = actionSuffixMatch[1]?.toLowerCase() as 'compile' | 'apply'
    if (configuredAction !== action) {
      throw new Error(
        `unsupported_action_path_combination:${key}:${configuredAction}->${action}`,
      )
    }
    return normalized
  }

  return `${normalized}/${action}`
}

export function resolveActionFromPath(pathname: string): 'compile' | 'apply' | null {
  const normalized = pathname.toLowerCase()

  if (normalized.endsWith('/compile')) {
    return 'compile'
  }

  if (normalized.endsWith('/apply')) {
    return 'apply'
  }

  return null
}

export function resolveIdempotencyKey(req: Request): string {
  const key = req.headers.get('x-idempotency-key') ?? req.headers.get('idempotency-key')
  if (key && key.trim().length > 0) {
    return key.trim()
  }
  return crypto.randomUUID()
}

export function resolveRequestId(req: Request): string {
  const direct = req.headers.get('x-request-id') ?? req.headers.get('request-id')
  if (direct && direct.trim().length > 0) {
    return direct.trim()
  }
  return `gateway-${Date.now().toString(36)}-${crypto.randomUUID()}`
}

export function resolveTraceId(req: Request, requestId: string): string {
  const direct = req.headers.get('x-trace-id') ?? req.headers.get('trace-id')
  if (direct && direct.trim().length > 0) {
    return direct.trim()
  }
  return `trace-${requestId}`
}