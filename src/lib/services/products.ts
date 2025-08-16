/**
 * UNIFIED PRODUCTS SERVICE
 * Centralized product operations using the singleton Supabase client
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';
import { productCache } from '../cache';

// Product types - Updated for products_enhanced
export interface Product {
  id: string;
  name: string;
  slug: string;
  handle?: string;
  description: string;
  category: string;
  subcategory?: string;
  base_price: number;
  compare_at_price?: number;
  sale_price?: number;
  sku: string;
  style_code?: string;
  season?: string;
  collection?: string;
  price_tier?: string;
  color_name?: string;
  color_family?: string;
  materials?: any;
  fit_type?: string;
  size_options?: {
    regular: boolean;
    short: boolean;
    long: boolean;
  };
  available_sizes?: string[];
  shopify_id?: string;
  stripe_product_id?: string;
  status: 'active' | 'draft' | 'archived';
  created_at: string;
  updated_at: string;
  metadata?: Record<string, any>;
  additional_info?: Record<string, any>;
  images?: ProductImage[] | any; // Can be array or JSON
  variants?: ProductVariant[];
  // SEO fields
  meta_title?: string;
  meta_description?: string;
  meta_keywords?: string[];
  og_title?: string;
  og_description?: string;
  search_terms?: string;
  url_slug?: string;
  is_indexable?: boolean;
  sitemap_priority?: number;
}

export interface ProductImage {
  id: string;
  product_id: string;
  variant_id?: string;
  r2_key?: string;
  r2_url?: string;
  image_url: string;  // Primary field used in database
  url?: string; // Legacy support
  image_type: 'primary' | 'gallery' | 'thumbnail' | 'detail';
  position: number; // Actual column name in database
  sort_order?: number; // Legacy support
  alt_text?: string;
  width?: number;
  height?: number;
  created_at: string;
  updated_at: string;
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
  search?: string;
  filters?: {
    lowStock?: boolean;
    noImages?: boolean;
    inactive?: boolean;
    recentlyUpdated?: boolean;
  };
}) {
  try {
    // Create cache key based on options
    const cacheKey = `products:${JSON.stringify(options || {})}`;
    
    // Try to get from cache first (skip cache for search and filters to ensure freshness)
    if (!options?.search && !options?.filters) {
      const cached = productCache.getSearchResults(cacheKey);
      if (cached) {
        console.debug('Cache hit for products:', cacheKey);
        return {
          data: cached,
          count: cached.length,
          success: true
        };
      }
    }
    let query = supabase
      .from('products_enhanced')
      .select(`
        *,
        images:product_images(product_id, image_url, image_type, position, alt_text),
        variants:product_variants(*)
      `, { count: 'exact' })
      .order('created_at', { ascending: false });

    // Apply filters
    if (options?.category) {
      query = query.eq('category', options.category);
    }
    if (options?.status) {
      query = query.eq('status', options.status);
    }
    if (options?.search) {
      query = query.or(`name.ilike.%${options.search}%,description.ilike.%${options.search}%,category.ilike.%${options.search}%`);
    }

    // Apply smart filters
    if (options?.filters?.inactive) {
      query = query.eq('status', 'inactive');
    }
    if (options?.filters?.recentlyUpdated) {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      query = query.gte('updated_at', sevenDaysAgo.toISOString());
    }

    // Apply pagination
    if (options?.limit && options?.offset !== undefined) {
      query = query.range(options.offset, options.offset + options.limit - 1);
    } else if (options?.limit) {
      query = query.limit(options.limit);
    }

    const { data, error, count } = await query;

    if (error) {
      console.error('Error fetching products:', error);
      throw error;
    }

    // Ensure images are sorted by position (database column name)
    let productsWithSortedImages = data?.map(product => {
      // Calculate total inventory from variants
      const totalInventory = product.variants?.reduce(
        (sum: number, variant: any) => sum + (variant.inventory_quantity || 0), 
        0
      ) || 0;

      return {
        ...product,
        images: Array.isArray(product.images) 
          ? product.images.sort((a: ProductImage, b: ProductImage) => (a.position || 0) - (b.position || 0))
          : [],
        total_inventory: totalInventory
      };
    }) || [];

    // Apply client-side filters that require calculated data
    if (options?.filters) {
      if (options.filters.lowStock) {
        productsWithSortedImages = productsWithSortedImages.filter(p => p.total_inventory < 5);
      }
      if (options.filters.noImages) {
        productsWithSortedImages = productsWithSortedImages.filter(p => !p.images || p.images.length === 0);
      }
    }

    console.log(`✅ Fetched ${productsWithSortedImages.length} products with images (total: ${count})`);

    // Cache the results (skip caching for search and filters)
    if (!options?.search && !options?.filters) {
      productCache.setSearchResults(cacheKey, productsWithSortedImages, 5 * 60 * 1000); // 5 minutes
      console.debug('Cached products:', cacheKey);
    }

    return {
      success: true,
      data: productsWithSortedImages,
      totalCount: count || 0,
      error: null
    };
  } catch (error) {
    console.error('fetchProductsWithImages error:', error);
    return {
      success: false,
      data: [],
      totalCount: 0,
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
      .from('products_enhanced')
      .select(`
        *,
        images:product_images(product_id, image_url, image_type, position, alt_text),
        variants:product_variants(*)
      `)
      .eq('slug', slugOrId)
      .single();

    // If not found by slug, try by ID
    if (!data) {
      const result = await supabase
        .from('products_enhanced')
        .select(`
          *,
          images:product_images(product_id, image_url, image_type, position, alt_text),
          variants:product_variants(*)
        `)
        .eq('id', slugOrId)
        .single();
      
      data = result.data;
      error = result.error;
    }

    if (error) throw error;

    // Sort images by position (database column name)
    if (data?.images) {
      data.images.sort((a: ProductImage, b: ProductImage) => (a.position || 0) - (b.position || 0));
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
      .from('products_enhanced')
      .select(`
        *,
        images:product_images(product_id, image_url, image_type, position, alt_text),
        variants:product_variants(*)
      `)
      .eq('id', id)
      .single();

    if (error) throw error;

    // Sort images by position (database column name)
    if (data?.images) {
      data.images.sort((a: ProductImage, b: ProductImage) => (a.position || 0) - (b.position || 0));
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
 * Get product image URL with support for multiple storage sources (R2, Supabase, etc.)
 */
