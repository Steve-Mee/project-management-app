// Supabase Edge Function for handling Stripe webhooks
// @ts-ignore - ESM import for Supabase in Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

// Type declarations for Deno global
declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
  env: {
    get: (key: string) => string | undefined;
  };
};

// Stripe webhook signature verification
function verifyStripeSignature(payload: string, signature: string, secret: string): boolean {
  // In production, implement proper signature verification using crypto
  // For now, return true for demo purposes
  return true
}

interface StripeWebhookEvent {
  id: string
  object: string
  api_version: string
  created: number
  data: {
    object: any
  }
  livemode: boolean
  pending_webhooks: number
  request: {
    id: string
    idempotency_key: string
  }
  type: string
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

    // Get Stripe signature from headers
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      return new Response(JSON.stringify({ error: 'Missing Stripe signature' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Get request body as text for signature verification
    const body = await req.text()

    // Get Stripe secret key from environment
    // @ts-ignore - Deno global
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeSecretKey) {
      return new Response(JSON.stringify({ error: 'Stripe secret key not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Verify webhook signature
    if (!verifyStripeSignature(body, signature, stripeSecretKey)) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Parse webhook payload
    const event: StripeWebhookEvent = JSON.parse(body)

    // Initialize Supabase client
    // @ts-ignore - Deno global
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    // @ts-ignore - Deno global
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSucceeded(supabase, event.data.object)
        break

      case 'payment_intent.payment_failed':
        await handlePaymentFailed(supabase, event.data.object)
        break

      case 'checkout.session.completed':
        await handleCheckoutCompleted(supabase, event.data.object)
        break

      default:
        // Log unhandled event types
        console.log(`Unhandled event type: ${event.type}`)
    }

    // Log successful webhook processing
    console.log('stripe_webhook_processed', {
      eventId: event.id,
      eventType: event.type,
      timestamp: new Date().toISOString()
    })

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})

async function handlePaymentSucceeded(supabase: any, paymentIntent: any) {
  const customerId = paymentIntent.customer

  // Find subscription by Stripe customer ID
  const { data: subscription, error } = await supabase
    .from('subscriptions')
    .select('user_id, status')
    .eq('stripe_customer_id', customerId)
    .single()

  if (error || !subscription) {
    console.error('Subscription not found for customer ID:', customerId)
    return
  }

  // Update subscription status
  await supabase
    .from('subscriptions')
    .update({
      status: 'active',
      updated_at: new Date().toISOString()
    })
    .eq('user_id', subscription.user_id)

  console.log('Updated subscription to active for user:', subscription.user_id)
}

async function handlePaymentFailed(supabase: any, paymentIntent: any) {
  const customerId = paymentIntent.customer

  // Find subscription by Stripe customer ID
  const { data: subscription, error } = await supabase
    .from('subscriptions')
    .select('user_id, status')
    .eq('stripe_customer_id', customerId)
    .single()

  if (error || !subscription) {
    console.error('Subscription not found for customer ID:', customerId)
    return
  }

  // Update subscription status to failed
  await supabase
    .from('subscriptions')
    .update({
      status: 'payment_failed',
      updated_at: new Date().toISOString()
    })
    .eq('user_id', subscription.user_id)

  console.log('Updated subscription to payment_failed for user:', subscription.user_id)
}

async function handleCheckoutCompleted(supabase: any, session: any) {
  const customerId = session.customer
  const paymentStatus = session.payment_status

  // Find subscription by Stripe customer ID
  const { data: subscription, error } = await supabase
    .from('subscriptions')
    .select('user_id, status')
    .eq('stripe_customer_id', customerId)
    .single()

  if (error || !subscription) {
    console.error('Subscription not found for customer ID:', customerId)
    return
  }

  // Update subscription status based on payment status
  const newStatus = paymentStatus === 'paid' ? 'active' : 'pending'

  await supabase
    .from('subscriptions')
    .update({
      status: newStatus,
      updated_at: new Date().toISOString()
    })
    .eq('user_id', subscription.user_id)

  console.log(`Updated subscription to ${newStatus} for user:`, subscription.user_id)
}