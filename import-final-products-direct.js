import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config();

// Initialize Supabase client
const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY // You'll need to add this to your .env
);

// Parse CSV
function parseCSV(content) {
  const lines = content.split('\n');
  const headers = lines[0].split(',').map(h => h.trim());
  const data = [];
  
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    
    const values = lines[i].split(',');
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index]?.trim() || '';
    });
    data.push(row);
  }
  
  return data;
}

// Main import function
async function importProducts() {
  console.log('🚀 Starting product import...\n');
  
  // Read CSV file
  const csvPath = path.join(__dirname, 'Final-Prodcut-CSV', 'master_product_final.csv');
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const products = parseCSV(csvContent);
  
  console.log(`📊 Found ${products.length} products to import\n`);
  
  // Stats
  let imported = 0;
  let updated = 0;
  let errors = 0;
  
  // Process each product
  for (const csvProduct of products) {
    try {
      // Prepare product data
      const productData = {
        id: csvProduct.product_id,
        name: csvProduct.name,
        handle: csvProduct.handle || csvProduct.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        sku: csvProduct.sku,
        category: csvProduct.category,
        description: csvProduct.description,
        status: csvProduct.status || 'active',
        base_price: csvProduct.base_price === '0' ? null : parseInt(csvProduct.base_price),
        primary_image: csvProduct.primary_image?.includes('placehold') ? null : csvProduct.primary_image,
        meta_title: csvProduct.meta_title,
        meta_description: csvProduct.meta_description,
        search_keywords: csvProduct.search_keywords,
        tags: csvProduct.tags ? csvProduct.tags.split(',').map(t => t.trim()) : []
      };
      
      // Check if product exists
      const { data: existing } = await supabase
        .from('products')
        .select('id')
        .eq('id', productData.id)
        .single();
      
      if (existing) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update(productData)
          .eq('id', productData.id);
        
        if (error) throw error;
        updated++;
        console.log(`✅ Updated: ${productData.name}`);
      } else {
        // Insert new product
        const { error } = await supabase
          .from('products')
          .insert(productData);
        
        if (error) throw error;
        imported++;
        console.log(`✅ Imported: ${productData.name}`);
      }
      
      // Import gallery images if present
      if (csvProduct.gallery_urls && csvProduct.gallery_urls !== 'nan') {
        const imageUrls = csvProduct.gallery_urls.split(';').filter(url => url.trim());
        
        if (imageUrls.length > 0) {
          // Delete existing gallery images
          await supabase
            .from('product_images')
            .delete()
            .eq('product_id', productData.id);
          
          // Insert new gallery images
          const galleryImages = imageUrls.map((url, index) => ({
            product_id: productData.id,
            image_url: url.trim(),
            position: index + 1,
            alt_text: productData.name
          }));
          
          const { error: imageError } = await supabase
            .from('product_images')
            .insert(galleryImages);
          
          if (imageError) {
            console.log(`⚠️ Gallery images failed for ${productData.name}:`, imageError.message);
          }
        }
      }
      
      // Create variants for the product
      const sizes = getSizesForCategory(csvProduct.category);
      if (sizes.length > 0) {
        const variants = sizes.map(size => ({
          product_id: productData.id,
          size: size,
          color: 'Default',
          sku: `${csvProduct.sku}-${size}`,
          price: productData.base_price,
          inventory_quantity: 100,
          stripe_active: false
        }));
        
        // Insert variants (ignore conflicts)
        for (const variant of variants) {
          await supabase
            .from('product_variants')
            .upsert(variant, { 
              onConflict: 'product_id,size,color',
              ignoreDuplicates: true 
            });
        }
      }
      
    } catch (error) {
      errors++;
      console.error(`❌ Error with ${csvProduct.name}:`, error.message);
    }
  }
  
  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 IMPORT SUMMARY:');
  console.log(`✅ New products imported: ${imported}`);
  console.log(`🔄 Existing products updated: ${updated}`);
  console.log(`❌ Errors: ${errors}`);
  console.log(`📦 Total processed: ${imported + updated}/${products.length}`);
  console.log('='.repeat(50));
  
  // Map Stripe prices
  console.log('\n💳 Mapping Stripe prices...');
  await mapStripePrices();
  
  console.log('\n✅ Import complete!');
}

// Get sizes based on category
function getSizesForCategory(category) {
  const sizeMap = {
    "Men's Suits": ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R'],
    'Blazers': ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R'],
    'Tuxedos': ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R'],
    'Luxury Velvet Blazers': ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'],
    'Prom & Formal Blazers': ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'],
    'Sparkle & Sequin Blazers': ['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'],
    'Casual Summer Blazers': ['S', 'M', 'L', 'XL', '2XL', '3XL'],
    "Men's Dress Shirts": ['S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'],
    'Vest & Tie Sets': ['S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL', '7XL'],
    'Shoes': ['7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12', '13'],
    'Kids Formal Wear': ['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14', '16'],
    'Accessories': ['One Size']
  };
  
  return sizeMap[category] || ['S', 'M', 'L', 'XL', '2XL'];
}

// Map Stripe prices
async function mapStripePrices() {
  const priceMap = {
    2499: 'price_1RpvHlCHc12x7sCzp0TVNS92',  // Ties
    3999: 'price_1RpvWnCHc12x7sCzzioA64qD',  // Shirts
    4999: 'price_1RpvfvCHc12x7sCzHBGgtQOl',  // Vests/Suspenders
    5999: 'price_1RpvfvCHc12x7sCzUeYkF7Qp',  // Sparkle vests
    6500: 'price_1RpvfvCHc12x7sCzKlmnOP89',  // Premium vests
    17999: 'price_1Rpv2tCHc12x7sCzVvLRto3m', // 2-piece suit
    22999: 'price_1Rpv31CHc12x7sCzlFtlUflr', // 3-piece suit
    24999: 'price_1RpvfvCHc12x7sCzq1jYfG9o', // Blazers
    29999: 'price_1RpvfvCHc12x7sCzq1jYfG9o'  // Maps to $299.99
  };
  
  let updated = 0;
  
  for (const [price, stripeId] of Object.entries(priceMap)) {
    const { data, error } = await supabase
      .from('product_variants')
      .update({
        stripe_price_id: stripeId,
        stripe_active: true
      })
      .eq('price', parseInt(price))
      .is('stripe_price_id', null);
    
    if (!error && data) {
      updated += data.length;
    }
  }
  
  console.log(`✅ Mapped Stripe prices for ${updated} variants`);
}

// Run import
importProducts().catch(console.error);