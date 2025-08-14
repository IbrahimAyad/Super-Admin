// TEST SCRIPT - Run this in your website console to verify images
// Or save as test-images.js and run with Node.js

import { createClient } from '@supabase/supabase-js';

// Your Supabase credentials
const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  'YOUR_ANON_KEY_HERE'  // Replace with your anon key
);

async function testImages() {
  console.log('🔍 Testing Image System...\n');
  
  // Test 1: Check if primary_image field exists
  console.log('Test 1: Checking primary_image field...');
  const { data: sample, error: error1 } = await supabase
    .from('products')
    .select('id, name, primary_image')
    .limit(3);
  
  if (error1) {
    console.error('❌ Error:', error1);
    return;
  }
  
  console.log('✅ Sample products with images:');
  sample.forEach(p => {
    console.log(`  - ${p.name}`);
    console.log(`    Image: ${p.primary_image?.substring(0, 50)}...`);
  });
  
  // Test 2: Count products with images
  console.log('\nTest 2: Counting products with images...');
  const { count: totalProducts } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'active');
  
  const { count: withImages } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'active')
    .not('primary_image', 'is', null);
  
  console.log(`✅ Products with images: ${withImages}/${totalProducts}`);
  
  // Test 3: Check image URL formats
  console.log('\nTest 3: Checking image URL types...');
  const { data: images } = await supabase
    .from('products')
    .select('primary_image')
    .eq('status', 'active')
    .not('primary_image', 'is', null)
    .limit(100);
  
  let realImages = 0;
  let placeholders = 0;
  let other = 0;
  
  images.forEach(img => {
    if (img.primary_image.includes('placehold')) placeholders++;
    else if (img.primary_image.includes('r2.dev')) realImages++;
    else other++;
  });
  
  console.log(`✅ Image types found:`);
  console.log(`  - Real images: ${realImages}`);
  console.log(`  - Placeholders: ${placeholders}`);
  console.log(`  - Other: ${other}`);
  
  // Test 4: Fetch with variants (full query)
  console.log('\nTest 4: Testing full product query...');
  const { data: fullProducts, error: error4 } = await supabase
    .from('products')
    .select(`
      id,
      name,
      category,
      primary_image,
      product_variants!inner(
        id,
        title,
        price,
        stripe_price_id,
        inventory_count
      )
    `)
    .eq('status', 'active')
    .limit(2);
  
  if (error4) {
    console.error('❌ Error in full query:', error4);
    return;
  }
  
  console.log('✅ Full product data structure:');
  console.log(JSON.stringify(fullProducts[0], null, 2));
  
  // Test 5: Specific test products
  console.log('\nTest 5: Testing specific products that should work...');
  const testIds = [
    'a9e4bbba-7128-4f45-9258-9b0d9465123b',
    '754192d7-e19e-475b-9b64-0463d31c4cad',
    'a31c629f-c935-4f17-9a05-53812d8af29d'
  ];
  
  const { data: testProducts } = await supabase
    .from('products')
    .select('id, name, primary_image')
    .in('id', testIds);
  
  console.log('✅ Test products (these MUST have images):');
  testProducts.forEach(p => {
    console.log(`  - ${p.name}`);
    console.log(`    ✓ Has image: ${p.primary_image ? 'YES' : 'NO'}`);
  });
  
  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 SUMMARY:');
  console.log('='.repeat(50));
  console.log(`Total Products: ${totalProducts}`);
  console.log(`With Images: ${withImages}`);
  console.log(`Coverage: ${((withImages/totalProducts) * 100).toFixed(1)}%`);
  console.log('\n✅ If you see images above, the database is working!');
  console.log('❌ If not, check your Supabase connection and RLS policies.');
}

// Run the test
testImages().catch(console.error);

// EXAMPLE OUTPUT YOU SHOULD SEE:
/*
🔍 Testing Image System...

Test 1: Checking primary_image field...
✅ Sample products with images:
  - Men's Velvet Black Blazer
    Image: https://placehold.co/400x600/6b46c1/ffffff?te...
  - Classic Tuxedo
    Image: https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbc...

Test 2: Counting products with images...
✅ Products with images: 274/274

Test 3: Checking image URL types...
✅ Image types found:
  - Real images: 91
  - Placeholders: 183
  - Other: 0

Test 4: Testing full product query...
✅ Full product data structure:
{
  "id": "xxx",
  "name": "Product Name",
  "primary_image": "https://...",
  "product_variants": [
    {
      "id": "xxx",
      "price": 29999,
      "stripe_price_id": "price_xxx"
    }
  ]
}
*/