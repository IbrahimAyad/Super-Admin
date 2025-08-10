#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get these from your .env file
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseKey) {
  console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY or VITE_SUPABASE_ANON_KEY in .env file');
  process.exit(1);
}

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
    aliases: ['hunter green', 'dark green', 'forest green', 'green'],
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
    aliases: ['powder blue', 'light blue', 'baby blue', 'blue'],
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

async function updateSuspenderImages() {
  console.log('🎨 Starting automatic image matching for suspender & bowtie sets...');
  console.log(`📍 Using Supabase URL: ${supabaseUrl}\n`);
  
  try {
    // Fetch all suspender & bowtie products with their images
    const { data: products, error } = await supabase
      .from('products')
      .select(`
        id, 
        name, 
        description, 
        base_price, 
        category,
        product_images (
          id,
          image_url,
          position
        )
      `)
      .or('name.ilike.%suspender%,name.ilike.%bowtie%,category.ilike.%accessories%')
      .order('name');

    if (error) {
      console.error('Error fetching products:', error);
      throw error;
    }

    console.log(`Found ${products?.length || 0} potential suspender/bowtie products\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    const results = [];

    for (const product of products || []) {
      console.log(`\n📦 Processing: ${product.name}`);
      
      // Try to match color from product name or description
      let matched = false;
      
      for (const mapping of imageMapping) {
        // Check main color and aliases
        const colorsToCheck = [mapping.color, ...(mapping.aliases || [])];
        
        for (const color of colorsToCheck) {
          // Create flexible pattern to match colors with spaces, hyphens, etc.
          const colorPattern = color.replace(/[-\s]/g, '[-\\s]?');
          const regex = new RegExp(`\\b${colorPattern}\\b`, 'i');
          
          const nameMatch = regex.test(product.name);
          const descMatch = regex.test(product.description || '');
          
          if (nameMatch || descMatch) {
            console.log(`  ✅ Matched color: ${color} (${nameMatch ? 'in name' : 'in description'})`);
            console.log(`  📸 Adding ${mapping.images.length} image(s)`);
            
            // First, delete existing images for this product
            await supabase
              .from('product_images')
              .delete()
              .eq('product_id', product.id);
            
            // Then insert new images
            const imageRecords = mapping.images.map((url, index) => ({
              product_id: product.id,
              image_url: url,
              image_type: index === 0 ? 'primary' : 'gallery',
              position: index,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString()
            }));
            
            const { data, error: updateError } = await supabase
              .from('product_images')
              .insert(imageRecords)
              .select();
            
            if (updateError) {
              console.log(`  ❌ Error updating: ${updateError.message}`);
              results.push({ product: product.name, status: 'error', error: updateError.message });
            } else {
              console.log(`  ✅ Successfully updated with:`);
              mapping.images.forEach((img, idx) => {
                const type = idx === 0 ? 'Main' : 'Additional';
                console.log(`     ${type}: ${img.split('/').pop()}`);
              });
              updatedCount++;
              results.push({ 
                product: product.name, 
                status: 'success', 
                images: mapping.images.length,
                color: color 
              });
            }
            
            matched = true;
            break;
          }
        }
        
        if (matched) break;
      }
      
      if (!matched) {
        console.log(`  ⏭️  Skipped - no color match found`);
        console.log(`     Tried to match in: "${product.name}"`);
        skippedCount++;
        results.push({ product: product.name, status: 'skipped', reason: 'no color match' });
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('✨ IMAGE MATCHING COMPLETE!');
    console.log('='.repeat(60));
    console.log(`✅ Successfully updated: ${updatedCount} products`);
    console.log(`⏭️  Skipped: ${skippedCount} products`);
    console.log('='.repeat(60));
    
    // Show summary of results
    console.log('\n📊 DETAILED RESULTS:');
    console.log('-'.repeat(60));
    
    results.forEach(r => {
      if (r.status === 'success') {
        console.log(`✅ ${r.product} - ${r.images} images added (${r.color})`);
      } else if (r.status === 'skipped') {
        console.log(`⏭️  ${r.product} - ${r.reason}`);
      } else {
        console.log(`❌ ${r.product} - ${r.error}`);
      }
    });

    return { updatedCount, skippedCount, results };

  } catch (error) {
    console.error('❌ Fatal error:', error);
    throw error;
  }
}

// Run the script
updateSuspenderImages()
  .then(result => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });