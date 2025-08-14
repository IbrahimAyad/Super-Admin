import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config();

// Use the correct Supabase instance
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

// Initialize Supabase client with service role key
const supabase = createClient(
  SUPABASE_URL,
  SERVICE_ROLE_KEY
);

// Parse CSV
function parseCSV(content) {
  const lines = content.split('\n');
  const headers = lines[0].split(',').map(h => h.trim());
  const data = [];
  
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    
    // Handle CSV with potential commas in values
    const values = [];
    let currentValue = '';
    let inQuotes = false;
    
    for (let char of lines[i]) {
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        values.push(currentValue.trim());
        currentValue = '';
      } else {
        currentValue += char;
      }
    }
    values.push(currentValue.trim());
    
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index] || '';
    });
    data.push(row);
  }
  
  return data;
}

// Step 1: Backup current data
async function backupData() {
  console.log('📦 Creating backup...');
  
  const timestamp = new Date().toISOString().split('T')[0];
  
  // This should be done in SQL, but for safety we'll note it
  console.log(`
⚠️  IMPORTANT: Run this in Supabase SQL Editor first:
  
CREATE TABLE IF NOT EXISTS products_backup_${timestamp.replace(/-/g, '_')} AS 
SELECT * FROM products;

CREATE TABLE IF NOT EXISTS product_variants_backup_${timestamp.replace(/-/g, '_')} AS 
SELECT * FROM product_variants;

CREATE TABLE IF NOT EXISTS product_images_backup_${timestamp.replace(/-/g, '_')} AS 
SELECT * FROM product_images;
  `);
  
  console.log('✅ Backup reminder displayed\n');
}

// Step 2: Import Products
async function importProducts() {
  console.log('📦 Importing products...\n');
  
  const csvPath = path.join(__dirname, 'kct_master_exports', 'master_product_final.csv');
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const products = parseCSV(csvContent);
  
  let imported = 0;
  let updated = 0;
  let errors = 0;
  
  for (const product of products) {
    try {
      const productData = {
        id: product.product_id,
        name: product.name,
        handle: product.handle,
        sku: product.sku,
        category: product.category,
        description: product.description,
        status: product.status || 'active',
        base_price: product.base_price === '0' || !product.base_price ? null : parseInt(product.base_price),
        primary_image: product.primary_image?.includes('placehold') ? null : product.primary_image,
        meta_title: product.meta_title,
        meta_description: product.meta_description,
        search_keywords: product.search_keywords,
        tags: product.tags ? product.tags.split(',').map(t => t.trim()) : []
      };
      
      // Check if product exists
      const { data: existing } = await supabase
        .from('products')
        .select('id')
        .eq('id', productData.id)
        .single();
      
      if (existing) {
        const { error } = await supabase
          .from('products')
          .update(productData)
          .eq('id', productData.id);
        
        if (error) throw error;
        updated++;
      } else {
        const { error } = await supabase
          .from('products')
          .insert(productData);
        
        if (error) throw error;
        imported++;
      }
      
      process.stdout.write(`\rProcessed: ${imported + updated}/${products.length}`);
      
    } catch (error) {
      errors++;
      console.error(`\n❌ Error with ${product.name}:`, error.message);
    }
  }
  
  console.log(`\n✅ Products: ${imported} new, ${updated} updated, ${errors} errors\n`);
}

// Step 3: Import Variants
async function importVariants() {
  console.log('📏 Importing variants...\n');
  
  const csvPath = path.join(__dirname, 'kct_master_exports', 'product_variants_import.csv');
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const variants = parseCSV(csvContent);
  
  let imported = 0;
  let errors = 0;
  
  // Group variants by product to batch insert
  const variantsByProduct = {};
  variants.forEach(v => {
    if (!variantsByProduct[v.product_id]) {
      variantsByProduct[v.product_id] = [];
    }
    variantsByProduct[v.product_id].push(v);
  });
  
  for (const [productId, productVariants] of Object.entries(variantsByProduct)) {
    try {
      // Delete existing variants for this product
      await supabase
        .from('product_variants')
        .delete()
        .eq('product_id', productId);
      
      // Prepare variant data
      const variantData = productVariants.map(v => {
        // Extract size from variant title
        const titleParts = v.variant_title.split(' - ');
        const size = titleParts[titleParts.length - 1] || 'One Size';
        
        return {
          product_id: v.product_id,
          size: size,
          color: 'Default',
          sku: v.sku || `${v.product_id}-${size}`,
          price: parseInt(v.price_cents) || 0,
          inventory_quantity: 100,
          stripe_price_id: v.stripe_price_id,
          stripe_active: v.stripe_active === 'True'
        };
      });
      
      // Insert all variants for this product
      const { error } = await supabase
        .from('product_variants')
        .insert(variantData);
      
      if (error) throw error;
      imported += variantData.length;
      
      process.stdout.write(`\rProcessed: ${imported}/${variants.length} variants`);
      
    } catch (error) {
      errors++;
      console.error(`\n❌ Error with product ${productId}:`, error.message);
    }
  }
  
  console.log(`\n✅ Variants: ${imported} imported, ${errors} errors\n`);
}

