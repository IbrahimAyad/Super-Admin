-- Import All Tuxedos from CSV
-- This imports premium tuxedos with various styles and colors

BEGIN;

-- Helper functions
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Create tuxedo size variants
CREATE OR REPLACE FUNCTION create_tuxedo_variants(
    p_product_id UUID,
    p_product_name TEXT,
    p_base_sku TEXT,
    p_base_price INTEGER,
    p_color TEXT
) RETURNS void AS $$
DECLARE
    sizes TEXT[] := ARRAY['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', 
                          '38L', '40L', '42L', '44L', '46L', '48L', '50L',
                          '38S', '40S', '42S', '44S', '46S'];
    size TEXT;
    variant_sku TEXT;
BEGIN
    FOREACH size IN ARRAY sizes
    LOOP
        variant_sku := p_base_sku || '-' || REPLACE(size, ' ', '');
        
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
                    WHEN size IN ('40R', '42R', '44R') THEN 20
                    WHEN size IN ('38R', '46R', '48R') THEN 15
                    WHEN size LIKE '%L' THEN 12
                    WHEN size LIKE '%S' THEN 10
                    ELSE 8
                END,
                NOW(),
                NOW()
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Import Premium Tuxedos with Shawl Lapels
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    tux_data RECORD;
    existing_handle TEXT;
