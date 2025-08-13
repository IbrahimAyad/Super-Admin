/**
 * Sync Supabase Products to Stripe
 * This script creates Stripe products and prices for all Supabase products
 * Run this to enable checkout for imported products
 */

import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// Configuration
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY'; // Replace with actual key
const STRIPE_SECRET_KEY = 'sk_live_YOUR_KEY'; // Replace with actual key

// Initialize clients
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' });

// Batch processing settings
const BATCH_SIZE = 10;
const DELAY_MS = 1000; // Delay between batches to avoid rate limits

interface Product {
  id: string;
  sku: string;
  name: string;
  description: string;
  category: string;
  primary_image: string;
  stripe_product_id?: string;
}

interface Variant {
  id: string;
  product_id: string;
  title: string;
  sku: string;
  price: number;
  option1?: string; // size
  option2?: string; // color
  stripe_price_id?: string;
}

async function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function createStripeProduct(product: Product): Promise<string | null> {
  try {
    // Check if product already exists in Stripe
    if (product.stripe_product_id) {
      console.log(`Product ${product.sku} already has Stripe ID: ${product.stripe_product_id}`);
      return product.stripe_product_id;
    }

    // Create product in Stripe
    const stripeProduct = await stripe.products.create({
      id: `prod_${product.sku.replace(/[^a-zA-Z0-9]/g, '_')}`, // Create predictable ID
      name: product.name,
      description: product.description || `Premium ${product.category}`,
      images: product.primary_image ? [product.primary_image] : [],
      metadata: {
        supabase_id: product.id,
        sku: product.sku,
        category: product.category
      },
      active: true
    });

    // Update Supabase with Stripe product ID
    await supabase
      .from('products')
      .update({ 
        stripe_product_id: stripeProduct.id,
        stripe_active: true 
      })
      .eq('id', product.id);

    console.log(`✅ Created Stripe product: ${product.name} (${stripeProduct.id})`);
    return stripeProduct.id;

  } catch (error: any) {
    // If product already exists with this ID, retrieve it
    if (error.code === 'resource_already_exists') {
      const existingProduct = await stripe.products.retrieve(
        `prod_${product.sku.replace(/[^a-zA-Z0-9]/g, '_')}`
      );
      
      await supabase
        .from('products')
        .update({ 
          stripe_product_id: existingProduct.id,
          stripe_active: true 
        })
        .eq('id', product.id);

      console.log(`✅ Linked existing Stripe product: ${product.name} (${existingProduct.id})`);
      return existingProduct.id;
    }

    console.error(`❌ Failed to create product ${product.sku}:`, error.message);
    return null;
  }
}

async function createStripePrice(variant: Variant, stripeProductId: string): Promise<string | null> {
  try {
    // Check if price already exists
    if (variant.stripe_price_id) {
      console.log(`  Variant ${variant.sku} already has Stripe price: ${variant.stripe_price_id}`);
      return variant.stripe_price_id;
    }

    // Create price in Stripe
    const stripePrice = await stripe.prices.create({
      product: stripeProductId,
      unit_amount: variant.price, // Already in cents
      currency: 'usd',
      nickname: variant.title,
      metadata: {
        supabase_variant_id: variant.id,
        sku: variant.sku,
        size: variant.option1 || '',
        color: variant.option2 || ''
      }
    });

    // Update Supabase with Stripe price ID
    await supabase
      .from('product_variants')
      .update({ 
        stripe_price_id: stripePrice.id,
        stripe_active: true 
      })
      .eq('id', variant.id);

    console.log(`  ✅ Created price: ${variant.title} - $${(variant.price / 100).toFixed(2)} (${stripePrice.id})`);
    return stripePrice.id;

  } catch (error: any) {
    console.error(`  ❌ Failed to create price for ${variant.sku}:`, error.message);
    return null;
  }
}

async function syncProductsToStripe() {
  console.log('🚀 Starting Supabase to Stripe sync...\n');

  // Get all active products from Supabase
  const { data: products, error: productsError } = await supabase
    .from('products')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });

  if (productsError || !products) {
    console.error('Failed to fetch products:', productsError);
    return;
  }

  console.log(`Found ${products.length} active products to sync\n`);

  let successCount = 0;
  let failCount = 0;
  let variantSuccessCount = 0;
  let variantFailCount = 0;

  // Process products in batches
  for (let i = 0; i < products.length; i += BATCH_SIZE) {
    const batch = products.slice(i, i + BATCH_SIZE);
    console.log(`\nProcessing batch ${Math.floor(i / BATCH_SIZE) + 1} of ${Math.ceil(products.length / BATCH_SIZE)}...`);

    for (const product of batch) {
      console.log(`\nProcessing: ${product.name} (${product.sku})`);
      
      // Create Stripe product
      const stripeProductId = await createStripeProduct(product);
      
      if (stripeProductId) {
        successCount++;

        // Get variants for this product
        const { data: variants, error: variantsError } = await supabase
          .from('product_variants')
          .select('*')
          .eq('product_id', product.id);

        if (variants && variants.length > 0) {
          console.log(`  Creating ${variants.length} price variants...`);
          
          for (const variant of variants) {
            const stripePriceId = await createStripePrice(variant, stripeProductId);
            if (stripePriceId) {
              variantSuccessCount++;
            } else {
              variantFailCount++;
            }
          }
        }
      } else {
        failCount++;
      }
    }

    // Delay between batches to avoid rate limiting
    if (i + BATCH_SIZE < products.length) {
      console.log(`\n⏳ Waiting ${DELAY_MS}ms before next batch...`);
      await sleep(DELAY_MS);
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 SYNC COMPLETE - SUMMARY:');
  console.log('='.repeat(50));
  console.log(`✅ Products synced: ${successCount}/${products.length}`);
  console.log(`❌ Products failed: ${failCount}`);
  console.log(`✅ Variants synced: ${variantSuccessCount}`);
  console.log(`❌ Variants failed: ${variantFailCount}`);
  console.log('='.repeat(50));

  // Verify sync
  const { data: needsSync } = await supabase
    .from('products')
    .select('id, sku, name')
    .eq('status', 'active')
    .is('stripe_product_id', null);

  if (needsSync && needsSync.length > 0) {
    console.log(`\n⚠️  ${needsSync.length} products still need Stripe sync:`);
    needsSync.slice(0, 5).forEach(p => console.log(`  - ${p.sku}: ${p.name}`));
    if (needsSync.length > 5) {
      console.log(`  ... and ${needsSync.length - 5} more`);
    }
  } else {
    console.log('\n✅ All active products are now synced with Stripe!');
  }
}

// Run the sync
syncProductsToStripe().catch(console.error);