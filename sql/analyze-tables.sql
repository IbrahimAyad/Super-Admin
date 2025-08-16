-- Analyze table structures to understand what we're working with

-- 1. Show all columns in products table
SELECT 
    'products' as table_name,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- 2. Show all columns in products_enhanced table
SELECT 
    'products_enhanced' as table_name,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products_enhanced'
ORDER BY ordinal_position;

-- 3. Show all columns in product_variants table
SELECT 
    'product_variants' as table_name,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_variants'
ORDER BY ordinal_position;

-- 4. Check foreign key relationships
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('product_variants', 'products', 'products_enhanced');

-- 5. Count records in each table
SELECT 'products' as table_name, COUNT(*) as record_count FROM products
UNION ALL
SELECT 'products_enhanced', COUNT(*) FROM products_enhanced
UNION ALL
SELECT 'product_variants', COUNT(*) FROM product_variants;

-- 6. Check if there are any products in 'products' table
SELECT id, name, handle, sku FROM products LIMIT 5;

-- 7. Check products_enhanced sample
SELECT id, name, handle, sku FROM products_enhanced LIMIT 5;