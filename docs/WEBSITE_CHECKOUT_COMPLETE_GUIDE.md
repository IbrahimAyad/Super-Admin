# Complete Website Checkout Integration Guide
**Last Updated**: August 12, 2025  
**System Version**: Production Ready  
**API Version**: Stripe 2023-10-16

---

## 🎯 Overview

This guide provides **complete implementation details** for integrating your website with the KCT Menswear admin system. The checkout system supports both:
- **Core Products**: Your 28 existing Stripe products (tuxedos, suits, etc.)
- **Catalog Products**: Products in Supabase database (183 existing + new imports)

---

## 🔑 Environment Configuration

### Required Environment Variables
```env
# Supabase (Required)
NEXT_PUBLIC_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24

# Stripe (Required - Publishable key only!)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW

# Application
NEXT_PUBLIC_APP_URL=https://kctmenswear.com
```

---

## 📦 1. Product Display Implementation

### Fetching Products from Multiple Sources

```javascript
// services/products.js
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export async function getProducts(options = {}) {
  const { category, limit = 50, offset = 0 } = options;
  
  // Fetch catalog products from Supabase
  let query = supabase
    .from('products')
    .select(`
      *,
      product_variants (
        id,
        size,
        color,
        sku,
        price,
        inventory_quantity
      ),
      product_images (
        image_url,
        alt_text,
        is_primary
      )
    `)
    .eq('status', 'active')
    .range(offset, offset + limit - 1);
  
  if (category) {
    query = query.eq('category', category);
  }
  
  const { data: catalogProducts, error } = await query;
  
  if (error) {
    console.error('Error fetching products:', error);
    return [];
  }
  
  // Core products are displayed separately or merged
  // They use stripe_price_id for checkout
  
  return catalogProducts;
}

// Get single product with all details
export async function getProduct(productId) {
  const { data, error } = await supabase
    .from('products')
    .select(`
      *,
      product_variants (*),
      product_images (*),
      product_reviews (
        rating,
        comment,
        created_at,
        customers (
          first_name,
          last_name
        )
      )
    `)
    .eq('id', productId)
    .single();
  
  return data;
}
```

### Core Products Configuration
```javascript
// config/coreProducts.js
// Your 28 Stripe products that aren't in the database
export const CORE_PRODUCTS = [
  {
    id: 'core_tux_001',
    name: 'Classic Black Tuxedo',
    stripe_product_id: 'prod_xxxxx',
    stripe_price_id: 'price_xxxxx',
    price: 599.99,
    category: 'Tuxedos',
    image: '/images/tuxedos/classic-black.jpg',
    sizes: ['36R', '38R', '40R', '42R', '44R', '46R', '48R']
  },
  // ... rest of your 28 core products
];
```

---

## 🛒 2. Shopping Cart Implementation

