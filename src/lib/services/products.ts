/**
 * UNIFIED PRODUCTS SERVICE
 * Centralized product operations using the singleton Supabase client
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';

// Product types
export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  category: string;
  subcategory?: string;
  base_price: number;
  sale_price?: number;
  sku: string;
  shopify_id?: string;
  status: 'active' | 'draft' | 'archived';
  created_at: string;
  updated_at: string;
  metadata?: Record<string, any>;
  images?: ProductImage[];
  variants?: ProductVariant[];
}

export interface ProductImage {
  id: string;
  product_id: string;
  variant_id?: string;
  r2_key?: string;
  r2_url?: string;
  url: string;  // Primary field used in database
  image_type: 'primary' | 'gallery' | 'thumbnail' | 'detail';
  sort_order: number;
  alt_text?: string;
  created_at: string;
}

export interface ProductVariant {
  id: string;
  product_id: string;
  name: string;
  sku: string;
  price: number;
  size?: string;
  color?: string;
  option1?: string;
  option2?: string;
  inventory_quantity?: number;
  inventory_count: number;
  available?: boolean;
  inStock?: boolean;
  status: 'active' | 'out_of_stock';
}

export interface SizeTemplate {
  id: string;
  category: string;
  subcategory?: string;
  template_name: string;
  sizes: any;
  display_type: 'grid' | 'dropdown' | 'two_step';
  is_default: boolean;
  is_active: boolean;
}

export interface ProductSmartTag {
  id: string;
  product_id: string;
  tag_type: 'occasion' | 'style' | 'season' | 'body_type' | 'recommendation';
  tag_value: string;
  confidence_score: number;
  source: 'manual' | 'ai' | 'user_behavior';
}

/**
 * Fetch products with images - ALWAYS use this method
 */
