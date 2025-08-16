import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkColumns() {
  console.log('Checking products_enhanced table structure...');
  
  try {
    // Get a sample record to see what columns exist
    const { data, error } = await supabase
      .from('products_enhanced')
      .select('*')
      .limit(1);
    
    if (error) {
      console.log('❌ Error:', error.message);
      return;
    }
    
    if (data && data.length > 0) {
      console.log('✅ Sample record columns:', Object.keys(data[0]));
      console.log('✅ Sample data:', data[0]);
    } else {
      console.log('⚠️  No records found in products_enhanced');
    }
    
  } catch (error) {
    console.error('Error checking columns:', error);
  }
}

checkColumns();