-- Create Product Variants - Final Version
-- Fixed to match actual product_variants table structure

-- First, sync products from products_enhanced
INSERT INTO products (
    id, 
    name, 
    description,
    sku, 
    category, 
    base_price, 
    status, 
    created_at, 
    updated_at
)
SELECT 
    id, 
    name, 
    COALESCE(description, 'Premium ' || name || ' from our exclusive collection.'),
    sku, 
    category, 
    base_price,
    status,
    created_at,
    updated_at
FROM products_enhanced
WHERE (sku LIKE 'F25-%' OR sku LIKE 'ACC-%')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    sku = EXCLUDED.sku,
    category = EXCLUDED.category,
    base_price = EXCLUDED.base_price,
    status = EXCLUDED.status,
    updated_at = NOW();

-- Create variants for new products
DO $$
DECLARE
    product_record RECORD;
    size_text TEXT;
    sizes_array TEXT[];
    inventory_qty INTEGER;
    created_count INTEGER := 0;
    product_count INTEGER := 0;
    variant_sku TEXT;
BEGIN
    RAISE NOTICE 'Starting variant creation...';
    
    -- Loop through new products
    FOR product_record IN 
        SELECT p.*, pe.color_name, pe.color_family
        FROM products p
        LEFT JOIN products_enhanced pe ON p.id = pe.id
        WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%'
        ORDER BY p.category, p.name
    LOOP
        product_count := product_count + 1;
        
        -- Determine sizes based on product type
        
        -- ACCESSORIES - Suspender & Bowtie Sets (One Size)
        IF product_record.sku LIKE 'ACC-SBS-%' OR 
           LOWER(product_record.name) LIKE '%suspender%bowtie%' OR
           LOWER(product_record.name) LIKE '%suspender%bow%' THEN
            sizes_array := ARRAY['One Size'];
            
        -- ACCESSORIES - Vest & Tie Sets (XS-6XL)
        ELSIF product_record.sku LIKE 'ACC-VTS-%' OR 
              LOWER(product_record.name) LIKE '%vest%tie%' OR
              LOWER(product_record.name) LIKE '%vest%' THEN
            sizes_array := ARRAY['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL'];
            
        -- TUXEDOS (36R-54R, 36L-54L)
        ELSIF product_record.category = 'Tuxedos' OR 
              LOWER(product_record.name) LIKE '%tuxedo%' THEN
            sizes_array := ARRAY[
                '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R',
                '36L', '38L', '40L', '42L', '44L', '46L', '48L', '50L', '52L', '54L'
            ];
            
        -- DOUBLE-BREASTED SUITS (36R-54R, 36L-54L)
        ELSIF product_record.category = 'Double-Breasted Suits' OR 
              LOWER(product_record.name) LIKE '%double%breasted%' THEN
            sizes_array := ARRAY[
                '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R',
                '36L', '38L', '40L', '42L', '44L', '46L', '48L', '50L', '52L', '54L'
            ];
            
        -- STRETCH SUITS (36R-54R, 36L-54L)
        ELSIF product_record.category = 'Stretch Suits' OR 
              LOWER(product_record.name) LIKE '%stretch%suit%' THEN
            sizes_array := ARRAY[
                '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R',
                '36L', '38L', '40L', '42L', '44L', '46L', '48L', '50L', '52L', '54L'
            ];
            
        -- REGULAR SUITS (36R-54R, 36L-54L)
        ELSIF product_record.category = 'Suits' OR 
              LOWER(product_record.name) LIKE '%suit%' THEN
            sizes_array := ARRAY[
                '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R',
                '36L', '38L', '40L', '42L', '44L', '46L', '48L', '50L', '52L', '54L'
            ];
            
        -- DRESS SHIRTS (Neck sizes)
        ELSIF product_record.category = 'Mens Shirts' OR 
              LOWER(product_record.name) LIKE '%shirt%' THEN
            sizes_array := ARRAY['14.5', '15', '15.5', '16', '16.5', '17', '17.5', '18'];
            
        ELSE
            -- Default sizes
            sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
        END IF;

        -- Create a variant for each size
        FOREACH size_text IN ARRAY sizes_array
        LOOP
            -- Set inventory levels based on size
            IF size_text = 'One Size' THEN
                inventory_qty := 100;
            ELSIF size_text IN ('40R', '42R', '44R', 'L', 'XL', '16', '16.5') THEN
                inventory_qty := floor(random() * 25 + 20)::INTEGER;
            ELSIF size_text LIKE '%L' AND size_text NOT IN ('L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL') THEN
                inventory_qty := floor(random() * 15 + 10)::INTEGER;
            ELSIF size_text IN ('XS', '5XL', '6XL', '14.5', '18', '54R', '54L') THEN
                inventory_qty := floor(random() * 10 + 5)::INTEGER;
            ELSE
                inventory_qty := floor(random() * 20 + 15)::INTEGER;
            END IF;

            -- Generate variant SKU
            variant_sku := product_record.sku || '-' || REPLACE(REPLACE(size_text, '.', ''), ' ', '');

            -- Insert the variant with proper structure
            BEGIN
                INSERT INTO product_variants (
                    product_id,
                    title,
                    price,  -- Required field
                    sku,    -- Required field
                    option1, -- Size
                    option2, -- Color
                    inventory_quantity,
                    stock_quantity,
                    available_quantity,
                    available,
                    created_at,
                    updated_at
                ) VALUES (
                    product_record.id,
                    product_record.name || ' - ' || size_text,
                    product_record.base_price,  -- Price as integer
                    variant_sku,
                    size_text,
                    COALESCE(product_record.color_name, 'Standard'),
                    inventory_qty,
                    inventory_qty,  -- stock_quantity
                    inventory_qty,  -- available_quantity
                    true,
                    NOW(),
                    NOW()
                )
                ON CONFLICT (sku) DO UPDATE SET
                    price = EXCLUDED.price,
                    inventory_quantity = EXCLUDED.inventory_quantity,
                    stock_quantity = EXCLUDED.stock_quantity,
                    available_quantity = EXCLUDED.available_quantity,
                    updated_at = NOW();
                    
                created_count := created_count + 1;
                
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error creating variant for % size %: %', 
                    product_record.name, size_text, SQLERRM;
            END;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VARIANTS CREATION COMPLETE';
    RAISE NOTICE 'Products processed: %', product_count;
    RAISE NOTICE 'Variants created/updated: %', created_count;
    RAISE NOTICE '==============================================';
