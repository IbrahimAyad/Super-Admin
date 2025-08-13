-- WORKING Import Script Using option1/option2 columns
-- Based on actual database structure where:
-- option1 = size
-- option2 = color
-- Generated: 2025-08-12

-- First, let's verify the complete structure
SELECT 'Checking product_variants structure...' as status;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product_variants' 
ORDER BY ordinal_position;

BEGIN;

-- Create helper function for URL-safe handles
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- TEST IMPORT: 3 Vest Sets with Variants
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    vest_data RECORD;
    size_array TEXT[] := ARRAY['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
    size_val TEXT;
BEGIN
    -- Import 3 test vest sets
    FOR vest_data IN 
        SELECT * FROM (VALUES
            ('White Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg', 6500, 'White'),
            ('Blush Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg', 6500, 'Blush'),
            ('Blue Carolina Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg', 6500, 'Carolina Blue')
        ) AS t(name, image_url, price_cents, color)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product
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
            new_product_id,
            'VEST-' || LPAD(product_counter::text, 3, '0'),
            create_handle(vest_data.name),
            vest_data.name,
            'Premium vest and tie set for formal occasions',
            vest_data.price_cents,
            'Vest & Tie Sets',
            'active',
            vest_data.image_url,
            jsonb_build_object(
                'source', 'csv_import_test',
                'import_date', NOW()::text
            ),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Created product: %', vest_data.name;
        
        -- Create size variants using option1 and option2
        FOREACH size_val IN ARRAY size_array
        LOOP
            INSERT INTO product_variants (
                product_id,
                title,  -- Add the required title column
                option1,  -- This is size
                option2,  -- This is color
                sku,
                price,
                inventory_quantity,
                created_at,
                updated_at
            ) VALUES (
                new_product_id,
                vest_data.name || ' - Size ' || size_val,  -- Create title like "White Vest And Tie Set - Size XS"
                size_val,  -- Size goes in option1
                vest_data.color,  -- Color goes in option2
                'VEST-' || LPAD(product_counter::text, 3, '0') || '-' || REPLACE(size_val, ' ', ''),
                vest_data.price_cents,  -- Price as INTEGER
                CASE 
                    WHEN size_val IN ('M', 'L', 'XL') THEN 25
                    WHEN size_val IN ('S', '2XL') THEN 20
                    ELSE 15
                END,
                NOW(),
                NOW()
            ) ON CONFLICT (sku) DO NOTHING;
        END LOOP;
        
        RAISE NOTICE 'Created % variants for %', array_length(size_array, 1), vest_data.name;
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- TEST IMPORT: 2 Shoes with size variants
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    shoe_data RECORD;
    shoe_sizes TEXT[] := ARRAY['7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12'];
    size_val TEXT;
BEGIN
    FOR shoe_data IN 
        SELECT * FROM (VALUES
            ('Black Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg', 16500, 'Black'),
            ('Brown Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg', 16500, 'Brown')
        ) AS t(name, image_url, price_cents, color)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product
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
            new_product_id,
            'SHOE-' || LPAD(product_counter::text, 3, '0'),
            create_handle(shoe_data.name),
            shoe_data.name,
            'Premium dress shoes for formal events',
            shoe_data.price_cents,
            'Shoes',
            'active',
            shoe_data.image_url,
            jsonb_build_object(
                'source', 'csv_import_test',
                'import_date', NOW()::text
            ),
            NOW(),
            NOW()
        );
        
        -- Create shoe size variants
        FOREACH size_val IN ARRAY shoe_sizes
        LOOP
            INSERT INTO product_variants (
                product_id,
                title,  -- Add the required title column
                option1,  -- Size
                option2,  -- Color
                sku,
                price,
                inventory_quantity,
                created_at,
                updated_at
            ) VALUES (
                new_product_id,
                shoe_data.name || ' - Size ' || size_val,  -- Create title like "Black Chelsea Boots - Size 9"
                size_val,
                shoe_data.color,
                'SHOE-' || LPAD(product_counter::text, 3, '0') || '-' || REPLACE(size_val, '.', ''),
                shoe_data.price_cents,
                20,  -- Default inventory
                NOW(),
                NOW()
            ) ON CONFLICT (sku) DO NOTHING;
        END LOOP;
        
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Imported % shoes with variants', product_counter - 1;
END $$;

-- TEST IMPORT: 2 Accessories without variants
DO $$
DECLARE
    product_counter INT := 1;
    accessory_data RECORD;
BEGIN
    FOR accessory_data IN
        SELECT * FROM (VALUES
            ('Black Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg', 4500),
            ('Red Cummerbund Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_red-cummerbund-set_1.0.jpg', 8500)
        ) AS t(name, image_url, price_cents)
    LOOP
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
            'ACC-' || LPAD(product_counter::text, 3, '0'),
            create_handle(accessory_data.name),
            accessory_data.name,
            'Premium accessories for formal occasions',
            accessory_data.price_cents,
            'Accessories',
            'active',
            accessory_data.image_url,
            jsonb_build_object(
                'source', 'csv_import_test',
                'import_date', NOW()::text
            ),
            NOW(),
            NOW()
        );
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Imported % accessories', product_counter - 1;
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id)
WHERE p.additional_info->>'source' = 'csv_import_test';

-- Summary Report
SELECT 
    'TEST IMPORT COMPLETE' as status,
    COUNT(*) as products_imported,
    COUNT(*) FILTER (WHERE category = 'Vest & Tie Sets') as vests,
    COUNT(*) FILTER (WHERE category = 'Shoes') as shoes,
    COUNT(*) FILTER (WHERE category = 'Accessories') as accessories
FROM products
WHERE additional_info->>'source' = 'csv_import_test';

-- Show imported products with variant counts
SELECT 
    p.sku,
    p.name,
    p.category,
    p.base_price/100.0 as price_dollars,
    COUNT(pv.id) as variant_count,
    string_agg(DISTINCT pv.option1, ', ' ORDER BY pv.option1) as sizes,
    string_agg(DISTINCT pv.option2, ', ' ORDER BY pv.option2) as colors
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.additional_info->>'source' = 'csv_import_test'
GROUP BY p.id, p.sku, p.name, p.category, p.base_price
ORDER BY p.created_at;

COMMIT;

-- To ROLLBACK if needed:
-- DELETE FROM products WHERE additional_info->>'source' = 'csv_import_test';