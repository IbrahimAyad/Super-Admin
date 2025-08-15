import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function fixRemainingBrokenUrls() {
  console.log('🔍 Finding products with broken URLs...\n');

  const R2_BASE = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/';
  const OLD_R2_BASE = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/';

  // Get products with old R2 URLs or other broken URLs
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, primary_image, category')
    .or(`primary_image.like.${OLD_R2_BASE}%,primary_image.not.like.${R2_BASE}%`)
    .order('name');

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`Found ${products.length} products with broken URLs\n`);

  // Map each product to correct R2 structure
  const updates = [];
  
  for (const product of products) {
    const nameLower = product.name.toLowerCase();
    let newUrl = '';
    
    // Extract color from product name
    const colors = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'purple', 'pink', 
                   'orange', 'brown', 'grey', 'gray', 'navy', 'wine', 'burgundy', 'royal',
                   'silver', 'gold', 'champagne', 'ivory', 'cream', 'light-blue', 'dark-grey'];
    
    let color = 'black'; // default
    for (const c of colors) {
      if (nameLower.includes(c.replace('-', ' '))) {
        color = c;
        break;
      }
    }
    
    // Determine folder based on product name/category
    let folder = '';
    
    // Check product name for specific items
    if (nameLower.includes('suspender') && nameLower.includes('bow tie')) {
      folder = 'main-suspender-bowtie-set/';
    } else if (nameLower.includes('blazer')) {
      if (nameLower.includes('velvet')) {
        folder = 'velvet-blazer/';
      } else if (nameLower.includes('prom')) {
        folder = 'prom_blazer/';
      } else {
        folder = 'prom_blazer/';
      }
    } else if (nameLower.includes('tuxedo')) {
      folder = 'tuxedos/';
    } else if (nameLower.includes('suit')) {
      if (nameLower.includes('double breasted')) {
        folder = 'double_breasted/';
      } else {
        folder = 'suits/';
      }
    } else if (nameLower.includes('cummerbund') || nameLower.includes('cummerband')) {
      // Cummerbunds are in main-solid-vest-tie
      folder = 'main-solid-vest-tie/';
    } else if (nameLower.includes('vest') || nameLower.includes('tie')) {
      folder = 'main-solid-vest-tie/';
    } else if (nameLower.includes('shirt')) {
      folder = 'dress_shirts/';
    } else if (nameLower.includes('shoe') || nameLower.includes('boot')) {
      folder = 'dress_shirts/'; // No specific shoe folder seen
    } else {
      // Default to vest-tie
      folder = 'main-solid-vest-tie/';
    }
    
    // Construct new URL
    newUrl = `${R2_BASE}${folder}${color}-model.png`;
    
    console.log(`Fixing: ${product.name}`);
    console.log(`  Old: ${product.primary_image}`);
    console.log(`  New: ${newUrl}`);
    
    updates.push({
      id: product.id,
      name: product.name,
      newUrl: newUrl
    });
  }
  
  // Apply all updates
  console.log(`\n🔧 Applying ${updates.length} URL fixes...`);
  
  let successCount = 0;
  for (const update of updates) {
    const { error: updateError } = await supabase
      .from('products')
      .update({ primary_image: update.newUrl })
      .eq('id', update.id);
    
    if (updateError) {
      console.error(`❌ Failed to update ${update.name}:`, updateError.message);
    } else {
      successCount++;
    }
  }
  
  console.log(`\n✅ Successfully fixed ${successCount}/${updates.length} products`);
  
  // Final verification
  const { data: remaining } = await supabase
    .from('products')
    .select('id')
    .not('primary_image', 'like', `${R2_BASE}%`)
    .not('primary_image', 'is', null);
  
  console.log(`\n📊 Remaining products with non-R2 URLs: ${remaining?.length || 0}`);
}

fixRemainingBrokenUrls().catch(console.error);