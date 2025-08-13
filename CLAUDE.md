# CLAUDE.md - Critical Project Knowledge

## 🔴 CRITICAL: Image System Architecture

### How Images Work in This System:
1. **Images are stored in a SEPARATE `product_images` table**
2. **The `products` table has a `primary_image` TEXT field that stores the URL directly**
3. **Images are linked via `product_id` foreign key in `product_images` table**

### Database Structure:

#### Products Table Columns:
- `id` (uuid) - Primary key
- `name` (text)
- `description` (text)
- `category` (text)
- `sku` (text)
- `handle` (text) - URL-safe slug
- `base_price` (INTEGER) - **Price in CENTS (e.g., $65.00 = 6500)**
- `primary_image` (text) - Stores the main image URL directly
- `additional_info` (jsonb) - Used for metadata (NOT `metadata` column)
- NO `image_url` column
- NO `metadata` column

#### Product_Images Table:
- `id` (uuid) - Primary key
- `product_id` (uuid) - Foreign key to products
- `image_url` (text) - The actual image URL
- `image_type` ('primary' | 'gallery' | 'thumbnail' | 'detail')
- `position` (integer) - Sort order
- `alt_text` (text)
- NO `is_primary` column
- NO `display_order` column (use `position` instead)

### How to Import Products with Images:

```sql
-- 1. Insert product with primary_image URL
INSERT INTO products (
    id, sku, handle, name, description, 
    base_price,  -- INTEGER in cents
    category, status, 
    primary_image,  -- Store URL here
    additional_info  -- Use this for metadata
) VALUES (
    gen_random_uuid(),
    'SKU-001',
    'product-handle',
    'Product Name',
    'Description',
    6500,  -- $65.00 in cents
    'Category',
    'active',
    'https://example.com/image.jpg',  -- URL goes here
    jsonb_build_object('source', 'csv_import')
);

-- 2. Optionally add to product_images table for gallery
INSERT INTO product_images (
    product_id,
    image_url,
    image_type,
    position,
    alt_text
) VALUES (
    'product-uuid',
    'https://example.com/image.jpg',
    'primary',
    1,
    'Alt text'
);
```

## 🔴 CRITICAL: Supabase Configuration

### Current Project:
- **URL**: `https://gvcswimqaxvylgxbklbz.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24`

## 🔴 CRITICAL: System Architecture

### Core Products vs Catalog Products:
1. **Core Products (28 items)**: 
   - Exist ONLY in Stripe
   - NOT in Supabase products table
   - Use `stripe_price_id` for checkout
   - Orders/customers ARE captured via webhooks

2. **Catalog Products (183+ items)**:
   - Stored in Supabase products table
   - Have product_variants for sizes
   - Use Supabase IDs for checkout

### Edge Functions:
- `create-checkout-secure` - Handles checkout
- `stripe-webhook-secure` - Processes Stripe webhooks
- Both functions handle hybrid product system

## 🔴 CRITICAL: Common Errors to Avoid

1. **DON'T use `metadata` column** - Use `additional_info` instead
2. **DON'T use `image_url` in products** - Use `primary_image` 
3. **DON'T use decimal for prices** - Use INTEGER (cents)
4. **DON'T forget `handle` column** - Required for URL slugs
5. **DON'T use `is_primary` in product_images** - Use `image_type = 'primary'`
6. **DON'T use `display_order`** - Use `position` instead

## 🔴 CRITICAL: Import Process

To import the 233 new products from CSV:
1. Check table structure first
2. Use `primary_image` for main image URL
3. Store prices as INTEGER in cents
4. Create URL-safe handles
5. Use `additional_info` for metadata
6. Create size variants based on category

## 📝 Testing Commands

Always run these first:
```sql
-- Check products table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products';

-- Check product_images structure  
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product_images';
```

## 🚨 Website Integration

### For Website Team:
1. Use Supabase Edge Functions (NOT Next.js API routes)
2. Keep 28 Core products in Stripe only
3. Use Resend for emails (API Key: `re_2P3zWsMq_8gLFuPBBg62yT7wAt9NBpoLP`)
4. Auto-create customer records for guests
5. Show bundles as single line items in Stripe

---
**Last Updated**: 2025-08-12
**Critical**: Always check table structure before imports!