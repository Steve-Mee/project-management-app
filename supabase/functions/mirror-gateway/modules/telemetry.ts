// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export type MirrorUsageStatus =
  | 'success'
  | 'failed'
  | 'rate_limited'
  | 'timeout'
  | 'upstream_error'

export async function writeMirrorUsageLog({
  supabase,
  userId,
  projectId,
  taskId,
  mode,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: ReturnType<typeof createClient>
  userId: string
  projectId: string
  taskId: string
  mode: 'private' | 'cloud'
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number
}): Promise<void> {
  const payload = {
    user_id: userId,
    project_id: projectId,
    task_id: taskId,
    mode,
    action,
    duration_ms: Math.max(0, Date.now() - startedAtMs),
    status,
    request_id: requestId,
    idempotency_key: idempotencyKey,
  }

  const { error } = await supabase.from('mirror_usage_logs').insert(payload)
  if (error) {
    console.error('mirror-gateway usage metering write failed:', error.message)
  }
}

export async function writeMirrorUsageLogIfReady({
  supabase,
  userId,
  projectId,
  taskId,
  mode,
  action,
  status,
  requestId,
  idempotencyKey,
  startedAtMs,
}: {
  supabase: ReturnType<typeof createClient> | null
  userId: string | null
  projectId: string | null
  taskId: string | null
  mode: 'private' | 'cloud' | null
  action: 'compile' | 'apply'
  status: MirrorUsageStatus
  requestId: string
  idempotencyKey: string
  startedAtMs: number | null
}): Promise<void> {
  if (!supabase || !userId || !projectId || !taskId || !mode || startedAtMs == null) {
    return
  }

  await writeMirrorUsageLog({
    supabase,
    userId,
    projectId,
    taskId,
    mode,
    action,
    status,
    requestId,
    idempotencyKey,
    startedAtMs,
  })
}
