/**
 * Clean up duplicate Stripe products
 * This script will delete all the duplicate products and keep only standard prices
 */

import Stripe from 'stripe';

// Configuration - REPLACE WITH YOUR KEY
const STRIPE_SECRET_KEY = 'sk_live_YOUR_KEY'; // Replace this!

const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' });

// Products to KEEP (your original core products)
const PRODUCTS_TO_KEEP = [
  // Your original suit products
  'prod_QqwGwxRIvwnebD', // Example - replace with actual IDs from your core products
  // Add the product IDs you want to keep here
];

// Price IDs to KEEP (your standard prices)
const PRICES_TO_KEEP = [
  // Suits
  'price_1Rpv2tCHc12x7sCzVvLRto3m', // Navy 2-piece $179.99
  'price_1Rpv31CHc12x7sCzlFtlUflr', // Navy 3-piece $229.99
  // Add all your original price IDs here
  'price_1RpvHlCHc12x7sCzp0TVNS92', // Tie $24.99
  'price_1RpvWnCHc12x7sCzzioA64qD', // Shirt $79.99
  // Add more as needed
];

async function cleanupDuplicateProducts() {
  console.log('🧹 Starting Stripe cleanup...\n');
  
  let hasMore = true;
  let startingAfter = undefined;
  let totalDeleted = 0;
  let totalSkipped = 0;
  
  console.log('Fetching all products...\n');
  
  while (hasMore) {
    // Fetch products in batches
    const products = await stripe.products.list({
      limit: 100,
      starting_after: startingAfter
    });
    
    for (const product of products.data) {
      // Check if this is a duplicate velvet/blazer/etc product
      const isDuplicate = 
        product.name.includes('Velvet') || 
        product.name.includes('Blazer') ||
        product.name.includes('Sparkle') ||
        product.name.includes('Suspender') ||
        product.name.includes('Casual') ||
        product.name.includes('Prom');
      
      // Skip if it's one we want to keep
      if (PRODUCTS_TO_KEEP.includes(product.id)) {
        console.log(`✅ Keeping: ${product.name}`);
        totalSkipped++;
        continue;
      }
      
      if (isDuplicate) {
        try {
          // First, archive the product (safer than deleting)
          await stripe.products.update(product.id, {
            active: false
          });
          
          console.log(`🗑️ Archived: ${product.name}`);
          totalDeleted++;
          
          // Small delay to avoid rate limits
          await new Promise(resolve => setTimeout(resolve, 100));
        } catch (error) {
          console.error(`❌ Failed to archive ${product.name}:`, error.message);
        }
      } else {
        totalSkipped++;
      }
    }
    
    hasMore = products.has_more;
    if (hasMore) {
      startingAfter = products.data[products.data.length - 1].id;
    }
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('📊 CLEANUP COMPLETE:');
  console.log('='.repeat(50));
  console.log(`🗑️ Archived: ${totalDeleted} duplicate products`);
  console.log(`✅ Kept: ${totalSkipped} products`);
  console.log('='.repeat(50));
}

async function listRemainingProducts() {
  console.log('\n📋 Remaining active products:\n');
  
  const activeProducts = await stripe.products.list({
    active: true,
    limit: 20
  });
  
  activeProducts.data.forEach(product => {
    console.log(`- ${product.name} (${product.id})`);
  });
  
  console.log(`\nTotal active products: ${activeProducts.data.length}`);
}

// Main execution
async function main() {
  console.log('⚠️  WARNING: This will archive duplicate products in Stripe!');
  console.log('Make sure you have the correct STRIPE_SECRET_KEY set.\n');
  console.log('Starting in 5 seconds... Press Ctrl+C to cancel.\n');
  
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  await cleanupDuplicateProducts();
  await listRemainingProducts();
}

main().catch(console.error);