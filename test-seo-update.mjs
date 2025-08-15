import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testSEOUpdate() {
  console.log('Testing SEO field updates...\n');
  
  try {
    // Get a sample product
    const { data: product, error: fetchError } = await supabase
      .from('products_enhanced')
      .select('*')
      .limit(1)
      .single();
    
    if (fetchError) {
      console.error('Error fetching product:', fetchError);
      return;
    }
    
    console.log(`Testing with product: ${product.name}`);
    console.log(`Current meta_title: ${product.meta_title}`);
    console.log(`Current meta_description: ${product.meta_description?.substring(0, 50)}...`);
    
    // Test updating SEO fields
    const updates = {
      meta_title: 'Test SEO Title Update - Limited Time',
      meta_description: 'Testing SEO description update functionality. This is a test to ensure the admin panel can update SEO fields correctly.',
      tags: ['test', 'seo', 'blazer', 'update'],
      sitemap_priority: 0.9,
      is_indexable: true
    };
    
    console.log('\nAttempting to update SEO fields...');
    
    const { data: updatedProduct, error: updateError } = await supabase
      .from('products_enhanced')
      .update(updates)
      .eq('id', product.id)
      .select()
      .single();
    
    if (updateError) {
      console.error('❌ Update failed:', updateError);
      return;
    }
    
    console.log('✅ SEO fields updated successfully!');
    console.log(`New meta_title: ${updatedProduct.meta_title}`);
    console.log(`New meta_description: ${updatedProduct.meta_description?.substring(0, 50)}...`);
    console.log(`New tags: ${updatedProduct.tags.join(', ')}`);
    console.log(`New sitemap_priority: ${updatedProduct.sitemap_priority}`);
    
    // Restore original values
    console.log('\nRestoring original values...');
    const { error: restoreError } = await supabase
      .from('products_enhanced')
      .update({
        meta_title: product.meta_title,
        meta_description: product.meta_description,
        tags: product.tags,
        sitemap_priority: product.sitemap_priority
      })
      .eq('id', product.id);
    
    if (!restoreError) {
      console.log('✅ Original values restored');
    }
    
    console.log('\n🎉 SEO update test completed successfully!');
    console.log('The admin panel should be able to edit SEO fields without issues.');
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testSEOUpdate();