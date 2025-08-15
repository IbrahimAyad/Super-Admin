import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testEnhancedProducts() {
  console.log('Testing Enhanced Products System...\n');
  
  try {
    // 1. Count total products
    const { data: allProducts, error: countError } = await supabase
      .from('products_enhanced')
      .select('*');
    
    if (countError) {
      console.error('Error fetching products:', countError);
      console.error('Details:', countError.message, countError.code, countError.details);
      return;
    }
    
    const totalCount = allProducts?.length || 0;
    
    console.log(`✅ Total products in database: ${totalCount}`);
    
    // 2. Check products by subcategory
    const subcategories = ['prom', 'velvet', 'summer', 'sparkle'];
    for (const sub of subcategories) {
      const { data, error } = await supabase
        .from('products_enhanced')
        .select('name, sku')
        .eq('subcategory', sub);
      
      if (!error) {
        console.log(`   - ${sub}: ${data.length} products`);
      }
    }
    
    // 3. Check SEO fields
    console.log('\n📝 Checking SEO fields...');
    const { data: seoData, error: seoError } = await supabase
      .from('products_enhanced')
      .select('name, meta_title, meta_description, tags, og_image')
      .limit(3);
    
    if (!seoError && seoData) {
      seoData.forEach(product => {
        console.log(`\n   Product: ${product.name}`);
        console.log(`   - Meta Title: ${product.meta_title ? '✅' : '❌'} ${product.meta_title || 'Not set'}`);
        console.log(`   - Meta Desc: ${product.meta_description ? '✅' : '❌'} ${product.meta_description ? product.meta_description.substring(0, 50) + '...' : 'Not set'}`);
        console.log(`   - Tags: ${product.tags && product.tags.length > 0 ? '✅' : '❌'} ${product.tags ? product.tags.join(', ') : 'None'}`);
        console.log(`   - OG Image: ${product.og_image ? '✅' : '❌'} ${product.og_image ? 'Set' : 'Not set'}`);
      });
    }
    
    // 4. Check images
    console.log('\n🖼️  Checking product images...');
    const { data: imageData, error: imageError } = await supabase
      .from('products_enhanced')
      .select('name, images')
      .limit(5);
    
    if (!imageError && imageData) {
      let totalImages = 0;
      let productsWithImages = 0;
      
      imageData.forEach(product => {
        const imageCount = product.images?.total_images || 0;
        totalImages += imageCount;
        if (imageCount > 0) productsWithImages++;
        console.log(`   - ${product.name}: ${imageCount} images`);
      });
      
      console.log(`\n   Summary: ${productsWithImages}/${imageData.length} products have images`);
    }
    
    // 5. Test a sample image URL
    console.log('\n🔗 Testing sample image URL...');
    const { data: sampleProduct } = await supabase
      .from('products_enhanced')
      .select('name, images')
      .not('images->hero', 'is', null)
      .limit(1)
      .single();
    
    if (sampleProduct && sampleProduct.images?.hero?.url) {
      console.log(`   Testing: ${sampleProduct.images.hero.url}`);
      try {
        const response = await fetch(sampleProduct.images.hero.url, { method: 'HEAD' });
        if (response.ok) {
          console.log(`   ✅ Image URL is accessible (Status: ${response.status})`);
        } else {
          console.log(`   ❌ Image URL returned status: ${response.status}`);
        }
      } catch (e) {
        console.log(`   ❌ Could not fetch image: ${e.message}`);
      }
    }
    
    console.log('\n✨ Test complete!');
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testEnhancedProducts();