export function getProductImageUrl(product: any, variant?: string): string {
  const SUPABASE_URL = import.meta.env.NEXT_PUBLIC_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  
  // Helper function to process URL
  const processUrl = (url: string): string => {
    if (!url || url.trim() === '') {
      return '/placeholder.svg';
    }

    // If it's already a full URL (starts with http/https), return as-is
    // This handles R2 URLs, Supabase URLs, and any other CDN URLs
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // For relative paths, try to construct a full URL
    // Remove leading slash if present
    const cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    
    // If it's just a filename (no path), it might be a legacy reference
    if (!cleanUrl.includes('/')) {
      // For files like "powder-blue-suspender-set.jpg", construct Supabase URL
      const rootUrl = `${SUPABASE_URL}${STORAGE_PATH}${cleanUrl}`;
      return rootUrl;
    }
    
    // For files with paths, construct the full Supabase URL
    const fullUrl = `${SUPABASE_URL}${STORAGE_PATH}${cleanUrl}`;
    return fullUrl;
  };

  // PRIORITY 1: Handle the proper ProductImage array structure (current database setup)
  if (product.images && Array.isArray(product.images)) {
    // Sort images by position to ensure primary image is first
    const sortedImages = product.images.sort((a: any, b: any) => (a.position || 0) - (b.position || 0));
    
    // Try to get primary image first
    const primaryImage = sortedImages.find((img: any) => img.image_type === 'primary');
    if (primaryImage) {
      // Check for image_url field first (main field), then fall back to legacy url field or r2_url
      if (primaryImage.image_url) {
        return processUrl(primaryImage.image_url);
      } else if (primaryImage.url) {
        return processUrl(primaryImage.url);
      } else if (primaryImage.r2_url) {
        return processUrl(primaryImage.r2_url);
      }
    }

    // Fall back to first available image with valid URL
    for (const img of sortedImages) {
      if (img.image_url) {
        return processUrl(img.image_url);
      } else if (img.url) {
        return processUrl(img.url);
      } else if (img.r2_url) {
        return processUrl(img.r2_url);
      }
    }
  }

  // PRIORITY 2: Handle direct product image fields (if they exist)
  if (product.primary_image) {
    return processUrl(product.primary_image);
  }

  // Handle image_gallery array
  if (product.image_gallery && Array.isArray(product.image_gallery) && product.image_gallery.length > 0) {
    return processUrl(product.image_gallery[0]);
  }

  // Handle legacy images string array structure  
  if (product.images && Array.isArray(product.images) && typeof product.images[0] === 'string') {
    return processUrl(product.images[0]);
  }

  // Return placeholder
  return '/placeholder.svg';
}

