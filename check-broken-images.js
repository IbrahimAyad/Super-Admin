/**
 * Check for broken image URLs
 * This will analyze all image URLs in the database
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkAllImages() {
  console.log('🔍 Analyzing ALL image URLs...\n');

  try {
    // Get all image URLs
    const { data: imageData, error } = await supabase
      .from('product_images')
      .select('id, product_id, image_url, image_type, position');

    if (error) {
      console.error('❌ Error fetching images:', error);
      return;
    }

    console.log(`📊 Total images to analyze: ${imageData.length}`);

    // Categorize URLs
    const categories = {
      r2FullUrls: [],
      relativePaths: [],
      supabaseUrls: [],
      otherHttps: [],
      emptyOrNull: [],
      problematic: []
    };

    imageData.forEach(img => {
      const url = img.image_url;
      
      if (!url || url.trim() === '' || url === null) {
        categories.emptyOrNull.push(img);
      } else if (url.startsWith('https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/')) {
        categories.r2FullUrls.push(img);
      } else if (url.includes('supabase') || url.includes('gvcswimqaxvylgxbklbz')) {
        categories.supabaseUrls.push(img);
      } else if (url.startsWith('https://') || url.startsWith('http://')) {
        categories.otherHttps.push(img);
      } else if (url.startsWith('/') || !url.includes('://')) {
        categories.relativePaths.push(img);
      } else {
        categories.problematic.push(img);
      }
    });

    // Print categorization results
    console.log('\n📋 URL Categorization Results:');
    console.log(`  ✅ R2 Full URLs (working): ${categories.r2FullUrls.length}`);
    console.log(`  🔗 Supabase URLs: ${categories.supabaseUrls.length}`);
    console.log(`  🌐 Other HTTPS URLs: ${categories.otherHttps.length}`);
    console.log(`  📁 Relative paths: ${categories.relativePaths.length}`);
    console.log(`  ❌ Empty/Null: ${categories.emptyOrNull.length}`);
    console.log(`  ⚠️  Problematic: ${categories.problematic.length}`);

    // Show problematic URLs
    if (categories.relativePaths.length > 0) {
      console.log('\n📁 Relative Path URLs (need fixing):');
      categories.relativePaths.slice(0, 10).forEach((img, idx) => {
        console.log(`  ${idx + 1}. ${img.image_url} (ID: ${img.id})`);
      });
      if (categories.relativePaths.length > 10) {
        console.log(`  ... and ${categories.relativePaths.length - 10} more`);
      }
    }

    if (categories.supabaseUrls.length > 0) {
      console.log('\n🔗 Supabase URLs:');
      categories.supabaseUrls.slice(0, 10).forEach((img, idx) => {
        console.log(`  ${idx + 1}. ${img.image_url} (ID: ${img.id})`);
      });
    }

    if (categories.emptyOrNull.length > 0) {
      console.log('\n❌ Empty/Null URLs:');
      categories.emptyOrNull.slice(0, 10).forEach((img, idx) => {
        console.log(`  ${idx + 1}. ID: ${img.id}, Product: ${img.product_id}`);
      });
    }

    if (categories.problematic.length > 0) {
      console.log('\n⚠️  Problematic URLs:');
      categories.problematic.forEach((img, idx) => {
        console.log(`  ${idx + 1}. ${img.image_url} (ID: ${img.id})`);
      });
    }

    // Test some potentially broken URLs
    if (categories.relativePaths.length > 0) {
      console.log('\n🧪 Testing Relative Path URLs...');
      for (const img of categories.relativePaths.slice(0, 3)) {
        await testRelativeUrl(img.image_url, img.id);
      }
    }

    if (categories.supabaseUrls.length > 0) {
      console.log('\n🧪 Testing Supabase URLs...');
      for (const img of categories.supabaseUrls.slice(0, 3)) {
        await testUrl(img.image_url, img.id);
      }
    }

    return categories;

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function testUrl(url, imageId) {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    const status = response.status;
    console.log(`  ${status === 200 ? '✅' : '❌'} ${url} - ${status} ${response.statusText}`);
  } catch (error) {
    console.log(`  ❌ ${url} - ${error.message}`);
  }
}

async function testRelativeUrl(relativePath, imageId) {
  const baseUrls = [
    'https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/',
    'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/'
  ];

  console.log(`\n  Testing relative path: ${relativePath}`);
  
  for (const baseUrl of baseUrls) {
    const fullUrl = baseUrl + (relativePath.startsWith('/') ? relativePath.substring(1) : relativePath);
    await testUrl(fullUrl, imageId);
  }
}

// Run the analysis
checkAllImages().then((results) => {
  console.log('\n🎯 Analysis Summary:');
  if (results) {
    const totalProblematic = results.relativePaths.length + results.emptyOrNull.length + results.problematic.length;
    console.log(`  Total problematic URLs: ${totalProblematic}`);
    console.log(`  Working R2 URLs: ${results.r2FullUrls.length}`);
    
    if (totalProblematic === 0) {
      console.log('🎉 No problematic URLs found! All images should be working.');
    } else {
      console.log('⚡ Found issues that need fixing.');
    }
  }
  console.log('\n🔍 Analysis complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Analysis failed:', error);
  process.exit(1);
});