BEGIN
    FOR tux_data IN 
        SELECT * FROM (VALUES
            -- Shawl Lapel Tuxedos
            ('Midnight Blue Tuxedo With Black Satin Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-midnight-blue-tuxedo-with-black-satin-shawl-lapel_1.0.jpg', 34500, 'Midnight Blue', 'Shawl'),
            ('Navy Blue Tuxedo With Satin Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_mens-slim-fit-navy-blue-tuxedo-with-satin-shawl-lapel-1_1.0.jpg', 32500, 'Navy Blue', 'Shawl'),
            ('Light Grey Tuxedo With Satin Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-light-grey-tuxedo-with-satin-shawl-lapel_1.0.jpg', 32500, 'Light Grey', 'Shawl'),
            ('Black Three Piece Tuxedo With Satin Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-classic-black-three-piece-tuxedo-with-satin-shawl-lapel_1.0.png', 38500, 'Black', 'Shawl'),
            ('Teal Blue Three Piece Tuxedo With Satin Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-teal-blue-three-piece-tuxedo-with-satin-shawl-lapel_1.0.jpg', 36500, 'Teal Blue', 'Shawl'),
            
            -- Peak Lapel Tuxedos
            ('Black Double Breasted Tuxedo With Satin Peak Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-black-double-breasted-tuxedo-with-satin-peak-lapel_1.0.jpg', 36500, 'Black', 'Peak'),
            ('White Double Breasted Tuxedo With Black Satin Peak Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-tuxedos_mens-slim-fit-white-double-breasted-tuxedo-with-black-satin-peak-lapel_1.0.jpg', 36500, 'White', 'Peak'),
            
            -- Notch Lapel Tuxedos
            ('Classic Black Tuxedo With Satin Notch Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-classic-black-tuxedo-with-satin-notch-lapel_1.0.jpg', 29500, 'Black', 'Notch'),
            
            -- Colored Tuxedos
            ('White And Black Tuxedo With Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-white-and-black-tuxedo-with-satin-lapel_1.0.jpg', 34500, 'White/Black', 'Standard'),
            ('Red Double Breasted Tuxedo With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-red-double-breasted-tuxedo-with-black-satin-lapel_1.0.jpg', 35500, 'Red', 'Standard'),
            ('Royal Blue Tuxedo With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-royal-blue-tuxedo-with-black-satin-lapel_1.0.jpg', 33500, 'Royal Blue', 'Standard'),
            ('Burgundy Tuxedo Jacket With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-burgundy-tuxedo-jacket-with-black-satin-lapel_1.0.jpg', 28500, 'Burgundy', 'Standard'),
            ('Charcoal Grey Tuxedo With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-charcoal-grey-tuxedo-with-black-satin-lapel_1.0.jpg', 32500, 'Charcoal Grey', 'Standard'),
            
            -- Special Design Tuxedos
            ('Red Tuxedo With Black Satin Lapel And Matching Vest', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-tuxedos_mens-slim-fit-red-tuxedo-with-black-satin-lapel-and-matching-vest_1.0.jpg', 38500, 'Red', 'With Vest'),
            ('Dazzling Silver Tuxedo With Black Paisley Design', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_dazzling-shiny-silver-tuxedo-with-black-paisley-design-a-showstopper-prom-and-wedding-seasons_2.0.jpg', 42500, 'Silver/Black Paisley', 'Paisley'),
            ('Black Paisley Three Piece Tuxedo With Velvet Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_elegant-black-paisley-three-piece-tuxedo-with-velvet-lapel-a-modern-classic-for-2024-prom-and-wedding-seasons_2.0.webp', 45500, 'Black Paisley', 'Velvet')
        ) AS t(name, image_url, price_cents, color, lapel_style)
    LOOP
        existing_handle := create_handle(tux_data.name);
        
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
                'TUX-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                tux_data.name,
                'Premium slim fit tuxedo with satin ' || tux_data.lapel_style || ' lapel - Perfect for weddings, proms, and black-tie events',
                tux_data.price_cents,
                'Tuxedos',
                'active',
                tux_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'lapel_style', tux_data.lapel_style,
                    'color', tux_data.color
                ),
                CASE 
                    WHEN tux_data.name ILIKE '%paisley%' OR tux_data.name ILIKE '%velvet%' THEN true 
                    ELSE false 
                END,
                true,
                true,
                true,
                true,
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
                tux_data.image_url,
                'primary',
                1,
                tux_data.name,
                NOW(),
                NOW()
            );
            
            -- Create size variants
            PERFORM create_tuxedo_variants(
                new_product_id,
                tux_data.name,
                'TUX-' || LPAD(product_counter::text, 3, '0'),
                tux_data.price_cents,
                tux_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', tux_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', tux_data.name;
        END IF;
    END LOOP;
END $$;

-- Import More Premium Tuxedos (Second Batch)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT;
    tux_data RECORD;
    existing_handle TEXT;
BEGIN
    -- Get starting counter
    SELECT COALESCE(MAX(SUBSTRING(sku FROM 5)::INT), 0) + 1 
    INTO product_counter
    FROM products 
    WHERE sku LIKE 'TUX-%';
    
    FOR tux_data IN 
        SELECT * FROM (VALUES
            -- Prom Collection
            ('Black Double Breasted Prom Tuxedo Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-double-breasted-prom-tuxedo-satin-lapel_2.0.jpg', 32500, 'Black', 'Prom'),
            ('White Black Double Breasted Tuxedo', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_white-black-double-breasted-tuxedo_2.0.jpg', 34500, 'White/Black', 'Prom'),
            ('Black And White Classic Tuxedo', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-and-white-tuxedo_2.0.jpg', 31500, 'Black/White', 'Classic'),
            
            -- Velvet Collection
            ('Burgundy Velvet Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg', 38500, 'Burgundy Velvet', 'Velvet'),
            ('Black Velvet Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_black-velvet-tuxedo-jacket_1.0.jpg', 38500, 'Black Velvet', 'Velvet'),
            ('Midnight Blue Velvet Tuxedo', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_midnight-blue-velvet-tuxedo_1.0.jpg', 39500, 'Midnight Blue Velvet', 'Velvet'),
            ('Green Velvet Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_green-velvet-tuxedo-jacket_1.0.jpg', 38500, 'Green Velvet', 'Velvet'),
            
            -- Paisley & Pattern Collection
            ('Gold Paisley Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-jacket_gold-paisley-tuxedo-jacket_1.0.jpg', 42500, 'Gold Paisley', 'Paisley'),
            ('Silver Sequin Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_silver-sequin-tuxedo-jacket_1.0.jpg', 45500, 'Silver Sequin', 'Sequin'),
            ('Black Floral Embroidered Tuxedo', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_black-floral-embroidered-tuxedo_1.0.jpg', 48500, 'Black Floral', 'Embroidered'),
            
            -- Unique Colors
            ('Pink Tuxedo With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-jacket_pink-tuxedo-with-black-lapel_1.0.jpg', 33500, 'Pink', 'Standard'),
            ('Turquoise Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_turquoise-tuxedo-jacket_1.0.jpg', 32500, 'Turquoise', 'Standard'),
            ('Purple Tuxedo With Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_purple-tuxedo-satin-lapel_1.0.jpg', 33500, 'Purple', 'Standard'),
            ('Orange Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-jacket_orange-tuxedo-jacket_1.0.jpg', 31500, 'Orange', 'Standard'),
            ('Gold Tuxedo Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_gold-tuxedo-jacket_1.0.jpg', 34500, 'Gold', 'Standard')
        ) AS t(name, image_url, price_cents, color, collection)
    LOOP
        existing_handle := create_handle(tux_data.name);
        
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
                'TUX-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                tux_data.name,
                'Premium ' || tux_data.collection || ' tuxedo - Luxury formal wear for special occasions',
                tux_data.price_cents,
                'Tuxedos',
                'active',
                tux_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'collection', tux_data.collection,
                    'color', tux_data.color
                ),
                CASE 
                    WHEN tux_data.collection IN ('Velvet', 'Paisley', 'Sequin', 'Embroidered') THEN true 
                    ELSE false 
                END,
                true,
                true,
                true,
                true,
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
                tux_data.image_url,
                'primary',
                1,
                tux_data.name,
                NOW(),
                NOW()
            );
            
            -- Create size variants
            PERFORM create_tuxedo_variants(
                new_product_id,
                tux_data.name,
                'TUX-' || LPAD(product_counter::text, 3, '0'),
                tux_data.price_cents,
                tux_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', tux_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', tux_data.name;
        END IF;
    END LOOP;
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_tuxedo_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id),
    in_stock = EXISTS(SELECT 1 FROM product_variants WHERE product_id = p.id AND inventory_quantity > 0)
WHERE p.additional_info->>'source' = 'csv_import'
AND p.category = 'Tuxedos';

-- Summary Report
SELECT 'Tuxedos Import Summary' as report;

SELECT 
    COUNT(*) as total_tuxedos,
    COUNT(*) FILTER (WHERE additional_info->>'collection' = 'Velvet') as velvet_tuxedos,
    COUNT(*) FILTER (WHERE additional_info->>'collection' = 'Paisley') as paisley_tuxedos,
    COUNT(*) FILTER (WHERE additional_info->>'lapel_style' = 'Shawl') as shawl_lapel,
    COUNT(*) FILTER (WHERE additional_info->>'lapel_style' = 'Peak') as peak_lapel,
    COUNT(*) FILTER (WHERE featured = true) as featured_items,
    AVG(base_price/100.0) as avg_price,
    MIN(base_price/100.0) as min_price,
    MAX(base_price/100.0) as max_price
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND category = 'Tuxedos'
AND created_at >= NOW() - INTERVAL '10 minutes';

-- Show sample of imported tuxedos
SELECT 
    sku,
    name,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    COALESCE(additional_info->>'collection', additional_info->>'lapel_style') as style,
    featured
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND category = 'Tuxedos'
AND created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY base_price DESC
LIMIT 15;

COMMIT;