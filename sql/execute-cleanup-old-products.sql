-- Execute Safe Cleanup of 274 Old Products
-- This will remove products that are NOT in products_enhanced and have no orders

-- Step 1: Final verification before deletion
SELECT 
    'Pre-Cleanup Status' as stage,
    COUNT(*) as products_to_remove,
    COUNT(DISTINCT pv.id) as variants_to_remove
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE pe.id IS NULL  -- Not in enhanced (274 products)
AND NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);

-- Step 2: Create final backup with timestamp
CREATE TABLE IF NOT EXISTS products_backup_20250116 AS
SELECT 
    p.*,
    NOW() as backed_up_at,
    'Not in enhanced table' as removal_reason
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL;

-- Step 3: Delete variants for the 274 old products
DELETE FROM product_variants
WHERE product_id IN (
    SELECT p.id
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE pe.id IS NULL  -- Not in enhanced
    AND NOT EXISTS (
        SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
    )
);

-- Step 4: Delete the 274 old products
DELETE FROM products
WHERE id IN (
    SELECT p.id
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE pe.id IS NULL  -- Not in enhanced
    AND NOT EXISTS (
        SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
    )
);

-- Step 5: Verify cleanup results
SELECT 
    'Post-Cleanup Status' as stage,
    COUNT(*) as total_products_remaining,
    COUNT(CASE WHEN pe.id IS NOT NULL THEN 1 END) as synced_with_enhanced,
    COUNT(CASE WHEN pe.id IS NULL THEN 1 END) as not_in_enhanced_should_be_zero
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id;

-- Step 6: Show what's left in products table
SELECT 
    p.category,
    COUNT(*) as count,
    COUNT(CASE WHEN pe.id IS NOT NULL THEN 1 END) as in_enhanced,
    STRING_AGG(DISTINCT SUBSTRING(p.sku FROM 1 FOR 3), ', ') as sku_prefixes
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
GROUP BY p.category
ORDER BY count DESC;

-- Step 7: Summary report
WITH cleanup_summary AS (
    SELECT 
        (SELECT COUNT(*) FROM products_backup_20250116) as backed_up_count,
        (SELECT COUNT(*) FROM products) as remaining_products,
        (SELECT COUNT(*) FROM products_enhanced) as enhanced_products,
        (SELECT COUNT(*) FROM product_variants) as total_variants
)
SELECT 
    '✅ Cleanup Complete' as status,
    backed_up_count as products_backed_up,
    remaining_products as products_remaining,
    enhanced_products as products_in_enhanced,
    total_variants as variants_remaining
FROM cleanup_summary;

-- Optional: View backup table sample
SELECT * FROM products_backup_20250116 
LIMIT 10;