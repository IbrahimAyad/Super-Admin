-- Fix Product Images for Imported Products
-- This script adds the images to both the primary_image field and product_images table

BEGIN;

-- First, let's check what we have
SELECT 'Current products with images:' as status;
SELECT sku, name, primary_image IS NOT NULL as has_primary_image
FROM products
WHERE additional_info->>'source' = 'csv_import_test';

-- Update the primary_image field for the test products
UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg'
WHERE sku = 'VEST-001' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg'
WHERE sku = 'VEST-002' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg'
WHERE sku = 'VEST-003' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg'
WHERE sku = 'SHOE-001' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg'
WHERE sku = 'SHOE-002' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg'
WHERE sku = 'ACC-001' AND primary_image IS NULL;

UPDATE products SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_red-cummerbund-set_1.0.jpg'
WHERE sku = 'ACC-002' AND primary_image IS NULL;

-- Now add to product_images table if not already there
DO $$
DECLARE
    prod RECORD;
BEGIN
    FOR prod IN 
        SELECT id, sku, name, primary_image 
        FROM products 
        WHERE additional_info->>'source' = 'csv_import_test'
        AND primary_image IS NOT NULL
    LOOP
        -- Check if image already exists
        IF NOT EXISTS (
            SELECT 1 FROM product_images 
            WHERE product_id = prod.id 
            AND image_url = prod.primary_image
        ) THEN
            INSERT INTO product_images (
                id,
                product_id,
                image_url,
                image_type,
                position,
                alt_text,
                created_at,
                updated_at
            ) VALUES (
                gen_random_uuid(),
                prod.id,
                prod.primary_image,
                'primary',
                1,
                prod.name,
                NOW(),
                NOW()
            );
            RAISE NOTICE 'Added image for %', prod.name;
        END IF;
    END LOOP;
END $$;

-- Verify the fix
SELECT 'After fix - Products with images:' as status;
SELECT 
    p.sku, 
    p.name,
    p.primary_image IS NOT NULL as has_primary_image,
    COUNT(pi.id) as image_count
FROM products p
LEFT JOIN product_images pi ON pi.product_id = p.id
WHERE p.additional_info->>'source' = 'csv_import_test'
GROUP BY p.id, p.sku, p.name, p.primary_image
ORDER BY p.sku;

COMMIT;

-- Show sample of what we fixed
SELECT 
    p.sku,
    p.name,
    LEFT(p.primary_image, 80) || '...' as image_url_preview
FROM products p
WHERE p.additional_info->>'source' = 'csv_import_test'
AND p.primary_image IS NOT NULL
ORDER BY p.sku;