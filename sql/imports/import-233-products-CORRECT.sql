-- CORRECT Product Import Script Based on Actual Database Structure
-- This version uses the correct columns and data types
-- Generated: 2025-08-12

BEGIN;

-- Create temporary function to generate size variants
CREATE OR REPLACE FUNCTION create_size_variants(
    p_product_id UUID,
    p_product_name TEXT,
    p_category TEXT,
    p_base_sku TEXT,
    p_base_price INTEGER
) RETURNS void AS $$
DECLARE
    sizes TEXT[];
    size TEXT;
    variant_sku TEXT;
BEGIN
    -- Determine sizes based on category
    IF p_category = 'Shoes' THEN
        sizes := ARRAY['7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12', '13'];
    ELSIF p_category IN ('Men''s Suits', 'Outerwear') THEN
        sizes := ARRAY['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '38L', '40L', '42L', '44L', '46L', '48L', '50L'];
    ELSIF p_category = 'Knitwear' THEN
        sizes := ARRAY['S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
    ELSIF p_product_name ILIKE '%vest%' THEN
        sizes := ARRAY['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL'];
    ELSIF p_product_name ILIKE '%kid%' THEN
        sizes := ARRAY['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14', '16'];
    ELSE
        -- No sizes needed for accessories
        RETURN;
    END IF;
    
    -- Create size variants
    FOREACH size IN ARRAY sizes
    LOOP
        variant_sku := p_base_sku || '-' || REPLACE(REPLACE(size, '.', ''), ' ', '');
        
        INSERT INTO product_variants (
            product_id,
            title,  -- Add the required title column
            size,
            color,
            sku,
            price,
            inventory_quantity,
            created_at,
            updated_at
        ) VALUES (
            p_product_id,
            p_product_name || ' - Size ' || size,  -- Create descriptive title
            size,
            CASE 
                WHEN p_product_name ILIKE '%black%' THEN 'Black'
                WHEN p_product_name ILIKE '%navy%' THEN 'Navy'
                WHEN p_product_name ILIKE '%blue%' THEN 'Blue'
                WHEN p_product_name ILIKE '%royal%' THEN 'Royal Blue'
                WHEN p_product_name ILIKE '%grey%' OR p_product_name ILIKE '%gray%' THEN 'Grey'
                WHEN p_product_name ILIKE '%white%' THEN 'White'
                WHEN p_product_name ILIKE '%red%' THEN 'Red'
                WHEN p_product_name ILIKE '%pink%' THEN 'Pink'
                WHEN p_product_name ILIKE '%green%' THEN 'Green'
                WHEN p_product_name ILIKE '%purple%' THEN 'Purple'
                WHEN p_product_name ILIKE '%brown%' THEN 'Brown'
                WHEN p_product_name ILIKE '%gold%' THEN 'Gold'
                WHEN p_product_name ILIKE '%silver%' THEN 'Silver'
                WHEN p_product_name ILIKE '%beige%' THEN 'Beige'
                WHEN p_product_name ILIKE '%burgundy%' THEN 'Burgundy'
                WHEN p_product_name ILIKE '%coral%' THEN 'Coral'
                ELSE 'Standard'
            END,
            variant_sku,
            p_base_price,
            CASE 
                -- Popular sizes get more inventory
                WHEN size IN ('M', 'L', 'XL', '40R', '42R', '9', '10', '11') THEN 25
                WHEN size IN ('S', '2XL', '38R', '44R', '8', '8.5', '9.5', '10.5') THEN 20
                WHEN size IN ('5XL', '6XL') THEN 10
                ELSE 15
            END,
            NOW(),
            NOW()
        ) ON CONFLICT (sku) DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Helper function to create URL-safe handle
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Import Vest and Tie Sets (37 products)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    vest_data RECORD;
BEGIN
    FOR vest_data IN 
        SELECT * FROM (VALUES
            ('White Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg', 6500),
            ('Blush Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg', 6500),
            ('Pink Bubblegum Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg', 6500),
            ('Canary Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_canary-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Carolina Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Brown Chocolate Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_chocolate-brown-vest-and-tie-set_1.0.jpg', 6500),
            ('Cinnamon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_cinnamon-vest-and-tie-set_1.0.jpg', 6500),
            ('Coral Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_coral-vest-and-tie-set_1.0.jpg', 6500),
            ('Rose Dusty Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_dusty-rose-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Emerald Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Forest Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_forest-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue French Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_french-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Fuchsia Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_fuchsia-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Lettuce Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_lettuce-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Kiwi Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_kiwi-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Pink Light Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_light-pink-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Lime Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_lime-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Red Medium Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_medium-red-vest-and-tie-set_1.0.jpg', 6500),
            ('Mocha Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_mocha-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Mermaid Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_mermaid-green-vest-and-tie-set_1.0.jpg', 6500),
            ('White Off Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_off-white-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Powder Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_powder-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Rust Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_rust-vest-and-tie-set_1.0.jpg', 6500),
            ('Orange Salmon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_salmon-orange-vest-and-tie-set_1.0.jpg', 6500),
            ('Gold True Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-gold-vest-and-tie-set_1.0.jpg', 6500),
            ('Turquoise Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_turquoise-vest-and-tie-set_1.0.jpg', 6500),
            ('Burgundy Wine Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_wine-burgundy-vest-and-tie-set_1.0.jpg', 6500),
            ('Aqua Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_aqua-vest-and-tie-set_1.0.jpg', 6500),
            ('Red Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_red-vest-and-tie-set_1.0.jpg', 6500),
            ('Baby Blue Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_baby-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Yellow Chartreuse Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_chartreuse-yellow-vest-and-tie-set_1.0.jpg', 6500),
            ('Purple Deep Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_deep-purple-vest-and-tie-set_1.0.jpg', 6500),
            ('Magenta Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_magenta-vest-and-tie-set_1.0.jpg', 6500),
            ('Brown Medium Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-tie_medium-brown-vest-and-tie-set_1.0.jpg', 6500),
            ('Beige Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_beige-vest-and-tie-set_1.0.jpg', 6500),
            ('Plum Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_plum-vest-and-tie-set_1.0.jpg', 6500),
            ('Lavender Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_lavender-vest-and-tie-set_1.0.jpg', 6500)
        ) AS t(name, image_url, price_cents)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product with correct columns
        INSERT INTO products (
            id,
            sku,
            handle,
            name,
            description,
            base_price,        -- INTEGER (cents)
            category,
            status,
            primary_image,     -- Store URL here
            additional_info,   -- Use this for metadata
            featured,
            visibility,
            requires_shipping,
            taxable,
            track_inventory,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'VST-' || LPAD(product_counter::text, 4, '0'),
            create_handle(vest_data.name),
            vest_data.name,
            'Premium vest and tie set - Perfect for weddings, proms, and formal events',
            vest_data.price_cents,
            'Vest & Tie Sets',
            'active',
            vest_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'import_date', NOW()::text,
                'has_sizes', true
            ),
            false,
            true,
            true,
            true,
            true,
            NOW(),
            NOW()
        );
        
        -- Also add to product_images table for compatibility
        INSERT INTO product_images (
            id,
            product_id,
            image_url,
            image_type,
            position,
            alt_text,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            new_product_id,
            vest_data.image_url,
            'primary',
            1,
            vest_data.name,
            NOW(),
            NOW()
        );
        
        -- Create size variants
        PERFORM create_size_variants(
            new_product_id,
            vest_data.name,
            'Vest & Tie Sets',
            'VST-' || LPAD(product_counter::text, 4, '0'),
            vest_data.price_cents
        );
        
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Imported % vest sets', product_counter - 1;
END $$;

-- Import Suspender Sets (6 products, no sizes)
DO $$
DECLARE
    product_counter INT := 1;
    suspender_data RECORD;
    new_product_id UUID;
BEGIN
    FOR suspender_data IN
        SELECT * FROM (VALUES
            ('Grey Dark Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_dark-grey-suspender-bow-tie-set_1.0.jpg'),
            ('Blue Light Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_light-blue-suspender-bow-tie-set_1.0.jpg'),
            ('Red True Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-red-suspender-bow-tie-set_1.0.jpg'),
            ('Wine Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_wine-suspender-bow-tie-set_1.0.jpg'),
            ('Black Suspender Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg'),
            ('Purple Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_purple-suspender-bow-tie-set_1.0.jpg')
        ) AS t(name, image_url)
    LOOP
        new_product_id := gen_random_uuid();
        
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
            featured,
            visibility,
            requires_shipping,
            taxable,
            track_inventory,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'SUS-' || LPAD(product_counter::text, 4, '0'),
            create_handle(suspender_data.name),
            suspender_data.name,
            'Premium suspender and bow tie set for formal occasions',
            4500,  -- $45.00 in cents
            'Accessories',
            'active',
            suspender_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'import_date', NOW()::text,
                'has_sizes', false
            ),
            false,
            true,
            true,
            true,
            false,  -- No inventory tracking for accessories
            NOW(),
            NOW()
        );
        
        -- Add to product_images
        INSERT INTO product_images (
            id,
            product_id,
            image_url,
            image_type,
            position,
            alt_text,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            new_product_id,
            suspender_data.image_url,
            'primary',
            1,
            suspender_data.name,
            NOW(),
            NOW()
        );
        
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Imported % suspender sets', product_counter - 1;
END $$;

-- NOTE: Continue with more products...
-- This is a working template. Add more products following the same pattern.

-- Clean up temporary functions
DROP FUNCTION IF EXISTS create_size_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts and inventory
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id),
    in_stock = CASE 
        WHEN (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id) > 0 
        THEN (SELECT EXISTS(SELECT 1 FROM product_variants WHERE product_id = p.id AND inventory_quantity > 0))
        ELSE true
    END
WHERE p.additional_info->>'source' = 'csv_import';

-- Summary Report
SELECT 
    'Import Summary' as report,
    COUNT(*) as total_products,
    COUNT(*) FILTER (WHERE category = 'Vest & Tie Sets') as vest_sets,
    COUNT(*) FILTER (WHERE category = 'Accessories') as accessories,
    SUM(variant_count) as total_variants
FROM products
WHERE additional_info->>'source' = 'csv_import';

-- Show sample of imported products
SELECT 
    sku,
    name,
    category,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    in_stock,
    primary_image IS NOT NULL as has_image
FROM products
WHERE additional_info->>'source' = 'csv_import'
ORDER BY created_at DESC
LIMIT 10;

COMMIT;