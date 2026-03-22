// Shared Mirror request schema for gateway validation.
// This module centralizes payload contract checks before auth/idempotency/forwarding.

import {
  normalizeRequestBody,
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
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

function isValidUuid(value: string): boolean {
  return UUID_REGEX.test(value)
}

function isValidHash(value: string): boolean {
  const parts = value.split(':')
  return parts.length === 2 && parts[0].length > 0 && parts[1].length > 0
}

function isValidHttpsUrl(value: string): boolean {
  try {
    const parsed = new URL(value)
    return parsed.protocol === 'https:' && parsed.hostname.length > 0
  } catch {
    return false
  }
}

export function validateMirrorComputeRequest(normalized: MirrorComputeRequest): string[] {
  const errors: string[] = []

  if (!normalized.prompt || normalized.prompt.length === 0) {
    errors.push('prompt: must be non-empty string')
  } else if (normalized.prompt.length > 50000) {
    errors.push('prompt: must be ≤50000 characters')
  }

  if (!normalized.projectId || normalized.projectId.length === 0) {
    errors.push('projectId: must be non-empty string')
  } else {
    if (normalized.projectId.length > 256) {
      errors.push('projectId: must be ≤256 characters')
    }
    if (!isValidUuid(normalized.projectId)) {
      errors.push('projectId: must be valid UUID')
    }
  }

  if (!normalized.taskId || normalized.taskId.length === 0) {
    errors.push('taskId: must be non-empty string')
  } else {
    if (normalized.taskId.length > 256) {
      errors.push('taskId: must be ≤256 characters')
    }
    if (!isValidUuid(normalized.taskId)) {
      errors.push('taskId: must be valid UUID')
    }
  }

  if (normalized.mode !== 'private' && normalized.mode !== 'cloud') {
    errors.push('mode: must be "private" or "cloud"')
  }

  if (normalized.actorUserId && !isValidUuid(normalized.actorUserId)) {
    errors.push('actorUserId: must be valid UUID when provided')
  }

  if (normalized.backupId && normalized.backupId.length > 512) {
    errors.push('backupId: must be ≤512 characters')
  }

  if (normalized.fileSetFingerprint && !isValidHash(normalized.fileSetFingerprint)) {
    errors.push('fileSetFingerprint: must be valid hash format, e.g. sha256:...')
  }

  if (normalized.signedInputUrls) {
    for (const [key, value] of Object.entries(normalized.signedInputUrls)) {
      if (!key || key.length > 512) {
        errors.push('signedInputUrls: key must be 1-512 characters')
      }
      if (!isValidHttpsUrl(value)) {
        errors.push(`signedInputUrls[${key}]: must be valid HTTPS URL`)
      }
    }
  }

  if (normalized.files) {
    const entries = Object.entries(normalized.files)
    if (entries.length > 1000) {
      errors.push('files: must contain ≤1000 entries')
    }

    for (const [key, value] of entries) {
      if (!key || key.length > 512) {
        errors.push(`files: key "${key}" must be 1-512 characters`)
      }
      if (value.length > 1024 * 1024) {
        errors.push(`files[${key}]: value must be ≤1MB`)
      }
    }
  }

  if (normalized.metadata && typeof normalized.metadata !== 'object') {
    errors.push('metadata: must be object when provided')
  }

  return errors
}

/**
 * Parse and validate incoming request body.
 * Returns validated normalized request or structured error.
 */
export async function validateAndParseRequest(
  req: Request,
): Promise<ValidatedRequest | RequestValidationError> {
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

  const normalized = normalizeRequestBody(rawBody)
  if (!normalized) {
    return {
      kind: 'invalid_fields',
      message: 'Missing or invalid fields: prompt, projectId (UUID), taskId (UUID), mode',
      statusCode: 400,
    }
  }

  const schemaErrors = validateMirrorComputeRequest(normalized)
  if (schemaErrors.length > 0) {
    return {
      kind: 'invalid_fields',
      message: schemaErrors.join('; '),
      statusCode: 400,
    }
  }

  return {
    normalized,
    raw: rawBody,
  }
}
