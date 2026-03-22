// Gateway middleware composition helpers.
// Keeps index.ts orchestration-focused by centralizing reusable middleware context wiring.

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface GatewayBaseContext {
  req: Request
  requestId: string
  traceId: string
  idempotencyKey: string
}

export interface GatewaySupabaseContext extends GatewayBaseContext {
  supabase: ReturnType<typeof createClient>
}

export function ensureGatewayEnv():
  | { ok: true; supabaseUrl: string; supabaseAnonKey: string }
  | { ok: false; reason: 'missing_supabase_env' } {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

  if (!supabaseUrl || !supabaseAnonKey) {
    return { ok: false, reason: 'missing_supabase_env' }
  }

  return { ok: true, supabaseUrl, supabaseAnonKey }
}

export function buildSupabaseClientForRequest(args: {
  supabaseUrl: string
  supabaseAnonKey: string
  authHeader: string | null
}): ReturnType<typeof createClient> {
  return createClient(args.supabaseUrl, args.supabaseAnonKey, {
    global: { headers: { Authorization: args.authHeader ?? '' } },
  })
}
