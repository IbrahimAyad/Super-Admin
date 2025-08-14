import { createClient } from '@supabase/supabase-js';

// Test both possible Supabase instances
const instances = [
  {
    name: 'Instance 1 (from service key)',
    url: 'https://vkbkzkuvdtuftvewnnue.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZrYmt6a3V2ZHR1ZnR2ZXdubnVlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDUzODY1OCwiZXhwIjoyMDUwMTE0NjU4fQ.l5Y0JbZToNRBR-mgVy4aKrjT5wTYcQBBGcfKmuQzPDU'
  },
  {
    name: 'Instance 2 (from code)',
    url: 'https://gvcswimqaxvylgxbklbz.supabase.co',
    key: 'Need service role key for this instance'
  }
];

console.log('Testing Supabase connections...\n');

for (const instance of instances) {
  console.log(`Testing ${instance.name}:`);
  console.log(`URL: ${instance.url}`);
  
  if (instance.key.includes('Need')) {
    console.log('❌ Service role key not available for this instance');
    console.log('   You need to get the service role key from Supabase dashboard\n');
    continue;
  }
  
  try {
    const supabase = createClient(instance.url, instance.key);
    
    // Try to count products
    const { count, error } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.log(`❌ Error: ${error.message}`);
    } else {
      console.log(`✅ Connected! Found ${count} products`);
    }
    
    // Try to get table info
    const { data: tables, error: tablesError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .limit(5);
    
    if (!tablesError && tables) {
      console.log(`   Tables found: ${tables.length}`);
    }
    
  } catch (err) {
    console.log(`❌ Connection failed: ${err.message}`);
  }
  
  console.log('');
}

console.log('\n📝 IMPORTANT:');
console.log('The service role key you provided is for: vkbkzkuvdtuftvewnnue.supabase.co');
console.log('But your app code uses: gvcswimqaxvylgxbklbz.supabase.co');
console.log('');
console.log('You need to either:');
console.log('1. Get the service role key for gvcswimqaxvylgxbklbz from Supabase dashboard');
console.log('2. Or confirm which Supabase instance has your production data');