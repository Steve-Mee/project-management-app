// Contract tests for gateway composition boundaries.
//
// Verifies that module-level contracts are respected without requiring
// real Supabase connections or network access:
//
//   1. pre_condition_handler gates auth entry correctly (auth–idempotency sequencing)
//   2. circuit_breaker_handler state transitions produce correct resilience decisions
//      (rate-limit/CB rejection after auth)
//   3. error_contract maps rejection codes to the right error_family + retryable flag

import { validateRequestPreconditions } from './pre_condition_handler.ts'
import {
  evaluateCircuitBreakerAllowance,
  type CircuitBreakerState,
} from './circuit_breaker_handler.ts'
import { buildStructuredError } from './error_contract.ts'

declare const Deno: {
  test: (name: string, fn: () => void | Promise<void>) => void
}

// ─── 1. PRE-CONDITION GATE: AUTH–IDEMPOTENCY SEQUENCING ─────────────────────
// Contract: any request that fails a pre-condition MUST return a Response
// (non-null), ensuring auth and idempotency are never entered.

Deno.test('OPTIONS request short-circuits before auth with CORS 200', () => {
  const req = new Request('http://localhost/compile', { method: 'OPTIONS' })
  const result = validateRequestPreconditions(req, 'compile', {
    requestId: 'req-cors-1',
    traceId: 'trace-cors-1',
    idempotencyKey: 'idem-cors-1',
  })
  if (result === null) {
    throw new Error('Expected Response for OPTIONS preflight, got null (auth gate bypassed)')
  }
  if (result.status !== 200) {
    throw new Error(`Expected status 200 for CORS preflight, got ${result.status}`)
  }
})

Deno.test('non-POST method returns 405 before auth', async () => {
  const req = new Request('http://localhost/compile', { method: 'GET' })
  const result = validateRequestPreconditions(req, 'compile', {
    requestId: 'req-method-1',
    traceId: 'trace-method-1',
    idempotencyKey: 'idem-method-1',
  })
  if (result === null) {
    throw new Error('Expected Response for GET request, got null (auth gate bypassed)')
  }
  if (result.status !== 405) {
    throw new Error(`Expected 405 Method Not Allowed, got ${result.status}`)
  }
  const body = await result.json()
  if (body.error?.code !== 'method_not_allowed') {
    throw new Error(`Expected error.code=method_not_allowed, got: ${body.error?.code}`)
  }
})

Deno.test('unrecognized route returns 400 before auth', async () => {
  const req = new Request('http://localhost/unknown', { method: 'POST' })
  const result = validateRequestPreconditions(req, null, {
    requestId: 'req-route-1',
    traceId: 'trace-route-1',
    idempotencyKey: 'idem-route-1',
  })
  if (result === null) {
    throw new Error('Expected Response for unknown route, got null (auth gate bypassed)')
  }
  if (result.status !== 400) {
    throw new Error(`Expected 400 Bad Request, got ${result.status}`)
  }
  const body = await result.json()
  if (body.error?.code !== 'bad_request') {
    throw new Error(`Expected error.code=bad_request, got: ${body.error?.code}`)
  }
})

Deno.test('valid POST /compile returns null allowing auth to proceed', () => {
  const req = new Request('http://localhost/compile', { method: 'POST' })
  const result = validateRequestPreconditions(req, 'compile', {
    requestId: 'req-ok-1',
    traceId: 'trace-ok-1',
    idempotencyKey: 'idem-ok-1',
  })
  if (result !== null) {
    throw new Error(
      `Expected null (proceed to auth), got Response with status ${(result as Response).status}`,
    )
  }
})

Deno.test('valid POST /apply returns null allowing auth to proceed', () => {
  const req = new Request('http://localhost/apply', { method: 'POST' })
  const result = validateRequestPreconditions(req, 'apply', {
    requestId: 'req-ok-2',
    traceId: 'trace-ok-2',
    idempotencyKey: 'idem-ok-2',
  })
  if (result !== null) {
    throw new Error(
      `Expected null (proceed to auth), got Response with status ${(result as Response).status}`,
    )
  }
})

// ─── 2. CIRCUIT BREAKER: REJECTION AFTER AUTH ───────────────────────────────
// Contract: CB state transitions correctly block/allow requests after auth
// succeeds but before forwarding. These mirror the rate-limit rejection path
// in index.ts steps 4–5.