### Cart Context with Hybrid Product Support
```javascript
// contexts/CartContext.jsx
import { createContext, useContext, useState, useEffect } from 'react';

const CartContext = createContext();

export function CartProvider({ children }) {
  const [cart, setCart] = useState([]);
  const [cartId, setCartId] = useState(null);

  useEffect(() => {
    // Load cart from localStorage
    const savedCart = localStorage.getItem('cart');
    const savedCartId = localStorage.getItem('cart_id');
    
    if (savedCart) {
      setCart(JSON.parse(savedCart));
    }
    
    if (!savedCartId) {
      // Generate unique cart ID for tracking
      const newCartId = `cart_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('cart_id', newCartId);
      setCartId(newCartId);
    } else {
      setCartId(savedCartId);
    }
  }, []);

  const addToCart = (product, variant = null, quantity = 1) => {
    const cartItem = {
      // Common fields
      id: product.id,
      name: product.name,
      quantity,
      image: product.image || product.image_url,
      
      // For CORE products (from Stripe)
      ...(product.stripe_price_id && {
        type: 'core',
        stripe_price_id: product.stripe_price_id,
        stripe_product_id: product.stripe_product_id,
        price: product.price,
        size: variant?.size || product.default_size
      }),
      
      // For CATALOG products (from Supabase)
      ...(variant && {
        type: 'catalog',
        variant_id: variant.id,
        product_id: product.id,
        sku: variant.sku,
        price: variant.price || product.base_price,
        size: variant.size,
        color: variant.color
      })
    };
    
    setCart(prev => {
      const existing = prev.find(item => 
        item.type === 'core' 
          ? item.stripe_price_id === cartItem.stripe_price_id
          : item.variant_id === cartItem.variant_id
      );
      
      if (existing) {
        return prev.map(item =>
          item === existing
            ? { ...item, quantity: item.quantity + quantity }
            : item
        );
      }
      
      return [...prev, cartItem];
    });
  };

  const updateQuantity = (itemId, quantity) => {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }
    
    setCart(prev =>
      prev.map(item =>
        item.id === itemId ? { ...item, quantity } : item
      )
    );
  };

  const removeFromCart = (itemId) => {
    setCart(prev => prev.filter(item => item.id !== itemId));
  };

  const clearCart = () => {
    setCart([]);
    localStorage.removeItem('cart');
  };

  const getCartTotal = () => {
    return cart.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(cart));
  }, [cart]);

  return (
    <CartContext.Provider value={{
      cart,
      cartId,
      addToCart,
      updateQuantity,
      removeFromCart,
      clearCart,
      getCartTotal,
      itemCount: cart.reduce((sum, item) => sum + item.quantity, 0)
    }}>
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => useContext(CartContext);
```

---

## 💳 3. Secure Checkout Implementation

### Complete Checkout Component
```javascript
// components/Checkout.jsx
import { useState } from 'react';
import { useCart } from '@/contexts/CartContext';
import { useAuth } from '@/contexts/AuthContext';
import { createClient } from '@supabase/supabase-js';
import { loadStripe } from '@stripe/stripe-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY);

export function Checkout() {
  const { cart, cartId, clearCart } = useCart();
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState(user?.email || '');
  const [error, setError] = useState(null);

  const handleCheckout = async () => {
    setLoading(true);
    setError(null);

    try {
      // Prepare items for checkout
      const items = cart.map(item => {
        if (item.type === 'core') {
          // Core product from Stripe
          return {
            type: 'stripe',
            stripe_price_id: item.stripe_price_id,
            quantity: item.quantity,
            customization: {
              size: item.size
            }
          };
        } else {
          // Catalog product from Supabase
          return {
            type: 'catalog',
            variant_id: item.variant_id,
            product_id: item.product_id,
            quantity: item.quantity,
            price: item.price,
            name: item.name,
            sku: item.sku,
            customization: {
              size: item.size,
              color: item.color
            }
          };
        }
      });

      // Create checkout session via Edge Function
      const { data, error: checkoutError } = await supabase.functions.invoke(
        'create-checkout-secure',
        {
          body: {
            items,
            customer_email: email,
            user_id: user?.id,
            cart_id: cartId,
            success_url: `${window.location.origin}/order-success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${window.location.origin}/cart`,
            metadata: {
              cart_id: cartId,
              user_id: user?.id || null,
              source: 'website'
            },
            // Optional: Add shipping address collection
            shipping_address_collection: {
              allowed_countries: ['US', 'CA']
            },
            // Optional: Custom fields
            custom_fields: [
              {
                key: 'gift_message',
                label: 'Gift Message (Optional)',
                type: 'text',
                optional: true
              }
            ]
          }
        }
      );

      if (checkoutError) {
        throw new Error(checkoutError.message);
      }

      if (!data?.url) {
        throw new Error('Failed to create checkout session');
      }

      // Redirect to Stripe Checkout
      window.location.href = data.url;
      
    } catch (err) {
      console.error('Checkout error:', err);
      setError(err.message || 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Guest checkout email input
  const GuestEmailInput = () => (
    <div className="guest-checkout">
      <h3>Guest Checkout</h3>
      <input
        type="email"
        placeholder="Enter your email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
        className="email-input"
      />
      <p className="hint">We'll use this to send your order confirmation</p>
    </div>
  );

  return (
    <div className="checkout-container">
      <h2>Checkout</h2>
      
      {/* Order Summary */}
      <div className="order-summary">
        <h3>Order Summary</h3>
        {cart.map(item => (
          <div key={item.id} className="cart-item">
            <span>{item.name}</span>
            <span>{item.size}</span>
            <span>{item.quantity} × ${item.price}</span>
          </div>
        ))}
        <div className="total">
          <strong>Total: ${cart.reduce((sum, item) => sum + (item.price * item.quantity), 0).toFixed(2)}</strong>
        </div>
      </div>

      {/* Guest or User Email */}
      {!user && <GuestEmailInput />}
      {user && (
        <div className="user-info">
          <p>Checking out as: {user.email}</p>
        </div>
      )}

      {/* Error Display */}
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {/* Checkout Button */}
      <button
        onClick={handleCheckout}
        disabled={loading || cart.length === 0 || (!user && !email)}
        className="checkout-button"
      >
        {loading ? 'Processing...' : 'Proceed to Payment'}
      </button>

      {/* Security badges */}
      <div className="security-badges">
        <img src="/stripe-badge.png" alt="Secured by Stripe" />
        <p>🔒 Your payment information is secure and encrypted</p>
      </div>
    </div>
  );
}
```

---

## ✅ 4. Order Success Page

```javascript
// pages/order-success.jsx
import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export default function OrderSuccess() {
  const router = useRouter();
  const { session_id } = router.query;
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (session_id) {
      fetchOrder();
    }
  }, [session_id]);

  const fetchOrder = async () => {
    try {
      // Fetch order by Stripe session ID
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items (*),
          customers (
            first_name,
            last_name,
            email
          )
        `)
        .eq('stripe_checkout_session_id', session_id)
        .single();

      if (data) {
        setOrder(data);
        // Clear the cart
        localStorage.removeItem('cart');
        localStorage.removeItem('cart_id');
      }
    } catch (error) {
      console.error('Error fetching order:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Loading your order...</div>;
  }

  if (!order) {
    return <div>Order not found</div>;
  }

  return (
    <div className="order-success">
      <div className="success-icon">✓</div>
      <h1>Thank You for Your Order!</h1>
      
      <div className="order-details">
        <h2>Order #{order.order_number}</h2>
        <p>We've sent a confirmation email to {order.customers?.email || order.guest_email}</p>
        
        <div className="order-summary">
          <h3>Order Summary</h3>
          {order.order_items?.map(item => (
            <div key={item.id} className="order-item">
              <span>{item.name}</span>
              <span>{item.quantity} × ${(item.unit_price / 100).toFixed(2)}</span>
            </div>
          ))}
          
          <div className="order-total">
            <strong>Total: ${order.total_amount}</strong>
          </div>
        </div>

        <div className="shipping-info">
          <h3>Shipping To:</h3>
          <p>
            {order.shipping_address?.name}<br />
            {order.shipping_address?.address?.line1}<br />
            {order.shipping_address?.address?.city}, {order.shipping_address?.address?.state} {order.shipping_address?.address?.postal_code}
          </p>
        </div>

        <div className="next-steps">
          <h3>What's Next?</h3>
          <ul>
            <li>You'll receive an email confirmation shortly</li>
            <li>We'll notify you when your order ships</li>
            <li>Track your order status in your account</li>
          </ul>
        </div>

        <div className="actions">
          <button onClick={() => router.push('/')}>
            Continue Shopping
          </button>
          {order.user_id && (
            <button onClick={() => router.push('/account/orders')}>
              View Order History
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## 🔄 5. Real-time Inventory Updates

```javascript
// hooks/useInventory.js
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export function useInventory(variantId) {
  const [inventory, setInventory] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!variantId) return;

    // Initial fetch
    fetchInventory();

    // Subscribe to real-time updates
    const subscription = supabase
      .channel(`variant_${variantId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'product_variants',
          filter: `id=eq.${variantId}`
        },
        (payload) => {
          setInventory(payload.new.inventory_quantity);
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [variantId]);

  const fetchInventory = async () => {
    const { data, error } = await supabase
      .from('product_variants')
      .select('inventory_quantity')
      .eq('id', variantId)
      .single();

    if (data) {
      setInventory(data.inventory_quantity);
    }
    setLoading(false);
  };

  return { inventory, loading };
}
```

---

## 🚦 6. Testing Checklist

### Development Testing
```javascript
// Test with Stripe test keys first
const TEST_CARDS = {
  success: '4242 4242 4242 4242',
  decline: '4000 0000 0000 0002',
  authentication: '4000 0025 0000 3155'
};
```

### Complete Test Flow
- [ ] **Product Display**
  - [ ] Core products show with Stripe price IDs
  - [ ] Catalog products show with variants
  - [ ] Images load from Cloudflare R2

- [ ] **Cart Functionality**
  - [ ] Add core product to cart
  - [ ] Add catalog product to cart
  - [ ] Update quantities
  - [ ] Remove items
  - [ ] Cart persists on refresh

- [ ] **Checkout Process**
  - [ ] Guest checkout works
  - [ ] User checkout works
  - [ ] Mixed cart (core + catalog) processes
  - [ ] Redirects to Stripe Checkout
  - [ ] Returns to success page

- [ ] **Order Confirmation**
  - [ ] Order appears in database
  - [ ] Customer record created
  - [ ] Inventory updated (catalog products)
  - [ ] Confirmation email sent
  - [ ] Success page shows order details

---

## 🔐 7. Security Considerations

### Required Security Headers
```javascript
// middleware.js or next.config.js
const securityHeaders = [
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self' https://*.stripe.com https://*.supabase.co"
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  }
];
```

### Never Do This
```javascript
// ❌ NEVER expose secret keys in frontend
const stripe = new Stripe('sk_live_xxxxx'); // WRONG!

// ❌ NEVER calculate prices on frontend
const total = items.reduce((sum, item) => sum + item.price, 0); // Verify server-side!

// ❌ NEVER trust client-side inventory
if (inventory > 0) { /* proceed */ } // Check server-side!
```

---

## 📊 8. Analytics Integration

```javascript
// Track key events for analytics
import { trackEvent } from '@/lib/analytics';

// Product view
trackEvent('product_view', {
  product_id: product.id,
  product_name: product.name,
  category: product.category,
  price: product.price
});

// Add to cart
trackEvent('add_to_cart', {
  product_id: product.id,
  variant_id: variant?.id,
  quantity: quantity,
  price: price
});

// Checkout started
trackEvent('checkout_started', {
  cart_value: cartTotal,
  item_count: cart.length,
  user_type: user ? 'registered' : 'guest'
});

// Purchase (handled by webhook)
```

---

## 🆘 9. Troubleshooting

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Invalid price_id" | Ensure core products have valid `stripe_price_id` |
| "Out of stock" | Check inventory in product_variants table |
| "Checkout fails" | Verify Edge Function is deployed and secrets are set |
| "No confirmation email" | Check email service configuration (Resend/SendGrid) |
| "Cart disappears" | Check localStorage is enabled |
| "CORS error" | Verify Cloudflare R2 CORS settings |

### Debug Mode
```javascript
// Enable debug logging
const DEBUG = process.env.NODE_ENV === 'development';

if (DEBUG) {
  console.log('Cart items:', cart);
  console.log('Checkout payload:', checkoutData);
  console.log('Response:', response);
}
```

---

## 🚀 10. Go-Live Checklist

### Before Launch
- [ ] Switch to Stripe live keys
- [ ] Test with real payment method
- [ ] Verify email delivery
- [ ] Check inventory sync
- [ ] Test on mobile devices
- [ ] Monitor Edge Function logs
- [ ] Set up error tracking (Sentry)
- [ ] Configure analytics (GA4/Mixpanel)

### After Launch
- [ ] Monitor Stripe Dashboard
- [ ] Check Supabase logs
- [ ] Review order creation
- [ ] Verify inventory updates
- [ ] Monitor conversion rates
- [ ] Check for cart abandonment

---

## 📞 Support Resources

### Documentation
- [Stripe Checkout Docs](https://stripe.com/docs/checkout)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Next.js Commerce](https://nextjs.org/commerce)

### Logs & Monitoring
```bash
# View Edge Function logs
supabase functions logs create-checkout-secure --tail

# Check webhook logs
supabase functions logs stripe-webhook-secure --tail

# Database queries
SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '1 hour';
SELECT * FROM webhook_logs WHERE status = 'failed';
```

### Contact
- **Technical Issues**: Check Supabase Dashboard logs
- **Payment Issues**: Stripe Dashboard → Payments
- **Order Issues**: Admin Panel → Orders

---

## 🎯 Summary

This checkout system provides:
1. **Hybrid product support** (Stripe core + Supabase catalog)
2. **Secure payment processing** via Edge Functions
3. **Real-time inventory management**
4. **Complete order tracking**
5. **Customer data capture**
6. **Email notifications**
7. **Analytics integration**

The website can now handle unlimited products while maintaining PCI compliance and capturing all critical business data in your admin system.