import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Papa from 'papaparse';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function parseCSV(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const result = Papa.parse(content, {
    header: true,
    skipEmptyLines: true
  });
  return result.data;
}

function analyzeMasterCSV2() {
  console.log('=== ANALYZING MASTER-CSV-2 FOLDER ===\n');
  
  const folder = path.join(__dirname, 'Master-CSV-2');
  
  // 1. Analyze main product file
  console.log('📦 1. WEBSITE MASTER (Enhanced, No Duplicates):');
  console.log('================================================\n');
  
  const masterFile = path.join(folder, 'Website_Master__Enhanced__No_Duplicates__Images_Cleaned_.csv');
  const masterData = parseCSV(masterFile);
  
  console.log(`Total products: ${masterData.length}`);
  
  // Check for unique images
  const imageSet = new Set();
  const duplicateImages = [];
  
  masterData.forEach(row => {
    if (row.primary_image) {
      if (imageSet.has(row.primary_image)) {
        duplicateImages.push(row.primary_image);
      } else {
        imageSet.add(row.primary_image);
      }
    }
  });
  
  console.log(`Unique images: ${imageSet.size}`);
  console.log(`Duplicate images: ${duplicateImages.length}`);
  
  // Check categories
  const categories = {};
  masterData.forEach(row => {
    const cat = row.category || 'Uncategorized';
    categories[cat] = (categories[cat] || 0) + 1;
  });
  
  console.log('\nCategories breakdown:');
  Object.entries(categories)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count}`);
    });
  
  // Check Stripe integration
  let hasStripeCount = 0;
  let missingStripeCount = 0;
  
  masterData.forEach(row => {
    if (row.stripe_price_id && row.stripe_price_id !== 'null' && row.stripe_price_id !== '') {
      hasStripeCount++;
    } else {
      missingStripeCount++;
    }
  });
  
  console.log(`\n💳 Stripe Integration:`);
  console.log(`  With Stripe IDs: ${hasStripeCount}`);
  console.log(`  Missing Stripe: ${missingStripeCount}`);
  
  // 2. Analyze variants file
  console.log('\n\n📊 2. WEBSITE VARIANTS (Size Collapsed):');
  console.log('=========================================\n');
  
  const variantsFile = path.join(folder, 'Website_Variants__Suspenders_collapsed_to_One_Size_.csv');
  const variantsData = parseCSV(variantsFile);
  
  console.log(`Total variants: ${variantsData.length}`);
  
  // Count unique products in variants
  const uniqueProducts = new Set(variantsData.map(v => v.product_id));
  console.log(`Unique products with variants: ${uniqueProducts.size}`);
  
  // Check sizes
  const sizes = {};
  variantsData.forEach(row => {
    const size = row.size || 'No Size';
    sizes[size] = (sizes[size] || 0) + 1;
  });
  
  console.log('\nSize distribution:');
  Object.entries(sizes)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15)
    .forEach(([size, count]) => {
      console.log(`  ${size}: ${count}`);
    });
  
  // Check Stripe in variants
  let variantStripeCount = 0;
  variantsData.forEach(row => {
    if (row.stripe_price_id && row.stripe_price_id !== 'null') {
      variantStripeCount++;
    }
  });
  
  console.log(`\nVariants with Stripe IDs: ${variantStripeCount}/${variantsData.length}`);
  
  // 3. Analyze images file
  console.log('\n\n🖼️ 3. WEBSITE IMAGES (Exploded):');
  console.log('==================================\n');
  
  const imagesFile = path.join(folder, 'Website_Images__Exploded__primary_first_.csv');
  const imagesData = parseCSV(imagesFile);
  
  console.log(`Total image entries: ${imagesData.length}`);
  
  // Count image types
  const imageTypes = {};
  imagesData.forEach(row => {
    const type = row.image_type || 'Unknown';
    imageTypes[type] = (imageTypes[type] || 0) + 1;
  });
  
  console.log('\nImage types:');
  Object.entries(imageTypes).forEach(([type, count]) => {
    console.log(`  ${type}: ${count}`);
  });
  
  // Check for R2 URLs
  let r2Count = 0;
  let httpCount = 0;
  let relativeCount = 0;
  
  imagesData.forEach(row => {
    const url = row.image_url || '';
    if (url.includes('r2.dev')) r2Count++;
    else if (url.startsWith('http')) httpCount++;
    else relativeCount++;
  });
  
  console.log('\nImage URL types:');
  console.log(`  R2 bucket: ${r2Count}`);
  console.log(`  HTTP URLs: ${httpCount}`);
  console.log(`  Relative paths: ${relativeCount}`);
  
  // Sample some images
  console.log('\nSample image URLs:');
  imagesData.slice(0, 5).forEach(row => {
    console.log(`  ${row.product_id}: ${row.image_url?.substring(0, 80)}...`);
  });
  
  // COMPARISON WITH CURRENT DATA
  console.log('\n\n⚖️ COMPARISON WITH CURRENT IMPORTED DATA:');
  console.log('==========================================\n');
  
  console.log('Current import (kct_master_exports):');
  console.log('  - 231 products (8 failed due to missing prices)');
  console.log('  - 399 variants with 100% Stripe coverage');
  console.log('  - 262 images');
  console.log('  - Many duplicate images');
  
  console.log('\nMaster-CSV-2:');
  console.log(`  - ${masterData.length} products (${masterData.length > 231 ? '+' : ''}${masterData.length - 231} difference)`);
  console.log(`  - ${variantsData.length} variants (${variantsData.length > 399 ? '+' : ''}${variantsData.length - 399} difference)`);
  console.log(`  - ${imagesData.length} image entries`);
  console.log(`  - ${imageSet.size} unique images (much better!)`);
  
  // Check for specific products
  console.log('\n\n🔍 KEY PRODUCT CHECK:');
  console.log('=====================\n');
  
  const keyProducts = {
    suits: masterData.filter(p => p.category?.toLowerCase().includes('suit')).length,
    tuxedos: masterData.filter(p => p.category?.toLowerCase().includes('tuxedo')).length,
    blazers: masterData.filter(p => p.category?.toLowerCase().includes('blazer')).length,
    vests: masterData.filter(p => p.category?.toLowerCase().includes('vest')).length,
    shirts: masterData.filter(p => p.category?.toLowerCase().includes('shirt')).length,
    suspenders: masterData.filter(p => p.category?.toLowerCase().includes('suspender')).length
  };
  
  Object.entries(keyProducts).forEach(([type, count]) => {
    console.log(`  ${type}: ${count} products`);
  });
  
  // RECOMMENDATION
  console.log('\n\n✅ RECOMMENDATION:');
  console.log('==================\n');
  
  const betterData = 
    imageSet.size > 100 && // More unique images
    variantsData.length > 300 && // Good variant coverage
    hasStripeCount > 100; // Some Stripe integration
  
  if (betterData) {
    console.log('✅ Master-CSV-2 appears to have BETTER data:');
    console.log('   - More unique images (less duplicates)');
    console.log('   - Comprehensive variant data with sizes');
    console.log('   - Clean, deduplicated product data');
    console.log('\n   RECOMMENDED: Import from Master-CSV-2 for better quality');
  } else {
    console.log('⚠️ Current data may be sufficient');
    console.log('   But Master-CSV-2 has cleaner image data');
  }
  
  // Show what's missing
  console.log('\n\n⚠️ POTENTIAL ISSUES:');
  console.log('====================\n');
  
  if (missingStripeCount > 50) {
    console.log(`- ${missingStripeCount} products missing Stripe IDs (need mapping)`);
  }
  
  if (relativeCount > 0) {
    console.log(`- ${relativeCount} images with relative paths (need full URLs)`);
  }
  
  console.log('\n💡 NEXT STEPS:');
  console.log('1. Backup current data');
  console.log('2. Import Master-CSV-2 data');
  console.log('3. Map Stripe price IDs');
  console.log('4. Fix image URLs to use R2 bucket');
}

analyzeMasterCSV2();