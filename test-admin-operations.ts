/**
 * TEST ADMIN OPERATIONS
 * Verifies that the new dual-client architecture fixes the 401/permission errors
 * Run with: npx tsx test-admin-operations.ts
 */

import { getAdminSupabaseClient, getSupabaseClient } from './src/lib/supabase-client';
import { testAdminAccess } from './src/lib/services/admin';
import { checkAdminAccess } from './src/lib/services/auth';

async function runAdminTests() {
  console.log('🧪 Testing Admin Operations...\n');

  // Test 1: Basic client initialization
  console.log('1️⃣ Testing Client Initialization:');
  try {
    const publicClient = getSupabaseClient();
    const adminClient = getAdminSupabaseClient();
    
    console.log('✅ Public client initialized');
    console.log('✅ Admin client initialized');
    
    // Check client configurations
    console.log(`   Public client URL: ${publicClient.supabaseUrl}`);
    console.log(`   Admin client URL: ${adminClient.supabaseUrl}`);
    console.log('   Keys are different:', 
      publicClient.supabaseKey !== adminClient.supabaseKey ? '✅ Yes' : '❌ No'
    );
  } catch (error) {
    console.error('❌ Client initialization failed:', error);
    return;
  }

  console.log('\n2️⃣ Testing Database Table Access:');
  
  // Test 2: Admin table access
  try {
    const adminClient = getAdminSupabaseClient();
    
    // Test admin_users table
    const { data: adminUsers, error: adminError } = await adminClient
      .from('admin_users')
      .select('id, role, is_active')
      .limit(5);
    
    if (adminError) {
      console.error('❌ admin_users access failed:', adminError.message);
    } else {
      console.log(`✅ admin_users table: ${adminUsers?.length || 0} records accessible`);
    }

    // Test products table
    const { data: products, error: productsError } = await adminClient
      .from('products')
      .select('id, name')
      .limit(5);
    
    if (productsError) {
      console.error('❌ products access failed:', productsError.message);
    } else {
      console.log(`✅ products table: ${products?.length || 0} records accessible`);
    }

    // Test customers table
    const { data: customers, error: customersError } = await adminClient
      .from('customers')
      .select('id, email')
      .limit(5);
    
    if (customersError) {
      console.error('❌ customers access failed:', customersError.message);
    } else {
      console.log(`✅ customers table: ${customers?.length || 0} records accessible`);
    }

    // Test orders table
    const { data: orders, error: ordersError } = await adminClient
      .from('orders')
      .select('id, status')
      .limit(5);
    
    if (ordersError) {
      console.error('❌ orders access failed:', ordersError.message);
    } else {
      console.log(`✅ orders table: ${orders?.length || 0} records accessible`);
    }

    // Test stripe_sync_summary table
    const { data: stripe, error: stripeError } = await adminClient
      .from('stripe_sync_summary')
      .select('id, sync_date')
      .limit(5);
    
    if (stripeError) {
      console.error('❌ stripe_sync_summary access failed:', stripeError.message);
    } else {
      console.log(`✅ stripe_sync_summary table: ${stripe?.length || 0} records accessible`);
    }

  } catch (error) {
    console.error('❌ Database access test failed:', error);
  }

  console.log('\n3️⃣ Testing Write Operations:');
  
  // Test 3: Write operations
  try {
    const adminClient = getAdminSupabaseClient();
    
    // Test inserting a test product
    const testProduct = {
      name: `Test Product ${Date.now()}`,
      description: 'Test product for admin operations',
      price: 99.99,
      category: 'test',
      status: 'draft',
      created_at: new Date().toISOString()
    };

    const { data: insertedProduct, error: insertError } = await adminClient
      .from('products')
      .insert(testProduct)
      .select()
      .single();

    if (insertError) {
      console.error('❌ Product insert failed:', insertError.message);
    } else {
      console.log('✅ Product insert successful:', insertedProduct.name);
      
      // Test updating the product
      const { error: updateError } = await adminClient
        .from('products')
        .update({ description: 'Updated test product' })
        .eq('id', insertedProduct.id);

      if (updateError) {
        console.error('❌ Product update failed:', updateError.message);
      } else {
        console.log('✅ Product update successful');
      }

      // Clean up - delete the test product
      const { error: deleteError } = await adminClient
        .from('products')
        .delete()
        .eq('id', insertedProduct.id);

      if (deleteError) {
        console.error('❌ Product delete failed (cleanup):', deleteError.message);
      } else {
        console.log('✅ Product delete successful (cleanup)');
      }
    }

  } catch (error) {
    console.error('❌ Write operations test failed:', error);
  }

  console.log('\n4️⃣ Testing Admin Service Functions:');
  
  // Test 4: Admin service functions
  try {
    const accessTest = await testAdminAccess();
    
    if (accessTest.success) {
      console.log('✅ Admin service test successful');
      console.log('   Table access results:', accessTest.data?.tableAccess);
      console.log('   All tables accessible:', 
        accessTest.data?.allTablesAccessible ? '✅ Yes' : '❌ No'
      );
    } else {
      console.error('❌ Admin service test failed:', accessTest.error);
    }

  } catch (error) {
    console.error('❌ Admin service test failed:', error);
  }

  console.log('\n5️⃣ Testing Public vs Admin Client Difference:');
  
  // Test 5: Compare public vs admin client behavior
  try {
    const publicClient = getSupabaseClient();
    const adminClient = getAdminSupabaseClient();
    
    // Try to access admin_users with public client (should have limited access)
    const { data: publicAdminData, error: publicError } = await publicClient
      .from('admin_users')
      .select('id')
      .limit(1);

    // Try to access admin_users with admin client (should have full access)
    const { data: adminAdminData, error: adminError } = await adminClient
      .from('admin_users')
      .select('*')
      .limit(1);

    console.log('Public client admin_users access:', 
      publicError ? '❌ Limited/Denied' : '✅ Allowed'
    );
    console.log('Admin client admin_users access:', 
      adminError ? '❌ Failed' : '✅ Full Access'
    );

  } catch (error) {
    console.error('❌ Client comparison test failed:', error);
  }

  console.log('\n🎉 Admin Operations Test Complete!');
  console.log('\n📋 Summary:');
  console.log('- Dual client architecture implemented');
  console.log('- Service role key being used for admin operations');
  console.log('- RLS policies should be fixed to prevent circular dependency');
  console.log('- Admin operations should now work without 401 errors');
  
  console.log('\n🔧 Next Steps:');
  console.log('1. Run the SQL fix: execute fix_admin_auth_final_v2.sql in Supabase');
  console.log('2. Ensure you have an admin user created');
  console.log('3. Test the admin panel UI operations');
  console.log('4. Monitor for any remaining 401 errors');
}

// Run the tests
runAdminTests().catch(console.error);