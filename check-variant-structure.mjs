import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkStructure() {
  // Get one row to see structure
  const { data, error } = await supabase
    .from('product_variants')
    .select('*')
    .limit(1);

  if (!error && data && data.length > 0) {
    console.log('product_variants table columns:');
    console.log(Object.keys(data[0]));
    console.log('\nSample data:');
    console.log(data[0]);
  } else if (error) {
    console.log('Error:', error);
  } else {
    console.log('No data in product_variants table');
  }
  
  process.exit(0);
}

checkStructure().catch(console.error);
