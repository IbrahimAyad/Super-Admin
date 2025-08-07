/**
 * SHARED SUPABASE SERVICE
 * This file handles cart, orders, wishlist, outfits, and other business logic
 * Last updated: 2024-08-05
 */

import { supabase } from './supabase-products';

// Cart Types and Methods
export interface CartItem {
  product_id?: string;
  variant_id?: string;
  stripe_price_id?: string;
  quantity: number;
  customization?: Record<string, any>;
}

export interface CartItemDB {
  id: string;
  user_id?: string;
  session_id?: string;
  product_id: string;
  variant_id?: string;
  quantity: number;
  customizations?: Record<string, any>;
  saved_for_later: boolean;
  created_at: string;
  product?: any;
  variant?: any;
}

export interface WishlistItem {
  id: string;
  user_id: string;
  product_id: string;
  variant_id?: string;
  notify_on_sale: boolean;
  created_at: string;
  product?: any;
  variant?: any;
}

export interface SavedOutfit {
  id: string;
  user_id: string;
  name: string;
  items: any[];
  occasion?: string;
  is_public: boolean;
  created_at: string;
}

export interface Order {
  id: string;
  order_number: string;
  stripe_checkout_session_id?: string;
  stripe_payment_intent_id?: string;
  customer_id?: string;
  guest_email?: string;
  items: any[];
  subtotal: number;
  tax_amount: number;
  shipping_amount: number;
  total: number;
  currency: string;
  status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refunded';
  shipping_address?: any;
  billing_address?: any;
  notes?: string;
  created_at: string;
  updated_at: string;
  order_items?: any[];
  customer?: any;
  totals?: {
    subtotal: number;
    tax: number;
    shipping: number;
    total: number;
  };
  tracking?: {
    status: string;
    created_at: string;
    updated_at: string;
  };
}

/**
 * Cart Management
 */
