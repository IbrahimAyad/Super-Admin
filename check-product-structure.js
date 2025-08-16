const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTables() {
  console.log('Checking product-related tables...\n');

  // Check product_variants table
  const { data: variants, error: variantsError } = await supabase
    .from('product_variants')
    .select('*')
    .limit(5);

  if (variantsError) {
    console.log('❌ product_variants table:', variantsError.message);
  } else {
    console.log('✅ product_variants table exists');
    console.log('   Sample count:', variants?.length || 0);
    if (variants && variants.length > 0) {
      console.log('   Sample variant:', {
        product_id: variants[0].product_id,
        size: variants[0].size,
        color: variants[0].color,
        inventory_quantity: variants[0].inventory_quantity
      });
    }
  }

  // Check inventory table
  const { data: inventory, error: inventoryError } = await supabase
    .from('inventory')
    .select('*')
    .limit(5);

  if (inventoryError) {
    console.log('\n❌ inventory table:', inventoryError.message);
  } else {
    console.log('\n✅ inventory table exists');
    console.log('   Sample count:', inventory?.length || 0);
  }

  // Check products_enhanced for variant/inventory fields
  const { data: products, error: productsError } = await supabase
    .from('products_enhanced')
    .select('*')
    .limit(1);

  if (products && products.length > 0) {
    console.log('\n📦 products_enhanced structure:');
    const product = products[0];
    console.log('   Has sizes field?', 'sizes' in product);
    console.log('   Has variants field?', 'variants' in product);
    console.log('   Has inventory_quantity field?', 'inventory_quantity' in product);
    console.log('   Has stock_quantity field?', 'stock_quantity' in product);
  }

  process.exit(0);
}

checkTables().catch(console.error);
