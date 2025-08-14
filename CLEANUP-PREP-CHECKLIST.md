# Pre-Cleanup Preparation Checklist

## 🔴 CRITICAL: Do These BEFORE Cleanup

### 1. ⚡ BACKUP CURRENT STATE (5 minutes)
```sql
-- Run this in Supabase SQL Editor NOW
-- Creates backup tables with timestamp

-- Backup products
CREATE TABLE products_backup_2025_01_13 AS 
SELECT * FROM products;

-- Backup variants
CREATE TABLE product_variants_backup_2025_01_13 AS 
SELECT * FROM product_variants;

-- Backup images
CREATE TABLE product_images_backup_2025_01_13 AS 
SELECT * FROM product_images;

-- Verify backups
SELECT 
    'products_backup' as table_name,
    COUNT(*) as row_count
FROM products_backup_2025_01_13
UNION ALL
SELECT 
    'variants_backup',
    COUNT(*)
FROM product_variants_backup_2025_01_13
UNION ALL
SELECT 
    'images_backup',
    COUNT(*)
FROM product_images_backup_2025_01_13;
```

### 2. 📊 CAPTURE CURRENT METRICS (2 minutes)
```sql
-- Save current state metrics
CREATE TABLE cleanup_metrics AS
SELECT 
    NOW() as snapshot_time,
    'before_cleanup' as stage,
    
    -- Product counts
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT p.name) as unique_product_names,
    COUNT(DISTINCT pv.id) as total_variants,
    
    -- Duplicate analysis
    (SELECT COUNT(*) FROM (
        SELECT name FROM products 
        GROUP BY name HAVING COUNT(*) > 1
    ) dupes) as products_with_duplicates,
    
    -- Image analysis
    COUNT(CASE WHEN p.primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images,
    COUNT(CASE WHEN p.primary_image LIKE '%8ea0502%' THEN 1 END) as new_gallery_images,
    COUNT(CASE WHEN p.primary_image LIKE '%5cd73a21%' THEN 1 END) as old_r2_images,
    
    -- Stripe coverage
    COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL THEN 1 END) as variants_with_stripe,
    
    -- Categories
    COUNT(DISTINCT p.category) as total_categories,
    
    -- Price ranges
    MIN(pv.price) as min_price,
    MAX(pv.price) as max_price,
    AVG(pv.price) as avg_price

FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active';

-- View the metrics
SELECT * FROM cleanup_metrics;
```

### 3. 🏷️ IDENTIFY CORE PRODUCTS (Important!)
```sql
-- Mark products to NEVER delete
ALTER TABLE products
ADD COLUMN IF NOT EXISTS is_core_product BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS cleanup_action VARCHAR(20);

-- Flag core products (before July 28, 2024)
UPDATE products
SET is_core_product = true,
    cleanup_action = 'keep'
WHERE created_at < '2024-07-28'
   OR id IN (
    -- Add any specific product IDs you want to preserve
    'a9e4bbba-7128-4f45-9258-9b0d9465123b', -- Example: best selling velvet blazer
    '754192d7-e19e-475b-9b64-0463d31c4cad'  -- Example: classic tuxedo
);

-- Verify core products
SELECT COUNT(*) as core_products_protected
FROM products
WHERE is_core_product = true;
```

### 4. 📝 ADD TRACKING COLUMNS
```sql
-- Add columns for cleanup tracking
ALTER TABLE products
ADD COLUMN IF NOT EXISTS original_id UUID,
ADD COLUMN IF NOT EXISTS merged_from_ids UUID[],
ADD COLUMN IF NOT EXISTS cleanup_notes TEXT,
ADD COLUMN IF NOT EXISTS last_modified_by VARCHAR(100);

-- Add columns for new features
ALTER TABLE products
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS meta_title VARCHAR(70),
ADD COLUMN IF NOT EXISTS meta_description VARCHAR(160),
ADD COLUMN IF NOT EXISTS search_keywords TEXT,
ADD COLUMN IF NOT EXISTS related_products UUID[],
ADD COLUMN IF NOT EXISTS key_features TEXT[],
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_best_seller BOOLEAN DEFAULT false;
```

