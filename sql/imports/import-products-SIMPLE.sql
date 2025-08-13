-- SIMPLIFIED Product Import Script - NO product_images table
-- Only uses products and product_variants tables
-- Prices in cents (INTEGER)
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
        sizes := ARRAY['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R'];
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
            'Standard',
            variant_sku,
            p_base_price,
            20, -- Default inventory
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

-- Import Vest and Tie Sets (Testing with first 10)
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
            ('Green Emerald Vest And Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg', 6500)
        ) AS t(name, image_url, price_cents)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product with primary_image
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
            'Premium vest and tie set for formal occasions',
            vest_data.price_cents,
            'Vest & Tie Sets',
            'active',
            vest_data.image_url,  -- Store image URL here
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

-- Import Shoes (Testing with first 5)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    shoe_data RECORD;
BEGIN
    FOR shoe_data IN 
        SELECT * FROM (VALUES
            ('Black Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg', 16500),
            ('Navy Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_navy-chelsea-boots_1.0.jpg', 16500),
            ('Brown Chelsea Boots', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_brown-chelsea-boots_1.0.jpg', 16500),
            ('Gold Prom Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_gold-prom-loafers-mens-sparkle-dress-shoes_1.0.jpg', 14500),
            ('Silver Prom Loafers', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_silver-prom-loafers-mens-black-silver-sparkle-dress_1.0.jpg', 14500)
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
            'Premium dress shoes for formal events',
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
    
    RAISE NOTICE 'Imported % shoes', product_counter - 1;
END $$;

-- Import Accessories without sizes (Testing with 3)
DO $$
DECLARE
    product_counter INT := 1;
    accessory_data RECORD;
BEGIN
    FOR accessory_data IN
        SELECT * FROM (VALUES
            ('Black Suspender Bow Tie Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg', 4500),
            ('Red Cummerbund Set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/cummerband_red-cummerbund-set_1.0.jpg', 8500),
            ('Black Wedding Bundle', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_wedding-bundle-black-bowtie-or-tie_6.0.jpg', 12500)
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
            featured,
            visibility,
            requires_shipping,
            taxable,
            track_inventory,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            'ACC-' || LPAD(product_counter::text, 4, '0'),
            create_handle(accessory_data.name),
            accessory_data.name,
            'Premium accessories for formal occasions',
            accessory_data.price_cents,
            'Accessories',
            'active',
            accessory_data.image_url,
            jsonb_build_object(
                'source', 'csv_import',
                'import_date', NOW()::text,
                'has_sizes', false
            ),
            false,
            true,
            true,
            true,
            false, -- No inventory tracking for accessories
            NOW(),
            NOW()
        );
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Imported % accessories', product_counter - 1;
END $$;

-- Clean up temporary functions
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
        ELSE true -- Accessories without variants are always in stock
    END
WHERE p.additional_info->>'source' = 'csv_import';

-- Summary Report
SELECT 
    category,
    COUNT(*) as product_count,
    COUNT(DISTINCT p.id) FILTER (WHERE pv.id IS NOT NULL) as products_with_variants,
    COUNT(pv.id) as total_variants,
    AVG(base_price/100.0) as avg_price_dollars
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.additional_info->>'source' = 'csv_import'
GROUP BY category
ORDER BY category;

-- Show sample of imported products
SELECT 
    sku,
    name,
    category,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    in_stock
FROM products
WHERE additional_info->>'source' = 'csv_import'
ORDER BY created_at DESC
LIMIT 10;

COMMIT;