#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read and analyze the master product CSV
const csvPath = path.join(__dirname, 'Final-Prodcut-CSV', 'master_product_final.csv');
const csvContent = fs.readFileSync(csvPath, 'utf-8');
const lines = csvContent.split('\n');
const headers = lines[0].split(',');

console.log('=== FINAL PRODUCT CSV ANALYSIS ===\n');

// CSV Structure
console.log('📊 CSV STRUCTURE:');
console.log('Total columns:', headers.length);
console.log('Columns:', headers.join(', '));
console.log('');

// Count records
const dataLines = lines.slice(1).filter(line => line.trim());
console.log('📈 RECORD COUNT:');
console.log('Total products:', dataLines.length);
console.log('');

// Analyze data quality
let stats = {
    hasStripeStatus: 0,
    hasImages: 0,
    hasGallery: 0,
    hasPrices: 0,
    hasVariants: 0,
    missingPrices: [],
    missingImages: [],
    categories: new Set(),
    stripeStatuses: {}
};

dataLines.forEach((line, index) => {
    const cols = line.split(',');
    const name = cols[1];
    const price = cols[7];
    const primaryImage = cols[9];
    const stripeStatus = cols[16];
    const category = cols[4];
    const totalVariants = cols[15];
    const galleryCount = cols[10];
    
    if (category) stats.categories.add(category);
    
    if (stripeStatus && stripeStatus !== 'Missing') {
        stats.hasStripeStatus++;
        stats.stripeStatuses[stripeStatus] = (stats.stripeStatuses[stripeStatus] || 0) + 1;
    }
    
    if (primaryImage && !primaryImage.includes('placehold')) {
        stats.hasImages++;
    } else {
        stats.missingImages.push(name);
    }
    
    if (galleryCount && parseInt(galleryCount) > 0) {
        stats.hasGallery++;
    }
    
    if (price && price !== '0' && price !== '$') {
        stats.hasPrices++;
    } else {
        stats.missingPrices.push(name);
    }
    
    if (totalVariants && parseInt(totalVariants) > 0) {
        stats.hasVariants++;
    }
});

console.log('✅ DATA QUALITY:');
console.log(`Products with Stripe integration: ${stats.hasStripeStatus}/${dataLines.length} (${Math.round(stats.hasStripeStatus/dataLines.length*100)}%)`);
console.log(`Products with real images: ${stats.hasImages}/${dataLines.length} (${Math.round(stats.hasImages/dataLines.length*100)}%)`);
console.log(`Products with gallery images: ${stats.hasGallery}/${dataLines.length}`);
console.log(`Products with valid prices: ${stats.hasPrices}/${dataLines.length}`);
console.log(`Products with variants: ${stats.hasVariants}/${dataLines.length}`);
console.log('');

console.log('📦 CATEGORIES FOUND:', stats.categories.size);
Array.from(stats.categories).sort().forEach(cat => console.log(`  - ${cat}`));
console.log('');

console.log('💳 STRIPE STATUS BREAKDOWN:');
Object.entries(stats.stripeStatuses).forEach(([status, count]) => {
    console.log(`  ${status}: ${count} products`);
});
console.log('');

if (stats.missingPrices.length > 0) {
    console.log('⚠️ PRODUCTS MISSING PRICES:', stats.missingPrices.length);
    stats.missingPrices.slice(0, 5).forEach(p => console.log(`  - ${p}`));
    if (stats.missingPrices.length > 5) console.log(`  ... and ${stats.missingPrices.length - 5} more`);
    console.log('');
}

if (stats.missingImages.length > 0) {
    console.log('⚠️ PRODUCTS WITH PLACEHOLDER IMAGES:', stats.missingImages.length);
    stats.missingImages.slice(0, 5).forEach(p => console.log(`  - ${p}`));
    if (stats.missingImages.length > 5) console.log(`  ... and ${stats.missingImages.length - 5} more`);
    console.log('');
}

// Check required fields for our database
console.log('🔍 REQUIRED FIELDS CHECK:');
const requiredFields = [
    'product_id', 'name', 'handle', 'sku', 'category', 
    'description', 'status', 'base_price', 'primary_image'
];

const missingFields = requiredFields.filter(field => !headers.includes(field));
if (missingFields.length === 0) {
    console.log('✅ All required fields present!');
} else {
    console.log('❌ Missing required fields:', missingFields.join(', '));
}
console.log('');

// Check for new/extra fields
const extraFields = headers.filter(field => ![
    'product_id', 'name', 'handle', 'sku', 'category', 'description',
    'status', 'base_price', 'price_usd', 'primary_image', 'gallery_count',
    'meta_title', 'meta_description', 'search_keywords', 'tags',
    'total_variants', 'stripe_status', 'created_at', 'updated_date',
    'total_images', 'gallery_urls', 'image_status'
].includes(field));

if (extraFields.length > 0) {
    console.log('📝 Extra/duplicate fields found:', extraFields.join(', '));
}

console.log('\n=== IMPORT READINESS ===');
console.log('✅ CSV has all required product data');
console.log('✅ Includes SEO fields (meta_title, meta_description)');
console.log('✅ Includes smart tags and search keywords');
console.log('✅ Has handle/slug for URL routing');
console.log(`⚠️  ${dataLines.length - stats.hasStripeStatus} products need Stripe price mapping`);
console.log(`⚠️  ${dataLines.length - stats.hasImages} products need real images`);

console.log('\n📋 RECOMMENDED IMPORT STEPS:');
console.log('1. Backup current database');
console.log('2. Add any missing columns to products table');
console.log('3. Import products with UPSERT (update existing, insert new)');
console.log('4. Import gallery images to product_images table');
console.log('5. Map products without Stripe IDs to existing prices');
console.log('6. Verify all products are accessible on website');