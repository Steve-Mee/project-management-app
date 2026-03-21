// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
// Mirror Gateway forwarding function (thin proxy only).
// Forwards authenticated requests to HTTP POST /compile backends with timeout,
// retries handled upstream, and structured error responses.
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders } from '../_shared/cors.ts'

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
  requestId: string
  traceId: string
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

interface IdempotencyRecord {
  user_id: string
  action: 'compile' | 'apply'
  idempotency_key: string
  request_hash: string
  request_id: string
  status: 'processing' | 'completed' | 'failed'
  response_status: number | null
  response_body: string | null
  response_content_type: string | null
  expires_at: string
  created_at: string | null
  updated_at: string | null
}

interface IdempotencyClaimResult {
  kind: 'claimed' | 'replay' | 'in_progress' | 'conflict'
  record?: IdempotencyRecord
}

type MirrorUsageStatus = 'success' | 'failed' | 'rate_limited' | 'timeout' | 'upstream_error'

function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...buildCorsHeaders(req), 'Content-Type': 'application/json' },
  })
}

function errorResponse(req: Request, error: StructuredError, status: number): Response {
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

function buildStructuredError({
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

function buildAuditErrorDetails(
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

async function hasCloudMirrorAccess(
  supabase: ReturnType<typeof createClient>,
  requestId: string,
): Promise<boolean> {
  const { data, error } = await supabase.rpc('has_cloud_mirror_access')

  if (error) {
    throw new Error(`cloud_entitlement_rpc_failed:${error.message}`)
  }

  if (typeof data === 'boolean') {
    return data
  }

  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>
    const shapedValue = record['has_access'] ?? record['allowed'] ?? record['result']
    if (typeof shapedValue === 'boolean') {
      return shapedValue
    }
  }

  throw new Error(`cloud_entitlement_rpc_invalid_shape:request_id=${requestId}`)
}

function resolveForwardEndpoint(mode: 'private' | 'cloud', action: 'compile' | 'apply'): string {
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

async function hasUseMirrorPermission(
  supabase: ReturnType<typeof createClient>,
): Promise<boolean> {
  const { data, error } = await supabase.rpc('has_permission', {
    permission_name: 'use_mirror',
  })

  if (error) {
    throw new Error(`permission_rpc_failed:${error.message}`)
  }

  return data === true
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

function resolveRequestId(req: Request): string {
  const direct = req.headers.get('x-request-id') ?? req.headers.get('request-id')
  if (direct && direct.trim().length > 0) {
    return direct.trim()
  }
  return `gateway-${Date.now().toString(36)}-${crypto.randomUUID()}`
}

function resolveTraceId(req: Request, requestId: string): string {
  const direct = req.headers.get('x-trace-id') ?? req.headers.get('trace-id')
  if (direct && direct.trim().length > 0) {
    return direct.trim()
  }
  return `trace-${requestId}`
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

async function fingerprintValueSha256(value: unknown): Promise<string> {
  const raw = stableStringify(value)
  const bytes = new TextEncoder().encode(raw)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  const hex = Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('')
  return `sha256:${hex}`
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
        ids.add(normalizeArtifactId(value.trim()))
      }
    }
  }
  return Array.from(ids)
}

function normalizeArtifactId(rawValue: string): string {
  if (!rawValue.startsWith('http://') && !rawValue.startsWith('https://')) {
    return rawValue
  }

  try {
    const parsed = new URL(rawValue)
    return `${parsed.origin}${parsed.pathname}`
  } catch {
    const queryIndex = rawValue.indexOf('?')
    return queryIndex >= 0 ? rawValue.slice(0, queryIndex) : rawValue
  }
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
const MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES = 64 * 1024
const DEFAULT_IDEMPOTENCY_TTL_SECONDS = 120
const IDEMPOTENCY_PROCESSING_STALE_SECONDS = 300
const IDEMPOTENCY_ALLOWED_STATUSES = ['processing', 'completed', 'failed'] as const

const DEFAULT_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE = 10
const DEFAULT_GATEWAY_RATE_LIMIT_BURST = 30
const DEFAULT_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS = 180
const DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE = 1
const DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY = 2
const DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE = 20
const DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST = 50
const RATE_LIMIT_COUNTABLE_STATUSES = ['processing', 'completed'] as const
const DEFAULT_GATEWAY_CIRCUIT_BREAKER_FAILURE_THRESHOLD = 5
const DEFAULT_GATEWAY_CIRCUIT_BREAKER_OPEN_SECONDS = 30

interface UpstreamCircuitBreakerState {
  consecutiveFailures: number
  openUntilMs: number | null
  halfOpenProbeActive: boolean
}

const upstreamCircuitBreakerState: UpstreamCircuitBreakerState = {
  consecutiveFailures: 0,
  openUntilMs: null,
  halfOpenProbeActive: false,
}

interface PerUserRateLimitCheckResult {
  allowed: boolean
  reason?: 'minute_rate' | 'burst_quota' | 'weighted_minute' | 'weighted_burst'
  retryAfterSeconds?: number
  minuteCount: number
  burstCount: number
  weightedMinuteUnits: number
  weightedBurstUnits: number
  weightedMinuteLimit: number
  weightedBurstLimit: number
}

type UpstreamFailureClass =
  | 'request_timeout'
  | 'transport_error'
  | 'upstream_timeout'
  | 'upstream_rate_limited'
  | 'upstream_client_error'
  | 'upstream_server_error'
  | 'upstream_unknown_error'

function logIdempotencyStatusContractOnColdStart(): void {
  const allowsProcessing = IDEMPOTENCY_ALLOWED_STATUSES.includes('processing')

  if (!allowsProcessing) {
    throw new Error('idempotency_status_contract_invalid:processing_missing')
  }

  console.info('mirror-gateway cold start idempotency status contract', {
    allowedStatuses: IDEMPOTENCY_ALLOWED_STATUSES,
  })
}

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
    console.error('mirror-gateway apply audit write failed:', error.message)
  }
}

async function writeMirrorUsageLog({
  supabase,
  userId,
  normalized,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  normalized: MirrorComputeRequest
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number
}): Promise<void> {
  const payload = {
    user_id: userId,
    project_id: normalized.projectId,
    task_id: normalized.taskId,
    mode: normalized.mode,
    action,
    duration_ms: Math.max(0, Date.now() - startedAtMs),
    status,
    request_id: requestId,
    idempotency_key: idempotencyKey,
  }

  const { error } = await supabase.from('mirror_usage_logs').insert(payload)
  if (error) {
    console.error('mirror-gateway usage metering write failed:', error.message)
  }
}

async function writeMirrorUsageLogIfReady({
  supabase,
  userId,
  normalized,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: ReturnType<typeof createClient> | null
  userId: string | null
  normalized: MirrorComputeRequest | null
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number | null
}): Promise<void> {
  if (!supabase || !userId || !normalized || startedAtMs == null) {
    return
  }

  await writeMirrorUsageLog({
    supabase,
    userId,
    normalized,
    action,
    status,
    requestId,
    idempotencyKey,
    startedAtMs,
  })
}

function idempotencyTtlSeconds(): number {
  const raw = Deno.env.get('MIRROR_IDEMPOTENCY_TTL_SECONDS')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed >= 30 && parsed <= 3600) {
    return parsed
  }
  return DEFAULT_IDEMPOTENCY_TTL_SECONDS
}

function idempotencyExpiresAtIso(): string {
  return new Date(Date.now() + idempotencyTtlSeconds() * 1000).toISOString()
}

function isExpiredIso(iso: string | undefined): boolean {
  if (!iso) {
    return true
  }

  const parsed = Date.parse(iso)
  if (Number.isNaN(parsed)) {
    return true
  }

  return parsed <= Date.now()
}

function parseRequestTimestamp(record: Pick<IdempotencyRecord, 'request_id' | 'created_at' | 'updated_at'>): number | null {
  const parseIsoTimestamp = (value: string | null | undefined): number | null => {
    if (!value) {
      return null
    }

    const parsed = Date.parse(value)
    if (Number.isNaN(parsed)) {
      return null
    }

    return parsed
  }

  // Prefer DB timestamps since request_id format is not guaranteed for all clients.
  const updatedAt = parseIsoTimestamp(record.updated_at)
  if (updatedAt != null) {
    return updatedAt
  }

  const createdAt = parseIsoTimestamp(record.created_at)
  if (createdAt != null) {
    return createdAt
  }

  const requestId = record.request_id
  if (!requestId) {
    return null
  }

  const compileMatch = requestId.match(/^compile-(\d{6,})$/)
  if (compileMatch && compileMatch[1]) {
    const parsed = Number.parseInt(compileMatch[1], 10)
    if (Number.isFinite(parsed)) {
      // compile request_id was generated using microseconds.
      return Math.floor(parsed / 1000)
    }
  }

  const gatewayMatch = requestId.match(/^gateway-([0-9a-z]+)-/)
  if (gatewayMatch && gatewayMatch[1]) {
    const parsed = Number.parseInt(gatewayMatch[1], 36)
    if (Number.isFinite(parsed)) {
      // gateway request_id embeds Date.now().toString(36).
      return parsed
    }
  }

  return null
}

function isProcessingClaimStale(record: IdempotencyRecord): boolean {
  if (record.status !== 'processing') {
    return false
  }

  const timestamp = parseRequestTimestamp(record)
  if (timestamp == null) {
    return false
  }

  return Date.now() - timestamp > IDEMPOTENCY_PROCESSING_STALE_SECONDS * 1000
}

async function resetIdempotencyKeyClaim({
  supabase,
  userId,
  action,
  idempotencyKey,
  requestHash,
  requestId,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  action: 'compile' | 'apply'
  idempotencyKey: string
  requestHash: string
  requestId: string
}): Promise<boolean> {
  const { data, error } = await supabase
    .from('mirror_request_idempotency')
    .update({
      request_hash: requestHash,
      request_id: requestId,
      status: 'processing',
      response_status: null,
      response_body: null,
      response_content_type: null,
      expires_at: idempotencyExpiresAtIso(),
    })
    .eq('user_id', userId)
    .eq('action', action)
    .eq('idempotency_key', idempotencyKey)
    .select('request_id')

  if (error) {
    throw new Error(`idempotency_reset_failed:${error.message}`)
  }

  return Array.isArray(data) && data.length > 0
}

function normalizeResponseBodyForStore(rawBody: string): string {
  const bytes = new TextEncoder().encode(rawBody)
  if (bytes.length <= MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES) {
    return rawBody
  }

  const clipped = bytes.slice(0, MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES)
  return new TextDecoder().decode(clipped)
}

async function buildIdempotencyRequestHash(
  userId: string,
  action: 'compile' | 'apply',
  normalized: MirrorComputeRequest,
): Promise<string> {
  return fingerprintValueSha256({
    userId,
    action,
    mode: normalized.mode,
    projectId: normalized.projectId,
    taskId: normalized.taskId,
    prompt: normalized.prompt,
    files: normalized.files ?? {},
    metadata: normalized.metadata ?? {},
    actorUserId: normalized.actorUserId ?? null,
    backupId: normalized.backupId ?? null,
    fileSetFingerprint: normalized.fileSetFingerprint ?? null,
    signedInputUrls: normalizeSignedInputUrls(normalized.signedInputUrls),
  })
}

async function claimIdempotencyKey({
  supabase,
  userId,
  action,
  idempotencyKey,
  requestHash,
  requestId,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  action: 'compile' | 'apply'
  idempotencyKey: string
  requestHash: string
  requestId: string
}): Promise<IdempotencyClaimResult> {
  const { data: existing, error: selectError } = await supabase
    .from('mirror_request_idempotency')
    .select(
      'user_id,action,idempotency_key,request_hash,request_id,status,response_status,response_body,response_content_type,expires_at,created_at,updated_at',
    )
    .eq('user_id', userId)
    .eq('action', action)
    .eq('idempotency_key', idempotencyKey)
    .maybeSingle<IdempotencyRecord>()

  if (selectError) {
    throw new Error(`idempotency_select_failed:${selectError.message}`)
  }

  if (existing) {
    const expired = isExpiredIso(existing.expires_at)
    const staleProcessing = isProcessingClaimStale(existing)

    if (existing.request_hash !== requestHash) {
      if (expired || staleProcessing) {
        await resetIdempotencyKeyClaim({
          supabase,
          userId,
          action,
          idempotencyKey,
          requestHash,
          requestId,
        })
        return { kind: 'claimed' }
      }

      return { kind: 'conflict', record: existing }
    }

    if ((existing.status === 'completed' || existing.status === 'failed') && !expired) {
      return { kind: 'replay', record: existing }
    }

    if (!expired && existing.status === 'processing' && !staleProcessing) {
      return { kind: 'in_progress', record: existing }
    }

    await resetIdempotencyKeyClaim({
      supabase,
      userId,
      action,
      idempotencyKey,
      requestHash,
      requestId,
    })
    return { kind: 'claimed' }
  }

  const { error: insertError } = await supabase.from('mirror_request_idempotency').insert({
    user_id: userId,
    action,
    idempotency_key: idempotencyKey,
    request_hash: requestHash,
    request_id: requestId,
    status: 'processing',
    expires_at: idempotencyExpiresAtIso(),
  })

  if (insertError) {
    const message = insertError.message.toLowerCase()
    if (message.includes('duplicate') || message.includes('unique')) {
      const { data: raceWinner, error: raceSelectError } = await supabase
        .from('mirror_request_idempotency')
        .select(
          'user_id,action,idempotency_key,request_hash,request_id,status,response_status,response_body,response_content_type,expires_at,created_at,updated_at',
        )
        .eq('user_id', userId)
        .eq('action', action)
        .eq('idempotency_key', idempotencyKey)
        .maybeSingle<IdempotencyRecord>()

      if (raceSelectError) {
        throw new Error(`idempotency_select_failed:${raceSelectError.message}`)
      }

      if (raceWinner) {
        const expired = isExpiredIso(raceWinner.expires_at)
        const staleProcessing = isProcessingClaimStale(raceWinner)

        if (raceWinner.request_hash !== requestHash) {
          if (expired || staleProcessing) {
            await resetIdempotencyKeyClaim({
              supabase,
              userId,
              action,
              idempotencyKey,
              requestHash,
              requestId,
            })
            return { kind: 'claimed' }
          }

          return { kind: 'conflict', record: raceWinner }
        }

        if ((raceWinner.status === 'completed' || raceWinner.status === 'failed') && !expired) {
          return { kind: 'replay', record: raceWinner }
        }

        if (!expired && raceWinner.status === 'processing' && !staleProcessing) {
          return { kind: 'in_progress', record: raceWinner }
        }

        await resetIdempotencyKeyClaim({
          supabase,
          userId,
          action,
          idempotencyKey,
          requestHash,
          requestId,
        })
        return { kind: 'claimed' }
      }
    }

    throw new Error(`idempotency_insert_failed:${insertError.message}`)
  }

  return { kind: 'claimed' }
}

async function finalizeIdempotencyKey({
  supabase,
  userId,
  action,
  idempotencyKey,
  requestId,
  requestHash,
  status,
  responseStatus,
  responseBody,
  responseContentType,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  action: 'compile' | 'apply'
  idempotencyKey: string
  requestId: string
  requestHash: string
  status: 'completed' | 'failed'
  responseStatus: number
  responseBody: string
  responseContentType: string
}): Promise<void> {
  const { data, error } = await supabase
    .from('mirror_request_idempotency')
    .update({
      status,
      request_id: requestId,
      request_hash: requestHash,
      response_status: responseStatus,
      response_body: normalizeResponseBodyForStore(responseBody),
      response_content_type: responseContentType,
      expires_at: idempotencyExpiresAtIso(),
    })
    .eq('user_id', userId)
    .eq('action', action)
    .eq('idempotency_key', idempotencyKey)
    .eq('request_id', requestId)
    .eq('request_hash', requestHash)
    .eq('status', 'processing')
    .select('request_id')

  if (error) {
    throw new Error(`idempotency_update_failed:${error.message}`)
  }

  if (!Array.isArray(data) || data.length === 0) {
    throw new Error('idempotency_update_conflict:no_matching_processing_claim')
  }
}

function parsePositiveIntegerEnv(key: string, fallback: number): number {
  const raw = Deno.env.get(key)
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return fallback
}

function parsePositiveNumberEnv(key: string, fallback: number): number {
  const raw = Deno.env.get(key)
  const parsed = raw ? Number.parseFloat(raw) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return fallback
}

function gatewayRateLimitRequestsPerMinute(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE',
    DEFAULT_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE,
  )
}

