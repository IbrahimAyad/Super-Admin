// Test products_enhanced database permissions
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testDatabasePermissions() {
  console.log('Testing products_enhanced table permissions...\n');

  // Test 1: SELECT access
  console.log('Test 1: SELECT access (as anonymous user)');
  try {
    const { data, error, count } = await supabase
      .from('products_enhanced')
      .select('*', { count: 'exact' })
      .limit(5);

    if (error) {
      console.error('❌ SELECT failed:', error.message);
      console.error('Error details:', error);
    } else {
      console.log('✅ SELECT successful');
      console.log(`   - Retrieved ${data?.length || 0} records`);
      console.log(`   - Total count: ${count || 'unknown'}`);
      if (data && data.length > 0) {
        console.log(`   - Sample record: ${data[0].name} (${data[0].sku})`);
      }
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err);
  }

  // Test 2: Check RLS policies
  console.log('\nTest 2: Row Level Security check');
  try {
    const { data: policies, error } = await supabase
      .rpc('get_policies', { table_name: 'products_enhanced' })
      .single();

    if (error) {
      console.log('⚠️  Could not check RLS policies (may need admin access)');
    } else {
      console.log('✅ RLS policies found:', policies);
    }
  } catch (err) {
    // Expected - this RPC function might not exist
    console.log('ℹ️  RLS policy check not available');
  }

  // Test 3: Check if we can access specific columns
  console.log('\nTest 3: Column access test');
  try {
    const { data, error } = await supabase
      .from('products_enhanced')
      .select('id, name, sku, price_tier, base_price, status')
      .eq('status', 'active')
      .limit(3);

    if (error) {
      console.error('❌ Column access failed:', error.message);
    } else {
      console.log('✅ Column access successful');
      console.log(`   - Retrieved ${data?.length || 0} active products`);
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err);
  }

  // Test 4: Check price_tiers table access
  console.log('\nTest 4: price_tiers table access');
  try {
    const { data, error } = await supabase
      .from('price_tiers')
      .select('*')
      .limit(5);

    if (error) {
      console.error('❌ price_tiers access failed:', error.message);
    } else {
      console.log('✅ price_tiers access successful');
      console.log(`   - Retrieved ${data?.length || 0} tiers`);
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err);
  }

  // Test 5: Test authenticated user access (if we have a user token)
  console.log('\nTest 5: Testing with authenticated context');
  console.log('ℹ️  Would require user authentication to test fully');

  console.log('\n' + '='.repeat(50));
  console.log('Database Permission Test Complete');
  console.log('='.repeat(50));
}

testDatabasePermissions();