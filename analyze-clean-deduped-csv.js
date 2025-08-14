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

async function analyzeDedupedCSV() {
  console.log('=== ANALYZING CLEAN DEDUPED CSV ===\n');
  
  const csvFile = path.join(__dirname, 'Product_Names___URLs__clean__deduped__no_placeholders_.csv');
  const csvData = parseCSV(csvFile);
  
  console.log(`Total entries in CSV: ${csvData.length}\n`);
  
  // Analyze image URLs for duplicates
  const imageMap = {};
  const duplicateImages = {};
  
  csvData.forEach(row => {
    const imageUrl = row.image_url || row.url || row.primary_image;
    if (imageUrl) {
      // Extract just the filename for comparison
      const filename = imageUrl.split('/').pop();
      
      if (!imageMap[filename]) {
        imageMap[filename] = [];
      }
      imageMap[filename].push(row.product_name || row.name || 'Unknown');
    }
  });
  
  // Find duplicates
  Object.entries(imageMap).forEach(([filename, products]) => {
    if (products.length > 1) {
      duplicateImages[filename] = products;
    }
  });
  
  console.log('📸 IMAGE ANALYSIS:');
  console.log('==================\n');
  console.log(`Unique images: ${Object.keys(imageMap).length}`);
  console.log(`Duplicate images: ${Object.keys(duplicateImages).length}\n`);
  
  if (Object.keys(duplicateImages).length > 0) {
    console.log('🔄 DUPLICATE IMAGES FOUND:\n');
    Object.entries(duplicateImages)
      .slice(0, 10)
      .forEach(([filename, products]) => {
        console.log(`\n${filename}:`);
        console.log(`  Used by ${products.length} products:`);
        products.slice(0, 5).forEach(p => console.log(`    - ${p}`));
        if (products.length > 5) console.log(`    ... and ${products.length - 5} more`);
      });
  }
  
  // Get current database products
  const { data: dbProducts, error } = await supabase
    .from('products')
    .select('name, primary_image');
  
  if (!error && dbProducts) {
    console.log('\n\n📊 DATABASE COMPARISON:');
    console.log('========================\n');
    console.log(`Database products: ${dbProducts.length}`);
    console.log(`CSV products: ${csvData.length}\n`);
    
    // Check which CSV products match database
    let matches = 0;
    let newProducts = [];
    
    csvData.forEach(csvRow => {
      const csvName = (csvRow.product_name || csvRow.name || '').toLowerCase().trim();
      const dbMatch = dbProducts.find(dbProd => 
        dbProd.name?.toLowerCase().trim() === csvName
      );
      
      if (dbMatch) {
        matches++;
      } else {
        newProducts.push(csvRow.product_name || csvRow.name);
      }
    });
    
    console.log(`Matched products: ${matches}`);
    console.log(`New products in CSV: ${newProducts.length}\n`);
    
    if (newProducts.length > 0 && newProducts.length < 20) {
      console.log('New products not in database:');
      newProducts.forEach(p => console.log(`  - ${p}`));
    }
    
    // Check database for duplicate images
    const dbImageMap = {};
    dbProducts.forEach(p => {
      if (p.primary_image) {
        const filename = p.primary_image.split('/').pop();
        if (!dbImageMap[filename]) {
          dbImageMap[filename] = [];
        }
        dbImageMap[filename].push(p.name);
      }
    });
    
    const dbDuplicates = Object.entries(dbImageMap)
      .filter(([_, products]) => products.length > 1);
    
    console.log('\n📸 DATABASE IMAGE STATUS:');
    console.log(`Database duplicate images: ${dbDuplicates.length}`);
    
    if (dbDuplicates.length > 0) {
      console.log('\nTop duplicate images in database:');
      dbDuplicates
        .sort((a, b) => b[1].length - a[1].length)
        .slice(0, 5)
        .forEach(([filename, products]) => {
          console.log(`  ${filename}: ${products.length} products`);
        });
    }
  }
  
  // Sample some entries
  console.log('\n\n📋 SAMPLE CSV ENTRIES:');
  console.log('======================\n');
  csvData.slice(0, 5).forEach(row => {
    console.log(`Product: ${row.product_name || row.name}`);
    console.log(`Image: ${(row.image_url || row.url || row.primary_image || '').substring(0, 80)}...`);
    console.log('---');
  });
  
  // Summary
  console.log('\n\n✅ SUMMARY:');
  console.log('===========');
  
  if (Object.keys(duplicateImages).length === 0) {
    console.log('✅ CSV has NO duplicate images - all unique!');
  } else {
    console.log(`⚠️ CSV still has ${Object.keys(duplicateImages).length} duplicate images`);
  }
  
  console.log('\n💡 RECOMMENDATION:');
  if (Object.keys(duplicateImages).length > 10) {
    console.log('This CSV can help identify which products need unique images');
    console.log('Use it to update products that currently share the same image');
  } else {
    console.log('CSV looks clean with mostly unique images');
    console.log('Can be used to update existing products with better image URLs');
  }
}

analyzeDedupedCSV().catch(console.error);