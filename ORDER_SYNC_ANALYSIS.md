# KCT Order Sync Analysis Report

**Date:** 2025-08-08  
**Scope:** Order synchronization between KCT website checkout and admin system  
**Files Analyzed:** 
- `/supabase/functions/kct-webhook/index.ts`
- `/supabase/functions/create-checkout/index.ts` 
- `/src/pages/AdminOrderManagement.tsx`
- `/src/lib/services/business.ts`
- Database schema migrations

## Executive Summary

The KCT order sync system has **several critical field mapping issues** that could cause data inconsistencies between website checkout and admin order management. While the core webhook functionality works, there are mismatches in field names and data structure expectations that need to be addressed.

## Key Findings

### 1. ✅ **Working Components**

**Webhook Function (`kct-webhook/index.ts`):**
- ✅ Successfully processes Stripe checkout.session.completed events
- ✅ Creates orders and order_items in database
- ✅ Handles both guest and customer orders
- ✅ Processes bundle orders with discounts
- ✅ Maps shipping and billing addresses correctly
- ✅ Generates proper order numbers (`KCT-YYYY-XXXXXX`)
- ✅ Creates proper SKUs for products

**Checkout Creation (`create-checkout/index.ts`):**
- ✅ Validates inventory before checkout
- ✅ Reserves stock during checkout process
- ✅ Handles both catalog and core products
- ✅ Passes order metadata to webhook correctly

### 2. ⚠️ **Critical Field Mapping Issues**

**Webhook Creates → Admin Expects:**

| Webhook Field | Admin Expected | Status | Issue |
|---------------|----------------|---------|-------|
| `stripe_session_id` | `stripe_checkout_session_id` | ❌ | Field name mismatch |
| `total_amount` | `total` | ⚠️ | Admin transforms this |
| `tax_amount` | `tax` | ⚠️ | Admin transforms this |
| `shipping_amount` | `shipping` | ⚠️ | Admin transforms this |
| `discount_amount` | `discount` | ⚠️ | Admin transforms this |
| `guest_email` | `customer_email` | ⚠️ | Admin transforms this |
| Individual address fields | `shipping_address` object | ❌ | Structure mismatch |
| Individual address fields | `billing_address` object | ❌ | Structure mismatch |

### 3. ❌ **Major Structural Issues**

**Address Storage Mismatch:**
```javascript
// Webhook stores as individual fields:
shipping_first_name, shipping_last_name, shipping_address_line_1, 
shipping_city, shipping_state, shipping_postal_code, shipping_country

// Admin expects as objects:
shipping_address: {
  line1, line2, city, state, postal_code, country
}
```

**Customer Information:**
```javascript
// Webhook logic:
customer_name: order.guest_email || 'Guest Customer'  // Uses email as name!
customer_email: order.guest_email || ''

// Should be:
customer_name: firstName + ' ' + lastName
customer_email: customerEmail
```

### 4. 🏗️ **Database Schema Analysis**

**Orders Table Structure (Good):**
- ✅ Has all required fields for webhook
- ✅ Supports individual address fields  
- ✅ Has proper relationships
- ✅ Includes bundle and payment tracking

**Order Items Structure (Good):**
- ✅ Has all product information fields
- ✅ Supports attributes/metadata
- ✅ Proper pricing fields

### 5. 🔄 **Data Flow Issues**

**Current Flow:**
1. Website checkout → creates Stripe session with metadata
2. Stripe webhook → processes session and creates order with individual fields
3. Admin UI → transforms data for display (working around structure issues)

**Issues:**
- Admin has to transform every order for display
- Address data stored as flat fields but needed as objects
- No validation that webhook data matches admin expectations

## Detailed Technical Analysis

### Webhook Order Creation Process

The webhook correctly processes Stripe events but has some inefficiencies:

```typescript
// Current webhook order creation (lines 175-212):
const { data: order, error: orderError } = await supabase
  .from("orders")
  .insert({
    order_number: orderNumber,
    customer_id: customer?.id || null,
    guest_email: customer ? null : customerEmail, // ❌ Should always store email
    status: "confirmed",
    // ... individual address fields instead of objects
    shipping_first_name: session.shipping_details?.name?.split(" ")[0] || "",
    shipping_last_name: session.shipping_details?.name?.split(" ").slice(1).join(" ") || "",
    // ... more individual fields
  })
```

### Admin Data Transformation

The admin compensates with transformations:

```typescript
// AdminOrderManagement.tsx lines 87-96:
const transformedOrders = (data || []).map(order => ({
  ...order,
  tax: order.tax_amount || 0,           // ⚠️ Required transformation
  shipping: order.shipping_amount || 0,  // ⚠️ Required transformation  
  discount: order.discount_amount || 0,  // ⚠️ Required transformation
  total: order.total_amount || 0,        // ⚠️ Required transformation
  customer_name: order.guest_email || 'Guest Customer', // ❌ Wrong!
  customer_email: order.guest_email || '' // ❌ Not always correct
}));
```

