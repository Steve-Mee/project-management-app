// Supabase Edge Function stub for Mirror compute forwarding
// Routes requests to private compute bridge or Fly.io HTTPS endpoint based on mode.
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
  env: {
    get: (key: string) => string | undefined
  }
}

interface MirrorComputeRequest {
  prompt: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
}

interface ForwardPayload {
  prompt: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  userId: string
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function resolveForwardEndpoint(mode: 'private' | 'cloud'): string {
  // PRIVATE_COMPUTE_ENDPOINT should point to an HTTP bridge in front of local gRPC.
  const privateEndpoint =
    Deno.env.get('PRIVATE_COMPUTE_ENDPOINT') ?? 'http://127.0.0.1:50051/mirror_compute'
  const flyEndpoint =
    Deno.env.get('FLY_MIRROR_COMPUTE_ENDPOINT') ?? 'https://mirror-compute.fly.dev/mirror_compute'

  return mode === 'private' ? privateEndpoint : flyEndpoint
}

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Missing or invalid authorization header' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse({ error: 'Supabase environment is not configured' }, 500)
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const body: Partial<MirrorComputeRequest> = await req.json()
    const { prompt, projectId, taskId, mode } = body

    if (!prompt || !projectId || !taskId || !mode) {
      return jsonResponse(
        { error: 'Missing required fields: prompt, projectId, taskId, mode' },
        400,
      )
    }

    if (mode !== 'private' && mode !== 'cloud') {
      return jsonResponse({ error: "Invalid mode. Expected 'private' or 'cloud'" }, 400)
    }

    const targetUrl = resolveForwardEndpoint(mode)
    const payload: ForwardPayload = {
      prompt,
      projectId,
      taskId,
      mode,
      userId: user.id,
    }

    const upstreamResponse = await fetch(targetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authHeader,
        'x-user-id': user.id,
      },
      body: JSON.stringify(payload),
    })

    const contentType = upstreamResponse.headers.get('content-type') ?? 'application/json'
    const upstreamBody = await upstreamResponse.text()

    return new Response(upstreamBody, {
      status: upstreamResponse.status,
      headers: { ...corsHeaders, 'Content-Type': contentType },
    })
  } catch (error) {
    console.error('mirror_compute forwarding error:', error)
    return jsonResponse({ error: 'Internal server error' }, 500)
  }
})