END $$;

-- Show summary of created variants by category
SELECT 
    p.category,
    COUNT(DISTINCT p.id) as product_count,
    COUNT(pv.id) as total_variants,
    MIN(pv.inventory_quantity) as min_inventory,
    MAX(pv.inventory_quantity) as max_inventory,
    ROUND(AVG(pv.inventory_quantity)) as avg_inventory
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%'
GROUP BY p.category
ORDER BY p.category;

-- Show sample of created variants
SELECT 
    p.category,
    p.name,
    pv.option1 as size,
    pv.option2 as color,
    pv.sku as variant_sku,
    pv.inventory_quantity
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%'
ORDER BY p.category, p.name, 
    CASE 
        WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
        WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
        WHEN pv.option1 = 'XS' THEN 1
        WHEN pv.option1 = 'S' THEN 2
        WHEN pv.option1 = 'M' THEN 3
        WHEN pv.option1 = 'L' THEN 4
        WHEN pv.option1 = 'XL' THEN 5
        WHEN pv.option1 = 'XXL' THEN 6
        WHEN pv.option1 = '3XL' THEN 7
        WHEN pv.option1 = '4XL' THEN 8
        WHEN pv.option1 = '5XL' THEN 9
        WHEN pv.option1 = '6XL' THEN 10
        WHEN pv.option1 ~ '^\d+\.?\d*$' THEN CAST(REPLACE(pv.option1, '.', '') AS NUMERIC)
        WHEN pv.option1 = 'One Size' THEN 0
        ELSE 999
    END
LIMIT 30;