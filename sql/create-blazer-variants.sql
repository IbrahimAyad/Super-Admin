-- Create Blazer Variants with Correct Pricing and Sizes
-- Blazers: $199-249 price range, sizes 36R-54R only (no Long sizes)

-- First, update blazer prices in products_enhanced to be in the $199-249 range
UPDATE products_enhanced
SET 
    base_price = 199 + FLOOR(RANDOM() * 50)::INTEGER,  -- Random price between $199-249
    compare_at_price = base_price + FLOOR(RANDOM() * 50 + 50)::INTEGER,  -- Compare price $50-100 higher
    updated_at = NOW()
WHERE (LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%')
AND (base_price < 199 OR base_price > 249);  -- Only update if outside range

-- Sync blazers from products_enhanced to products table
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
    COALESCE(description, 'Premium ' || name || ' - Luxurious blazer from our exclusive collection. Perfect for special occasions and formal events.'),
    sku, 
    category, 
    base_price,
    status,
    created_at,
    updated_at
FROM products_enhanced
WHERE LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    sku = EXCLUDED.sku,
    category = EXCLUDED.category,
    base_price = EXCLUDED.base_price,
    status = EXCLUDED.status,
    updated_at = NOW();

-- Create variants for blazers
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
    RAISE NOTICE 'Creating variants for Blazer collection...';
    RAISE NOTICE 'Sizes: 36R-54R only (no Long sizes)';
    RAISE NOTICE 'Price range: $199-249';
    
    -- Blazer sizes: 36R-54R only (no Longs)
    sizes_array := ARRAY[
        '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R'
    ];
    
    -- Loop through blazer products
    FOR product_record IN 
        SELECT p.*, pe.color_name, pe.color_family
        FROM products p
        LEFT JOIN products_enhanced pe ON p.id = pe.id
        WHERE LOWER(p.name) LIKE '%blazer%' OR LOWER(p.category) LIKE '%blazer%'
        ORDER BY p.category, p.name
    LOOP
        product_count := product_count + 1;
        RAISE NOTICE 'Processing blazer: % (SKU: %)', product_record.name, product_record.sku;
        
        -- Create a variant for each size
        FOREACH size_text IN ARRAY sizes_array
        LOOP
            -- Set inventory levels based on size popularity
            -- Popular sizes get more inventory
            IF size_text IN ('40R', '42R', '44R', '46R') THEN
                -- Most popular sizes - higher inventory
                inventory_qty := floor(random() * 30 + 25)::INTEGER; -- 25-55 units
            ELSIF size_text IN ('38R', '48R', '50R') THEN
                -- Moderate popularity
                inventory_qty := floor(random() * 20 + 15)::INTEGER; -- 15-35 units
            ELSIF size_text IN ('36R', '52R', '54R') THEN
                -- Less common sizes - lower inventory
                inventory_qty := floor(random() * 15 + 8)::INTEGER; -- 8-23 units
            ELSE
                -- Standard inventory
                inventory_qty := floor(random() * 25 + 20)::INTEGER; -- 20-45 units
            END IF;

            -- Generate variant SKU
            variant_sku := product_record.sku || '-' || size_text;

            -- Insert the variant
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
                    product_record.base_price,  -- Price from products table
                    variant_sku,
                    size_text,
                    COALESCE(product_record.color_name, 
                        CASE 
                            WHEN product_record.sku LIKE 'VB-%' THEN 'Velvet'
                            WHEN product_record.sku LIKE 'PB-%' THEN 'Paisley'
                            WHEN product_record.sku LIKE 'SPB%' THEN 'Sparkle'
                            WHEN product_record.sku LIKE 'SB-%' THEN 'Sequin'
                            ELSE 'Classic'
                        END),
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
    RAISE NOTICE 'BLAZER VARIANTS CREATION COMPLETE';
    RAISE NOTICE 'Blazers processed: %', product_count;
    RAISE NOTICE 'Variants created/updated: %', created_count;
    RAISE NOTICE 'Size range: 36R-54R (10 sizes per blazer)';
    RAISE NOTICE 'Price range: $199-249';
    RAISE NOTICE '==============================================';
END $$;

-- Show summary of blazer variants created
SELECT 
    p.category,
    CASE 
        WHEN p.sku LIKE 'VB-%' THEN 'Velvet Blazers'
        WHEN p.sku LIKE 'PB-%' THEN 'Paisley Blazers'
        WHEN p.sku LIKE 'SPB%' THEN 'Sparkle Blazers'
        WHEN p.sku LIKE 'SB-%' THEN 'Sequin Blazers'
        ELSE 'Other Blazers'
    END as blazer_type,
    COUNT(DISTINCT p.id) as product_count,
    COUNT(pv.id) as total_variants,
    MIN(p.base_price) as min_price,
    MAX(p.base_price) as max_price,
    ROUND(AVG(p.base_price)) as avg_price,
    ROUND(AVG(pv.inventory_quantity)) as avg_inventory
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(p.name) LIKE '%blazer%' OR LOWER(p.category) LIKE '%blazer%'
GROUP BY p.category, blazer_type
ORDER BY blazer_type;

-- Show sample of created blazer variants
SELECT 
    p.name,
    p.sku,
    p.base_price as price,
    STRING_AGG(pv.option1, ', ' ORDER BY 
        CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER)
    ) as available_sizes,
    COUNT(pv.id) as total_sizes
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(p.name) LIKE '%blazer%' OR LOWER(p.category) LIKE '%blazer%'
GROUP BY p.name, p.sku, p.base_price
ORDER BY p.sku
LIMIT 10;