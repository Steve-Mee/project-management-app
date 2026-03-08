// Mirror compute forwarding function.
// Forwards authenticated requests to HTTP POST /compile backends with timeout,
// retries handled upstream, and structured error responses.
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
  env: {
    get: (key: string) => string | undefined
  }
}

interface MirrorComputeRequest {
  prompt: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  files?: Record<string, string>
  metadata?: Record<string, unknown>
}

interface ForwardPayload {
  prompt: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  userId: string
  files: Record<string, string>
  metadata: Record<string, unknown>
}

interface StructuredError {
  code:
    | 'bad_request'
    | 'unauthorized'
    | 'method_not_allowed'
    | 'timeout'
    | 'upstream_error'
    | 'internal_error'
  message: string
  retryable: boolean
  requestId: string
  details?: unknown
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function errorResponse(error: StructuredError, status: number): Response {
  return jsonResponse({ success: false, error }, status)
}

function resolveForwardEndpoint(mode: 'private' | 'cloud'): string {
  const privateEndpoint =
    Deno.env.get('PRIVATE_COMPUTE_ENDPOINT') ?? 'http://127.0.0.1:50051/compile'
  const cloudEndpoint =
    Deno.env.get('FLY_MIRROR_COMPUTE_ENDPOINT') ?? 'https://mirror-compute.fly.dev/compile'

  return mode === 'private' ? privateEndpoint : cloudEndpoint
}

function timeoutMs(): number {
  const raw = Deno.env.get('MIRROR_FORWARD_TIMEOUT_MS')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed >= 1000) {
    return parsed
  }
  return 20000
}

function normalizeRequestBody(body: Partial<MirrorComputeRequest>): MirrorComputeRequest | null {
  const { prompt, projectId, taskId, mode, files, metadata } = body
  if (!prompt || !projectId || !taskId || !mode) {
    return null
  }
  if (mode !== 'private' && mode !== 'cloud') {
    return null
  }

  const safeFiles = files && typeof files === 'object' ? files : {}
  const safeMetadata = metadata && typeof metadata === 'object' ? metadata : {}

  return {
    prompt,
    projectId,
    taskId,
    mode,
    files: safeFiles,
    metadata: safeMetadata,
  }
}

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID()

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return errorResponse(
      {
        code: 'method_not_allowed',
        message: 'Method not allowed',
        retryable: false,
        requestId,
      },
      405,
    )
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(
        {
          code: 'unauthorized',
          message: 'Missing or invalid authorization header',
          retryable: false,
          requestId,
        },
        401,
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    if (!supabaseUrl || !supabaseAnonKey) {
      return errorResponse(
        {
          code: 'internal_error',
          message: 'Supabase environment is not configured',
          retryable: false,
          requestId,
        },
        500,
      )
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return errorResponse(
        {
          code: 'unauthorized',
          message: 'Unauthorized',
          retryable: false,
          requestId,
        },
        401,
      )
    }

    const rawBody: Partial<MirrorComputeRequest> = await req.json()
    const normalized = normalizeRequestBody(rawBody)
    if (!normalized) {
      return errorResponse(
        {
          code: 'bad_request',
          message: 'Missing or invalid fields: prompt, projectId, taskId, mode',
          retryable: false,
          requestId,
        },
        400,
      )
    }

    const targetUrl = resolveForwardEndpoint(normalized.mode)
    const payload: ForwardPayload = {
      prompt: normalized.prompt,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
      mode: normalized.mode,
      userId: user.id,
      files: normalized.files ?? {},
      metadata: normalized.metadata ?? {},
    }

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs())

    let upstreamResponse: Response
    try {
      upstreamResponse = await fetch(targetUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: authHeader,
          'x-user-id': user.id,
          'x-request-id': requestId,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      })
    } catch (error) {
      clearTimeout(timeout)
      if (error instanceof DOMException && error.name === 'AbortError') {
        return errorResponse(
          {
            code: 'timeout',
            message: 'Upstream /compile request timed out',
            retryable: true,
            requestId,
          },
          504,
        )
      }

      return errorResponse(
        {
          code: 'upstream_error',
          message: 'Failed to reach upstream /compile endpoint',
          retryable: true,
          requestId,
          details: String(error),
        },
        502,
      )
    } finally {
      clearTimeout(timeout)
    }

    const contentType = upstreamResponse.headers.get('content-type') ?? 'application/json'
    const upstreamBody = await upstreamResponse.text()

    if (!upstreamResponse.ok) {
      return errorResponse(
        {
          code: 'upstream_error',
          message: 'Upstream /compile returned a non-success status',
          retryable:
            upstreamResponse.status === 408 ||
            upstreamResponse.status === 429 ||
            upstreamResponse.status >= 500,
          requestId,
          details: {
            status: upstreamResponse.status,
            body: upstreamBody,
          },
        },
        upstreamResponse.status,
      )
    }

    return new Response(upstreamBody, {
      status: upstreamResponse.status,
      headers: { ...corsHeaders, 'Content-Type': contentType, 'x-request-id': requestId },
    })
  } catch (error) {
    console.error('mirror_compute forwarding error:', error)
    return errorResponse(
      {
        code: 'internal_error',
        message: 'Internal server error',
        retryable: false,
        requestId,
        details: String(error),
      },
      500,
    )
  }
})
