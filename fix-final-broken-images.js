import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function fixFinalBrokenImages() {
  console.log('🔧 Fixing final broken image URLs...\n');
  
  const fixes = [
    {
      name: 'Blue Light Suspender Bow Tie Set',
      oldUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/blue-model.png',
      issue: 'Correct URL exists (found similar product with .png)'
    },
    {
      name: 'Black Floral Embroidered Tuxedo',
      oldUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_black-floral-embroidered-tuxedo_1.0.jpg',
      newUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-jacket_black-floral-embroidered-tuxedo_1.0.jpg',
      issue: 'Remove nested batch_2 folder'
    },
    {
      name: 'Black Velvet Tuxedo Jacket',
      oldUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_black-velvet-tuxedo-jacket_1.0.jpg',
      newUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-jacket_black-velvet-tuxedo-jacket_1.0.jpg',
      issue: 'Remove nested batch_3 folder'
    },
    {
      name: 'Burgundy Velvet Dinner Jacket',
      oldUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg',
      newUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg',
      issue: 'Remove nested batch_3 folder'
    },
    {
      name: 'Burgundy Velvet Tuxedo Jacket',
      oldUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg',
      newUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg',
      issue: 'Remove nested batch_2 folder'
    },
    {
      name: 'Carolina Blue Vest & Tie Set',
      oldUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_royal-blue-vest-and-tie-set_1.0.jpg',
      newUrl: 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_carolina-blue-vest-and-tie-set_1.0.jpg',
      issue: 'Fix filename to match product'
    }
  ];
  
  console.log(`📋 Fixing ${fixes.length} products with broken URLs\n`);
  
  for (const fix of fixes) {
    console.log(`\n🔧 Fixing: ${fix.name}`);
    console.log(`   Issue: ${fix.issue}`);
    
    if (fix.newUrl) {
      console.log(`   Old: ${fix.oldUrl}`);
      console.log(`   New: ${fix.newUrl}`);
      
      // Update the product
      const { data, error } = await supabase
        .from('products')
        .update({ primary_image: fix.newUrl })
        .eq('primary_image', fix.oldUrl);
      
      if (error) {
        console.error(`   ❌ Error: ${error.message}`);
      } else {
        console.log(`   ✅ Fixed!`);
      }
    } else {
      console.log(`   ℹ️  This product already has the correct URL`);
    }
  }
  
  // Also check for any products with .pn extension (typo)
  console.log('\n\n🔍 Checking for .pn extension typos...');
  
  const { data: typoProducts, error: typoError } = await supabase
    .from('products')
    .select('id, name, primary_image')
    .like('primary_image', '%.pn')
    .not('primary_image', 'like', '%.png');
  
  if (typoProducts && typoProducts.length > 0) {
    console.log(`Found ${typoProducts.length} products with .pn typo\n`);
    
    for (const product of typoProducts) {
      const fixedUrl = product.primary_image + 'g'; // Add the missing 'g'
      console.log(`Fixing typo for: ${product.name}`);
      console.log(`  Old: ${product.primary_image}`);
      console.log(`  New: ${fixedUrl}`);
      
      const { error: updateError } = await supabase
        .from('products')
        .update({ primary_image: fixedUrl })
        .eq('id', product.id);
      
      if (updateError) {
        console.error(`  ❌ Error: ${updateError.message}`);
      } else {
        console.log(`  ✅ Fixed!`);
      }
    }
  } else {
    console.log('No products found with .pn extension typo');
  }
  
  console.log('\n✨ Final image URL fixes complete!');
}

fixFinalBrokenImages().catch(console.error);