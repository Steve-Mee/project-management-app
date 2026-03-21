// Authentication and permission enforcement handler.
// Validates user identity, Mirror permission, and cloud entitlement in isolation.

type SupabaseClient = ReturnType<typeof import('https://esm.sh/@supabase/supabase-js@2').createClient>

export interface AuthUser {
  id: string
  email?: string
}

export type AuthErrorKind =
  | 'missing_auth_header'
  | 'invalid_auth_header'
  | 'auth_failed'
  | 'permission_check_failed'
  | 'permission_denied'
  | 'cloud_entitlement_failed'
  | 'cloud_entitlement_denied'

export interface AuthError {
  kind: AuthErrorKind
  message: string
  details?: Record<string, unknown>
  statusCode: number
}

export interface AuthCheckResult {
  user: AuthUser
  canUseMirror: boolean
  hasCloudEntitlement: boolean
}

/**
 * Parse and validate Authorization header.
 * Returns bearer token or error.
 */
export function parseAuthHeader(authHeaderValue: string | null): string | AuthError {
  if (!authHeaderValue || !authHeaderValue.startsWith('Bearer ')) {
    return {
      kind: 'missing_auth_header',
      message: 'Missing or invalid authorization header',
      statusCode: 401,
    }
  }

  return authHeaderValue.slice('Bearer '.length)
}

/**
 * Authenticate user via Supabase auth.
 */
export async function authenticateUser(
  supabase: SupabaseClient,
): Promise<AuthUser | AuthError> {
  try {
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return {
        kind: 'auth_failed',
        message: 'Unauthorized',
        statusCode: 401,
      }
    }

    return {
      id: user.id,
      email: user.email,
    }
  } catch (error) {
    return {
      kind: 'auth_failed',
      message: 'Unauthorized',
      details: {
        reason: 'exception',
        error: String(error),
      },
      statusCode: 401,
    }
  }
}

/**
 * Check if user has use_mirror permission.
 */
export async function checkUseMirrorPermission(
  supabase: SupabaseClient,
): Promise<boolean | AuthError> {
  try {
    const { data, error } = await supabase.rpc('has_permission', {
      permission_name: 'use_mirror',
    })

    if (error) {
      return {
        kind: 'permission_check_failed',
        message: 'Mirror permission check failed',
        details: {
          reason: 'rpc_failed',
          error: error.message,
        },
        statusCode: 403,
      }
    }

    if (data === true) {
      return true
    }

    return {
      kind: 'permission_denied',
      message: 'Insufficient permissions: use_mirror required',
      statusCode: 403,
    }
  } catch (error) {
    return {
      kind: 'permission_check_failed',
      message: 'Mirror permission check failed',
      details: {
        reason: 'exception',
        error: String(error),
      },
      statusCode: 403,
    }
  }
}

/**
 * Check if user has cloud Mirror access entitlement.
 * Only checked when mode === 'cloud'.
 */
export async function checkCloudMirrorEntitlement(
  supabase: SupabaseClient,
  requestId: string,
): Promise<boolean | AuthError> {
  try {
    const { data, error } = await supabase.rpc('has_cloud_mirror_access')

    if (error) {
      return {
        kind: 'cloud_entitlement_failed',
        message: 'Cloud Mirror entitlement check failed',
        details: {
          reason: 'rpc_failed',
          error: error.message,
          requestId,
        },
        statusCode: 403,
      }
    }

    // Handle various response shapes
    if (typeof data === 'boolean') {
      return data
    }

    if (data && typeof data === 'object') {
      const record = data as Record<string, unknown>
      const shapedValue = record['has_access'] ?? record['allowed'] ?? record['result']
      if (typeof shapedValue === 'boolean') {
        return shapedValue
      }
    }

    return {
      kind: 'cloud_entitlement_failed',
      message: 'Cloud Mirror entitlement check returned invalid shape',
      details: {
        reason: 'invalid_response_shape',
        requestId,
        response: data,
      },
      statusCode: 403,
    }
  } catch (error) {
    return {
      kind: 'cloud_entitlement_failed',
      message: 'Cloud Mirror entitlement check failed',
      details: {
        reason: 'exception',
        error: String(error),
        requestId,
      },
      statusCode: 403,
    }
  }
}

/**
 * Execute full auth + permission chain for given mode.
 * Returns complete auth result or first error encountered.
 */
export async function performFullAuthCheck(
  supabase: SupabaseClient,
  authHeader: string | null,
  mode: 'private' | 'cloud',
  requestId: string,
): Promise<AuthCheckResult | AuthError> {
  // Step 1: Parse auth header
  const tokenOrError = parseAuthHeader(authHeader)
  if ('kind' in tokenOrError) {
    return tokenOrError
  }

  // Step 2: Authenticate user
  const userOrError = await authenticateUser(supabase)
  if ('kind' in userOrError) {
    return userOrError
  }

  // Step 3: Check use_mirror permission
  const permissionOrError = await checkUseMirrorPermission(supabase)
  if (permissionOrError !== true) {
    return permissionOrError as AuthError
  }

  // Step 4: Check cloud entitlement (only if needed)
  let hasCloudEntitlement = false
  if (mode === 'cloud') {
    const entitlementOrError = await checkCloudMirrorEntitlement(supabase, requestId)
    if (entitlementOrError === true) {
      hasCloudEntitlement = true
    } else {
      return entitlementOrError as AuthError
    }
  }

  return {
    user: userOrError,
    canUseMirror: true,
    hasCloudEntitlement,
  }
}
