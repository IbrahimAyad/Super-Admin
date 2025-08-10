// Auto-match Cloudflare R2 images to suspender & bowtie products
// Run this in the Supabase SQL Editor or as a Node script

const updateSuspenderImages = async () => {
  // Import Supabase client
  const { createClient } = require('@supabase/supabase-js');
  
  // Get these from your .env file
  const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  const supabase = createClient(supabaseUrl, supabaseKey);
  
  // Base URL for Cloudflare R2 images
  const R2_BASE_URL = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set';

  // Complete image mapping based on your file list
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
      aliases: ['burnt orange'],
      images: [
        `${R2_BASE_URL}/burnt-orange-model.png`, // Main image
        `${R2_BASE_URL}/burnt-orange.jpg`, // Secondary
      ]
    },
    {
      color: 'dusty-rose',
      aliases: ['dusty rose', 'rose'],
      images: [
        `${R2_BASE_URL}/dusty-rose-model.png`, // Main image
        `${R2_BASE_URL}/dusty-rose-sus-.jpg`, // Secondary
      ]
    },
    {
      color: 'fuchsia',
      aliases: ['pink', 'hot pink'],
      images: [
        `${R2_BASE_URL}/fuchsia-model-sus-bowtie.png`, // Main image
        `${R2_BASE_URL}/fuchsia-sus-bowtie.jpg`, // Secondary
      ]
    },
    {
      color: 'gold',
      aliases: ['golden'],
      images: [
        `${R2_BASE_URL}/gold-sus-bowtie-model.png`, // Main image
        `${R2_BASE_URL}/gold-sus-bowtie.jpg`, // Secondary
      ]
    },
    {
      color: 'hunter-green',
      aliases: ['hunter green', 'dark green', 'forest green'],
      images: [
        `${R2_BASE_URL}/hunter-green-model.png`, // Main image
        `${R2_BASE_URL}/hunter-green-sus-bow-tie.jpg`, // Secondary
      ]
    },
    {
      color: 'medium-red',
      aliases: ['red', 'medium red'],
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
      aliases: ['powder blue', 'light blue', 'baby blue'],
      images: [
        `${R2_BASE_URL}/powder-blue-model.png`, // Main image
        `${R2_BASE_URL}/powder-blue-model-2.png`, // Alternative model shot
        `${R2_BASE_URL}/powder-blue-sus-bowtie.jpg`, // Secondary
      ]
    },
    {
      color: 'burgundy',
      aliases: ['wine', 'maroon'],
      images: [
        `${R2_BASE_URL}/burgundy-model.png`, // Assuming this exists
      ]
    },
    {
      color: 'navy',
      aliases: ['navy-blue', 'navy blue', 'dark blue'],
      images: [
        `${R2_BASE_URL}/navy-blue-model.png`, // Assuming this exists
      ]
    },
    {
      color: 'gray',
      aliases: ['grey', 'silver'],
      images: [
        `${R2_BASE_URL}/gray-model.png`, // Assuming this exists
      ]
    }
  ];

  console.log('🎨 Starting automatic image matching for suspender & bowtie sets...\n');
  
  try {
    // Fetch all suspender & bowtie products
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, description, image_url, price')
      .or('name.ilike.%suspender%,name.ilike.%bowtie%,category.ilike.%accessories%')
      .order('name');

    if (error) throw error;

    console.log(`Found ${products?.length || 0} potential suspender/bowtie products\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    const updatePromises = [];

    for (const product of products || []) {
      console.log(`\nProcessing: ${product.name}`);
      
      // Try to match color from product name
      let matched = false;
      
      for (const mapping of imageMapping) {
        // Check main color and aliases
        const colorsToCheck = [mapping.color, ...(mapping.aliases || [])];
        
        for (const color of colorsToCheck) {
          // Create flexible pattern to match colors with spaces, hyphens, etc.
          const colorPattern = color.replace(/[-\s]/g, '[-\\s]?');
          const regex = new RegExp(`\\b${colorPattern}\\b`, 'i');
          
          if (regex.test(product.name) || regex.test(product.description || '')) {
            console.log(`  ✅ Matched color: ${color}`);
            console.log(`  📸 Images to add: ${mapping.images.length}`);
            
            // Update the product with images
            const mainImage = mapping.images[0];
            
            updatePromises.push(
              supabase
                .from('products')
                .update({ 
                  image_url: mainImage,
                  additional_images: mapping.images.slice(1), // All other images
                  updated_at: new Date().toISOString()
                })
                .eq('id', product.id)
                .then(result => {
                  if (result.error) {
                    console.log(`  ❌ Error updating ${product.name}: ${result.error.message}`);
                  } else {
                    console.log(`  ✅ Updated ${product.name} with ${mapping.images.length} images`);
                    updatedCount++;
                  }
                })
            );
            
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

    // Wait for all updates to complete
    await Promise.all(updatePromises);

    console.log('\n' + '='.repeat(50));
    console.log(`✨ Image matching complete!`);
    console.log(`   Updated: ${updatedCount} products`);
    console.log(`   Skipped: ${skippedCount} products`);
    console.log('='.repeat(50));

    return { updatedCount, skippedCount };

  } catch (error) {
    console.error('❌ Error:', error);
    throw error;
  }
};

// Export for use as module or run directly
if (typeof module !== 'undefined' && module.exports) {
  module.exports = updateSuspenderImages;
}

// Run if called directly
if (require.main === module) {
  require('dotenv').config();
  updateSuspenderImages()
    .then(result => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}