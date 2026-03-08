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
  actorUserId?: string
  backupId?: string
  fileSetFingerprint?: string
  signedInputUrls?: Record<string, string>
  files?: Record<string, string>
  metadata?: Record<string, unknown>
}

interface ForwardPayload {
  prompt: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  action: 'compile' | 'apply'
  userId: string
  files: Record<string, string>
  metadata: Record<string, unknown>
  actorUserId: string
  backupId: string | null
  fileSetFingerprint: string | null
  signedInputUrls: Record<string, string>
}

interface StructuredError {
  code:
    | 'bad_request'
    | 'payload_too_large'
    | 'unauthorized'
    | 'method_not_allowed'
    | 'config_error'
    | 'timeout'
    | 'upstream_error'
    | 'internal_error'
  message: string
  retryable: boolean
  requestId: string
  idempotencyKey?: string
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

function resolveForwardEndpoint(mode: 'private' | 'cloud', action: 'compile' | 'apply'): string {
  const key = mode === 'private' ? 'PRIVATE_COMPUTE_ENDPOINT' : 'FLY_MIRROR_COMPUTE_ENDPOINT'
  const configured = Deno.env.get(key)?.trim()
  if (!configured) {
    throw new Error(`missing_endpoint_env:${key}`)
  }

  const normalized = configured.replace(/\/$/, '')
  if (normalized.endsWith('/compile') || normalized.endsWith('/apply')) {
    return normalized
  }

  return `${normalized}/${action}`
}

function resolveActionFromPath(pathname: string): 'compile' | 'apply' | null {
  const normalized = pathname.toLowerCase()

  if (normalized.endsWith('/compile')) {
    return 'compile'
  }

  if (normalized.endsWith('/apply')) {
    return 'apply'
  }

  return null
}

function resolveIdempotencyKey(req: Request): string {
  const key = req.headers.get('x-idempotency-key') ?? req.headers.get('idempotency-key')
  if (key && key.trim().length > 0) {
    return key.trim()
  }
  return crypto.randomUUID()
}

function stableStringify(value: unknown): string {
  if (value === null || value === undefined) {
    return ''
  }

  if (typeof value !== 'object') {
    return String(value)
  }

  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(',')}]`
  }

  const record = value as Record<string, unknown>
  const keys = Object.keys(record).sort()
  return `{${keys.map((key) => `${key}:${stableStringify(record[key])}`).join(',')}}`
}

function fingerprintValue(value: unknown): string {
  const raw = stableStringify(value)
  let hash = 2166136261
  for (let i = 0; i < raw.length; i += 1) {
    hash ^= raw.charCodeAt(i)
    hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24)
  }

  const normalized = (hash >>> 0).toString(16).padStart(8, '0')
  return `fnv1a32:${normalized}`
}

function normalizeArtifactIds(request: MirrorComputeRequest): string[] {
  const ids = new Set<string>()
  if (request.backupId && request.backupId.trim().length > 0) {
    ids.add(request.backupId.trim())
  }
  const signedInputUrls = request.signedInputUrls
  if (signedInputUrls && typeof signedInputUrls === 'object') {
    for (const value of Object.values(signedInputUrls)) {
      if (typeof value === 'string' && value.trim().length > 0) {
        ids.add(value.trim())
      }
    }
  }
  return Array.from(ids)
}

function normalizeUuidOrNull(value: string | undefined, fallback: string): string {
  const candidate = value?.trim()
  if (!candidate) {
    return fallback
  }

  const uuidV4Like = /^[0-9a-fA-F-]{36}$/
  return uuidV4Like.test(candidate) ? candidate : fallback
}

const MAX_REQUEST_BODY_BYTES = 512 * 1024

function normalizeNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return undefined
  }

  const normalized = value.trim()
  return normalized.length > 0 ? normalized : undefined
}

function normalizeSignedInputUrls(value: unknown): Record<string, string> {
  if (!value || typeof value !== 'object') {
    return {}
  }

  const normalizedEntries: Array<[string, string]> = []
  for (const [rawKey, rawValue] of Object.entries(value as Record<string, unknown>)) {
    const key = normalizeNonEmptyString(rawKey)
    const url = normalizeNonEmptyString(rawValue)
    if (key && url) {
      normalizedEntries.push([key, url])
    }
  }

  normalizedEntries.sort((a, b) => a[0].localeCompare(b[0]))
  return Object.fromEntries(normalizedEntries)
}

async function parseRequestJsonWithLimit(req: Request): Promise<Partial<MirrorComputeRequest>> {
  const contentLength = req.headers.get('content-length')
  if (contentLength) {
    const parsedLength = Number.parseInt(contentLength, 10)
    if (Number.isFinite(parsedLength) && parsedLength > MAX_REQUEST_BODY_BYTES) {
      throw new Error('payload_too_large:header')
    }
  }

  const rawBody = await req.text()
  const bodyBytes = new TextEncoder().encode(rawBody).length
  if (bodyBytes > MAX_REQUEST_BODY_BYTES) {
    throw new Error('payload_too_large:body')
  }

  try {
    return JSON.parse(rawBody) as Partial<MirrorComputeRequest>
  } catch {
    throw new Error('bad_json')
  }
}

function normalizeForwardFields(normalized: MirrorComputeRequest, userId: string): {
  actorUserId: string
  backupId: string | null
  fileSetFingerprint: string | null
  signedInputUrls: Record<string, string>
} {
  return {
    actorUserId: normalizeUuidOrNull(normalized.actorUserId, userId),
    backupId: normalizeNonEmptyString(normalized.backupId) ?? null,
    fileSetFingerprint: normalizeNonEmptyString(normalized.fileSetFingerprint) ?? null,
    signedInputUrls: normalizeSignedInputUrls(normalized.signedInputUrls),
  }
}

async function writeApplyAuditEvent({
  supabase,
  userId,
  normalized,
  requestId,
  idempotencyKey,
  event,
  success,
  details,
  appliedFilesFingerprint,
  diffFingerprint,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  normalized: MirrorComputeRequest
  requestId: string
  idempotencyKey: string
  event: 'apply_started' | 'apply_completed' | 'apply_failed'
  success: boolean | null
  details: Record<string, unknown>
  appliedFilesFingerprint?: string
  diffFingerprint?: string
}): Promise<void> {
  if (event !== 'apply_started' && event !== 'apply_completed' && event !== 'apply_failed') {
    return
  }

  const payload = {
    user_id: userId,
    project_id: normalized.projectId,
    task_id: normalized.taskId,
    mode: normalized.mode,
    event,
    request_id: requestId,
    idempotency_key: idempotencyKey,
    backup_id: normalized.backupId ?? null,
    success,
    actor_user_id: normalizeUuidOrNull(normalized.actorUserId, userId),
    file_set_fingerprint: normalized.fileSetFingerprint ?? null,
    applied_files_fingerprint: appliedFilesFingerprint ?? null,
    diff_fingerprint: diffFingerprint ?? null,
    artifact_ids: normalizeArtifactIds(normalized),
    details,
  }

  const { error } = await supabase.from('mirror_apply_audit_events').insert(payload)
  if (error) {
    console.error('mirror_compute apply audit write failed:', error.message)
  }
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
  const {
    prompt,
    projectId,
    taskId,
    mode,
    files,
    metadata,
    actorUserId,
    backupId,
    fileSetFingerprint,
    signedInputUrls,
  } = body
  const normalizedPrompt = normalizeNonEmptyString(prompt)
  const normalizedProjectId = normalizeNonEmptyString(projectId)
  const normalizedTaskId = normalizeNonEmptyString(taskId)

  if (!normalizedPrompt || !normalizedProjectId || !normalizedTaskId || !mode) {
    return null
  }
  if (mode !== 'private' && mode !== 'cloud') {
    return null
  }

  const safeFiles: Record<string, string> = {}
  if (files && typeof files === 'object') {
    for (const [rawPath, rawContent] of Object.entries(files)) {
      if (typeof rawPath === 'string' && typeof rawContent === 'string') {
        const path = rawPath.trim()
        if (path.length > 0) {
          safeFiles[path] = rawContent
        }
      }
    }
  }

  const safeMetadata = metadata && typeof metadata === 'object' ? metadata : {}

  return {
    prompt: normalizedPrompt,
    projectId: normalizedProjectId,
    taskId: normalizedTaskId,
    mode,
    actorUserId: normalizeNonEmptyString(actorUserId),
    backupId: normalizeNonEmptyString(backupId),
    fileSetFingerprint: normalizeNonEmptyString(fileSetFingerprint),
    signedInputUrls: normalizeSignedInputUrls(signedInputUrls),
    files: safeFiles,
    metadata: safeMetadata,
  }
}

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID()
  const idempotencyKey = resolveIdempotencyKey(req)
  const action = resolveActionFromPath(new URL(req.url).pathname)

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
        idempotencyKey,
      },
      405,
    )
  }

  if (!action) {
    return errorResponse(
      {
        code: 'bad_request',
        message: 'Invalid route. Use /compile or /apply.',
        retryable: false,
        requestId,
        idempotencyKey,
      },
      400,
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
          idempotencyKey,
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
          idempotencyKey,
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
          idempotencyKey,
        },
        401,
      )
    }

    let rawBody: Partial<MirrorComputeRequest>
    try {
      rawBody = await parseRequestJsonWithLimit(req)
    } catch (error) {
      if (error instanceof Error && error.message.startsWith('payload_too_large:')) {
        return errorResponse(
          {
            code: 'payload_too_large',
            message: `Request body exceeds ${MAX_REQUEST_BODY_BYTES} bytes limit`,
            retryable: false,
            requestId,
            idempotencyKey,
          },
          413,
        )
      }

      if (error instanceof Error && error.message === 'bad_json') {
        return errorResponse(
          {
            code: 'bad_request',
            message: 'Invalid JSON body',
            retryable: false,
            requestId,
            idempotencyKey,
          },
          400,
        )
      }

      throw error
    }

    const normalized = normalizeRequestBody(rawBody)
    if (!normalized) {
      return errorResponse(
        {
          code: 'bad_request',
          message: 'Missing or invalid fields: prompt, projectId, taskId, mode',
          retryable: false,
          requestId,
          idempotencyKey,
        },
        400,
      )
    }

    const targetUrl = resolveForwardEndpoint(normalized.mode, action)

    if (action === 'apply') {
      await writeApplyAuditEvent({
        supabase,
        userId: user.id,
        normalized,
        requestId,
        idempotencyKey,
        event: 'apply_started',
        success: null,
        details: {
          source: 'edge_function',
          filesCount: Object.keys(normalized.files ?? {}).length,
        },
      })
    }

    const normalizedForwardFields = normalizeForwardFields(normalized, user.id)

    const payload: ForwardPayload = {
      prompt: normalized.prompt,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
      mode: normalized.mode,
      action,
      userId: user.id,
      files: normalized.files ?? {},
      metadata: normalized.metadata ?? {},
      actorUserId: normalizedForwardFields.actorUserId,
      backupId: normalizedForwardFields.backupId,
      fileSetFingerprint: normalizedForwardFields.fileSetFingerprint,
      signedInputUrls: normalizedForwardFields.signedInputUrls,
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
          'x-idempotency-key': idempotencyKey,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      })
    } catch (error) {
      clearTimeout(timeout)
      if (error instanceof DOMException && error.name === 'AbortError') {
        if (action === 'apply') {
          await writeApplyAuditEvent({
            supabase,
            userId: user.id,
            normalized,
            requestId,
            idempotencyKey,
            event: 'apply_failed',
            success: false,
            details: {
              code: 'timeout',
              message: `Upstream /${action} request timed out`,
            },
          })
        }

        return errorResponse(
          {
            code: 'timeout',
            message: `Upstream /${action} request timed out`,
            retryable: true,
            requestId,
            idempotencyKey,
          },
          504,
        )
      }

      if (action === 'apply') {
        await writeApplyAuditEvent({
          supabase,
          userId: user.id,
          normalized,
          requestId,
          idempotencyKey,
          event: 'apply_failed',
          success: false,
          details: {
            code: 'upstream_error',
            message: `Failed to reach upstream /${action} endpoint`,
            error: String(error),
          },
        })
      }

      return errorResponse(
        {
          code: 'upstream_error',
          message: `Failed to reach upstream /${action} endpoint`,
          retryable: true,
          requestId,
          idempotencyKey,
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
      if (action === 'apply') {
        await writeApplyAuditEvent({
          supabase,
          userId: user.id,
          normalized,
          requestId,
          idempotencyKey,
          event: 'apply_failed',
          success: false,
          details: {
            code: 'upstream_error',
            status: upstreamResponse.status,
            body: upstreamBody,
          },
          diffFingerprint: fingerprintValue(upstreamBody),
        })
      }

      return errorResponse(
        {
          code: 'upstream_error',
          message: `Upstream /${action} returned a non-success status`,
          retryable:
            upstreamResponse.status === 408 ||
            upstreamResponse.status === 429 ||
            upstreamResponse.status >= 500,
          requestId,
          idempotencyKey,
          details: {
            status: upstreamResponse.status,
            body: upstreamBody,
          },
        },
        upstreamResponse.status,
      )
    }

    if (action === 'apply') {
      let appliedFilesFingerprint: string | undefined
      try {
        const parsed = JSON.parse(upstreamBody)
        const files = parsed?.files
        if (files && typeof files === 'object') {
          appliedFilesFingerprint = fingerprintValue(Object.keys(files as Record<string, unknown>).sort())
        }
      } catch (_) {
        // Keep fallback fingerprint below.
      }

      await writeApplyAuditEvent({
        supabase,
        userId: user.id,
        normalized,
        requestId,
        idempotencyKey,
        event: 'apply_completed',
        success: true,
        details: {
          status: upstreamResponse.status,
        },
        appliedFilesFingerprint,
        diffFingerprint: fingerprintValue(upstreamBody),
      })
    }

    return new Response(upstreamBody, {
      status: upstreamResponse.status,
      headers: {
        ...corsHeaders,
        'Content-Type': contentType,
        'x-request-id': requestId,
        'x-idempotency-key': idempotencyKey,
      },
    })
  } catch (error) {
    if (error instanceof Error && error.message.startsWith('missing_endpoint_env:')) {
      return errorResponse(
        {
          code: 'config_error',
          message: error.message,
          retryable: false,
          requestId,
          idempotencyKey,
        },
        500,
      )
    }

    console.error('mirror_compute forwarding error:', error)
    return errorResponse(
      {
        code: 'internal_error',
        message: 'Internal server error',
        retryable: false,
        requestId,
        idempotencyKey,
        details: String(error),
      },
      500,
    )
  }
})
