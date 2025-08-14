// Import high-quality gallery images from product_gallery-Super-Admin.csv
// This updates both primary images AND creates gallery entries

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import csv from 'csv-parser';

const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3emttcWF2bnl5dWd4eXRuZ2ZrIiwicm9sZSI6InNlcnZpY2UfX3JvbGUiLCJpYXQiOjE3NjgxMDY1NDUsImV4cCI6MjA4MzY4MjU0NX0.oSLw8YjmRqNoU9P-Hpkxvs0pzg88KZsBG6SssUhP_hE'
);

async function importGalleryImages() {
  console.log('🖼️  Importing high-quality gallery images...\n');
  
  const products = await loadCSV('./product_gallery-Super-Admin.csv');
  console.log(`📊 Found ${products.length} products with gallery images\n`);
  
  // Generate SQL for updates
  let sql = `-- AUTO-GENERATED: Import Gallery Images from CSV
-- Generated: ${new Date().toISOString()}

BEGIN;

-- Clear old gallery entries for products we're updating
DELETE FROM product_images 
WHERE product_id IN (
  SELECT id FROM products 
  WHERE status = 'active' 
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
);

`;

  // Map categories from CSV to database categories
  const categoryMap = {
    'velvet-blazer': 'Luxury Velvet Blazers',
    'sparkle-blazer': 'Sparkle & Sequin Blazers',
    'prom_blazer': 'Prom & Formal Blazers',
    'main-solid-vest-tie': 'Vest & Tie Sets',
    'main-sparkle-vest': 'Vest & Tie Sets',
    'tuxedos': 'Tuxedos',
    'dress_shirts/mock_neck': 'Men\'s Dress Shirts',
    'dress_shirts/turtle_neck': 'Men\'s Dress Shirts',
    'dress_shirts/stretch_collar': 'Men\'s Dress Shirts',
    'double_breasted': 'Men\'s Suits',
    'stretch_suits': 'Men\'s Suits',
    'suits': 'Men\'s Suits',
    'main-suspender-bowtie-set': 'Accessories',
    'summer-blazer': 'Casual Summer Blazers'
  };

  // Process each product
  for (const row of products) {
    if (row.folder === 'folder') continue; // Skip header row
    
    const dbCategory = categoryMap[row.folder] || null;
    if (!dbCategory) continue;
    
    const mainImage = row.main_image_url;
    const galleryUrls = row.gallery_urls ? row.gallery_urls.split(';') : [mainImage];
    const productStem = row.product_stem;
    
    // Generate product name from stem
    const productName = formatProductName(productStem, row.folder);
    
    // Update primary image
    sql += `
-- Update ${productName}
UPDATE products
SET primary_image = '${mainImage}'
WHERE category = '${dbCategory}'
  AND (
    LOWER(name) LIKE '%${extractKeyword(productStem)}%'
    OR LOWER(sku) LIKE '%${productStem}%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
LIMIT 1;

`;

    // Insert gallery images
    if (galleryUrls.length > 1) {
      sql += `-- Add gallery images for ${productName}\n`;
      galleryUrls.forEach((url, index) => {
        const imageType = index === 0 ? 'primary' : 'gallery';
        sql += `INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, '${url}', '${imageType}', ${index + 1}, '${productName} - Image ${index + 1}'
FROM products
WHERE category = '${dbCategory}'
  AND primary_image = '${mainImage}'
  AND status = 'active'
ON CONFLICT DO NOTHING;

`;
      });
    }
  }

  sql += `
-- Update statistics
SELECT 
    'IMPORT COMPLETE' as status,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502158a94b8c%' THEN 1 END) as new_gallery_images,
    COUNT(CASE WHEN primary_image LIKE '%webp%' THEN 1 END) as webp_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as remaining_placeholders
FROM products
WHERE status = 'active';

-- Gallery entries created
SELECT 
    COUNT(*) as total_gallery_images,
    COUNT(DISTINCT product_id) as products_with_galleries
FROM product_images;

COMMIT;`;

  // Save SQL file
  fs.writeFileSync('IMPORT-GALLERY-IMAGES.sql', sql);
  console.log('✅ Generated IMPORT-GALLERY-IMAGES.sql\n');
  
  // Analyze potential matches
  await analyzeMatches(products);
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

function formatProductName(stem, folder) {
  // Convert product_stem to readable name
  let name = stem
    .replace(/_/g, ' ')
    .replace(/mens /g, 'Men\'s ')
    .replace(/\b\d{4}\b/g, '') // Remove year
    .replace(/\b\d{4}[a-z]?\b/g, '') // Remove SKU codes
    .trim();
  
  // Capitalize words
  name = name.replace(/\b\w/g, l => l.toUpperCase());
  
  // Add category context if needed
  if (folder.includes('vest')) name += ' Vest & Tie Set';
  if (folder.includes('blazer')) name += ' Blazer';
  if (folder.includes('shirt')) name += ' Dress Shirt';
  
  return name;
}

function extractKeyword(stem) {
  // Extract main keyword for matching
  const keywords = stem.split('_');
  // Filter out common words and numbers
  const meaningful = keywords.filter(k => 
    !['mens', 'model', '2021', '2022', '2023', '2024', '2025'].includes(k) &&
    !k.match(/^\d+$/)
  );
  return meaningful[meaningful.length - 1] || stem;
}

async function analyzeMatches(galleryProducts) {
  console.log('📈 Analyzing potential matches...\n');
  
  // Get current products from database
  const { data: dbProducts } = await supabase
    .from('products')
    .select('category, primary_image')
    .eq('status', 'active');
  
  if (dbProducts) {
    const stats = {
      total: dbProducts.length,
      withPlaceholders: dbProducts.filter(p => p.primary_image?.includes('placehold')).length,
      withOldImages: dbProducts.filter(p => p.primary_image?.includes('pub-5cd')).length,
      withNewGallery: dbProducts.filter(p => p.primary_image?.includes('8ea0502')).length
    };
    
    console.log('Current Database Status:');
    console.log(`  Total products: ${stats.total}`);
    console.log(`  With placeholders: ${stats.withPlaceholders}`);
    console.log(`  With old R2 images: ${stats.withOldImages}`);
    console.log(`  With new gallery images: ${stats.withNewGallery}`);
    console.log(`\nPotential updates: ${stats.withPlaceholders + stats.withOldImages}`);
    console.log('\nGallery CSV has ${galleryProducts.length} products to match');
  }
}

// Run the import
importGalleryImages().catch(console.error);