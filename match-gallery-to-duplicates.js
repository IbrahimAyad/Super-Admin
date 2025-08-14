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

async function matchGalleryImages() {
  console.log('=== MATCHING GALLERY IMAGES TO PRODUCTS ===\n');
  
  // Load gallery CSV
  const galleryData = parseCSV('product_gallery-Super-Admin.csv');
  console.log(`Gallery CSV has ${galleryData.length} unique image sets\n`);
  
  // Get products with duplicate images
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, sku, primary_image')
    .order('name');
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  // Known duplicate images
  const duplicateImages = [
    'mens_double_breasted_suit_2021_0.webp',
    'mens_black_paisley_pattern_velvet_model_1059.webp',
    'mens_black_glitter_finish_sparkle_model_1030.webp',
    'mens_black_floral_pattern_prom_blazer_model_1009.webp',
    'mens_dress_shirt_mock_neck_3001_0.webp',
    'mens_blue_casual_summer_blazer_2025_1025.webp'
  ];
  
  // Find products using duplicate images
  const productsWithDuplicates = products.filter(p => 
    p.primary_image && duplicateImages.some(dup => p.primary_image.includes(dup))
  );
  
  console.log(`Found ${productsWithDuplicates.length} products with duplicate images\n`);
  
  // Extract unique stems from gallery
  const galleryStems = new Set(galleryData.map(g => g.product_stem));
  console.log(`Gallery has ${galleryStems.size} unique product stems\n`);
  
  // Check which gallery images could be used
  console.log('🔍 AVAILABLE REPLACEMENTS IN GALLERY:\n');
  console.log('=====================================\n');
  
  // Group gallery by category
  const galleryByCategory = {};
  galleryData.forEach(g => {
    const category = g.folder || 'other';
    if (!galleryByCategory[category]) {
      galleryByCategory[category] = [];
    }
    galleryByCategory[category].push(g);
  });
  
  Object.entries(galleryByCategory).forEach(([category, items]) => {
    console.log(`${category}: ${items.length} unique products`);
  });
  
  // Match products to potential gallery images
  console.log('\n\n📸 MATCHING PRODUCTS TO GALLERY:\n');
  console.log('==================================\n');
  
  const updates = [];
  let matched = 0;
  let unmatched = [];
  
  // For double breasted suits
  const dbSuits = productsWithDuplicates.filter(p => 
    p.primary_image.includes('mens_double_breasted_suit_2021_0.webp')
  );
  
  if (dbSuits.length > 0) {
    console.log(`\n🔹 Double Breasted Suits (${dbSuits.length} products):`);
    const dbGallery = galleryData.filter(g => g.folder === 'double_breasted');
    console.log(`   Gallery has ${dbGallery.length} unique double breasted images`);
    
    // Assign different images to each suit
    dbSuits.forEach((suit, index) => {
      if (index < dbGallery.length) {
        updates.push({
          id: suit.id,
          name: suit.name,
          oldImage: suit.primary_image,
          newImage: dbGallery[index].main_image_url,
          gallery: dbGallery[index].gallery_urls
        });
        matched++;
        console.log(`   ✅ ${suit.name} → ${dbGallery[index].product_stem}`);
      } else {
        unmatched.push(suit.name);
      }
    });
  }
  
  // For velvet blazers
  const velvetBlazers = productsWithDuplicates.filter(p => 
    p.primary_image.includes('mens_black_paisley_pattern_velvet_model_1059.webp')
  );
  
  if (velvetBlazers.length > 0) {
    console.log(`\n🔹 Velvet Blazers (${velvetBlazers.length} products):`);
    const velvetGallery = galleryData.filter(g => g.folder === 'velvet');
    console.log(`   Gallery has ${velvetGallery.length} unique velvet images`);
    
    velvetBlazers.forEach((blazer, index) => {
      if (index < velvetGallery.length) {
        updates.push({
          id: blazer.id,
          name: blazer.name,
          oldImage: blazer.primary_image,
          newImage: velvetGallery[index].main_image_url,
          gallery: velvetGallery[index].gallery_urls
        });
        matched++;
        console.log(`   ✅ ${blazer.name} → ${velvetGallery[index].product_stem}`);
      } else {
        unmatched.push(blazer.name);
      }
    });
  }
  
  // For sparkle blazers
  const sparkleBlazers = productsWithDuplicates.filter(p => 
    p.primary_image.includes('mens_black_glitter_finish_sparkle_model_1030.webp')
  );
  
  if (sparkleBlazers.length > 0) {
    console.log(`\n🔹 Sparkle/Glitter Blazers (${sparkleBlazers.length} products):`);
    const glitterGallery = galleryData.filter(g => g.folder === 'glitter');
    console.log(`   Gallery has ${glitterGallery.length} unique glitter images`);
    
    sparkleBlazers.forEach((blazer, index) => {
      if (index < glitterGallery.length) {
        updates.push({
          id: blazer.id,
          name: blazer.name,
          oldImage: blazer.primary_image,
          newImage: glitterGallery[index].main_image_url,
          gallery: glitterGallery[index].gallery_urls
        });
        matched++;
        console.log(`   ✅ ${blazer.name} → ${glitterGallery[index].product_stem}`);
      } else {
        unmatched.push(blazer.name);
      }
    });
  }
  
  // Summary
  console.log('\n\n📊 SUMMARY:');
  console.log('===========');
  console.log(`Total products with duplicates: ${productsWithDuplicates.length}`);
  console.log(`Can be fixed with gallery images: ${matched}`);
  console.log(`Still need unique images: ${unmatched.length}`);
  
  if (updates.length > 0) {
    console.log('\n\n💾 APPLYING UPDATES...\n');
    
    for (const update of updates.slice(0, 50)) { // Update first 50 to test
      const galleryImages = update.gallery ? update.gallery.split(';') : [];
      
      const { error: updateError } = await supabase
        .from('products')
        .update({ 
          primary_image: update.newImage,
          gallery_images: galleryImages
        })
        .eq('id', update.id);
      
      if (updateError) {
        console.error(`❌ Error updating ${update.name}:`, updateError);
      } else {
        console.log(`✅ Updated ${update.name}`);
      }
    }
    
    console.log(`\n✅ Updated ${Math.min(updates.length, 50)} products with unique images from gallery`);
    
    if (updates.length > 50) {
      console.log(`\n⚠️ ${updates.length - 50} more products can be updated. Run again to continue.`);
    }
  }
  
  if (unmatched.length > 0) {
    console.log('\n\n⚠️ Products still needing unique images:');
    unmatched.slice(0, 20).forEach(name => console.log(`  - ${name}`));
    if (unmatched.length > 20) {
      console.log(`  ... and ${unmatched.length - 20} more`);
    }
  }
}

matchGalleryImages().catch(console.error);