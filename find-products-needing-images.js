import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function findProductsNeedingImages() {
  console.log('=== FINDING PRODUCTS THAT NEED UNIQUE IMAGES ===\n');
  
  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, sku, category, primary_image')
    .order('category, name');
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  // Known duplicate images that many products share
  const knownDuplicateImages = [
    'mens_black_paisley_pattern_velvet_model_1059.webp',
    'mens_double_breasted_suit_2021_0.webp',
    'mens_black_glitter_finish_sparkle_model_1030.webp',
    'mens_black_floral_pattern_prom_blazer_model_1009.webp',
    'mens_blue_casual_summer_blazer_2025_1025.webp',
    'mens_dress_shirt_mock_neck_3001_0.webp',
    'suit_black-3-piece-suit_1.0.jpg',
    'gold-model.png',
    'black-model.png',
    'wine-model.png',
    'coral-model.png',
    'blush-model.png',
    'fuchsia-model.png',
    'canary-model.png',
    'necktie_black-with-red-design_1.0.jpg',
    'vest_black-vest-and-tie-set_1.0.jpg',
    'blazer_black-and-red-floral-with-matching-bowtie_1.0.jpg'
  ];
  
  // Find products with issues
  const needsUniqueImage = [];
  const missingImage = [];
  const hasPlaceholder = [];
  
  products.forEach(product => {
    const image = product.primary_image;
    
    if (!image) {
      missingImage.push(product);
    } else if (image.includes('placeholder') || image.includes('placehold')) {
      hasPlaceholder.push(product);
    } else if (knownDuplicateImages.some(dup => image.includes(dup))) {
      needsUniqueImage.push(product);
    }
  });
  
  // Create CSV content
  const csvRows = ['Name,SKU,Category,Current Image,Issue'];
  
  // Add products needing unique images
  needsUniqueImage.forEach(p => {
    const imageName = p.primary_image ? p.primary_image.split('/').pop() : 'none';
    csvRows.push(`"${p.name}","${p.sku || ''}","${p.category || ''}","${imageName}","Duplicate Image"`);
  });
  
  // Add products with missing images
  missingImage.forEach(p => {
    csvRows.push(`"${p.name}","${p.sku || ''}","${p.category || ''}","none","Missing Image"`);
  });
  
  // Add products with placeholders
  hasPlaceholder.forEach(p => {
    csvRows.push(`"${p.name}","${p.sku || ''}","${p.category || ''}","placeholder","Placeholder Image"`);
  });
  
  // Save to CSV file
  const csvContent = csvRows.join('\n');
  const csvPath = path.join(__dirname, 'PRODUCTS_NEEDING_IMAGES.csv');
  fs.writeFileSync(csvPath, csvContent);
  
  // Display summary
  console.log('📊 SUMMARY:');
  console.log('===========\n');
  console.log(`Total products analyzed: ${products.length}`);
  console.log(`Products with duplicate images: ${needsUniqueImage.length}`);
  console.log(`Products with missing images: ${missingImage.length}`);
  console.log(`Products with placeholder images: ${hasPlaceholder.length}`);
  console.log(`\nTOTAL needing new images: ${needsUniqueImage.length + missingImage.length + hasPlaceholder.length}`);
  
  // Show breakdown by category
  const categoryBreakdown = {};
  [...needsUniqueImage, ...missingImage, ...hasPlaceholder].forEach(p => {
    const cat = p.category || 'Uncategorized';
    categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + 1;
  });
  
  console.log('\n📂 BY CATEGORY:');
  console.log('===============');
  Object.entries(categoryBreakdown)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`${cat}: ${count} products`);
    });
  
  // Show sample products needing images
  console.log('\n📸 SAMPLE PRODUCTS NEEDING UNIQUE IMAGES:');
  console.log('==========================================\n');
  
  const samples = needsUniqueImage.slice(0, 10);
  samples.forEach(p => {
    const imageName = p.primary_image ? p.primary_image.split('/').pop() : 'none';
    console.log(`${p.name}`);
    console.log(`  SKU: ${p.sku || 'N/A'}`);
    console.log(`  Category: ${p.category || 'N/A'}`);
    console.log(`  Current image: ${imageName}`);
    console.log('');
  });
  
  console.log('\n✅ CSV FILE CREATED:');
  console.log('====================');
  console.log(`📁 File saved as: PRODUCTS_NEEDING_IMAGES.csv`);
  console.log(`   Contains ${needsUniqueImage.length + missingImage.length + hasPlaceholder.length} products`);
  console.log('\n💡 This file lists all products that need unique images uploaded.');
  console.log('   Share this with your design team to get proper product photos.');
  
  return csvPath;
}

findProductsNeedingImages().catch(console.error);