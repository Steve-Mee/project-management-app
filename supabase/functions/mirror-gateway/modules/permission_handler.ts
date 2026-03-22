// Permission composition handler for gateway entrypoint.
// Wraps auth + entitlement flow so index.ts remains orchestration-focused.

// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as authHandler from './auth_handler.ts'

type SupabaseClient = ReturnType<typeof createClient>

export type GatewayAuthResult =
  | { ok: true; user: authHandler.AuthUser }
  | { ok: false; error: authHandler.AuthError }

export async function performGatewayAuthCheck({
  supabase,
  authHeader,
  mode,
  requestId,
}: {
  supabase: SupabaseClient
  authHeader: string | null
  mode: 'private' | 'cloud'
  requestId: string
}): Promise<GatewayAuthResult> {
  const result = await authHandler.performFullAuthCheck(
    supabase,
    authHeader,
    mode,
    requestId,
  )

  if ('kind' in result) {
    return { ok: false, error: result }
  }

  return {
    ok: true,
    user: result.user,
  }
}
