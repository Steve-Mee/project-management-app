// Idempotency handler: request deduplication and replay logic.
// Manages idempotency key lifecycle: claim → processing → finalize with replay capability.

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import type { MirrorComputeRequest } from './request_validator.ts'

type SupabaseClient = ReturnType<typeof createClient>

const DEFAULT_IDEMPOTENCY_TTL_SECONDS = 120
const IDEMPOTENCY_PROCESSING_STALE_SECONDS = 300
const MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES = 64 * 1024

export interface IdempotencyRecord {
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

export type IdempotencyClaimKind = 'claimed' | 'replay' | 'in_progress' | 'conflict'

export interface IdempotencyClaimResult {
  kind: IdempotencyClaimKind
  record?: IdempotencyRecord
}

export interface IdempotencyReplayResponse {
  status: number
  body: string
  contentType: string
  wasIdempotencyReplay: boolean
}

/**
 * Compute stable string representation for fingerprinting.
 * Used for idempotency request hash.
 */
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

/**
 * Fingerprint value using SHA256.
 */
export async function fingerprintValueSha256(value: unknown): Promise<string> {
  const raw = stableStringify(value)
  const bytes = new TextEncoder().encode(raw)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  const hex = Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('')
  return `sha256:${hex}`
}

/**
 * Build idempotency request hash from request parameters.
 */
export async function buildIdempotencyRequestHash(
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
    signedInputUrls: normalized.signedInputUrls ?? {},
  })
}

/**
 * Parse ISO timestamp from record, handling multiple sources.
 */
function parseRequestTimestamp(record: Pick<IdempotencyRecord, 'request_id' | 'created_at' | 'updated_at'>): number | null {
  const parseIsoTimestamp = (value: string | null | undefined): number | null => {
    if (!value) return null
    const parsed = Date.parse(value)
    return Number.isNaN(parsed) ? null : parsed
  }

  // Prefer DB timestamps
  const updatedAt = parseIsoTimestamp(record.updated_at)
  if (updatedAt != null) return updatedAt

  const createdAt = parseIsoTimestamp(record.created_at)
  if (createdAt != null) return createdAt

  // Fallback: extract from request_id if standard format
  const requestId = record.request_id
  if (!requestId) return null

  const compileMatch = requestId.match(/^compile-(\d{6,})$/)
  if (compileMatch && compileMatch[1]) {
    const parsed = Number.parseInt(compileMatch[1], 10)
    if (Number.isFinite(parsed)) {
      return Math.floor(parsed / 1000) // microseconds to ms
    }
  }

  const gatewayMatch = requestId.match(/^gateway-([0-9a-z]+)-/)
  if (gatewayMatch && gatewayMatch[1]) {
    const parsed = Number.parseInt(gatewayMatch[1], 36)
    if (Number.isFinite(parsed)) {
      return parsed
    }
  }

  return null
}

/**
 * Check if processing claim is stale (exceeds max processing time).
 */
function isProcessingClaimStale(record: IdempotencyRecord): boolean {
  if (record.status !== 'processing') return false

  const timestamp = parseRequestTimestamp(record)
  if (timestamp == null) return false

  return Date.now() - timestamp > IDEMPOTENCY_PROCESSING_STALE_SECONDS * 1000
}

/**
 * Check if idempotency record TTL is expired.
 */
function isExpiredIso(iso: string | undefined): boolean {
  if (!iso) return true
  const parsed = Date.parse(iso)
  if (Number.isNaN(parsed)) return true
  return parsed <= Date.now()
}

/**
 * Get idempotency TTL in seconds from environment or use default.
 */
function idempotencyTtlSeconds(): number {
  const raw = (globalThis as any).Deno?.env?.get?.('MIRROR_IDEMPOTENCY_TTL_SECONDS')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed >= 30 && parsed <= 3600) {
    return parsed
  }
  return DEFAULT_IDEMPOTENCY_TTL_SECONDS
}

/**
 * Calculate expiration timestamp for new idempotency record.
 */
function idempotencyExpiresAtIso(): string {
  return new Date(Date.now() + idempotencyTtlSeconds() * 1000).toISOString()
}

/**
 * Normalize response body for storage (clip if too large).
 */
