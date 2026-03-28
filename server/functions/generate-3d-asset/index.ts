// Supabase Edge Function for queuing 3D generation jobs
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../../../supabase/functions/_shared/cors.ts'

declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
  env: {
    get: (key: string) => string | undefined
  }
}

type LlmProvider = 'openai' | 'claude'
type GenerationFormat = 'glb' | 'fbx' | 'png' | 'usdz'
type GenerationEngine = 'blender' | 'tripo' | 'hunyuan3d'
type GenerationResolution = '512' | '1024' | '2048' | '4k'

interface GenerateThreeDRequest {
  prompt: string
  projectId: string
  taskId?: string | null
  settings?: {
    resolution?: GenerationResolution
    format?: GenerationFormat
    engine?: GenerationEngine
  }
}

interface NormalizedSettings {
  resolution: GenerationResolution
  format: GenerationFormat
  engine: GenerationEngine
}

interface StructuredGenerationPlan {
  provider: LlmProvider
  blenderScript: string | null
  meshApi: {
    provider: 'tripo' | 'hunyuan3d' | null
    endpoint: string | null
    payload: Record<string, unknown> | null
  }
  promptSummary: string
  warnings: string[]
}

const DEFAULT_SETTINGS: NormalizedSettings = {
  resolution: '1024',
  format: 'glb',
  engine: 'blender',
}

function jsonResponse(req: Request, body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), 'Content-Type': 'application/json' },
  })
}

function normalizeSettings(input?: GenerateThreeDRequest['settings']): NormalizedSettings {
  const resolution = input?.resolution
  const format = input?.format
  const engine = input?.engine

  return {
    resolution:
      resolution === '512' || resolution === '1024' || resolution === '2048' || resolution === '4k'
        ? resolution
        : DEFAULT_SETTINGS.resolution,
    format:
      format === 'glb' || format === 'fbx' || format === 'png' || format === 'usdz'
        ? format
        : DEFAULT_SETTINGS.format,
    engine:
      engine === 'blender' || engine === 'tripo' || engine === 'hunyuan3d'
        ? engine
        : DEFAULT_SETTINGS.engine,
  }
}

function normalizeRequest(payload: GenerateThreeDRequest):
  | { ok: true; value: { prompt: string; projectId: string; taskId: string | null; settings: NormalizedSettings } }
  | { ok: false; error: string } {
  const prompt = payload.prompt?.trim()
  const projectId = payload.projectId?.trim()
  const taskId = payload.taskId?.trim() || null

  if (!prompt) {
    return { ok: false, error: 'Missing required field: prompt' }
  }

  if (!projectId) {
    return { ok: false, error: 'Missing required field: projectId' }
  }

  return {
    ok: true,
    value: {
      prompt,
      projectId,
      taskId,
      settings: normalizeSettings(payload.settings),
    },
  }
}

async function generateWithOpenAi(args: {
  prompt: string
  settings: NormalizedSettings
}): Promise<StructuredGenerationPlan> {
  const apiKey = Deno.env.get('OPENAI_API_KEY')
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured')
  }

  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('THREE_D_OPENAI_MODEL') ?? 'gpt-4.1-mini',
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'text',
              text:
                'Convert user prompts into safe, deterministic 3D generation plans. Return JSON only with fields: promptSummary, blenderScript, meshApi{provider,endpoint,payload}, warnings.',
            },
          ],
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: `Prompt: ${args.prompt}\nSettings: ${JSON.stringify(args.settings)}`,
            },
          ],
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'three_d_generation_plan',
          schema: {
            type: 'object',
            additionalProperties: false,
            properties: {
              promptSummary: { type: 'string' },
              blenderScript: { type: ['string', 'null'] },
              meshApi: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  provider: { type: ['string', 'null'], enum: ['tripo', 'hunyuan3d', null] },
                  endpoint: { type: ['string', 'null'] },
                  payload: { type: ['object', 'null'] },
                },
                required: ['provider', 'endpoint', 'payload'],
              },
              warnings: {
                type: 'array',
                items: { type: 'string' },
              },
            },
            required: ['promptSummary', 'blenderScript', 'meshApi', 'warnings'],
          },
        },
      },
    }),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`OpenAI planning failed: ${text}`)
  }

  const data = await response.json()
  const jsonText = data?.output?.[0]?.content?.[0]?.text
  if (typeof jsonText !== 'string') {
    throw new Error('OpenAI planning failed: missing JSON output')
  }

  const parsed = JSON.parse(jsonText)
  return {
    provider: 'openai',
    blenderScript: parsed.blenderScript ?? null,
    meshApi: {
      provider: parsed.meshApi?.provider ?? null,
      endpoint: parsed.meshApi?.endpoint ?? null,
      payload: parsed.meshApi?.payload ?? null,
    },
    promptSummary: parsed.promptSummary ?? args.prompt,
    warnings: Array.isArray(parsed.warnings) ? parsed.warnings : [],
  }
}

