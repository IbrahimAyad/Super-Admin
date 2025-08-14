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

// Function to extract color from product name
function extractColor(name) {
  const colors = [
    'black', 'white', 'red', 'blue', 'green', 'gold', 'silver', 'burgundy', 'wine',
    'navy', 'pink', 'purple', 'brown', 'grey', 'gray', 'charcoal', 'royal blue',
    'coral', 'blush', 'fuchsia', 'canary', 'emerald', 'forest', 'mint', 'teal',
    'orange', 'yellow', 'tan', 'beige', 'cream', 'ivory', 'dusty rose', 'dusty sage',
    'burnt orange', 'medium red', 'light blue', 'powder blue', 'carolina blue',
    'french blue', 'chocolate', 'cinnamon', 'lavender', 'mauve', 'salmon', 'rust',
    'aqua', 'turquoise', 'rose gold', 'sparkle', 'glitter', 'kiwi', 'lettuce', 'lime',
    'mermaid', 'baby blue'
  ];
  
  const nameLower = name.toLowerCase();
  for (const color of colors) {
    if (nameLower.includes(color)) {
      return color;
    }
  }
  return null;
}

// Function to match product type
function getProductType(name) {
  const nameLower = name.toLowerCase();
  
  if (nameLower.includes('vest') && (nameLower.includes('tie') || nameLower.includes('bowtie'))) {
    return 'vest-tie';
  }
  if (nameLower.includes('suspender')) {
    return 'suspender';
  }
  if (nameLower.includes('travel suit') || nameLower.includes('stretch')) {
    return 'stretch-suit';
  }
  if (nameLower.includes('tuxedo')) {
    return 'tuxedo';
  }
  if (nameLower.includes('suit')) {
    return 'suit';
  }
  if (nameLower.includes('sparkle') && nameLower.includes('vest')) {
    return 'sparkle-vest';
  }
  return null;
}