### 5. 🔍 CREATE DUPLICATE DETECTION VIEW
```sql
-- Create view to easily see duplicates
CREATE OR REPLACE VIEW duplicate_products AS
WITH product_groups AS (
    SELECT 
        LOWER(TRIM(name)) as normalized_name,
        COUNT(*) as duplicate_count,
        MIN(created_at) as first_created,
        MAX(created_at) as last_created,
        ARRAY_AGG(id ORDER BY created_at) as product_ids,
        ARRAY_AGG(primary_image) as all_images,
        ARRAY_AGG(sku) as all_skus
    FROM products
    WHERE status = 'active'
    GROUP BY LOWER(TRIM(name))
    HAVING COUNT(*) > 1
)
SELECT * FROM product_groups
ORDER BY duplicate_count DESC;

-- Check the duplicates
SELECT * FROM duplicate_products LIMIT 10;
```

### 6. 🖼️ PREPARE IMAGE CONSOLIDATION
```sql
-- Analyze image sources
CREATE OR REPLACE VIEW image_analysis AS
SELECT 
    CASE 
        WHEN primary_image LIKE '%8ea0502%' THEN 'New Gallery R2'
        WHEN primary_image LIKE '%5cd73a21%' THEN 'Old R2'
        WHEN primary_image LIKE '%5cd8c531%' THEN 'Oldest R2'
        WHEN primary_image LIKE '%placehold%' THEN 'Placeholder'
        WHEN primary_image IS NULL THEN 'No Image'
        ELSE 'Other'
    END as image_source,
    COUNT(*) as product_count,
    ARRAY_AGG(id) as product_ids
FROM products
WHERE status = 'active'
GROUP BY image_source;

-- View image distribution
SELECT * FROM image_analysis;
```

### 7. 💰 PROTECT STRIPE INTEGRATION
```sql
-- Create safety view for Stripe prices
CREATE OR REPLACE VIEW stripe_price_safety AS
SELECT 
    pv.stripe_price_id,
    COUNT(DISTINCT pv.id) as variants_using,
    ARRAY_AGG(DISTINCT p.name) as product_names
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE pv.stripe_price_id IS NOT NULL
GROUP BY pv.stripe_price_id
ORDER BY COUNT(DISTINCT pv.id) DESC;

-- Verify all Stripe prices
SELECT * FROM stripe_price_safety;
```

## 📋 CLEANUP READINESS CHECKLIST

Run these checks before starting:

```sql
-- Final pre-cleanup checklist
SELECT 
    'Backups Created' as check_item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products_backup_2025_01_13')
        THEN '✅ Ready' 
        ELSE '❌ Missing' 
    END as status
UNION ALL
SELECT 
    'Core Products Marked',
    CASE 
        WHEN EXISTS (SELECT 1 FROM products WHERE is_core_product = true)
        THEN '✅ Ready (' || COUNT(*) || ' protected)' 
        ELSE '❌ Not marked' 
    END
FROM products WHERE is_core_product = true
UNION ALL
SELECT 
    'Tracking Columns Added',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'tags')
        THEN '✅ Ready' 
        ELSE '❌ Missing' 
    END
UNION ALL
SELECT 
    'Duplicate View Created',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'duplicate_products')
        THEN '✅ Ready' 
        ELSE '❌ Missing' 
    END;
```

## 🚀 QUICK ROLLBACK PLAN

If anything goes wrong:

```sql
-- Emergency rollback
BEGIN;

-- Restore products
DROP TABLE products CASCADE;
ALTER TABLE products_backup_2025_01_13 RENAME TO products;

-- Restore variants
DROP TABLE product_variants CASCADE;
ALTER TABLE product_variants_backup_2025_01_13 RENAME TO product_variants;

-- Restore images
DROP TABLE product_images CASCADE;
ALTER TABLE product_images_backup_2025_01_13 RENAME TO product_images;

COMMIT;
```

## ✅ READY FOR CLEANUP!

Once all checks show "✅ Ready", you can safely proceed with the cleanup while ChatGPT works on the CSV!