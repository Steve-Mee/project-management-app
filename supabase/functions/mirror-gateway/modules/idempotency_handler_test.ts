import {
  buildIdempotencyRequestHash,
  claimIdempotencyKey,
  finalizeIdempotencyKey,
  resolveIdempotencyEarlyExit,
} from './idempotency_handler.ts'
import type { MirrorComputeRequest } from './request_validator.ts'

declare const Deno: {
  test: (name: string, fn: () => void | Promise<void>) => void
}

type Row = {
  user_id: string
  action: 'compile' | 'apply'
  idempotency_key: string
  request_hash: string
  request_id: string
  status: 'processing' | 'completed' | 'failed'
  response_status?: number | null
  response_body?: string | null
  response_content_type?: string | null
  expires_at: string
  created_at?: string | null
  updated_at?: string | null
}

class FakeSupabaseClient {
  readonly rows: Row[]

  constructor(rows: Row[] = []) {
    this.rows = rows
  }

  from(_table: string): FakeQueryBuilder {
    return new FakeQueryBuilder(this.rows)
  }
}

function nowIso(): string {
  return new Date().toISOString()
}

function pastIso(secondsAgo: number): string {
  return new Date(Date.now() - secondsAgo * 1000).toISOString()
}

class FakeQueryBuilder {
  private readonly rows: Row[]
  private filters: Array<[keyof Row, unknown]> = []
  private updatePatch: Partial<Row> | null = null

  constructor(rows: Row[]) {
    this.rows = rows
  }

  select(_columns?: string): this {
    return this
  }

  eq(column: keyof Row, value: unknown): this {
    this.filters.push([column, value])
    return this
  }

  maybeSingle<T>(): Promise<{ data: T | null; error: null }> {
    const match = this.findMatches()[0] ?? null
    return Promise.resolve({ data: (match as T | null), error: null })
  }

  insert(payload: Row): Promise<{ error: { message: string } | null }> {
    const duplicate = this.rows.find((row) =>
      row.user_id === payload.user_id &&
      row.action === payload.action &&
      row.idempotency_key === payload.idempotency_key,
    )

    if (duplicate) {
      return Promise.resolve({ error: { message: 'duplicate key value violates unique constraint' } })
    }

    this.rows.push({
      ...payload,
      response_status: payload.response_status ?? null,
      response_body: payload.response_body ?? null,
      response_content_type: payload.response_content_type ?? null,
      created_at: payload.created_at ?? new Date().toISOString(),
      updated_at: payload.updated_at ?? new Date().toISOString(),
    })
    return Promise.resolve({ error: null })
  }

  update(patch: Partial<Row>): this {
    this.updatePatch = patch
    return this
  }

  then<TResult1 = { data: Array<Pick<Row, 'request_id'>>; error: null }, TResult2 = never>(
    onfulfilled?:
      | ((value: { data: Array<Pick<Row, 'request_id'>>; error: null }) => TResult1 | PromiseLike<TResult1>)
      | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): Promise<TResult1 | TResult2> {
    const result = this.executeUpdate()
    return Promise.resolve(result).then(onfulfilled, onrejected)
  }

  private findMatches(): Row[] {
    return this.rows.filter((row) =>
      this.filters.every(([column, value]) => row[column] === value),
    )
  }

  private executeUpdate(): { data: Array<Pick<Row, 'request_id'>>; error: null } {
    const matches = this.findMatches()
    if (!this.updatePatch) {
      return { data: matches.map((row) => ({ request_id: row.request_id })), error: null }
    }

    for (const row of matches) {
      Object.assign(row, this.updatePatch, { updated_at: new Date().toISOString() })
    }

    return { data: matches.map((row) => ({ request_id: row.request_id })), error: null }
  }
}

const validRequest: MirrorComputeRequest = {
  prompt: 'Implement feature X',
  projectId: '550e8400-e29b-41d4-a716-446655440000',
  taskId: '7d444840-9dc0-11d1-b245-5ffdce74fad2',
  mode: 'cloud',
  files: { 'lib/main.dart': 'void main() {}' },
  metadata: { requestId: 'req-1' },
}

Deno.test('buildIdempotencyRequestHash is stable for equivalent payloads', async () => {
  const hashA = await buildIdempotencyRequestHash('user-1', 'compile', {
    ...validRequest,
    metadata: { b: 2, a: 1 },
  })
  const hashB = await buildIdempotencyRequestHash('user-1', 'compile', {
    ...validRequest,
    metadata: { a: 1, b: 2 },
  })

  if (hashA !== hashB) {
    throw new Error(`Expected stable hash, got ${hashA} != ${hashB}`)
  }
})

