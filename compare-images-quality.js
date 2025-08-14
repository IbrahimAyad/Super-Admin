import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Papa from 'papaparse';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.LCWdoDoyJ_xo05CbRmM7erHsov8PsNqyo31n-bGvYtg';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function parseCSV(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const result = Papa.parse(content, {
    header: true,
    skipEmptyLines: true
  });
  return result.data;
}

async function compareImageQuality() {
  console.log('=== COMPARING IMAGE QUALITY ===\n');
  
  // Load Master-CSV-2 data
  const masterFile = path.join(__dirname, 'Master-CSV-2', 'Website_Master__Enhanced__No_Duplicates__Images_Cleaned_.csv');
  const masterData = parseCSV(masterFile);
  
  // Get the 50 products from database that match Master-CSV-2 SKUs
  const skuList = masterData.map(p => p.sku);
  
  const { data: existingProducts, error } = await supabase
    .from('products')
    .select('*')
    .in('sku', skuList);
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  console.log(`Comparing ${existingProducts.length} products\n`);
  
  let betterInCSV = 0;
  let betterInDB = 0;
  let sameQuality = 0;
  const updates = [];
  
  for (const csvProduct of masterData) {
    const dbProduct = existingProducts.find(p => p.sku === csvProduct.sku);
    
    if (!dbProduct) continue;
    
    const csvImage = csvProduct.primary_image;
    const dbImage = dbProduct.primary_image;
    
    // Analyze image quality
    const csvHasR2 = csvImage?.includes('r2.dev');
    const dbHasR2 = dbImage?.includes('r2.dev');
    const csvIsPlaceholder = !csvImage || csvImage.includes('placeholder') || csvImage.includes('placehold');
    const dbIsPlaceholder = !dbImage || dbImage.includes('placeholder') || dbImage.includes('placehold');
    
    // Check for duplicate images
    const knownDuplicates = [
      'mens_double_breasted_suit_2021_0.webp',
      'mens_black_paisley_pattern_velvet_model_1059.webp',
      'mens_black_glitter_finish_sparkle_model_1030.webp',
      'gold-model.png',
      'black-model.png',
      'wine-model.png'
    ];
    
    const dbHasDuplicate = knownDuplicates.some(dup => dbImage?.includes(dup));
    const csvHasDuplicate = knownDuplicates.some(dup => csvImage?.includes(dup));
    
    console.log(`\n${csvProduct.name} (${csvProduct.sku}):`);
    console.log(`  CSV image: ${csvImage?.substring(csvImage.lastIndexOf('/') + 1) || 'none'}`);
    console.log(`  DB image:  ${dbImage?.substring(dbImage.lastIndexOf('/') + 1) || 'none'}`);
    
    // Determine which is better
    if (csvIsPlaceholder && !dbIsPlaceholder) {
      console.log(`  ✅ DB has better image`);
      betterInDB++;
    } else if (!csvIsPlaceholder && dbIsPlaceholder) {
      console.log(`  🔄 CSV has better image - SHOULD UPDATE`);
      betterInCSV++;
      updates.push({
        sku: csvProduct.sku,
        name: csvProduct.name,
        oldImage: dbImage,
        newImage: csvImage
      });
    } else if (!csvIsPlaceholder && !dbIsPlaceholder) {
      // Both have real images
      if (dbHasDuplicate && !csvHasDuplicate) {
        console.log(`  🔄 CSV has unique image (DB has duplicate) - SHOULD UPDATE`);
        betterInCSV++;
        updates.push({
          sku: csvProduct.sku,
          name: csvProduct.name,
          oldImage: dbImage,
          newImage: csvImage
        });
      } else if (csvImage !== dbImage) {
        console.log(`  🤔 Different images (both real)`);
        sameQuality++;
      } else {
        console.log(`  = Same image`);
        sameQuality++;
      }
    } else {
      console.log(`  = Both placeholder or same`);
      sameQuality++;
    }
  }
  
  console.log('\n\n📊 SUMMARY:');
  console.log('===========');
  console.log(`Products where CSV has better image: ${betterInCSV}`);
  console.log(`Products where DB has better image: ${betterInDB}`);
  console.log(`Products with same/similar quality: ${sameQuality}`);
  
  if (updates.length > 0) {
    console.log('\n\n🔄 RECOMMENDED UPDATES:');
    console.log('========================');
    updates.forEach(u => {
      console.log(`\n${u.name}:`);
      console.log(`  FROM: ${u.oldImage?.substring(u.oldImage.lastIndexOf('/') + 1)}`);
      console.log(`  TO:   ${u.newImage?.substring(u.newImage.lastIndexOf('/') + 1)}`);
    });
    
    console.log('\n\n💾 APPLYING UPDATES...\n');
    
    for (const update of updates) {
      const { error: updateError } = await supabase
        .from('products')
        .update({ primary_image: update.newImage })
        .eq('sku', update.sku);
      
      if (updateError) {
        console.error(`❌ Error updating ${update.sku}:`, updateError);
      } else {
        console.log(`✅ Updated ${update.name}`);
      }
    }
    
    console.log(`\n✅ Updated ${updates.length} products with better images from Master-CSV-2`);
  } else {
    console.log('\n✅ No updates needed - current images are already good or better');
  }
}

compareImageQuality().catch(console.error);