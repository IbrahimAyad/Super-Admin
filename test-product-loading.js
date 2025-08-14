// Test Product Loading Issue
// This tests if the anon key can see all products

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testProductLoading() {
  console.log('Testing product loading with anon key...\n');
  
  // Test 1: Count total products
  const { count: totalCount, error: countError } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'active')
    .eq('visibility', true);
  
  console.log(`Total products in database: ${totalCount}`);
  if (countError) console.error('Count error:', countError);
  
  // Test 2: Fetch without limit
  const { data: allProducts, error: allError } = await supabase
    .from('products')
    .select('id, name, category')
    .eq('status', 'active')
    .eq('visibility', true);
  
  console.log(`Products fetched without limit: ${allProducts?.length || 0}`);
  if (allError) console.error('Fetch error:', allError);
  
  // Test 3: Fetch with large limit
  const { data: limitedProducts, error: limitError } = await supabase
    .from('products')
    .select('id, name, category')
    .eq('status', 'active')
    .eq('visibility', true)
    .limit(1000);
  
  console.log(`Products fetched with limit(1000): ${limitedProducts?.length || 0}`);
  if (limitError) console.error('Limited fetch error:', limitError);
  
  // Test 4: Check by category
  const categories = ['Accessories', 'Men\'s Suits', 'Tuxedos', 'Luxury Velvet Blazers'];
  
  console.log('\nProducts by category:');
  for (const category of categories) {
    const { data, count } = await supabase
      .from('products')
      .select('*', { count: 'exact' })
      .eq('status', 'active')
      .eq('visibility', true)
      .eq('category', category);
    
    console.log(`  ${category}: ${data?.length || 0} fetched, ${count} total`);
  }
  
  // Test 5: Check if there's a default limit
  const { data: defaultFetch } = await supabase
    .from('products')
    .select('id');
  
  console.log(`\nDefault fetch (no conditions): ${defaultFetch?.length || 0} products`);
  
  // Test 6: Check with pagination
  const pageSize = 50;
  let offset = 0;
  let totalFetched = 0;
  let hasMore = true;
  
  console.log('\nTesting pagination:');
  while (hasMore && offset < 300) {
    const { data, error } = await supabase
      .from('products')
      .select('id')
      .eq('status', 'active')
      .eq('visibility', true)
      .range(offset, offset + pageSize - 1);
    
    if (data) {
      totalFetched += data.length;
      console.log(`  Page ${Math.floor(offset/pageSize) + 1}: ${data.length} products`);
      hasMore = data.length === pageSize;
      offset += pageSize;
    } else {
      hasMore = false;
    }
  }
  console.log(`Total fetched via pagination: ${totalFetched}`);
  
  // Summary
  console.log('\n=== SUMMARY ===');
  console.log(`Database has: ${totalCount} products`);
  console.log(`Can fetch: ${allProducts?.length || 0} products`);
  console.log(`Gap: ${totalCount - (allProducts?.length || 0)} products missing`);
  
  if (totalCount > (allProducts?.length || 0)) {
    console.log('\n⚠️ ISSUE FOUND: Not all products are being returned!');
    console.log('Possible causes:');
    console.log('1. RLS policies limiting access');
    console.log('2. Supabase query timeout');
    console.log('3. Default row limit in Supabase settings');
  } else {
    console.log('\n✅ All products are accessible!');
  }
}

testProductLoading().catch(console.error);