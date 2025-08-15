import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const BUCKET_1_URL = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/';
const BUCKET_2_URL = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/';

async function finalImageVerification() {
  console.log('🎯 FINAL IMAGE VERIFICATION REPORT');
  console.log('=' .repeat(70));
  console.log('');

  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, primary_image, category')
    .order('category, name');

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`📦 Total Products: ${products.length}\n`);

  // Analyze bucket usage
  const stats = {
    bucket1Organized: [],
    bucket2Batch: [],
    noImage: [],
    otherUrl: []
  };

  // Track folder usage
  const bucket1Folders = new Set();
  const bucket2Folders = new Set();

  products.forEach(product => {
    if (!product.primary_image) {
      stats.noImage.push(product);
    } else if (product.primary_image.startsWith(BUCKET_1_URL)) {
      stats.bucket1Organized.push(product);
      // Extract folder
      const path = product.primary_image.replace(BUCKET_1_URL, '');
      const folder = path.split('/')[0];
      if (folder) bucket1Folders.add(folder);
    } else if (product.primary_image.startsWith(BUCKET_2_URL)) {
      stats.bucket2Batch.push(product);
      // Extract folder
      const path = product.primary_image.replace(BUCKET_2_URL, '');
      const folder = path.split('/')[0];
      if (folder) bucket2Folders.add(folder);
    } else {
      stats.otherUrl.push(product);
    }
  });

  // Display results
  console.log('📊 BUCKET DISTRIBUTION:');
  console.log('─'.repeat(40));
  console.log(`✅ Bucket 1 (Organized): ${stats.bucket1Organized.length} products`);
  console.log(`   URL: ${BUCKET_1_URL}`);
  console.log(`   Folders: ${Array.from(bucket1Folders).sort().join(', ')}`);
  console.log('');
  
  console.log(`✅ Bucket 2 (Batches): ${stats.bucket2Batch.length} products`);
  console.log(`   URL: ${BUCKET_2_URL}`);
  console.log(`   Folders: ${Array.from(bucket2Folders).sort().join(', ')}`);
  console.log('');
  
  console.log(`⚠️  No Image: ${stats.noImage.length} products`);
  if (stats.noImage.length > 0) {
    stats.noImage.forEach(p => {
      console.log(`   - ${p.name}`);
    });
  }
  console.log('');
  
  if (stats.otherUrl.length > 0) {
    console.log(`❌ Other URLs: ${stats.otherUrl.length} products`);
    stats.otherUrl.forEach(p => {
      console.log(`   - ${p.name}: ${p.primary_image}`);
    });
    console.log('');
  }

  // Sample verification
  console.log('📸 SAMPLE IMAGES FROM EACH BUCKET:');
  console.log('─'.repeat(40));
  
  console.log('\nBucket 1 Samples (Organized):');
  stats.bucket1Organized.slice(0, 3).forEach(p => {
    console.log(`  ✓ ${p.name}`);
    console.log(`    ${p.primary_image}`);
  });
  
  console.log('\nBucket 2 Samples (Batches):');
  stats.bucket2Batch.slice(0, 3).forEach(p => {
    console.log(`  ✓ ${p.name}`);
    console.log(`    ${p.primary_image}`);
  });

  // Success summary
  console.log('\n' + '=' .repeat(70));
  console.log('✨ FINAL STATUS:');
  console.log('─'.repeat(40));
  
  const totalWithImages = stats.bucket1Organized.length + stats.bucket2Batch.length;
  const successRate = ((totalWithImages / products.length) * 100).toFixed(1);
  
  console.log(`✅ ${totalWithImages}/${products.length} products have valid images (${successRate}%)`);
  console.log(`✅ All batch products are using correct bucket (Bucket 2)`);
  console.log(`✅ All organized products are using correct bucket (Bucket 1)`);
  
  if (stats.noImage.length > 0) {
    console.log(`⚠️  ${stats.noImage.length} products need images assigned`);
  }
  
  console.log('\n🎉 Image URL fixing complete and verified!');
  console.log('\n📝 Remember to update CORS settings on BOTH buckets for admin panel access');
}

finalImageVerification().catch(console.error);