import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.WP6fHzd1PGFxaILz3r1O4lNKLqy-WB5Q89Ht3iGzrLM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function importProducts() {
  console.log('Starting product import...\n');
  
  // Test products - 3 vests
  const testProducts = [
    {
      name: 'White Vest And Tie Set',
      image_url: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg',
      price: 6500,
      color: 'White'
    },
    {
      name: 'Blush Vest And Tie Set',
      image_url: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg',
      price: 6500,
      color: 'Blush'
    },
    {
      name: 'Blue Carolina Vest And Tie Set',
      image_url: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg',
      price: 6500,
      color: 'Carolina Blue'
    }
  ];
  
  const sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
  let productCounter = 1;
  
  for (const product of testProducts) {
    const sku = `VEST-${String(productCounter).padStart(3, '0')}`;
    const handle = product.name.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-');
    
    console.log(`Importing: ${product.name}`);
    
    // Insert product
    const { data: productData, error: productError } = await supabase
      .from('products')
      .insert({
        sku,
        handle,
        name: product.name,
        description: 'Premium vest and tie set for formal occasions',
        base_price: product.price,
        category: 'Vest & Tie Sets',
        status: 'active',
        primary_image: product.image_url,
        additional_info: {
          source: 'csv_import_test',
          import_date: new Date().toISOString()
        }
      })
      .select()
      .single();
    
    if (productError) {
      console.error(`Error inserting product ${product.name}:`, productError);
      continue;
    }
    
    console.log(`✓ Created product: ${productData.name} (ID: ${productData.id})`);
    
    // Insert variants with title
    for (const size of sizes) {
      const variantSku = `${sku}-${size.replace(' ', '')}`;
      const title = `${product.name} - Size ${size}`;
      
      const { error: variantError } = await supabase
        .from('product_variants')
        .insert({
          product_id: productData.id,
          title: title,  // Include the required title
          option1: size,  // Size
          option2: product.color,  // Color
          sku: variantSku,
          price: product.price,
          inventory_quantity: size === 'M' || size === 'L' || size === 'XL' ? 25 : 15
        });
      
      if (variantError) {
        console.error(`Error inserting variant ${variantSku}:`, variantError);
      }
    }
    
    console.log(`✓ Created ${sizes.length} variants for ${product.name}\n`);
    
    // Also add to product_images table
    await supabase
      .from('product_images')
      .insert({
        product_id: productData.id,
        image_url: product.image_url,
        image_type: 'primary',
        position: 1,
        alt_text: product.name
      });
    
    productCounter++;
  }
  
  // Update product counts
  const { data: importedProducts } = await supabase
    .from('products')
    .select('id')
    .eq('additional_info->source', 'csv_import_test');
  
  for (const product of importedProducts || []) {
    const { data: variants } = await supabase
      .from('product_variants')
      .select('inventory_quantity')
      .eq('product_id', product.id);
    
    const variantCount = variants?.length || 0;
    const totalInventory = variants?.reduce((sum, v) => sum + (v.inventory_quantity || 0), 0) || 0;
    
    await supabase
      .from('products')
      .update({
        variant_count: variantCount,
        total_inventory: totalInventory
      })
      .eq('id', product.id);
  }
  
  // Summary
  const { data: summary } = await supabase
    .from('products')
    .select('*')
    .eq('additional_info->source', 'csv_import_test');
  
  console.log('\n=== IMPORT SUMMARY ===');
  console.log(`Total products imported: ${summary?.length || 0}`);
  
  if (summary && summary.length > 0) {
    console.log('\nImported products:');
    summary.forEach(p => {
      console.log(`- ${p.sku}: ${p.name} ($${(p.base_price/100).toFixed(2)})`);
    });
  }
  
  console.log('\n✅ Import complete!');
  console.log('\nTo import all 233 products, run the full SQL script in Supabase SQL Editor:');
  console.log('https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/sql/new');
}

importProducts().catch(console.error);