import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

// Size templates by category
const SIZE_TEMPLATES = {
  'Blazers': ['34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R'],
  'Suits': ['34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R'],
  'Shirts': ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
  'Pants': ['28', '30', '32', '34', '36', '38', '40', '42'],
  'Accessories': ['One Size'],
  'default': ['S', 'M', 'L', 'XL', 'XXL']
};

async function populateSizes() {
  console.log('🚀 Starting to populate product sizes...\n');

  // Get all products
  const { data: products, error: productsError } = await supabase
    .from('products_enhanced')
    .select('*')
    .order('created_at', { ascending: false });

  if (productsError) {
    console.error('Error fetching products:', productsError);
    return;
  }

  console.log(`Found ${products.length} products to process\n`);

  let created = 0;
  let skipped = 0;
  let errors = 0;

  for (const product of products) {
    const category = product.category || 'default';
    const sizes = SIZE_TEMPLATES[category] || SIZE_TEMPLATES.default;
    
    console.log(`Processing: ${product.name} (${category})`);
    console.log(`  Will create ${sizes.length} size variants`);

    // Check if variants already exist for this product
    const { data: existingVariants } = await supabase
      .from('product_variants')
      .select('id')
      .eq('product_id', product.id);

    if (existingVariants && existingVariants.length > 0) {
      console.log(`  ⏭️  Skipping - already has ${existingVariants.length} variants`);
      skipped++;
      continue;
    }

    // Create variants for each size
    for (const size of sizes) {
      const variantData = {
        product_id: product.id,
        title: `${product.name} - ${size}`,
        option1: size, // Size in option1
        option2: product.color_name || product.color_family || 'Default', // Color in option2
        sku: `${product.sku}-${size.replace(/\s+/g, '')}`,
        price: product.base_price, // Already in cents
        inventory_quantity: size === 'One Size' ? 100 : Math.floor(Math.random() * 20) + 5, // Random inventory 5-25 for sizes, 100 for one-size
        available: true,
        available_quantity: size === 'One Size' ? 100 : Math.floor(Math.random() * 20) + 5,
        reserved_quantity: 0,
        stock_quantity: size === 'One Size' ? 100 : Math.floor(Math.random() * 20) + 5
      };

      const { error: insertError } = await supabase
        .from('product_variants')
        .insert(variantData);

      if (insertError) {
        console.log(`  ❌ Error creating variant for size ${size}:`, insertError.message);
        errors++;
      } else {
        console.log(`  ✅ Created variant: ${size}`);
        created++;
      }
    }
  }

  console.log('\n📊 Summary:');
  console.log(`  Created: ${created} variants`);
  console.log(`  Skipped: ${skipped} products (already had variants)`);
  console.log(`  Errors: ${errors}`);
  
  process.exit(0);
}

populateSizes().catch(console.error);