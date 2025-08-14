-- EXPORT ALL PRODUCTS TO CSV
-- Run this in Supabase SQL Editor and export the results

SELECT 
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.category,
    SUBSTRING(p.description, 1, 200) as description,
    p.handle,
    p.supplier,
    p.brand,
    p.status,
    
    -- Pricing
    pv.price as price_cents,
    CONCAT('$', ROUND(pv.price / 100.0, 2)) as price_formatted,
    pv.stripe_price_id,
    CASE 
        WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' THEN 'Ready'
        ELSE 'Missing'
    END as stripe_status,
    
    -- Inventory
    pv.inventory_count,
    CASE 
        WHEN pv.inventory_count > 0 THEN 'In Stock'
        ELSE 'Out of Stock'
    END as stock_status,
    
    -- Images
    p.primary_image,
    CASE 
        WHEN p.primary_image LIKE '%placehold%' THEN 'Placeholder'
        WHEN p.primary_image LIKE '%8ea0502%' THEN 'Gallery (New)'
        WHEN p.primary_image LIKE '%pub-5cd%' THEN 'Old R2'
        WHEN p.primary_image IS NOT NULL THEN 'Has Image'
        ELSE 'No Image'
    END as image_status,
    
    -- Gallery count
    (SELECT COUNT(*) FROM product_images pi WHERE pi.product_id = p.id) as gallery_count,
    
    -- Gallery URLs (first 3)
    (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.position LIMIT 1 OFFSET 0) as gallery_1,
    (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.position LIMIT 1 OFFSET 1) as gallery_2,
    (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.position LIMIT 1 OFFSET 2) as gallery_3,
    
    -- Variant info
    pv.id as variant_id,
    pv.title as variant_title,
    (SELECT COUNT(*) FROM product_variants pv2 WHERE pv2.product_id = p.id) as total_variants,
    
    -- Dates
    p.created_at::date as created_date,
    p.updated_at::date as updated_date
    
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
ORDER BY 
    p.category,
    p.name,
    pv.title;