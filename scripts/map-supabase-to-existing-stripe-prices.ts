/**
 * Map Supabase Products to EXISTING Stripe Price IDs
 * Uses the price IDs you've already created in Stripe
 */

import { createClient } from '@supabase/supabase-js';

// Configuration
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY'; // Replace this!

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Your existing Stripe price mappings (from your core products)
// Map price amounts to Stripe price IDs
const EXISTING_STRIPE_PRICES = {
  // Standard prices you mentioned
  2499: 'price_24_99',    // $24.99 - Need actual price ID
  4999: 'price_49_99',    // $49.99 - Need actual price ID
  7999: 'price_79_99',    // $79.99 - Need actual price ID
  9999: 'price_99_99',    // $99.99 - Need actual price ID
  12999: 'price_129_99',  // $129.99 - Need actual price ID
  17999: 'price_179_99',  // $179.99 - Need actual price ID
  19999: 'price_199_99',  // $199.99 - Need actual price ID
  22999: 'price_229_99',  // $229.99 - Need actual price ID
  24999: 'price_249_99',  // $249.99 - Need actual price ID
  29999: 'price_299_99',  // $299.99 - Need actual price ID
  32999: 'price_329_99',  // $329.99 - Need actual price ID
  34999: 'price_349_99',  // $349.99 - Need actual price ID
  
  // From your suits (2-piece and 3-piece prices)
  // These are the actual price IDs from your script
  // 2-piece suits ($179.99)
  17999: 'price_1Rpv2tCHc12x7sCzVvLRto3m', // Can use Navy 2-piece as standard
  
  // 3-piece suits ($229.99)
  22999: 'price_1Rpv31CHc12x7sCzlFtlUflr', // Can use Navy 3-piece as standard
  
  // Ties ($24.99)
  2499: 'price_1RpvHlCHc12x7sCzp0TVNS92', // Ultra Skinny Tie
  
  // Dress Shirts ($79.99)
  7999: 'price_1RpvWnCHc12x7sCzzioA64qD', // Slim Cut Dress Shirt
  
  // You can add more mappings based on your existing products
};

// Category-based price mapping (if needed)
const CATEGORY_PRICE_MAPPING = {
  'Tuxedos': {
    default: 32999, // $329.99 for tuxedos
    priceId: 'price_329_99' // Need actual ID
  },
  'Men\'s Suits': {
    twoPiece: 17999, // $179.99
    threePiece: 22999, // $229.99
    priceIds: {
      17999: 'price_1Rpv2tCHc12x7sCzVvLRto3m', // Use existing 2-piece price
      22999: 'price_1Rpv31CHc12x7sCzlFtlUflr'  // Use existing 3-piece price
    }
  },
  'Luxury Velvet Blazers': {
    default: 24999, // $249.99
    priceId: 'price_249_99' // Need actual ID
  },
  'Vest & Tie Sets': {
    default: 4999, // $49.99
    priceId: 'price_49_99' // Need actual ID
  },
  'Accessories': {
    default: 2499, // $24.99
    priceId: 'price_1RpvHlCHc12x7sCzp0TVNS92' // Use tie price
  }
};

async function analyzeCurrentPrices() {
  console.log('📊 Analyzing current price distribution...\n');
  
  // Get price distribution
  const { data: priceData } = await supabase
    .from('product_variants')
    .select(`
      price,
      products!inner(category)
    `)
    .eq('products.status', 'active')
    .is('stripe_price_id', null);

  if (!priceData) return;

  // Group by price and category
  const priceGroups = new Map();
  priceData.forEach(item => {
    const key = `${item.price}_${item.products.category}`;
    const count = priceGroups.get(key) || { price: item.price, category: item.products.category, count: 0 };
    count.count++;
    priceGroups.set(key, count);
  });

  console.log('Price distribution by category:');
  console.log('================================');
  
  const categories = new Map();
  priceGroups.forEach(item => {
    if (!categories.has(item.category)) {
      categories.set(item.category, []);
    }
    categories.get(item.category).push(item);
  });

  categories.forEach((prices, category) => {
    console.log(`\n${category}:`);
    prices.sort((a, b) => a.price - b.price).forEach(p => {
      console.log(`  $${(p.price / 100).toFixed(2)}: ${p.count} variants`);
    });
  });
}

