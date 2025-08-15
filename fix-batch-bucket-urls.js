import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// The two bucket URLs
const BUCKET_1_URL = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/'; // kct-base-products (organized folders)
const BUCKET_2_URL = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/'; // kct-new-website-products (batch folders)

async function fixBatchBucketUrls() {
  console.log('🔍 Analyzing product images for bucket URL corrections...\n');
  console.log('Bucket 1 (organized): ' + BUCKET_1_URL);
  console.log('Bucket 2 (batches): ' + BUCKET_2_URL);
  console.log('=' .repeat(70) + '\n');

  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, primary_image')
    .order('name');

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`Found ${products.length} total products\n`);

  // Categorize products
  const categories = {
    correctBucket1: [],  // Organized folders with correct bucket
    correctBucket2: [],  // Batch folders with correct bucket
    wrongBucket: [],     // Batch folders with wrong bucket (need fixing)
    noImage: []
  };

  products.forEach(product => {
    if (!product.primary_image) {
      categories.noImage.push(product);
      return;
    }

    const image = product.primary_image;
    
    // Check if it's a batch image (contains batch_1 or tie_clean_batch)
    const isBatchImage = image.includes('/batch_1/') || 
                        image.includes('/tie_clean_batch_');
    
    if (isBatchImage) {
      // Batch images should use BUCKET_2_URL
      if (image.startsWith(BUCKET_2_URL)) {
        categories.correctBucket2.push(product);
      } else if (image.startsWith(BUCKET_1_URL)) {
        categories.wrongBucket.push(product);
      }
    } else {
      // Organized folder images should use BUCKET_1_URL
      if (image.startsWith(BUCKET_1_URL)) {
        categories.correctBucket1.push(product);
      }
    }
  });

  console.log('📊 Current Status:');
  console.log(`✅ Correct Bucket 1 (organized): ${categories.correctBucket1.length}`);
  console.log(`✅ Correct Bucket 2 (batches): ${categories.correctBucket2.length}`);
  console.log(`❌ Wrong bucket (need fixing): ${categories.wrongBucket.length}`);
  console.log(`⚠️  No image: ${categories.noImage.length}`);
  console.log('');

  if (categories.wrongBucket.length === 0) {
    console.log('✨ All products are using the correct bucket URLs!');
    return;
  }

  // Show what needs fixing
  console.log('🔴 Products that need bucket URL correction:');
  console.log('(These have batch images but are using the wrong bucket)\n');
  
  categories.wrongBucket.slice(0, 5).forEach(p => {
    console.log(`  ${p.name}`);
    console.log(`    Current: ${p.primary_image}`);
    console.log(`    Should be: ${p.primary_image.replace(BUCKET_1_URL, BUCKET_2_URL)}`);
    console.log('');
  });

  if (categories.wrongBucket.length > 5) {
    console.log(`  ... and ${categories.wrongBucket.length - 5} more\n`);
  }

  // Fix the wrong bucket URLs
  console.log('🔧 Fixing incorrect bucket URLs...\n');
  
  let successCount = 0;
  let failCount = 0;

  for (const product of categories.wrongBucket) {
    // Replace wrong bucket URL with correct one
    const newUrl = product.primary_image.replace(BUCKET_1_URL, BUCKET_2_URL);
    
    const { error: updateError } = await supabase
      .from('products')
      .update({ primary_image: newUrl })
      .eq('id', product.id);
    
    if (updateError) {
      console.error(`❌ Failed to update ${product.name}:`, updateError.message);
      failCount++;
    } else {
      successCount++;
      if (successCount <= 10) {
        console.log(`✅ Fixed: ${product.name}`);
      }
    }
  }

  console.log(`\n✨ Successfully fixed ${successCount}/${categories.wrongBucket.length} products`);
  if (failCount > 0) {
    console.log(`❌ Failed to fix ${failCount} products`);
  }

  // Final verification
  console.log('\n📊 Final Verification:\n');
  
  const { data: verifyProducts } = await supabase
    .from('products')
    .select('primary_image')
    .not('primary_image', 'is', null);

  let bucket1Count = 0;
  let bucket2Count = 0;
  let otherCount = 0;

  verifyProducts.forEach(p => {
    if (p.primary_image.startsWith(BUCKET_1_URL)) bucket1Count++;
    else if (p.primary_image.startsWith(BUCKET_2_URL)) bucket2Count++;
    else otherCount++;
  });

  console.log(`Products using Bucket 1 (organized): ${bucket1Count}`);
  console.log(`Products using Bucket 2 (batches): ${bucket2Count}`);
  if (otherCount > 0) {
    console.log(`Products using other URLs: ${otherCount}`);
  }

  console.log('\n✅ Bucket URL correction complete!');
}

fixBatchBucketUrls().catch(console.error);