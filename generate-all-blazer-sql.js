#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

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

// Function to generate SKU
function generateSKU(category, index, name) {
  const prefix = {
    'prom': 'PB',
    'velvet': 'VB',
    'summer': 'SB',
    'sparkle': 'SPB'
  }[category] || 'BL';
  
  const colorCode = name.includes('black') ? 'BLK' :
                    name.includes('navy') ? 'NVY' :
                    name.includes('burgundy') ? 'BURG' :
                    name.includes('gold') ? 'GOLD' :
                    name.includes('red') ? 'RED' :
                    name.includes('blue') ? 'BLU' :
                    name.includes('purple') ? 'PUR' :
                    name.includes('teal') ? 'TEAL' :
                    name.includes('white') ? 'WHT' :
                    'MIX';
  
  return `${prefix}-${String(index).padStart(3, '0')}-${colorCode}`;
}

// Function to determine price tier based on category and features
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
let sql = `-- AUTO-GENERATED SQL FOR ALL BLAZERS IN LOCAL FOLDERS
-- Generated from: ${localBasePath}
-- CDN URL base: ${cdnBaseUrl}
-- Generated on: ${new Date().toISOString()}

-- Clear existing blazers if needed (optional - uncomment to use)
-- DELETE FROM products_enhanced WHERE category = 'Blazers';

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
    sql += `\n-- No products found in ${category} folder\n`;
    return;
  }
  
  sql += `\n-- ${'='.repeat(44)}\n`;
  sql += `-- ${category.toUpperCase()} BLAZERS (${products.length} products)\n`;
  sql += `-- ${'='.repeat(44)}\n\n`;
  
  products.forEach((productFolder, index) => {
    productCount++;
    const productPath = path.join(categoryPath, productFolder);
    const images = fs.readdirSync(productPath).filter(f => f.endsWith('.webp'));
    
    const productName = folderToProductName(productFolder);
    const sku = generateSKU(category, index + 1, productFolder);
    const priceTier = getPriceTier(category, productFolder);
    const basePrice = getBasePrice(priceTier);
    const comparePrice = Math.floor(basePrice * 1.25);
    
    // Find main image
    const mainImage = images.find(img => img.includes('main')) || images[0];
    
    // Categorize images
    const lifestyle = images.filter(img => 
      img.includes('lifestyle') || img.includes('back') || img.includes('side')
    );
    const details = images.filter(img => 
      img.includes('close') || img.includes('detail') || img.includes('front-close')
    );
    
    sql += `-- ${productCount}. ${productName}\n`;
    sql += `INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  '${productName.replace(/'/g, "''")}',
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
  '${productFolder.includes('black') ? 'Black' :
     productFolder.includes('navy') ? 'Blue' :
     productFolder.includes('burgundy') ? 'Red' :
     productFolder.includes('gold') ? 'Gold' :
     productFolder.includes('red') ? 'Red' :
     productFolder.includes('blue') ? 'Blue' :
     productFolder.includes('purple') ? 'Purple' :
     productFolder.includes('teal') ? 'Teal' :
     productFolder.includes('white') ? 'White' :
     'Multi'}',
  '${productFolder.includes('black') ? 'Black' :
     productFolder.includes('navy') ? 'Navy' :
     productFolder.includes('burgundy') ? 'Burgundy' :
     productFolder.includes('gold') ? 'Gold' :
     productFolder.includes('red') ? 'Red' :
     productFolder.includes('blue') ? 'Blue' :
     productFolder.includes('purple') ? 'Purple' :
     productFolder.includes('teal') ? 'Teal' :
     productFolder.includes('white') ? 'White' :
     'Multi-Color'}',
  '{"primary": "${category === 'velvet' ? 'Velvet' : 'Polyester Blend'}", "composition": {"${category === 'velvet' ? 'Cotton Velvet' : 'Polyester'}": ${category === 'velvet' ? 85 : 75}, "${category === 'velvet' ? 'Silk' : 'Viscose'}": ${category === 'velvet' ? 15 : 25}}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "${cdnBaseUrl}/${category}/${productFolder}/${mainImage}",
      "alt": "${productName} - Main View"
    },
    "flat": null,
    "lifestyle": [${
      lifestyle.slice(0, 3).map(img => `
      {
        "url": "${cdnBaseUrl}/${category}/${productFolder}/${img}",
        "alt": "${productName} - ${img.replace('.webp', '').replace('-', ' ')}"
      }`).join(',')
    }
    ],
    "details": [${
      details.slice(0, 2).map(img => `
      {
        "url": "${cdnBaseUrl}/${category}/${productFolder}/${img}",
        "alt": "${productName} - ${img.replace('.webp', '').replace('-', ' ')}"
      }`).join(',')
    }
    ],
    "total_images": ${images.length}
  }'::jsonb,
  '${productName} from our ${category} collection.${
    productFolder.includes('bowtie') ? ' Includes matching bowtie.' : ''
  }',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

`;
  });
});

sql += `\n-- ${'='.repeat(44)}\n`;
sql += `-- SUMMARY\n`;
sql += `-- ${'='.repeat(44)}\n`;
sql += `-- Total products generated: ${productCount}\n`;
sql += `-- Categories: ${categories.join(', ')}\n\n`;

sql += `-- Verify all products
SELECT 
  subcategory,
  COUNT(*) as count
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY subcategory;

-- Show sample products
SELECT 
  name,
  sku,
  subcategory,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->'hero'->>'url' as hero_image
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY created_at DESC
LIMIT 10;`;

// Write SQL file
const outputPath = '/Users/ibrahim/Desktop/Super-Admin/INSERT_ALL_BLAZERS_AUTO.sql';
fs.writeFileSync(outputPath, sql);

console.log(`✅ Generated SQL for ${productCount} products`);
console.log(`📁 Categories found: ${categories.join(', ')}`);
console.log(`💾 Saved to: ${outputPath}`);

// Also create a summary
const summary = {
  totalProducts: productCount,
  categories: {},
  generated: new Date().toISOString()
};

categories.forEach(cat => {
  const products = fs.readdirSync(path.join(localBasePath, cat)).filter(f => 
    fs.statSync(path.join(localBasePath, cat, f)).isDirectory()
  );
  summary.categories[cat] = products.length;
});

console.log('\n📊 Summary:');
console.log(JSON.stringify(summary, null, 2));