async function generateWithClaude(args: {
  prompt: string
  settings: NormalizedSettings
}): Promise<StructuredGenerationPlan> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY is not configured')
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('THREE_D_CLAUDE_MODEL') ?? 'claude-3-5-sonnet-20241022',
      max_tokens: 1200,
      system:
        'Return JSON only. Build a safe and deterministic 3D generation plan with fields promptSummary, blenderScript, meshApi{provider,endpoint,payload}, warnings.',
      messages: [
        {
          role: 'user',
          content: `Prompt: ${args.prompt}\nSettings: ${JSON.stringify(args.settings)}`,
        },
      ],
    }),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Claude planning failed: ${text}`)
  }

  const data = await response.json()
  const textContent = data?.content?.[0]?.text
  if (typeof textContent !== 'string') {
    throw new Error('Claude planning failed: missing JSON output')
  }

  const parsed = JSON.parse(textContent)
  return {
    provider: 'claude',
    blenderScript: parsed.blenderScript ?? null,
    meshApi: {
      provider: parsed.meshApi?.provider ?? null,
      endpoint: parsed.meshApi?.endpoint ?? null,
      payload: parsed.meshApi?.payload ?? null,
    },
    promptSummary: parsed.promptSummary ?? args.prompt,
    warnings: Array.isArray(parsed.warnings) ? parsed.warnings : [],
  }
}

async function buildStructuredPlan(args: {
  prompt: string
  settings: NormalizedSettings
}): Promise<StructuredGenerationPlan> {
  const preferredProvider = (Deno.env.get('THREE_D_LLM_PROVIDER') ?? 'openai').toLowerCase()

  if (preferredProvider === 'claude') {
    return generateWithClaude(args)
  }

  return generateWithOpenAi(args)
}

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(req) })
  }

  try {
    if (req.method !== 'POST') {
      return jsonResponse(req, { error: 'Method not allowed' }, 405)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse(req, { error: 'Missing or invalid authorization header' }, 401)
    }

    const body = (await req.json()) as GenerateThreeDRequest
    const normalized = normalizeRequest(body)
    if (!normalized.ok) {
      return jsonResponse(req, { error: normalized.error }, 400)
    }

    const { prompt, projectId, taskId, settings } = normalized.value

    // Same request-scoped auth client pattern as existing functions.
    const userScopedClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: authData, error: authError } = await userScopedClient.auth.getUser()
    if (authError || !authData?.user) {
      return jsonResponse(req, { error: 'Invalid token' }, 401)
    }

    const userId = authData.user.id

    const { data: membership, error: membershipError } = await userScopedClient
      .from('project_members')
      .select('role')
      .eq('project_id', projectId)
      .eq('user_id', userId)
      .single()

    if (membershipError || !membership) {
      return jsonResponse(req, { error: 'Project not found or access denied' }, 403)
    }

    const structuredPlan = await buildStructuredPlan({ prompt, settings })

    // Same service-role client pattern used by privileged edge functions.
    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const jobId = crypto.randomUUID()
    const nowIso = new Date().toISOString()

    const queuePayload = {
      id: jobId,
      project_id: projectId,
      task_id: taskId,
      user_id: userId,
      prompt,
      settings,
      provider: structuredPlan.provider,
      generation_plan: {
        blender_script: structuredPlan.blenderScript,
        mesh_api: structuredPlan.meshApi,
        prompt_summary: structuredPlan.promptSummary,
        warnings: structuredPlan.warnings,
      },
      status: 'queued',
      created_at: nowIso,
      updated_at: nowIso,
    }

    const { error: queueError } = await serviceClient
      .from('three_d_generation_queue')
      .insert(queuePayload)

    if (queueError) {
      console.error('three_d_generation_queue_insert_failed', queueError)
      return jsonResponse(req, { error: 'Failed to queue 3D generation job' }, 500)
    }

    return jsonResponse(req, {
      success: true,
      jobId,
      status: 'queued',
      projectId,
      taskId,
    })
  } catch (error) {
    console.error('generate_3d_asset_unexpected_error', error)
    return jsonResponse(req, { error: 'Internal server error' }, 500)
  }
})
