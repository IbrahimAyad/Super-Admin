# Admin Panel Function Requirements

## Critical Functions Needed (Based on Code Analysis)

### 1. **Dashboard Functions** (Most Important)
- `get_dashboard_stats()` - Called by EnhancedDashboardWidgets.tsx
- `get_recent_orders(limit_count)` - Called by useDashboardData.ts
- `get_low_stock_products(threshold)` - Called by useDashboardData.ts

### 2. **Cart Functions**
- `transfer_guest_cart(customer_id, session_id)` - Called by business.ts
- `get_cart_items(customer_id, session_id)` - Called by business.ts
- `add_to_cart(customer_id, session_id, product_id, variant_id, quantity)`
- `update_cart_item(item_id, quantity)`
- `remove_cart_item(item_id)`
- `clear_cart(customer_id, session_id)`

### 3. **Product/Inventory Functions**
- `get_admin_products_paginated(page_size, page_number, search_term, filter_category, filter_status)` - Called by useOptimizedProducts.ts
- `get_available_inventory(variant_uuid)` - Called by multiple components
- `get_inventory_status()` - Called by LowStockAlerts.tsx
- `get_inventory_summary()` - Called by inventoryService.ts

### 4. **Analytics Functions** (Optional but Referenced)
- `get_revenue_metrics(start_date, end_date, interval)`
- `get_hourly_revenue_trend()`
- `get_order_analytics(days_back)`
- `get_top_products(limit, days_back)`
- `get_customer_ltv_analytics()`
- `get_realtime_customer_activity(limit)`
- `get_traffic_source_performance(days_back)`
- `get_realtime_website_metrics()`

### 5. **Security/Audit Functions** (Optional)
- `log_admin_security_event(event_type, details, admin_id)`
- `log_login_attempt(email, success, ip_address)`
- `check_failed_login_attempts(email)`

### 6. **Settings Functions**
- `get_public_settings_cached()`
- `update_setting_with_audit(key, value, updated_by)`
- `validate_setting_value(key, value)`

### 7. **Utility Functions**
- `get_table_columns(table_name)` - Used for diagnostics
- `check_table_indexes(table_name)` - Used for diagnostics

## Functions Currently Causing Errors

Based on the error messages:
1. **`get_recent_orders`** - 400 error (function exists but has wrong signature or missing columns)
2. **`transfer_guest_cart`** - 404 error (function might not exist)
3. **Reviews endpoint** - 400 error (reviews table missing)

## Recommended Approach

### Phase 1: Fix Critical Functions (Required for Admin Panel)
1. Create `get_dashboard_stats()`
2. Fix `get_recent_orders(limit_count)`
3. Create `get_low_stock_products(threshold)`
4. Create `transfer_guest_cart(customer_id, session_id)`
5. Create reviews table

### Phase 2: Add Product Management Functions
1. Create `get_admin_products_paginated()` for pagination
2. Create inventory functions

### Phase 3: Add Analytics (Optional)
- Only if analytics dashboard is needed

## Database Tables Required

Based on function dependencies:
- `orders` (with customer_id, email, order_number, total_amount, status, payment_status)
- `customers` 
- `reviews`
- `cart_items`
- `products` (already exists)
- `product_variants` (already exists with 399 records)

## Key Findings

1. The app expects many RPC functions that don't exist
2. Some functions exist with wrong signatures
3. The admin panel is trying to call analytics functions that were never created
4. Most critical are the dashboard stats and recent orders functions