Deno.test('buildIdempotencyRequestHash changes when action changes', async () => {
  const compileHash = await buildIdempotencyRequestHash('user-1', 'compile', validRequest)
  const applyHash = await buildIdempotencyRequestHash('user-1', 'apply', validRequest)

  if (compileHash === applyHash) {
    throw new Error('Expected idempotency hash to differ between compile and apply actions')
  }
})

Deno.test('claimIdempotencyKey claims a new key as processing', async () => {
  const supabase = new FakeSupabaseClient()

  const claim = await claimIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'compile',
    idempotencyKey: 'idem-1',
    requestHash: 'sha256:abc',
    requestId: 'gateway-abc-1',
  })

  if (claim.kind !== 'claimed') {
    throw new Error(`Expected claimed, got: ${claim.kind}`)
  }
  if (supabase.rows.length !== 1 || supabase.rows[0].status !== 'processing') {
    throw new Error('Expected one processing idempotency row to be inserted')
  }
})

Deno.test('claimIdempotencyKey returns in_progress for active matching request', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'compile',
      idempotency_key: 'idem-1',
      request_hash: 'sha256:abc',
      request_id: 'req-existing-1',
      status: 'processing',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  const claim = await claimIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'compile',
    idempotencyKey: 'idem-1',
    requestHash: 'sha256:abc',
    requestId: 'gateway-new-1',
  })

  if (claim.kind !== 'in_progress') {
    throw new Error(`Expected in_progress, got: ${claim.kind}`)
  }
})

Deno.test('claimIdempotencyKey returns replay for completed matching request', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-2',
      request_hash: 'sha256:def',
      request_id: 'req-existing-2',
      status: 'completed',
      response_status: 200,
      response_body: '{"success":true}',
      response_content_type: 'application/json',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  const claim = await claimIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'apply',
    idempotencyKey: 'idem-2',
    requestHash: 'sha256:def',
    requestId: 'gateway-new-2',
  })

  if (claim.kind !== 'replay') {
    throw new Error(`Expected replay, got: ${claim.kind}`)
  }
})

Deno.test('claimIdempotencyKey returns conflict for active mismatched payload', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-3',
      request_hash: 'sha256:old',
      request_id: 'req-existing-3',
      status: 'processing',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  const claim = await claimIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'apply',
    idempotencyKey: 'idem-3',
    requestHash: 'sha256:new',
    requestId: 'gateway-new-3',
  })

  if (claim.kind !== 'conflict') {
    throw new Error(`Expected conflict, got: ${claim.kind}`)
  }
})

Deno.test('claimIdempotencyKey reclaims expired mismatched payload', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-4',
      request_hash: 'sha256:old',
      request_id: 'req-existing-4',
      status: 'processing',
      expires_at: new Date(Date.now() - 60_000).toISOString(),
      created_at: pastIso(600),
      updated_at: pastIso(600),
    },
  ])

  const claim = await claimIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'apply',
    idempotencyKey: 'idem-4',
    requestHash: 'sha256:new',
    requestId: 'gateway-new-4',
  })

  if (claim.kind !== 'claimed') {
    throw new Error(`Expected claimed after expiry recovery, got: ${claim.kind}`)
  }
  if (supabase.rows[0].request_hash !== 'sha256:new' || supabase.rows[0].status !== 'processing') {
    throw new Error('Expected expired row to be reset to the new processing claim')
  }
})

Deno.test('resolveIdempotencyEarlyExit maps conflict, in-progress, and replay correctly', () => {
  const conflict = resolveIdempotencyEarlyExit(
    {
      kind: 'conflict',
      record: {
        user_id: 'user-1',
        action: 'compile',
        idempotency_key: 'idem-1',
        request_hash: 'sha256:old',
        request_id: 'req-old-1',
        status: 'processing',
        response_status: null,
        response_body: null,
        response_content_type: null,
        expires_at: new Date(Date.now() + 60_000).toISOString(),
        created_at: nowIso(),
        updated_at: nowIso(),
      },
    },
    'compile',
  )
  if (!conflict || conflict.isReplay || conflict.httpStatus !== 409 || conflict.retryable) {
    throw new Error('Expected conflict early exit to be non-replay 409 and non-retryable')
  }

  const inProgress = resolveIdempotencyEarlyExit(
    {
      kind: 'in_progress',
      record: {
        user_id: 'user-1',
        action: 'compile',
        idempotency_key: 'idem-2',
        request_hash: 'sha256:old',
        request_id: 'req-old-2',
        status: 'processing',
        response_status: null,
        response_body: null,
        response_content_type: null,
        expires_at: new Date(Date.now() + 60_000).toISOString(),
        created_at: nowIso(),
        updated_at: nowIso(),
      },
    },
    'compile',
  )
  if (!inProgress || inProgress.isReplay || inProgress.httpStatus !== 409 || !inProgress.retryable) {
    throw new Error('Expected in-progress early exit to be non-replay 409 and retryable')
  }

  const replay = resolveIdempotencyEarlyExit(
    {
      kind: 'replay',
      record: {
        user_id: 'user-1',
        action: 'compile',
        idempotency_key: 'idem-3',
        request_hash: 'sha256:old',
        request_id: 'req-old-3',
        status: 'completed',
        response_status: 201,
        response_body: '{"success":true}',
        response_content_type: 'application/json',
        expires_at: new Date(Date.now() + 60_000).toISOString(),
        created_at: nowIso(),
        updated_at: nowIso(),
      },
    },
    'compile',
  )
  if (!replay || !replay.isReplay || replay.cachedStatus !== 201) {
    throw new Error('Expected replay early exit to return cached response details')
  }
})

