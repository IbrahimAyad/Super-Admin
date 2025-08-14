// STEP 3: Map All Products to Stripe Prices  
// Direct update using admin credentials

import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client - we'll use the anon key with RLS disabled
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Price mapping based on amount in cents
const priceMapping = {
  1000: 'price_1RvZjuCHc12x7sCzuxLkEcNl',   // $10.00
  1500: 'price_1RvZjvCHc12x7sCzieAwMC6k',   // $15.00
  2499: 'price_1RpvHlCHc12x7sCzp0TVNS92',   // $24.99 (existing)
  2999: 'price_1RvZjwCHc12x7sCzDit4VmDS',   // $29.99
  3999: 'price_1RpvWnCHc12x7sCzzioA64qD',   // $39.99 (existing)
  4499: 'price_1RvZjxCHc12x7sCzLyifMyJh',   // $44.99
  4999: 'price_1RvZjxCHc12x7sCzMLltz6kA',   // $49.99
  5999: 'price_1RvZjyCHc12x7sCzT4uiFmmb',   // $59.99
  6999: 'price_1RvZjzCHc12x7sCzDItTKV3d',   // $69.99
  7999: 'price_1RvZk0CHc12x7sCzXObY7lRI',   // $79.99
  8999: 'price_1RvZk1CHc12x7sCzwbf2rwUW',   // $89.99
  9999: 'price_1RpvQqCHc12x7sCzfRrWStZb',   // $99.99 (existing bundle)
  12999: 'price_1RvZk2CHc12x7sCzhD6H7TN9',  // $129.99
  14999: 'price_1RpvRACHc12x7sCzVYFZh6Ia',  // $149.99 (existing bundle)
  17999: 'price_1Rpv2tCHc12x7sCzVvLRto3m',  // $179.99 (existing 2-piece)
  19999: 'price_1RpvZUCHc12x7sCzM4sp9DY5',  // $199.99 (existing starter)
  22999: 'price_1Rpv31CHc12x7sCzlFtlUflr',  // $229.99 (existing 3-piece)
  24999: 'price_1RpvZtCHc12x7sCzny7VmEWD',  // $249.99 (existing professional)
  29999: 'price_1RpvfvCHc12x7sCzq1jYfG9o',  // $299.99 (existing premium)
  32999: 'price_1RvZk3CHc12x7sCzVrOV6VDc',  // $329.99
  34999: 'price_1RvZk4CHc12x7sCzzGMs4qOT',  // $349.99
};

async function mapProductsToStripe() {
  console.log('\\n=== STEP 3: MAP ALL PRODUCTS TO STRIPE PRICES ===\\n');
  
  try {
    // First authenticate as admin
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'ibrahim@kct-usa.com',
      password: 'KCT12345678!'
    });

    if (authError) {
      console.error('Authentication error:', authError);
      return;
    }

    console.log('✅ Authenticated as admin\\n');

    // Get all product variants with their products
    const { data: variants, error: fetchError } = await supabase
      .from('product_variants')
      .select(`
        id,
        price,
        stripe_price_id,
        title,
        product_id,
        products!inner(
          status,
          name,
          category
        )
      `)
      .eq('products.status', 'active')
      .or('stripe_price_id.is.null,stripe_price_id.eq.');
    
    if (fetchError) {
      console.error('Error fetching variants:', fetchError);
      return;
    }
    
    console.log(`Found ${variants.length} variants needing Stripe price mapping\\n`);
    
    // Group by price for summary
    const priceGroups = {};
    variants.forEach(variant => {
      if (!priceGroups[variant.price]) {
        priceGroups[variant.price] = [];
      }
      priceGroups[variant.price].push(variant);
    });
    
    // Show what we'll update
    console.log('Price mapping plan:');
    for (const [price, variantList] of Object.entries(priceGroups)) {
      const stripePriceId = priceMapping[price];
      const priceUSD = (parseInt(price) / 100).toFixed(2);
      
      if (stripePriceId) {
        console.log(`  $${priceUSD}: ${variantList.length} variants → ${stripePriceId}`);
      } else {
        console.log(`  $${priceUSD}: ${variantList.length} variants → ⚠️ NO MAPPING`);
      }
    }
    
    console.log('\\nStarting updates...\\n');
    
    // Update each price group
    let totalMapped = 0;
    let totalSkipped = 0;
    
    for (const [price, variantList] of Object.entries(priceGroups)) {
      const stripePriceId = priceMapping[price];
      
      if (stripePriceId) {
        const variantIds = variantList.map(v => v.id);
        
        const { data: updateData, error: updateError } = await supabase
          .from('product_variants')
          .update({
            stripe_price_id: stripePriceId,
            stripe_active: true
          })
          .in('id', variantIds)
          .select();
        
        if (updateError) {
          console.error(`❌ Error updating variants at $${(price/100).toFixed(2)}:`, updateError);
        } else {
          totalMapped += updateData.length;
          console.log(`✅ Updated ${updateData.length} variants at $${(price/100).toFixed(2)}`);
        }
      } else {
        totalSkipped += variantList.length;
        console.warn(`⚠️ Skipped ${variantList.length} variants at $${(price/100).toFixed(2)} - no price mapping`);
      }
    }
    
    console.log(`\\n=== UPDATE COMPLETE ===`);
    console.log(`✅ Mapped: ${totalMapped} variants`);
    console.log(`⚠️ Skipped: ${totalSkipped} variants (no price mapping)\\n`);
    
    // Verify the results
    const { data: verifyData, error: verifyError } = await supabase
      .from('product_variants')
      .select('stripe_price_id, products!inner(status)')
      .eq('products.status', 'active');
    
    if (!verifyError && verifyData) {
      const mapped = verifyData.filter(v => v.stripe_price_id && v.stripe_price_id !== '').length;
      const unmapped = verifyData.filter(v => !v.stripe_price_id || v.stripe_price_id === '').length;
      
      console.log('=== FINAL STATUS ===');
      console.log(`✅ Mapped to Stripe: ${mapped} variants`);
      console.log(`❌ Still unmapped: ${unmapped} variants`);
      console.log(`📊 Success rate: ${((mapped / verifyData.length) * 100).toFixed(2)}%\\n`);
    }
    
    console.log('=== NEXT STEP ===');
    console.log('Run: node stripe-fix/step4-verify.js');
    console.log('To verify all products are correctly mapped\\n');
    
  } catch (error) {
    console.error('Error in mapping process:', error);
  }
}

// Run the mapping
mapProductsToStripe();