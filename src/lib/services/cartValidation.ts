/**
 * CART VALIDATION SERVICE
 * Provides comprehensive cart validation, security checks, and expiration management
 */

import { supabase } from '../supabase-client';
import { CartItemDB } from './business';

export interface CartValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  expiredItems: string[];
  priceChanges: Array<{
    itemId: string;
    productName: string;
    oldPrice: number;
    newPrice: number;
    change: number;
  }>;
  inventoryIssues: Array<{
    itemId: string;
    productName: string;
    requested: number;
    available: number;
  }>;
}

export interface CartSecurityCheck {
  isSecure: boolean;
  riskLevel: 'low' | 'medium' | 'high';
  flags: string[];
  recommendations: string[];
}

export interface CartExpirationInfo {
  isExpired: boolean;
  expiresAt: Date;
  timeRemaining: number; // milliseconds
  warningThreshold: number; // milliseconds (5 minutes)
}

const CART_EXPIRATION_TIME = 30 * 60 * 1000; // 30 minutes
const WARNING_THRESHOLD = 5 * 60 * 1000; // 5 minutes
const MAX_CART_VALUE = 10000; // $10,000 maximum cart value
const MAX_ITEMS_PER_PRODUCT = 10; // Maximum quantity per product
const MAX_TOTAL_ITEMS = 50; // Maximum total items in cart
const SUSPICIOUS_ACTIVITY_THRESHOLD = 5; // Number of rapid additions

export class CartValidationService {
  private cartCreatedAt: Date | null = null;
  private lastValidation: Date | null = null;
  private validationCache = new Map<string, any>();

  /**
   * Initialize cart expiration tracking
   */
  initializeCartExpiration(cartCreatedAt?: Date): void {
    this.cartCreatedAt = cartCreatedAt || new Date();
  }

  /**
   * Get cart expiration information
   */
  getCartExpirationInfo(): CartExpirationInfo {
    if (!this.cartCreatedAt) {
      this.initializeCartExpiration();
    }

    const now = new Date();
    const expiresAt = new Date(this.cartCreatedAt!.getTime() + CART_EXPIRATION_TIME);
    const timeRemaining = expiresAt.getTime() - now.getTime();
    const isExpired = timeRemaining <= 0;

    return {
      isExpired,
      expiresAt,
      timeRemaining: Math.max(0, timeRemaining),
      warningThreshold: WARNING_THRESHOLD,
    };
  }

  /**
   * Extend cart expiration (called on user activity)
   */
  extendCartExpiration(): void {
    this.cartCreatedAt = new Date();
  }

  /**
   * Comprehensive cart validation
   */
  async validateCart(
    items: CartItemDB[], 
    userId?: string, 
    sessionId?: string
  ): Promise<CartValidationResult> {
    const result: CartValidationResult = {
      isValid: true,
      errors: [],
      warnings: [],
      expiredItems: [],
      priceChanges: [],
      inventoryIssues: [],
    };

    // Basic validation
    if (!items || items.length === 0) {
      result.errors.push('Cart is empty');
      result.isValid = false;
      return result;
    }

    // Check cart size limits
    if (items.length > MAX_TOTAL_ITEMS) {
      result.errors.push(`Cart exceeds maximum allowed items (${MAX_TOTAL_ITEMS})`);
      result.isValid = false;
    }

    let totalValue = 0;
    const productQuantities = new Map<string, number>();

    // Validate each item
    for (const item of items) {
      try {
        // Validate item structure
        if (!item.product_id) {
          result.errors.push('Invalid item: missing product ID');
          result.isValid = false;
          continue;
        }

        // Check quantity limits
        if (item.quantity <= 0 || item.quantity > MAX_ITEMS_PER_PRODUCT) {
          result.errors.push(
            `Invalid quantity for ${item.product?.name || 'item'}: must be between 1 and ${MAX_ITEMS_PER_PRODUCT}`
          );
          result.isValid = false;
          continue;
        }

        // Track product quantities
        const existingQty = productQuantities.get(item.product_id) || 0;
        productQuantities.set(item.product_id, existingQty + item.quantity);

        if (productQuantities.get(item.product_id)! > MAX_ITEMS_PER_PRODUCT) {
          result.errors.push(
            `Total quantity for ${item.product?.name || 'product'} exceeds limit (${MAX_ITEMS_PER_PRODUCT})`
          );
          result.isValid = false;
        }

        // Validate variant if specified
        if (item.variant_id) {
          const variantValidation = await this.validateVariant(item);
          if (!variantValidation.isValid) {
            result.errors.push(...variantValidation.errors);
            result.warnings.push(...variantValidation.warnings);
            result.inventoryIssues.push(...variantValidation.inventoryIssues);
            result.priceChanges.push(...variantValidation.priceChanges);
            result.isValid = false;
          }
        }

        // Calculate total value
        const itemPrice = item.variant?.price || item.product?.base_price || 0;
        totalValue += itemPrice * item.quantity;

      } catch (error) {
        console.error('Error validating cart item:', error);
        result.errors.push(`Failed to validate item: ${item.product?.name || 'unknown'}`);
        result.isValid = false;
      }
    }

    // Check total cart value
    if (totalValue > MAX_CART_VALUE) {
      result.errors.push(`Cart total exceeds maximum allowed value ($${MAX_CART_VALUE.toLocaleString()})`);
      result.isValid = false;
    }

    // Check for suspicious activity
    const securityCheck = await this.performSecurityCheck(items, userId, sessionId);
    if (securityCheck.riskLevel === 'high') {
      result.errors.push('Cart flagged for security review');
      result.isValid = false;
    } else if (securityCheck.riskLevel === 'medium') {
      result.warnings.push(...securityCheck.flags);
    }

    // Check cart expiration
    const expirationInfo = this.getCartExpirationInfo();
    if (expirationInfo.isExpired) {
      result.errors.push('Cart has expired. Please refresh and try again.');
      result.isValid = false;
    } else if (expirationInfo.timeRemaining <= WARNING_THRESHOLD) {
      result.warnings.push(
        `Cart expires in ${Math.ceil(expirationInfo.timeRemaining / (60 * 1000))} minutes`
      );
    }

    this.lastValidation = new Date();
    return result;
  }

