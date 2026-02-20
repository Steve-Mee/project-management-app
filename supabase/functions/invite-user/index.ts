// Supabase Edge Function for sending project invitations
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface InviteRequest {
  projectId: string
  email: string
  role: string
}

// @ts-ignore - Deno global
Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Parse request body
    const { projectId, email, role }: InviteRequest = await req.json()

    // Validate input
    if (!projectId || !email || !role) {
      return new Response(JSON.stringify({ error: 'Missing required fields: projectId, email, role' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Validate role
    if (!['owner', 'admin', 'member', 'viewer'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Invalid role' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Get auth token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const authToken = authHeader.replace('Bearer ', '')

    // Create Supabase client
    const supabaseClient = createClient(
      // @ts-ignore - Deno env
      Deno.env.get('SUPABASE_URL') ?? '',
      // @ts-ignore - Deno env
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: `Bearer ${authToken}` } } }
    )

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Check if user has permission (owner/admin)
    const { data: membership, error: memberError } = await supabaseClient
      .from('project_members')
      .select('role')
      .eq('project_id', projectId)
      .eq('user_id', user.id)
      .single()

    if (memberError || !membership) {
      return new Response(JSON.stringify({ error: 'Project not found or access denied' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (membership.role !== 'owner' && membership.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Insufficient permissions' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Check if invitation already exists
    const { data: existingInvitation } = await supabaseClient
      .from('invitations')
      .select('id')
      .eq('project_id', projectId)
      .eq('email', email)
      .eq('status', 'pending')
      .single()

    if (existingInvitation) {
      return new Response(JSON.stringify({ error: 'Invitation already sent' }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Generate token
    const invitationToken = crypto.randomUUID()

    // Insert invitation
    const { error: insertError } = await supabaseClient
      .from('invitations')
      .insert({
        email,
        project_id: projectId,
        role,
        invited_by: user.id,
        status: 'pending',
        token: invitationToken,
        created_at: new Date().toISOString()
      })

    if (insertError) {
      console.error('Insert error:', insertError)
      return new Response(JSON.stringify({ error: 'Failed to create invitation' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Send email via Resend
    // @ts-ignore - Deno env
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      console.error('RESEND_API_KEY not set')
      return new Response(JSON.stringify({ error: 'Email service not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const acceptUrl = `https://myprojectmanagementapp.com/accept-invite?token=${invitationToken}`

    const emailHtml = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Uitnodiging voor project</title>
        </head>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h1 style="color: #333;">Uitnodiging voor project</h1>
          <p>U bent uitgenodigd om deel te nemen aan een project.</p>
          <p>Rol: ${role}</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${acceptUrl}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
              Accepteer uitnodiging
            </a>
          </div>
          <p>Of kopieer deze link naar uw browser: <a href="${acceptUrl}">${acceptUrl}</a></p>
          <p>Deze uitnodiging verloopt over 7 dagen.</p>
        </body>
      </html>
    `

    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'no-reply@myprojectmanagementapp.com',
        to: [email],
        subject: 'Uitnodiging voor project',
        html: emailHtml
      })
    })

    if (!emailResponse.ok) {
      console.error('Email send failed:', await emailResponse.text())
      // Don't fail the request if email fails, but log it
    }

    return new Response(JSON.stringify({ success: true, token: invitationToken }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})