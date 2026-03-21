// Circuit breaker handler: upstream failure tracking and recovery.
// Detects sustained upstream failures and blocks requests during recovery.

/**
 * In-memory circuit breaker state.
 * Tracks consecutive failures and open/half-open phases.
 */
export interface CircuitBreakerState {
  consecutiveFailures: number
  openUntilMs: number | null
  halfOpenProbeActive: boolean
}

export type CircuitBreakerDecisionReason = 'closed' | 'half_open_probe' | 'open'

export interface CircuitBreakerDecision {
  allowed: boolean
  reason: CircuitBreakerDecisionReason
  retryAfterSeconds?: number
}

/**
 * Get configured circuit breaker failure threshold.
 */
export function getCircuitBreakerFailureThreshold(): number {
  const deno = (globalThis as any).Deno
  const raw = deno?.env?.get?.('MIRROR_GATEWAY_CIRCUIT_BREAKER_FAILURE_THRESHOLD')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return 5 // default
}

/**
 * Get configured circuit breaker open duration in seconds.
 */
export function getCircuitBreakerOpenSeconds(): number {
  const deno = (globalThis as any).Deno
  const raw = deno?.env?.get?.('MIRROR_GATEWAY_CIRCUIT_BREAKER_OPEN_SECONDS')
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return 30 // default
}

/**
 * Evaluate if request should be allowed based on current circuit breaker state.
 * - 'closed': normal operation, request allowed
 * - 'half_open_probe': probe allowed to test recovery
 * - 'open': circuit is open, request denied
 */
export function evaluateCircuitBreakerAllowance(state: CircuitBreakerState): CircuitBreakerDecision {
  const now = Date.now()
  const openUntil = state.openUntilMs

  // Circuit is open: deny unless we've waited long enough to half-open
  if (openUntil != null && openUntil > now) {
    return {
      allowed: false,
      reason: 'open',
      retryAfterSeconds: Math.max(1, Math.ceil((openUntil - now) / 1000)),
    }
  }

  // Transition from open to half-open
  if (openUntil != null && openUntil <= now) {
    if (state.halfOpenProbeActive) {
      // Another request is already probing; deny this one
      return {
        allowed: false,
        reason: 'open',
        retryAfterSeconds: 1,
      }
    }
    // Allow first request as probe
    state.halfOpenProbeActive = true
    return {
      allowed: true,
      reason: 'half_open_probe',
    }
  }

  // Closed: normal operation
  return {
    allowed: true,
    reason: 'closed',
  }
}

/**
 * Record upstream success: reset failure counter.
 */
export function registerUpstreamSuccess(state: CircuitBreakerState): void {
  state.consecutiveFailures = 0
  state.openUntilMs = null
  state.halfOpenProbeActive = false
}

/**
 * Record upstream failure: increment counter and open if threshold reached.
 */
export function registerUpstreamFailure(state: CircuitBreakerState): void {
  const threshold = getCircuitBreakerFailureThreshold()
  const openSeconds = getCircuitBreakerOpenSeconds()
  const now = Date.now()

  // Half-open probe failed: reopen circuit immediately
  if (state.halfOpenProbeActive) {
    state.openUntilMs = now + openSeconds * 1000
    state.halfOpenProbeActive = false
    state.consecutiveFailures = threshold
    return
  }

  // Increment counter and potentially open circuit
  state.consecutiveFailures += 1
  if (state.consecutiveFailures >= threshold) {
    state.openUntilMs = now + openSeconds * 1000
  }
}

/**
 * Get human-readable circuit breaker status for logging.
 */
export function describeCircuitBreakerState(state: CircuitBreakerState): {
  status: 'closed' | 'open' | 'half_open'
  consecutiveFailures: number
  openUntilMs: number | null
} {
  const now = Date.now()

  if (state.openUntilMs == null) {
    return {
      status: 'closed',
      consecutiveFailures: state.consecutiveFailures,
      openUntilMs: null,
    }
  }

  if (state.openUntilMs > now) {
    return {
      status: 'open',
      consecutiveFailures: state.consecutiveFailures,
      openUntilMs: state.openUntilMs,
    }
  }

  return {
    status: state.halfOpenProbeActive ? 'half_open' : 'closed',
    consecutiveFailures: state.consecutiveFailures,
    openUntilMs: state.openUntilMs,
  }
}
