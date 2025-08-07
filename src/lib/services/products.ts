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
  r2_key: string;
  r2_url: string;
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
 * Get product image URL with fallback
 */
export function getProductImageUrl(product: any, variant?: string): string {
  // Handle the new structure with primary_image field
  if (product.primary_image) {
    return product.primary_image;
  }

  // Handle image_gallery array
  if (product.image_gallery && Array.isArray(product.image_gallery) && product.image_gallery.length > 0) {
    return product.image_gallery[0];
  }

  // Handle legacy images string array structure  
  if (product.images && Array.isArray(product.images) && typeof product.images[0] === 'string') {
    return product.images[0];
  }

  // Handle the proper ProductImage array structure
  if (product.images && Array.isArray(product.images)) {
    // Try to get primary image first
    const primaryImage = product.images.find((img: any) => img.image_type === 'primary');
    if (primaryImage?.r2_url) return primaryImage.r2_url;

    // Fall back to first image with r2_url
    for (const img of product.images) {
      if (img.r2_url) return img.r2_url;
    }
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