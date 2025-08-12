# Website Integration Guide - Secure Checkout

## Overview
This guide explains how to integrate your website with the new secure checkout system using Supabase Edge Functions.

## Key Changes

### 1. Environment Variables
Update your website's `.env` file:

```env
# Stripe - Use ONLY the publishable key (never put secret key in frontend)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

### 2. Update Checkout Component

Replace any direct Stripe checkout with the secure Edge Function call:

**OLD WAY (Direct Stripe):**
```javascript
// DON'T DO THIS - Exposes secret key
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const session = await stripe.checkout.sessions.create({...});
```

**NEW WAY (Secure Edge Function):**
```javascript
import { supabase } from '@/lib/supabase-client';

const createCheckoutSession = async (items, userId) => {
  // Call the secure Edge Function
  const { data, error } = await supabase.functions.invoke('create-checkout-secure', {
    body: {
      items: items,
      userId: userId,
      successUrl: `${window.location.origin}/success`,
      cancelUrl: `${window.location.origin}/cart`,
    }
  });

  if (error) throw error;
  
  // Redirect to Stripe Checkout
  window.location.href = data.url;
};
```

### 3. Update Cart/Checkout Button

```jsx
import { useState } from 'react';
import { supabase } from '@/lib/supabase-client';
import { useAuth } from '@/contexts/AuthContext';

export function CheckoutButton({ cartItems }) {
  const [loading, setLoading] = useState(false);
  const { user } = useAuth();

  const handleCheckout = async () => {
    setLoading(true);
    
    try {
      // Prepare cart items for checkout
      const items = cartItems.map(item => ({
        price_id: item.stripe_price_id,
        quantity: item.quantity,
        product_id: item.id,
        name: item.name,
        price: item.price
      }));

      // Call secure checkout function
      const { data, error } = await supabase.functions.invoke('create-checkout-secure', {
        body: {
          items,
          userId: user?.id,
          customerEmail: user?.email,
          successUrl: `${window.location.origin}/order-success`,
          cancelUrl: `${window.location.origin}/cart`,
          metadata: {
            cart_id: localStorage.getItem('cart_id'),
            user_id: user?.id
          }
        }
      });

      if (error) throw error;

      // Redirect to Stripe Checkout
      if (data?.url) {
        window.location.href = data.url;
      }
    } catch (error) {
      console.error('Checkout error:', error);
      alert('Failed to create checkout session');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button 
      onClick={handleCheckout}
      disabled={loading || cartItems.length === 0}
      className="checkout-button"
    >
      {loading ? 'Processing...' : 'Secure Checkout'}
    </button>
  );
}
```

### 4. Handle Success Page

Create a success page to handle post-payment:

```jsx
// pages/order-success.jsx or app/order-success/page.tsx
import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase-client';

export default function OrderSuccess() {
  const searchParams = useSearchParams();
  const [order, setOrder] = useState(null);
  
  useEffect(() => {
    const sessionId = searchParams.get('session_id');
    if (sessionId) {
      fetchOrder(sessionId);
    }
  }, []);

  const fetchOrder = async (sessionId) => {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('stripe_session_id', sessionId)
      .single();
    
    if (data) {
      setOrder(data);
      // Clear cart
      localStorage.removeItem('cart');
      localStorage.removeItem('cart_id');
    }
  };

  return (
    <div className="success-page">
      <h1>Order Confirmed!</h1>
      {order && (
        <div>
          <p>Order ID: {order.id}</p>
          <p>Total: ${order.total_amount}</p>
          <p>You will receive an email confirmation shortly.</p>
        </div>
      )}
    </div>
  );
}
```

### 5. User Authentication Integration

Ensure users are logged in or create guest sessions:

```javascript
// Check if user is authenticated
const { data: { user } } = await supabase.auth.getUser();

if (!user) {
  // Option 1: Require login
  router.push('/login?redirect=/checkout');
  
  // Option 2: Create guest checkout
  const guestEmail = prompt('Enter your email for order updates:');
  // Pass guestEmail to checkout
}
```

### 6. Webhook Handling

The webhook is automatically handled by the Edge Function. It will:
- Confirm payment
- Create order in database
- Update inventory
- Send confirmation email
- Update user profile (if logged in)

## Security Best Practices

### ✅ DO:
- Use Edge Functions for all payment processing
- Validate cart items on the server
- Use Supabase Auth for user management
- Store only the publishable key in frontend
- Implement rate limiting on checkout attempts

### ❌ DON'T:
- Put secret keys in frontend code
- Trust client-side price calculations
- Skip cart validation
- Create Stripe customers from frontend
- Process refunds from frontend

## Testing

### Test Card Numbers:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- 3D Secure: `4000 0025 0000 3155`

### Test Flow:
1. Add items to cart
2. Click checkout
3. Use test card
4. Verify order created in database
5. Check email (if configured)
6. Verify inventory updated

## Migration Checklist

- [ ] Update environment variables
- [ ] Replace direct Stripe calls with Edge Functions
- [ ] Update checkout button component
- [ ] Create success/cancel pages
- [ ] Test with Stripe test mode
- [ ] Update user authentication flow
- [ ] Test email notifications
- [ ] Verify inventory updates
- [ ] Switch to live keys for production

## Common Issues

### "Invalid price_id"
- Ensure products have `stripe_price_id` field
- Run product sync: `supabase functions invoke sync-stripe-products`

### "Webhook signature verification failed"
- Check webhook secret is correctly set
- Ensure webhook URL matches Edge Function

### "User not found"
- Implement guest checkout or require login
- Pass user data to Edge Function

## Support Functions

### Sync Products with Stripe:
```javascript
const syncProducts = async () => {
  const { data, error } = await supabase.functions.invoke('sync-stripe-products');
  console.log('Sync result:', data);
};
```

### Check Order Status:
```javascript
const checkOrder = async (orderId) => {
  const { data, error } = await supabase.functions.invoke('get-order', {
    body: { orderId }
  });
  return data;
};
```

## Next Steps

1. Test the complete flow with test cards
2. Configure email service (Resend/SendGrid)
3. Set up order management in admin panel
4. Configure shipping options
5. Implement order tracking for customers

## Need Help?

- Check Edge Function logs: `supabase functions logs create-checkout-secure`
- View webhook events in Stripe Dashboard
- Check browser console for errors
- Review Supabase logs for database issues