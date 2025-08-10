import { supabase } from '../src/lib/supabase';

// Base URL for Cloudflare R2 images
const R2_BASE_URL = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set';

// Image mapping based on the file list you showed
const imageMapping = [
  {
    color: 'black',
    images: [
      `${R2_BASE_URL}/black-model.png`, // Main image
    ]
  },
  {
    color: 'brown',
    images: [
      `${R2_BASE_URL}/brown-model-sus-bowtie.png`, // Main image
      `${R2_BASE_URL}/brown-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'burnt-orange',
    images: [
      `${R2_BASE_URL}/burnt-orange-model.png`, // Main image
      `${R2_BASE_URL}/burnt-orange.jpg`, // Secondary
    ]
  },
  {
    color: 'dusty-rose',
    images: [
      `${R2_BASE_URL}/dusty-rose-model.png`, // Main image
      `${R2_BASE_URL}/dusty-rose-sus-.jpg`, // Secondary
    ]
  },
  {
    color: 'fuchsia',
    images: [
      `${R2_BASE_URL}/fuchsia-model-sus-bowtie.png`, // Main image
      `${R2_BASE_URL}/fuchsia-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'gold',
    images: [
      `${R2_BASE_URL}/gold-sus-bowtie-model.png`, // Main image
      `${R2_BASE_URL}/gold-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'hunter-green',
    images: [
      `${R2_BASE_URL}/hunter-green-model.png`, // Main image
      `${R2_BASE_URL}/hunter-green-sus-bow-tie.jpg`, // Secondary
    ]
  },
  {
    color: 'medium-red',
    images: [
      `${R2_BASE_URL}/medium-red-sus-bowtie-model.png`, // Main image
      `${R2_BASE_URL}/medium-red-sus-bowtie-model-2.png`, // Alternative model shot
      `${R2_BASE_URL}/medium-red-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'orange',
    images: [
      `${R2_BASE_URL}/orange-model.png`, // Main image
      `${R2_BASE_URL}/orange-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'powder-blue',
    images: [
      `${R2_BASE_URL}/powder-blue-model.png`, // Main image
      `${R2_BASE_URL}/powder-blue-model-2.png`, // Alternative model shot
      `${R2_BASE_URL}/powder-blue-sus-bowtie.jpg`, // Secondary
    ]
  },
  {
    color: 'burgundy',
    images: [
      `${R2_BASE_URL}/burgundy-model.png`, // Main image (assuming this exists)
    ]
  },
  {
    color: 'navy',
    aliases: ['navy-blue'],
    images: [
      `${R2_BASE_URL}/navy-blue-model.png`, // Main image (assuming this exists)
    ]
  },
  {
    color: 'gray',
    aliases: ['grey'],
    images: [
      `${R2_BASE_URL}/gray-model.png`, // Main image (assuming this exists)
    ]
  }
];

async function updateSuspenderImages() {
  console.log('🎨 Starting automatic image matching for suspender & bowtie sets...\n');
  
  try {
    // 1. Fetch all suspender & bowtie products
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, description, image_url')
      .or('name.ilike.%suspender%,name.ilike.%bowtie%,category.ilike.%accessories%')
      .order('name');

    if (error) throw error;

    console.log(`Found ${products?.length || 0} potential suspender/bowtie products\n`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const product of products || []) {
      console.log(`\nProcessing: ${product.name}`);
      
      // Try to match color from product name
      let matched = false;
      
      for (const mapping of imageMapping) {
        // Check main color and aliases
        const colorsToCheck = [mapping.color, ...(mapping.aliases || [])];
        
        for (const color of colorsToCheck) {
          const colorPattern = color.replace('-', '[\\s-]?'); // Match with or without spaces/hyphens
          const regex = new RegExp(colorPattern, 'i');
          
          if (regex.test(product.name) || regex.test(product.description || '')) {
            console.log(`  ✅ Matched color: ${color}`);
            
            // Update the product with the main image
            const mainImage = mapping.images[0];
            
            // First, update the main product image
            const { error: updateError } = await supabase
              .from('products')
              .update({ 
                image_url: mainImage,
                updated_at: new Date().toISOString()
              })
              .eq('id', product.id);

            if (updateError) {
              console.log(`  ❌ Error updating product: ${updateError.message}`);
            } else {
              console.log(`  ✅ Updated main image: ${mainImage}`);
              
              // Now add all images to product_images table
              const imageRecords = mapping.images.map((url, index) => ({
                product_id: product.id,
                image_url: url,
                position: index,
                is_primary: index === 0,
                created_at: new Date().toISOString()
              }));
              
              // Delete existing images for this product first
              await supabase
                .from('product_images')
                .delete()
                .eq('product_id', product.id);
              
              // Insert new images
              const { error: imageError } = await supabase
                .from('product_images')
                .insert(imageRecords);
              
              if (imageError) {
                console.log(`  ⚠️  Could not add to product_images table: ${imageError.message}`);
              } else {
                console.log(`  ✅ Added ${mapping.images.length} images to product_images table`);
              }
              
              updatedCount++;
            }
            
            matched = true;
            break;
          }
        }
        
        if (matched) break;
      }
      
      if (!matched) {
        console.log(`  ⏭️  Skipped - no color match found`);
        skippedCount++;
      }
    }

    console.log('\n' + '='.repeat(50));
    console.log(`✨ Image matching complete!`);
    console.log(`   Updated: ${updatedCount} products`);
    console.log(`   Skipped: ${skippedCount} products`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the script
updateSuspenderImages();