async function mapToExistingPrices() {
  console.log('\n\n🔄 Mapping variants to existing Stripe prices...\n');

  // Get all variants without Stripe price IDs
  const { data: variants, error } = await supabase
    .from('product_variants')
    .select(`
      id,
      sku,
      title,
      price,
      option1,
      option2,
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

  console.log(`Found ${variants.length} variants to map\n`);

  let mapped = 0;
  let needsNewPrice = 0;
  const missingPrices = new Set();

  // Process each variant
  for (const variant of variants) {
    const category = variant.products.category;
    const price = variant.price;
    
    // Try to find existing Stripe price ID
    let stripePriceId = null;
    
    // First check direct price mapping
    if (EXISTING_STRIPE_PRICES[price]) {
      stripePriceId = EXISTING_STRIPE_PRICES[price];
    }
    // Then check category-based mapping
    else if (CATEGORY_PRICE_MAPPING[category]) {
      const categoryMapping = CATEGORY_PRICE_MAPPING[category];
      if (categoryMapping.priceIds && categoryMapping.priceIds[price]) {
        stripePriceId = categoryMapping.priceIds[price];
      } else if (price === categoryMapping.default) {
        stripePriceId = categoryMapping.priceId;
      }
    }

    if (stripePriceId && stripePriceId !== 'price_' + (price / 100).toFixed(2).replace('.', '_')) {
      // We have a real price ID, update the variant
      try {
        const { error: updateError } = await supabase
          .from('product_variants')
          .update({ 
            stripe_price_id: stripePriceId,
            stripe_active: true 
          })
          .eq('id', variant.id);

        if (!updateError) {
          mapped++;
          if (mapped % 50 === 0) {
            console.log(`Progress: ${mapped} variants mapped...`);
          }
        }
      } catch (err) {
        console.error(`Failed to update ${variant.sku}:`, err);
      }
    } else {
      needsNewPrice++;
      missingPrices.add(`${category}: $${(price / 100).toFixed(2)}`);
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 MAPPING COMPLETE:');
  console.log('='.repeat(50));
  console.log(`✅ Mapped to existing prices: ${mapped}`);
  console.log(`⚠️  Need new Stripe prices: ${needsNewPrice}`);
  
  if (missingPrices.size > 0) {
    console.log('\n📝 Missing Stripe price IDs for:');
    Array.from(missingPrices).forEach(p => console.log(`  - ${p}`));
    console.log('\nYou need to either:');
    console.log('1. Create these prices in Stripe, OR');
    console.log('2. Use the closest existing price, OR');
    console.log('3. Update the product prices to match existing ones');
  }
}

async function suggestPriceMappings() {
  console.log('\n\n💡 SUGGESTED APPROACH:\n');
  console.log('Based on your existing setup, you should:');
  console.log('1. Use your existing suit prices for all suits/tuxedos/blazers');
  console.log('2. Use your existing tie price ($24.99) for accessories');
  console.log('3. Use your existing shirt price ($79.99) for mid-range items');
  console.log('4. Create just a few new prices for the gaps\n');

  // Show which existing prices can be reused
  console.log('Existing prices you can reuse:');
  console.log('================================');
  console.log('$24.99 → price_1RpvHlCHc12x7sCzp0TVNS92 (Tie price)');
  console.log('$79.99 → price_1RpvWnCHc12x7sCzzioA64qD (Shirt price)');
  console.log('$179.99 → price_1Rpv2tCHc12x7sCzVvLRto3m (2-piece suit)');
  console.log('$229.99 → price_1Rpv31CHc12x7sCzlFtlUflr (3-piece suit)');
  console.log('\nFor tie bundles:');
  console.log('$99.99 → price_1RpvQqCHc12x7sCzfRrWStZb (5-tie bundle)');
  console.log('$129.99 → price_1RpvRACHc12x7sCzVYFZh6Ia (8-tie bundle)');
  console.log('$179.99 → price_1RpvRSCHc12x7sCzpo0fgH6A (11-tie bundle)');
}

// Main execution
async function main() {
  console.log('🚀 Analyzing Supabase products for Stripe mapping\n');
  console.log('This will map to your EXISTING Stripe prices\n');
  console.log('=' + '='.repeat(50) + '\n');

  await analyzeCurrentPrices();
  await mapToExistingPrices();
  await suggestPriceMappings();

  console.log('\n✅ Analysis complete!');
  console.log('\nNext steps:');
  console.log('1. Update EXISTING_STRIPE_PRICES with your actual price IDs');
  console.log('2. Run this script again to map all variants');
  console.log('3. Create any missing prices in Stripe if needed');
}

main().catch(console.error);