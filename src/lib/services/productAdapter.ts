/**
 * Product Adapter Service
 * Provides compatibility layer between old products and products_enhanced tables
 * Allows gradual migration without breaking existing components
 */

import { supabase } from '../supabase';

// Types for both systems
export interface OldProduct {
  id: string;
  name: string;
  description?: string;
  price: number; // in dollars
  category?: string;
  subcategory?: string;
  image_url?: string;
  gallery_images?: string[];
  sku?: string;
  status?: string;
  stripe_product_id?: string;
  created_at?: string;
  updated_at?: string;
}

export interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  slug: string;
  style_code?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  price_tier: string;
  base_price: number; // in cents
  compare_at_price?: number;
  color_family?: string;
  color_name?: string;
  materials?: any;
  fit_type?: string;
  images: {
    hero?: { url: string; alt?: string };
    flat?: { url: string; alt?: string };
    lifestyle?: Array<{ url: string; alt?: string }>;
    details?: Array<{ url: string; alt?: string }>;
    variants?: Record<string, Array<{ url: string; alt?: string }>>;
    total_images?: number;
  };
  description?: string;
  status: string;
  stripe_product_id?: string;
  stripe_active?: boolean;
  created_at: string;
  updated_at: string;
}

/**
 * Convert enhanced product to old format for backward compatibility
 */
export function enhancedToOld(product: EnhancedProduct): OldProduct {
  const galleryImages: string[] = [];
  
  // Collect all images into gallery
  if (product.images?.lifestyle) {
    galleryImages.push(...product.images.lifestyle.map(img => img.url));
  }
  if (product.images?.details) {
    galleryImages.push(...product.images.details.map(img => img.url));
  }
  if (product.images?.flat) {
    galleryImages.push(product.images.flat.url);
  }
  
  return {
    id: product.id,
    name: product.name,
    description: product.description,
    price: product.base_price / 100, // Convert cents to dollars
    category: product.category,
    subcategory: product.subcategory,
    image_url: product.images?.hero?.url,
    gallery_images: galleryImages,
    sku: product.sku,
    status: product.status,
    stripe_product_id: product.stripe_product_id,
    created_at: product.created_at,
    updated_at: product.updated_at,
  };
}

/**
 * Convert old product to enhanced format (partial - for display only)
 */
export function oldToEnhanced(product: OldProduct): Partial<EnhancedProduct> {
  const lifestyle = product.gallery_images?.map(url => ({ url })) || [];
  
  return {
    id: product.id,
    name: product.name,
    sku: product.sku || '',
    handle: product.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-') || '',
    slug: product.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-') || '',
    category: product.category || 'Uncategorized',
    subcategory: product.subcategory,
    price_tier: getPriceTierFromPrice(product.price),
    base_price: Math.round((product.price || 0) * 100), // Convert dollars to cents
    images: {
      hero: product.image_url ? { url: product.image_url } : undefined,
      lifestyle: lifestyle,
      details: [],
      total_images: 1 + lifestyle.length,
    },
    description: product.description,
    status: product.status || 'active',
    stripe_product_id: product.stripe_product_id,
    created_at: product.created_at || new Date().toISOString(),
    updated_at: product.updated_at || new Date().toISOString(),
  };
}

/**
 * Get price tier from price amount
 */
function getPriceTierFromPrice(price: number): string {
  const priceInCents = price * 100;
  
  if (priceInCents < 7500) return 'TIER_1';
  if (priceInCents < 10000) return 'TIER_2';
  if (priceInCents < 12500) return 'TIER_3';
  if (priceInCents < 15000) return 'TIER_4';
  if (priceInCents < 20000) return 'TIER_5';
  if (priceInCents < 25000) return 'TIER_6';
  if (priceInCents < 30000) return 'TIER_7';
  if (priceInCents < 40000) return 'TIER_8';
  if (priceInCents < 50000) return 'TIER_9';
  if (priceInCents < 60000) return 'TIER_10';
  return 'TIER_10'; // Default for higher prices
}

/**
 * Unified product service that tries enhanced first, falls back to old
 */
export const productAdapter = {
  /**
   * Get all products (tries enhanced first)
   */
  async getAll(): Promise<OldProduct[]> {
    // Try enhanced products first
    const { data: enhanced, error: enhancedError } = await supabase
      .from('products_enhanced')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false });
    
    if (!enhancedError && enhanced && enhanced.length > 0) {
      console.log(`[ProductAdapter] Using enhanced products (${enhanced.length} found)`);
      return enhanced.map(enhancedToOld);
    }
    
    // Fallback to old products
    const { data: old, error: oldError } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (oldError) {
      console.error('[ProductAdapter] Error fetching products:', oldError);
      throw oldError;
    }
    
    console.log(`[ProductAdapter] Using old products (${old?.length || 0} found)`);
    return old || [];
  },

  /**
   * Get single product by ID
   */
  async getById(id: string): Promise<OldProduct | null> {
    // Try enhanced first
    const { data: enhanced } = await supabase
      .from('products_enhanced')
      .select('*')
      .eq('id', id)
      .single();
    
    if (enhanced) {
      return enhancedToOld(enhanced);
    }
    
    // Fallback to old
    const { data: old } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .single();
    
    return old;
  },

  /**
   * Get product by SKU
   */
  async getBySku(sku: string): Promise<OldProduct | null> {
    // Try enhanced first
    const { data: enhanced } = await supabase
      .from('products_enhanced')
      .select('*')
      .eq('sku', sku)
      .single();
    
    if (enhanced) {
      return enhancedToOld(enhanced);
    }
    
    // Fallback to old
    const { data: old } = await supabase
      .from('products')
      .select('*')
      .eq('sku', sku)
      .single();
    
    return old;
  },

  /**
   * Search products
   */
  async search(query: string): Promise<OldProduct[]> {
    // Try enhanced first
    const { data: enhanced } = await supabase
      .from('products_enhanced')
      .select('*')
      .or(`name.ilike.%${query}%,sku.ilike.%${query}%,description.ilike.%${query}%`)
      .eq('status', 'active');
    
    if (enhanced && enhanced.length > 0) {
      return enhanced.map(enhancedToOld);
    }
    
    // Fallback to old
    const { data: old } = await supabase
      .from('products')
      .select('*')
      .or(`name.ilike.%${query}%,sku.ilike.%${query}%,description.ilike.%${query}%`);
    
    return old || [];
  },

  /**
   * Get products by category
   */
  async getByCategory(category: string): Promise<OldProduct[]> {
    // Try enhanced first
    const { data: enhanced } = await supabase
      .from('products_enhanced')
      .select('*')
      .eq('category', category)
      .eq('status', 'active');
    
    if (enhanced && enhanced.length > 0) {
      return enhanced.map(enhancedToOld);
    }
    
    // Fallback to old
    const { data: old } = await supabase
      .from('products')
      .select('*')
      .eq('category', category);
    
    return old || [];
  },

  /**
   * Check which system is being used
   */
  async getSystemInfo(): Promise<{ 
    using: 'enhanced' | 'old' | 'both';
    enhancedCount: number;
    oldCount: number;
  }> {
    const { count: enhancedCount } = await supabase
      .from('products_enhanced')
      .select('*', { count: 'exact', head: true });
    
    const { count: oldCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });
    
    const using = enhancedCount && enhancedCount > 0 
      ? (oldCount && oldCount > 0 ? 'both' : 'enhanced')
      : 'old';
    
    return {
      using,
      enhancedCount: enhancedCount || 0,
      oldCount: oldCount || 0,
    };
  },
};

// Export for use in components
export default productAdapter;