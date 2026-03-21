// Request parsing, validation and normalization orchestrator.
// Combines JSON parsing, raw data validation, and field normalization into single Request object.

import {
  normalizeNonEmptyString,
  normalizeRequestBody,
  normalizeSignedInputUrls,
  parseRequestJsonWithLimit,
} from './request_normalization.ts'

export interface MirrorComputeRequest {
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

export type RequestValidationErrorKind =
  | 'payload_too_large'
  | 'bad_json'
  | 'bad_request'
  | 'invalid_fields'

export interface RequestValidationError {
  kind: RequestValidationErrorKind
  message: string
  statusCode: number
}

export interface ValidatedRequest {
  normalized: MirrorComputeRequest
  raw: unknown
}

const MAX_REQUEST_BODY_BYTES = 512 * 1024

/**
 * Parse and validate incoming request body.
 * Returns validated normalized request or structured error.
 */
export async function validateAndParseRequest(
  req: Request,
): Promise<ValidatedRequest | RequestValidationError> {
  // Step 1: Parse JSON with size limit
  let rawBody: Partial<MirrorComputeRequest>
  try {
    rawBody = await parseRequestJsonWithLimit(req, MAX_REQUEST_BODY_BYTES)
  } catch (error) {
    if (error instanceof Error && error.message.startsWith('payload_too_large:')) {
      return {
        kind: 'payload_too_large',
        message: `Request body exceeds ${MAX_REQUEST_BODY_BYTES} bytes limit`,
        statusCode: 413,
      }
    }

    if (error instanceof Error && error.message === 'bad_json') {
      return {
        kind: 'bad_json',
        message: 'Invalid JSON body',
        statusCode: 400,
      }
    }

    throw error
  }

  // Step 2: Normalize and validate fields
  const normalized = normalizeRequestBody(rawBody)
  if (!normalized) {
    return {
      kind: 'invalid_fields',
      message: 'Missing or invalid fields: prompt, projectId, taskId, mode',
      statusCode: 400,
    }
  }

  return {
    normalized,
    raw: rawBody,
  }
}

/**
 * Extract and normalize artifact identifiers (backup IDs, signed URLs).
 * Used for audit logging and artifact tracking.
 */
export function normalizeArtifactIds(request: MirrorComputeRequest): string[] {
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
export function normalizeArtifactId(rawValue: string): string {
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
export function normalizeUuidOrNull(value: string | undefined, fallback: string): string {
  const candidate = value?.trim()
  if (!candidate) {
    return fallback
  }

  const uuidV4Like = /^[0-9a-fA-F-]{36}$/
  return uuidV4Like.test(candidate) ? candidate : fallback
}

/**
 * Extract and normalize forward fields (actorUserId, backupId, fileSetFingerprint, signedInputUrls).
 */
export function normalizeForwardFields(normalized: MirrorComputeRequest, userId: string): {
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

/**
 * Build forward payload for upstream runner.
 */
export interface ForwardPayload {
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

export function buildForwardPayload(
  normalized: MirrorComputeRequest,
  userId: string,
  action: 'compile' | 'apply',
  requestId: string,
  traceId: string,
  forwardFields: ReturnType<typeof normalizeForwardFields>,
): ForwardPayload {
  return {
    prompt: normalized.prompt,
    projectId: normalized.projectId,
    taskId: normalized.taskId,
    mode: normalized.mode,
    action,
    userId,
    files: normalized.files ?? {},
    metadata: {
      ...(normalized.metadata ?? {}),
      requestId,
      traceId,
    },
    requestId,
    traceId,
    actorUserId: forwardFields.actorUserId,
    backupId: forwardFields.backupId,
    fileSetFingerprint: forwardFields.fileSetFingerprint,
    signedInputUrls: forwardFields.signedInputUrls,
  }
}
