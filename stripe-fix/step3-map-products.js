// STEP 3: Map All Products to Stripe Prices
// Run this AFTER creating prices in Step 2

import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client with service role key
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.GQKE1hdPfVnz-PxF2SHYK3cKJDG4PvKFY4r8K2OubWc';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    persistSession: false
  }
});

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
    // First, get all unmapped product variants
    const { data: unmappedVariants, error: fetchError } = await supabase
      .from('product_variants')
      .select(`
        id,
        price,
        stripe_price_id,
        product:products!inner(
          status
        )
      `)
      .eq('product.status', 'active')
      .or('stripe_price_id.is.null,stripe_price_id.eq.');
    
    if (fetchError) {
      console.error('Error fetching variants:', fetchError);
      return;
    }
    
    console.log(`Found ${unmappedVariants.length} variants needing Stripe price mapping\\n`);
    
    // Group by price
    const priceGroups = {};
    unmappedVariants.forEach(variant => {
      if (!priceGroups[variant.price]) {
        priceGroups[variant.price] = [];
      }
      priceGroups[variant.price].push(variant.id);
    });
    
    // Map each price group
    let totalMapped = 0;
    
    for (const [price, variantIds] of Object.entries(priceGroups)) {
      const stripePriceId = priceMapping[price];
      
      if (stripePriceId) {
        console.log(`Mapping ${variantIds.length} variants at $${(price/100).toFixed(2)} to ${stripePriceId}`);
        
        const { error: updateError } = await supabase
          .from('product_variants')
          .update({
            stripe_price_id: stripePriceId,
            stripe_active: true
          })
          .in('id', variantIds);
        
        if (updateError) {
          console.error(`Error updating variants at price ${price}:`, updateError);
        } else {
          totalMapped += variantIds.length;
        }
      } else {
        console.warn(`⚠️ No Stripe price mapping for $${(price/100).toFixed(2)} (${variantIds.length} variants)`);
      }
    }
    
    console.log(`\\n✅ Mapped ${totalMapped} variants to Stripe prices\\n`);
    
    // Verify the results
    const { data: stats, error: statsError } = await supabase
      .from('product_variants')
      .select(`
        stripe_price_id,
        product:products!inner(
          status
        )
      `)
      .eq('product.status', 'active');
    
    if (!statsError && stats) {
      const mapped = stats.filter(v => v.stripe_price_id && v.stripe_price_id !== '').length;
      const unmapped = stats.filter(v => !v.stripe_price_id || v.stripe_price_id === '').length;
      
      console.log('=== FINAL STATUS ===');
      console.log(`✅ Mapped to Stripe: ${mapped} variants`);
      console.log(`❌ Still unmapped: ${unmapped} variants`);
      console.log(`📊 Success rate: ${((mapped / stats.length) * 100).toFixed(2)}%\\n`);
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