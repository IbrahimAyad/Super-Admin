-- Import Suits from CSV
-- This imports suits that don't exist yet (different from KCT-SUIT series)

BEGIN;

-- Helper functions
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Create suit size variants
CREATE OR REPLACE FUNCTION create_suit_variants(
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

-- Import Men's Double Breasted Suits
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    suit_data RECORD;
    existing_handle TEXT;
BEGIN
    FOR suit_data IN 
        SELECT * FROM (VALUES
            ('Brown Classic Check Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-double-breasted-suit_classic-brown-check-double-breasted-suit-the-connoisseurs-choice_1.0.jpg', 26500, 'Brown Check'),
            ('Gray Classic Double Breasted Suit Ensemble', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_classic-gray-double-breasted-suit-ensemble_1.0.jpg', 26500, 'Gray'),
            ('Lavender Dream Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_lavender-dream-double-breasted-suit-set_1.0.jpg', 28500, 'Lavender'),
            ('Pink Pastel Pinstripe Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-double-breasted-suit_pastel-pink-pinstripe-double-breasted-suit-casual-chic_1.0.jpg', 27500, 'Pink Pinstripe'),
            ('Ocean Blue Textured Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-double-breasted-suit_ocean-blue-textured-double-breasted-suit-a-splash-of-style_1.0.jpg', 28500, 'Ocean Blue'),
            ('Yellow Sunny Elegance Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_sunny-elegance-double-breasted-yellow-suit_1.0.jpg', 27500, 'Yellow'),
            ('Navy Blue Pinstripe Double Breasted Executive', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_navy-blue-pinstripe-double-breasted-suit-executive-precision_1.0.png', 29500, 'Navy Pinstripe'),
            ('Sage Elegance Double Breasted Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_sage-elegance-double-breasted-suit-set_1.0.jpg', 26500, 'Sage')
        ) AS t(name, image_url, price_cents, color)
    LOOP
        existing_handle := create_handle(suit_data.name);
        
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
                'SUIT-DB-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                suit_data.name,
                'Premium double breasted suit for formal and business occasions',
                suit_data.price_cents,
                'Men''s Suits',
                'active',
                suit_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'style', 'Double Breasted'
                ),
                false,
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
                suit_data.image_url,
                'primary',
                1,
                suit_data.name,
                NOW(),
                NOW()
            );
            
            -- Create size variants
            PERFORM create_suit_variants(
                new_product_id,
                suit_data.name,
                'SUIT-DB-' || LPAD(product_counter::text, 3, '0'),
                suit_data.price_cents,
                suit_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', suit_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', suit_data.name;
        END IF;
    END LOOP;
END $$;

-- Import Tuxedos and Special Suits
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    tux_data RECORD;
    existing_handle TEXT;
BEGIN
    FOR tux_data IN 
        SELECT * FROM (VALUES
            ('Emerald Green Tuxedo With Black Satin Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_mens-slim-fit-emerald-green-tuxedo-with-black-satin-lapel_1.0.png', 32500, 'Emerald Green'),
            ('Royal Blue Three Piece Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_royal-blue-three-piece-suit_1.0.jpg', 28500, 'Royal Blue'),
            ('Classic Navy Business Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-suits_classic-navy-business-suit_1.0.jpg', 24500, 'Navy'),
            ('Charcoal Grey Executive Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_charcoal-grey-executive-suit_1.0.jpg', 26500, 'Charcoal'),
            ('Burgundy Velvet Dinner Jacket', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg', 34500, 'Burgundy')
        ) AS t(name, image_url, price_cents, color)
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
                'SUIT-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                tux_data.name,
                'Premium formal suit for special occasions and business events',
                tux_data.price_cents,
                'Men''s Suits',
                'active',
                tux_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'style', CASE 
                        WHEN tux_data.name ILIKE '%tuxedo%' THEN 'Tuxedo'
                        WHEN tux_data.name ILIKE '%three piece%' THEN 'Three Piece'
                        ELSE 'Classic'
                    END
                ),
                CASE WHEN tux_data.name ILIKE '%tuxedo%' THEN true ELSE false END,
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
            PERFORM create_suit_variants(
                new_product_id,
                tux_data.name,
                'SUIT-' || LPAD(product_counter::text, 3, '0'),
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

-- Import Kids Suits
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    kid_suit_data RECORD;
    existing_handle TEXT;
    kid_sizes TEXT[] := ARRAY['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14', '16'];
    size_val TEXT;
BEGIN
    FOR kid_suit_data IN 
        SELECT * FROM (VALUES
            ('Royal Blue Kids Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-suit_royal-blue-kids-suit_1.0.jpg', 12500, 'Royal Blue'),
            ('Black Kids Suit', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-suit_black-kids-suit_1.0.jpg', 12500, 'Black')
        ) AS t(name, image_url, price_cents, color)
    LOOP
        existing_handle := create_handle(kid_suit_data.name);
        
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
                'KID-SUIT-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                kid_suit_data.name,
                'Premium kids suit for special occasions and formal events',
                kid_suit_data.price_cents,
                'Kids Formal Wear',
                'active',
                kid_suit_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'age_group', 'Kids'
                ),
                false,
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
                kid_suit_data.image_url,
                'primary',
                1,
                kid_suit_data.name,
                NOW(),
                NOW()
            );
            
            -- Create kids size variants
            FOREACH size_val IN ARRAY kid_sizes
            LOOP
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
                    new_product_id,
                    kid_suit_data.name || ' - Size ' || size_val,
                    size_val,
                    kid_suit_data.color,
                    'KID-SUIT-' || LPAD(product_counter::text, 3, '0') || '-' || REPLACE(size_val, ' ', ''),
                    kid_suit_data.price_cents,
                    15,
                    NOW(),
                    NOW()
                ) ON CONFLICT (sku) DO NOTHING;
            END LOOP;
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', kid_suit_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', kid_suit_data.name;
        END IF;
    END LOOP;
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_suit_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id),
    in_stock = EXISTS(SELECT 1 FROM product_variants WHERE product_id = p.id AND inventory_quantity > 0)
WHERE p.additional_info->>'source' = 'csv_import'
AND p.category IN ('Men''s Suits', 'Kids Formal Wear');

-- Summary Report
SELECT 'New Suits Import Summary' as report;

SELECT 
    category,
    COUNT(*) as product_count,
    COUNT(*) FILTER (WHERE additional_info->>'style' = 'Double Breasted') as double_breasted,
    COUNT(*) FILTER (WHERE additional_info->>'style' = 'Tuxedo') as tuxedos,
    COUNT(*) FILTER (WHERE category = 'Kids Formal Wear') as kids_suits,
    AVG(base_price/100.0) as avg_price,
    SUM(variant_count) as total_variants
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND (category = 'Men''s Suits' OR category = 'Kids Formal Wear')
AND created_at >= NOW() - INTERVAL '10 minutes'
GROUP BY category;

-- Show newly imported suits
SELECT 
    sku,
    name,
    category,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    additional_info->>'style' as style
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND (category = 'Men''s Suits' OR category = 'Kids Formal Wear')
AND created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY sku;

COMMIT;