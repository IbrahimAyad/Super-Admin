/**
 * Test Image Loading in the KCT Admin System
 * This script will test the getProductImageUrl function and validate image accessibility
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

// Replicate the getProductImageUrl function locally for testing
function getProductImageUrl(product, variant) {
  const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  
  const processUrl = (url) => {
    if (!url || url.trim() === '') {
      return '/placeholder.svg';
    }

    // If it's already a full URL (starts with http/https), return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // For relative paths, try to construct a full URL
    const cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    
    if (!cleanUrl.includes('/')) {
      const rootUrl = `${SUPABASE_URL}${STORAGE_PATH}${cleanUrl}`;
      return rootUrl;
    }
    
    const fullUrl = `${SUPABASE_URL}${STORAGE_PATH}${cleanUrl}`;
    return fullUrl;
  };

  // Handle the proper ProductImage array structure
  if (product.images && Array.isArray(product.images)) {
    const sortedImages = product.images.sort((a, b) => (a.position || 0) - (b.position || 0));
    
    // Try to get primary image first
    const primaryImage = sortedImages.find((img) => img.image_type === 'primary');
    if (primaryImage) {
      if (primaryImage.image_url) {
        return processUrl(primaryImage.image_url);
      } else if (primaryImage.url) {
        return processUrl(primaryImage.url);
      } else if (primaryImage.r2_url) {
        return processUrl(primaryImage.r2_url);
      }
    }

    // Fall back to first available image with valid URL
    for (const img of sortedImages) {
      if (img.image_url) {
        return processUrl(img.image_url);
      } else if (img.url) {
        return processUrl(img.url);
      } else if (img.r2_url) {
        return processUrl(img.r2_url);
      }
    }
  }

  return '/placeholder.svg';
}

async function testImageLoading() {
  console.log('🧪 Testing Image Loading in KCT Admin System...\n');

  try {
    // Get products with images using the same query as the frontend
    const { data: products, error } = await supabase
      .from('products')
      .select(`
        *,
        images:product_images(*),
        variants:product_variants(*)
      `)
      .order('created_at', { ascending: false })
      .limit(5);

    if (error) {
      console.error('❌ Error fetching products:', error);
      return;
    }

    console.log(`📊 Testing ${products.length} products with images...\n`);

    for (const product of products) {
      console.log(`\n🔍 Testing Product: ${product.name}`);
      console.log(`   Product ID: ${product.id}`);
      console.log(`   Images count: ${product.images?.length || 0}`);
      
      if (product.images && product.images.length > 0) {
        // Show raw image data
        console.log('   Raw image data:');
        product.images.forEach((img, idx) => {
          console.log(`     ${idx + 1}. URL: ${img.image_url}`);
          console.log(`        Type: ${img.image_type}, Position: ${img.position}`);
        });

        // Test getProductImageUrl function
        const generatedUrl = getProductImageUrl(product);
        console.log(`   Generated URL: ${generatedUrl}`);

        // Test if the generated URL is accessible
        await testUrlAccessibility(generatedUrl, product.id);

        // Test first few raw URLs directly
        for (const img of product.images.slice(0, 2)) {
          console.log(`   Testing raw URL: ${img.image_url}`);
          await testUrlAccessibility(img.image_url, img.id);
        }
      } else {
        console.log('   ❌ No images found for this product');
      }
      
      console.log('   ' + '─'.repeat(60));
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

async function testUrlAccessibility(url, itemId) {
  if (!url || url === '/placeholder.svg') {
    console.log(`   ⚠️  Placeholder URL: ${url}`);
    return;
  }

  try {
    const response = await fetch(url, { method: 'HEAD' });
    const status = response.status;
    
    if (status === 200) {
      console.log(`   ✅ Accessible (${status}): ${url.substring(0, 80)}...`);
    } else if (status === 403) {
      console.log(`   ❌ Forbidden (${status}): ${url.substring(0, 80)}...`);
    } else if (status === 404) {
      console.log(`   ❌ Not Found (${status}): ${url.substring(0, 80)}...`);
    } else {
      console.log(`   ⚠️  Status ${status}: ${url.substring(0, 80)}...`);
    }
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}`);
  }
}

// Run the test
testImageLoading().then(() => {
  console.log('\n🎯 Image Loading Test Complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});