Deno.test('resolveIdempotencyEarlyExit falls back to default cached response metadata', () => {
  const replay = resolveIdempotencyEarlyExit(
    {
      kind: 'replay',
      record: {
        user_id: 'user-1',
        action: 'compile',
        idempotency_key: 'idem-4',
        request_hash: 'sha256:old',
        request_id: 'req-old-4',
        status: 'failed',
        response_status: null,
        response_body: null,
        response_content_type: null,
        expires_at: new Date(Date.now() + 60_000).toISOString(),
        created_at: nowIso(),
        updated_at: nowIso(),
      },
    },
    'compile',
  )

  if (!replay || !replay.isReplay) {
    throw new Error('Expected replay fallback descriptor')
  }
  if (replay.cachedStatus != 200 || replay.cachedContentType !== 'application/json') {
    throw new Error('Expected replay fallback to default status/content type')
  }
  if (!replay.cachedBody.includes('idempotency_record_missing_response')) {
    throw new Error('Expected replay fallback body to mention missing cached response')
  }
})

Deno.test('finalizeIdempotencyKey stores cached response and clips oversized bodies', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-5',
      request_hash: 'sha256:ghi',
      request_id: 'req-existing-5',
      status: 'processing',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  const largeBody = 'x'.repeat(70 * 1024)
  await finalizeIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'apply',
    idempotencyKey: 'idem-5',
    requestId: 'req-existing-5',
    requestHash: 'sha256:ghi',
    status: 'completed',
    responseStatus: 200,
    responseBody: largeBody,
    responseContentType: 'application/json',
  })

  const row = supabase.rows[0]
  if (row.status !== 'completed' || row.response_status !== 200) {
    throw new Error('Expected finalized row to be marked completed with cached response status')
  }
  if (!row.response_body || row.response_body.length >= largeBody.length) {
    throw new Error('Expected oversized response body to be clipped before storing')
  }
})

Deno.test('finalizeIdempotencyKey rejects updates without matching processing claim', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-6',
      request_hash: 'sha256:jkl',
      request_id: 'req-existing-6',
      status: 'completed',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  let threw = false
  try {
    await finalizeIdempotencyKey({
      supabase: supabase as never,
      userId: 'user-1',
      action: 'apply',
      idempotencyKey: 'idem-6',
      requestId: 'req-existing-6',
      requestHash: 'sha256:jkl',
      status: 'completed',
      responseStatus: 200,
      responseBody: '{"success":true}',
      responseContentType: 'application/json',
    })
  } catch (error) {
    threw = error instanceof Error &&
      error.message === 'idempotency_update_conflict:no_matching_processing_claim'
  }

  if (!threw) {
    throw new Error('Expected finalizeIdempotencyKey to reject missing processing claim')
  }
})

Deno.test('finalizeIdempotencyKey can persist failed status responses', async () => {
  const supabase = new FakeSupabaseClient([
    {
      user_id: 'user-1',
      action: 'apply',
      idempotency_key: 'idem-7',
      request_hash: 'sha256:mno',
      request_id: 'req-existing-7',
      status: 'processing',
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      created_at: nowIso(),
      updated_at: nowIso(),
    },
  ])

  await finalizeIdempotencyKey({
    supabase: supabase as never,
    userId: 'user-1',
    action: 'apply',
    idempotencyKey: 'idem-7',
    requestId: 'req-existing-7',
    requestHash: 'sha256:mno',
    status: 'failed',
    responseStatus: 502,
    responseBody: '{"success":false}',
    responseContentType: 'application/json',
  })

  const row = supabase.rows[0]
  if (row.status !== 'failed' || row.response_status !== 502) {
    throw new Error('Expected failed idempotency finalization to persist response status')
  }
})