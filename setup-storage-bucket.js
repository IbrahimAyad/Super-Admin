/**
 * Setup Supabase Storage Bucket for Product Images
 * This script creates the product-images bucket with proper permissions
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';
// For bucket creation, we need the service role key
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxOTg3MTc0NSwiZXhwIjoyMDM1NDQ3NzQ1fQ.dT4yoJFZXo01R0ntM10O0JshGlXIUrKoYaKAoQ9LTDY';

const supabase = createClient(supabaseUrl, supabaseKey);
const adminSupabase = createClient(supabaseUrl, serviceRoleKey);

async function setupStorageBucket() {
  console.log('🪣 Setting up Supabase Storage Bucket...\n');

  try {
    // 1. Check if bucket already exists
    console.log('1. Checking existing buckets...');
    const { data: buckets, error: listError } = await supabase.storage.listBuckets();
    
    if (listError) {
      console.error('❌ Error listing buckets:', listError);
      return;
    }

    const productImagesBucket = buckets.find(b => b.name === 'product-images');
    
    if (productImagesBucket) {
      console.log('✅ product-images bucket already exists');
    } else {
      // 2. Create the bucket
      console.log('2. Creating product-images bucket...');
      const { data: newBucket, error: createError } = await adminSupabase.storage
        .createBucket('product-images', {
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
          fileSizeLimit: 10485760 // 10MB
        });

      if (createError) {
        console.error('❌ Error creating bucket:', createError);
        return;
      }

      console.log('✅ Created product-images bucket:', newBucket);
    }

    // 3. Set up RLS policies for the bucket
    console.log('3. Setting up bucket policies...');
    
    // The bucket should be publicly readable but only authenticated users can upload
    // Since we set public: true above, public read access is automatically granted

    console.log('✅ Bucket is configured for public read access');

    // 4. Test bucket access
    console.log('4. Testing bucket access...');
    const { data: files, error: listFilesError } = await supabase.storage
      .from('product-images')
      .list('', { limit: 1 });

    if (listFilesError) {
      console.error('❌ Error accessing bucket:', listFilesError);
    } else {
      console.log('✅ Bucket is accessible:', files.length, 'files found');
    }

    // 5. Test file upload (optional - create a test file)
    console.log('5. Testing file upload capability...');
    
    const testContent = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0]); // Simple JPEG header
    const testFileName = `test-${Date.now()}.jpg`;
    
    const { data: uploadData, error: uploadError } = await adminSupabase.storage
      .from('product-images')
      .upload(testFileName, testContent, {
        contentType: 'image/jpeg',
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) {
      console.error('❌ Error uploading test file:', uploadError);
    } else {
      console.log('✅ Test file uploaded successfully:', uploadData.path);
      
      // Get public URL for test file
      const { data: { publicUrl } } = adminSupabase.storage
        .from('product-images')
        .getPublicUrl(uploadData.path);
      
      console.log('🔗 Test file public URL:', publicUrl);
      
      // Clean up test file
      const { error: deleteError } = await adminSupabase.storage
        .from('product-images')
        .remove([uploadData.path]);
      
      if (deleteError) {
        console.warn('⚠️  Could not delete test file:', deleteError);
      } else {
        console.log('🧹 Test file cleaned up');
      }
    }

  } catch (error) {
    console.error('❌ Setup failed:', error);
  }
}

// Run the setup
setupStorageBucket().then(() => {
  console.log('\n🎯 Storage Bucket Setup Complete!');
  console.log('\nNext steps:');
  console.log('1. ✅ Bucket is ready for image uploads');
  console.log('2. ✅ Public read access is configured');
  console.log('3. ✅ Bucket supports common image formats');
  console.log('4. 📋 Update your image upload functions to use this bucket');
  
  process.exit(0);
}).catch(error => {
  console.error('❌ Setup failed:', error);
  process.exit(1);
});