export async function fetchProductsWithImages(options?: {
  category?: string;
  limit?: number;
  offset?: number;
  status?: 'active' | 'draft' | 'archived';
}) {
  try {
    let query = supabase
      .from('products')
      .select(`
        *,
        images:product_images(*),
        variants:product_variants(*)
      `)
      .order('created_at', { ascending: false });

    // Apply filters
    if (options?.category) {
      query = query.eq('category', options.category);
    }
    if (options?.status) {
      query = query.eq('status', options.status);
    }
    if (options?.limit) {
      query = query.limit(options.limit);
    }
    if (options?.offset) {
      query = query.range(options.offset, options.offset + (options.limit || 10) - 1);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error fetching products:', error);
      throw error;
    }

    // Ensure images are sorted by sort_order
    const productsWithSortedImages = data?.map(product => ({
      ...product,
      images: Array.isArray(product.images) 
        ? product.images.sort((a: ProductImage, b: ProductImage) => (a.sort_order || 0) - (b.sort_order || 0))
        : []
    })) || [];

    console.log(`✅ Fetched ${productsWithSortedImages.length} products with images`);

    return {
      success: true,
      data: productsWithSortedImages,
      error: null
    };
  } catch (error) {
    console.error('fetchProductsWithImages error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get single product by slug or ID
 */
export async function getProduct(slugOrId: string) {
  try {
    // First try by slug
    let { data, error } = await supabase
      .from('products')
      .select(`
        *,
        images:product_images(*),
        variants:product_variants(*)
      `)
      .eq('slug', slugOrId)
      .single();

    // If not found by slug, try by ID
    if (!data) {
      const result = await supabase
        .from('products')
        .select(`
          *,
          images:product_images(*),
          variants:product_variants(*)
        `)
        .eq('id', slugOrId)
        .single();
      
      data = result.data;
      error = result.error;
    }

    if (error) throw error;

    // Sort images by sort_order
    if (data?.images) {
      data.images.sort((a: ProductImage, b: ProductImage) => a.sort_order - b.sort_order);
    }

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getProduct error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get single product by ID (optimized for frontend)
 */
export async function getProductById(id: string) {
  try {
    const { data, error } = await supabase
      .from('products')
      .select(`
        *,
        images:product_images(*),
        variants:product_variants(*)
      `)
      .eq('id', id)
      .single();

    if (error) throw error;

    // Sort images by sort_order
    if (data?.images) {
      data.images.sort((a: ProductImage, b: ProductImage) => a.sort_order - b.sort_order);
    }

    // Calculate additional fields the frontend expects
    if (data) {
      const totalInventory = data.variants?.reduce(
        (sum: number, variant: any) => sum + (variant.inventory_quantity || 0), 
        0
      ) || 0;

      const enhancedVariants = data.variants?.map((variant: any) => ({
        ...variant,
        available: (variant.inventory_quantity || 0) > 0,
        inStock: (variant.inventory_quantity || 0) > 0
      }));

      return {
        success: true,
        data: {
          ...data,
          totalInventory,
          variants: enhancedVariants,
          inStock: totalInventory > 0
        },
        error: null
      };
    }

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getProductById error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get products via Edge Function (for complex filtering)
 */
export async function getProductsViaFunction(filters?: {
  category?: string;
  product_type?: 'core' | 'catalog' | 'all';
  search?: string;
  limit?: number;
  offset?: number;
}) {
  try {
    const searchParams = new URLSearchParams();
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined) {
          searchParams.append(key, value.toString());
        }
      });
    }

    const { data, error } = await supabase.functions.invoke('get-products', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getProductsViaFunction error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Debug function to check what image URLs are stored in the database
 */
export async function debugImageUrls(limit: number = 10) {
  try {
    const { data, error } = await supabase
      .from('product_images')
      .select('id, product_id, url, r2_url, image_type, sort_order')
      .limit(limit);

    if (error) throw error;

    console.log('=== IMAGE URL DEBUGGING ===');
    console.log(`Found ${data?.length || 0} images in database:`);
    
    data?.forEach((img, index) => {
      console.log(`\nImage ${index + 1}:`);
      console.log('  ID:', img.id);
      console.log('  Product ID:', img.product_id);
      console.log('  URL field:', img.url);
      console.log('  R2_URL field:', img.r2_url);
      console.log('  Image type:', img.image_type);
      console.log('  Sort order:', img.sort_order);
    });

    console.log('=== END DEBUG ===');
    return { success: true, data };
  } catch (error) {
    console.error('debugImageUrls error:', error);
    return { success: false, error };
  }
}

/**
 * Get product image URL with fallback and proper Supabase Storage handling
 */
export function getProductImageUrl(product: any, variant?: string, debugMode: boolean = false): string {
  const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  
  if (debugMode) {
    console.log('getProductImageUrl called with product:', {
      id: product?.id,
      name: product?.name,
      hasImages: !!product?.images,
      imagesLength: product?.images?.length || 0,
      firstImage: product?.images?.[0]
    });
  }

  // Helper function to process URL
  const processUrl = (url: string): string => {
    if (!url) {
      if (debugMode) console.log('No URL provided, returning placeholder');
      return '/placeholder.svg';
    }

    if (debugMode) console.log('Processing URL:', url);

    // If it's already a full URL (starts with http/https), return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (debugMode) console.log('URL is already absolute:', url);
      return url;
    }

    // If it's a relative path, prepend Supabase storage URL
    const fullUrl = `${SUPABASE_URL}${STORAGE_PATH}${url.startsWith('/') ? url.substring(1) : url}`;
    if (debugMode) console.log('Converted relative URL to absolute:', fullUrl);
    return fullUrl;
  };

  // PRIORITY 1: Handle the proper ProductImage array structure (current database setup)
  if (product.images && Array.isArray(product.images)) {
    if (debugMode) console.log('Processing ProductImage array, length:', product.images.length);
    
    // Sort images by sort_order to ensure primary image is first
    const sortedImages = product.images.sort((a: any, b: any) => (a.sort_order || 0) - (b.sort_order || 0));
    
    // Try to get primary image first
    const primaryImage = sortedImages.find((img: any) => img.image_type === 'primary');
    if (primaryImage) {
      if (debugMode) console.log('Found primary image:', primaryImage);
      // Check for url field first (main field), then fall back to r2_url
      if (primaryImage.url) {
        return processUrl(primaryImage.url);
      } else if (primaryImage.r2_url) {
        return processUrl(primaryImage.r2_url);
      }
    }

    // Fall back to first available image with valid URL
    for (const img of sortedImages) {
      if (debugMode) console.log('Checking image:', img);
      if (img.url) {
        if (debugMode) console.log('Using image.url:', img.url);
        return processUrl(img.url);
      } else if (img.r2_url) {
        if (debugMode) console.log('Using image.r2_url:', img.r2_url);
        return processUrl(img.r2_url);
      }
    }
  }

  // PRIORITY 2: Handle direct product image fields (if they exist)
  if (product.primary_image) {
    if (debugMode) console.log('Using primary_image field:', product.primary_image);
    return processUrl(product.primary_image);
  }

  // Handle image_gallery array
  if (product.image_gallery && Array.isArray(product.image_gallery) && product.image_gallery.length > 0) {
    if (debugMode) console.log('Using image_gallery[0]:', product.image_gallery[0]);
    return processUrl(product.image_gallery[0]);
  }

  // Handle legacy images string array structure  
  if (product.images && Array.isArray(product.images) && typeof product.images[0] === 'string') {
    if (debugMode) console.log('Using images string array[0]:', product.images[0]);
    return processUrl(product.images[0]);
  }

  // Return placeholder
  if (debugMode) console.log('No valid image found, returning placeholder');
  return '/placeholder.svg';
}

/**
 * Format price for display
 */
export function formatPrice(cents: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(cents / 100);
}

/**
 * Check if product is on sale
 */
export function isOnSale(product: Product): boolean {
  return !!product.sale_price && product.sale_price < product.base_price;
}

/**
 * Get display price (sale or base)
 */
export function getDisplayPrice(product: Product): number {
  return product.sale_price || product.base_price;
}

/**
 * Comprehensive test function for debugging image loading issues
 * Call this from browser console: await testImageLoading()
 */
export async function testImageLoading() {
  console.log('=== TESTING IMAGE LOADING ===');
  
  try {
    // Test 1: Check database connection
    console.log('\n1. Testing database connection...');
    const connectionTest = await testSupabaseConnection();
    console.log('Connection test result:', connectionTest);

    // Test 2: Check what URLs are in the database
    console.log('\n2. Checking image URLs in database...');
    await debugImageUrls(5);

    // Test 3: Fetch a few products and test image URL generation
    console.log('\n3. Testing product fetching and image URL generation...');
    const productsResult = await fetchProductsWithImages({ limit: 3 });
    
    if (productsResult.success && productsResult.data.length > 0) {
      productsResult.data.forEach((product, index) => {
        console.log(`\n--- Product ${index + 1}: ${product.name} ---`);
        console.log('Product ID:', product.id);
        console.log('Images array:', product.images);
        console.log('Generated URL (debug mode):', getProductImageUrl(product, undefined, true));
        console.log('Generated URL (prod mode):', getProductImageUrl(product, undefined, false));
      });
    } else {
      console.log('No products found or error:', productsResult.error);
    }

    // Test 4: Check if storage bucket exists by attempting to access a known file
    console.log('\n4. Testing storage bucket accessibility...');
    const testUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/';
    console.log('Storage base URL:', testUrl);
    console.log('Note: Check Network tab to see if requests to this URL return 404 (bucket missing) or 403 (no files)');

  } catch (error) {
    console.error('Test failed:', error);
  }
  
  console.log('\n=== END IMAGE LOADING TEST ===');
}

/**
 * Test connection - use this to verify Supabase is working
 */
export async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('count')
      .limit(1);

    if (error) throw error;

    return {
      success: true,
      message: 'Supabase connection successful',
      error: null
    };
  } catch (error) {
    console.error('Supabase connection test failed:', error);
    return {
      success: false,
      message: 'Supabase connection failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Quick diagnostic for admin panel image issues
 */
export async function diagnoseAdminImageIssues() {
  console.log('🔍 ADMIN PANEL IMAGE DIAGNOSTIC');
  
  try {
    // 1. Test fetching products
    console.log('\n1. Testing product fetch...');
    const result = await fetchProductsWithImages({ limit: 3 });
    
    if (!result.success) {
      console.error('❌ Product fetch failed:', result.error);
      return;
    }
    
    console.log(`✅ Fetched ${result.data.length} products`);
    
    // 2. Test each product's image structure  
    result.data.forEach((product, index) => {
      console.log(`\n--- Product ${index + 1}: ${product.name} ---`);
      console.log('Raw images data:', product.images);
      console.log('Images count:', product.images?.length || 0);
      
      if (product.images && product.images.length > 0) {
        const firstImage = product.images[0];
        console.log('First image structure:', {
          id: firstImage.id,
          url: firstImage.url,
          r2_url: firstImage.r2_url,
          image_type: firstImage.image_type,
          sort_order: firstImage.sort_order
        });
        
        console.log('Generated URL:', getProductImageUrl(product, undefined, true));
      } else {
        console.log('⚠️  No images found for this product');
      }
    });
    
    // 3. Check storage bucket accessibility
    console.log('\n3. Testing storage bucket accessibility...');
    const testImageUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/';
    console.log('Storage base URL:', testImageUrl);
    
    // 4. Summary
    console.log('\n📊 SUMMARY:');
    console.log(`- Products fetched: ${result.data.length}`);
    console.log(`- Products with images: ${result.data.filter(p => p.images?.length > 0).length}`);
    console.log(`- Products without images: ${result.data.filter(p => !p.images?.length).length}`);
    
  } catch (error) {
    console.error('💥 Diagnostic failed:', error);
  }
}

/**
 * Export debugging functions to window for easy browser console access
 * Call this in development: enableImageDebugging()
 */
export function enableImageDebugging() {
  if (typeof window !== 'undefined') {
    (window as any).testImageLoading = testImageLoading;
    (window as any).debugImageUrls = debugImageUrls;
    (window as any).getProductImageUrl = getProductImageUrl;
    (window as any).fetchProductsWithImages = fetchProductsWithImages;
    (window as any).diagnoseAdminImageIssues = diagnoseAdminImageIssues;
    console.log('📸 Image debugging functions enabled!');
    console.log('Available functions:');
    console.log('- testImageLoading() - comprehensive test suite');
    console.log('- debugImageUrls(limit) - check URLs in database');
    console.log('- getProductImageUrl(product, variant, debugMode) - test URL generation');
    console.log('- fetchProductsWithImages(options) - fetch products with images');
    console.log('- diagnoseAdminImageIssues() - quick admin panel diagnostic');
  }
}

// === SMART SIZING SYSTEM ===

/**
 * Get size template for a product category
 */
export async function getSizeTemplate(category: string) {
  try {
    const { data, error } = await supabase
      .from('size_templates')
      .select('*')
      .eq('category', category)
      .eq('is_active', true)
      .eq('is_default', true)
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getSizeTemplate error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Generate variants from size template (for admin use)
 */
export async function generateVariantsFromTemplate(productId: string, category: string) {
  try {
    // Get the template for this category
    const templateResult = await getSizeTemplate(category);
    if (!templateResult.success || !templateResult.data) {
      throw new Error(`No template found for category: ${category}`);
    }

    const template = templateResult.data;
    const variants = [];
    const sizes = template.sizes;

    // Generate variants based on category
    switch (category) {
      case 'suits':
        ['short', 'regular', 'long'].forEach(length => {
          if (sizes[length]) {
            sizes[length].forEach((size: string) => {
              variants.push({
                product_id: productId,
                sku: `${productId.substring(0, 8)}-${size}`,
                size_display: size,
                option1: size,
                inventory_quantity: 0,
                stock_quantity: 0,
                price: 0,
                status: 'active'
              });
            });
          }
        });
        break;

      case 'blazers':
        if (sizes.regular) {
          sizes.regular.forEach((size: string) => {
            variants.push({
              product_id: productId,
              sku: `${productId.substring(0, 8)}-${size}`,
              size_display: size,
              option1: size,
              inventory_quantity: 0,
              stock_quantity: 0,
              price: 0,
              status: 'active'
            });
          });
        }
        break;

      case 'dress_shirts':
        if (sizes.fit_types && sizes.neck_sizes && sizes.sleeve_lengths) {
          sizes.fit_types.forEach((fit: string) => {
            sizes.neck_sizes.forEach((neck: string) => {
              sizes.sleeve_lengths.forEach((sleeve: string) => {
                const sizeDisplay = `${neck}/${sleeve}`;
                variants.push({
                  product_id: productId,
                  sku: `${productId.substring(0, 8)}-${neck}-${sleeve.replace('-', '')}-${fit}`,
                  size_display: sizeDisplay,
                  option1: sizeDisplay,
                  option2: fit,
                  inventory_quantity: 0,
                  stock_quantity: 0,
                  price: 0,
                  status: 'active'
                });
              });
            });
          });
        }
        break;

      case 'sweaters':
        if (sizes.sizes) {
          sizes.sizes.forEach((size: string) => {
            variants.push({
              product_id: productId,
              sku: `${productId.substring(0, 8)}-${size}`,
              size_display: size,
              option1: size,
              inventory_quantity: 0,
              stock_quantity: 0,
              price: 0,
              status: 'active'
            });
          });
        }
        break;

      case 'dress_shoes':
        if (sizes.whole_sizes) {
          sizes.whole_sizes.forEach((size: number) => {
            // Whole size
            variants.push({
              product_id: productId,
              sku: `${productId.substring(0, 8)}-${size}`,
              size_display: size.toString(),
              option1: size.toString(),
              inventory_quantity: 0,
              stock_quantity: 0,
              price: 0,
              status: 'active'
            });

            // Half size if enabled
            if (sizes.half_sizes_available) {
              variants.push({
                product_id: productId,
                sku: `${productId.substring(0, 8)}-${size}5`,
                size_display: `${size}.5`,
                option1: `${size}.5`,
                inventory_quantity: 0,
                stock_quantity: 0,
                price: 0,
                status: 'active'
              });
            }
          });
        }
        break;
    }

    // Insert variants
    const { data, error } = await supabase
      .from('product_variants')
      .insert(variants)
      .select();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('generateVariantsFromTemplate error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Sync Stripe products
 */
export async function syncStripeProducts() {
  try {
    const { data, error } = await supabase.functions.invoke('sync-stripe-products', {
      method: 'POST',
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('syncStripeProducts error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Create a new product with images
 */
export async function createProductWithImages(productData: Partial<Product>, imageFiles?: File[]) {
  try {
    // For now, redirect to basic product creation
    const { data, error } = await supabase
      .from('products')
      .insert([productData])
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('createProductWithImages error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Update an existing product with images
 */
export async function updateProductWithImages(productId: string, productData: Partial<Product>, imageFiles?: File[]) {
  try {
    // For now, redirect to basic product update
    const { data, error } = await supabase
      .from('products')
      .update(productData)
      .eq('id', productId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateProductWithImages error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}