/**
 * Debug function to test image URL generation
 * Call from console: window.debugImageUrl('powder-blue-suspender-set.jpg')
 */
export function debugImageUrl(filename: string) {
  const SUPABASE_URL = import.meta.env.NEXT_PUBLIC_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  
  console.group('🔍 Image URL Debug');
  console.log('Input filename:', filename);
  console.log('Supabase URL:', SUPABASE_URL);
  console.log('Storage path:', STORAGE_PATH);
  
  // Test different URL constructions
  const directUrl = `${SUPABASE_URL}${STORAGE_PATH}${filename}`;
  const withoutSlash = filename.startsWith('/') ? filename.substring(1) : filename;
  const constructedUrl = `${SUPABASE_URL}${STORAGE_PATH}${withoutSlash}`;
  
  console.log('Direct URL:', directUrl);
  console.log('Constructed URL:', constructedUrl);
  
  // Test with mock product data
  const mockProduct = {
    images: [{
      image_url: filename,
      position: 0,
      image_type: 'primary'
    }]
  };
  
  const generatedUrl = getProductImageUrl(mockProduct);
  console.log('Generated via getProductImageUrl:', generatedUrl);
  
  console.groupEnd();
  
  return {
    directUrl,
    constructedUrl, 
    generatedUrl
  };
}

// Make debug function available globally in development
if (typeof window !== 'undefined' && import.meta.env.DEV) {
  (window as any).debugImageUrl = debugImageUrl;
  console.log('🛠️ Debug function available: window.debugImageUrl("filename.jpg")');
}

/**
 * Format price for display - handles both cents and dollars
 */
export function formatPrice(price: number): string {
  // If price is greater than 1000, assume it's in cents
  // Otherwise assume it's in dollars (for products_enhanced which stores as dollars)
  const amount = price > 1000 ? price / 100 : price;
  
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}

/**
 * Convert price to cents for Stripe
 */
export function priceToCents(price: number): number {
  // If price is less than 1000, it's likely in dollars, so convert to cents
  return price < 1000 ? Math.round(price * 100) : Math.round(price);
}

/**
 * Convert cents to dollars
 */
