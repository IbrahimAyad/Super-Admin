import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@13.10.0?target=deno';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Stripe
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    });

    // Initialize Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get request body
    const { cart, customerInfo, sessionId, metadata } = await req.json();

    if (!cart || cart.length === 0) {
      throw new Error('Cart is empty');
    }

    // Calculate total
    const subtotal = cart.reduce((sum: number, item: any) => {
      return sum + (item.product.base_price * item.quantity);
    }, 0);

    // Create line items for Stripe
    const lineItems = cart.map((item: any) => ({
      price_data: {
        currency: 'usd',
        product_data: {
          name: item.product.name,
          description: `${item.product.category} - Size: ${item.size || 'Not specified'}`,
          images: item.product.images?.hero?.url ? [item.product.images.hero.url] : [],
          metadata: {
            product_id: item.product.id,
            sku: item.product.sku,
            size: item.size || '',
          },
        },
        unit_amount: item.product.base_price, // Price in cents
      },
      quantity: item.quantity,
    }));

    // Create Stripe checkout session
    const checkoutSession = await stripe.checkout.sessions.create({
      payment_method_types: ['card', 'apple_pay', 'google_pay'],
      line_items: lineItems,
      mode: 'payment',
      success_url: `${Deno.env.get('SITE_URL')}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${Deno.env.get('SITE_URL')}/checkout/cancel`,
      customer_email: customerInfo?.email,
      shipping_address_collection: {
        allowed_countries: ['US', 'CA'],
      },
      shipping_options: [
        {
          shipping_rate_data: {
            type: 'fixed_amount',
            fixed_amount: {
              amount: 0,
              currency: 'usd',
            },
            display_name: 'Free Shipping',
            delivery_estimate: {
              minimum: {
                unit: 'business_day',
                value: 5,
              },
              maximum: {
                unit: 'business_day',
                value: 7,
              },
            },
          },
        },
        {
          shipping_rate_data: {
            type: 'fixed_amount',
            fixed_amount: {
              amount: 2500, // $25
              currency: 'usd',
            },
            display_name: 'Express Shipping',
            delivery_estimate: {
              minimum: {
                unit: 'business_day',
                value: 2,
              },
              maximum: {
                unit: 'business_day',
                value: 3,
              },
            },
          },
        },
        {
          shipping_rate_data: {
            type: 'fixed_amount',
            fixed_amount: {
              amount: 5000, // $50
              currency: 'usd',
            },
            display_name: 'Overnight Shipping',
            delivery_estimate: {
              minimum: {
                unit: 'business_day',
                value: 1,
              },
              maximum: {
                unit: 'business_day',
                value: 1,
              },
            },
          },
        },
      ],
      allow_promotion_codes: true,
      metadata: {
        chat_session_id: sessionId,
        source: 'chat_checkout',
        ...metadata,
      },
      custom_text: {
        submit: {
          message: 'We\'ll securely process your payment and send order confirmation.',
        },
      },
      consent_collection: {
        promotions: 'auto',
      },
      invoice_creation: {
        enabled: true,
      },
    });

    // Store checkout session in database for tracking
    const { error: dbError } = await supabase
      .from('checkout_sessions')
      .insert({
        session_id: checkoutSession.id,
        chat_session_id: sessionId,
        customer_email: customerInfo?.email,
        cart_data: cart,
        amount: subtotal,
        status: 'pending',
        created_at: new Date().toISOString(),
      });

    if (dbError) {
      console.error('Error storing checkout session:', dbError);
      // Don't fail the request, just log the error
    }

    // Return checkout URL to redirect user
    return new Response(
      JSON.stringify({
        url: checkoutSession.url,
        sessionId: checkoutSession.id,
        amount: subtotal,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error creating checkout session:', error);
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to create checkout session',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});