import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTables() {
  console.log('Checking for products_enhanced table...');
  
  try {
    // Test if products_enhanced exists
    const { data: enhanced, error: enhancedError } = await supabase
      .from('products_enhanced')
      .select('id, name')
      .limit(1);
    
    if (enhancedError) {
      console.log('❌ products_enhanced table error:', enhancedError.message);
    } else {
      console.log('✅ products_enhanced table exists, sample:', enhanced);
    }
    
    // Check regular products table
    const { data: regular, error: regularError } = await supabase
      .from('products')
      .select('id, name')
      .limit(1);
    
    if (regularError) {
      console.log('❌ products table error:', regularError.message);
    } else {
      console.log('✅ products table exists, sample:', regular);
    }
    
  } catch (error) {
    console.error('Error checking tables:', error);
  }
}

checkTables();