function gatewayRateLimitBurst(): number {
  return parsePositiveIntegerEnv('MIRROR_GATEWAY_RATE_LIMIT_BURST', DEFAULT_GATEWAY_RATE_LIMIT_BURST)
}

function gatewayRateLimitBurstWindowSeconds(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS',
    DEFAULT_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS,
  )
}

function gatewayRateLimitActionWeight(action: 'compile' | 'apply'): number {
  return action === 'apply'
    ? parsePositiveNumberEnv(
        'MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY',
        DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY,
      )
    : parsePositiveNumberEnv(
        'MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE',
        DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE,
      )
}

function gatewayRateLimitWeightedUnitsPerMinute(): number {
  return parsePositiveNumberEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE',
    DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE,
  )
}

function gatewayRateLimitWeightedUnitsBurst(): number {
  return parsePositiveNumberEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST',
    DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST,
  )
}

function gatewayCircuitBreakerFailureThreshold(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_CIRCUIT_BREAKER_FAILURE_THRESHOLD',
    DEFAULT_GATEWAY_CIRCUIT_BREAKER_FAILURE_THRESHOLD,
  )
}

function gatewayCircuitBreakerOpenSeconds(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_CIRCUIT_BREAKER_OPEN_SECONDS',
    DEFAULT_GATEWAY_CIRCUIT_BREAKER_OPEN_SECONDS,
  )
}

