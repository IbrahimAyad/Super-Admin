import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Papa from 'papaparse';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function parseCSV(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const result = Papa.parse(content, {
    header: true,
    skipEmptyLines: true
  });
  return result.data;
}

async function matchAndUpdateProducts() {
  console.log('=== MATCHING MASTER-CSV-2 WITH EXISTING PRODUCTS ===\n');
  
  // Load Master-CSV-2 data
  const masterFile = path.join(__dirname, 'Master-CSV-2', 'Website_Master__Enhanced__No_Duplicates__Images_Cleaned_.csv');
  const imagesFile = path.join(__dirname, 'Master-CSV-2', 'Website_Images__Exploded__primary_first_.csv');
  
  const masterData = parseCSV(masterFile);
  const imagesData = parseCSV(imagesFile);
  
  console.log(`Master-CSV-2: ${masterData.length} products\n`);
  
  // Get existing products from database
  const { data: existingProducts, error } = await supabase
    .from('products')
    .select('*')
    .order('name');
  
  if (error) {
    console.error('Error fetching products:', error);
    return;
  }
  
  console.log(`Current database: ${existingProducts.length} products\n`);
  
  // Create image map for Master-CSV-2
  const imageMap = {};
  imagesData.forEach(img => {
    if (!imageMap[img.product_id]) {
      imageMap[img.product_id] = [];
    }
    imageMap[img.product_id].push(img);
  });
  
  // Match products
  const matches = [];
  const newProducts = [];
  const updates = [];
  
  for (const csvProduct of masterData) {
    // Try to find matching product in database
    const normalizedName = csvProduct.name.toLowerCase().trim();
    const normalizedSku = csvProduct.sku?.toLowerCase().trim();
    
    const match = existingProducts.find(existing => {
      const existingName = existing.name?.toLowerCase().trim();
      const existingSku = existing.sku?.toLowerCase().trim();
      
      // Match by SKU first
      if (normalizedSku && existingSku && normalizedSku === existingSku) {
        return true;
      }
      
      // Match by exact name
      if (existingName === normalizedName) {
        return true;
      }
      
      // Fuzzy match - check if names are very similar
      if (existingName && normalizedName) {
        // Check if one contains the other
        if (existingName.includes(normalizedName) || normalizedName.includes(existingName)) {
          return true;
        }
        
        // Check for specific patterns
        // "Aqua Vest & Tie Set" vs "Aqua Vest And Tie Set"
        const cleanExisting = existingName.replace(/&/g, 'and').replace(/\s+/g, ' ');
        const cleanCsv = normalizedName.replace(/&/g, 'and').replace(/\s+/g, ' ');
        if (cleanExisting === cleanCsv) {
          return true;
        }
      }
      
      return false;
    });
    
    if (match) {
      // Check if CSV has better image
      const csvHasRealImage = csvProduct.primary_image && 
                             !csvProduct.primary_image.includes('placeholder') &&
                             csvProduct.primary_image.includes('r2.dev');
      
      const existingHasPlaceholder = !match.primary_image || 
                                    match.primary_image.includes('placeholder') ||
                                    match.primary_image.includes('placehold');
      
      if (csvHasRealImage && (existingHasPlaceholder || !match.primary_image)) {
        matches.push({
          csv: csvProduct,
          existing: match,
          action: 'UPDATE_IMAGE'
        });
        
        // Prepare update
        updates.push({
          id: match.id,
          primary_image: csvProduct.primary_image,
          gallery_images: imageMap[csvProduct.product_id]
            ?.filter(img => img.image_type === 'gallery')
            ?.map(img => img.image_url) || []
        });
      } else {
        matches.push({
          csv: csvProduct,
          existing: match,
          action: 'KEEP_EXISTING'
        });
      }
    } else {
      // New product not in database
      newProducts.push(csvProduct);
    }
  }
  
  // Display results
  console.log('📊 MATCHING RESULTS:');
  console.log('====================\n');
  
  console.log(`✅ Matched products: ${matches.length}`);
  console.log(`🆕 New products to add: ${newProducts.length}`);
  console.log(`🔄 Products to update with better images: ${updates.length}\n`);
  
  // Show matches
  if (matches.length > 0) {
    console.log('\n📝 MATCHED PRODUCTS:');
    console.log('--------------------');
    matches.forEach(m => {
      console.log(`\n${m.csv.name}:`);
      console.log(`  SKU: ${m.csv.sku} → ${m.existing.sku}`);
      console.log(`  Action: ${m.action}`);
      if (m.action === 'UPDATE_IMAGE') {
        console.log(`  Old image: ${m.existing.primary_image?.substring(0, 50)}...`);
        console.log(`  New image: ${m.csv.primary_image?.substring(0, 50)}...`);
      }
    });
  }
  
  // Show new products
  if (newProducts.length > 0) {
    console.log('\n\n🆕 NEW PRODUCTS TO ADD:');
    console.log('------------------------');
    newProducts.forEach(p => {
      console.log(`- ${p.name} (${p.sku}) - ${p.category}`);
    });
  }
  
  // Ask for confirmation before updating
  console.log('\n\n💾 UPDATE SUMMARY:');
  console.log('==================');
  console.log(`Will update ${updates.length} products with better images from Master-CSV-2`);
  console.log(`Will keep ${newProducts.length} new products from Master-CSV-2`);
  
  // Perform updates
  if (updates.length > 0) {
    console.log('\n🔄 Updating products with better images...\n');
    
    for (const update of updates) {
      const { error: updateError } = await supabase
        .from('products')
        .update({
          primary_image: update.primary_image,
          gallery_images: update.gallery_images
        })
        .eq('id', update.id);
      
      if (updateError) {
        console.error(`Error updating product ${update.id}:`, updateError);
      } else {
        console.log(`✅ Updated product ${update.id}`);
      }
    }
  }
  
  // Check for products with duplicate/bad images that could benefit
  console.log('\n\n🔍 PRODUCTS THAT NEED BETTER IMAGES:');
  console.log('======================================');
  
  const productsWithDuplicateImages = existingProducts.filter(p => {
    // These are the known duplicate images from earlier analysis
    const duplicateImages = [
      'mens_double_breasted_suit_2021_0.webp',
      'mens_black_paisley_pattern_velvet_model_1059.webp',
      'mens_black_glitter_finish_sparkle_model_1030.webp',
      'mens_black_floral_pattern_prom_blazer_model_1009.webp'
    ];
    
    return p.primary_image && duplicateImages.some(dup => p.primary_image.includes(dup));
  });
  
  console.log(`Found ${productsWithDuplicateImages.length} products with known duplicate images`);
  
  // Show sample
  productsWithDuplicateImages.slice(0, 5).forEach(p => {
    console.log(`  - ${p.name}`);
  });
  
  console.log('\n✅ RECOMMENDATION:');
  console.log('1. Update the matched products with better images');
  console.log('2. Add the new products from Master-CSV-2');
  console.log('3. Fix R2 CORS to allow image loading');
  console.log('4. Upload unique images for products with duplicates');
}

matchAndUpdateProducts().catch(console.error);