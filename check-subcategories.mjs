import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkSubcategories() {
  console.log('Checking product subcategories...\n');
  
  // Get all unique subcategories
  const { data, error } = await supabase
    .from('products_enhanced')
    .select('subcategory, category');
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  // Count by subcategory
  const subcategoryCount = {};
  const categoryCount = {};
  
  data.forEach(product => {
    const sub = product.subcategory || 'No Subcategory';
    const cat = product.category || 'No Category';
    
    subcategoryCount[sub] = (subcategoryCount[sub] || 0) + 1;
    categoryCount[cat] = (categoryCount[cat] || 0) + 1;
  });
  
  console.log('Categories:');
  Object.entries(categoryCount).forEach(([cat, count]) => {
    console.log(`  ${cat}: ${count} products`);
  });
  
  console.log('\nSubcategories:');
  Object.entries(subcategoryCount).forEach(([sub, count]) => {
    console.log(`  ${sub}: ${count} products`);
  });
  
  // Check a few products with their images
  console.log('\nSample products with images:');
  const { data: samples } = await supabase
    .from('products_enhanced')
    .select('name, subcategory, images')
    .limit(5);
  
  samples?.forEach(product => {
    console.log(`\n${product.name}`);
    console.log(`  Subcategory: ${product.subcategory || 'None'}`);
    if (product.images?.hero?.url) {
      console.log(`  Hero Image: ${product.images.hero.url}`);
    }
  });
}

checkSubcategories();