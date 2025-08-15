import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function diagnoseAdminPanel() {
  console.log('🔍 DIAGNOSING ADMIN PANEL ISSUES');
  console.log('=' .repeat(70));
  console.log('');

  const issues = [];
  const fixes = [];

  // 1. Check if reviews table exists
  console.log('1️⃣ Checking reviews table...');
  try {
    const { count, error } = await supabase
      .from('reviews')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.log('   ❌ Reviews table missing or inaccessible');
      issues.push('Reviews table missing');
      fixes.push('CREATE TABLE reviews - see FIX-ADMIN-PANEL-ERRORS.sql');
    } else {
      console.log(`   ✅ Reviews table exists (${count || 0} reviews)`);
    }
  } catch (e) {
    console.log('   ❌ Error checking reviews table:', e.message);
    issues.push('Reviews table error');
  }

  // 2. Check transfer_guest_cart function
  console.log('\n2️⃣ Checking transfer_guest_cart function...');
  try {
    // Try to call the function with dummy data
    const { error } = await supabase.rpc('transfer_guest_cart', {
      p_customer_id: '00000000-0000-0000-0000-000000000000',
      p_session_id: 'test-session'
    });
    
    if (error && error.message.includes('not exist')) {
      console.log('   ❌ transfer_guest_cart function missing');
      issues.push('transfer_guest_cart function missing');
      fixes.push('CREATE FUNCTION transfer_guest_cart - see FIX-ADMIN-PANEL-ERRORS.sql');
    } else {
      console.log('   ✅ transfer_guest_cart function exists');
    }
  } catch (e) {
    console.log('   ❌ Error checking transfer_guest_cart:', e.message);
  }

  // 3. Check get_recent_orders function
  console.log('\n3️⃣ Checking get_recent_orders function...');
  try {
    const { data, error } = await supabase.rpc('get_recent_orders', {
      limit_count: 1
    });
    
    if (error) {
      console.log('   ❌ get_recent_orders function error:', error.message);
      issues.push('get_recent_orders function error');
      fixes.push('CREATE OR REPLACE FUNCTION get_recent_orders - see FIX-ADMIN-PANEL-ERRORS.sql');
    } else {
      console.log('   ✅ get_recent_orders function works');
    }
  } catch (e) {
    console.log('   ❌ Error checking get_recent_orders:', e.message);
  }

  // 4. Check cart_items table
  console.log('\n4️⃣ Checking cart_items table...');
  try {
    const { error } = await supabase
      .from('cart_items')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.log('   ❌ cart_items table missing');
      issues.push('cart_items table missing');
      fixes.push('CREATE TABLE cart_items - see FIX-ADMIN-PANEL-ERRORS.sql');
    } else {
      console.log('   ✅ cart_items table exists');
    }
  } catch (e) {
    console.log('   ❌ Error checking cart_items:', e.message);
  }

  // 5. Check product_variants table
  console.log('\n5️⃣ Checking product_variants table...');
  try {
    const { count, error } = await supabase
      .from('product_variants')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.log('   ❌ product_variants table missing');
      issues.push('product_variants table missing');
      fixes.push('CREATE TABLE product_variants - see FIX-ADMIN-PANEL-ERRORS.sql');
    } else {
      console.log(`   ✅ product_variants table exists (${count || 0} variants)`);
    }
  } catch (e) {
    console.log('   ❌ Error checking product_variants:', e.message);
  }

  // 6. Check orders table columns
  console.log('\n6️⃣ Checking orders table structure...');
  try {
    const { data: orders } = await supabase
      .from('orders')
      .select('id, email, payment_status')
      .limit(1);
    
    console.log('   ✅ Orders table has required columns');
  } catch (e) {
    if (e.message.includes('email') || e.message.includes('payment_status')) {
      console.log('   ❌ Orders table missing columns (email or payment_status)');
      issues.push('Orders table missing columns');
      fixes.push('ALTER TABLE orders ADD columns - see FIX-ADMIN-PANEL-ERRORS.sql');
    }
  }

  // 7. Check admin user
  console.log('\n7️⃣ Checking admin user access...');
  try {
    const { data: adminUsers } = await supabase
      .from('admin_users')
      .select('*');
    
    if (adminUsers && adminUsers.length > 0) {
      console.log(`   ✅ ${adminUsers.length} admin user(s) configured`);
      adminUsers.forEach(admin => {
        console.log(`      - ${admin.email} (${admin.role})`);
      });
    } else {
      console.log('   ⚠️  No admin users found');
    }
  } catch (e) {
    console.log('   ❌ Error checking admin users:', e.message);
  }

  // Summary
  console.log('\n' + '=' .repeat(70));
  console.log('📊 DIAGNOSIS SUMMARY\n');
  
  if (issues.length === 0) {
    console.log('✅ All admin panel components are properly configured!');
  } else {
    console.log(`❌ Found ${issues.length} issue(s):\n`);
    issues.forEach((issue, i) => {
      console.log(`   ${i + 1}. ${issue}`);
      console.log(`      Fix: ${fixes[i]}`);
    });
    
    console.log('\n📝 TO FIX THESE ISSUES:');
    console.log('1. Open Supabase SQL Editor');
    console.log('2. Copy the contents of FIX-ADMIN-PANEL-ERRORS.sql');
    console.log('3. Run the SQL script');
    console.log('4. Refresh your admin panel');
  }

  // Test data statistics
  console.log('\n📈 DATABASE STATISTICS:');
  
  const tables = ['products', 'customers', 'orders', 'reviews'];
  for (const table of tables) {
    try {
      const { count } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      console.log(`   ${table}: ${count || 0} records`);
    } catch (e) {
      console.log(`   ${table}: Unable to count`);
    }
  }
}

diagnoseAdminPanel().catch(console.error);