async function smartMatchImages() {
  console.log('=== SMART MATCHING REMAINING PRODUCTS ===\n');
  
  // Load gallery CSV
  const galleryData = parseCSV('product_gallery-Super-Admin.csv');
  
  // Get products that still have duplicate or missing images
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, sku, primary_image, category')
    .order('name');
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  // Known duplicate images still in use
  const duplicateImages = [
    'black-model.png',
    'gold-model.png', 
    'wine-model.png',
    'coral-model.png',
    'blush-model.png',
    'fuchsia-model.png',
    'canary-model.png',
    'burnt-orange-model.png',
    'dusty-rose-model.png',
    'necktie_black-with-red-design_1.0.jpg',
    'vest_black-vest-and-tie-set_1.0.jpg',
    'blazer_black-and-red-floral-with-matching-bowtie_1.0.jpg',
    'suit_black-3-piece-suit_1.0.jpg'
  ];
  
  // Find products still needing fixes
  const needsImage = products.filter(p => 
    !p.primary_image || 
    p.primary_image.includes('placeholder') ||
    duplicateImages.some(dup => p.primary_image?.includes(dup))
  );
  
  console.log(`Found ${needsImage.length} products still needing unique images\n`);
  
  // Group gallery images by type
  const vestTieGallery = galleryData.filter(g => g.folder === 'main-solid-vest-tie');
  const suspenderGallery = galleryData.filter(g => g.folder === 'main-suspender-bowtie-set');
  const sparkleVestGallery = galleryData.filter(g => g.folder === 'main-sparkle-vest');
  const stretchSuitGallery = galleryData.filter(g => g.folder === 'stretch_suits');
  const tuxedoGallery = galleryData.filter(g => g.folder === 'tuxedos');
  const suitGallery = galleryData.filter(g => g.folder === 'suits');
  
  console.log('📂 Available Gallery Images:');
  console.log(`  Vest & Tie: ${vestTieGallery.length} images`);
  console.log(`  Suspenders: ${suspenderGallery.length} images`);
  console.log(`  Sparkle Vests: ${sparkleVestGallery.length} images`);
  console.log(`  Stretch Suits: ${stretchSuitGallery.length} images`);
  console.log(`  Tuxedos: ${tuxedoGallery.length} images`);
  console.log(`  Suits: ${suitGallery.length} images\n`);
  
  const updates = [];
  const usedImages = new Set();
  
  // Smart matching based on product name and type
  needsImage.forEach(product => {
    const color = extractColor(product.name);
    const type = getProductType(product.name);
    let matchedImage = null;
    let gallerySource = null;
    
    // Try to match based on type and color
    if (type === 'vest-tie' && vestTieGallery.length > 0) {
      // Try to find matching color
      for (const img of vestTieGallery) {
        if (color && img.product_stem.includes(color.replace(' ', '_')) && !usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'vest-tie (color match)';
          usedImages.add(img.main_image_url);
          break;
        }
      }
      // If no color match, use any unused
      if (!matchedImage) {
        for (const img of vestTieGallery) {
          if (!usedImages.has(img.main_image_url)) {
            matchedImage = img.main_image_url;
            gallerySource = 'vest-tie (generic)';
            usedImages.add(img.main_image_url);
            break;
          }
        }
      }
    } else if (type === 'suspender' && suspenderGallery.length > 0) {
      for (const img of suspenderGallery) {
        if (color && img.product_stem.includes(color.replace(' ', '_')) && !usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'suspender (color match)';
          usedImages.add(img.main_image_url);
          break;
        }
      }
      if (!matchedImage) {
        for (const img of suspenderGallery) {
          if (!usedImages.has(img.main_image_url)) {
            matchedImage = img.main_image_url;
            gallerySource = 'suspender (generic)';
            usedImages.add(img.main_image_url);
            break;
          }
        }
      }
    } else if (type === 'sparkle-vest' && sparkleVestGallery.length > 0) {
      for (const img of sparkleVestGallery) {
        if (color && img.product_stem.includes(color.replace(' ', '_')) && !usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'sparkle-vest (color match)';
          usedImages.add(img.main_image_url);
          break;
        }
      }
      if (!matchedImage) {
        for (const img of sparkleVestGallery) {
          if (!usedImages.has(img.main_image_url)) {
            matchedImage = img.main_image_url;
            gallerySource = 'sparkle-vest (generic)';
            usedImages.add(img.main_image_url);
            break;
          }
        }
      }
    } else if (type === 'stretch-suit' && stretchSuitGallery.length > 0) {
      for (const img of stretchSuitGallery) {
        if (!usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'stretch-suit';
          usedImages.add(img.main_image_url);
          break;
        }
      }
    } else if (type === 'tuxedo' && tuxedoGallery.length > 0) {
      for (const img of tuxedoGallery) {
        if (color && img.product_stem.includes(color.replace(' ', '_')) && !usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'tuxedo (color match)';
          usedImages.add(img.main_image_url);
          break;
        }
      }
      if (!matchedImage) {
        for (const img of tuxedoGallery) {
          if (!usedImages.has(img.main_image_url)) {
            matchedImage = img.main_image_url;
            gallerySource = 'tuxedo (generic)';
            usedImages.add(img.main_image_url);
            break;
          }
        }
      }
    } else if (type === 'suit' && suitGallery.length > 0) {
      for (const img of suitGallery) {
        if (!usedImages.has(img.main_image_url)) {
          matchedImage = img.main_image_url;
          gallerySource = 'suit';
          usedImages.add(img.main_image_url);
          break;
        }
      }
    }
    
    if (matchedImage) {
      updates.push({
        id: product.id,
        name: product.name,
        color: color,
        type: type,
        newImage: matchedImage,
        source: gallerySource
      });
    }
  });
  
  console.log(`\n📸 Smart Matched ${updates.length} products\n`);
  
  // Show what we're updating
  console.log('🔄 MATCHED PRODUCTS:\n');
  updates.slice(0, 20).forEach(u => {
    console.log(`${u.name}`);
    console.log(`  Color: ${u.color || 'unknown'} | Type: ${u.type} | Source: ${u.source}`);
  });
  
  if (updates.length > 20) {
    console.log(`\n... and ${updates.length - 20} more`);
  }
  
  // Apply updates
  if (updates.length > 0) {
    console.log('\n\n💾 APPLYING UPDATES...\n');
    
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
    
    console.log(`\n✅ Successfully updated ${updates.length} more products with unique images!`);
  }
  
  // Final check
  const { data: finalCheck } = await supabase
    .from('products')
    .select('primary_image');
  
  const stillDuplicates = finalCheck.filter(p => 
    p.primary_image && duplicateImages.some(dup => p.primary_image.includes(dup))
  );
  
  console.log('\n\n📊 FINAL STATUS:');
  console.log('================');
  console.log(`Total products: ${finalCheck.length}`);
  console.log(`Still have duplicates: ${stillDuplicates.length}`);
  console.log(`Products with unique images: ${finalCheck.length - stillDuplicates.length}`);
}

smartMatchImages().catch(console.error);