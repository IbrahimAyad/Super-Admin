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

    // Ensure images are sorted by position (database column name)
    const productsWithSortedImages = data?.map(product => ({
      ...product,
      images: Array.isArray(product.images) 
        ? product.images.sort((a: ProductImage, b: ProductImage) => (a.position || 0) - (b.position || 0))
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
      .from('products')
      .select(`
        *,
        images:product_images(*),
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
 * Get product image URL with fallback and proper Supabase Storage handling
 */
export function getProductImageUrl(product: any, variant?: string): string {
  const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const STORAGE_PATH = '/storage/v1/object/public/product-images/';
  

  // Helper function to process URL
  const processUrl = (url: string): string => {
    if (!url) {
      return '/placeholder.svg';
    }

    // If it's already a full URL (starts with http/https), return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If it's a relative path, prepend Supabase storage URL
    const fullUrl = `${SUPABASE_URL}${STORAGE_PATH}${url.startsWith('/') ? url.substring(1) : url}`;
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
      .from('products')
      .insert([productInfo])
      .select()
      .single();

    if (productError) throw productError;

    // If there are images, insert them into product_images table
    if (images && images.length > 0 && product) {
      const imageInserts = images.map(img => ({
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
 * Update an existing product with images
 */
export async function updateProductWithImages(productId: string, productData: Partial<Product> & { images?: Array<{ url: string; position: number; alt_text?: string; image_type?: string }> }, imageFiles?: File[]) {
  try {
    // Separate product data from images
    const { images, ...productInfo } = productData;
    
    // Update the product first
    const { data: product, error: productError } = await supabase
      .from('products')
      .update(productInfo)
      .eq('id', productId)
      .select()
      .single();

    if (productError) throw productError;

    // Handle images if provided
    if (images && product) {
      // For updates, we'll replace all existing images with the new ones
      // First, delete existing images
      const { error: deleteError } = await supabase
        .from('product_images')
        .delete()
        .eq('product_id', productId);

      if (deleteError) {
        console.warn('Failed to delete existing images:', deleteError);
      }

      // Then insert new images
      if (images.length > 0) {
        const imageInserts = images.map(img => ({
          product_id: productId,
          image_url: img.url,
          position: img.position,
          alt_text: img.alt_text || '',
          image_type: img.image_type || (img.position === 0 ? 'primary' : 'gallery')
        }));

        const { error: imagesError } = await supabase
          .from('product_images')
          .insert(imageInserts);

        if (imagesError) {
          console.warn('Failed to insert updated images:', imagesError);
          // Don't fail the entire operation for image errors
        }
      }
    }

    return {
      success: true,
      data: product,
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