function classifyUpstreamStatusFailure(status: number): UpstreamFailureClass {
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

function logRateLimitDecision({
  requestId,
  traceId,
  userId,
  action,
  allowed,
  reason,
  minuteCount,
  burstCount,
  minuteLimit,
  burstLimit,
  weightedMinuteUnits,
  weightedBurstUnits,
  weightedMinuteLimit,
  weightedBurstLimit,
  actionWeight,
  burstWindowSeconds,
  minuteWindowStart,
  burstWindowStart,
  evaluatedAt,
}: {
  requestId: string
  traceId: string
  userId: string
  action: 'compile' | 'apply'
  allowed: boolean
  reason?: PerUserRateLimitCheckResult['reason']
  minuteCount: number
  burstCount: number
  minuteLimit: number
  burstLimit: number
  weightedMinuteUnits: number
  weightedBurstUnits: number
  weightedMinuteLimit: number
  weightedBurstLimit: number
  actionWeight: number
  burstWindowSeconds: number
  minuteWindowStart: string
  burstWindowStart: string
  evaluatedAt: string
}): void {
  console.info('mirror-gateway rate limit decision', {
    requestId,
    traceId,
    userId,
    action,
    allowed,
    reason: reason ?? null,
    evaluatedAt,
    minuteWindowStart,
    burstWindowStart,
    observedRequestsLastMinute: minuteCount,
    observedRequestsInBurstWindow: burstCount,
    weightedUnitsLastMinute: weightedMinuteUnits,
    weightedUnitsInBurstWindow: weightedBurstUnits,
    actionWeight,
    maxRequestsPerMinute: minuteLimit,
    burstLimit,
    weightedUnitsPerMinuteLimit: weightedMinuteLimit,
    weightedBurstLimit,
    burstWindowSeconds,
    countableStatuses: RATE_LIMIT_COUNTABLE_STATUSES,
  })
}

function logCircuitBreakerDecision({
  requestId,
  traceId,
  action,
  mode,
  allowed,
  reason,
  retryAfterSeconds,
}: {
  requestId: string
  traceId: string
  action: 'compile' | 'apply'
  mode: 'private' | 'cloud'
  allowed: boolean
  reason: 'closed' | 'half_open_probe' | 'open'
  retryAfterSeconds?: number
}): void {
  console.info('mirror-gateway circuit breaker decision', {
    requestId,
    traceId,
    action,
    mode,
    allowed,
    reason,
    retryAfterSeconds: retryAfterSeconds ?? null,
    consecutiveFailures: upstreamCircuitBreakerState.consecutiveFailures,
    openUntilMs: upstreamCircuitBreakerState.openUntilMs,
    halfOpenProbeActive: upstreamCircuitBreakerState.halfOpenProbeActive,
  })
}

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

function redactForObservability(value: unknown, depth = 0): unknown {
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
    output[key] = sensitiveKeyPattern.test(key)
      ? '[redacted]'
      : redactForObservability(nested, depth + 1)
  }
  return output
}

