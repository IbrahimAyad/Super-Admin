import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function verifyImages() {
  console.log('=== VERIFYING IMAGE STATUS ===\n');
  
  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(10);
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  console.log('📸 Sample Product Images:\n');
  products.forEach(p => {
    console.log(`${p.name}:`);
    if (p.primary_image) {
      const imageUrl = p.primary_image;
      if (imageUrl.includes('r2.dev')) {
        console.log(`  ✅ R2 Image: ${imageUrl.substring(imageUrl.lastIndexOf('/') + 1)}`);
      } else if (imageUrl.includes('placehold')) {
        console.log(`  ⚠️ Placeholder: ${imageUrl.substring(0, 50)}...`);
      } else {
        console.log(`  ❓ Other: ${imageUrl.substring(0, 50)}...`);
      }
    } else {
      console.log(`  ❌ No image`);
    }
  });
  
  // Count overall stats
  const { data: allProducts } = await supabase
    .from('products')
    .select('primary_image');
  
  let r2Count = 0;
  let placeholderCount = 0;
  let missingCount = 0;
  let otherCount = 0;
  
  allProducts.forEach(p => {
    if (!p.primary_image) {
      missingCount++;
    } else if (p.primary_image.includes('r2.dev')) {
      r2Count++;
    } else if (p.primary_image.includes('placehold')) {
      placeholderCount++;
    } else {
      otherCount++;
    }
  });
  
  console.log('\n\n📊 OVERALL IMAGE STATS:');
  console.log('=======================');
  console.log(`Total products: ${allProducts.length}`);
  console.log(`✅ R2 images: ${r2Count}`);
  console.log(`⚠️ Placeholders: ${placeholderCount}`);
  console.log(`❌ Missing: ${missingCount}`);
  console.log(`❓ Other: ${otherCount}`);
  
  console.log('\n\n✅ NEXT STEPS:');
  console.log('==============');
  
  if (r2Count > 200) {
    console.log('1. ✅ Most products have R2 images');
    console.log('2. 🔄 Refresh your admin dashboard (Cmd+Shift+R)');
    console.log('3. 📸 Check if images are loading now');
  }
  
  if (placeholderCount > 0) {
    console.log(`\n⚠️ ${placeholderCount} products still need real images uploaded`);
  }
  
  console.log('\n💡 TIP: If images still not loading:');
  console.log('  - Clear browser cache (Cmd+Shift+Delete)');
  console.log('  - Try incognito mode');
  console.log('  - Check browser console for CORS errors');
}

verifyImages().catch(console.error);