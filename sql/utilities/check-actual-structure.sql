-- ============================================
-- CHECK ACTUAL TABLE STRUCTURE
-- ============================================

-- 1. Show ALL columns in product_images table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
ORDER BY ordinal_position;

-- 2. Show sample of ALL data from product_images
SELECT * 
FROM product_images
LIMIT 5;

-- 3. Check products table to see if images are stored there
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
AND (column_name LIKE '%image%' OR column_name LIKE '%url%' OR column_name LIKE '%photo%')
ORDER BY ordinal_position;

-- 4. Sample from products table looking for image fields
SELECT 
    id,
    name,
    primary_image,
    image_gallery
FROM products
WHERE (primary_image IS NOT NULL OR image_gallery IS NOT NULL)
LIMIT 5;

-- 5. Count how many products have images
SELECT 
    COUNT(*) as total_products,
    COUNT(primary_image) as has_primary_image,
    COUNT(image_gallery) as has_image_gallery
FROM products;

-- 6. Check if product_images table is empty
SELECT COUNT(*) as product_images_count FROM product_images;

-- 7. Show a sample primary_image value
SELECT 
    substring(primary_image from 1 for 200) as primary_image_sample
FROM products
WHERE primary_image IS NOT NULL
LIMIT 5;