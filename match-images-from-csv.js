// Script to generate SQL for updating all placeholder images with real R2 bucket images
// Based on the CSV files we have with actual image URLs

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import csv from 'csv-parser';

// Initialize Supabase client
const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || 'YOUR_SERVICE_KEY'
);

// Read and parse CSV files
async function loadImageMappings() {
  const mappings = [];
  
  // Load main products CSV
  const mainProducts = await loadCSV('./sql/imports/products_main_urls.csv');
  const blazers = await loadCSV('./products_blazers_urls.csv');
  const sets = await loadCSV('./sql/imports/products_sets_urls.csv');
  
  return { mainProducts, blazers, sets };
}

function loadCSV(filepath) {
  return new Promise((resolve) => {
    const results = [];
    fs.createReadStream(filepath)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('end', () => resolve(results));
  });
}

// Generate smart matching SQL
async function generateImageUpdateSQL() {
  const { mainProducts, blazers, sets } = await loadImageMappings();
  
  let sql = `-- AUTO-GENERATED SQL TO UPDATE PLACEHOLDER IMAGES WITH REAL R2 IMAGES
-- Generated from CSV files: ${new Date().toISOString()}

BEGIN;

-- Show current state
SELECT 
    'BEFORE' as status,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images
FROM products WHERE status = 'active';

`;

  // Process blazers (most specific)
  console.log('Processing blazers...');
  blazers.forEach(item => {
    if (item.image_1) {
      const keywords = extractKeywords(item.product_name_guess || item.base_name);
      sql += `
-- ${item.product_name_guess || item.base_name}
UPDATE products
SET primary_image = '${item.image_1}'
WHERE category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Blazers')
    AND (${keywords.map(k => `LOWER(name) LIKE '%${k.toLowerCase()}%'`).join(' OR ')})
    AND primary_image LIKE '%placehold%'
    LIMIT 1;
`;
    }
  });

  // Process main products
  console.log('Processing main products...');
  mainProducts.forEach(item => {
    if (item.image_1) {
      const productType = detectProductType(item.product_slug);
      const keywords = extractKeywords(item.product_name);
      
      sql += `
-- ${item.product_name}
UPDATE products
SET primary_image = '${item.image_1}'
WHERE ${getCategoryCondition(productType)}
    AND (${keywords.map(k => `LOWER(name) LIKE '%${k.toLowerCase()}%'`).join(' OR ')})
    AND primary_image LIKE '%placehold%'
    LIMIT 1;
`;
    }
  });

  sql += `
-- Show results
SELECT 
    'AFTER' as status,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images
FROM products WHERE status = 'active';

-- Breakdown by category
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total DESC;

COMMIT;`;

  return sql;
}

// Helper functions
function extractKeywords(productName) {
  if (!productName) return [];
  
  // Extract meaningful keywords from product name
  const keywords = productName
    .split(/[\s-]+/)
    .filter(word => 
      word.length > 2 && 
      !['and', 'the', 'with', 'for', 'men', 'mens'].includes(word.toLowerCase())
    );
  
  // Add color keywords if present
  const colors = ['black', 'red', 'blue', 'navy', 'green', 'purple', 'gold', 'silver', 'white', 'grey'];
  const foundColors = colors.filter(c => productName.toLowerCase().includes(c));
  
  return [...new Set([...keywords, ...foundColors])];
}

function detectProductType(slug) {
  if (slug.includes('blazer')) return 'blazer';
  if (slug.includes('suit')) return 'suit';
  if (slug.includes('vest')) return 'vest';
  if (slug.includes('shirt')) return 'shirt';
  if (slug.includes('tie') || slug.includes('bowtie')) return 'accessories';
  if (slug.includes('shoe') || slug.includes('boot')) return 'footwear';
  if (slug.includes('cummerband')) return 'accessories';
  return 'other';
}

function getCategoryCondition(productType) {
  const categoryMap = {
    blazer: `category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Blazers', 'Casual Summer Blazers')`,
    suit: `category = 'Men''s Suits'`,
    vest: `category = 'Vest & Tie Sets'`,
    shirt: `category = 'Men''s Dress Shirts'`,
    accessories: `category = 'Accessories'`,
    footwear: `category = 'Accessories'`,
    other: `category IS NOT NULL`
  };
  
  return categoryMap[productType] || categoryMap.other;
}

// Main execution
async function main() {
  console.log('🖼️  Generating image update SQL from CSV files...\n');
  
  try {
    const sql = await generateImageUpdateSQL();
    
    // Save to file
    const filename = 'UPDATE-IMAGES-FROM-CSV.sql';
    fs.writeFileSync(filename, sql);
    
    console.log(`✅ SQL file generated: ${filename}`);
    console.log('\nNext steps:');
    console.log('1. Review the generated SQL file');
    console.log('2. Run it in Supabase SQL Editor');
    console.log('3. Verify images are updated');
    
    // Also analyze current state
    const { data: stats } = await supabase
      .from('products')
      .select('primary_image')
      .eq('status', 'active');
    
    if (stats) {
      const placeholders = stats.filter(p => p.primary_image?.includes('placehold')).length;
      const realImages = stats.filter(p => p.primary_image?.includes('r2.dev')).length;
      
      console.log(`\n📊 Current Status:`);
      console.log(`   Placeholder images: ${placeholders}`);
      console.log(`   Real images: ${realImages}`);
      console.log(`   Total products: ${stats.length}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}