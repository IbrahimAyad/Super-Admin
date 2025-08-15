import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function mapBrokenToExistingImages() {
  console.log('🔧 Mapping broken images to existing alternatives...\n');
  
  // Map products with non-existent images to real images that exist
  const mappings = [
    {
      name: 'Black Floral Embroidered Tuxedo',
      newUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/black-model.png'
    },
    {
      name: 'Black Velvet Tuxedo Jacket',
      newUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/black-model.png'
    },
    {
      name: 'Burgundy Velvet Dinner Jacket',
      newUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/burgundy-model.png'
    },
    {
      name: 'Burgundy Velvet Tuxedo Jacket',
      newUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/burgundy-model.png'
    },
    {
      name: 'Carolina Blue Vest & Tie Set',
      newUrl: 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blue-model.png'
    }
  ];
  
  console.log(`📋 Mapping ${mappings.length} products to existing images\n`);
  
  let successCount = 0;
  
  for (const mapping of mappings) {
    console.log(`\n🔧 ${mapping.name}`);
    console.log(`   New image: ${mapping.newUrl}`);
    
    const { error } = await supabase
      .from('products')
      .update({ primary_image: mapping.newUrl })
      .eq('name', mapping.name);
    
    if (error) {
      console.error(`   ❌ Error: ${error.message}`);
    } else {
      console.log(`   ✅ Mapped to existing image!`);
      successCount++;
    }
  }
  
  console.log('\n' + '=' .repeat(70));
  console.log(`\n✨ Successfully mapped ${successCount}/${mappings.length} products to existing images`);
  console.log('\nThese products now use images that actually exist in your R2 buckets.');
}

mapBrokenToExistingImages().catch(console.error);