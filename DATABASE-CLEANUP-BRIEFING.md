# Database Cleanup Briefing for ChatGPT

## 🔴 CRITICAL DATABASE STRUCTURE

### 1. Products Table
```sql
products:
  - id (uuid) - Primary key
  - name (text)
  - description (text) 
  - category (text)
  - sku (text)
  - handle (text) - URL slug
  - base_price (INTEGER) - Price in CENTS (e.g., $65.00 = 6500)
  - primary_image (text) - Direct URL string, NOT a foreign key
  - additional_info (jsonb) - For metadata
  - status (text) - 'active' or 'inactive'
  - created_at, updated_at
  
  ❌ NO COLUMNS: supplier, brand, image_url, metadata, slug, total_inventory, in_stock
```

### 2. Product_Variants Table
```sql
product_variants:
  - id (uuid)
  - product_id (uuid) - Foreign key to products
  - title (text) - Size/variant name
  - price (INTEGER) - Price in CENTS
  - stripe_price_id (text) - Stripe price ID for checkout
  - stripe_active (boolean)
  
  ❌ NO COLUMNS: inventory_count, sku, barcode
```

### 3. Product_Images Table (Gallery System)
```sql
product_images:
  - id (uuid)
  - product_id (uuid) - Foreign key
  - image_url (text)
  - image_type ('primary'|'gallery'|'thumbnail'|'detail')
  - position (integer) - Sort order
  - alt_text (text)
  
  ❌ NO COLUMNS: is_primary, display_order
```

## 🎯 CURRENT ISSUES TO FIX

### 1. Duplicate Products
- **209+ duplicate velvet blazers** (same product imported multiple times)
- Many products with identical names but different IDs
- Keep OLDEST products (created before August 2024)
- Delete newer duplicates

### 2. Image Problems
- **THREE different R2 buckets** being used:
  - OLD: `pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2` (91 products)
  - NEW: `pub-8ea0502158a94b8ca8a7abb9e18a57e8` (137 products)
  - OLDEST: `pub-5cd8c531c0034986bf6282a223bd0564` (from CSV imports)
- 183 products using placeholder images
- Images stored in TWO places:
  - `products.primary_image` (main display)
  - `product_images` table (gallery)

### 3. Stripe Integration
- All 2,991 variants NOW have stripe_price_ids ✅
- But prices are MAPPED (e.g., $289.99 products use $299.99 Stripe price)
- Some invalid/old price IDs might still exist

### 4. Category Inconsistencies
```
CORRECT Categories:
- Luxury Velvet Blazers (33 products)
- Sparkle & Sequin Blazers (26 products)
- Men's Suits (36 products)
- Vest & Tie Sets (25 products)
- Accessories (23 products)
- Prom & Formal Blazers (14 products)
- Men's Dress Shirts (10 products)
- Casual Summer Blazers (7 products)
- Tuxedos (20 products)
- Blazers (8 products)
- Kids Formal Wear (5 products)
```

## 📋 CLEANUP PRIORITIES

### Phase 1: Remove Duplicates
```sql
-- Keep only oldest version of each product
WITH duplicates AS (
  SELECT name, MIN(created_at) as keep_date
  FROM products
  GROUP BY name
  HAVING COUNT(*) > 1
)
DELETE FROM products
WHERE name IN (SELECT name FROM duplicates)
  AND created_at > (SELECT keep_date FROM duplicates WHERE duplicates.name = products.name);
```

### Phase 2: Standardize Images
1. Pick ONE R2 bucket (recommend: `pub-8ea0502158a94b8ca8a7abb9e18a57e8`)
2. Update all products to use consistent image URLs
3. Remove placeholder images where real images exist
4. Ensure `product_images` table is properly populated

### Phase 3: Fix Data Integrity
- Remove orphaned product_variants (no parent product)
- Remove orphaned product_images
- Ensure every product has at least one variant
- Verify all stripe_price_ids are valid

### Phase 4: Standardize Categories
- Fix inconsistent naming (e.g., "Blazers" vs "Blazer")
- Merge similar categories if needed
- Ensure consistent capitalization

## ⚠️ WARNINGS

1. **NEVER delete products created before July 28, 2024** (core products)
2. **Price fields are in CENTS** (multiply by 100 when inserting)
3. **primary_image is a TEXT field**, not a foreign key
4. **Some columns don't exist** (see ❌ marks above)
5. **Preserve all Stripe integrations** (took weeks to fix)

## 🎯 DESIRED END STATE

After cleanup:
- **~150-200 unique products** (not 274 with duplicates)
- **All products with real images** (no placeholders)
- **Consistent R2 bucket usage**
- **Proper gallery entries** in product_images
- **100% Stripe integration maintained**
- **Clean category structure**
- **No orphaned records**

## 💡 SUGGESTED APPROACH

1. **Backup first**: `pg_dump` or create backup tables
2. **Identify duplicates**: Group by name, keep oldest
3. **Consolidate images**: Pick best image for each product
4. **Clean relationships**: Fix foreign key issues
5. **Verify Stripe**: Ensure checkout still works
6. **Test thoroughly**: Check admin panel and website

## 🔍 Validation Queries

```sql
-- Check for duplicates
SELECT name, COUNT(*) as count
FROM products
GROUP BY name
HAVING COUNT(*) > 1;

-- Check image distribution
SELECT 
  CASE 
    WHEN primary_image LIKE '%8ea0502%' THEN 'New R2'
    WHEN primary_image LIKE '%5cd73a21%' THEN 'Old R2'
    WHEN primary_image LIKE '%5cd8c531%' THEN 'Oldest R2'
    WHEN primary_image LIKE '%placehold%' THEN 'Placeholder'
    ELSE 'Other'
  END as bucket,
  COUNT(*)
FROM products
GROUP BY bucket;

-- Verify Stripe coverage
SELECT 
  COUNT(*) as total,
  COUNT(stripe_price_id) as with_stripe,
  ROUND(COUNT(stripe_price_id) * 100.0 / COUNT(*), 1) as percent
FROM product_variants;
```

## 📝 IMPORTANT CONTEXT

This is a live e-commerce system for KCT Menswear. The database has been through multiple imports and fixes. The goal is to clean it up to a professional state while maintaining all functionality. The admin panel and website both depend on this data structure, so maintain backward compatibility.

**Tell ChatGPT**: "Clean this database to production quality while preserving all Stripe integrations and core products from before July 28, 2024."