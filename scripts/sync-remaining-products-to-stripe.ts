/**
 * Sync REMAINING Supabase Products to Stripe
 * This script only syncs products that don't already have Stripe IDs
 * Safe to run multiple times - it skips already synced products
 */

import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// Configuration - REPLACE THESE WITH YOUR ACTUAL KEYS
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY'; // Replace this!
const STRIPE_SECRET_KEY = 'sk_live_YOUR_KEY'; // Replace this!

// Initialize clients
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' });

// Batch settings
const BATCH_SIZE = 5; // Smaller batch for safety
const DELAY_MS = 2000; // 2 second delay between batches

async function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function syncRemainingProducts() {
  console.log('🚀 Starting sync of REMAINING products to Stripe...\n');

  // Get products that don't have Stripe IDs
  const { data: products, error: productsError } = await supabase
    .from('products')
    .select('*')
    .is('stripe_product_id', null)
    .eq('status', 'active')
    .order('created_at', { ascending: false });

  if (productsError || !products) {
    console.error('Failed to fetch products:', productsError);
    return;
  }

  console.log(`Found ${products.length} products without Stripe IDs\n`);

  let productSuccessCount = 0;
  let productFailCount = 0;
  let variantSuccessCount = 0;
  let variantFailCount = 0;

  // Process products in batches
  for (let i = 0; i < products.length; i += BATCH_SIZE) {
    const batch = products.slice(i, i + BATCH_SIZE);
    console.log(`\nProcessing batch ${Math.floor(i / BATCH_SIZE) + 1} of ${Math.ceil(products.length / BATCH_SIZE)}...`);

    for (const product of batch) {
      console.log(`\nProcessing: ${product.name} (${product.sku})`);
      
      try {
        // Create product in Stripe
        const stripeProduct = await stripe.products.create({
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

        console.log(`✅ Created Stripe product: ${stripeProduct.id}`);
        productSuccessCount++;

        // Now sync variants for this product
        const { data: variants } = await supabase
          .from('product_variants')
          .select('*')
          .eq('product_id', product.id)
          .is('stripe_price_id', null);

        if (variants && variants.length > 0) {
          console.log(`  Creating ${variants.length} price variants...`);
          
          for (const variant of variants) {
            try {
              const stripePrice = await stripe.prices.create({
                product: stripeProduct.id,
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

              await supabase
                .from('product_variants')
                .update({ 
                  stripe_price_id: stripePrice.id,
                  stripe_active: true 
                })
                .eq('id', variant.id);

              console.log(`  ✅ Price: ${variant.title} - $${(variant.price / 100).toFixed(2)}`);
              variantSuccessCount++;
            } catch (error: any) {
              console.error(`  ❌ Failed variant ${variant.sku}:`, error.message);
              variantFailCount++;
            }
          }
        }
      } catch (error: any) {
        console.error(`❌ Failed product ${product.sku}:`, error.message);
        productFailCount++;
      }
    }

    // Delay between batches
    if (i + BATCH_SIZE < products.length) {
      console.log(`\n⏳ Waiting ${DELAY_MS}ms before next batch...`);
      await sleep(DELAY_MS);
    }
  }

  // Now check for variants without Stripe IDs on products that DO have Stripe IDs
  console.log('\n🔍 Checking for orphaned variants...');
  
  const { data: orphanedVariants } = await supabase
    .from('product_variants')
    .select(`
      *,
      products!inner(stripe_product_id)
    `)
    .is('stripe_price_id', null)
    .not('products.stripe_product_id', 'is', null);

  if (orphanedVariants && orphanedVariants.length > 0) {
    console.log(`Found ${orphanedVariants.length} variants without prices on products that have Stripe IDs\n`);
    
    for (const variant of orphanedVariants) {
      try {
        const stripePrice = await stripe.prices.create({
          product: variant.products.stripe_product_id,
          unit_amount: variant.price,
          currency: 'usd',
          nickname: variant.title,
          metadata: {
            supabase_variant_id: variant.id,
            sku: variant.sku,
            size: variant.option1 || '',
            color: variant.option2 || ''
          }
        });

        await supabase
          .from('product_variants')
          .update({ 
            stripe_price_id: stripePrice.id,
            stripe_active: true 
          })
          .eq('id', variant.id);

        console.log(`✅ Fixed orphaned variant: ${variant.title}`);
        variantSuccessCount++;
      } catch (error: any) {
        console.error(`❌ Failed orphaned variant ${variant.sku}:`, error.message);
        variantFailCount++;
      }
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 SYNC COMPLETE - SUMMARY:');
  console.log('='.repeat(50));
  console.log(`✅ Products synced: ${productSuccessCount}`);
  console.log(`❌ Products failed: ${productFailCount}`);
  console.log(`✅ Variants synced: ${variantSuccessCount}`);
  console.log(`❌ Variants failed: ${variantFailCount}`);
  console.log('='.repeat(50));

  // Final check
  const { data: finalCheck } = await supabase
    .from('product_variants')
    .select('id')
    .is('stripe_price_id', null);

  if (finalCheck && finalCheck.length > 0) {
    console.log(`\n⚠️ ${finalCheck.length} variants still need Stripe sync`);
  } else {
    console.log('\n✅ All variants now have Stripe price IDs!');
  }
}

// Run the sync
syncRemainingProducts().catch(console.error);