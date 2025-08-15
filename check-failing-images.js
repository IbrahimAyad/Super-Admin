import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// The failing URLs you provided
const failingUrls = [
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_black-floral-embroidered-tuxedo_1.0.jpg',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_black-velvet-tuxedo-jacket_1.0.jpg',
  'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/blue-model.pn', // Note: missing 'g' at end
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_royal-blue-vest-and-tie-set_1.0.jpg'
];

async function checkFailingImages() {
  console.log('🔍 Checking products with failing image URLs...\n');
  console.log('=' .repeat(70));
  
  for (const url of failingUrls) {
    console.log(`\n📸 Checking: ${url}`);
    console.log('─'.repeat(60));
    
    // Find products with this URL
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, primary_image')
      .eq('primary_image', url);
    
    if (error) {
      console.error('Error:', error);
      continue;
    }
    
    if (products && products.length > 0) {
      products.forEach(p => {
        console.log(`✓ Found product: ${p.name}`);
        console.log(`  ID: ${p.id}`);
        
        // Analyze the issue
        if (url.includes('.pn')) {
          console.log(`  ❌ Issue: URL is missing 'g' at the end (.pn instead of .png)`);
          console.log(`  ✅ Fix: Add 'g' to make it .png`);
        } else if (url.includes('batch_1/batch_2') || url.includes('batch_1/batch_3')) {
          console.log(`  ⚠️  Issue: These are nested batch folders (batch_1/batch_2 or batch_1/batch_3)`);
          console.log(`  📝 Note: These images might not exist in R2 bucket`);
        } else if (url.includes('batch_1/vest_')) {
          console.log(`  ⚠️  Issue: Direct vest_ file in batch_1 folder`);
          console.log(`  📝 Note: This image might not exist in R2 bucket`);
        }
      });
    } else {
      console.log('❌ No products found with this exact URL');
      
      // Try to find similar URLs
      const partialUrl = url.replace('https://', '%').split('/').slice(-1)[0];
      const { data: similarProducts } = await supabase
        .from('products')
        .select('id, name, primary_image')
        .like('primary_image', `%${partialUrl}%`)
        .limit(3);
      
      if (similarProducts && similarProducts.length > 0) {
        console.log('  Found similar products:');
        similarProducts.forEach(p => {
          console.log(`  - ${p.name}`);
          console.log(`    ${p.primary_image}`);
        });
      }
    }
  }
  
  console.log('\n' + '=' .repeat(70));
  console.log('📊 ANALYSIS SUMMARY:');
  console.log('─'.repeat(40));
  console.log('1. One URL has a typo (.pn instead of .png)');
  console.log('2. Several URLs point to nested batch folders (batch_1/batch_2/, batch_1/batch_3/)');
  console.log('3. These nested batch images might not exist in the R2 bucket');
  console.log('\n💡 RECOMMENDATION:');
  console.log('- Fix the .pn typo to .png');
  console.log('- Verify if batch_1/batch_2/ and batch_1/batch_3/ folders exist in R2');
  console.log('- Consider mapping these to existing images in batch_1/ folder');
}

checkFailingImages().catch(console.error);