import {
  validateAndParseRequest,
  validateMirrorComputeRequest,
} from './request_schema.ts'

declare const Deno: {
  test: (name: string, fn: () => void | Promise<void>) => void
}

Deno.test('validateMirrorComputeRequest accepts valid payload', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    files: { 'lib/main.dart': 'void main() {}' },
    metadata: { requestId: 'req-1' },
    actorUserId: '550e8400-e29b-41d4-a716-446655440000',
    backupId: 'backup-1',
    fileSetFingerprint: 'sha256:abc123',
    signedInputUrls: { archive: 'https://example.com/archive.zip' },
  })

  if (errors.length > 0) {
    throw new Error(`Expected no errors, got: ${errors.join('; ')}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects invalid UUID and mode', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: 'not-a-uuid',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'team' as 'private' | 'cloud',
    files: { 'lib/main.dart': 'void main() {}' },
  })

  const joined = errors.join(' | ')
  if (!joined.includes('projectId')) {
    throw new Error(`Expected projectId validation error, got: ${joined}`)
  }
  if (!joined.includes('mode')) {
    throw new Error(`Expected mode validation error, got: ${joined}`)
  }
})

Deno.test('validateAndParseRequest rejects bad json', async () => {
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{bad-json}',
  })

  const result = await validateAndParseRequest(req)
  if (!('kind' in result)) {
    throw new Error('Expected validation error result for bad JSON')
  }
  if (result.kind !== 'bad_json') {
    throw new Error(`Expected bad_json, got: ${result.kind}`)
  }
})

Deno.test('validateAndParseRequest accepts valid request', async () => {
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      prompt: 'Refactor service layer',
      projectId: '550e8400-e29b-41d4-a716-446655440000',
      taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
      mode: 'private',
      files: { 'lib/service.dart': 'class Service {}' },
      metadata: { requestId: 'req-2' },
    }),
  })

  const result = await validateAndParseRequest(req)
  if ('kind' in result) {
    throw new Error(`Expected valid result, got ${result.kind}: ${result.message}`)
  }

  if (result.normalized.mode !== 'private') {
    throw new Error(`Expected mode private, got: ${result.normalized.mode}`)
  }
  if (result.normalized.projectId !== '550e8400-e29b-41d4-a716-446655440000') {
    throw new Error('projectId mismatch after parsing')
  }
})

Deno.test('validateAndParseRequest rejects payload too large from content-length header', async () => {
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'content-length': String(600 * 1024),
    },
    body: JSON.stringify({
      prompt: 'Refactor service layer',
      projectId: '550e8400-e29b-41d4-a716-446655440000',
      taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
      mode: 'private',
    }),
  })

  const result = await validateAndParseRequest(req)
  if (!('kind' in result)) {
    throw new Error('Expected payload_too_large result')
  }
  if (result.kind !== 'payload_too_large' || result.statusCode !== 413) {
    throw new Error(`Expected payload_too_large/413, got ${result.kind}/${result.statusCode}`)
  }
})

Deno.test('validateAndParseRequest rejects missing required fields', async () => {
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      prompt: 'Missing ids',
      mode: 'cloud',
    }),
  })

  const result = await validateAndParseRequest(req)
  if (!('kind' in result)) {
    throw new Error('Expected invalid_fields result for missing identifiers')
  }
  if (result.kind !== 'invalid_fields') {
    throw new Error(`Expected invalid_fields, got: ${result.kind}`)
  }
})

Deno.test('validateAndParseRequest rejects payload too large from actual body bytes', async () => {
  const oversizedPrompt = 'x'.repeat(520 * 1024)
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      prompt: oversizedPrompt,
      projectId: '550e8400-e29b-41d4-a716-446655440000',
      taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
      mode: 'private',
    }),
  })

  const result = await validateAndParseRequest(req)
  if (!('kind' in result) || result.kind !== 'payload_too_large') {
    throw new Error(`Expected payload_too_large from body bytes, got: ${'kind' in result ? result.kind : 'success'}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects oversized prompt', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'x'.repeat(50001),
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
  })

  if (!errors.includes('prompt: must be ≤50000 characters')) {
    throw new Error(`Expected prompt limit error, got: ${errors.join(' | ')}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects invalid actor user id and fingerprint', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    actorUserId: 'not-a-uuid',
    fileSetFingerprint: 'invalid-fingerprint',
  })

  const joined = errors.join(' | ')
  if (!joined.includes('actorUserId')) {
    throw new Error(`Expected actorUserId validation error, got: ${joined}`)
  }
  if (!joined.includes('fileSetFingerprint')) {
    throw new Error(`Expected fileSetFingerprint validation error, got: ${joined}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects backup id and signed url keys over limit', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    backupId: 'b'.repeat(513),
    signedInputUrls: {
      ['k'.repeat(513)]: 'https://example.com/archive.zip',
    },
  })

  const joined = errors.join(' | ')
  if (!joined.includes('backupId')) {
    throw new Error(`Expected backupId validation error, got: ${joined}`)
  }
  if (!joined.includes('signedInputUrls: key must be 1-512 characters')) {
    throw new Error(`Expected signedInputUrls key length error, got: ${joined}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects non-https signed input urls', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    signedInputUrls: { archive: 'http://example.com/archive.zip' },
  })

  const joined = errors.join(' | ')
  if (!joined.includes('signedInputUrls[archive]')) {
    throw new Error(`Expected signedInputUrls HTTPS validation error, got: ${joined}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects too many files', () => {
  const files: Record<string, string> = {}
  for (let index = 0; index < 1001; index += 1) {
    files[`lib/file_${index}.dart`] = 'ok'
  }

  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    files,
  })

  if (!errors.includes('files: must contain ≤1000 entries')) {
    throw new Error(`Expected file count error, got: ${errors.join(' | ')}`)
  }
})

