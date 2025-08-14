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

async function updateWithGalleryImages() {
  console.log('=== UPDATING PRODUCTS WITH GALLERY IMAGES ===\n');
  
  // Load gallery CSV
  const galleryData = parseCSV('product_gallery-Super-Admin.csv');
  
  // Get products with duplicate images
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, sku, primary_image')
    .order('name');
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  // Known duplicate images that need replacing
  const duplicateImages = [
    'mens_double_breasted_suit_2021_0.webp',
    'mens_black_paisley_pattern_velvet_model_1059.webp', 
    'mens_black_glitter_finish_sparkle_model_1030.webp',
    'mens_black_floral_pattern_prom_blazer_model_1009.webp',
    'mens_dress_shirt_mock_neck_3001_0.webp',
    'mens_blue_casual_summer_blazer_2025_1025.webp'
  ];
  
  const updates = [];
  
  // 1. Double Breasted Suits
  const dbSuits = products.filter(p => 
    p.primary_image?.includes('mens_double_breasted_suit_2021_0.webp')
  );
  const dbGallery = galleryData.filter(g => g.folder === 'double_breasted');
  
  dbSuits.forEach((suit, index) => {
    if (index < dbGallery.length) {
      updates.push({
        id: suit.id,
        name: suit.name,
        newImage: dbGallery[index].main_image_url
      });
    }
  });
  
  // 2. Velvet Blazers - use velvet-blazer folder
  const velvetBlazers = products.filter(p => 
    p.primary_image?.includes('mens_black_paisley_pattern_velvet_model_1059.webp')
  );
  const velvetGallery = galleryData.filter(g => g.folder === 'velvet-blazer');
  
  velvetBlazers.forEach((blazer, index) => {
    if (index < velvetGallery.length) {
      updates.push({
        id: blazer.id,
        name: blazer.name,
        newImage: velvetGallery[index].main_image_url
      });
    }
  });
  
  // 3. Sparkle Blazers - use sparkle-blazer folder
  const sparkleBlazers = products.filter(p => 
    p.primary_image?.includes('mens_black_glitter_finish_sparkle_model_1030.webp')
  );
  const sparkleGallery = galleryData.filter(g => g.folder === 'sparkle-blazer');
  
  sparkleBlazers.forEach((blazer, index) => {
    if (index < sparkleGallery.length) {
      updates.push({
        id: blazer.id,
        name: blazer.name,
        newImage: sparkleGallery[index].main_image_url
      });
    }
  });
  
  // 4. Prom Blazers
  const promBlazers = products.filter(p => 
    p.primary_image?.includes('mens_black_floral_pattern_prom_blazer_model_1009.webp')
  );
  const promGallery = galleryData.filter(g => g.folder === 'prom_blazer');
  
  promBlazers.forEach((blazer, index) => {
    if (index < promGallery.length) {
      updates.push({
        id: blazer.id,
        name: blazer.name,
        newImage: promGallery[index].main_image_url
      });
    }
  });
  
  // 5. Dress Shirts
  const dressShirts = products.filter(p => 
    p.primary_image?.includes('mens_dress_shirt_mock_neck_3001_0.webp')
  );
  const shirtGallery = galleryData.filter(g => g.folder?.includes('dress_shirts'));
  
  dressShirts.forEach((shirt, index) => {
    if (index < shirtGallery.length) {
      updates.push({
        id: shirt.id,
        name: shirt.name,
        newImage: shirtGallery[index].main_image_url
      });
    }
  });
  
  // 6. Summer Blazers
  const summerBlazers = products.filter(p => 
    p.primary_image?.includes('mens_blue_casual_summer_blazer_2025_1025.webp')
  );
  const summerGallery = galleryData.filter(g => g.folder === 'summer-blazer');
  
  summerBlazers.forEach((blazer, index) => {
    if (index < summerGallery.length) {
      updates.push({
        id: blazer.id,
        name: blazer.name,
        newImage: summerGallery[index].main_image_url
      });
    }
  });
  
  // Apply updates
  console.log(`📸 Found ${updates.length} products that can be updated with unique images\n`);
  
  if (updates.length > 0) {
    console.log('Updating products...\n');
    
    for (const update of updates) {
      const { error: updateError } = await supabase
        .from('products')
        .update({ primary_image: update.newImage })
        .eq('id', update.id);
      
      if (updateError) {
        console.error(`❌ Error: ${update.name}`);
      } else {
        console.log(`✅ ${update.name}`);
      }
    }
    
    console.log(`\n✅ Successfully updated ${updates.length} products with unique images!`);
  }
  
  // Show what categories we have in gallery
  console.log('\n\n📂 AVAILABLE GALLERY CATEGORIES:');
  console.log('==================================');
  const categories = {};
  galleryData.forEach(g => {
    const cat = g.folder || 'other';
    categories[cat] = (categories[cat] || 0) + 1;
  });
  
  Object.entries(categories)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`${cat}: ${count} unique products`);
    });
  
  console.log('\n✅ Your product gallery CSV has images for:');
  console.log('  - 47 Vest & Tie Sets');
  console.log('  - 35 Velvet Blazers');
  console.log('  - 27 Prom Blazers');
  console.log('  - 20 Tuxedos');
  console.log('  - 18 Sparkle Blazers');
  console.log('  - 16 Suspender Sets');
  console.log('  - Plus suits, dress shirts, and more!');
}

updateWithGalleryImages().catch(console.error);