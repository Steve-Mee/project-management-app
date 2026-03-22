export interface MirrorComputeRequestLike {
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

const UUID_V4_LIKE_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

export function normalizeNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return undefined
  }

  const normalized = value.trim()
  return normalized.length > 0 ? normalized : undefined
}

export function normalizeSignedInputUrls(value: unknown): Record<string, string> {
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

export async function parseRequestJsonWithLimit(
  req: Request,
  maxRequestBodyBytes: number,
): Promise<Partial<MirrorComputeRequestLike>> {
  const contentLength = req.headers.get('content-length')
  if (contentLength) {
    const parsedLength = Number.parseInt(contentLength, 10)
    if (Number.isFinite(parsedLength) && parsedLength > maxRequestBodyBytes) {
      throw new Error('payload_too_large:header')
    }
  }

  const rawBody = await req.text()
  const bodyBytes = new TextEncoder().encode(rawBody).length
  if (bodyBytes > maxRequestBodyBytes) {
    throw new Error('payload_too_large:body')
  }

  try {
    return JSON.parse(rawBody) as Partial<MirrorComputeRequestLike>
  } catch {
    throw new Error('bad_json')
  }
}

export function normalizeRequestBody(
  body: Partial<MirrorComputeRequestLike>,
): MirrorComputeRequestLike | null {
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
  if (!UUID_V4_LIKE_REGEX.test(normalizedProjectId)) {
    return null
  }
  if (!UUID_V4_LIKE_REGEX.test(normalizedTaskId)) {
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