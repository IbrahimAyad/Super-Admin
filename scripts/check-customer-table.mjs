/**
 * CHECK CUSTOMER TABLE STRUCTURE
 * Uses the anon key to check what columns exist
 */

import { createClient } from '@supabase/supabase-js';

// Use environment variables
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkTable() {
  console.log('Checking customers table structure...\n');
  
  // Try to fetch one record to see the structure
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .limit(1);
  
  if (error) {
    console.error('Error:', error.message);
    return;
  }
  
  if (data && data.length > 0) {
    console.log('Columns found in customers table:');
    console.log(Object.keys(data[0]).join(', '));
    console.log('\nSample record (first 5 fields):');
    const sample = Object.entries(data[0]).slice(0, 5);
    sample.forEach(([key, value]) => {
      console.log(`  ${key}: ${value}`);
    });
  } else {
    console.log('No records found, but table exists');
  }
  
  // Count existing customers
  const { count } = await supabase
    .from('customers')
    .select('*', { count: 'exact', head: true });
  
  console.log(`\nTotal customers in table: ${count || 0}`);
  
  // Check for new columns
  const newColumns = [
    'first_name', 'last_name', 'name', 'accepts_email_marketing', 
    'total_spent', 'customer_tier', 'vip_status'
  ];
  
  if (data && data.length > 0) {
    const existingColumns = Object.keys(data[0]);
    console.log('\nNew column status:');
    newColumns.forEach(col => {
      const exists = existingColumns.includes(col);
      console.log(`  ${col}: ${exists ? '✅ EXISTS' : '❌ MISSING'}`);
    });
  }
}

checkTable().catch(console.error);