function normalizeResponseBodyForStore(rawBody: string): string {
  const bytes = new TextEncoder().encode(rawBody)
  if (bytes.length <= MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES) {
    return rawBody
  }

  const clipped = bytes.slice(0, MAX_IDEMPOTENCY_RESPONSE_BODY_BYTES)
  return new TextDecoder().decode(clipped)
}

/**
 * Reset idempotency key claim to 'processing' state.
 * Used when key is reused with same hash after expiry/staleness.
 */
async function resetIdempotencyKeyClaim({
  supabase,
  userId,
  action,
  idempotencyKey,
  requestHash,
  requestId,
}: {
  supabase: SupabaseClient
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

/**
 * Claim idempotency key: attempt to reserve for this request.
 * Returns 'claimed' if new, 'replay' if completed, 'in_progress' if already processing,
 * or 'conflict' if hash mismatch and not yet recoverable.
 */
export async function claimIdempotencyKey({
  supabase,
  userId,
  action,
  idempotencyKey,
  requestHash,
  requestId,
}: {
  supabase: SupabaseClient
  userId: string
  action: 'compile' | 'apply'
  idempotencyKey: string
  requestHash: string
  requestId: string
}): Promise<IdempotencyClaimResult> {
  // Check if key already exists
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

    // Hash mismatch: conflict or recoverable?
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

    // Hash match: check status
    if ((existing.status === 'completed' || existing.status === 'failed') && !expired) {
      return { kind: 'replay', record: existing }
    }

    if (!expired && existing.status === 'processing' && !staleProcessing) {
      return { kind: 'in_progress', record: existing }
    }

    // Expired or stale: reset and claim
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

  // No existing record: insert new
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
      // Race condition: another request inserted first, retry select
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

// ---------------------------------------------------------------------------
// Early-exit resolution (conflict / in_progress / replay)
// ---------------------------------------------------------------------------

export type IdempotencyUsageStatus = 'success' | 'failed'

export interface IdempotencyEarlyExitError {
  usageStatus: IdempotencyUsageStatus
  isReplay: false
  httpStatus: number
  errorCode: string
  message: string
  retryable: boolean
  details: Record<string, unknown>
}

export interface IdempotencyEarlyExitReplay {
  usageStatus: IdempotencyUsageStatus
  isReplay: true
  cachedStatus: number
  cachedBody: string
  cachedContentType: string
}

export type IdempotencyEarlyExitResult = IdempotencyEarlyExitError | IdempotencyEarlyExitReplay

/**
 * Resolve idempotency claim to a structured early-exit descriptor.
 * Returns null when the claim is fresh ('claimed') and execution may continue.
 * index.ts consumes this to collapse conflict/in_progress/replay into one handler block.
 */
export function resolveIdempotencyEarlyExit(
  claim: IdempotencyClaimResult,
  action: string,
): IdempotencyEarlyExitResult | null {
  if (claim.kind === 'claimed') return null

  if (claim.kind === 'conflict') {
    return {
      usageStatus: 'failed',
      isReplay: false,
      httpStatus: 409,
      errorCode: 'bad_request',
      message: 'Idempotency key reuse with different payload is not allowed',
      retryable: false,
      details: { action, priorRequestId: claim.record?.request_id },
    }
  }

  if (claim.kind === 'in_progress') {
    return {
      usageStatus: 'failed',
      isReplay: false,
      httpStatus: 409,
      errorCode: 'bad_request',
      message: 'A request with this idempotency key is already processing',
      retryable: true,
      details: { action, priorRequestId: claim.record?.request_id },
    }
  }

  if (claim.kind === 'replay' && claim.record) {
    const cachedStatus = claim.record.response_status ?? 200
    const cachedBody =
      claim.record.response_body ??
      JSON.stringify({ success: false, error: 'idempotency_record_missing_response' })
    return {
      usageStatus: cachedStatus >= 200 && cachedStatus < 400 ? 'success' : 'failed',
      isReplay: true,
      cachedStatus,
      cachedBody,
      cachedContentType: claim.record.response_content_type ?? 'application/json',
    }
  }

  return null
}

/**
 * Finalize idempotency key with response details.
 * Transitions from 'processing' to 'completed' or 'failed'.
 */
export async function finalizeIdempotencyKey({
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
  supabase: SupabaseClient
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
