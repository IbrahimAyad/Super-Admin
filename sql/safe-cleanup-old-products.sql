-- Safe Cleanup of Old Products
-- The 28 Core Stripe products are NOT in Supabase - they're handled directly by Stripe
-- We can safely clean up old products that are duplicates or unused

-- Step 1: Identify products to keep vs remove
WITH product_analysis AS (
    SELECT 
        p.id,
        p.name,
        p.sku,
        p.category,
        p.base_price,
        p.stripe_product_id,
        p.created_at,
        pe.id as enhanced_id,
        COUNT(DISTINCT pv.id) as variant_count,
        COUNT(DISTINCT oi.id) as order_count,
        CASE 
            WHEN pe.id IS NOT NULL THEN 'KEEP - In Enhanced'
            WHEN COUNT(DISTINCT oi.id) > 0 THEN 'KEEP - Has Orders'
            WHEN p.stripe_product_id IS NOT NULL THEN 'CHECK - Has Stripe ID (likely old attempt)'
            WHEN p.sku LIKE 'F25-%' THEN 'KEEP - Fall 2025'
            WHEN p.sku LIKE 'ACC-%' THEN 'KEEP - Accessories'
            WHEN p.sku LIKE 'VB-%' THEN 'KEEP - Velvet Blazer'
            WHEN p.sku LIKE 'PB-%' THEN 'KEEP - Paisley Blazer'
            WHEN p.sku LIKE 'SPB%' THEN 'KEEP - Sparkle Blazer'
            WHEN p.sku LIKE 'SB-%' AND p.category = 'Blazers' THEN 'KEEP - Sequin Blazer'
            WHEN p.sku LIKE 'BLZ-%' THEN 'REMOVE - Old Blazer Format'
            WHEN p.sku LIKE 'SB-%' AND p.category != 'Blazers' THEN 'REMOVE - Old Suspender Format'
            WHEN p.sku LIKE 'SVB-%' THEN 'REMOVE - Old Vest Format'
            ELSE 'REVIEW - Unknown'
        END as action
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    LEFT JOIN product_variants pv ON p.id = pv.product_id
    LEFT JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.id, p.name, p.sku, p.category, p.base_price, p.stripe_product_id, p.created_at, pe.id
)
SELECT 
    action,
    COUNT(*) as product_count,
    COUNT(CASE WHEN variant_count > 0 THEN 1 END) as with_variants,
    COUNT(CASE WHEN order_count > 0 THEN 1 END) as with_orders
FROM product_analysis
GROUP BY action
ORDER BY action;

-- Step 2: Show sample of products marked for removal
WITH products_to_remove AS (
    SELECT 
        p.id,
        p.name,
        p.sku,
        p.category,
        p.stripe_product_id,
        COUNT(DISTINCT pv.id) as variant_count,
        COUNT(DISTINCT oi.id) as order_count
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    LEFT JOIN product_variants pv ON p.id = pv.product_id
    LEFT JOIN order_items oi ON p.id = oi.product_id
    WHERE pe.id IS NULL  -- Not in enhanced
    AND (
        p.sku LIKE 'BLZ-%'  -- Old blazer format
        OR (p.sku LIKE 'SB-%' AND p.category != 'Blazers')  -- Old suspender format
        OR p.sku LIKE 'SVB-%'  -- Old vest format
    )
    GROUP BY p.id, p.name, p.sku, p.category, p.stripe_product_id
    HAVING COUNT(DISTINCT oi.id) = 0  -- No orders
)
SELECT * FROM products_to_remove
ORDER BY sku
LIMIT 20;

-- Step 3: Create backup of products to be removed
CREATE TABLE IF NOT EXISTS products_backup_before_cleanup AS
SELECT p.*, NOW() as backed_up_at
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL  -- Not in enhanced
AND (
    p.sku LIKE 'BLZ-%'  -- Old blazer format
    OR (p.sku LIKE 'SB-%' AND p.category != 'Blazers')  -- Old suspender format
    OR p.sku LIKE 'SVB-%'  -- Old vest format
)
AND NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);

-- Step 4: Count what will be removed
SELECT 
    'Products to Remove' as action,
    COUNT(*) as count
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL  -- Not in enhanced
AND (
    p.sku LIKE 'BLZ-%'  -- Old blazer format
    OR (p.sku LIKE 'SB-%' AND p.category != 'Blazers')  -- Old suspender format
    OR p.sku LIKE 'SVB-%'  -- Old vest format
)
AND NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);

-- Step 5: SAFE REMOVAL (only uncomment and run after verifying above)
/*
-- First, delete variants for products being removed
DELETE FROM product_variants
WHERE product_id IN (
    SELECT p.id
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE pe.id IS NULL  -- Not in enhanced
    AND (
        p.sku LIKE 'BLZ-%'  -- Old blazer format
        OR (p.sku LIKE 'SB-%' AND p.category != 'Blazers')  -- Old suspender format
        OR p.sku LIKE 'SVB-%'  -- Old vest format
    )
    AND NOT EXISTS (
        SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
    )
);

-- Then, delete the products themselves
DELETE FROM products
WHERE id IN (
    SELECT p.id
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE pe.id IS NULL  -- Not in enhanced
    AND (
        p.sku LIKE 'BLZ-%'  -- Old blazer format
        OR (p.sku LIKE 'SB-%' AND p.category != 'Blazers')  -- Old suspender format
        OR p.sku LIKE 'SVB-%'  -- Old vest format
    )
    AND NOT EXISTS (
        SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
    )
);
*/

-- Step 6: Verify what remains
SELECT 
    'Products Remaining' as status,
    COUNT(*) as total,
    COUNT(CASE WHEN pe.id IS NOT NULL THEN 1 END) as in_enhanced,
    COUNT(CASE WHEN pe.id IS NULL THEN 1 END) as not_in_enhanced,
    COUNT(CASE WHEN p.stripe_product_id IS NOT NULL THEN 1 END) as with_stripe_id
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id;