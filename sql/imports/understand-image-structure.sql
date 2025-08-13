-- Check the actual product_images table structure
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'product_images'
ORDER BY ordinal_position;

-- Check how existing products link to images
SELECT 
    p.id,
    p.sku,
    p.name,
    p.primary_image,
    pi.id as image_id,
    pi.image_url,
    pi.image_type,
    pi.position
FROM products p
LEFT JOIN product_images pi ON pi.product_id = p.id
WHERE p.sku IS NOT NULL
LIMIT 5;
