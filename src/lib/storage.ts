import { supabase } from './supabase-client';

export interface UploadResult {
  url: string;
  path: string;
  error?: string;
}

/**
 * Upload a file to Supabase Storage
 */
export async function uploadFile(
  bucket: string,
  file: File,
  path?: string
): Promise<UploadResult> {
  try {
    // Generate unique filename if path not provided
    const fileName = path || `${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
    
    // Upload file
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      console.error('Upload error:', error);
      return { url: '', path: '', error: error.message };
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl(data.path);

    return {
      url: publicUrl,
      path: data.path,
    };
  } catch (error) {
    console.error('Upload error:', error);
    return { 
      url: '', 
      path: '', 
      error: error instanceof Error ? error.message : 'Upload failed' 
    };
  }
}

/**
 * Delete a file from Supabase Storage
 */
export async function deleteFile(bucket: string, path: string): Promise<boolean> {
  try {
    const { error } = await supabase.storage
      .from(bucket)
      .remove([path]);

    if (error) {
      console.error('Delete error:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Delete error:', error);
    return false;
  }
}

/**
 * Upload product image with consistent path structure
 */
export async function uploadProductImage(
  file: File,
  productId?: string,
  imageType: 'primary' | 'gallery' = 'gallery'
): Promise<UploadResult> {
  try {
    // Create file path similar to DraggableImageGallery
    const fileExt = file.name.split('.').pop();
    const cleanFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
    
    let fileName: string;
    if (productId) {
      // Use productId folder structure
      fileName = `${productId}/${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
    } else {
      // Fallback for when no productId is provided
      fileName = `temp/${Date.now()}-${cleanFileName}`;
    }
    
    // Upload file to Supabase Storage
    const { data, error } = await supabase.storage
      .from('product-images')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      console.error('Upload error:', error);
      return { url: '', path: '', error: error.message };
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('product-images')
      .getPublicUrl(data.path);

    return {
      url: publicUrl,
      path: data.path,
    };
  } catch (error) {
    console.error('Upload error:', error);
    return { 
      url: '', 
      path: '', 
      error: error instanceof Error ? error.message : 'Upload failed' 
    };
  }
}

/**
 * Upload customer avatar
 */
export async function uploadCustomerAvatar(
  file: File,
  customerId: string
): Promise<UploadResult> {
  const folder = `${customerId}`;
  const fileName = `avatar-${Date.now()}.${file.name.split('.').pop()}`;
  const path = `${folder}/${fileName}`;
  
  return uploadFile('customer-avatars', file, path);
}

/**
 * Get storage URL for a file
 */
export function getStorageUrl(bucket: string, path: string): string {
  const { data: { publicUrl } } = supabase.storage
    .from(bucket)
    .getPublicUrl(path);
  
  return publicUrl;
}

/**
 * List files in a folder
 */
export async function listFiles(bucket: string, folder: string) {
  try {
    const { data, error } = await supabase.storage
      .from(bucket)
      .list(folder, {
        limit: 100,
        offset: 0,
      });

    if (error) {
      console.error('List files error:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('List files error:', error);
    return [];
  }
}

/**
 * Test storage bucket access and permissions
 */
export async function testStorageBucket(bucket: string = 'product-images') {
  try {
    console.log(`🧪 Testing storage bucket: ${bucket}`);
    
    // Test 1: List files to check bucket exists and is accessible
    const { data: listData, error: listError } = await supabase.storage
      .from(bucket)
      .list('', { limit: 1 });
    
    if (listError) {
      console.error('❌ Bucket list error:', listError);
      return {
        success: false,
        error: `Bucket access failed: ${listError.message}`,
        tests: {
          bucketAccess: false,
          publicUrl: false
        }
      };
    }
    
    console.log('✅ Bucket access successful');
    
    // Test 2: Try to get a public URL (test with a known file or dummy path)
    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl('test-path.jpg');
    
    console.log('✅ Public URL generation successful:', publicUrl);
    
    return {
      success: true,
      message: 'Storage bucket is accessible and configured correctly',
      tests: {
        bucketAccess: true,
        publicUrl: !!publicUrl
      },
      samplePublicUrl: publicUrl
    };
  } catch (error) {
    console.error('💥 Storage test error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown storage error',
      tests: {
        bucketAccess: false,
        publicUrl: false
      }
    };
  }
}