/**
 * LEGACY SUPABASE FILE - TO BE REMOVED
 * This file contains the old KCTMenswearAPI class and types
 * Will be gradually migrated to the new unified services
 * Last updated: 2025-08-07
 */

// Re-export the new unified services for backward compatibility
export {
  supabase,
  getSupabaseClient,
  // Auth services
  signUp,
  signIn,
  signInWithGoogle,
  signOut,
  resetPassword,
  getProfile,
  updateProfile,
  updateMeasurements,
  checkAdminAccess,
  // Product services  
  fetchProductsWithImages,
  getProduct,
  getProductById,
  getProductsViaFunction,
  getProductImageUrl,
  formatPrice,
  isOnSale,
  getDisplayPrice,
  testSupabaseConnection,
  getSizeTemplate,
  syncStripeProducts,
  // Business services
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  transferGuestCart,
  createCheckout,
  getUserOrders,
  getOrder,
  getWishlist,
  addToWishlist,
  removeFromWishlist,
  getSavedOutfits,
  saveOutfit,
  deleteOutfit,
  getUserPreferences,
  updateUserPreferences,
  createWedding,
  getWeddingByCode,
  getAllWeddings,
  getInventoryStatus,
  // Types
  type UserProfile,
  type Product,
  type ProductImage,
  type ProductVariant,
  type CartItem,
  type CartItemDB,
  type Order,
  type OrderItem,
  type WishlistItem,
  type SavedOutfit,
  type Wedding,
  type WeddingMember,
  type UserPreferences,
  type SizeTemplate,
  type ProductSmartTag,
} from './services';

// Legacy class wrapper for backward compatibility
export class KCTMenswearAPI {
  static async getProducts(filters?: {
    category?: string;
    product_type?: 'core' | 'catalog' | 'all';
    search?: string;
    limit?: number;
    offset?: number;
  }) {
    const { getProductsViaFunction } = await import('./services');
    const result = await getProductsViaFunction(filters);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to get products');
    }
  }

  static async createCheckout(items: any[], options?: {
    success_url?: string;
    cancel_url?: string;
    customer_email?: string;
  }) {
    const { createCheckout } = await import('./services');
    const result = await createCheckout(items, options);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to create checkout');
    }
  }

  static async getOrder(identifier: {
    id?: string;
    order_number?: string;
    session_id?: string;
  }) {
    const { getOrder } = await import('./services');
    const result = await getOrder(identifier);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to get order');
    }
  }

  static async syncStripeProducts() {
    const { syncStripeProducts } = await import('./services');
    const result = await syncStripeProducts();
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to sync Stripe products');
    }
  }

  // Direct database queries for authenticated users
  static async getUserOrders(userId: string) {
    const { getUserOrders } = await import('./services');
    const result = await getUserOrders(userId);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to get user orders');
    }
  }

  static async getInventoryStatus(variantId: string) {
    const { getInventoryStatus } = await import('./services');
    const result = await getInventoryStatus(variantId);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to get inventory status');
    }
  }

  // Authentication Methods
  static async signUp(email: string, password: string, userData?: any) {
    const { signUp } = await import('./services');
    const result = await signUp(email, password, userData);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to sign up');
    }
  }

  static async signIn(email: string, password: string) {
    const { signIn } = await import('./services');
    const result = await signIn(email, password);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to sign in');
    }
  }

  static async signInWithGoogle() {
    const { signInWithGoogle } = await import('./services');
    const result = await signInWithGoogle();
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to sign in with Google');
    }
  }

  static async signOut() {
    const { signOut } = await import('./services');
    const result = await signOut();
    if (!result.success) {
      throw new Error(result.error || 'Failed to sign out');
    }
  }

  static async resetPassword(email: string) {
    const { resetPassword } = await import('./services');
    const result = await resetPassword(email);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to reset password');
    }
  }

  // User Profile Methods
  static async getProfile(userId: string) {
    const { getProfile } = await import('./services');
    const result = await getProfile(userId);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to get profile');
    }
  }

  static async updateProfile(userId: string, updates: any) {
    const { updateProfile } = await import('./services');
    const result = await updateProfile(userId, updates);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to update profile');
    }
  }

  static async updateMeasurements(userId: string, measurements: Record<string, any>) {
    const { updateMeasurements } = await import('./services');
    const result = await updateMeasurements(userId, measurements);
    if (result.success) {
      return result.data;
    } else {
      throw new Error(result.error || 'Failed to update measurements');
    }
  }

  // ... (continue with other methods as needed for backward compatibility)
}