Deno.test('closed circuit breaker allows request after auth', () => {
  const state: CircuitBreakerState = {
    consecutiveFailures: 0,
    openUntilMs: null,
    halfOpenProbeActive: false,
  }
  const decision = evaluateCircuitBreakerAllowance(state)
  if (!decision.allowed) {
    throw new Error('Expected allowed=true from closed circuit breaker')
  }
  if (decision.reason !== 'closed') {
    throw new Error(`Expected reason=closed, got: ${decision.reason}`)
  }
})

Deno.test('open circuit breaker blocks request and reports retryAfterSeconds', () => {
  const state: CircuitBreakerState = {
    consecutiveFailures: 5,
    openUntilMs: Date.now() + 30_000,
    halfOpenProbeActive: false,
  }
  const decision = evaluateCircuitBreakerAllowance(state)
  if (decision.allowed) {
    throw new Error('Expected allowed=false from open circuit breaker')
  }
  if (decision.reason !== 'open') {
    throw new Error(`Expected reason=open, got: ${decision.reason}`)
  }
  if (!decision.retryAfterSeconds || decision.retryAfterSeconds < 1) {
    throw new Error(`Expected retryAfterSeconds >= 1, got: ${decision.retryAfterSeconds}`)
  }
})

Deno.test('cooled-off circuit breaker allows single half-open probe, then blocks second', () => {
  const state: CircuitBreakerState = {
    consecutiveFailures: 5,
    openUntilMs: Date.now() - 1, // window expired
    halfOpenProbeActive: false,
  }
  const probe = evaluateCircuitBreakerAllowance(state)
  if (!probe.allowed) {
    throw new Error('Expected first request to be allowed as half-open probe after cooldown')
  }
  if (probe.reason !== 'half_open_probe') {
    throw new Error(`Expected reason=half_open_probe, got: ${probe.reason}`)
  }
  // Second concurrent request must be blocked while probe is in-flight
  const concurrent = evaluateCircuitBreakerAllowance(state)
  if (concurrent.allowed) {
    throw new Error('Expected second request to be blocked while CB probe is active')
  }
})

// ─── 3. ERROR CONTRACT: REJECTION RESPONSE SHAPES ───────────────────────────
// Contract: rejection error codes map to the correct error_family and
// retryable flag, ensuring callers can distinguish recoverable errors.

Deno.test('rate_limited error maps to rate_limit family and is retryable', () => {
  const error = buildStructuredError({
    code: 'rate_limited',
    message: 'Mirror gateway rate limit exceeded',
    retryable: true,
    requestId: 'req-rl-1',
    traceId: 'trace-rl-1',
    idempotencyKey: 'idem-rl-1',
    details: { retryAfterSeconds: 60 },
    stage: 'rate_limit',
  })
  if (error.error_family !== 'rate_limit') {
    throw new Error(`Expected error_family=rate_limit, got: ${error.error_family}`)
  }
  if (!error.retryable) {
    throw new Error('rate_limited error must have retryable=true')
  }
})

Deno.test('unauthorized error maps to auth family and is non-retryable', () => {
  const error = buildStructuredError({
    code: 'unauthorized',
    message: 'Missing or invalid auth token',
    retryable: false,
    requestId: 'req-auth-1',
    traceId: 'trace-auth-1',
    stage: 'auth',
  })
  if (error.error_family !== 'auth') {
    throw new Error(`Expected error_family=auth, got: ${error.error_family}`)
  }
  if (error.retryable) {
    throw new Error('unauthorized error must have retryable=false')
  }
})

Deno.test('upstream_error maps to upstream family and propagates upstream_status', () => {
  const error = buildStructuredError({
    code: 'upstream_error',
    message: 'Upstream runner returned 503',
    retryable: true,
    requestId: 'req-up-1',
    traceId: 'trace-up-1',
    upstreamStatus: 503,
    stage: 'forwarding',
  })
  if (error.error_family !== 'upstream') {
    throw new Error(`Expected error_family=upstream, got: ${error.error_family}`)
  }
  if (error.upstream_status !== 503) {
    throw new Error(`Expected upstream_status=503, got: ${error.upstream_status}`)
  }
})
