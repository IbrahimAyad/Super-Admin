import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// Correct R2 bucket URL
const R2_BUCKET_URL = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev';

async function fixProductImages() {
  console.log('=== FIXING PRODUCT IMAGES ===\n');
  
  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching products:', error);
    return;
  }
  
  console.log(`Found ${products.length} products to check\n`);
  
  let fixedCount = 0;
  let brokenCount = 0;
  let duplicateCount = 0;
  
  // Track unique images to detect duplicates
  const imageUsage = {};
  
  for (const product of products) {
    let needsUpdate = false;
    let updates = {};
    
    // Check primary_image
    if (product.primary_image) {
      const currentImage = product.primary_image;
      
      // Track image usage
      if (!imageUsage[currentImage]) {
        imageUsage[currentImage] = [];
      }
      imageUsage[currentImage].push(product.name);
      
      // Fix image URL if it's not using the R2 bucket
      if (!currentImage.startsWith('http') && !currentImage.includes('r2.dev')) {
        // This is just a filename, need to prepend the R2 URL
        // Try to determine the correct folder based on category
        let folder = 'products'; // default
        
        if (product.category) {
          const cat = product.category.toLowerCase();
          if (cat.includes('suit')) folder = 'suits';
          else if (cat.includes('tuxedo')) folder = 'tuxedos';
          else if (cat.includes('blazer')) folder = 'blazers';
          else if (cat.includes('vest')) folder = 'vests';
          else if (cat.includes('shirt')) folder = 'shirts';
          else if (cat.includes('shoe') || cat.includes('boot')) folder = 'shoes';
          else if (cat.includes('suspender')) folder = 'accessories';
          else if (cat.includes('tie')) folder = 'accessories';
          else if (cat.includes('kid')) folder = 'kids';
        }
        
        updates.primary_image = `${R2_BUCKET_URL}/${folder}/${currentImage}`;
        needsUpdate = true;
        console.log(`🔧 Fixing image URL for ${product.name}`);
        console.log(`   From: ${currentImage}`);
        console.log(`   To: ${updates.primary_image}`);
      }
      
      // Check if it's a placeholder
      if (currentImage.includes('placehold') || currentImage.includes('placeholder')) {
        console.log(`⚠️ ${product.name} has placeholder image`);
        brokenCount++;
      }
    } else {
      console.log(`❌ ${product.name} has no image`);
      brokenCount++;
    }
    
    // Fix gallery images if present
    if (product.gallery_images && Array.isArray(product.gallery_images)) {
      const fixedGallery = product.gallery_images.map(img => {
        if (!img.startsWith('http') && !img.includes('r2.dev')) {
          return `${R2_BUCKET_URL}/products/${img}`;
        }
        return img;
      });
      
      if (JSON.stringify(fixedGallery) !== JSON.stringify(product.gallery_images)) {
        updates.gallery_images = fixedGallery;
        needsUpdate = true;
      }
    }
    
    // Update if needed
    if (needsUpdate) {
      const { error: updateError } = await supabase
        .from('products')
        .update(updates)
        .eq('id', product.id);
      
      if (updateError) {
        console.error(`Error updating ${product.name}:`, updateError);
      } else {
        fixedCount++;
      }
    }
  }
  
  // Report duplicates
  console.log('\n=== DUPLICATE IMAGE ANALYSIS ===\n');
  Object.entries(imageUsage)
    .filter(([img, products]) => products.length > 1)
    .forEach(([img, products]) => {
      console.log(`\n📸 Image: ${img.split('/').pop()}`);
      console.log(`   Used by ${products.length} products:`);
      products.slice(0, 5).forEach(p => console.log(`   - ${p}`));
      if (products.length > 5) console.log(`   ... and ${products.length - 5} more`);
      duplicateCount += products.length - 1;
    });
  
  // Also check product_images table
  console.log('\n=== CHECKING PRODUCT_IMAGES TABLE ===\n');
  const { data: productImages, error: imgError } = await supabase
    .from('product_images')
    .select('*');
  
  if (!imgError && productImages) {
    let imgFixCount = 0;
    for (const img of productImages) {
      if (img.image_url && !img.image_url.startsWith('http')) {
        const { error: updateError } = await supabase
          .from('product_images')
          .update({ 
            image_url: `${R2_BUCKET_URL}/products/${img.image_url}` 
          })
          .eq('id', img.id);
        
        if (!updateError) imgFixCount++;
      }
    }
    console.log(`Fixed ${imgFixCount} product_images entries`);
  }
  
  console.log('\n=== SUMMARY ===\n');
  console.log(`✅ Fixed URLs: ${fixedCount} products`);
  console.log(`⚠️ Missing/broken images: ${brokenCount} products`);
  console.log(`🔄 Duplicate images: ${duplicateCount} instances`);
  
  console.log('\n=== NEXT STEPS ===\n');
  console.log('1. Update R2 CORS settings to allow new Vercel URL');
  console.log('2. Upload missing product images to R2 bucket');
  console.log('3. Consider using unique images for each product');
}

fixProductImages().catch(console.error);