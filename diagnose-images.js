/**
 * Image Diagnosis Script
 * Run with: node diagnose-images.js
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnoseImages() {
  console.log('🔍 Diagnosing Image Issues...\n');

  try {
    // 1. Check storage bucket configuration
    console.log('1. Checking Storage Bucket...');
    const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
    
    if (bucketError) {
      console.error('❌ Bucket error:', bucketError);
    } else {
      const productImagesBucket = buckets.find(b => b.name === 'product-images');
      if (productImagesBucket) {
        console.log('✅ product-images bucket found:', productImagesBucket);
      } else {
        console.log('❌ product-images bucket not found. Available buckets:', buckets.map(b => b.name));
      }
    }

    // 2. Get sample product images data
    console.log('\n2. Checking Product Images Table...');
    const { data: imageData, error: imageError } = await supabase
      .from('product_images')
      .select('id, product_id, image_url, image_type, position')
      .limit(20);

    // Get count of all images
    const { count, error: countError } = await supabase
      .from('product_images')
      .select('id', { count: 'exact', head: true });
    
    if (!countError) {
      console.log(`📊 Total images in database: ${count}`);
    }

    if (imageError) {
      console.error('❌ Image data error:', imageError);
    } else {
      console.log('✅ Sample image data:');
      imageData.forEach((img, idx) => {
        console.log(`  ${idx + 1}. ${img.image_url} (type: ${img.image_type}, pos: ${img.position})`);
      });

      // 3. Analyze URL patterns
      console.log('\n3. Analyzing URL Patterns...');
      const urlPatterns = {};
      imageData.forEach(img => {
        const url = img.image_url;
        if (url.startsWith('https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/')) {
          urlPatterns['R2 Full URLs'] = (urlPatterns['R2 Full URLs'] || 0) + 1;
        } else if (url.startsWith('https://')) {
          urlPatterns['Other HTTPS URLs'] = (urlPatterns['Other HTTPS URLs'] || 0) + 1;
        } else if (url.startsWith('/')) {
          urlPatterns['Relative paths with slash'] = (urlPatterns['Relative paths with slash'] || 0) + 1;
        } else if (!url.includes('://')) {
          urlPatterns['Relative paths'] = (urlPatterns['Relative paths'] || 0) + 1;
        } else {
          urlPatterns['Other'] = (urlPatterns['Other'] || 0) + 1;
        }
      });
      
      console.log('URL Pattern Distribution:');
      Object.entries(urlPatterns).forEach(([pattern, count]) => {
        console.log(`  ${pattern}: ${count}`);
      });

      // 4. Test image URLs
      console.log('\n4. Testing Image URL Accessibility...');
      for (const img of imageData.slice(0, 5)) {
        await testImageUrl(img.image_url, img.id);
      }
    }

    // 5. List some files in the bucket
    console.log('\n5. Checking Storage Bucket Contents...');
    const { data: files, error: filesError } = await supabase.storage
      .from('product-images')
      .list('', { limit: 10 });

    if (filesError) {
      console.error('❌ Files error:', filesError);
    } else {
      console.log('✅ Sample files in bucket:');
      files.forEach((file, idx) => {
        console.log(`  ${idx + 1}. ${file.name} (${file.metadata?.size || 'unknown size'})`);
      });
    }

  } catch (error) {
    console.error('❌ General error:', error);
  }
}

async function testImageUrl(imageUrl, imageId) {
  try {
    // Generate different URL possibilities
    const urls = generateUrlVariations(imageUrl);
    
    console.log(`\n  Testing image ${imageId}:`);
    console.log(`    Original URL: ${imageUrl}`);
    
    for (const [label, url] of Object.entries(urls)) {
      try {
        const response = await fetch(url, { method: 'HEAD' });
        const status = response.status;
        const statusText = response.statusText;
        
        if (status === 200) {
          console.log(`    ✅ ${label}: ${status} ${statusText}`);
        } else {
          console.log(`    ❌ ${label}: ${status} ${statusText}`);
        }
      } catch (error) {
        console.log(`    ❌ ${label}: ${error.message}`);
      }
    }
  } catch (error) {
    console.log(`    ❌ Error testing URLs for ${imageId}: ${error.message}`);
  }
}

function generateUrlVariations(originalUrl) {
  const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  
  const variations = {
    'Original': originalUrl,
  };

  // If it's a relative path, try different constructions
  if (!originalUrl.startsWith('http')) {
    const cleanUrl = originalUrl.startsWith('/') ? originalUrl.substring(1) : originalUrl;
    variations['Constructed'] = `${SUPABASE_URL}${STORAGE_PATH}${cleanUrl}`;
    variations['Direct Path'] = `${SUPABASE_URL}${STORAGE_PATH}${originalUrl}`;
  }

  // Try without leading slash
  if (originalUrl.startsWith('/')) {
    const withoutSlash = originalUrl.substring(1);
    variations['Without Leading Slash'] = `${SUPABASE_URL}${STORAGE_PATH}${withoutSlash}`;
  }

  return variations;
}

// Run the diagnosis
diagnoseImages().then(() => {
  console.log('\n🔍 Diagnosis complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Diagnosis failed:', error);
  process.exit(1);
});