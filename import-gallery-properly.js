// Properly distribute all 205 gallery images to products
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import csv from 'csv-parser';

const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3emttcWF2bnl5dWd4eXRuZ2ZrIiwicm9sZSI6InNlcnZpY2UfX3JvbGUiLCJpYXQiOjE3NjgxMDY1NDUsImV4cCI6MjA4MzY4MjU0NX0.oSLw8YjmRqNoU9P-Hpkxvs0pzg88KZsBG6SssUhP_hE'
);

async function distributeGalleryImages() {
  console.log('📊 Loading gallery images from CSV...\n');
  
  // Load gallery images
  const galleryImages = await loadCSV('./product_gallery-Super-Admin.csv');
  console.log(`Found ${galleryImages.length} unique gallery products\n`);
  
  // Get products that need images
  const { data: productsNeedingImages } = await supabase
    .from('products')
    .select('id, name, category, sku')
    .eq('status', 'active')
    .or('primary_image.like.%placehold%,primary_image.like.%pub-5cd%')
    .order('category', { ascending: true });
  
  console.log(`Found ${productsNeedingImages?.length || 0} products needing images\n`);
  
  // Map gallery images to product categories
  const imagesByCategory = {
    'Luxury Velvet Blazers': [],
    'Sparkle & Sequin Blazers': [],
    'Prom & Formal Blazers': [],
    'Vest & Tie Sets': [],
    'Men\'s Suits': [],
    'Men\'s Dress Shirts': [],
    'Tuxedos': [],
    'Accessories': [],
    'Casual Summer Blazers': [],
    'Blazers': [],
    'Kids Formal Wear': []
  };
  
  // Organize gallery images by type
  galleryImages.forEach(img => {
    if (img.folder === 'folder') return; // Skip header
    
    const mainImage = img.main_image_url;
    const galleryUrls = img.gallery_urls ? img.gallery_urls.split(';') : [];
    
    // Categorize based on folder/product type
    if (img.folder.includes('velvet')) {
      imagesByCategory['Luxury Velvet Blazers'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('sparkle')) {
      imagesByCategory['Sparkle & Sequin Blazers'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('prom')) {
      imagesByCategory['Prom & Formal Blazers'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('vest') || img.folder.includes('tie')) {
      imagesByCategory['Vest & Tie Sets'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('suit') || img.folder.includes('double_breasted')) {
      imagesByCategory['Men\'s Suits'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('shirt')) {
      imagesByCategory['Men\'s Dress Shirts'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('tuxedo')) {
      imagesByCategory['Tuxedos'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('suspender') || img.folder.includes('bowtie')) {
      imagesByCategory['Accessories'].push({ main: mainImage, gallery: galleryUrls });
    }
    if (img.folder.includes('summer')) {
      imagesByCategory['Casual Summer Blazers'].push({ main: mainImage, gallery: galleryUrls });
    }
  });
  
  // Generate SQL with proper distribution
  let sql = `-- PROPERLY DISTRIBUTED GALLERY IMAGES
-- Each product gets a UNIQUE image from the gallery CSV

BEGIN;

-- Clear previous gallery attempts
DELETE FROM product_images 
WHERE image_url LIKE '%8ea0502%';

`;

  // Track which images have been used
  const usedImages = new Set();
  
  // Process each category
  for (const [category, images] of Object.entries(imagesByCategory)) {
    if (images.length === 0) continue;
    
    const categoryProducts = productsNeedingImages?.filter(p => p.category === category) || [];
    console.log(`${category}: ${images.length} images for ${categoryProducts.length} products`);
    
    let imageIndex = 0;
    
    categoryProducts.forEach((product, productIndex) => {
      // Get next unused image, cycling through if needed
      const image = images[imageIndex % images.length];
      imageIndex++;
      
      // Skip if this exact image was already used
      if (!usedImages.has(image.main)) {
        usedImages.add(image.main);
        
        // Update primary image
        sql += `
-- Update ${product.name}
UPDATE products
SET primary_image = '${image.main}'
WHERE id = '${product.id}';

`;
        
        // Add gallery images
        if (image.gallery.length > 0) {
          image.gallery.forEach((galleryUrl, idx) => {
            sql += `INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
VALUES ('${product.id}', '${galleryUrl}', '${idx === 0 ? 'primary' : 'gallery'}', ${idx + 1}, '${product.name.replace(/'/g, "''")} - View ${idx + 1}')
ON CONFLICT DO NOTHING;

`;
          });
        }
      }
    });
  }
  
  sql += `
-- Verify results
SELECT 
    'DISTRIBUTION COMPLETE' as status,
    COUNT(DISTINCT primary_image) as unique_images_used,
    COUNT(*) as total_products_updated
FROM products
WHERE primary_image LIKE '%8ea0502%'
    AND status = 'active';

-- Check by category
SELECT 
    category,
    COUNT(*) as total,
    COUNT(DISTINCT primary_image) as unique_images
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%8ea0502%'
GROUP BY category
ORDER BY total DESC;

COMMIT;`;

  // Save SQL
  fs.writeFileSync('DISTRIBUTE-GALLERY-IMAGES.sql', sql);
  console.log('\n✅ Generated DISTRIBUTE-GALLERY-IMAGES.sql');
  console.log(`📊 Will update ${usedImages.size} products with unique images`);
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

// Run
distributeGalleryImages().catch(console.error);