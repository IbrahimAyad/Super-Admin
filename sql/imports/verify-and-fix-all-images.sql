-- Comprehensive Image Fix Script
-- This ensures all products have their images properly set

-- First, let's see what's missing
SELECT 'Products without images:' as check_type;
SELECT sku, name, category, primary_image
FROM products
WHERE additional_info->>'source' = 'csv_import_test'
AND (primary_image IS NULL OR primary_image = '');

-- Now let's fix them based on the SKU patterns
BEGIN;

-- Fix Vest & Tie Sets
UPDATE products 
SET primary_image = CASE sku
    WHEN 'VEST-001' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg'
    WHEN 'VEST-002' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg'
    WHEN 'VEST-003' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg'
    ELSE primary_image
END
WHERE sku IN ('VEST-001', 'VEST-002', 'VEST-003')
AND (primary_image IS NULL OR primary_image = '');

-- Fix Shoes
UPDATE products
SET primary_image = CASE sku
    WHEN 'SHOE-001' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg'
    WHEN 'SHOE-002' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg'
    ELSE primary_image
END
WHERE sku IN ('SHOE-001', 'SHOE-002')
AND (primary_image IS NULL OR primary_image = '');

-- Fix Accessories
UPDATE products
SET primary_image = CASE sku
    WHEN 'ACC-001' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg'
    WHEN 'ACC-002' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_red-cummerbund-set_1.0.jpg'
    ELSE primary_image
END
WHERE sku IN ('ACC-001', 'ACC-002')
AND (primary_image IS NULL OR primary_image = '');

-- Now ensure product_images table is synchronized
INSERT INTO product_images (
    id,
    product_id,
    image_url,
    image_type,
    position,
    alt_text,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    p.id,
    p.primary_image,
    'primary',
    1,
    p.name,
    NOW(),
    NOW()
FROM products p
WHERE p.additional_info->>'source' = 'csv_import_test'
AND p.primary_image IS NOT NULL
AND p.primary_image != ''
AND NOT EXISTS (
    SELECT 1 FROM product_images pi 
    WHERE pi.product_id = p.id 
    AND pi.image_url = p.primary_image
);

-- Verify all products now have images
SELECT 'Final verification:' as status;
SELECT 
    p.sku,
    p.name,
    p.category,
    CASE 
        WHEN p.primary_image IS NOT NULL AND p.primary_image != '' THEN '✓ Has primary image'
        ELSE '✗ Missing image'
    END as primary_image_status,
    COUNT(pi.id) as images_in_table
FROM products p
LEFT JOIN product_images pi ON pi.product_id = p.id
WHERE p.additional_info->>'source' = 'csv_import_test'
GROUP BY p.id, p.sku, p.name, p.category, p.primary_image
ORDER BY p.sku;

COMMIT;

-- Show the actual image URLs to verify they're correct
SELECT 
    sku,
    name,
    SUBSTRING(primary_image FROM 1 FOR 100) || '...' as image_url_preview
FROM products
WHERE additional_info->>'source' = 'csv_import_test'
ORDER BY sku;