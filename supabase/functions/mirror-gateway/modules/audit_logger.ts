// Audit logger: apply events and usage metering persistence.
// Writes audit events and usage logs to Supabase with optional context handling.

import type { MirrorComputeRequest } from './request_validator.ts'

type SupabaseClient = ReturnType<typeof import('https://esm.sh/@supabase/supabase-js@2').createClient>
type MirrorUsageStatus = 'success' | 'failed' | 'rate_limited' | 'upstream_error'

/**
 * Write apply audit event (started, completed, failed).
 * Must be called with complete context (user, normalized, requestId, etc).
 */
export async function writeApplyAuditEvent({
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
  supabase: SupabaseClient
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

  // Normalize artifact IDs for audit trail
  const artifactIds = normalizeArtifactIds(normalized)

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
    artifact_ids: artifactIds,
    details,
  }

  const { error } = await supabase.from('mirror_apply_audit_events').insert(payload)
  if (error) {
    console.error('mirror-gateway apply audit write failed:', error.message)
  }
}

/**
 * Write usage log entry with complete context.
 */
export async function writeMirrorUsageLog({
  supabase,
  userId,
  projectId,
  taskId,
  mode,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: SupabaseClient
  userId: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number
}): Promise<void> {
  const durationMs = Date.now() - startedAtMs

  const payload = {
    user_id: userId,
    project_id: projectId,
    task_id: taskId,
    mode,
    action,
    status,
    request_id: requestId,
    idempotency_key: idempotencyKey,
    duration_ms: durationMs,
    recorded_at: new Date().toISOString(),
  }

  const { error } = await supabase.from('mirror_usage_logs').insert(payload)
  if (error) {
    console.error('mirror-gateway usage log write failed:', error.message)
  }
}

/**
 * Conditional usage log write that requires complete context.
 * Silently skips if context is incomplete (safe for early error returns).
 */
export async function writeMirrorUsageLogIfReady({
  supabase,
  userId,
  projectId,
  taskId,
  mode,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: SupabaseClient | null
  userId: string | null
  projectId: string | null
  taskId: string | null
  mode: 'private' | 'cloud' | null
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number | null
}): Promise<void> {
  if (!supabase || !userId || !projectId || !taskId || !mode || !startedAtMs) {
    return
  }

  await writeMirrorUsageLog({
    supabase,
    userId,
    projectId,
    taskId,
    mode,
    action,
    status,
    requestId,
    idempotencyKey,
    startedAtMs,
  })
}

/**
 * Normalize artifact IDs from request (backup + signed URLs).
 */
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

/**
 * Normalize artifact ID by stripping query parameters from URLs.
 */
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

/**
 * Normalize UUID or return fallback.
 */
function normalizeUuidOrNull(value: string | undefined, fallback: string): string {
  const candidate = value?.trim()
  if (!candidate) {
    return fallback
  }

  const uuidV4Like = /^[0-9a-fA-F-]{36}$/
  return uuidV4Like.test(candidate) ? candidate : fallback
}
