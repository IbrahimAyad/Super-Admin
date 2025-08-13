-- Enhanced Product Import Script with Size Variants (FIXED)
-- This script imports products from CSV files and creates size variants where appropriate
-- Fixed: Using base_price instead of price for products table
-- Generated: 2025-08-12

BEGIN;

-- Create temporary function to generate size variants
CREATE OR REPLACE FUNCTION create_size_variants(
    p_product_id UUID,
    p_product_name TEXT,
    p_category TEXT,
    p_base_sku TEXT,
    p_base_price DECIMAL
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
    ELSIF p_product_name ILIKE '%vest%and%tie%' OR p_product_name ILIKE '%vest%tie%' THEN
        sizes := ARRAY['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL'];
    ELSIF p_product_name ILIKE '%kid%' THEN
        sizes := ARRAY['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14', '16'];
    ELSE
        -- No sizes needed
        RETURN;
    END IF;
    
    -- Create size variants
    i := 1;
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
                WHEN p_product_name ILIKE '%blue%' THEN 'Blue'
                WHEN p_product_name ILIKE '%navy%' THEN 'Navy'
                WHEN p_product_name ILIKE '%grey%' OR p_product_name ILIKE '%gray%' THEN 'Grey'
                WHEN p_product_name ILIKE '%white%' THEN 'White'
                WHEN p_product_name ILIKE '%red%' THEN 'Red'
                WHEN p_product_name ILIKE '%pink%' THEN 'Pink'
                WHEN p_product_name ILIKE '%green%' THEN 'Green'
                WHEN p_product_name ILIKE '%purple%' THEN 'Purple'
                WHEN p_product_name ILIKE '%brown%' THEN 'Brown'
                WHEN p_product_name ILIKE '%gold%' THEN 'Gold'
                WHEN p_product_name ILIKE '%silver%' THEN 'Silver'
                WHEN p_product_name ILIKE '%yellow%' THEN 'Yellow'
                WHEN p_product_name ILIKE '%orange%' THEN 'Orange'
                WHEN p_product_name ILIKE '%burgundy%' THEN 'Burgundy'
                WHEN p_product_name ILIKE '%coral%' THEN 'Coral'
                WHEN p_product_name ILIKE '%turquoise%' THEN 'Turquoise'
                WHEN p_product_name ILIKE '%lavender%' THEN 'Lavender'
                WHEN p_product_name ILIKE '%beige%' THEN 'Beige'
                WHEN p_product_name ILIKE '%tan%' THEN 'Tan'
                ELSE 'Standard'
            END,
            variant_sku,
            p_base_price,
            CASE 
                -- Popular sizes get more inventory
                WHEN size IN ('M', 'L', 'XL', '40R', '42R', '9', '10', '11') THEN 25
                WHEN size IN ('S', '2XL', '38R', '44R', '8', '8.5', '9.5', '10.5') THEN 20
                WHEN size IN ('5XL', '6XL') THEN 10  -- Lower inventory for extended sizes
                ELSE 15
            END,
            NOW(),
            NOW()
        ) ON CONFLICT (sku) DO NOTHING;
        
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Skip individual ties/bowties (only 2 of them)
-- Creating products that need sizes

