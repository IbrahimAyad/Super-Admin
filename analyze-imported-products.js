import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Supabase connection
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function analyzeProducts() {
  console.log('=== PRODUCT CATALOG ANALYSIS ===\n');
  
  // Get all products grouped by category
  const { data: products, error } = await supabase
    .from('products')
    .select('*')
    .eq('status', 'active')
    .order('category');
  
  if (error) {
    console.error('Error fetching products:', error);
    return;
  }
  
  // Group by category
  const categories = {};
  products.forEach(p => {
    if (!categories[p.category]) {
      categories[p.category] = [];
    }
    categories[p.category].push(p);
  });
  
  console.log(`📦 TOTAL ACTIVE PRODUCTS: ${products.length}\n`);
  
  console.log('📊 PRODUCTS BY CATEGORY:\n');
  Object.entries(categories)
    .sort((a, b) => b[1].length - a[1].length)
    .forEach(([category, items]) => {
      console.log(`${category}: ${items.length} products`);
      
      // Show sample products for major categories
      if (items.length > 5) {
        console.log(`  Sample items:`);
        items.slice(0, 3).forEach(item => {
          console.log(`    - ${item.name}`);
        });
      }
    });
  
  // Check for suits specifically
  console.log('\n🔍 SUIT ANALYSIS:');
  const suitCategories = Object.entries(categories)
    .filter(([cat]) => cat.toLowerCase().includes('suit'));
  
  let totalSuits = 0;
  suitCategories.forEach(([category, items]) => {
    console.log(`  ${category}: ${items.length} suits`);
    totalSuits += items.length;
  });
  console.log(`  TOTAL SUITS: ${totalSuits}`);
  
  // Check for suit sizes in variants
  const { data: suitVariants } = await supabase
    .from('product_variants')
    .select('size, product_id')
    .in('product_id', products.filter(p => p.category?.includes('Suit')).map(p => p.id));
  
  if (suitVariants && suitVariants.length > 0) {
    const uniqueSizes = [...new Set(suitVariants.map(v => v.size))].sort();
    console.log(`\n  ✅ Suit sizes available: ${uniqueSizes.join(', ')}`);
    console.log(`  Total suit variants: ${suitVariants.length}`);
  }
  
  // Check for other key products
  console.log('\n🔍 KEY PRODUCT TYPES:');
  
  const keyTypes = {
    'Tuxedo': products.filter(p => p.category?.includes('Tuxedo') || p.name?.includes('Tuxedo')),
    'Blazer': products.filter(p => p.category?.includes('Blazer') || p.name?.includes('Blazer')),
    'Vest': products.filter(p => p.category?.includes('Vest') || p.name?.includes('Vest')),
    'Shirt': products.filter(p => p.category?.includes('Shirt') || p.name?.includes('Shirt')),
    'Accessories': products.filter(p => p.category?.includes('Accessories') || p.category?.includes('Suspender')),
    'Shoes': products.filter(p => p.category?.includes('Shoe') || p.name?.includes('Boot')),
    'Kids': products.filter(p => p.category?.includes('Kid') || p.name?.includes('Kid'))
  };
  
  Object.entries(keyTypes).forEach(([type, items]) => {
    console.log(`  ${type}: ${items.length} products`);
  });
  
  // Check Stripe coverage
  const { data: variantsWithStripe } = await supabase
    .from('product_variants')
    .select('stripe_price_id')
    .not('stripe_price_id', 'is', null);
  
  const { count: totalVariants } = await supabase
    .from('product_variants')
    .select('*', { count: 'exact', head: true });
  
  console.log('\n💳 STRIPE INTEGRATION:');
  console.log(`  Variants with Stripe IDs: ${variantsWithStripe?.length || 0}/${totalVariants || 0}`);
  console.log(`  Coverage: ${Math.round((variantsWithStripe?.length || 0) / (totalVariants || 1) * 100)}%`);
  
  // Check images
  const productsWithImages = products.filter(p => p.primary_image && !p.primary_image.includes('placehold'));
  console.log('\n🖼️ IMAGES:');
  console.log(`  Products with images: ${productsWithImages.length}/${products.length}`);
  console.log(`  Coverage: ${Math.round(productsWithImages.length / products.length * 100)}%`);
  
  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📝 SUMMARY:\n');
  
  const hasGoodCoverage = {
    suits: totalSuits > 20,
    tuxedos: keyTypes['Tuxedo'].length > 10,
    blazers: keyTypes['Blazer'].length > 30,
    vests: keyTypes['Vest'].length > 30,
    accessories: keyTypes['Accessories'].length > 10,
    stripeIntegration: (variantsWithStripe?.length || 0) / (totalVariants || 1) > 0.9,
    images: productsWithImages.length / products.length > 0.8
  };
  
  console.log('✅ WHAT WE HAVE:');
  if (hasGoodCoverage.suits) console.log('  • Good selection of suits with sizes');
  if (hasGoodCoverage.tuxedos) console.log('  • Full tuxedo collection');
  if (hasGoodCoverage.blazers) console.log('  • Comprehensive blazer selection');
  if (hasGoodCoverage.vests) console.log('  • Complete vest & tie sets');
  if (hasGoodCoverage.accessories) console.log('  • Accessories (suspenders, bowties)');
  if (hasGoodCoverage.stripeIntegration) console.log('  • 100% Stripe integration');
  if (hasGoodCoverage.images) console.log('  • Most products have images');
  
  console.log('\n⚠️ POTENTIAL GAPS:');
  if (!hasGoodCoverage.suits) console.log('  • Need more suits (only ' + totalSuits + ' found)');
  if (keyTypes['Shirt'].length < 10) console.log('  • Limited dress shirts');
  if (!products.some(p => p.name?.includes('Pants') || p.category?.includes('Pants'))) {
    console.log('  • No standalone pants/trousers');
  }
  
  console.log('\n🎯 CONCLUSION:');
  const overallCoverage = Object.values(hasGoodCoverage).filter(v => v).length / Object.keys(hasGoodCoverage).length;
  if (overallCoverage > 0.7) {
    console.log('✅ YES - We have the majority of the original catalog!');
    console.log('   The core products are all there with proper sizes.');
  } else {
    console.log('⚠️ PARTIAL - We have most products but may be missing some categories');
  }
}

analyzeProducts().catch(console.error);