import React, { createContext, useContext, useEffect, useState } from 'react';
import { CartItemDB, getCart, addToCart, updateCartItem, removeFromCart, clearCart as clearCartService, transferGuestCart } from '@/lib/services';
import { cartValidationService, CartValidationResult, CartExpirationInfo } from '@/lib/services/cartValidation';
import { useAuth } from './AuthContext';
import { toast } from 'sonner';
import { storage } from '@/lib/prefixed-storage';

interface CartContextType {
  items: CartItemDB[];
  loading: boolean;
  validationResult: CartValidationResult | null;
  expirationInfo: CartExpirationInfo | null;
  addItem: (productId: string, variantId?: string, quantity?: number, customizations?: Record<string, any>) => Promise<void>;
  updateItem: (itemId: string, quantity?: number, customizations?: Record<string, any>) => Promise<void>;
  removeItem: (itemId: string) => Promise<void>;
  clearCart: () => Promise<void>;
  getCartTotal: () => number;
  getItemCount: () => number;
  refreshCart: () => Promise<void>;
  validateCart: () => Promise<CartValidationResult>;
  extendCartExpiration: () => void;
  getCartHealthScore: () => number;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [items, setItems] = useState<CartItemDB[]>([]);
  const [loading, setLoading] = useState(false);
  const [validationResult, setValidationResult] = useState<CartValidationResult | null>(null);
  const [expirationInfo, setExpirationInfo] = useState<CartExpirationInfo | null>(null);

  // Generate session ID for guest users
  const [sessionId] = useState(() => {
    const stored = storage.getItem('cart_session_id');
    if (stored) return stored;
    const newId = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    storage.setItem('cart_session_id', newId);
    return newId;
  });

  useEffect(() => {
    loadCart();
    
    // Initialize cart validation service
    cartValidationService.initializeCartExpiration();
    updateExpirationInfo();
  }, [user?.id]);

  useEffect(() => {
    // Transfer guest cart when user logs in
    if (user?.id && sessionId) {
      handleGuestCartTransfer();
    }
  }, [user?.id, sessionId]);

