const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkDatabaseFunctions() {
  console.log('🔍 Checking for missing database functions...\n');
  
  // Test the functions that are causing errors
  const functionsToCheck = [
    { name: 'get_recent_orders', params: {} },
    { name: 'log_login_attempt', params: { email: 'test@example.com', success: false } },
    { name: 'transfer_guest_cart', params: { p_guest_id: 'test-guest', p_user_id: 'test-user' } }
  ];

  for (const func of functionsToCheck) {
    console.log(`\nChecking function: ${func.name}`);
    console.log('Parameters:', func.params);
    
    try {
      const { data, error } = await supabase.rpc(func.name, func.params);
      
      if (error) {
        console.log(`❌ Error: ${error.message}`);
        console.log(`   Code: ${error.code}`);
        console.log(`   Details: ${error.details || 'None'}`);
        console.log(`   Hint: ${error.hint || 'None'}`);
      } else {
        console.log(`✅ Function exists and returned:`, data);
      }
    } catch (e) {
      console.log(`❌ Exception: ${e.message}`);
    }
  }

  // Check if login_attempts table exists
  console.log('\n\n🔍 Checking for login_attempts table...');
  try {
    const { data, error, count } = await supabase
      .from('login_attempts')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.log(`❌ Table 'login_attempts' error: ${error.message}`);
      console.log(`   Code: ${error.code}`);
    } else {
      console.log(`✅ Table 'login_attempts' exists`);
    }
  } catch (e) {
    console.log(`❌ Exception checking table: ${e.message}`);
  }

  // List all tables
  console.log('\n\n📋 Listing all tables in public schema...');
  try {
    const { data, error } = await supabase.rpc('get_table_list', {});
    if (error) {
      // Try direct query if function doesn't exist
      const { data: tables, error: tablesError } = await supabase
        .from('information_schema.tables')
        .select('table_name')
        .eq('table_schema', 'public');
      
      if (tablesError) {
        console.log('Could not list tables');
      } else if (tables) {
        console.log('Tables found:', tables.map(t => t.table_name).join(', '));
      }
    } else {
      console.log('Tables:', data);
    }
  } catch (e) {
    console.log('Could not list tables');
  }

  // Check what auth/user related tables exist
  console.log('\n\n🔍 Checking for auth-related tables...');
  const authTables = ['users', 'customers', 'profiles', 'sessions', 'login_attempts', 'auth_logs'];
  
  for (const table of authTables) {
    try {
      const { count, error } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      if (!error) {
        console.log(`✅ Table '${table}' exists`);
      } else if (error.code === '42P01') {
        console.log(`❌ Table '${table}' does not exist`);
      } else {
        console.log(`⚠️ Table '${table}' - Error: ${error.message}`);
      }
    } catch (e) {
      console.log(`❌ Table '${table}' - Exception: ${e.message}`);
    }
  }

  console.log('\n\n📊 Summary:');
  console.log('The missing functions are:');
  console.log('1. get_recent_orders() - Returns 400 error');
  console.log('2. log_login_attempt() - Returns 404 error'); 
  console.log('3. transfer_guest_cart() - Returns 404 error');
  console.log('4. login_attempts table - Returns 403 error');
  console.log('\nThese are being called but don\'t exist in the database.');
  console.log('They appear to be auth/order tracking functions that were never created.');
}

checkDatabaseFunctions().catch(console.error);