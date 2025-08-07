import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import Stripe from "https://esm.sh/stripe@14.21.0";
import { getCorsHeaders } from "../_shared/cors.ts";

// Environment validation
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!STRIPE_SECRET_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing required environment variables");
  throw new Error("Server configuration error");
}

// Initialize clients
const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
});

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

interface SyncRequest {
  product: {
    id: string;
    name: string;
    description?: string;
    sku?: string;
    metadata?: Record<string, string>;
  };
  variants: Array<{
    id: string;
    price: number;
    title: string;
    sku?: string;
    metadata?: Record<string, string>;
  }>;
  mode: 'create' | 'update';
  test?: boolean;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req.headers.get("origin"));

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body: SyncRequest = await req.json();

    // Test mode - just validate
    if (body.test) {
      return new Response(
        JSON.stringify({ success: true, message: "Edge Function is ready" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let stripeProduct;
    
    // Create or update Stripe product
    if (body.mode === 'create') {
      stripeProduct = await stripe.products.create({
        name: body.product.name,
        description: body.product.description,
        metadata: {
          ...body.product.metadata,
          supabase_id: body.product.id,
        },
        default_price_data: body.variants.length === 1 ? {
          currency: 'usd',
          unit_amount: Math.round(body.variants[0].price * 100), // Convert to cents
        } : undefined,
      });
    } else {
      // Update existing product
      const { data: existingProduct } = await supabase
        .from('products')
        .select('stripe_product_id')
        .eq('id', body.product.id)
        .single();

      if (!existingProduct?.stripe_product_id) {
        throw new Error('Product not found or not synced');
      }

      stripeProduct = await stripe.products.update(existingProduct.stripe_product_id, {
        name: body.product.name,
        description: body.product.description,
        metadata: {
          ...body.product.metadata,
          supabase_id: body.product.id,
        },
      });
    }

    // Create prices for each variant
    const priceIds: Record<string, string> = {};
    
    for (const variant of body.variants) {
      try {
        // Check if price already exists
        const { data: existingVariant } = await supabase
          .from('product_variants')
          .select('stripe_price_id')
          .eq('id', variant.id)
          .single();

        let stripePrice;
        
        if (existingVariant?.stripe_price_id && body.mode === 'update') {
          // Price objects are immutable in Stripe, so we need to create a new one
          // and archive the old one if the price changed
          const existingPrice = await stripe.prices.retrieve(existingVariant.stripe_price_id);
          
          if (existingPrice.unit_amount !== Math.round(variant.price * 100)) {
            // Archive old price
            await stripe.prices.update(existingVariant.stripe_price_id, { active: false });
            
            // Create new price
            stripePrice = await stripe.prices.create({
              product: stripeProduct.id,
              currency: 'usd',
              unit_amount: Math.round(variant.price * 100),
              nickname: variant.title,
              metadata: {
                ...variant.metadata,
                supabase_variant_id: variant.id,
              },
            });
          } else {
            // Price hasn't changed, keep existing
            stripePrice = existingPrice;
          }
        } else {
          // Create new price
          stripePrice = await stripe.prices.create({
            product: stripeProduct.id,
            currency: 'usd',
            unit_amount: Math.round(variant.price * 100),
            nickname: variant.title,
            metadata: {
              ...variant.metadata,
              supabase_variant_id: variant.id,
            },
          });
        }
        
        priceIds[variant.id] = stripePrice.id;
      } catch (error) {
        console.error(`Failed to create price for variant ${variant.id}:`, error);
      }
    }

    // Log the sync operation
    await supabase
      .from('stripe_sync_log')
      .insert({
        sync_type: 'product',
        entity_id: body.product.id,
        entity_type: 'product',
        stripe_id: stripeProduct.id,
        action: body.mode,
        status: 'success',
        metadata: {
          product_name: body.product.name,
          variants_synced: Object.keys(priceIds).length,
          stripe_product_id: stripeProduct.id,
        },
      });

    return new Response(
      JSON.stringify({
        success: true,
        stripe_product_id: stripeProduct.id,
        price_ids: priceIds,
        message: `Successfully ${body.mode}d product in Stripe`,
      }),
      { 
        headers: { 
          ...corsHeaders, 
          "Content-Type": "application/json" 
        },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Sync error:', error);
    
    // Log the error
    if (body?.product?.id) {
      await supabase
        .from('stripe_sync_log')
        .insert({
          sync_type: 'product',
          entity_id: body.product.id,
          entity_type: 'product',
          action: 'error',
          status: 'failed',
          error_message: error.message,
        });
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { 
        headers: { 
          ...corsHeaders, 
          "Content-Type": "application/json" 
        },
        status: 400,
      }
    );
  }
});