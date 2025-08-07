-- Check the ACTUAL columns in product_images table
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
ORDER BY ordinal_position;

-- Check sample data
SELECT * FROM product_images LIMIT 5;

-- Check if it's using image_url or some other column name
SELECT 
    COUNT(*) as total_images,
    COUNT(image_url) as has_image_url,
    COUNT(r2_url) as has_r2_url,
    COUNT(r2_key) as has_r2_key
FROM product_images;

-- Show all column names as a list
SELECT string_agg(column_name, ', ') as all_columns
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images';