function sanitizeUpstreamBodyForErrorDetails(upstreamBody: string): unknown {
  try {
    const parsed = JSON.parse(upstreamBody)
    return redactForObservability(parsed)
  } catch {
    return redactPotentialSecretString(upstreamBody)
  }
}

function logUpstreamFailureEvent({
  requestId,
  traceId,
  action,
  mode,
  failureClass,
  status,
  retryable,
  stage,
  details,
}: {
  requestId: string
  traceId: string
  action: 'compile' | 'apply'
  mode: 'private' | 'cloud'
  failureClass: UpstreamFailureClass
  status: number | null
  retryable: boolean
  stage: string
  details?: unknown
}): void {
  console.warn('mirror-gateway upstream failure', {
    requestId,
    traceId,
    action,
    mode,
    failureClass,
    upstreamStatus: status,
    retryable,
    stage,
    details: redactForObservability(details),
  })
}

async function checkPerUserRateLimit(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  action: 'compile' | 'apply',
): Promise<PerUserRateLimitCheckResult> {
  const minuteLimit = gatewayRateLimitRequestsPerMinute()
  const burstLimit = gatewayRateLimitBurst()
  const burstWindowSeconds = gatewayRateLimitBurstWindowSeconds()

  const nowIso = new Date().toISOString()
  const oneMinuteAgo = new Date(Date.now() - 60 * 1000).toISOString()
  const burstWindowStart = new Date(Date.now() - burstWindowSeconds * 1000).toISOString()

  const [minuteCount, burstCount] = await Promise.all([
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action,
      nowIso,
      windowStartIso: oneMinuteAgo,
      errorCode: 'rate_limit_minute_check_failed',
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action,
      nowIso,
      windowStartIso: burstWindowStart,
      errorCode: 'rate_limit_burst_check_failed',
    }),
  ])

  const [minuteCompileCount, minuteApplyCount, burstCompileCount, burstApplyCount] = await Promise.all([
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'compile',
      nowIso,
      windowStartIso: oneMinuteAgo,
      errorCode: 'rate_limit_weighted_minute_compile_check_failed',
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'apply',
      nowIso,
      windowStartIso: oneMinuteAgo,
      errorCode: 'rate_limit_weighted_minute_apply_check_failed',
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'compile',
      nowIso,
      windowStartIso: burstWindowStart,
      errorCode: 'rate_limit_weighted_burst_compile_check_failed',
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'apply',
      nowIso,
      windowStartIso: burstWindowStart,
      errorCode: 'rate_limit_weighted_burst_apply_check_failed',
    }),
  ])

  const safeMinuteCount = minuteCount
  const safeBurstCount = burstCount
  const compileWeight = gatewayRateLimitActionWeight('compile')
  const applyWeight = gatewayRateLimitActionWeight('apply')
  const weightedMinuteLimit = gatewayRateLimitWeightedUnitsPerMinute()
  const weightedBurstLimit = gatewayRateLimitWeightedUnitsBurst()
  const weightedMinuteUnits = minuteCompileCount * compileWeight + minuteApplyCount * applyWeight
  const weightedBurstUnits = burstCompileCount * compileWeight + burstApplyCount * applyWeight

  if (safeMinuteCount >= minuteLimit) {
    return {
      allowed: false,
      reason: 'minute_rate',
      retryAfterSeconds: 60,
      minuteCount: safeMinuteCount,
      burstCount: safeBurstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (safeBurstCount >= burstLimit) {
    return {
      allowed: false,
      reason: 'burst_quota',
      retryAfterSeconds: burstWindowSeconds,
      minuteCount: safeMinuteCount,
      burstCount: safeBurstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (weightedMinuteUnits >= weightedMinuteLimit) {
    return {
      allowed: false,
      reason: 'weighted_minute',
      retryAfterSeconds: 60,
      minuteCount: safeMinuteCount,
      burstCount: safeBurstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (weightedBurstUnits >= weightedBurstLimit) {
    return {
      allowed: false,
      reason: 'weighted_burst',
      retryAfterSeconds: burstWindowSeconds,
      minuteCount: safeMinuteCount,
      burstCount: safeBurstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  return {
    allowed: true,
    minuteCount: safeMinuteCount,
    burstCount: safeBurstCount,
    weightedMinuteUnits,
    weightedBurstUnits,
    weightedMinuteLimit,
    weightedBurstLimit,
  }
}

async function countRateLimitRequestsInWindow({
  supabase,
  userId,
  action,
  nowIso,
  windowStartIso,
  errorCode,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  action: 'compile' | 'apply'
  nowIso: string
  windowStartIso: string
  errorCode: string
}): Promise<number> {
  const { count, error } = await supabase
    .from('mirror_request_idempotency')
    .select('*', { head: true, count: 'exact' })
    .eq('user_id', userId)
    .eq('action', action)
    .in('status', [...RATE_LIMIT_COUNTABLE_STATUSES])
    .gt('expires_at', nowIso)
    .gte('created_at', windowStartIso)

  if (error) {
    throw new Error(`${errorCode}:${error.message}`)
  }

  return count ?? 0
}

function evaluateCircuitBreakerAllowance(): {
  allowed: boolean
  reason: 'closed' | 'half_open_probe' | 'open'
  retryAfterSeconds?: number
} {
  const now = Date.now()
  const openUntil = upstreamCircuitBreakerState.openUntilMs
  if (openUntil != null && openUntil > now) {
    return {
      allowed: false,
      reason: 'open',
      retryAfterSeconds: Math.max(1, Math.ceil((openUntil - now) / 1000)),
    }
  }

  if (openUntil != null && openUntil <= now) {
    if (upstreamCircuitBreakerState.halfOpenProbeActive) {
      return {
        allowed: false,
        reason: 'open',
        retryAfterSeconds: 1,
      }
    }
    upstreamCircuitBreakerState.halfOpenProbeActive = true
    return {
      allowed: true,
      reason: 'half_open_probe',
    }
  }

  return {
    allowed: true,
    reason: 'closed',
  }
}

function registerUpstreamSuccess(): void {
  upstreamCircuitBreakerState.consecutiveFailures = 0
  upstreamCircuitBreakerState.openUntilMs = null
  upstreamCircuitBreakerState.halfOpenProbeActive = false
}

function registerUpstreamFailure(): void {
  const threshold = gatewayCircuitBreakerFailureThreshold()
  const openSeconds = gatewayCircuitBreakerOpenSeconds()
  const now = Date.now()

  if (upstreamCircuitBreakerState.halfOpenProbeActive) {
    upstreamCircuitBreakerState.openUntilMs = now + openSeconds * 1000
    upstreamCircuitBreakerState.halfOpenProbeActive = false
    upstreamCircuitBreakerState.consecutiveFailures = threshold
    return
  }

  upstreamCircuitBreakerState.consecutiveFailures += 1
  if (upstreamCircuitBreakerState.consecutiveFailures >= threshold) {
    upstreamCircuitBreakerState.openUntilMs = now + openSeconds * 1000
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

logIdempotencyStatusContractOnColdStart()

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  const requestId = resolveRequestId(req)
  const traceId = resolveTraceId(req, requestId)
  const idempotencyKey = resolveIdempotencyKey(req)
  const action = resolveActionFromPath(new URL(req.url).pathname)
  let usageSupabase: ReturnType<typeof createClient> | null = null
  let usageUserId: string | null = null
  let usageNormalized: MirrorComputeRequest | null = null
  let usageStartedAtMs: number | null = null

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: buildCorsHeaders(req) })
  }

  if (req.method !== 'POST') {
    return errorResponse(req,
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

  if (!action) {
    return errorResponse(req,
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
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(req,
        buildStructuredError({
          code: 'unauthorized',
          message: 'Missing or invalid authorization header',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'authentication',
        }),
        401,
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    if (!supabaseUrl || !supabaseAnonKey) {
      return errorResponse(req,
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
      global: { headers: { Authorization: authHeader } },
    })
    usageSupabase = supabase

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return errorResponse(req,
        buildStructuredError({
          code: 'unauthorized',
          message: 'Unauthorized',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'authentication',
        }),
        401,
      )
    }
    usageUserId = user.id

    let rawBody: Partial<MirrorComputeRequest>
    try {
      rawBody = await parseRequestJsonWithLimit(req)
    } catch (error) {
      if (error instanceof Error && error.message.startsWith('payload_too_large:')) {
        return errorResponse(req,
          buildStructuredError({
            code: 'payload_too_large',
            message: `Request body exceeds ${MAX_REQUEST_BODY_BYTES} bytes limit`,
            retryable: false,
            requestId,
            traceId,
            idempotencyKey,
            stage: 'request_validation',
          }),
          413,
        )
      }

      if (error instanceof Error && error.message === 'bad_json') {
        return errorResponse(req,
          buildStructuredError({
            code: 'bad_request',
            message: 'Invalid JSON body',
            retryable: false,
            requestId,
            traceId,
            idempotencyKey,
            stage: 'request_validation',
          }),
          400,
        )
      }

      throw error
    }

    const normalized = normalizeRequestBody(rawBody)
    if (!normalized) {
      return errorResponse(req,
        buildStructuredError({
          code: 'bad_request',
          message: 'Missing or invalid fields: prompt, projectId, taskId, mode',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'request_validation',
        }),
        400,
      )
    }
    const startedAtMs = Date.now()
    usageNormalized = normalized
    usageStartedAtMs = startedAtMs

    let canUseMirror = false
    try {
      canUseMirror = await hasUseMirrorPermission(supabase)
    } catch (error) {
      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs,
      })
      return errorResponse(req,
        buildStructuredError({
          code: 'unauthorized',
          message: 'Mirror permission check failed',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          details: String(error),
          stage: 'authorization',
        }),
        403,
      )
    }

    if (!canUseMirror) {
      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs,
      })
      return errorResponse(req,
        buildStructuredError({
          code: 'unauthorized',
          message: 'Insufficient permissions: use_mirror required',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'authorization',
        }),
        403,
      )
    }

    if (normalized.mode === 'cloud') {
      let hasCloudEntitlement = false
      try {
        hasCloudEntitlement = await hasCloudMirrorAccess(supabase, requestId)
      } catch (error) {
        await writeMirrorUsageLog({
          supabase,
          userId: user.id,
          normalized,
          action,
          status: 'failed',
          requestId,
          idempotencyKey,
          startedAtMs,
        })
        return errorResponse(req,
          buildStructuredError({
            code: 'forbidden',
            message: 'Cloud Mirror mode requires successful cloud entitlement verification',
            retryable: false,
            requestId,
            traceId,
            idempotencyKey,
            details: {
              mode: normalized.mode,
              entitlement: 'cloud_mirror_access',
              reason: 'rpc_failed',
              cause: String(error),
              authority: 'rpc_only',
              environment: (Deno.env.get('SUPABASE_ENV') ?? 'unknown').trim() || 'unknown',
            },
            stage: 'authorization',
          }),
          403,
        )
      }

      if (!hasCloudEntitlement) {
        await writeMirrorUsageLog({
          supabase,
          userId: user.id,
          normalized,
          action,
          status: 'failed',
          requestId,
          idempotencyKey,
          startedAtMs,
        })
        return errorResponse(req,
          buildStructuredError({
            code: 'forbidden',
            message: 'Cloud Mirror mode requires an active premium cloud entitlement',
            retryable: false,
            requestId,
            traceId,
            idempotencyKey,
            details: {
              mode: normalized.mode,
              entitlement: 'cloud_mirror_access',
              reason: 'rpc_false',
              authority: 'rpc_only',
            },
            stage: 'authorization',
          }),
          403,
        )
      }
    }

    const idempotencyRequestHash = await buildIdempotencyRequestHash(user.id, action, normalized)
    let idempotencyClaim: IdempotencyClaimResult
    try {
      idempotencyClaim = await claimIdempotencyKey({
        supabase,
        userId: user.id,
        action,
        idempotencyKey,
        requestHash: idempotencyRequestHash,
        requestId,
      })
    } catch (error) {
      if (error instanceof Error && error.message.startsWith('idempotency_')) {
        await writeMirrorUsageLog({
          supabase,
          userId: user.id,
          normalized,
          action,
          status: 'failed',
          requestId,
          idempotencyKey,
          startedAtMs,
        })
        return errorResponse(req,
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

    if (idempotencyClaim.kind === 'conflict') {
      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs,
      })
      return errorResponse(req,
        buildStructuredError({
          code: 'bad_request',
          message: 'Idempotency key reuse with different payload is not allowed',
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          details: {
            action,
            priorRequestId: idempotencyClaim.record?.request_id,
          },
          stage: 'idempotency',
        }),
        409,
      )
    }

    if (idempotencyClaim.kind === 'in_progress') {
      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs,
      })
      return errorResponse(req,
        buildStructuredError({
          code: 'bad_request',
          message: 'A request with this idempotency key is already processing',
          retryable: true,
          requestId,
          traceId,
          idempotencyKey,
          details: {
            action,
            priorRequestId: idempotencyClaim.record?.request_id,
          },
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
      const cachedContentType =
        idempotencyClaim.record.response_content_type ?? 'application/json'

      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: cachedStatus >= 200 && cachedStatus < 400 ? 'success' : 'failed',
        requestId,
        idempotencyKey,
        startedAtMs,
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

    let rateLimitCheck: PerUserRateLimitCheckResult
    try {
      rateLimitCheck = await checkPerUserRateLimit(supabase, user.id, action)
    } catch (error) {
      if (error instanceof Error && error.message.startsWith('rate_limit_')) {
        await writeMirrorUsageLog({
          supabase,
          userId: user.id,
          normalized,
          action,
          status: 'failed',
          requestId,
          idempotencyKey,
          startedAtMs,
        })
        return errorResponse(req,
          buildStructuredError({
            code: 'config_error',
            message: 'Rate limit check is unavailable',
            retryable: true,
            requestId,
            traceId,
            idempotencyKey,
            details: error.message,
            stage: 'rate_limit',
          }),
          500,
        )
      }
      throw error
    }

    const minuteLimit = gatewayRateLimitRequestsPerMinute()
    const burstLimit = gatewayRateLimitBurst()
    const weightedMinuteLimit = gatewayRateLimitWeightedUnitsPerMinute()
    const weightedBurstLimit = gatewayRateLimitWeightedUnitsBurst()
    const actionWeight = gatewayRateLimitActionWeight(action)
    const burstWindowSeconds = gatewayRateLimitBurstWindowSeconds()
    logRateLimitDecision({
      requestId,
      traceId,
      userId: user.id,
      action,
      allowed: rateLimitCheck.allowed,
      reason: rateLimitCheck.reason,
      minuteCount: rateLimitCheck.minuteCount,
      burstCount: rateLimitCheck.burstCount,
      minuteLimit,
      burstLimit,
      weightedMinuteUnits: rateLimitCheck.weightedMinuteUnits,
      weightedBurstUnits: rateLimitCheck.weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
      actionWeight,
      burstWindowSeconds,
      minuteWindowStart: new Date(Date.now() - 60 * 1000).toISOString(),
      burstWindowStart: new Date(Date.now() - burstWindowSeconds * 1000).toISOString(),
      evaluatedAt: new Date().toISOString(),
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
          maxRequestsPerMinute: minuteLimit,
          burstLimit,
          actionWeight,
          weightedUnitsLastMinute: rateLimitCheck.weightedMinuteUnits,
          weightedUnitsInBurstWindow: rateLimitCheck.weightedBurstUnits,
          weightedUnitsPerMinuteLimit: weightedMinuteLimit,
          weightedBurstLimit,
          burstWindowSeconds,
          observedRequestsLastMinute: rateLimitCheck.minuteCount,
          observedRequestsInBurstWindow: rateLimitCheck.burstCount,
          retryAfterSeconds,
        },
        stage: 'rate_limit',
      })

      const rateLimitBody = {
        success: false,
        error: rateLimitError,
      }

      try {
        await finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: 429,
          responseBody: JSON.stringify(rateLimitBody),
          responseContentType: 'application/json',
        })
      } catch (idempotencyError) {
        console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
      }

      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'rate_limited',
        requestId,
        idempotencyKey,
        startedAtMs,
      })

      return new Response(JSON.stringify(rateLimitBody), {
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

    const targetUrl = resolveForwardEndpoint(normalized.mode, action)
    const circuitBreakerDecision = evaluateCircuitBreakerAllowance()
    logCircuitBreakerDecision({
      requestId,
      traceId,
      action,
      mode: normalized.mode,
      allowed: circuitBreakerDecision.allowed,
      reason: circuitBreakerDecision.reason,
      retryAfterSeconds: circuitBreakerDecision.retryAfterSeconds,
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
        details: {
          reason: 'circuit_breaker_open',
          retryAfterSeconds,
        },
        stage: 'circuit_breaker',
      })

      try {
        await finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: 503,
          responseBody: JSON.stringify({
            success: false,
            error: breakerError,
          }),
          responseContentType: 'application/json',
        })
      } catch (idempotencyError) {
        console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
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
          details: buildAuditErrorDetails(breakerError),
        })
      }

      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'upstream_error',
        requestId,
        idempotencyKey,
        startedAtMs,
      })

      return new Response(
        JSON.stringify({
          success: false,
          error: breakerError,
        }),
        {
          status: 503,
          headers: {
            ...buildCorsHeaders(req),
            'Content-Type': 'application/json',
            'Retry-After': String(retryAfterSeconds),
            'x-request-id': requestId,
            'x-trace-id': traceId,
            'x-idempotency-key': idempotencyKey,
          },
        },
      )
    }

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
          source: 'mirror_gateway',
          filesCount: Object.keys(normalized.files ?? {}).length,
        },
      })
    }

    const normalizedForwardFields = normalizeForwardFields(normalized, user.id)
    const forwardMetadata: Record<string, unknown> = {
      ...(normalized.metadata ?? {}),
      requestId,
      traceId,
    }

    const payload: ForwardPayload = {
      prompt: normalized.prompt,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
      mode: normalized.mode,
      action,
      userId: user.id,
      files: normalized.files ?? {},
      metadata: forwardMetadata,
      requestId,
      traceId,
      actorUserId: normalizedForwardFields.actorUserId,
      backupId: normalizedForwardFields.backupId,
      fileSetFingerprint: normalizedForwardFields.fileSetFingerprint,
      signedInputUrls: normalizedForwardFields.signedInputUrls,
    }

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs())

    console.info('mirror-gateway forwarding request', {
      requestId,
      traceId,
      idempotencyKey,
      action,
      mode: normalized.mode,
      targetUrl,
      projectId: normalized.projectId,
      taskId: normalized.taskId,
    })

    let upstreamResponse: Response
    try {
      upstreamResponse = await fetch(targetUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: authHeader,
          'x-user-id': user.id,
          'x-request-id': requestId,
          'x-trace-id': traceId,
          'x-idempotency-key': idempotencyKey,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      })
    } catch (error) {
      clearTimeout(timeout)
      if (error instanceof DOMException && error.name === 'AbortError') {
        registerUpstreamFailure()
        const timeoutError = buildStructuredError({
          code: 'timeout',
          message: `Upstream /${action} request timed out`,
          retryable: true,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'forward',
        })
        logUpstreamFailureEvent({
          requestId,
          traceId,
          action,
          mode: normalized.mode,
          failureClass: 'request_timeout',
          status: null,
          retryable: true,
          stage: 'forward',
          details: { reason: 'abort_signal_timeout' },
        })
        try {
          await finalizeIdempotencyKey({
            supabase,
            userId: user.id,
            action,
            idempotencyKey,
            requestId,
            requestHash: idempotencyRequestHash,
            status: 'failed',
            responseStatus: 504,
            responseBody: JSON.stringify({
              success: false,
              error: timeoutError,
            }),
            responseContentType: 'application/json',
          })
        } catch (idempotencyError) {
          console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
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
            details: buildAuditErrorDetails(timeoutError),
          })
        }

        await writeMirrorUsageLog({
          supabase,
          userId: user.id,
          normalized,
          action,
          status: 'timeout',
          requestId,
          idempotencyKey,
          startedAtMs,
        })

        return errorResponse(req,
          timeoutError,
          504,
        )
      }

      registerUpstreamFailure()
      const upstreamTransportError = buildStructuredError({
        code: 'upstream_error',
        message: `Failed to reach upstream /${action} endpoint`,
        retryable: true,
        requestId,
        traceId,
        idempotencyKey,
        details: String(error),
        stage: 'forward',
      })
      logUpstreamFailureEvent({
        requestId,
        traceId,
        action,
        mode: normalized.mode,
        failureClass: 'transport_error',
        status: null,
        retryable: true,
        stage: 'forward',
        details: String(error),
      })

      try {
        await finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: 502,
          responseBody: JSON.stringify({
            success: false,
              error: upstreamTransportError,
          }),
          responseContentType: 'application/json',
        })
      } catch (idempotencyError) {
        console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
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
          details: buildAuditErrorDetails(upstreamTransportError),
        })
      }

      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'upstream_error',
        requestId,
        idempotencyKey,
        startedAtMs,
      })

      return errorResponse(req,
        upstreamTransportError,
        502,
      )
    } finally {
      clearTimeout(timeout)
    }

    const contentType = upstreamResponse.headers.get('content-type') ?? 'application/json'
    const upstreamBody = await upstreamResponse.text()

    if (!upstreamResponse.ok) {
      const upstreamFailureClass = classifyUpstreamStatusFailure(upstreamResponse.status)
      if (
        upstreamFailureClass === 'upstream_timeout' ||
        upstreamFailureClass === 'upstream_rate_limited' ||
        upstreamFailureClass === 'upstream_server_error' ||
        upstreamFailureClass === 'upstream_unknown_error'
      ) {
        registerUpstreamFailure()
      }
      const upstreamStatusError = buildStructuredError({
        code: 'upstream_error',
        message: `Upstream /${action} returned a non-success status`,
        retryable:
          upstreamResponse.status === 408 ||
          upstreamResponse.status === 429 ||
          upstreamResponse.status >= 500,
        requestId,
        traceId,
        idempotencyKey,
        details: {
          status: upstreamResponse.status,
          body: sanitizeUpstreamBodyForErrorDetails(upstreamBody),
        },
        upstreamStatus: upstreamResponse.status,
        stage: 'upstream',
      })
      logUpstreamFailureEvent({
        requestId,
        traceId,
        action,
        mode: normalized.mode,
        failureClass: upstreamFailureClass,
        status: upstreamResponse.status,
        retryable: upstreamStatusError.retryable,
        stage: 'upstream',
        details: { responseBodyBytes: new TextEncoder().encode(upstreamBody).length },
      })

      try {
        await finalizeIdempotencyKey({
          supabase,
          userId: user.id,
          action,
          idempotencyKey,
          requestId,
          requestHash: idempotencyRequestHash,
          status: 'failed',
          responseStatus: upstreamResponse.status,
          responseBody: upstreamBody,
          responseContentType: contentType,
        })
      } catch (idempotencyError) {
        console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
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
          details: buildAuditErrorDetails(upstreamStatusError),
          diffFingerprint: await fingerprintValueSha256(upstreamBody),
        })
      }

      await writeMirrorUsageLog({
        supabase,
        userId: user.id,
        normalized,
        action,
        status: 'upstream_error',
        requestId,
        idempotencyKey,
        startedAtMs,
      })

      return errorResponse(req,
        upstreamStatusError,
        upstreamResponse.status,
      )
    }

    registerUpstreamSuccess()

    try {
      await finalizeIdempotencyKey({
        supabase,
        userId: user.id,
        action,
        idempotencyKey,
        requestId,
        requestHash: idempotencyRequestHash,
        status: 'completed',
        responseStatus: upstreamResponse.status,
        responseBody: upstreamBody,
        responseContentType: contentType,
      })
    } catch (idempotencyError) {
      console.error('mirror-gateway idempotency finalize failed:', idempotencyError)
    }

    if (action === 'apply') {
      let appliedFilesFingerprint: string | undefined
      try {
        const parsed = JSON.parse(upstreamBody)
        const files = parsed?.files
        if (files && typeof files === 'object') {
          appliedFilesFingerprint = await fingerprintValueSha256(
            Object.keys(files as Record<string, unknown>).sort(),
          )
        }
      } catch (_) {
        // Keep fallback fingerprint below.
      }

      if (!appliedFilesFingerprint) {
        appliedFilesFingerprint = await fingerprintValueSha256(upstreamBody)
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
        diffFingerprint: await fingerprintValueSha256(upstreamBody),
      })
    }

    await writeMirrorUsageLog({
      supabase,
      userId: user.id,
      normalized,
      action,
      status: 'success',
      requestId,
      idempotencyKey,
      startedAtMs,
    })

    return new Response(upstreamBody, {
      status: upstreamResponse.status,
      headers: {
        ...buildCorsHeaders(req),
        'Content-Type': contentType,
        'x-request-id': requestId,
        'x-trace-id': traceId,
        'x-idempotency-key': idempotencyKey,
      },
    })
  } catch (error) {
    if (
      error instanceof Error &&
      (error.message.startsWith('missing_endpoint_env:') ||
        error.message.startsWith('unsupported_action_path_combination:'))
    ) {
      await writeMirrorUsageLogIfReady({
        supabase: usageSupabase,
        userId: usageUserId,
        normalized: usageNormalized,
        action: action ?? 'compile',
        status: 'failed',
        requestId,
        idempotencyKey,
        startedAtMs: usageStartedAtMs,
      })
      return errorResponse(req,
        buildStructuredError({
          code: 'config_error',
          message: error.message,
          retryable: false,
          requestId,
          traceId,
          idempotencyKey,
          stage: 'configuration',
        }),
        500,
      )
    }

    console.error('mirror-gateway forwarding error:', error)
    await writeMirrorUsageLogIfReady({
      supabase: usageSupabase,
      userId: usageUserId,
      normalized: usageNormalized,
      action: action ?? 'compile',
      status: 'failed',
      requestId,
      idempotencyKey,
      startedAtMs: usageStartedAtMs,
    })
    return errorResponse(req,
      buildStructuredError({
        code: 'internal_error',
        message: 'Internal server error',
        retryable: false,
        requestId,
        traceId,
        idempotencyKey,
        details: String(error),
        stage: 'internal',
      }),
      500,
    )
  }
})