  /**
   * Validate individual variant
   */
  private async validateVariant(item: CartItemDB): Promise<{
    isValid: boolean;
    errors: string[];
    warnings: string[];
    inventoryIssues: any[];
    priceChanges: any[];
  }> {
    const result = {
      isValid: true,
      errors: [],
      warnings: [],
      inventoryIssues: [],
      priceChanges: [],
    };

    if (!item.variant_id) return result;

    try {
      // Get current variant data
      const { data: variant, error } = await supabase
        .from('product_variants')
        .select(`
          *,
          products (
            id,
            name,
            status,
            is_active
          )
        `)
        .eq('id', item.variant_id)
        .single();

      if (error || !variant) {
        result.errors.push(`Product variant not found: ${item.product?.name || 'unknown'}`);
        result.isValid = false;
        return result;
      }

      // Check product status
      if (!variant.products.is_active || variant.products.status !== 'active') {
        result.errors.push(`Product is no longer available: ${variant.products.name}`);
        result.isValid = false;
      }

      // Check inventory
      const { data: availableQty, error: invError } = await supabase
        .rpc('get_available_inventory', { variant_uuid: item.variant_id });

      if (invError) {
        result.errors.push(`Failed to check inventory for: ${variant.products.name}`);
        result.isValid = false;
      } else if (availableQty < item.quantity) {
        result.inventoryIssues.push({
          itemId: item.id,
          productName: variant.products.name,
          requested: item.quantity,
          available: availableQty,
        });
        
        if (availableQty === 0) {
          result.errors.push(`${variant.products.name} is out of stock`);
          result.isValid = false;
        } else {
          result.warnings.push(
            `Limited stock for ${variant.products.name}: only ${availableQty} available`
          );
        }
      }

      // Check price changes
      const currentPrice = variant.price;
      const cartPrice = item.variant?.price || item.price || 0;
      
      if (Math.abs(currentPrice - cartPrice) > 0.01) {
        const priceChange = ((currentPrice - cartPrice) / cartPrice) * 100;
        
        result.priceChanges.push({
          itemId: item.id,
          productName: variant.products.name,
          oldPrice: cartPrice,
          newPrice: currentPrice,
          change: priceChange,
        });

        if (Math.abs(priceChange) > 5) { // More than 5% change
          result.warnings.push(
            `Price changed for ${variant.products.name}: ${priceChange > 0 ? '+' : ''}${priceChange.toFixed(1)}%`
          );
        }
      }

    } catch (error) {
      console.error('Error validating variant:', error);
      result.errors.push(`Failed to validate: ${item.product?.name || 'unknown'}`);
      result.isValid = false;
    }

    return result;
  }

