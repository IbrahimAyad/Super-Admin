/**
 * Simplified Stripe Sync Using Standard Price Points
 * Since all products use only 12 price points, we can create reusable prices!
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

// Your standard price points (in cents)
const STANDARD_PRICES = [
  2499,   // $24.99
  4999,   // $49.99
  7999,   // $79.99
  9999,   // $99.99
  12999,  // $129.99
  17999,  // $179.99
  19999,  // $199.99
  22999,  // $229.99
  24999,  // $249.99
  29999,  // $299.99
  32999,  // $329.99
  34999   // $349.99
];

// Map to store created price IDs
const priceMap = new Map<number, string>();

async function createStandardProduct() {
  console.log('🎯 Creating standard KCT Menswear product in Stripe...\n');
  
  try {
    // Check if standard product already exists
    const existingProducts = await stripe.products.search({
      query: 'metadata[\'type\']:\'kct_standard_product\''
    });

    let standardProduct;
    
    if (existingProducts.data.length > 0) {
      standardProduct = existingProducts.data[0];
      console.log(`✅ Found existing standard product: ${standardProduct.id}\n`);
    } else {
      // Create one standard product for all prices
      standardProduct = await stripe.products.create({
        name: 'KCT Menswear Item',
        description: 'Premium menswear from KCT Menswear collection',
        metadata: {
          type: 'kct_standard_product'
        },
        active: true
      });
      console.log(`✅ Created standard product: ${standardProduct.id}\n`);
    }

    return standardProduct.id;
  } catch (error) {
    console.error('Failed to create standard product:', error);
    throw error;
  }
}

async function createStandardPrices(productId: string) {
  console.log('💰 Creating standard price points...\n');
  
  for (const priceInCents of STANDARD_PRICES) {
    try {
      // Check if this price already exists
      const existingPrices = await stripe.prices.search({
        query: `product:'${productId}' AND unit_amount:${priceInCents}`
      });

      let priceId;
      
      if (existingPrices.data.length > 0) {
        priceId = existingPrices.data[0].id;
        console.log(`✅ Found existing price: $${(priceInCents / 100).toFixed(2)} - ${priceId}`);
      } else {
        // Create the price
        const stripePrice = await stripe.prices.create({
          product: productId,
          unit_amount: priceInCents,
          currency: 'usd',
          nickname: `Standard Price - $${(priceInCents / 100).toFixed(2)}`,
          metadata: {
            standard_price: 'true',
            amount_usd: (priceInCents / 100).toFixed(2)
          }
        });
        priceId = stripePrice.id;
        console.log(`✅ Created price: $${(priceInCents / 100).toFixed(2)} - ${priceId}`);
      }
      
      priceMap.set(priceInCents, priceId);
    } catch (error) {
      console.error(`❌ Failed to create price $${(priceInCents / 100).toFixed(2)}:`, error);
    }
  }
  
  console.log(`\n✅ Created/found ${priceMap.size} standard prices\n`);
}

async function updateVariantsWithStandardPrices() {
  console.log('🔄 Updating product variants with standard prices...\n');
  
  // Get all variants without Stripe price IDs
  const { data: variants, error } = await supabase
    .from('product_variants')
    .select(`
      id,
      sku,
      title,
      price,
      product_id,
      products!inner(
        name,
        category,
        status
      )
    `)
    .is('stripe_price_id', null)
    .eq('products.status', 'active');

  if (error || !variants) {
    console.error('Failed to fetch variants:', error);
    return;
  }

  console.log(`Found ${variants.length} variants to update\n`);

  let successCount = 0;
  let skipCount = 0;
  let failCount = 0;

  // Group by price to show summary
  const priceGroups = new Map<number, number>();
  variants.forEach(v => {
    const count = priceGroups.get(v.price) || 0;
    priceGroups.set(v.price, count + 1);
  });

  console.log('Price distribution:');
  Array.from(priceGroups.entries())
    .sort((a, b) => a[0] - b[0])
    .forEach(([price, count]) => {
      console.log(`  $${(price / 100).toFixed(2)}: ${count} variants`);
    });
  console.log('');

  // Process variants in batches
  const BATCH_SIZE = 50;
  for (let i = 0; i < variants.length; i += BATCH_SIZE) {
    const batch = variants.slice(i, i + BATCH_SIZE);
    
    for (const variant of batch) {
      const stripePriceId = priceMap.get(variant.price);
      
      if (!stripePriceId) {
        console.warn(`⚠️ No standard price for $${(variant.price / 100).toFixed(2)} - ${variant.title}`);
        
        // Check if this is close to a standard price (within $1)
        const closestPrice = STANDARD_PRICES.find(p => Math.abs(p - variant.price) <= 100);
        if (closestPrice) {
          console.log(`   Suggesting: $${(closestPrice / 100).toFixed(2)} instead`);
        }
        skipCount++;
        continue;
      }

      try {
        // Update the variant with the standard price ID
        const { error: updateError } = await supabase
          .from('product_variants')
          .update({ 
            stripe_price_id: stripePriceId,
            stripe_active: true 
          })
          .eq('id', variant.id);

        if (updateError) {
          throw updateError;
        }

        successCount++;
        if (successCount % 100 === 0) {
          console.log(`Progress: ${successCount} variants updated...`);
        }
      } catch (error) {
        console.error(`❌ Failed to update variant ${variant.sku}:`, error);
        failCount++;
      }
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 UPDATE COMPLETE - SUMMARY:');
  console.log('='.repeat(50));
  console.log(`✅ Variants updated: ${successCount}`);
  console.log(`⚠️ Variants skipped (non-standard price): ${skipCount}`);
  console.log(`❌ Variants failed: ${failCount}`);
  console.log('='.repeat(50));

  // Check for non-standard prices
  if (skipCount > 0) {
    const { data: nonStandard } = await supabase
      .from('product_variants')
      .select('price, COUNT(*)')
      .is('stripe_price_id', null)
      .not('price', 'in', `(${STANDARD_PRICES.join(',')})`)
      .group('price')
      .order('price');

    if (nonStandard && nonStandard.length > 0) {
      console.log('\n⚠️ Non-standard prices found:');
      nonStandard.forEach(item => {
        console.log(`  $${(item.price / 100).toFixed(2)}: ${item.count} variants`);
      });
      console.log('\nConsider updating these to standard prices for consistency.');
    }
  }
}

async function syncStandardPrices() {
  try {
    console.log('🚀 Starting Simplified Stripe Sync with Standard Prices\n');
    console.log('This approach uses reusable prices for efficiency!\n');
    console.log('=' + '='.repeat(50) + '\n');

    // Step 1: Create standard product
    const productId = await createStandardProduct();

    // Step 2: Create all standard prices
    await createStandardPrices(productId);

    // Step 3: Update variants with standard prices
    await updateVariantsWithStandardPrices();

    // Final check
    const { data: finalCheck } = await supabase
      .from('product_variants')
      .select('COUNT(*)')
      .is('stripe_price_id', null);

    const remaining = finalCheck?.[0]?.count || 0;
    
    if (remaining > 0) {
      console.log(`\n⚠️ ${remaining} variants still need Stripe sync`);
      console.log('These likely have non-standard prices.');
    } else {
      console.log('\n✅ All variants now have Stripe price IDs!');
      console.log('🎉 Your checkout system is fully operational!');
    }

  } catch (error) {
    console.error('Sync failed:', error);
  }
}

// Run the sync
syncStandardPrices().catch(console.error);