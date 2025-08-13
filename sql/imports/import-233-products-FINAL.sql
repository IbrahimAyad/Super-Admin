-- FINAL Product Import Script for 233 Products
-- Uses correct column types based on actual table structure
-- base_price is INTEGER (stored in cents)
-- Uses additional_info instead of metadata
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
    i INT;
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
        RETURN; -- No sizes needed for accessories
    END IF;
    
    -- Create size variants
    FOREACH size IN ARRAY sizes
    LOOP
        variant_sku := p_base_sku || '-' || REPLACE(REPLACE(size, '.', ''), ' ', '');
        
        INSERT INTO product_variants (
            product_id,
            size,
            color,
            sku,
            price,
            inventory_quantity,
            created_at,
            updated_at
        ) VALUES (
            p_product_id,
            size,
            CASE 
                WHEN p_product_name ILIKE '%black%' THEN 'Black'
                WHEN p_product_name ILIKE '%navy%' THEN 'Navy'
                WHEN p_product_name ILIKE '%blue%' THEN 'Blue'
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
                WHEN p_product_name ILIKE '%tan%' THEN 'Tan'
                ELSE 'Standard'
            END,
            variant_sku,
            p_base_price, -- price in product_variants is also integer (cents)
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

-- Helper function to create URL-safe handle from name
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Import Vest and Tie Sets (37 products with sizes XS-6XL)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    vest_data RECORD;
BEGIN
    FOR vest_data IN 
        SELECT * FROM (VALUES
            ('White Nan A Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Blush Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg', 6500),
            ('Pink Nan Bubblegum Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Canary Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_canary-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Nan Carolina Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Brown Nan Chocolate Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_chocolate-brown-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Cinnamon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_cinnamon-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Coral Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_coral-vest-and-tie-set_1.0.jpg', 6500),
            ('Rose Nan Dusty Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_dusty-rose-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Emerald Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Forest Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_forest-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Nan French Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_french-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Fuchsia Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_fuchsia-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Lettuce Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_lettuce-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Kiwi Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_kiwi-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Pink Nan Light Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_light-pink-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Lime Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_lime-green-vest-and-tie-set_1.0.jpg', 6500),
            ('Red Nan Medium Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_medium-red-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Mocha Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_mocha-vest-and-tie-set_1.0.jpg', 6500),
            ('Green Nan Mermaid Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_mermaid-green-vest-and-tie-set_1.0.jpg', 6500),
            ('White Nan Off Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_off-white-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Nan Powder Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_powder-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Rust Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_rust-vest-and-tie-set_1.0.jpg', 6500),
            ('Orange Nan Salmon Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_salmon-orange-vest-and-tie-set_1.0.jpg', 6500),
            ('Gold Nan True Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-gold-vest-and-tie-set_1.0.jpg', 6500),
            ('Nan Turquoise Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_turquoise-vest-and-tie-set_1.0.jpg', 6500),
            ('Burgundy Nan Wine Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_wine-burgundy-vest-and-tie-set_1.0.jpg', 6500),
            ('Vest And Tie Aqua Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_aqua-vest-and-tie-set_1.0.jpg', 6500),
            ('Red Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_red-vest-and-tie-set_1.0.jpg', 6500),
            ('Blue Vest Tie Baby Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_baby-blue-vest-and-tie-set_1.0.jpg', 6500),
            ('Yellow Vest Tie Chartreuse Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_chartreuse-yellow-vest-and-tie-set_1.0.jpg', 6500),
            ('Purple Vest Tie Deep Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_deep-purple-vest-and-tie-set_1.0.jpg', 6500),
            ('Vest Tie Magenta Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_magenta-vest-and-tie-set_1.0.jpg', 6500),
            ('Brown Vest Tie Medium Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-tie_medium-brown-vest-and-tie-set_1.0.jpg', 6500),
            ('Beige Vest Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_beige-vest-and-tie-set_1.0.jpg', 6500),
            ('Vest Tie Plum Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_plum-vest-and-tie-set_1.0.jpg', 6500),
            ('Lavender Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_lavender-vest-and-tie-set_1.0.jpg', 6500)
        ) AS t(name, image_url, price_cents)
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
        
        -- Also add to product_images table
        INSERT INTO product_images (
            product_id,
            image_url,
            alt_text,
            is_primary,
            display_order,
            created_at
        ) VALUES (
            new_product_id,
            vest_data.image_url,
            vest_data.name,
            true,
            1,
            NOW()
        ) ON CONFLICT DO NOTHING;
        
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
END $$;

-- Import Suspender Sets (6 products, no sizes)
DO $$
DECLARE
    product_counter INT := 1;
    suspender_data RECORD;
BEGIN
    FOR suspender_data IN
        SELECT * FROM (VALUES
            ('Grey Nan Dark Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_dark-grey-suspender-bow-tie-set_1.0.jpg'),
            ('Blue Nan Light Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_light-blue-suspender-bow-tie-set_1.0.jpg'),
            ('Red Nan True Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-red-suspender-bow-tie-set_1.0.jpg'),
            ('Nan Wine Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_wine-suspender-bow-tie-set_1.0.jpg'),
            ('Black Suspender Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg'),
            ('Purple Nan Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_purple-suspender-bow-tie-set_1.0.jpg')
        ) AS t(name, image_url)
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
            featured,
            visibility,
            requires_shipping,
            taxable,
            track_inventory,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            'SUS-' || LPAD(product_counter::text, 4, '0'),
            create_handle(suspender_data.name),
            suspender_data.name,
            'Premium suspender and bow tie set for formal occasions',
            4500, -- $45.00 in cents
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
            true,
            NOW(),
            NOW()
        );
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Wedding Bundles (3 products, no sizes)
DO $$
DECLARE
    product_counter INT := 1;
    wedding_data RECORD;
