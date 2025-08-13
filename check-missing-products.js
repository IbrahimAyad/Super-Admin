import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkMissingProducts() {
  // Read CSV
  const csvContent = fs.readFileSync('sql/imports/products_main_urls.csv', 'utf8');
  const lines = csvContent.split('\n').filter(line => line.trim());
  
  // Parse CSV products
  const csvProducts = new Map();
  const productTypes = new Map();
  
  lines.forEach(line => {
    const parts = line.split(',');
    if (parts[0] && parts[0] !== 'product_slug') {
      const slug = parts[0];
      const name = parts[1] || '';
      
      // Categorize by type
      let type = 'other';
      if (slug.includes('vest') && slug.includes('tie')) type = 'vest-tie-sets';
      else if (slug.includes('suit')) type = 'suits';
      else if (slug.includes('suspender')) type = 'suspenders';
      else if (slug.includes('shoe') || slug.includes('boot')) type = 'shoes';
      else if (slug.includes('tuxedo')) type = 'tuxedos';
      else if (slug.includes('dress-shirt')) type = 'dress-shirts';
      else if (slug.includes('turtleneck')) type = 'turtlenecks';
      else if (slug.includes('jacket')) type = 'jackets';
      else if (slug.includes('bowtie')) type = 'bowties';
      else if (slug.includes('cummerband')) type = 'cummerbunds';
      else if (slug.includes('sweater')) type = 'sweaters';
      else if (slug.includes('wedding-dress')) type = 'wedding-dresses';
      
      csvProducts.set(slug, { name, type });
      productTypes.set(type, (productTypes.get(type) || 0) + 1);
    }
  });
  
  console.log('CSV Product Analysis:');
  console.log('Total products in CSV:', csvProducts.size);
  console.log('\nBreakdown by type:');
  [...productTypes.entries()]
    .sort((a, b) => b[1] - a[1])
    .forEach(([type, count]) => {
      console.log(`  ${type}: ${count}`);
    });
  
  // Check what's in database
  const { data: dbProducts, error } = await supabase
    .from('products')
    .select('sku, name, category')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching products:', error);
    return;
  }
  
  const dbCategories = new Map();
  dbProducts.forEach(p => {
    const cat = p.category || 'Uncategorized';
    dbCategories.set(cat, (dbCategories.get(cat) || 0) + 1);
  });
  
  console.log('\nDatabase Product Summary:');
  console.log('Total products in database:', dbProducts.length);
  console.log('\nBreakdown by category:');
  [...dbCategories.entries()]
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count}`);
    });
  
  // Find missing product types
  console.log('\n=== PRODUCTS STILL TO IMPORT ===');
  const missingTypes = ['tuxedos', 'dress-shirts', 'turtlenecks', 'jackets', 'bowties', 'cummerbunds', 'sweaters'];
  
  missingTypes.forEach(type => {
    const count = productTypes.get(type) || 0;
    if (count > 0) {
      console.log(`\n${type.toUpperCase()}: ${count} products`);
      
      // Show sample products
      let shown = 0;
      csvProducts.forEach((product, slug) => {
        if (product.type === type && shown < 3) {
          console.log(`  - ${product.name || slug}`);
          shown++;
        }
      });
    }
  });
  
  console.log('\n=== SUMMARY ===');
  const totalImported = dbProducts.length;
  const totalInCSV = csvProducts.size;
  const remaining = Math.max(0, totalInCSV - totalImported);
  
  console.log(`Products in CSV: ${totalInCSV}`);
  console.log(`Products in Database: ${totalImported}`);
  console.log(`Approximate remaining to import: ${remaining}`);
}

checkMissingProducts().catch(console.error);