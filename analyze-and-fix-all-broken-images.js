import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function analyzeAndFixImages() {
  console.log('🔍 Analyzing all product images...\n');

  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, primary_image, category')
    .order('name');

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`Found ${products.length} total products\n`);

  // Analyze image issues
  const issues = {
    missingHttps: [],
    oldFormat: [],
    correctFormat: [],
    noImage: []
  };

  const R2_BASE = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/';

  products.forEach(product => {
    if (!product.primary_image) {
      issues.noImage.push(product);
    } else if (!product.primary_image.startsWith('https://')) {
      issues.missingHttps.push(product);
    } else if (!product.primary_image.startsWith(R2_BASE)) {
      issues.oldFormat.push(product);
    } else {
      issues.correctFormat.push(product);
    }
  });

  console.log('📊 Image Status Summary:');
  console.log(`✅ Correct R2 URLs: ${issues.correctFormat.length}`);
  console.log(`❌ Old format URLs: ${issues.oldFormat.length}`);
  console.log(`❌ Missing https://: ${issues.missingHttps.length}`);
  console.log(`❌ No image: ${issues.noImage.length}`);
  console.log('');

  // Show samples of broken images
  if (issues.oldFormat.length > 0) {
    console.log('🔴 Sample of products with OLD format URLs:');
    issues.oldFormat.slice(0, 10).forEach(p => {
      console.log(`  - ${p.name}: ${p.primary_image}`);
    });
    console.log('');
  }

  // Fix missing https://
  if (issues.missingHttps.length > 0) {
    console.log(`\n🔧 Fixing ${issues.missingHttps.length} products missing https://...`);
    
    for (const product of issues.missingHttps) {
      const newUrl = R2_BASE + product.primary_image;
      const { error: updateError } = await supabase
        .from('products')
        .update({ primary_image: newUrl })
        .eq('id', product.id);

      if (updateError) {
        console.error(`  ❌ Failed to update ${product.name}:`, updateError.message);
      } else {
        console.log(`  ✅ Fixed ${product.name}`);
      }
    }
  }

  // Map old formats to new R2 structure
  console.log('\n🔄 Mapping old format URLs to R2 bucket structure...\n');

  const pathMappings = {
    // Map old prefixes to R2 folders based on screenshots
    'nan_': 'main-solid-vest-tie/',
    'vest-tie_': 'main-solid-vest-tie/',
    'vest-and-tie_': 'main-solid-vest-tie/',
    'boots_': 'dress_shirts/',  // or appropriate folder
    'blazer_': 'prom_blazer/',
    'bowtie_': 'main-suspender-bowtie-set/',
    'cummerband_': 'main-solid-vest-tie/',
    'kid-suit_': 'suits/',
    'mens-tuxedos_': 'tuxedos/',
    'mens-blazers_': 'velvet-blazer/',
    'mens-suits_': 'suits/',
    'mens-double-breasted-suit_': 'double_breasted/'
  };

  // Process each old format URL
  let fixedCount = 0;
  for (const product of issues.oldFormat) {
    let newUrl = product.primary_image;
    
    // Check if it's an old localhost or other non-R2 URL
    if (newUrl.includes('localhost') || !newUrl.includes('r2.dev')) {
      // Extract filename from old URL
      const parts = newUrl.split('/');
      const filename = parts[parts.length - 1];
      
      // Try to determine correct folder based on product name or category
      let folder = 'main-solid-vest-tie/'; // default
      
      // Check for specific patterns in filename
      for (const [prefix, mappedFolder] of Object.entries(pathMappings)) {
        if (filename.includes(prefix)) {
          folder = mappedFolder;
          break;
        }
      }
      
      // Also check category
      if (product.category) {
        const catLower = product.category.toLowerCase();
        if (catLower.includes('blazer')) folder = 'velvet-blazer/';
        else if (catLower.includes('shirt')) folder = 'dress_shirts/';
        else if (catLower.includes('suit')) folder = 'suits/';
        else if (catLower.includes('tuxedo')) folder = 'tuxedos/';
        else if (catLower.includes('bowtie')) folder = 'main-suspender-bowtie-set/';
      }
      
      // Extract color from filename or product name
      const colors = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'purple', 'pink', 
                     'orange', 'brown', 'grey', 'gray', 'navy', 'wine', 'burgundy', 'royal',
                     'silver', 'gold', 'champagne', 'ivory', 'cream'];
      
      let color = 'black'; // default
      const nameLower = product.name.toLowerCase();
      for (const c of colors) {
        if (nameLower.includes(c) || filename.toLowerCase().includes(c)) {
          color = c;
          break;
        }
      }
      
      // Construct new URL with model.png as default
      newUrl = `${R2_BASE}${folder}${color}-model.png`;
      
      console.log(`  Mapping: ${product.name}`);
      console.log(`    From: ${product.primary_image}`);
      console.log(`    To: ${newUrl}`);
      
      // Update the product
      const { error: updateError } = await supabase
        .from('products')
        .update({ primary_image: newUrl })
        .eq('id', product.id);

      if (updateError) {
        console.error(`    ❌ Failed:`, updateError.message);
      } else {
        console.log(`    ✅ Updated`);
        fixedCount++;
      }
    }
  }

  console.log(`\n✨ Fixed ${fixedCount} products with old format URLs`);

  // Final verification
  console.log('\n📊 Final Status Check:');
  const { data: finalProducts } = await supabase
    .from('products')
    .select('primary_image')
    .not('primary_image', 'is', null);

  const finalCorrect = finalProducts.filter(p => 
    p.primary_image.startsWith(R2_BASE)
  ).length;

  console.log(`✅ Products with correct R2 URLs: ${finalCorrect}/${finalProducts.length}`);
  console.log(`❌ Products still needing fixes: ${finalProducts.length - finalCorrect}`);
}

analyzeAndFixImages().catch(console.error);