  /**
   * Perform security checks on cart
   */
  async performSecurityCheck(
    items: CartItemDB[], 
    userId?: string, 
    sessionId?: string
  ): Promise<CartSecurityCheck> {
    const result: CartSecurityCheck = {
      isSecure: true,
      riskLevel: 'low',
      flags: [],
      recommendations: [],
    };

    try {
      // Check for rapid cart modifications
      if (userId || sessionId) {
        const { data: recentActivity } = await supabase
          .from('cart_items')
          .select('created_at')
          .or(`user_id.eq.${userId},session_id.eq.${sessionId}`)
          .gte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString()) // Last 5 minutes
          .order('created_at', { ascending: false });

        if (recentActivity && recentActivity.length > SUSPICIOUS_ACTIVITY_THRESHOLD) {
          result.flags.push('Rapid cart modifications detected');
          result.riskLevel = 'medium';
        }
      }

      // Check for unusual quantities
      const unusualQuantities = items.filter(item => item.quantity > 5);
      if (unusualQuantities.length > 0) {
        result.flags.push('High quantities detected');
        result.recommendations.push('Verify bulk order requirements');
      }

      // Check for high-value items
      const highValueItems = items.filter(item => {
        const price = item.variant?.price || item.product?.base_price || 0;
        return price * item.quantity > 1000;
      });

      if (highValueItems.length > 0) {
        result.flags.push('High-value items in cart');
        result.recommendations.push('Consider fraud protection measures');
        if (result.riskLevel === 'low') result.riskLevel = 'medium';
      }

      // Check for repeated failed attempts (if we had that data)
      // This would require tracking failed checkout attempts by IP/user

      // Geographic risk assessment (would require IP geolocation)
      // This could be implemented with additional data

    } catch (error) {
      console.error('Error performing security check:', error);
      result.flags.push('Security check failed');
      result.riskLevel = 'medium';
    }

    if (result.flags.length > 2) {
      result.riskLevel = 'high';
      result.isSecure = false;
    }

    return result;
  }

  /**
   * Clean up expired carts
   */
  async cleanupExpiredCarts(userId?: string, sessionId?: string): Promise<void> {
    try {
      const expiredAt = new Date(Date.now() - CART_EXPIRATION_TIME).toISOString();

      let query = supabase
        .from('cart_items')
        .delete()
        .lt('created_at', expiredAt);

      if (userId) {
        query = query.eq('user_id', userId);
      } else if (sessionId) {
        query = query.eq('session_id', sessionId);
      }

      const { error } = await query;

      if (error) {
        console.error('Error cleaning up expired carts:', error);
      }
    } catch (error) {
      console.error('Error in cleanup expired carts:', error);
    }
  }

  /**
   * Reserve inventory for checkout
   */
  async reserveInventory(
    items: CartItemDB[], 
    sessionId: string, 
    expirationMinutes: number = 15
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const reservations = [];
      
      for (const item of items) {
        if (item.variant_id) {
          reservations.push({
            variant_id: item.variant_id,
            quantity: item.quantity,
            session_id: sessionId,
            reserved_at: new Date().toISOString(),
            expires_at: new Date(Date.now() + expirationMinutes * 60 * 1000).toISOString(),
          });
        }
      }

      if (reservations.length === 0) {
        return { success: true };
      }

      const { error } = await supabase
        .from('stock_reservations')
        .insert(reservations);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      console.error('Error reserving inventory:', error);
      return { success: false, error: 'Failed to reserve inventory' };
    }
  }

  /**
   * Release inventory reservations
   */
  async releaseInventoryReservations(sessionId: string): Promise<void> {
    try {
      await supabase
        .from('stock_reservations')
        .delete()
        .eq('session_id', sessionId);
    } catch (error) {
      console.error('Error releasing inventory reservations:', error);
    }
  }

  /**
   * Get cart health score (0-100)
   */
  getCartHealthScore(validationResult: CartValidationResult): number {
    let score = 100;

    // Deduct for errors
    score -= validationResult.errors.length * 20;

    // Deduct for warnings
    score -= validationResult.warnings.length * 5;

    // Deduct for inventory issues
    score -= validationResult.inventoryIssues.length * 10;

    // Deduct for price changes
    score -= validationResult.priceChanges.length * 5;

    return Math.max(0, score);
  }
}

// Export singleton instance
export const cartValidationService = new CartValidationService();
export default cartValidationService;