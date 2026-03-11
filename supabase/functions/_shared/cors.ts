// SECURITY: In production, Access-Control-Allow-Origin must never be a wildcard.
// Set ALLOWED_ORIGINS to a comma-separated allowlist in your Supabase project secrets,
// e.g. "https://app.example.com,https://staging.example.com".
// When ALLOWED_ORIGINS is absent the function falls back to wildcard (*), which is
// acceptable only during local development (supabase start / serve).
const _allowedOrigins: string[] =
  (Deno.env.get('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);

/** Returns CORS headers for `request`.
 *  In production (ALLOWED_ORIGINS set) the reflected origin is validated
 *  against the allowlist; unrecognised origins receive a null origin so the
 *  browser blocks the response.  In development the wildcard is returned. */
export function corsHeaders(request: Request): Record<string, string> {
  const allowOrigin =
    _allowedOrigins.length === 0
      ? '*'
      : (() => {
          const origin = request.headers.get('Origin') ?? '';
          return _allowedOrigins.includes(origin) ? origin : 'null';
        })();

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Vary': 'Origin',
  };
}
