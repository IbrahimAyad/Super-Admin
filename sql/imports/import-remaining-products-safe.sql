-- Safe Import Script - Skips existing products
-- Only imports products that don't already exist

BEGIN;

-- Helper function to create URL-safe handle
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Helper function to create size variants
CREATE OR REPLACE FUNCTION create_size_variants(
    p_product_id UUID,
    p_product_name TEXT,
    p_category TEXT,
    p_base_sku TEXT,
    p_base_price INTEGER,
    p_color TEXT
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
        
        -- Skip if variant already exists
        IF NOT EXISTS (SELECT 1 FROM product_variants WHERE sku = variant_sku) THEN
            INSERT INTO product_variants (
                product_id,
                title,
                option1,  -- size
                option2,  -- color
                sku,
                price,
                inventory_quantity,
                created_at,
                updated_at
            ) VALUES (
                p_product_id,
                p_product_name || ' - Size ' || size,
                size,
                p_color,
                variant_sku,
                p_base_price,
                CASE 
                    WHEN size IN ('M', 'L', 'XL', '40R', '42R', '9', '10', '11') THEN 25
                    WHEN size IN ('S', '2XL', '38R', '44R', '8', '8.5', '9.5', '10.5') THEN 20
                    WHEN size IN ('5XL', '6XL') THEN 10
                    ELSE 15
                END,
                NOW(),
                NOW()
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Import REMAINING Vest and Tie Sets (skip existing ones)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT;
    vest_data RECORD;
    existing_handle TEXT;
BEGIN
    -- Get starting counter based on existing products
    SELECT COALESCE(MAX(SUBSTRING(sku FROM 5)::INT), 0) + 1 
    INTO product_counter
    FROM products 
    WHERE sku LIKE 'VST-%';
    
    FOR vest_data IN 
        SELECT * FROM (VALUES
            -- Skip the 3 already imported, add the rest
            ('Pink Bubblegum Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg', 6500, 'Pink'),
            ('Canary Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_canary-vest-and-tie-set_1.0.jpg', 6500, 'Canary'),
            ('Brown Chocolate Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_chocolate-brown-vest-and-tie-set_1.0.jpg', 6500, 'Chocolate Brown'),
            ('Cinnamon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_cinnamon-vest-and-tie-set_1.0.jpg', 6500, 'Cinnamon'),
            ('Coral Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_coral-vest-and-tie-set_1.0.jpg', 6500, 'Coral'),
            ('Rose Dusty Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_dusty-rose-vest-and-tie-set_1.0.jpg', 6500, 'Dusty Rose'),
            ('Green Emerald Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg', 6500, 'Emerald Green'),
            ('Green Forest Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_forest-green-vest-and-tie-set_1.0.jpg', 6500, 'Forest Green'),
            ('Blue French Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_french-blue-vest-and-tie-set_1.0.jpg', 6500, 'French Blue'),
            ('Fuchsia Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_fuchsia-vest-and-tie-set_1.0.jpg', 6500, 'Fuchsia'),
            ('Green Lettuce Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_lettuce-green-vest-and-tie-set_1.0.jpg', 6500, 'Lettuce Green'),
            ('Green Kiwi Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_kiwi-green-vest-and-tie-set_1.0.jpg', 6500, 'Kiwi Green'),
            ('Pink Light Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_light-pink-vest-and-tie-set_1.0.jpg', 6500, 'Light Pink'),
            ('Green Lime Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_lime-green-vest-and-tie-set_1.0.jpg', 6500, 'Lime Green'),
            ('Red Medium Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_medium-red-vest-and-tie-set_1.0.jpg', 6500, 'Medium Red'),
            ('Mocha Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_mocha-vest-and-tie-set_1.0.jpg', 6500, 'Mocha'),
            ('Green Mermaid Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_mermaid-green-vest-and-tie-set_1.0.jpg', 6500, 'Mermaid Green'),
            ('White Off Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_off-white-vest-and-tie-set_1.0.jpg', 6500, 'Off White'),
            ('Blue Powder Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_powder-blue-vest-and-tie-set_1.0.jpg', 6500, 'Powder Blue'),
            ('Rust Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_rust-vest-and-tie-set_1.0.jpg', 6500, 'Rust'),
            ('Orange Salmon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_salmon-orange-vest-and-tie-set_1.0.jpg', 6500, 'Salmon Orange'),
            ('Gold True Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-gold-vest-and-tie-set_1.0.jpg', 6500, 'True Gold'),
            ('Turquoise Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_turquoise-vest-and-tie-set_1.0.jpg', 6500, 'Turquoise'),
            ('Burgundy Wine Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_wine-burgundy-vest-and-tie-set_1.0.jpg', 6500, 'Wine Burgundy'),
            ('Aqua Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_aqua-vest-and-tie-set_1.0.jpg', 6500, 'Aqua'),
            ('Red Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_red-vest-and-tie-set_1.0.jpg', 6500, 'Red'),
            ('Baby Blue Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_baby-blue-vest-and-tie-set_1.0.jpg', 6500, 'Baby Blue'),
            ('Yellow Chartreuse Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_chartreuse-yellow-vest-and-tie-set_1.0.jpg', 6500, 'Chartreuse Yellow'),
            ('Purple Deep Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_deep-purple-vest-and-tie-set_1.0.jpg', 6500, 'Deep Purple'),
            ('Magenta Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_magenta-vest-and-tie-set_1.0.jpg', 6500, 'Magenta'),
            ('Brown Medium Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-tie_medium-brown-vest-and-tie-set_1.0.jpg', 6500, 'Medium Brown'),
            ('Beige Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_beige-vest-and-tie-set_1.0.jpg', 6500, 'Beige'),
            ('Plum Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_plum-vest-and-tie-set_1.0.jpg', 6500, 'Plum'),
            ('Lavender Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_lavender-vest-and-tie-set_1.0.jpg', 6500, 'Lavender')
        ) AS t(name, image_url, price_cents, color)
    LOOP
        -- Check if product already exists by handle
        existing_handle := create_handle(vest_data.name);
        
        IF NOT EXISTS (SELECT 1 FROM products WHERE handle = existing_handle) THEN
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
                existing_handle,
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
            
            -- Add to product_images table
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
                vest_data.price_cents,
                vest_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', vest_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', vest_data.name;
        END IF;
    END LOOP;
END $$;

-- Import remaining Suspender Sets (skip existing)
DO $$
DECLARE
    product_counter INT;
    suspender_data RECORD;
    new_product_id UUID;
    existing_handle TEXT;
BEGIN
    -- Get starting counter
    SELECT COALESCE(MAX(SUBSTRING(sku FROM 5)::INT), 0) + 1 
    INTO product_counter
    FROM products 
    WHERE sku LIKE 'SUS-%';
    
    FOR suspender_data IN
        SELECT * FROM (VALUES
            ('Grey Dark Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_dark-grey-suspender-bow-tie-set_1.0.jpg'),
            ('Blue Light Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_light-blue-suspender-bow-tie-set_1.0.jpg'),
            ('Red True Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-red-suspender-bow-tie-set_1.0.jpg'),
            ('Wine Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_wine-suspender-bow-tie-set_1.0.jpg'),
            ('Purple Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_purple-suspender-bow-tie-set_1.0.jpg')
        ) AS t(name, image_url)
    LOOP
        existing_handle := create_handle(suspender_data.name);
        
        IF NOT EXISTS (SELECT 1 FROM products WHERE handle = existing_handle) THEN
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
                existing_handle,
                suspender_data.name,
                'Premium suspender and bow tie set for formal occasions',
                4500,
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
                false,
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
            RAISE NOTICE 'Imported: %', suspender_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', suspender_data.name;
        END IF;
    END LOOP;
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_size_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts
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
    COUNT(*) FILTER (WHERE category = 'Shoes') as shoes,
    SUM(variant_count) as total_variants
FROM products
WHERE additional_info->>'source' IN ('csv_import', 'csv_import_test');

-- Show newly imported products
SELECT 
    sku,
    name,
    category,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    primary_image IS NOT NULL as has_image
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC;

COMMIT;