Deno.test('validateMirrorComputeRequest rejects oversized file content', () => {
  const errors = validateMirrorComputeRequest({
    prompt: 'Implement feature X',
    projectId: '550e8400-e29b-41d4-a716-446655440000',
    taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
    mode: 'cloud',
    files: { 'lib/main.dart': 'x'.repeat(1024 * 1024 + 1) },
  })

  const joined = errors.join(' | ')
  if (!joined.includes('files[lib/main.dart]: value must be ≤1MB')) {
    throw new Error(`Expected file size error, got: ${joined}`)
  }
})

Deno.test('validateAndParseRequest normalizes blank files and sorts signed input urls', async () => {
  const req = new Request('http://localhost/apply', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      prompt: 'Apply fix',
      projectId: '550e8400-e29b-41d4-a716-446655440000',
      taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
      mode: 'cloud',
      files: {
        ' lib/main.dart ': 'void main() {}',
        '   ': 'ignored',
      },
      signedInputUrls: {
        zeta: 'https://example.com/zeta.zip',
        alpha: 'https://example.com/alpha.zip',
        blank: '   ',
      },
    }),
  })

  const result = await validateAndParseRequest(req)
  if ('kind' in result) {
    throw new Error(`Expected valid normalized result, got ${result.kind}: ${result.message}`)
  }

  const fileKeys = Object.keys(result.normalized.files ?? {})
  if (fileKeys.length !== 1 || fileKeys[0] !== 'lib/main.dart') {
    throw new Error(`Expected trimmed non-blank files, got: ${fileKeys.join(', ')}`)
  }

  const signedUrlKeys = Object.keys(result.normalized.signedInputUrls ?? {})
  if (signedUrlKeys.join(',') !== 'alpha,zeta') {
    throw new Error(`Expected sorted signedInputUrls keys, got: ${signedUrlKeys.join(',')}`)
  }
})

Deno.test('validateAndParseRequest coerces invalid metadata to empty object', async () => {
  const req = new Request('http://localhost/compile', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      prompt: 'Refactor service layer',
      projectId: '550e8400-e29b-41d4-a716-446655440000',
      taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
      mode: 'private',
      metadata: 'not-an-object',
    }),
  })

  const result = await validateAndParseRequest(req)
  if ('kind' in result) {
    throw new Error(`Expected valid result with normalized metadata, got ${result.kind}`)
  }
  if (Object.keys(result.normalized.metadata ?? {}).length !== 0) {
    throw new Error('Expected invalid metadata to normalize to empty object')
  }
})
