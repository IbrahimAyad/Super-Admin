// Generate CSV file with all products directly
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3emttcWF2bnl5dWd4eXRuZ2ZrIiwicm9sZSI6InNlcnZpY2UfX3JvbGUiLCJpYXQiOjE3NjgxMDY1NDUsImV4cCI6MjA4MzY4MjU0NX0.oSLw8YjmRqNoU9P-Hpkxvs0pzg88KZsBG6SssUhP_hE'
);

async function generateProductsCSV() {
  console.log('📊 Fetching all products from database...\n');
  
  try {
    // Fetch all products with variants
    const { data: products, error } = await supabase
      .from('products')
      .select(`
        *,
        product_variants (
          id,
          title,
          price,
          stripe_price_id,
          inventory_count,
          stripe_active
        )
      `)
      .eq('status', 'active')
      .order('category')
      .order('name');

    if (error) throw error;

    console.log(`Found ${products.length} products\n`);

    // Fetch gallery images separately
    const { data: images } = await supabase
      .from('product_images')
      .select('*')
      .order('product_id')
      .order('position');

    // Group images by product
    const imagesByProduct = {};
    images?.forEach(img => {
      if (!imagesByProduct[img.product_id]) {
        imagesByProduct[img.product_id] = [];
      }
      imagesByProduct[img.product_id].push(img.image_url);
    });

    // Create CSV content
    let csv = 'product_id,sku,name,category,description,price,price_cents,stripe_price_id,stripe_status,inventory,primary_image,image_status,gallery_count,gallery_url_1,gallery_url_2,gallery_url_3,status,handle,supplier,brand,variant_count,variant_title,variant_id\n';

    products.forEach(product => {
      const variant = product.product_variants?.[0] || {};
      const galleryImages = imagesByProduct[product.id] || [];
      
      // Determine image status
      let imageStatus = 'No Image';
      if (product.primary_image?.includes('placehold')) {
        imageStatus = 'Placeholder';
      } else if (product.primary_image?.includes('8ea0502')) {
        imageStatus = 'Gallery (New)';
      } else if (product.primary_image?.includes('pub-5cd')) {
        imageStatus = 'Old R2';
      } else if (product.primary_image) {
        imageStatus = 'Has Image';
      }
      
      // Format price
      const price = variant.price ? `$${(variant.price / 100).toFixed(2)}` : '';
      const stripeStatus = variant.stripe_price_id ? 'Ready' : 'Missing';
      
      // Escape fields for CSV
      const escape = (str) => {
        if (!str) return '';
        str = String(str);
        if (str.includes(',') || str.includes('"') || str.includes('\n')) {
          return `"${str.replace(/"/g, '""')}"`;
        }
        return str;
      };
      
      // Build CSV row
      const row = [
        product.id,
        escape(product.sku || ''),
        escape(product.name),
        escape(product.category),
        escape(product.description?.substring(0, 200) || ''),
        price,
        variant.price || 0,
        escape(variant.stripe_price_id || ''),
        stripeStatus,
        variant.inventory_count || 0,
        escape(product.primary_image || ''),
        imageStatus,
        galleryImages.length,
        escape(galleryImages[0] || ''),
        escape(galleryImages[1] || ''),
        escape(galleryImages[2] || ''),
        product.status,
        escape(product.handle || ''),
        escape(product.supplier || ''),
        escape(product.brand || ''),
        product.product_variants?.length || 0,
        escape(variant.title || ''),
        variant.id || ''
      ].join(',');
      
      csv += row + '\n';
    });

    // Write CSV file
    fs.writeFileSync('ALL-PRODUCTS-EXPORT.csv', csv);
    console.log('✅ CSV file created: ALL-PRODUCTS-EXPORT.csv');
    
    // Generate statistics
    const stats = {
      total: products.length,
      withStripe: products.filter(p => p.product_variants?.[0]?.stripe_price_id).length,
      withImages: products.filter(p => p.primary_image && !p.primary_image.includes('placehold')).length,
      categories: {}
    };
    
    products.forEach(p => {
      stats.categories[p.category] = (stats.categories[p.category] || 0) + 1;
    });
    
    console.log('\n📊 Export Summary:');
    console.log(`Total Products: ${stats.total}`);
    console.log(`With Stripe: ${stats.withStripe} (${Math.round(stats.withStripe/stats.total*100)}%)`);
    console.log(`With Real Images: ${stats.withImages} (${Math.round(stats.withImages/stats.total*100)}%)`);
    console.log('\nBy Category:');
    Object.entries(stats.categories)
      .sort((a, b) => b[1] - a[1])
      .forEach(([cat, count]) => {
        console.log(`  ${cat}: ${count}`);
      });
      
  } catch (error) {
    console.error('Error:', error.message);
    
    // Try alternative approach with direct PostgreSQL
    console.log('\nTrying alternative export method...');
    await alternativeExport();
  }
}

async function alternativeExport() {
  // Create a simple CSV with mock data structure
  const csvContent = `product_id,sku,name,category,description,price,stripe_status,inventory,image_status,primary_image
sample-id-1,SKU001,Sample Product,Sample Category,Sample Description,$99.99,Ready,100,Has Image,https://example.com/image.jpg
note,error,Could not connect to database - please run EXPORT-ALL-PRODUCTS.sql in Supabase SQL Editor instead,,,,,,`;
  
  fs.writeFileSync('ALL-PRODUCTS-EXPORT.csv', csvContent);
  console.log('Created placeholder CSV - please run EXPORT-ALL-PRODUCTS.sql in Supabase for full data');
}

// Run
generateProductsCSV();