## Test Results Summary

Using the test script (`test-order-sync.js`):

| Test Category | Status | Issues Found |
|---------------|--------|--------------|
| Database Schema | ✅ Pass | None |
| Webhook Order Creation | ✅ Pass | None |
| Field Mappings | ❌ Fail | 5 field mismatches |
| Admin Display | ⚠️ Partial | Requires transformations |
| Bundle Orders | ✅ Pass | None |
| Guest vs Customer | ⚠️ Partial | Customer name mapping issue |
| Order Items | ✅ Pass | None |

## Recommendations

### 1. 🔧 **Immediate Fixes (High Priority)**

**Fix Address Storage:**
```typescript
// In webhook, store addresses as JSON objects:
shipping_address: {
  name: session.shipping_details?.name,
  line1: session.shipping_details?.address?.line1,
  line2: session.shipping_details?.address?.line2,
  city: session.shipping_details?.address?.city,
  state: session.shipping_details?.address?.state,
  postal_code: session.shipping_details?.address?.postal_code,
  country: session.shipping_details?.address?.country
},
billing_address: {
  name: customerName,
  line1: session.customer_details?.address?.line1,
  // ... rest of address
}
```

**Fix Customer Name Handling:**
```typescript
// Store proper customer name from Stripe
const customerName = session.customer_details?.name || "";
const [firstName, ...lastNameParts] = customerName.split(" ");
const lastName = lastNameParts.join(" ");

// In order creation:
customer_email: customerEmail, // Always store email
customer_first_name: firstName,
customer_last_name: lastName,
```

### 2. 📊 **Database Schema Updates**

Add computed columns or update existing fields:
```sql
-- Add JSON address columns if needed
ALTER TABLE orders 
ADD COLUMN shipping_address_json JSONB,
ADD COLUMN billing_address_json JSONB;

-- Or standardize on existing individual fields and update admin
```

### 3. 🖥️ **Admin UI Improvements**

Remove transformations by updating field names:
```typescript
// Instead of transforming, use proper field names:
const { data } = await supabase
  .from('orders')
  .select(`
    *,
    order_items (*),
    customers (first_name, last_name, email)
  `)
  .order('created_at', { ascending: false });

// Use customer relationship instead of guest_email for customer name
```

### 4. 🧪 **Testing & Monitoring**

- **Automated Testing:** Run `test-order-sync.js` in CI/CD
- **Webhook Monitoring:** Add logging to track order creation success rates
- **Admin Alerts:** Notify when orders can't be displayed properly
- **Data Validation:** Add constraints to ensure data consistency

### 5. 🔄 **Process Improvements**

**Webhook Validation:**
```typescript
// Add validation before order creation
function validateOrderData(orderData) {
  const required = ['customer_email', 'total_amount', 'status'];
  const missing = required.filter(field => !orderData[field]);
  if (missing.length) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
}
```

**Error Handling:**
```typescript
// Add retry logic and better error reporting
try {
  await createOrder(orderData);
} catch (error) {
  console.error('Order creation failed:', error);
  // Send alert to admin
  await supabase.functions.invoke('send-admin-alert', {
    body: { error: error.message, session_id: session.id }
  });
  throw error;
}
```

## Migration Strategy

### Phase 1: Fix Critical Issues (Week 1)
1. Update webhook to store addresses as JSON objects
2. Fix customer name handling
3. Update admin to use proper field references
4. Test with staging Stripe events

### Phase 2: Database Optimization (Week 2)
1. Add database constraints for data validation
2. Create indexes for common admin queries
3. Add computed columns if needed
4. Run data migration for existing orders

### Phase 3: Enhanced Features (Week 3-4)
1. Add order event tracking
2. Implement webhook retry logic
3. Add admin order creation alerts
4. Create comprehensive monitoring dashboard

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|-----------|
| Orders not displaying in admin | High | Medium | Current transformations provide workaround |
| Address data inconsistency | Medium | High | Update webhook immediately |
| Customer name display issues | Low | High | Fix customer name logic |
| Webhook failures | High | Low | Add retry logic and monitoring |

## Conclusion

The KCT order sync system is functional but has several structural issues that should be addressed. The webhook successfully creates orders, but field mapping inconsistencies require the admin system to perform unnecessary transformations. 

**Priority actions:**
1. Fix address storage structure in webhook
2. Correct customer name handling
3. Update admin UI to use standardized field names
4. Implement the provided test script for ongoing validation

The test script (`test-order-sync.js`) provides automated verification of the sync process and should be integrated into the development workflow to prevent regression of these issues.