import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSizes() {
  console.log('Checking how sizes are stored...\n');

  // Check products_enhanced for size-related fields
  const { data: products, error: productsError } = await supabase
    .from('products_enhanced')
    .select('*')
    .limit(2);

  if (!productsError && products && products.length > 0) {
    console.log('📦 products_enhanced fields:');
    const product = products[0];
    const sizeRelatedFields = Object.keys(product).filter(key => 
      key.toLowerCase().includes('size') || 
      key.toLowerCase().includes('option') ||
      key.toLowerCase().includes('variant')
    );
    console.log('   Size-related fields:', sizeRelatedFields.length > 0 ? sizeRelatedFields : 'None found');
    
    // Check for arrays or JSON fields
    if (product.sizes) console.log('   sizes field:', product.sizes);
    if (product.size_options) console.log('   size_options field:', product.size_options);
    if (product.available_sizes) console.log('   available_sizes field:', product.available_sizes);
    if (product.options) console.log('   options field:', product.options);
    if (product.variants) console.log('   variants field:', product.variants);
  }

  // Check if there's a separate sizes table
  const { data: sizesTable, error: sizesError } = await supabase
    .from('sizes')
    .select('*')
    .limit(5);

  if (!sizesError) {
    console.log('\n✅ sizes table exists');
    console.log('   Sample data:', sizesTable);
  } else {
    console.log('\n❌ No separate sizes table');
  }

  // Check product_sizes junction table
  const { data: productSizes, error: productSizesError } = await supabase
    .from('product_sizes')
    .select('*')
    .limit(5);

  if (!productSizesError) {
    console.log('\n✅ product_sizes table exists');
    console.log('   Sample data:', productSizes);
  } else {
    console.log('\n❌ No product_sizes junction table');
  }

  // Check actual product_variants with data
  const { data: variants, error: variantsError } = await supabase
    .from('product_variants')
    .select('*')
    .limit(10);

  if (!variantsError && variants) {
    console.log('\n📊 product_variants analysis:');
    console.log('   Total retrieved:', variants.length);
    const withSizes = variants.filter(v => v.size && v.size !== 'One Size');
    console.log('   With actual sizes:', withSizes.length);
    if (withSizes.length > 0) {
      console.log('   Sample sizes:', withSizes.map(v => v.size).slice(0, 5));
    }
  }

  process.exit(0);
}

checkSizes().catch(console.error);
