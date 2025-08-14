// Export all products to comprehensive CSV
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import { createObjectCsvWriter } from 'csv-writer';

const supabase = createClient(
  'https://zwzkmqavnyyugxytngfk.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3emttcWF2bnl5dWd4eXRuZ2ZrIiwicm9sZSI6InNlcnZpY2UfX3JvbGUiLCJpYXQiOjE3NjgxMDY1NDUsImV4cCI6MjA4MzY4MjU0NX0.oSLw8YjmRqNoU9P-Hpkxvs0pzg88KZsBG6SssUhP_hE'
);

async function exportAllProducts() {
  console.log('📊 Exporting all products from database...\n');
  
  // Fetch all products with variants and images
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
      ),
      product_images (
        image_url,
        image_type,
        position
      )
    `)
    .eq('status', 'active')
    .order('category', { ascending: true })
    .order('name', { ascending: true });

  if (error) {
    console.error('Error fetching products:', error);
    return;
  }

  console.log(`Found ${products.length} products\n`);

  // Prepare CSV data
  const csvData = [];
  
  products.forEach(product => {
    // Get variant data
    const variant = product.product_variants?.[0] || {};
    
    // Get gallery images
    const galleryImages = product.product_images || [];
    const galleryUrls = galleryImages
      .sort((a, b) => a.position - b.position)
      .map(img => img.image_url);
    
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
    
    // Determine Stripe status
    const stripeStatus = variant.stripe_price_id ? 'Ready' : 'Missing';
    const priceFormatted = variant.price ? `$${(variant.price / 100).toFixed(2)}` : '';
    
    csvData.push({
      id: product.id,
      sku: product.sku || '',
      name: product.name,
      category: product.category,
      description: product.description?.substring(0, 200) || '',
      price: priceFormatted,
      price_cents: variant.price || 0,
      stripe_price_id: variant.stripe_price_id || '',
      stripe_status: stripeStatus,
      inventory_count: variant.inventory_count || 0,
      primary_image: product.primary_image || '',
      image_status: imageStatus,
      gallery_count: galleryImages.length,
      gallery_image_1: galleryUrls[0] || '',
      gallery_image_2: galleryUrls[1] || '',
      gallery_image_3: galleryUrls[2] || '',
      gallery_image_4: galleryUrls[3] || '',
      gallery_image_5: galleryUrls[4] || '',
      status: product.status,
      created_at: product.created_at,
      updated_at: product.updated_at,
      handle: product.handle || '',
      supplier: product.supplier || '',
      brand: product.brand || '',
      tags: product.tags?.join(', ') || '',
      variant_count: product.product_variants?.length || 0,
      variant_title: variant.title || '',
      variant_id: variant.id || ''
    });
  });

  // Create CSV writer
  const csvWriter = createObjectCsvWriter({
    path: 'FULL-PRODUCT-EXPORT.csv',
    header: [
      { id: 'id', title: 'Product ID' },
      { id: 'sku', title: 'SKU' },
      { id: 'name', title: 'Product Name' },
      { id: 'category', title: 'Category' },
      { id: 'description', title: 'Description' },
      { id: 'price', title: 'Price' },
      { id: 'price_cents', title: 'Price (Cents)' },
      { id: 'stripe_price_id', title: 'Stripe Price ID' },
      { id: 'stripe_status', title: 'Stripe Status' },
      { id: 'inventory_count', title: 'Inventory' },
      { id: 'primary_image', title: 'Primary Image URL' },
      { id: 'image_status', title: 'Image Status' },
      { id: 'gallery_count', title: 'Gallery Images' },
      { id: 'gallery_image_1', title: 'Gallery 1' },
      { id: 'gallery_image_2', title: 'Gallery 2' },
      { id: 'gallery_image_3', title: 'Gallery 3' },
      { id: 'gallery_image_4', title: 'Gallery 4' },
      { id: 'gallery_image_5', title: 'Gallery 5' },
      { id: 'status', title: 'Status' },
      { id: 'created_at', title: 'Created Date' },
      { id: 'updated_at', title: 'Updated Date' },
      { id: 'handle', title: 'URL Handle' },
      { id: 'supplier', title: 'Supplier' },
      { id: 'brand', title: 'Brand' },
      { id: 'tags', title: 'Tags' },
      { id: 'variant_count', title: 'Variant Count' },
      { id: 'variant_title', title: 'Variant Title' },
      { id: 'variant_id', title: 'Variant ID' }
    ]
  });

  // Write CSV
  await csvWriter.writeRecords(csvData);
  console.log('✅ CSV export complete: FULL-PRODUCT-EXPORT.csv\n');

  // Generate summary statistics
  const stats = {
    total: csvData.length,
    byCategory: {},
    byImageStatus: {},
    byStripeStatus: {},
    priceRange: {
      min: Math.min(...csvData.map(p => p.price_cents).filter(p => p > 0)),
      max: Math.max(...csvData.map(p => p.price_cents).filter(p => p > 0)),
      avg: csvData.reduce((sum, p) => sum + (p.price_cents || 0), 0) / csvData.length
    }
  };

  // Count by category
  csvData.forEach(product => {
    stats.byCategory[product.category] = (stats.byCategory[product.category] || 0) + 1;
    stats.byImageStatus[product.image_status] = (stats.byImageStatus[product.image_status] || 0) + 1;
    stats.byStripeStatus[product.stripe_status] = (stats.byStripeStatus[product.stripe_status] || 0) + 1;
  });

  console.log('📊 Export Summary:');
  console.log('=================');
  console.log(`Total Products: ${stats.total}`);
  console.log(`\nBy Category:`);
  Object.entries(stats.byCategory)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count}`);
    });
  
  console.log(`\nImage Status:`);
  Object.entries(stats.byImageStatus).forEach(([status, count]) => {
    console.log(`  ${status}: ${count}`);
  });
  
  console.log(`\nStripe Integration:`);
  Object.entries(stats.byStripeStatus).forEach(([status, count]) => {
    console.log(`  ${status}: ${count}`);
  });
  
  console.log(`\nPrice Range:`);
  console.log(`  Min: $${(stats.priceRange.min / 100).toFixed(2)}`);
  console.log(`  Max: $${(stats.priceRange.max / 100).toFixed(2)}`);
  console.log(`  Avg: $${(stats.priceRange.avg / 100).toFixed(2)}`);
  
  console.log('\n📁 File saved as: FULL-PRODUCT-EXPORT.csv');
  console.log('   You can open this in Excel, Google Sheets, or any spreadsheet app');
}

// Run export
exportAllProducts().catch(console.error);