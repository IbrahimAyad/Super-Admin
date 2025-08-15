#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Base paths
const localBasePath = '/Users/ibrahim/Desktop/Super-Admin/ENHANCED-PRODCUTS/blazers';
const cdnBaseUrl = 'https://cdn.kctmenswear.com/blazers';

// Function to convert folder name to product name
function folderToProductName(folderName) {
  return folderName
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
    .replace('Mens ', "Men's ");
}

// Function to escape strings for SQL
function escapeSql(str) {
  return str.replace(/'/g, "''");
}

// Function to escape strings for JSON inside SQL
function escapeJson(str) {
  return str.replace(/'/g, "").replace(/"/g, '\\"');
}

// Function to generate SKU
function generateSKU(category, index, name) {
  const prefix = {
    'prom': 'PB',
    'velvet': 'VB', 
    'summer': 'SB',
    'sparkle': 'SPB'
  }[category] || 'BL';
  
  // Make SKU more unique by including more of the name
  const namePart = name
    .replace(/mens-/, '')
    .split('-')
    .slice(0, 3)
    .map(w => w.substring(0, 2).toUpperCase())
    .join('');
  
  return `${prefix}-${namePart}-${String(index).padStart(3, '0')}`;
}

// Function to determine price tier
function getPriceTier(category, name) {
  if (name.includes('glitter') || name.includes('embellished') || name.includes('rhinestone')) {
    return 'TIER_8';
  }
  if (category === 'velvet') {
    return name.includes('burgundy') ? 'TIER_9' : 'TIER_8';
  }
  if (category === 'prom') {
    return name.includes('bowtie') ? 'TIER_6' : 'TIER_7';
  }
  if (category === 'summer') {
    return 'TIER_6';
  }
  if (category === 'sparkle') {
    return 'TIER_8';
  }
  return 'TIER_7';
}

// Function to get base price from tier
function getBasePrice(tier) {
  const prices = {
    'TIER_6': 22999,  // $229.99
    'TIER_7': 27999,  // $279.99
    'TIER_8': 34999,  // $349.99
    'TIER_9': 39999,  // $399.99
  };
  return prices[tier] || 27999;
}

// Start SQL generation
let sql = `-- UPSERT ALL BLAZERS WITH HANDLE CONFLICT RESOLUTION
-- Generated on: ${new Date().toISOString()}
-- This handles duplicates by updating existing products

-- Check current state
SELECT 'Before Insert' as status, COUNT(*) as blazer_count 
FROM products_enhanced WHERE category = 'Blazers';

`;

// Read all category folders
const categories = fs.readdirSync(localBasePath).filter(f => 
  fs.statSync(path.join(localBasePath, f)).isDirectory()
);

let productCount = 0;

categories.forEach(category => {
  const categoryPath = path.join(localBasePath, category);
  const products = fs.readdirSync(categoryPath).filter(f => 
    fs.statSync(path.join(categoryPath, f)).isDirectory()
  );
  
  if (products.length === 0) {
    return;
  }
  
  sql += `\n-- ${category.toUpperCase()} BLAZERS (${products.length} products)\n`;
  
  products.forEach((productFolder, index) => {
    productCount++;
    const productPath = path.join(categoryPath, productFolder);
    const images = fs.readdirSync(productPath).filter(f => f.endsWith('.webp'));
    
    const productName = folderToProductName(productFolder);
    const productNameSql = escapeSql(productName);
    const productNameJson = escapeJson(productName);
    
    const sku = generateSKU(category, index + 1, productFolder);
    const priceTier = getPriceTier(category, productFolder);
    const basePrice = getBasePrice(priceTier);
    const comparePrice = Math.floor(basePrice * 1.25);
    
    // Find main image
    const mainImage = images.find(img => img.includes('main')) || images[0] || 'main.webp';
    
    // Categorize images
    const lifestyle = images.filter(img => 
      (img.includes('lifestyle') || img.includes('back') || img.includes('side')) && !img.includes('close')
    );
    const details = images.filter(img => 
      img.includes('close') || img.includes('detail') || img.includes('front-close')
    );
    
    // Determine color
    const colorFamily = productFolder.includes('black') ? 'Black' :
                       productFolder.includes('navy') ? 'Blue' :
                       productFolder.includes('burgundy') ? 'Red' :
                       productFolder.includes('gold') ? 'Gold' :
                       productFolder.includes('red') ? 'Red' :
                       productFolder.includes('blue') ? 'Blue' :
                       productFolder.includes('purple') ? 'Purple' :
                       productFolder.includes('teal') ? 'Teal' :
                       productFolder.includes('white') ? 'White' :
                       productFolder.includes('silver') ? 'Silver' :
                       productFolder.includes('pink') ? 'Pink' :
                       'Multi';
    
    const colorName = productFolder.includes('black') ? 'Black' :
                     productFolder.includes('navy') ? 'Navy' :
                     productFolder.includes('burgundy') ? 'Burgundy' :
                     productFolder.includes('gold') ? 'Gold' :
                     productFolder.includes('red') && !productFolder.includes('burgundy') ? 'Red' :
                     productFolder.includes('royal-blue') ? 'Royal Blue' :
                     productFolder.includes('blue') && !productFolder.includes('royal') ? 'Blue' :
                     productFolder.includes('purple') ? 'Purple' :
                     productFolder.includes('teal') ? 'Teal' :
                     productFolder.includes('white') && !productFolder.includes('off') ? 'White' :
                     productFolder.includes('off-white') ? 'Off White' :
                     productFolder.includes('silver') ? 'Silver' :
                     productFolder.includes('pink') ? 'Pink' :
                     'Multi-Color';
    
    sql += `\n-- ${productCount}. ${productName}\n`;
    sql += `INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  '${productNameSql}',
  '${sku}',
  '${productFolder}',
  '${productFolder}',
  '${category.toUpperCase()}24-${String(index + 1).padStart(3, '0')}',
  '${category === 'summer' ? 'SS24' : 'FW24'}',
  '${category === 'prom' ? 'Prom Collection 2024' : 
     category === 'velvet' ? 'Velvet Collection' :
     category === 'sparkle' ? 'Sparkle Collection' :
     'Summer Collection'}',
  'Blazers',
  '${category.charAt(0).toUpperCase() + category.slice(1)}',
  '${priceTier}',
  ${basePrice},
  ${comparePrice},
  '${colorFamily}',
  '${colorName}',
  '{"primary": "${category === 'velvet' ? 'Velvet' : category === 'sparkle' ? 'Sparkle Fabric' : 'Polyester Blend'}", "composition": {"${category === 'velvet' ? 'Cotton Velvet' : 'Polyester'}": ${category === 'velvet' ? 85 : 75}, "${category === 'velvet' ? 'Silk' : category === 'sparkle' ? 'Metallic Fiber' : 'Viscose'}": ${category === 'velvet' ? 15 : category === 'sparkle' ? 25 : 25}}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "${cdnBaseUrl}/${category}/${productFolder}/${mainImage}",
      "alt": "${productNameJson} - Main View"
    },
    "flat": null,
    "lifestyle": [${
      lifestyle.slice(0, 3).map(img => `
      {
        "url": "${cdnBaseUrl}/${category}/${productFolder}/${img}",
        "alt": "${productNameJson} - ${img.replace('.webp', '').replace(/-/g, ' ')}"
      }`).join(',')
    }
    ],
    "details": [${
      details.slice(0, 2).map(img => `
      {
        "url": "${cdnBaseUrl}/${category}/${productFolder}/${img}",
        "alt": "${productNameJson} - ${img.replace('.webp', '').replace(/-/g, ' ')}"
      }`).join(',')
    }
    ],
    "total_images": ${images.length}
  }'::jsonb,
  '${escapeSql(productName)} from our ${category} collection.${
    productFolder.includes('bowtie') ? ' Includes matching bowtie.' : ''
  }',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
  slug = EXCLUDED.slug,
  style_code = EXCLUDED.style_code,
  season = EXCLUDED.season,
  collection = EXCLUDED.collection,
  subcategory = EXCLUDED.subcategory,
  price_tier = EXCLUDED.price_tier,
  base_price = EXCLUDED.base_price,
  compare_at_price = EXCLUDED.compare_at_price,
  color_family = EXCLUDED.color_family,
  color_name = EXCLUDED.color_name,
  materials = EXCLUDED.materials,
  fit_type = EXCLUDED.fit_type,
  images = EXCLUDED.images,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  updated_at = NOW();

`;
  });
});

sql += `\n-- SUMMARY\n`;
sql += `-- Total products: ${productCount}\n\n`;

sql += `-- Verify results
SELECT 'After Insert' as status, COUNT(*) as blazer_count 
FROM products_enhanced WHERE category = 'Blazers';

SELECT 
  subcategory,
  COUNT(*) as count
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY subcategory;

-- Show sample of products
SELECT 
  name,
  sku,
  handle,
  subcategory,
  price_tier,
  images->'hero'->>'url' as hero_image
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY updated_at DESC
LIMIT 10;`;

// Write SQL file
const outputPath = '/Users/ibrahim/Desktop/Super-Admin/UPSERT_ALL_BLAZERS_FINAL.sql';
fs.writeFileSync(outputPath, sql);

console.log(`✅ Generated UPSERT SQL for ${productCount} products`);
console.log(`📁 Categories: ${categories.join(', ')}`);
console.log(`💾 Saved to: ${outputPath}`);
console.log('\n⚠️  This version uses ON CONFLICT (handle) to avoid duplicate errors');
console.log('✅ Existing products will be updated, new ones will be inserted');