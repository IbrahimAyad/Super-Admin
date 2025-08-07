/**
 * Test CORS Headers and Browser-like Requests
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testCorsAndHeaders() {
  console.log('🌐 Testing CORS Headers and Browser-like Requests...\n');

  try {
    // Get a sample image URL
    const { data: products, error } = await supabase
      .from('products')
      .select('*, images:product_images(*)')
      .limit(1);

    if (error || !products?.length) {
      console.error('❌ Failed to get test product');
      return;
    }

    const product = products[0];
    if (!product.images?.length) {
      console.log('❌ No images to test');
      return;
    }

    const testUrl = product.images[0].image_url;
    console.log(`🔗 Testing URL: ${testUrl}\n`);

    // Test with different request types
    await testWithDifferentMethods(testUrl);

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function testWithDifferentMethods(url) {
  const methods = ['HEAD', 'GET'];
  const headers = [
    { name: 'Basic', headers: {} },
    { 
      name: 'Browser-like', 
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
      }
    },
    {
      name: 'With Origin',
      headers: {
        'Origin': 'http://localhost:8080',
        'Referer': 'http://localhost:8080/'
      }
    }
  ];

  for (const method of methods) {
    console.log(`\n📋 Testing ${method} requests:`);
    
    for (const headerSet of headers) {
      try {
        const response = await fetch(url, {
          method,
          headers: headerSet.headers
        });

        console.log(`  ${headerSet.name}: ${response.status} ${response.statusText}`);
        
        // Check CORS headers
        const corsHeaders = {
          'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
          'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
          'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
          'Access-Control-Expose-Headers': response.headers.get('Access-Control-Expose-Headers'),
          'Vary': response.headers.get('Vary'),
          'Cache-Control': response.headers.get('Cache-Control'),
          'Content-Type': response.headers.get('Content-Type')
        };

        // Only show relevant headers
        const relevantHeaders = Object.entries(corsHeaders)
          .filter(([key, value]) => value !== null)
          .reduce((acc, [key, value]) => ({ ...acc, [key]: value }), {});

        if (Object.keys(relevantHeaders).length > 0) {
          console.log(`    Headers:`, relevantHeaders);
        }

        // For GET requests, check content length
        if (method === 'GET' && response.ok) {
          const contentLength = response.headers.get('content-length');
          if (contentLength) {
            console.log(`    Content-Length: ${contentLength} bytes`);
          }
        }

      } catch (error) {
        console.log(`  ${headerSet.name}: ❌ ${error.message}`);
      }
    }
  }

  // Test with specific problematic scenarios
  console.log('\n🚨 Testing Problematic Scenarios:');
  
  // Test with CORS preflight
  try {
    const preflightResponse = await fetch(url, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'http://localhost:8080',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'content-type'
      }
    });
    console.log(`  CORS Preflight: ${preflightResponse.status} ${preflightResponse.statusText}`);
  } catch (error) {
    console.log(`  CORS Preflight: ❌ ${error.message}`);
  }

  // Test with expired/invalid cache headers
  try {
    const cacheResponse = await fetch(url, {
      method: 'GET',
      headers: {
        'If-Modified-Since': new Date(Date.now() - 24 * 60 * 60 * 1000).toUTCString(),
        'Cache-Control': 'max-age=0'
      }
    });
    console.log(`  Cache Test: ${cacheResponse.status} ${cacheResponse.statusText}`);
  } catch (error) {
    console.log(`  Cache Test: ❌ ${error.message}`);
  }
}

// Run the test
testCorsAndHeaders().then(() => {
  console.log('\n🎯 CORS and Headers Test Complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});