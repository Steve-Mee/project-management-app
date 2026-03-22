// Resilience composition handler for rate-limit and circuit-breaker middleware.

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as rateLimiterHandler from './rate_limiter_handler.ts'
import * as circuitBreakerHandler from './circuit_breaker_handler.ts'

type SupabaseClient = ReturnType<typeof createClient>

export interface RateLimitDecisionResult {
  allowed: boolean
  reason?: rateLimiterHandler.RateLimitReason
  retryAfterSeconds?: number
}

export async function evaluateRateLimitDecision({
  supabase,
  userId,
  action,
  requestId,
  onDecision,
}: {
  supabase: SupabaseClient
  userId: string
  action: 'compile' | 'apply'
  requestId: string
  onDecision: (args: {
    requestId: string
    action: 'compile' | 'apply'
    allowed: boolean
    reason?: string
  }) => void
}): Promise<RateLimitDecisionResult> {
  const check = await rateLimiterHandler.checkPerUserRateLimit(supabase, userId, action)
  onDecision({
    requestId,
    action,
    allowed: check.allowed,
    reason: check.reason,
  })

  return {
    allowed: check.allowed,
    reason: check.reason,
    retryAfterSeconds: check.retryAfterSeconds,
  }
}

export interface CircuitBreakerDecisionResult {
  allowed: boolean
  reason: circuitBreakerHandler.CircuitBreakerDecisionReason
  retryAfterSeconds?: number
}

export function evaluateCircuitBreakerDecision({
  state,
  requestId,
  action,
  onDecision,
}: {
  state: circuitBreakerHandler.CircuitBreakerState
  requestId: string
  action: 'compile' | 'apply'
  onDecision: (args: {
    requestId: string
    action: 'compile' | 'apply'
    allowed: boolean
    reason?: string
  }) => void
}): CircuitBreakerDecisionResult {
  const decision = circuitBreakerHandler.evaluateCircuitBreakerAllowance(state)
  onDecision({
    requestId,
    action,
    allowed: decision.allowed,
    reason: decision.reason,
  })

  return {
    allowed: decision.allowed,
    reason: decision.reason,
    retryAfterSeconds: decision.retryAfterSeconds,
  }
}
