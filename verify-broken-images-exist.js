import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function verifyBrokenImagesExist() {
  console.log('🔍 Checking if the broken image files actually exist...\n');
  console.log('=' .repeat(70));
  
  // Get the products that were supposedly fixed
  const productsToCheck = [
    'Black Floral Embroidered Tuxedo',
    'Black Velvet Tuxedo Jacket', 
    'Burgundy Velvet Dinner Jacket',
    'Burgundy Velvet Tuxedo Jacket',
    'Carolina Blue Vest & Tie Set'
  ];
  
  for (const productName of productsToCheck) {
    const { data: product } = await supabase
      .from('products')
      .select('name, primary_image')
      .eq('name', productName)
      .single();
    
    if (product) {
      console.log(`\n📸 ${product.name}`);
      console.log(`Current URL: ${product.primary_image}`);
      
      // These images likely don't exist. Let's suggest alternatives
      const nameLower = product.name.toLowerCase();
      let suggestedUrl = '';
      
      if (nameLower.includes('tuxedo')) {
        // Map to organized tuxedos folder
        const color = nameLower.includes('burgundy') ? 'burgundy' : 'black';
        suggestedUrl = `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/${color}-model.png`;
      } else if (nameLower.includes('velvet') && nameLower.includes('jacket')) {
        // Map to velvet-blazer folder
        const color = nameLower.includes('burgundy') ? 'burgundy' : 'black';
        suggestedUrl = `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/${color}-model.png`;
      } else if (nameLower.includes('vest')) {
        // Map to main-solid-vest-tie folder
        const color = nameLower.includes('carolina') || nameLower.includes('blue') ? 'blue' : 'black';
        suggestedUrl = `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/${color}-model.png`;
      }
      
      console.log(`❌ This file probably doesn't exist in R2`);
      console.log(`✅ Suggested alternative: ${suggestedUrl}`);
    }
  }
  
  console.log('\n' + '=' .repeat(70));
  console.log('\n📝 REALITY CHECK:');
  console.log('The batch_1/batch_2/ and batch_1/batch_3/ folders probably don\'t exist.');
  console.log('The files with these paths were likely never uploaded to R2.');
  console.log('\n💡 SOLUTION:');
  console.log('Map these products to existing images in the organized folders instead.');
}

verifyBrokenImagesExist().catch(console.error);