// Step 4: Import Images
async function importImages() {
  console.log('🖼️ Importing images...\n');
  
  const csvPath = path.join(__dirname, 'kct_master_exports', 'product_images_import.csv');
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const images = parseCSV(csvContent);
  
  let imported = 0;
  let errors = 0;
  
  // Group images by product
  const imagesByProduct = {};
  images.forEach(img => {
    if (!imagesByProduct[img.product_id]) {
      imagesByProduct[img.product_id] = [];
    }
    imagesByProduct[img.product_id].push(img);
  });
  
  for (const [productId, productImages] of Object.entries(imagesByProduct)) {
    try {
      // Delete existing images for this product
      await supabase
        .from('product_images')
        .delete()
        .eq('product_id', productId);
      
      // Prepare image data
      const imageData = productImages
        .filter(img => img.image_url && img.image_url !== 'nan')
        .map((img, index) => ({
          product_id: img.product_id,
          image_url: img.image_url,
          position: parseInt(img.position) || (index + 1),
          alt_text: img.alt_text || '',
          image_type: img.image_type || 'gallery'
        }));
      
      if (imageData.length > 0) {
        const { error } = await supabase
          .from('product_images')
          .insert(imageData);
        
        if (error) throw error;
        imported += imageData.length;
      }
      
      process.stdout.write(`\rProcessed: ${imported}/${images.length} images`);
      
    } catch (error) {
      errors++;
      console.error(`\n❌ Error with product ${productId}:`, error.message);
    }
  }
  
  console.log(`\n✅ Images: ${imported} imported, ${errors} errors\n`);
}

// Step 5: Import Tags
async function importTags() {
  console.log('🏷️ Importing tags...\n');
  
  const csvPath = path.join(__dirname, 'kct_master_exports', 'product_tags_import.csv');
  
  if (!fs.existsSync(csvPath)) {
    console.log('⚠️ No tags file found, skipping...\n');
    return;
  }
  
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const tags = parseCSV(csvContent);
  
  // Group tags by product
  const tagsByProduct = {};
  tags.forEach(tag => {
    if (!tagsByProduct[tag.product_id]) {
      tagsByProduct[tag.product_id] = [];
    }
    tagsByProduct[tag.product_id].push(tag.tag_name);
  });
  
  let updated = 0;
  
  for (const [productId, productTags] of Object.entries(tagsByProduct)) {
    try {
      const { error } = await supabase
        .from('products')
        .update({ tags: productTags })
        .eq('id', productId);
      
      if (!error) updated++;
      
    } catch (error) {
      console.error(`❌ Error updating tags for ${productId}:`, error.message);
    }
  }
  
  console.log(`✅ Tags: ${updated} products updated\n`);
}

// Step 6: Verify Import
async function verifyImport() {
  console.log('🔍 Verifying import...\n');
  
  // Count products
  const { count: productCount } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true });
  
  // Count variants
  const { count: variantCount } = await supabase
    .from('product_variants')
    .select('*', { count: 'exact', head: true });
  
  // Count variants with Stripe
  const { count: stripeCount } = await supabase
    .from('product_variants')
    .select('*', { count: 'exact', head: true })
    .not('stripe_price_id', 'is', null);
  
  // Count images
  const { count: imageCount } = await supabase
    .from('product_images')
    .select('*', { count: 'exact', head: true });
  
  console.log('📊 IMPORT RESULTS:');
  console.log(`✅ Products: ${productCount}`);
  console.log(`✅ Variants: ${variantCount}`);
  console.log(`✅ Variants with Stripe: ${stripeCount} (${Math.round(stripeCount/variantCount*100)}%)`);
  console.log(`✅ Images: ${imageCount}`);
  console.log('');
  
  // Test a few products
  const { data: sampleProducts } = await supabase
    .from('products')
    .select('name, category')
    .limit(5);
  
  console.log('Sample products:');
  sampleProducts?.forEach(p => console.log(`  - ${p.name} (${p.category})`));
}

// Main import function
async function runImport() {
  console.log('🚀 KCT MASTER DATA IMPORT\n');
  console.log('This will import:');
  console.log('• 231 products');
  console.log('• 2,592 variants with sizes');
  console.log('• 309 product images');
  console.log('• Product tags\n');
  
  // Service role key is configured
  
  try {
    await backupData();
    
    console.log('Starting import...\n');
    
    await importProducts();
    await importVariants();
    await importImages();
    await importTags();
    await verifyImport();
    
    console.log('✅ IMPORT COMPLETE!\n');
    console.log('Next steps:');
    console.log('1. Test checkout with a few products');
    console.log('2. Verify images are loading');
    console.log('3. Check size selection works');
    console.log('4. Confirm Stripe checkout processes');
    
  } catch (error) {
    console.error('❌ Import failed:', error);
    process.exit(1);
  }
}

// Run the import
runImport();