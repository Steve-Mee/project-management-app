// Rate limiter handler: per-user quota enforcement.
// Tracks compile/apply request counts per minute and burst windows with weighted units.

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type SupabaseClient = ReturnType<typeof createClient>

const DEFAULT_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE = 10
const DEFAULT_GATEWAY_RATE_LIMIT_BURST = 30
const DEFAULT_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS = 180
const DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE = 1
const DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY = 2
const DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE = 20
const DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST = 50
const RATE_LIMIT_COUNTABLE_STATUSES = ['processing', 'completed'] as const

export type RateLimitReason = 'minute_rate' | 'burst_quota' | 'weighted_minute' | 'weighted_burst'

export interface RateLimitCheckResult {
  allowed: boolean
  reason?: RateLimitReason
  retryAfterSeconds?: number
  minuteCount: number
  burstCount: number
  weightedMinuteUnits: number
  weightedBurstUnits: number
  weightedMinuteLimit: number
  weightedBurstLimit: number
}

/**
 * Parse positive integer environment variable with fallback.
 */
function parsePositiveIntegerEnv(key: string, fallback: number): number {
  const deno = (globalThis as any).Deno
  const raw = deno?.env?.get?.(key)
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return fallback
}

/**
 * Parse positive float environment variable with fallback.
 */
function parsePositiveNumberEnv(key: string, fallback: number): number {
  const deno = (globalThis as any).Deno
  const raw = deno?.env?.get?.(key)
  const parsed = raw ? Number.parseFloat(raw) : Number.NaN
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed
  }
  return fallback
}

/**
 * Get configured requests per minute limit.
 */
export function gatewayRateLimitRequestsPerMinute(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE',
    DEFAULT_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE,
  )
}

/**
 * Get configured burst limit.
 */
export function gatewayRateLimitBurst(): number {
  return parsePositiveIntegerEnv('MIRROR_GATEWAY_RATE_LIMIT_BURST', DEFAULT_GATEWAY_RATE_LIMIT_BURST)
}

/**
 * Get configured burst window in seconds.
 */
export function gatewayRateLimitBurstWindowSeconds(): number {
  return parsePositiveIntegerEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS',
    DEFAULT_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS,
  )
}

/**
 * Get configured action weight (compile vs apply).
 */
export function gatewayRateLimitActionWeight(action: 'compile' | 'apply'): number {
  return action === 'apply'
    ? parsePositiveNumberEnv(
        'MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY',
        DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY,
      )
    : parsePositiveNumberEnv(
        'MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE',
        DEFAULT_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE,
      )
}

/**
 * Get configured weighted units per minute limit.
 */
export function gatewayRateLimitWeightedUnitsPerMinute(): number {
  return parsePositiveNumberEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE',
    DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE,
  )
}

/**
 * Get configured weighted units burst limit.
 */
export function gatewayRateLimitWeightedUnitsBurst(): number {
  return parsePositiveNumberEnv(
    'MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST',
    DEFAULT_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST,
  )
}

/**
 * Count requests in time window matching status filter.
 */
async function countRateLimitRequestsInWindow({
  supabase,
  userId,
  action,
  nowIso,
  windowStartIso,
}: {
  supabase: SupabaseClient
  userId: string
  action: 'compile' | 'apply'
  nowIso: string
  windowStartIso: string
}): Promise<number> {
  const { count, error } = await supabase
    .from('mirror_request_idempotency')
    .select('*', { head: true, count: 'exact' })
    .eq('user_id', userId)
    .eq('action', action)
    .in('status', [...RATE_LIMIT_COUNTABLE_STATUSES])
    .gt('expires_at', nowIso)
    .gte('created_at', windowStartIso)

  if (error) {
    throw new Error(`rate_limit_check_failed:${error.message}`)
  }

  return count ?? 0
}

/**
 * Check per-user rate limit with minute and burst windows plus weighted units.
 * Returns allowed: true/false with reason if denied and retry-after seconds.
 */
export async function checkPerUserRateLimit(
  supabase: SupabaseClient,
  userId: string,
  action: 'compile' | 'apply',
): Promise<RateLimitCheckResult> {
  const minuteLimit = gatewayRateLimitRequestsPerMinute()
  const burstLimit = gatewayRateLimitBurst()
  const burstWindowSeconds = gatewayRateLimitBurstWindowSeconds()

  const nowIso = new Date().toISOString()
  const oneMinuteAgo = new Date(Date.now() - 60 * 1000).toISOString()
  const burstWindowStart = new Date(Date.now() - burstWindowSeconds * 1000).toISOString()

  // Count requests in each window
  const [minuteCount, burstCount] = await Promise.all([
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action,
      nowIso,
      windowStartIso: oneMinuteAgo,
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action,
      nowIso,
      windowStartIso: burstWindowStart,
    }),
  ])

  // Count by action type for weighted calculation
  const [minuteCompileCount, minuteApplyCount, burstCompileCount, burstApplyCount] = await Promise.all([
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'compile',
      nowIso,
      windowStartIso: oneMinuteAgo,
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'apply',
      nowIso,
      windowStartIso: oneMinuteAgo,
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'compile',
      nowIso,
      windowStartIso: burstWindowStart,
    }),
    countRateLimitRequestsInWindow({
      supabase,
      userId,
      action: 'apply',
      nowIso,
      windowStartIso: burstWindowStart,
    }),
  ])

  // Calculate weighted units
  const compileWeight = gatewayRateLimitActionWeight('compile')
  const applyWeight = gatewayRateLimitActionWeight('apply')
  const weightedMinuteLimit = gatewayRateLimitWeightedUnitsPerMinute()
  const weightedBurstLimit = gatewayRateLimitWeightedUnitsBurst()
  const weightedMinuteUnits = minuteCompileCount * compileWeight + minuteApplyCount * applyWeight
  const weightedBurstUnits = burstCompileCount * compileWeight + burstApplyCount * applyWeight

  // Check limits in priority order
  if (minuteCount >= minuteLimit) {
    return {
      allowed: false,
      reason: 'minute_rate',
      retryAfterSeconds: 60,
      minuteCount,
      burstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (burstCount >= burstLimit) {
    return {
      allowed: false,
      reason: 'burst_quota',
      retryAfterSeconds: burstWindowSeconds,
      minuteCount,
      burstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (weightedMinuteUnits >= weightedMinuteLimit) {
    return {
      allowed: false,
      reason: 'weighted_minute',
      retryAfterSeconds: 60,
      minuteCount,
      burstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  if (weightedBurstUnits >= weightedBurstLimit) {
    return {
      allowed: false,
      reason: 'weighted_burst',
      retryAfterSeconds: burstWindowSeconds,
      minuteCount,
      burstCount,
      weightedMinuteUnits,
      weightedBurstUnits,
      weightedMinuteLimit,
      weightedBurstLimit,
    }
  }

  return {
    allowed: true,
    minuteCount,
    burstCount,
    weightedMinuteUnits,
    weightedBurstUnits,
    weightedMinuteLimit,
    weightedBurstLimit,
  }
}