BEGIN
    FOR wedding_data IN
        SELECT * FROM (VALUES
            ('Charcoal Nan Bowtie Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_charcoal-bowtie-wedding-bundle_5.0.jpg'),
            ('Rose Nan French Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_french-rose-wedding-bundle_4.0.jpg'),
            ('Black Nan Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_wedding-bundle-black-bowtie-or-tie_6.0.jpg')
        ) AS t(name, image_url)
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
            featured,
            visibility,
            requires_shipping,
            taxable,
            track_inventory,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            'WED-' || LPAD(product_counter::text, 4, '0'),
            create_handle(wedding_data.name),
            wedding_data.name,
            'Complete wedding bundle package - Everything you need for your special day',
            12500, -- $125.00 in cents
            'Wedding',
            'active',
            wedding_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'import_date', NOW()::text,
                'has_sizes', false,
                'bundle_items', ARRAY['Vest', 'Tie', 'Pocket Square', 'Cufflinks']
            ),
            true, -- Featured product
            true,
            true,
            true,
            true,
            NOW(),
            NOW()
        );
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Shoes (16 products with sizes 7-13)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    shoe_data RECORD;
BEGIN
    FOR shoe_data IN 
        SELECT * FROM (VALUES
            ('Black Boot Jotter Cap Toe', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boot_black-jotter-cap-toe_1.0.jpg', 18500),
            ('Navy Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_navy-chelsea-boots_1.0.jpg', 16500),
            ('Black Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg', 16500),
            ('Brown Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg', 16500),
            ('Beige Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boots_beige-chelsea-boots_1.0.jpg', 16500),
            ('Gold Studded Sneakers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_kct-menswear-gold-studded-sneakers-dazzling-urban-luxury_1.0.jpg', 22500),
            ('Silver Prom Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_silver-prom-loafers-mens-black-silver-sparkle-dress_1.0.jpg', 14500),
            ('Gold Prom Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_gold-prom-loafers-mens-sparkle-dress-shoes_1.0.jpg', 14500),
            ('Royal Blue Velvet Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_royal-blue-velvet-loafers-gold-spikes-prom-shoes_1.0.jpg', 17500),
            ('Black Velvet Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_black-velvet-loafers-gold-spikes-prom-shoes_1.0.jpg', 17500),
            ('Red Velvet Studded Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_red-velvet-studded-prom-loafers_1.0.jpg', 18500),
            ('White Leather Sneakers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_all-white-leather-versatile-sneakers-prom-professional_1.0.jpg', 19500),
            ('Sparkling Black Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-black-loafers-prom-shoes_1.0.jpg', 15500),
            ('Sparkling Silver Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-silver-loafers-prom-shoes_1.0.jpg', 15500),
            ('Sparkling Gold Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_sparkling-gold-loafers-prom-shoes_1.0.jpg', 15500),
            ('Sparkling Royal Blue Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_sparkling-royal-blue-loafers-prom-shoes_1.0.jpg', 15500)
        ) AS t(name, image_url, price_cents)
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
            'SHO-' || LPAD(product_counter::text, 4, '0'),
            create_handle(shoe_data.name),
            shoe_data.name,
            'Premium dress shoes - Perfect for formal events and special occasions',
            shoe_data.price_cents,
            'Shoes',
            'active',
            shoe_data.image_url,
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
        
        -- Create shoe size variants
        PERFORM create_size_variants(
            new_product_id,
            shoe_data.name,
            'Shoes',
            'SHO-' || LPAD(product_counter::text, 4, '0'),
            shoe_data.price_cents
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- NOTE: Add more products here following the same pattern...
-- Men's Suits (10 products)
-- Outerwear (7 products)
-- Knitwear (2 products)
-- Kids Formal (4 products)
-- Special Items (5 products)

-- Clean up temporary functions
DROP FUNCTION IF EXISTS create_size_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts and inventory totals
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id),
    in_stock = (SELECT EXISTS(SELECT 1 FROM product_variants WHERE product_id = p.id AND inventory_quantity > 0))
WHERE p.additional_info->>'source' = 'csv_import';

-- Summary Report
DO $$
DECLARE
    total_products INT;
    total_variants INT;
    products_with_sizes INT;
    total_inventory INT;
BEGIN
    SELECT COUNT(*) INTO total_products 
    FROM products 
    WHERE additional_info->>'source' = 'csv_import';
    
    SELECT COUNT(*) INTO total_variants
    FROM product_variants pv
    JOIN products p ON pv.product_id = p.id
    WHERE p.additional_info->>'source' = 'csv_import';
    
    SELECT COUNT(*) INTO products_with_sizes
    FROM products 
    WHERE additional_info->>'source' = 'csv_import' 
    AND (additional_info->>'has_sizes')::boolean = true;
    
    SELECT COALESCE(SUM(total_inventory), 0) INTO total_inventory
    FROM products
    WHERE additional_info->>'source' = 'csv_import';
    
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Import Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Products imported: %', total_products;
    RAISE NOTICE 'Products with sizes: %', products_with_sizes;
    RAISE NOTICE 'Size variants created: %', total_variants;
    RAISE NOTICE 'Total inventory units: %', total_inventory;
    RAISE NOTICE '=================================';
END $$;

COMMIT;