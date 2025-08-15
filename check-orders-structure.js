import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function checkOrdersStructure() {
  console.log('🔍 Checking orders table structure...\n');
  
  try {
    // Get table columns using Supabase's internal tables
    const { data: columns, error } = await supabase
      .from('orders')
      .select('*')
      .limit(0);
    
    if (error) {
      console.log('Error accessing orders table:', error.message);
      
      // Try to get column info from information_schema
      const { data: schemaInfo } = await supabase.rpc('get_table_columns', {
        table_name: 'orders'
      }).catch(() => ({ data: null }));
      
      if (schemaInfo) {
        console.log('Orders table columns from schema:', schemaInfo);
      }
    } else {
      // Get sample data to see structure
      const { data: sample } = await supabase
        .from('orders')
        .select('*')
        .limit(1);
      
      if (sample && sample.length > 0) {
        console.log('Orders table columns:');
        Object.keys(sample[0]).forEach(col => {
          console.log(`  - ${col}: ${typeof sample[0][col]}`);
        });
      } else {
        // Table exists but empty, try to get structure another way
        console.log('Orders table exists but is empty');
        console.log('Attempting to insert test record to see structure...');
        
        const { error: insertError } = await supabase
          .from('orders')
          .insert({
            id: '00000000-0000-0000-0000-000000000000',
            total_amount: 0
          });
        
        if (insertError) {
          console.log('Insert error reveals structure:', insertError.message);
        }
        
        // Clean up test record
        await supabase
          .from('orders')
          .delete()
          .eq('id', '00000000-0000-0000-0000-000000000000');
      }
    }
    
    // Check if customer_id column exists specifically
    console.log('\n📋 Checking for customer_id column...');
    const { data: hasCustomerId, error: checkError } = await supabase
      .from('orders')
      .select('customer_id')
      .limit(0);
    
    if (checkError && checkError.message.includes('column "customer_id" does not exist')) {
      console.log('❌ customer_id column is MISSING');
      console.log('\nTo add it, run this SQL:');
      console.log('ALTER TABLE orders ADD COLUMN customer_id UUID;');
    } else {
      console.log('✅ customer_id column exists');
    }
    
  } catch (e) {
    console.error('Error:', e.message);
  }
}

checkOrdersStructure().catch(console.error);