export async function getCart(userId?: string, sessionId?: string) {
  try {
    const { data, error } = await supabase.rpc('get_cart_items', {
      p_user_id: userId || null,
      p_session_id: sessionId || null
    });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getCart error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function addToCart(item: {
  product_id: string;
  variant_id?: string;
  quantity: number;
  customizations?: Record<string, any>;
  user_id?: string;
  session_id?: string;
}) {
  try {
    const { data, error } = await supabase.rpc('add_to_cart', {
      p_product_id: item.product_id,
      p_variant_id: item.variant_id || null,
      p_quantity: item.quantity,
      p_customizations: item.customizations || {},
      p_user_id: item.user_id || null,
      p_session_id: item.session_id || null
    });

    if (error) throw error;
    return {
      success: true,
      data: data?.[0] || data,
      error: null
    };
  } catch (error) {
    console.error('addToCart error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function updateCartItem(itemId: string, updates: { quantity?: number; customizations?: Record<string, any> }) {
  try {
    const { data, error } = await supabase.rpc('update_cart_item', {
      p_item_id: itemId,
      p_quantity: updates.quantity || null,
      p_customizations: updates.customizations || null
    });

    if (error) throw error;
    return {
      success: true,
      data: data?.[0] || data,
      error: null
    };
  } catch (error) {
    console.error('updateCartItem error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function removeFromCart(itemId: string) {
  try {
    const { data, error } = await supabase.rpc('remove_cart_item', {
      p_item_id: itemId
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('removeFromCart error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function clearCart(userId?: string, sessionId?: string) {
  try {
    const { data, error } = await supabase.rpc('clear_cart', {
      p_user_id: userId || null,
      p_session_id: sessionId || null
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('clearCart error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function transferGuestCart(sessionId: string, userId: string) {
  try {
    const { data, error } = await supabase.rpc('transfer_guest_cart', {
      p_session_id: sessionId,
      p_user_id: userId
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('transferGuestCart error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Wishlist Management
 */
export async function getWishlist(userId: string) {
  try {
    const { data, error } = await supabase
      .from('wishlists')
      .select(`
        *,
        product:products(*),
        variant:product_variants(*)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getWishlist error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function addToWishlist(userId: string, productId: string, variantId?: string) {
  try {
    const { data, error } = await supabase
      .from('wishlists')
      .insert({
        user_id: userId,
        product_id: productId,
        variant_id: variantId
      })
      .select(`
        *,
        product:products(*),
        variant:product_variants(*)
      `)
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('addToWishlist error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function removeFromWishlist(userId: string, productId: string, variantId?: string) {
  try {
    let query = supabase
      .from('wishlists')
      .delete()
      .eq('user_id', userId)
      .eq('product_id', productId);

    if (variantId) {
      query = query.eq('variant_id', variantId);
    }

    const { error } = await query;
    if (error) throw error;
    
    return {
      success: true,
      error: null
    };
  } catch (error) {
    console.error('removeFromWishlist error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Saved Outfits Management
 */
export async function getSavedOutfits(userId: string) {
  try {
    const { data, error } = await supabase
      .from('saved_outfits')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getSavedOutfits error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function saveOutfit(userId: string, outfit: {
  name: string;
  items: any[];
  occasion?: string;
  is_public?: boolean;
}) {
  try {
    const { data, error } = await supabase
      .from('saved_outfits')
      .insert({
        user_id: userId,
        ...outfit
      })
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('saveOutfit error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function deleteOutfit(outfitId: string) {
  try {
    const { error } = await supabase
      .from('saved_outfits')
      .delete()
      .eq('id', outfitId);

    if (error) throw error;
    return {
      success: true,
      error: null
    };
  } catch (error) {
    console.error('deleteOutfit error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Orders Management
 */
export async function getUserOrders(userId: string) {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        *,
        order_items (*),
        customers (*)
      `)
      .eq('customers.auth_user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getUserOrders error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getOrder(identifier: {
  id?: string;
  order_number?: string;
  session_id?: string;
}) {
  try {
    const { data, error } = await supabase.functions.invoke('get-order', {
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
    console.error('getOrder error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Checkout and Payment
 */
export async function createCheckout(items: CartItem[], options?: {
  success_url?: string;
  cancel_url?: string;
  customer_email?: string;
}) {
  try {
    const { data, error } = await supabase.functions.invoke('create-checkout', {
      body: { items, ...options },
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('createCheckout error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Inventory Management
 */
export async function getInventoryStatus(variantId: string) {
  try {
    const { data, error } = await supabase
      .rpc('get_available_inventory', { variant_uuid: variantId });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getInventoryStatus error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * User Preferences
 */
export interface UserPreferences {
  id: string;
  user_id: string;
  email_marketing: boolean;
  order_updates: boolean;
  style_tips: boolean;
}

export async function getUserPreferences(userId: string) {
  try {
    const { data, error } = await supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getUserPreferences error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function updateUserPreferences(userId: string, preferences: Partial<UserPreferences>) {
  try {
    const { data, error } = await supabase
      .from('user_preferences')
      .upsert({
        user_id: userId,
        ...preferences
      })
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateUserPreferences error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Wedding Management
 */
export interface Wedding {
  id: string;
  wedding_code: string;
  couple_names: string;
  event_date: string;
  venue_name?: string;
  party_size: number;
  color_scheme: {
    primary: string;
    accent?: string;
  };
  coordinator_email: string;
  coordinator_phone?: string;
  discount_percentage: number;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface WeddingMember {
  id: string;
  wedding_id: string;
  role: string;
  name: string;
  email?: string;
  phone?: string;
  measurements: Record<string, any>;
  measurement_status: string;
  assigned_outfit: Record<string, any>;
  outfit_status: string;
  order_id?: string;
  created_at: string;
  updated_at: string;
}

export async function createWedding(wedding: {
  couple_names: string;
  event_date: string;
  venue_name?: string;
  party_size: number;
  color_scheme: { primary: string; accent?: string };
  coordinator_email: string;
  coordinator_phone?: string;
}) {
  try {
    // Generate unique 6-character wedding code
    const generateCode = () => Math.random().toString(36).substring(2, 8).toUpperCase();
    let wedding_code = generateCode();
    
    // Ensure code is unique
    let codeExists = true;
    while (codeExists) {
      const { data } = await supabase
        .from('weddings')
        .select('id')
        .eq('wedding_code', wedding_code)
        .single();
      
      if (!data) codeExists = false;
      else wedding_code = generateCode();
    }

    // Calculate discount based on party size
    const discount_percentage = wedding.party_size >= 10 ? 20 : 
                               wedding.party_size >= 7 ? 15 : 
                               wedding.party_size >= 5 ? 10 : 5;

    const { data, error } = await supabase
      .from('weddings')
      .insert({
        ...wedding,
        wedding_code,
        discount_percentage,
        status: 'planning'
      })
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('createWedding error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getWeddingByCode(code: string) {
  try {
    const { data, error } = await supabase
      .from('weddings')
      .select(`
        *,
        wedding_members(*)
      `)
      .eq('wedding_code', code.toUpperCase())
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getWeddingByCode error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function addWeddingMember(weddingId: string, member: {
  role: string;
  name: string;
  email?: string;
  phone?: string;
}) {
  try {
    const { data, error } = await supabase
      .from('wedding_members')
      .insert({
        wedding_id: weddingId,
        ...member
      })
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('addWeddingMember error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function updateWeddingMemberMeasurements(memberId: string, measurements: Record<string, any>) {
  try {
    const { data, error } = await supabase
      .from('wedding_members')
      .update({
        measurements,
        measurement_status: 'completed',
        updated_at: new Date().toISOString()
      })
      .eq('id', memberId)
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateWeddingMemberMeasurements error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getWeddingMembers(weddingId: string) {
  try {
    const { data, error } = await supabase
      .from('wedding_members')
      .select('*')
      .eq('wedding_id', weddingId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getWeddingMembers error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getUserWeddings(userEmail: string) {
  try {
    const { data, error } = await supabase
      .from('weddings')
      .select(`
        *,
        wedding_members!inner(*)
      `)
      .or(`coordinator_email.eq.${userEmail},wedding_members.email.eq.${userEmail}`);

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getUserWeddings error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getAllWeddings() {
  try {
    const { data, error } = await supabase
      .from('weddings')
      .select(`
        *,
        wedding_members(*)
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return {
      success: true,
      data: data || [],
      error: null
    };
  } catch (error) {
    console.error('getAllWeddings error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getWeddingStatistics() {
  try {
    const { data: weddings, error } = await supabase
      .from('weddings')
      .select('*');

    if (error) throw error;

    const { data: members, error: membersError } = await supabase
      .from('wedding_members')
      .select('*');

    if (membersError) throw membersError;

    return {
      success: true,
      data: {
        totalWeddings: weddings?.length || 0,
        totalMembers: members?.length || 0,
        upcomingWeddings: weddings?.filter(w => new Date(w.event_date) > new Date()).length || 0,
        completedMeasurements: members?.filter(m => m.measurement_status === 'complete').length || 0
      },
      error: null
    };
  } catch (error) {
    console.error('getWeddingStatistics error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Product Sync and Admin Functions
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

export async function getProducts(filters?: {
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
    console.error('getProducts error:', error);
    return {
      success: false,
      data: [],
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}