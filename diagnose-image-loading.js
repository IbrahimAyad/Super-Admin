import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function diagnoseImages() {
  console.log('=== DIAGNOSING IMAGE LOADING ISSUES ===\n');
  
  // Get a sample of recently updated products
  const { data: products, error } = await supabase
    .from('products')
    .select('name, primary_image')
    .limit(10)
    .order('updated_at', { ascending: false });
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  console.log('📸 SAMPLE PRODUCT IMAGES:\n');
  products.forEach(p => {
    console.log(`${p.name}:`);
    console.log(`  ${p.primary_image}\n`);
  });
  
  // Check for common issues
  console.log('🔍 CHECKING FOR COMMON ISSUES:\n');
  
  // Test a direct image URL
  const testUrl = products[0]?.primary_image;
  if (testUrl) {
    console.log('Test Image URL:');
    console.log(testUrl);
    console.log('\n✅ To test this image:');
    console.log('1. Copy the URL above');
    console.log('2. Paste in a new browser tab');
    console.log('3. If it loads there but not on site, it\'s a CORS issue');
    console.log('4. If it doesn\'t load anywhere, the image doesn\'t exist in R2');
  }
  
  // Check URL patterns
  const { data: allProducts } = await supabase
    .from('products')
    .select('primary_image');
  
  let r2Count = 0;
  let httpsCount = 0;
  let httpCount = 0;
  let relativeCount = 0;
  
  allProducts.forEach(p => {
    if (p.primary_image) {
      if (p.primary_image.includes('r2.dev')) r2Count++;
      if (p.primary_image.startsWith('https://')) httpsCount++;
      if (p.primary_image.startsWith('http://')) httpCount++;
      if (!p.primary_image.startsWith('http')) relativeCount++;
    }
  });
  
  console.log('\n📊 IMAGE URL ANALYSIS:');
  console.log(`Total products: ${allProducts.length}`);
  console.log(`R2 bucket URLs: ${r2Count}`);
  console.log(`HTTPS URLs: ${httpsCount}`);
  console.log(`HTTP URLs: ${httpCount}`);
  console.log(`Relative paths: ${relativeCount}`);
  
  console.log('\n\n🔧 TROUBLESHOOTING STEPS:\n');
  console.log('1. CHECK BROWSER CONSOLE:');
  console.log('   - Open the website');
  console.log('   - Press F12 for DevTools');
  console.log('   - Go to Console tab');
  console.log('   - Look for CORS errors or 404s');
  console.log('   - Share the exact error message');
  
  console.log('\n2. CHECK NETWORK TAB:');
  console.log('   - In DevTools, go to Network tab');
  console.log('   - Refresh the page');
  console.log('   - Filter by "Img"');
  console.log('   - Look for red failed requests');
  console.log('   - Click on a failed image to see details');
  
  console.log('\n3. VERIFY R2 CORS:');
  console.log('   Current allowed origins should include:');
  console.log('   - Your website domain (kctmenswear.com)');
  console.log('   - Admin panel URLs');
  console.log('   - Make sure to Save after updating CORS in Cloudflare');
  
  console.log('\n4. TEST DIRECT ACCESS:');
  console.log('   Try accessing this URL directly:');
  console.log(`   ${products[0]?.primary_image}`);
  
  console.log('\n\n❓ COMMON ISSUES:');
  console.log('1. CORS not saved properly in Cloudflare');
  console.log('2. Browser caching old CORS headers (try incognito)');
  console.log('3. Website using different Supabase instance');
  console.log('4. Images need different URL format for website');
  
  console.log('\n💡 What domain is your website on? Share the URL where images aren\'t loading.');
}

diagnoseImages().catch(console.error);