-- Import Vest and Tie Sets with sizes
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    vest_data RECORD;
BEGIN
    FOR vest_data IN 
        SELECT * FROM (VALUES
            ('White Nan A Vest And Tie Set', 'nan-a-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg'),
            ('Nan Blush Vest And Tie Set', 'nan-blush-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg'),
            ('Pink Nan Bubblegum Vest And Tie Set', 'nan-bubblegum-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg'),
            ('Nan Canary Vest And Tie Set', 'nan-canary-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_canary-vest-and-tie-set_1.0.jpg'),
            ('Blue Nan Carolina Vest And Tie Set', 'nan-carolina-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg'),
            ('Brown Nan Chocolate Vest And Tie Set', 'nan-chocolate-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_chocolate-brown-vest-and-tie-set_1.0.jpg'),
            ('Nan Cinnamon Vest And Tie Set', 'nan-cinnamon-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_cinnamon-vest-and-tie-set_1.0.jpg'),
            ('Nan Coral Vest And Tie Set', 'nan-coral-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_coral-vest-and-tie-set_1.0.jpg'),
            ('Rose Nan Dusty Vest And Tie Set', 'nan-dusty-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_dusty-rose-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Emerald Vest And Tie Set', 'nan-emerald-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Forest Vest And Tie Set', 'nan-forest-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_forest-green-vest-and-tie-set_1.0.jpg'),
            ('Blue Nan French Vest And Tie Set', 'nan-french-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_french-blue-vest-and-tie-set_1.0.jpg'),
            ('Nan Fuchsia Vest And Tie Set', 'nan-fuchsia-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_fuchsia-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Lettuce Vest And Tie Set', 'nan-lettuce-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_lettuce-green-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Kiwi Vest And Tie Set', 'nan-kiwi-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_kiwi-green-vest-and-tie-set_1.0.jpg'),
            ('Pink Nan Light Vest And Tie Set', 'nan-light-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_light-pink-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Lime Vest And Tie Set', 'nan-lime-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_lime-green-vest-and-tie-set_1.0.jpg'),
            ('Red Nan Medium Vest And Tie Set', 'nan-medium-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_medium-red-vest-and-tie-set_1.0.jpg'),
            ('Nan Mocha Vest And Tie Set', 'nan-mocha-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_mocha-vest-and-tie-set_1.0.jpg'),
            ('Green Nan Mermaid Vest And Tie Set', 'nan-mermaid-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_mermaid-green-vest-and-tie-set_1.0.jpg'),
            ('White Nan Off Vest And Tie Set', 'nan-off-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_off-white-vest-and-tie-set_1.0.jpg'),
            ('Blue Nan Powder Vest And Tie Set', 'nan-powder-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_powder-blue-vest-and-tie-set_1.0.jpg'),
            ('Nan Rust Vest And Tie Set', 'nan-rust-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_rust-vest-and-tie-set_1.0.jpg'),
            ('Orange Nan Salmon Vest And Tie Set', 'nan-salmon-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_salmon-orange-vest-and-tie-set_1.0.jpg'),
            ('Gold Nan True Vest And Tie Set', 'nan-true-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-gold-vest-and-tie-set_1.0.jpg'),
            ('Nan Turquoise Vest And Tie Set', 'nan-turquoise-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_turquoise-vest-and-tie-set_1.0.jpg'),
            ('Burgundy Nan Wine Vest And Tie Set', 'nan-wine-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_wine-burgundy-vest-and-tie-set_1.0.jpg'),
            ('Vest And Tie Aqua Set', 'vest-and-tie-aqua-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_aqua-vest-and-tie-set_1.0.jpg'),
            ('Red Vest And Tie Set', 'vest-and-tie-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-and-tie_red-vest-and-tie-set_1.0.jpg'),
            ('Blue Vest Tie Baby Set', 'vest-tie-baby-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_baby-blue-vest-and-tie-set_1.0.jpg'),
            ('Yellow Vest Tie Chartreuse Set', 'vest-tie-chartreuse-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_chartreuse-yellow-vest-and-tie-set_1.0.jpg'),
            ('Purple Vest Tie Deep Set', 'vest-tie-deep-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_deep-purple-vest-and-tie-set_1.0.jpg'),
            ('Vest Tie Magenta Set', 'vest-tie-magenta-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest-tie_magenta-vest-and-tie-set_1.0.jpg'),
            ('Brown Vest Tie Medium Set', 'vest-tie-medium-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/vest-tie_medium-brown-vest-and-tie-set_1.0.jpg'),
            ('Beige Vest Tie Set', 'vest-tie-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_beige-vest-and-tie-set_1.0.jpg'),
            ('Vest Tie Plum Set', 'vest-tie-plum-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/vest-tie_plum-vest-and-tie-set_1.0.jpg')
        ) AS t(name, slug, image_url)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,  -- Changed from price to base_price
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'VST-CSV-' || LPAD(product_counter::text, 4, '0'),
            vest_data.name,
            'Premium vest and tie set - ' || vest_data.name,
            65.00,
            'Vest & Tie Sets',
            'active',
            vest_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', vest_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create size variants for vest sets
        PERFORM create_size_variants(
            new_product_id,
            vest_data.name,
            'Vest & Tie Sets',
            'VST-CSV-' || LPAD(product_counter::text, 4, '0'),
            65.00
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Suspender Sets (no sizes needed)
INSERT INTO products (sku, name, description, base_price, category, status, image_url, metadata)
SELECT 
    'SUS-CSV-' || LPAD(row_number() OVER()::text, 4, '0'),
    name,
    'Premium suspender and bow tie set',
    45.00,
    'Accessories',
    'active',
    image_url,
    jsonb_build_object('source', 'csv_import', 'has_sizes', false)
FROM (VALUES
    ('Grey Nan Dark Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_dark-grey-suspender-bow-tie-set_1.0.jpg'),
    ('Blue Nan Light Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_light-blue-suspender-bow-tie-set_1.0.jpg'),
    ('Red Nan True Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-red-suspender-bow-tie-set_1.0.jpg'),
    ('Nan Wine Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_wine-suspender-bow-tie-set_1.0.jpg'),
    ('Black Suspender Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg'),
    ('Purple Nan Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_purple-suspender-bow-tie-set_1.0.jpg')
) AS t(name, image_url);

-- Import Wedding Bundles (no sizes needed)
INSERT INTO products (sku, name, description, base_price, category, status, image_url, metadata)
SELECT 
    'WED-CSV-' || LPAD(row_number() OVER()::text, 4, '0'),
    name,
    'Complete wedding bundle package',
    125.00,
    'Accessories',
    'active',
    image_url,
    jsonb_build_object('source', 'csv_import', 'has_sizes', false)
FROM (VALUES
    ('Charcoal Nan Bowtie Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_charcoal-bowtie-wedding-bundle_5.0.jpg'),
    ('Rose Nan French Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_french-rose-wedding-bundle_4.0.jpg'),
    ('Black Nan Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_wedding-bundle-black-bowtie-or-tie_6.0.jpg')
) AS t(name, image_url);

-- Import Shoes with sizes
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    shoe_data RECORD;
BEGIN
    FOR shoe_data IN 
        SELECT * FROM (VALUES
            ('Black Boot Jotter Cap Toe', 'boot-jotter-cap-toe', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boot_black-jotter-cap-toe_1.0.jpg', 185.00),
            ('Navy Chelsea Boots', 'boots-chelsea-boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_navy-chelsea-boots_1.0.jpg', 165.00),
            ('Black Chelsea Boots', 'boots-chelsea-boots-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg', 165.00),
            ('Brown Chelsea Boots', 'boots-chelsea-boots-brown', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg', 165.00),
            ('Beige Chelsea Boots', 'boots-chelsea-boots-beige', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boots_beige-chelsea-boots_1.0.jpg', 165.00),
            ('Gold Studded Sneakers', 'dress-shoe-studded-sneakers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_kct-menswear-gold-studded-sneakers-dazzling-urban-luxury_1.0.jpg', 225.00),
            ('Silver Prom Loafers', 'dress-shoe-prom-loafers-silver', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_silver-prom-loafers-mens-black-silver-sparkle-dress_1.0.jpg', 145.00),
            ('Gold Prom Loafers', 'dress-shoe-prom-loafers-gold', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_gold-prom-loafers-mens-sparkle-dress-shoes_1.0.jpg', 145.00),
            ('Royal Blue Velvet Loafers', 'dress-shoe-velvet-loafers-royal', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_royal-blue-velvet-loafers-gold-spikes-prom-shoes_1.0.jpg', 175.00),
            ('Black Velvet Loafers', 'dress-shoe-velvet-loafers-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_black-velvet-loafers-gold-spikes-prom-shoes_1.0.jpg', 175.00),
            ('Red Velvet Studded Loafers', 'dress-shoe-velvet-studded', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_red-velvet-studded-prom-loafers_1.0.jpg', 185.00),
            ('White Leather Sneakers', 'dress-shoe-white-leather', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_all-white-leather-versatile-sneakers-prom-professional_1.0.jpg', 195.00),
            ('Sparkling Black Loafers', 'dress-shoe-sparkling-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-black-loafers-prom-shoes_1.0.jpg', 155.00),
            ('Sparkling Silver Loafers', 'dress-shoe-sparkling-silver', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-silver-loafers-prom-shoes_1.0.jpg', 155.00),
            ('Sparkling Gold Loafers', 'dress-shoe-sparkling-gold', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_sparkling-gold-loafers-prom-shoes_1.0.jpg', 155.00),
            ('Sparkling Royal Blue Loafers', 'dress-shoe-sparkling-royal', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_sparkling-royal-blue-loafers-prom-shoes_1.0.jpg', 155.00)
        ) AS t(name, slug, image_url, base_price)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'SHO-CSV-' || LPAD(product_counter::text, 4, '0'),
            shoe_data.name,
            'Premium dress shoes - ' || shoe_data.name,
            shoe_data.base_price,
            'Shoes',
            'active',
            shoe_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', shoe_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create shoe size variants
        PERFORM create_size_variants(
            new_product_id,
            shoe_data.name,
            'Shoes',
            'SHO-CSV-' || LPAD(product_counter::text, 4, '0'),
            shoe_data.base_price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Men's Suits with sizes (sample - add more as needed)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    suit_data RECORD;
BEGIN
    FOR suit_data IN 
        SELECT * FROM (VALUES
            ('Classic Black Three Piece Tuxedo', 'mens-tuxedos-classic-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-classic-black-three-piece-tuxedo-with-satin-shawl-lapel_1.0.png', 395.00),
            ('Midnight Blue Tuxedo', 'mens-blazers-midnight-blue', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-midnight-blue-tuxedo-with-black-satin-shawl-lapel_1.0.jpg', 375.00),
            ('Navy Blue Slim Fit Tuxedo', 'mens-blazers-navy-blue', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_mens-slim-fit-navy-blue-tuxedo-with-satin-shawl-lapel-1_1.0.jpg', 365.00),
            ('Light Grey Tuxedo', 'mens-blazers-light-grey', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-light-grey-tuxedo-with-satin-shawl-lapel_1.0.jpg', 365.00),
            ('Classic Brown Check Double Breasted Suit', 'mens-double-breasted-brown', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-double-breasted-suit_classic-brown-check-double-breasted-suit-the-connoisseurs-choice_1.0.jpg', 425.00),
            ('Classic Gray Double Breasted Suit', 'mens-double-breasted-gray', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_classic-gray-double-breasted-suit-ensemble_1.0.jpg', 395.00),
            ('Lavender Dream Double Breasted Suit', 'mens-double-breasted-lavender', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_lavender-dream-double-breasted-suit-set_1.0.jpg', 415.00),
            ('Ocean Blue Textured Double Breasted Suit', 'mens-double-breasted-ocean', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-double-breasted-suit_ocean-blue-textured-double-breasted-suit-a-splash-of-style_1.0.jpg', 435.00),
            ('Grey Tweed Three Piece Suit', 'mens-suits-grey-tweed', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-suits_mens-slim-fit-grey-tweed-three-piece-suit_1.0.png', 385.00),
            ('Light Grey Three Piece Suit', 'mens-suits-light-grey', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_mens-slim-fit-light-grey-three-piece-suit_1.0.png', 365.00)
        ) AS t(name, slug, image_url, base_price)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'SUT-CSV-' || LPAD(product_counter::text, 4, '0'),
            suit_data.name,
            'Premium men''s suit - ' || suit_data.name,
            suit_data.base_price,
            'Men''s Suits',
            'active',
            suit_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', suit_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create suit size variants
        PERFORM create_size_variants(
            new_product_id,
            suit_data.name,
            'Men''s Suits',
            'SUT-CSV-' || LPAD(product_counter::text, 4, '0'),
            suit_data.base_price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Outerwear (Jackets) with sizes
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    jacket_data RECORD;
BEGIN
    FOR jacket_data IN 
        SELECT * FROM (VALUES
            ('Black Puffer Jacket', 'jacket-puffer-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/jacket_black-puffer-jacket_1.0.jpg', 225.00),
            ('Grey Puffer Jacket', 'jacket-puffer-grey', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/jacket_grey-puffer-jacket_1.0.jpg', 225.00),
            ('Tan Puffer Jacket', 'jacket-puffer-tan', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/jacket_tan-puffer-jacket_1.0.jpg', 225.00),
            ('Camel Puffer Jacket', 'jacket-puffer-camel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/jacket_camel-puffer-jacket_1.0.jpg', 225.00),
            ('Black Modern Jacket', 'jacket-modern-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/jacket_black-modern-jacket_1.0.jpg', 195.00),
            ('Grey Sherpa Puffer', 'jacket-sherpa-grey', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/jacket_grey-sherpa-puffer_1.0.jpg', 245.00),
            ('Camel Sherpa Puffer', 'jacket-sherpa-camel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/jacket_camel-sherpa-puffer_1.0.jpg', 245.00)
        ) AS t(name, slug, image_url, base_price)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'OUT-CSV-' || LPAD(product_counter::text, 4, '0'),
            jacket_data.name,
            'Premium outerwear - ' || jacket_data.name,
            jacket_data.base_price,
            'Outerwear',
            'active',
            jacket_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', jacket_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create jacket size variants
        PERFORM create_size_variants(
            new_product_id,
            jacket_data.name,
            'Outerwear',
            'OUT-CSV-' || LPAD(product_counter::text, 4, '0'),
            jacket_data.base_price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Knitwear (Sweaters) with S-4XL sizes
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    sweater_data RECORD;
BEGIN
    FOR sweater_data IN 
        SELECT * FROM (VALUES
            ('White and Grey Heavy Sweater', 'mens-sweaters-white-grey', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-sweaters_white-and-grey-heavy-sweater_1.0.jpg', 125.00),
            ('Black White Multi-Pattern Knit Sweater', 'mens-sweaters-multi-pattern', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-sweaters_mens-black-white-heavyweight-multi-pattern-knit-sweater_1.0.jpg', 145.00)
        ) AS t(name, slug, image_url, base_price)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'KNT-CSV-' || LPAD(product_counter::text, 4, '0'),
            sweater_data.name,
            'Premium knitwear - ' || sweater_data.name,
            sweater_data.base_price,
            'Knitwear',
            'active',
            sweater_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', sweater_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create sweater size variants (S-4XL)
        PERFORM create_size_variants(
            new_product_id,
            sweater_data.name,
            'Knitwear',
            'KNT-CSV-' || LPAD(product_counter::text, 4, '0'),
            sweater_data.base_price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Kids Suits with kids sizes
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    kids_data RECORD;
BEGIN
    FOR kids_data IN 
        SELECT * FROM (VALUES
            ('Black Kids Suit', 'kid-suit-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-suit_black-kids-suit_1.0.jpg', 145.00),
            ('Royal Blue Kids Suit', 'kid-suit-royal-blue', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-suit_royal-blue-kids-suit_1.0.jpg', 145.00),
            ('Black Kids Tux', 'kid-tux-black', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-tux_black-kids-tux_1.0.jpg', 165.00),
            ('Royal Blue Kids Tux', 'kid-tux-royal-blue', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/kid-tux_royal-blue-kids-tux_1.0.jpg', 165.00)
        ) AS t(name, slug, image_url, base_price)
    LOOP
        new_product_id := gen_random_uuid();
        
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            image_url,
            metadata,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'KID-CSV-' || LPAD(product_counter::text, 4, '0'),
            kids_data.name,
            'Premium kids formal wear - ' || kids_data.name,
            kids_data.base_price,
            'Kids Formal',
            'active',
            kids_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', kids_data.slug,
                'has_sizes', true
            ),
            NOW(),
            NOW()
        );
        
        -- Create kids size variants
        PERFORM create_size_variants(
            new_product_id,
            kids_data.name,
            'Kids Formal',
            'KID-CSV-' || LPAD(product_counter::text, 4, '0'),
            kids_data.base_price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
END $$;

-- Import Sparkle/Special Items (no sizes for most accessories)
INSERT INTO products (sku, name, description, base_price, category, status, image_url, metadata)
SELECT 
    'SPE-CSV-' || LPAD(row_number() OVER()::text, 4, '0'),
    name,
    'Premium special occasion item',
    85.00,
    'Accessories',
    'active',
    image_url,
    jsonb_build_object('source', 'csv_import', 'has_sizes', false)
FROM (VALUES
    ('Royal Blue Sparkle Vest And Bowtie', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/sparkle-vest-and-tie_royal-blue-sparkle-vest-and-bowtie_1.0.jpg'),
    ('Red Sparkle Vest And Bowtie', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/sparkle-vest-and-tie_red-sparkle-vest-and-bowtie_1.0.jpg'),
    ('Red Cummerbund Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_red-cummerbund-set_1.0.jpg'),
    ('Black Cummerbund Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_black-cummerbund-set_1.0.jpg'),
    ('Royal Blue Cummerbund Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/cummerband_royal-blue-cummerbund-set_1.0.jpg')
) AS t(name, image_url);

-- Clean up temporary function
DROP FUNCTION IF EXISTS create_size_variants;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_csv_import ON products((metadata->>'source')) WHERE metadata->>'source' = 'csv_import';
CREATE INDEX IF NOT EXISTS idx_product_variants_csv ON product_variants(sku) WHERE sku LIKE '%-CSV-%';

-- Summary
DO $$
DECLARE
    total_products INT;
    total_variants INT;
    products_with_sizes INT;
BEGIN
    SELECT COUNT(*) INTO total_products 
    FROM products 
    WHERE metadata->>'source' = 'csv_import';
    
    SELECT COUNT(*) INTO total_variants
    FROM product_variants
    WHERE sku LIKE '%-CSV-%';
    
    SELECT COUNT(*) INTO products_with_sizes
    FROM products 
    WHERE metadata->>'source' = 'csv_import' 
    AND (metadata->>'has_sizes')::boolean = true;
    
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Import Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Products imported: %', total_products;
    RAISE NOTICE 'Products with sizes: %', products_with_sizes;
    RAISE NOTICE 'Size variants created: %', total_variants;
    RAISE NOTICE '=================================';
END $$;

COMMIT;