  useEffect(() => {
    // Set up expiration timer
    const interval = setInterval(() => {
      updateExpirationInfo();
    }, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    // Validate cart when items change
    if (items.length > 0) {
      validateCartItems();
    } else {
      setValidationResult(null);
    }
  }, [items]);

  const loadCart = async () => {
    setLoading(true);
    try {
      const result = await getCart(user?.id, sessionId);
      if (result.success) {
        setItems(result.data);
      } else {
        throw new Error(result.error || 'Failed to load cart');
      }
    } catch (error) {
      console.error('Error loading cart:', error);
      toast.error('Failed to load cart');
    } finally {
      setLoading(false);
    }
  };

  const handleGuestCartTransfer = async () => {
    try {
      const result = await transferGuestCart(sessionId, user!.id);
      if (!result.success) {
        throw new Error(result.error || 'Failed to transfer cart');
      }
      await loadCart(); // Reload cart after transfer
    } catch (error) {
      console.error('Error transferring guest cart:', error);
    }
  };

  const addItem = async (
    productId: string,
    variantId?: string,
    quantity: number = 1,
    customizations?: Record<string, any>
  ) => {
    try {
      // Check if item already exists
      const existingItem = items.find(
        item => item.product_id === productId && 
                 (variantId ? item.variant_id === variantId : !item.variant_id)
      );

      if (existingItem) {
        // Update existing item
        await updateItem(existingItem.id, existingItem.quantity + quantity, customizations);
      } else {
        // Add new item
        const result = await addToCart({
          product_id: productId,
          variant_id: variantId,
          quantity,
          customizations,
          user_id: user?.id,
          session_id: user?.id ? undefined : sessionId
        });
        if (!result.success) {
          throw new Error(result.error || 'Failed to add item');
        }
        await loadCart();
        toast.success('Item added to cart');
      }
    } catch (error) {
      console.error('Error adding item to cart:', error);
      toast.error('Failed to add item to cart');
    }
  };

  const updateItem = async (itemId: string, quantity?: number, customizations?: Record<string, any>) => {
    try {
      if (quantity === 0) {
        await removeItem(itemId);
        return;
      }

      const result = await updateCartItem(itemId, { quantity, customizations });
      if (!result.success) {
        throw new Error(result.error || 'Failed to update item');
      }
      await loadCart();
    } catch (error) {
      console.error('Error updating cart item:', error);
      toast.error('Failed to update item');
    }
  };

  const removeItem = async (itemId: string) => {
    try {
      const result = await removeFromCart(itemId);
      if (!result.success) {
        throw new Error(result.error || 'Failed to remove item');
      }
      await loadCart();
      toast.success('Item removed from cart');
    } catch (error) {
      console.error('Error removing cart item:', error);
      toast.error('Failed to remove item');
    }
  };

  const clearCart = async () => {
    try {
      const result = await clearCartService(user?.id, sessionId);
      if (!result.success) {
        throw new Error(result.error || 'Failed to clear cart');
      }
      setItems([]);
      toast.success('Cart cleared');
    } catch (error) {
      console.error('Error clearing cart:', error);
      toast.error('Failed to clear cart');
    }
  };

  const getCartTotal = () => {
    return items.reduce((total, item) => {
      const price = item.variant?.price || item.product?.base_price || 0;
      return total + (price * item.quantity);
    }, 0);
  };

  const getItemCount = () => {
    return items.reduce((count, item) => count + item.quantity, 0);
  };

  const refreshCart = async () => {
    await loadCart();
  };

  const updateExpirationInfo = () => {
    const info = cartValidationService.getCartExpirationInfo();
    setExpirationInfo(info);

    // Show warnings as cart approaches expiration
    if (info.timeRemaining <= 5 * 60 * 1000 && info.timeRemaining > 4 * 60 * 1000) {
      toast.warning('Your cart will expire in 5 minutes. Complete your purchase soon!');
    } else if (info.timeRemaining <= 1 * 60 * 1000 && info.timeRemaining > 0) {
      toast.error('Your cart will expire in 1 minute!');
    } else if (info.isExpired) {
      toast.error('Your cart has expired. Items will be removed.');
      clearCart();
    }
  };

  const validateCartItems = async () => {
    try {
      const result = await cartValidationService.validateCart(items, user?.id, sessionId);
      setValidationResult(result);

      // Show critical errors
      if (result.errors.length > 0) {
        result.errors.forEach(error => {
          toast.error(error);
        });
      }

      // Show warnings
      if (result.warnings.length > 0) {
        result.warnings.forEach(warning => {
          toast.warning(warning);
        });
      }

      // Handle inventory issues
      if (result.inventoryIssues.length > 0) {
        result.inventoryIssues.forEach(issue => {
          toast.warning(
            `${issue.productName}: Only ${issue.available} available (you have ${issue.requested})`
          );
        });
      }

      // Handle price changes
      if (result.priceChanges.length > 0) {
        result.priceChanges.forEach(change => {
          const changeText = change.change > 0 ? 'increased' : 'decreased';
          toast.warning(
            `Price ${changeText} for ${change.productName}: $${change.oldPrice.toFixed(2)} → $${change.newPrice.toFixed(2)}`
          );
        });
      }

    } catch (error) {
      console.error('Error validating cart:', error);
    }
  };

  const validateCart = async (): Promise<CartValidationResult> => {
    const result = await cartValidationService.validateCart(items, user?.id, sessionId);
    setValidationResult(result);
    return result;
  };

  const extendCartExpiration = () => {
    cartValidationService.extendCartExpiration();
    updateExpirationInfo();
  };

  const getCartHealthScore = (): number => {
    if (!validationResult) return 100;
    return cartValidationService.getCartHealthScore(validationResult);
  };

  const value = {
    items,
    loading,
    validationResult,
    expirationInfo,
    addItem,
    updateItem,
    removeItem,
    clearCart,
    getCartTotal,
    getItemCount,
    refreshCart,
    validateCart,
    extendCartExpiration,
    getCartHealthScore,
  };

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const context = useContext(CartContext);
  if (context === undefined) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
}