export function centsToPrice(cents: number): number {
  return cents / 100;
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
export async function createProductWithImages(productData: Partial<Product> & { images?: Array<{ url: string; position: number; alt_text?: string; image_type?: string }> }, imageFiles?: File[]) {
  try {
    // Separate product data from images
    const { images, ...productInfo } = productData;
    
    // Create the product first
    const { data: product, error: productError } = await supabase
      .from('products_enhanced')
      .insert([productInfo])
      .select()
      .single();

    if (productError) throw productError;

    // Handle file uploads if provided
    let uploadedImageUrls: string[] = [];
    if (imageFiles && imageFiles.length > 0) {
      const uploadResult = await uploadProductImageFiles(imageFiles, product.id);
      if (!uploadResult.success) {
        console.warn('Failed to upload some images:', uploadResult.error);
        // Don't fail the entire operation for image upload errors
      } else {
        uploadedImageUrls = uploadResult.urls;
      }
    }

    // Combine provided images with newly uploaded ones
    const allImages = [...(images || [])];
    uploadedImageUrls.forEach((url, index) => {
      allImages.push({
        url,
        position: (images?.length || 0) + index,
        alt_text: '',
        image_type: (images?.length || 0) + index === 0 ? 'primary' : 'gallery'
      });
    });

    // If there are images, insert them into product_images table
    if (allImages.length > 0 && product) {
      const imageInserts = allImages.map(img => ({
        product_id: product.id,
        image_url: img.url,
        position: img.position,
        alt_text: img.alt_text || '',
        image_type: img.image_type || (img.position === 0 ? 'primary' : 'gallery')
      }));

      const { error: imagesError } = await supabase
        .from('product_images')
        .insert(imageInserts);

      if (imagesError) {
        console.warn('Failed to insert some images:', imagesError);
        // Don't fail the entire operation for image errors
      }
    }

    return {
      success: true,
      data: product,
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
 * Upload image files and return their Supabase Storage URLs
 */
export async function uploadProductImageFiles(files: File[], productId?: string): Promise<{ success: boolean; urls: string[]; error?: string }> {
  try {
    const uploadedUrls: string[] = [];
    
    for (const file of files) {
      if (!file.type.startsWith('image/')) {
        throw new Error(`${file.name} is not a valid image file`);
      }
      
      // Generate unique filename
      const fileExt = file.name.split('.').pop();
      const timestamp = Date.now();
      const randomId = Math.random().toString(36).substring(2);
      
      let fileName: string;
      if (productId) {
        fileName = `${productId}/${timestamp}-${randomId}.${fileExt}`;
      } else {
        fileName = `temp/${timestamp}-${randomId}.${fileExt}`;
      }
      
      // Upload to Supabase Storage
      const { data, error } = await supabase.storage
        .from('product-images')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        });
      
      if (error) {
        console.error('Upload error for file:', file.name, error);
        throw new Error(`Failed to upload ${file.name}: ${error.message}`);
      }
      
      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('product-images')
        .getPublicUrl(data.path);
      
      uploadedUrls.push(publicUrl);
    }
    
    return {
      success: true,
      urls: uploadedUrls
    };
  } catch (error) {
    console.error('uploadProductImageFiles error:', error);
    return {
      success: false,
      urls: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Quick toggle product status
 */
export async function toggleProductStatus(productId: string) {
  try {
    // First get current status
    const { data: currentProduct, error: fetchError } = await supabase
      .from('products_enhanced')
      .select('status')
      .eq('id', productId)
      .single();

    if (fetchError) throw fetchError;

    // Toggle status
    const newStatus = currentProduct.status === 'active' ? 'draft' : 'active';

    const { data, error } = await supabase
      .from('products_enhanced')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
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
    console.error('toggleProductStatus error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Quick duplicate product
 */
export async function duplicateProduct(productId: string) {
  try {
    // Get the original product with images
    const { data: originalProduct, error: fetchError } = await supabase
      .from('products_enhanced')
      .select(`
        *,
        images:product_images(product_id, image_url, image_type, position, alt_text),
        variants:product_variants(*)
      `)
      .eq('id', productId)
      .single();

    if (fetchError) throw fetchError;

    // Create new product data
    const { id, created_at, updated_at, ...productData } = originalProduct;
    const newProductData = {
      ...productData,
      name: `${productData.name} (Copy)`,
      slug: `${productData.slug}-copy-${Date.now()}`,
      sku: `${productData.sku}-COPY-${Date.now().toString().slice(-6)}`,
      status: 'draft' as const
    };

    // Create the new product
    const { data: newProduct, error: createError } = await supabase
      .from('products_enhanced')
      .insert([newProductData])
      .select()
      .single();

    if (createError) throw createError;

    // Duplicate images if any
    if (originalProduct.images && originalProduct.images.length > 0) {
      const imageInserts = originalProduct.images.map((img: any) => ({
        product_id: newProduct.id,
        image_url: img.image_url,
        position: img.position,
        alt_text: img.alt_text || '',
        image_type: img.image_type
      }));

      const { error: imagesError } = await supabase
        .from('product_images')
        .insert(imageInserts);

      if (imagesError) {
        console.warn('Failed to duplicate images:', imagesError);
      }
    }

    return {
      success: true,
      data: newProduct,
      error: null
    };
  } catch (error) {
    console.error('duplicateProduct error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get recently updated products for admin
 */
export async function getRecentlyUpdatedProducts(limit: number = 5) {
  try {
    const { data, error } = await supabase
      .from('products_enhanced')
      .select(`
        id,
        name,
        status,
        updated_at,
        images:product_images!inner(image_url)
      `)
      .order('updated_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getRecentlyUpdatedProducts error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Update an existing product with images
 */
export async function updateProductWithImages(productId: string, productData: Partial<Product> & { images?: Array<{ url: string; position: number; alt_text?: string; image_type?: string }> }, imageFiles?: File[]) {
  try {
    console.log('🔄 updateProductWithImages called with:', { productId, productData, hasImageFiles: !!imageFiles });

    // Validate required parameters
    if (!productId || !productData) {
      throw new Error('Product ID and product data are required');
    }

    // First, handle any file uploads
    let uploadedImageUrls: string[] = [];
    if (imageFiles && imageFiles.length > 0) {
      console.log('📤 Uploading image files...');
      const uploadResult = await uploadProductImageFiles(imageFiles, productId);
      if (!uploadResult.success) {
        console.error('❌ Image upload failed:', uploadResult.error);
        throw new Error(uploadResult.error || 'Failed to upload images');
      }
      uploadedImageUrls = uploadResult.urls;
      console.log('✅ Image files uploaded:', uploadedImageUrls);
    }
    
    // Separate product data from images
    const { images, ...productInfo } = productData;
    
    // Clean product data - remove any undefined values and ensure proper types
    const cleanProductInfo = Object.fromEntries(
      Object.entries(productInfo).filter(([_, value]) => value !== undefined)
    );

    // Ensure updated_at is set
    cleanProductInfo.updated_at = new Date().toISOString();

    console.log('🔄 Updating product with clean data:', cleanProductInfo);
    
    // Update the product first
    const { data: product, error: productError } = await supabase
      .from('products_enhanced')
      .update(cleanProductInfo)
      .eq('id', productId)
      .select()
      .single();

    if (productError) {
      console.error('❌ Product update failed:', productError);
      // Provide more specific error messages
      if (productError.code === '23505') {
        throw new Error('A product with this SKU or slug already exists');
      } else if (productError.code === '23502') {
        throw new Error('Required field is missing');
      } else if (productError.code === '42501') {
        throw new Error('Permission denied. Please check your authentication');
      }
      throw new Error(`Database error: ${productError.message}`);
    }

    console.log('✅ Product updated successfully:', product);

    // Handle images if provided
    if (images && product) {
      console.log('🖼️ Updating product images...');
      
      try {
        // For updates, we'll replace all existing images with the new ones
        // First, delete existing images
        const { error: deleteError } = await supabase
          .from('product_images')
          .delete()
          .eq('product_id', productId);

        if (deleteError) {
          console.warn('⚠️ Failed to delete existing images (continuing):', deleteError);
        }

        // Combine provided images with newly uploaded ones
        const allImages = [...images];
        uploadedImageUrls.forEach((url, index) => {
          allImages.push({
            url,
            position: images.length + index,
            alt_text: '',
            image_type: images.length + index === 0 ? 'primary' : 'gallery'
          });
        });

        // Then insert all images
        if (allImages.length > 0) {
          const imageInserts = allImages.map(img => ({
            product_id: productId,
            image_url: img.url,
            position: img.position,
            alt_text: img.alt_text || '',
            image_type: img.image_type || (img.position === 0 ? 'primary' : 'gallery'),
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }));

          console.log('🔄 Inserting image records:', imageInserts);

          const { error: imagesError } = await supabase
            .from('product_images')
            .insert(imageInserts);

          if (imagesError) {
            console.error('❌ Failed to insert updated images:', imagesError);
            // Don't fail the entire operation for image errors, but log it
            console.warn('⚠️ Product updated but images may not have saved properly');
          } else {
            console.log('✅ Product images updated successfully');
          }
        }
      } catch (imageError) {
        console.error('❌ Error handling images:', imageError);
        // Don't fail the entire operation for image errors
      }
    }

    return {
      success: true,
      data: product,
      error: null
    };
  } catch (error) {
    console.error('💥 updateProductWithImages error:', error);
    
    // Provide more user-friendly error messages
    let errorMessage = 'Unknown error occurred';
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    }

    return {
      success: false,
      data: null,
      error: errorMessage
    };
  }
}