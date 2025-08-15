import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function verifyAllImagesFixed() {
  console.log('🔍 Verifying all product images are fixed...\n');

  const R2_BASE = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/';

  // Get all products
  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, primary_image, category, status')
    .order('category, name');

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`Total products in database: ${products.length}\n`);

  // Categorize products
  const categories = {
    correctR2: [],
    noImage: [],
    wrongFormat: [],
    inactive: []
  };

  products.forEach(product => {
    if (product.status !== 'active') {
      categories.inactive.push(product);
    } else if (!product.primary_image) {
      categories.noImage.push(product);
    } else if (product.primary_image.startsWith(R2_BASE)) {
      categories.correctR2.push(product);
    } else {
      categories.wrongFormat.push(product);
    }
  });

  console.log('📊 FINAL IMAGE STATUS REPORT:');
  console.log('=' .repeat(50));
  console.log(`✅ Active products with correct R2 URLs: ${categories.correctR2.length}`);
  console.log(`⚠️  Active products without images: ${categories.noImage.length}`);
  console.log(`❌ Active products with wrong URL format: ${categories.wrongFormat.length}`);
  console.log(`🔸 Inactive products: ${categories.inactive.length}`);
  console.log('=' .repeat(50));

  // Show products without images
  if (categories.noImage.length > 0) {
    console.log('\n⚠️  Products without images:');
    categories.noImage.forEach(p => {
      console.log(`  - ${p.name} (${p.category || 'no category'})`);
    });
  }

  // Show products with wrong format (should be 0)
  if (categories.wrongFormat.length > 0) {
    console.log('\n❌ Products with wrong URL format:');
    categories.wrongFormat.forEach(p => {
      console.log(`  - ${p.name}: ${p.primary_image}`);
    });
  }

  // Sample some correct URLs to verify
  console.log('\n✅ Sample of correct R2 URLs:');
  categories.correctR2.slice(0, 5).forEach(p => {
    console.log(`  - ${p.name}`);
    console.log(`    ${p.primary_image}`);
  });

  // Group by R2 folder to see distribution
  console.log('\n📁 Image distribution by R2 folder:');
  const folderCounts = {};
  categories.correctR2.forEach(p => {
    const url = p.primary_image;
    const folder = url.replace(R2_BASE, '').split('/')[0];
    folderCounts[folder] = (folderCounts[folder] || 0) + 1;
  });

  Object.entries(folderCounts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([folder, count]) => {
      console.log(`  ${folder}: ${count} products`);
    });

  console.log('\n🎉 Image URL fixing complete!');
  console.log(`${categories.correctR2.length}/${products.filter(p => p.status === 'active').length} active products have valid R2 image URLs`);
}

verifyAllImagesFixed().catch(console.error);