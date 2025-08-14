import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

// Use anon key like the website does
const supabase = createClient(SUPABASE_URL, ANON_KEY);

async function checkImageFormats() {
  console.log('=== CHECKING IMAGE FORMATS ===\n');
  
  // Get products using anon key (like website does)
  const { data: products, error } = await supabase
    .from('products')
    .select('name, primary_image, status')
    .eq('status', 'active')
    .limit(20);
  
  if (error) {
    console.error('Error fetching with anon key:', error);
    return;
  }
  
  console.log(`Found ${products.length} active products\n`);
  
  // Categorize images
  const working = [];
  const notWorking = [];
  
  products.forEach(p => {
    if (p.primary_image) {
      // Check image path structure
      const img = p.primary_image;
      
      // Images that typically work
      if (img.includes('/batch_1/') || 
          img.includes('/tie_clean_batch_01/') ||
          img.includes('/batch_2/')) {
        working.push({ name: p.name, image: img });
      }
      // Images from folders we just updated
      else if (img.includes('/main-solid-vest-tie/') ||
               img.includes('/velvet-blazer/') ||
               img.includes('/sparkle-blazer/') ||
               img.includes('/double_breasted/') ||
               img.includes('/prom_blazer/')) {
        notWorking.push({ name: p.name, image: img });
      }
    }
  });
  
  console.log('📸 IMAGES THAT SHOULD WORK (old format):');
  console.log('==========================================');
  working.slice(0, 3).forEach(item => {
    console.log(`${item.name}:`);
    console.log(`  ${item.image}\n`);
  });
  
  console.log('\n❌ IMAGES THAT MIGHT NOT WORK (new format):');
  console.log('============================================');
  notWorking.slice(0, 3).forEach(item => {
    console.log(`${item.name}:`);
    console.log(`  ${item.image}\n`);
  });
  
  // Check if the issue is the folder structure
  console.log('\n🔍 FOLDER ANALYSIS:\n');
  
  const folders = new Set();
  products.forEach(p => {
    if (p.primary_image && p.primary_image.includes('r2.dev/')) {
      const parts = p.primary_image.split('r2.dev/')[1].split('/');
      if (parts[0]) folders.add(parts[0]);
    }
  });
  
  console.log('Folders being used:');
  Array.from(folders).forEach(f => console.log(`  - ${f}`));
  
  console.log('\n\n💡 POSSIBLE ISSUE:\n');
  console.log('The new images use different folder names that might not exist in R2:');
  console.log('  - main-solid-vest-tie (with hyphens)');
  console.log('  - velvet-blazer (with hyphen)');
  console.log('  - sparkle-blazer (with hyphen)');
  console.log('\nBut the actual R2 folders might be:');
  console.log('  - main_solid_vest_tie (with underscores)');
  console.log('  - velvet_blazer (with underscore)');
  console.log('  - sparkle_blazer (with underscore)');
  
  console.log('\n\n✅ QUICK FIX:');
  console.log('We might need to update the image URLs to match the actual R2 folder structure.');
  console.log('Or verify what folders actually exist in your R2 bucket.');
}

checkImageFormats().catch(console.error);