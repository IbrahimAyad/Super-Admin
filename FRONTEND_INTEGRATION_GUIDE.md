# Frontend Integration Guide - KCT Menswear

## Overview
This document outlines all backend changes and integration points for the frontend website to properly sync with the admin system.

---

## 1. Stripe Integration Changes

### API Configuration
- **API Version**: `2023-10-16` (DO NOT use 2025-07-30)
- **Publishable Key**: `pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW`
- **Mode**: LIVE (Production)

### Checkout Integration

#### Endpoint
```
POST https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/create-checkout-secure
```

#### Request Format
```javascript
const response = await fetch('https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/create-checkout-secure', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    items: [
      {
        // For Stripe Core Products (your 28 products)
        stripe_price_id: 'price_xxxxx',  // Use this for core products
        quantity: 1,
        customization: {
          size: 'M',
          color: 'Navy'
        }
      },
      {
        // For Supabase Catalog Products
        variant_id: 'uuid-here',  // Use this for products in Supabase
        quantity: 1,
        customization: {
          monogram: 'JD',
          sleeve_length: 'regular'
        }
      }
    ],
    success_url: 'https://yoursite.com/order-success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: 'https://yoursite.com/cart',
    customer_email: 'customer@email.com'  // Optional
  })
});

const data = await response.json();
// Redirect to: data.url
```

### Important Changes
1. **Two Product Types Now Supported**:
   - **Core Products**: Use `stripe_price_id` (your existing 28 Stripe products)
   - **Catalog Products**: Use `variant_id` (products in Supabase database)

2. **Customization Data**: Always pass customization options in the `customization` field

3. **Session Management**: Stock is reserved for 15 minutes during checkout

---

## 2. Order Management

### Order Creation Flow
When a customer completes checkout:

1. **Webhook Processing** (`kct-webhook` function handles):
   - `checkout.session.completed` event
   - Creates order in `orders` table
   - Updates inventory
   - Creates/updates customer record

2. **Order Structure**:
```javascript
{
  order_number: 'KCT-2025-XXXXX',
  stripe_checkout_session_id: 'cs_xxx',
  stripe_payment_intent_id: 'pi_xxx',
  customer_id: 'uuid',  // If registered
  guest_email: 'email',  // If guest
  status: 'confirmed',  // confirmed, processing, shipped, delivered, cancelled
  financial_status: 'paid',  // paid, partially_refunded, refunded
  refund_status: null,  // pending_refund, refunded, refund_failed
  total_amount: 10000,  // In cents
  items: [
    {
      name: 'Product Name',
      sku: 'SKU123',
      stripe_product_id: 'prod_xxx',  // For core products
      stripe_price_id: 'price_xxx',   // For core products
      variant_id: 'uuid',              // For catalog products
      quantity: 1,
      unit_price: 5000,  // In cents
      total_price: 5000,  // In cents
      customization: {
        size: 'M',
        color: 'Navy'
      }
    }
  ],
  shipping_address: {},
  billing_address: {}
}
```

---

## 3. Customer Management

### Customer Creation
- Automatically created on first order
- Linked to Stripe customer if email matches
- Stored in `customers` table

### Customer Fields
```javascript
{
  id: 'uuid',
  stripe_customer_id: 'cus_xxx',  // If Stripe customer
  auth_user_id: 'uuid',  // If registered user
  email: 'customer@email.com',
  first_name: 'John',
  last_name: 'Doe',
  phone: '+1234567890',
  total_spent: 10000,  // In cents
  order_count: 1,
  created_at: '2025-01-01T00:00:00Z'
}
```

---

## 4. Inventory Management

### For Catalog Products (in Supabase)
- Stock automatically decremented on order
- Stock automatically restored on cancellation/refund
- 15-minute reservation during checkout

### For Core Products (Stripe only)
- Inventory managed externally in Stripe
- No stock tracking in Supabase

---

## 5. Analytics Events

### Track these events:
```javascript
// Page view
await supabase.from('analytics_events').insert({
  event_type: 'page_view',
  page_url: window.location.href,
  user_id: userId,  // Optional
  session_id: sessionId,
  metadata: { referrer: document.referrer }
});

// Add to cart
await supabase.from('analytics_events').insert({
  event_type: 'add_to_cart',
  user_id: userId,
  session_id: sessionId,
  metadata: {
    product_id: productId,
    variant_id: variantId,
    quantity: 1,
    price: 5000  // In cents
  }
});

// Checkout started
await supabase.from('analytics_events').insert({
  event_type: 'checkout_started',
  user_id: userId,
  session_id: sessionId,
  metadata: {
    cart_value: 10000,  // In cents
    item_count: 2
  }
});

// Order completed (handled by webhook)
```

---

## 6. Refund Process

### Frontend should:
1. Display refund request button on order details
2. Submit refund request to admin for approval
3. Show refund status on order

### Refund Request API:
```javascript
await supabase.from('refund_requests').insert({
  order_id: orderId,
  reason: 'Customer reason here',
  refund_amount: 5000,  // In cents, partial refunds supported
  status: 'pending'  // Will be processed by admin
});
```

---

## 7. Environment Variables

Update your `.env`:
```env
VITE_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW
```

---

## 8. Testing Checklist

### Before Going Live:
- [ ] Test checkout with core products (stripe_price_id)
- [ ] Test checkout with catalog products (variant_id)
- [ ] Test mixed cart (both product types)
- [ ] Verify order creation in admin
- [ ] Test guest checkout
- [ ] Test registered user checkout
- [ ] Verify inventory updates
- [ ] Test refund request submission
- [ ] Verify analytics tracking
- [ ] Test order status page

---

## 9. Migration Notes

### Breaking Changes:
1. **Price Storage**: All prices now stored in CENTS (multiply by 100)
2. **Product Types**: Distinguish between core and catalog products
3. **API Version**: Must use Stripe API version 2023-10-16

### Backward Compatibility:
- Old orders will still display correctly
- Guest orders supported without changes

---

## Support

For questions or issues:
- Admin Dashboard: http://localhost:3004/admin
- Stripe Dashboard: https://dashboard.stripe.com
- Supabase Dashboard: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz

---

Last Updated: August 2025