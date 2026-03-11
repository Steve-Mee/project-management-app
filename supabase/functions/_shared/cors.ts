// SECURITY PERIMETER:
// Mirror Gateway is a thin proxy and should be reachable only from trusted web
// origins plus the Fly.io private networking path behind it. In production we
// therefore reflect only an explicit allowlist from ALLOWED_ORIGINS, falling
// back to SUPABASE_PROJECT_URL when no custom allowlist is provided. Wildcard
// CORS is reserved for local/dev workflows only.

function normalizeOrigin(value: string | undefined): string | null {
  const raw = value?.trim()
  if (!raw) {
    return null
  }

  try {
    return new URL(raw).origin
  } catch (_) {
    return raw.replace(/\/$/, '')
  }
}

function isDevelopmentCorsMode(): boolean {
  const envValues = [
    Deno.env.get('ENV'),
    Deno.env.get('APP_ENV'),
    Deno.env.get('NODE_ENV'),
    Deno.env.get('SUPABASE_ENV'),
  ]
    .map((value) => value?.trim().toLowerCase())
    .filter((value): value is string => Boolean(value))

  if (envValues.some((value) => ['dev', 'development', 'local', 'test'].includes(value))) {
    return true
  }

  if (envValues.some((value) => ['prod', 'production'].includes(value))) {
    return false
  }

  return !Deno.env.get('DENO_DEPLOYMENT_ID')
}

function resolveAllowedOrigins(): string[] {
  const configured = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((value) => normalizeOrigin(value))
    .filter((value): value is string => Boolean(value))

  if (configured.length > 0) {
    return Array.from(new Set(configured))
  }

  const projectOrigin = normalizeOrigin(Deno.env.get('SUPABASE_PROJECT_URL'))
  return projectOrigin ? [projectOrigin] : []
}

export function buildCorsHeaders(request: Request): Record<string, string> {
  const allowOrigin = (() => {
    if (isDevelopmentCorsMode()) {
      return '*'
    }

    const origin = normalizeOrigin(request.headers.get('Origin') ?? undefined)
    const allowedOrigins = resolveAllowedOrigins()

    if (origin && allowedOrigins.includes(origin)) {
      return origin
    }

    return 'null'
  })()

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Vary': 'Origin',
  }
}

export const corsHeaders = buildCorsHeaders
