-- FINAL CHECK AND IMPORT SCRIPT
-- This checks what actually exists and only uses those columns

-- STEP 1: Check what columns ACTUALLY exist
DO $$
DECLARE
    has_size_column BOOLEAN;
    has_color_column BOOLEAN;
    has_option1_column BOOLEAN;
    variant_columns TEXT;
BEGIN
    -- Check if product_variants has 'size' column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_variants' AND column_name = 'size'
    ) INTO has_size_column;
    
    -- Check if product_variants has 'color' column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_variants' AND column_name = 'color'
    ) INTO has_color_column;
    
    -- Check if product_variants has 'option1' column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_variants' AND column_name = 'option1'
    ) INTO has_option1_column;
    
    -- Get all columns from product_variants
    SELECT string_agg(column_name, ', ') 
    FROM information_schema.columns 
    WHERE table_name = 'product_variants'
    INTO variant_columns;
    
    RAISE NOTICE '=== PRODUCT_VARIANTS TABLE CHECK ===';
    RAISE NOTICE 'Has size column: %', has_size_column;
    RAISE NOTICE 'Has color column: %', has_color_column;
    RAISE NOTICE 'Has option1 column: %', has_option1_column;
    RAISE NOTICE 'All columns: %', variant_columns;
END $$;

-- STEP 2: Show sample existing variant to understand structure
SELECT '=== SAMPLE EXISTING VARIANT ===' as check;
SELECT * FROM product_variants LIMIT 1;

-- STEP 3: Show how existing products with variants look
SELECT '=== SAMPLE PRODUCT WITH VARIANTS ===' as check;
SELECT 
    p.id,
    p.sku,
    p.name,
    p.category,
    COUNT(pv.id) as variant_count,
    array_agg(DISTINCT pv.sku) as variant_skus
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.id IS NOT NULL
GROUP BY p.id, p.sku, p.name, p.category
LIMIT 3;

-- STEP 4: TEST IMPORT - Single product without variants first
BEGIN;

-- Test inserting one product
INSERT INTO products (
    id,
    sku,
    handle,
    name,
    description,
    base_price,
    category,
    status,
    primary_image,
    additional_info,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'TEST-IMPORT-001',
    'test-import-product',
    'Test Import Product',
    'This is a test import to verify structure',
    5000, -- $50.00 in cents
    'Test Category',
    'active',
    'https://example.com/test.jpg',
    jsonb_build_object('source', 'test_import'),
    NOW(),
    NOW()
);

-- Show it worked
SELECT 'Product inserted successfully!' as status;

-- Clean up test
ROLLBACK;

-- STEP 5: If size/color columns don't exist, check what we should use
-- This query will show us the actual structure of existing variants
SELECT 
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_name = 'product_variants'
AND column_name IN ('size', 'color', 'option1', 'option2', 'option_1', 'option_2', 
                    'variant_option_1', 'variant_option_2', 'variant_name')
ORDER BY ordinal_position;