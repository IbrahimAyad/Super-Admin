-- Check Current Stripe Integration Status
-- Run this to see which products/variants need syncing

-- Overall Status
SELECT 
    'Products' as type,
    COUNT(*) as total,
    COUNT(stripe_product_id) as has_stripe,
    COUNT(*) - COUNT(stripe_product_id) as needs_stripe,
    ROUND(COUNT(stripe_product_id)::numeric / COUNT(*)::numeric * 100, 2) as percent_complete
FROM products
WHERE status = 'active'

UNION ALL

SELECT 
    'Variants' as type,
    COUNT(*) as total,
    COUNT(stripe_price_id) as has_stripe,
    COUNT(*) - COUNT(stripe_price_id) as needs_stripe,
    ROUND(COUNT(stripe_price_id)::numeric / COUNT(*)::numeric * 100, 2) as percent_complete
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- Products without Stripe IDs (top 10)
SELECT 
    sku,
    name,
    category,
    base_price / 100.0 as price_usd
FROM products
WHERE stripe_product_id IS NULL
AND status = 'active'
ORDER BY created_at DESC
LIMIT 10;

-- Check which categories need syncing
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(stripe_product_id) as synced_products,
    COUNT(*) - COUNT(stripe_product_id) as needs_sync
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY needs_sync DESC;

-- Variants missing Stripe prices on products that HAVE Stripe IDs
SELECT COUNT(*) as orphaned_variants
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.stripe_product_id IS NOT NULL
AND pv.stripe_price_id IS NULL;