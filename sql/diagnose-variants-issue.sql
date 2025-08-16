-- Diagnose why variants aren't being created

-- 1. Check if product_variants table has any unique constraints
SELECT 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'product_variants'
AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY');

-- 2. Check existing variants for our products
SELECT 
    p.sku,
    p.name,
    pv.option1 as size,
    pv.option2 as color,
    pv.sku as variant_sku
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%'
ORDER BY p.sku
LIMIT 20;

-- 3. Check for any existing variants that might be blocking
SELECT 
    COUNT(*) as existing_variants,
    COUNT(DISTINCT product_id) as products_with_variants
FROM product_variants
WHERE product_id IN (
    SELECT id FROM products 
    WHERE sku LIKE 'F25-%' OR sku LIKE 'ACC-%'
);

-- 4. Try to manually create a single variant to see exact error
DO $$
DECLARE
    test_product RECORD;
BEGIN
    -- Get one product to test
    SELECT p.*, pe.color_name 
    INTO test_product
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE p.sku LIKE 'F25-DOU-%'
    LIMIT 1;
    
    IF test_product.id IS NOT NULL THEN
        RAISE NOTICE 'Testing variant creation for: % (ID: %)', test_product.name, test_product.id;
        
        -- Try to insert a variant
        INSERT INTO product_variants (
            product_id,
            title,
            option1,
            option2,
            sku,
            price,
            inventory_quantity,
            available,
            available_quantity,
            created_at,
            updated_at
        ) VALUES (
            test_product.id,
            test_product.name || ' - 42R',
            '42R',
            COALESCE(test_product.color_name, 'Standard'),
            test_product.sku || '-42R',
            test_product.base_price,
            25,
            true,
            25,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'SUCCESS: Variant created';
    ELSE
        RAISE NOTICE 'No test product found';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR creating variant: %', SQLERRM;
    RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
END $$;

-- 5. Check the columns in product_variants table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'product_variants'
ORDER BY ordinal_position;