-- RUN THIS FIRST to understand the ACTUAL database structure
-- Before importing ANYTHING!

-- 1. Check products table columns
SELECT '=== PRODUCTS TABLE ===' as table_info;
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
AND column_name IN ('id', 'sku', 'handle', 'name', 'description', 'base_price', 
                    'category', 'status', 'primary_image', 'additional_info', 
                    'metadata', 'image_url')
ORDER BY ordinal_position;

-- 2. Check product_variants table columns
SELECT '=== PRODUCT_VARIANTS TABLE ===' as table_info;
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'product_variants'
ORDER BY ordinal_position;

-- 3. Check product_images table columns
SELECT '=== PRODUCT_IMAGES TABLE ===' as table_info;
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'product_images'
ORDER BY ordinal_position;

-- 4. Check if we have existing products with these SKU patterns
SELECT '=== EXISTING PRODUCTS CHECK ===' as check_type;
SELECT 
    COUNT(*) as total_products,
    COUNT(*) FILTER (WHERE sku LIKE 'VST-%') as existing_vests,
    COUNT(*) FILTER (WHERE sku LIKE 'SUS-%') as existing_suspenders,
    COUNT(*) FILTER (WHERE sku LIKE 'SHO-%') as existing_shoes,
    COUNT(*) FILTER (WHERE additional_info->>'source' = 'csv_import') as previous_imports
FROM products;

-- 5. Check sample of existing product_variants to see structure
SELECT '=== SAMPLE PRODUCT_VARIANT ===' as sample;
SELECT * FROM product_variants LIMIT 1;

-- 6. Check sample of existing product to see how it's structured
SELECT '=== SAMPLE PRODUCT ===' as sample;
SELECT id, sku, handle, name, category, base_price, primary_image
FROM products 
WHERE primary_image IS NOT NULL
LIMIT 1;