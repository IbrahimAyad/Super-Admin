-- Import Premium Blazers from products_blazers_urls.csv
-- This imports luxury blazers including velvet, sequin, paisley, and floral designs

BEGIN;

-- Helper functions
CREATE OR REPLACE FUNCTION create_handle(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(p_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Create blazer size variants
CREATE OR REPLACE FUNCTION create_blazer_variants(
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
                    WHEN size IN ('40R', '42R', '44R') THEN 15
                    WHEN size IN ('38R', '46R', '48R') THEN 12
                    WHEN size LIKE '%L' THEN 10
                    WHEN size LIKE '%S' THEN 8
                    ELSE 6
                END,
                NOW(),
                NOW()
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Import Velvet & Luxury Blazers
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT := 1;
    blazer_data RECORD;
    existing_handle TEXT;
BEGIN
    FOR blazer_data IN 
        SELECT * FROM (VALUES
            -- Velvet Collection
            ('Black Velvet Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-velvet-blazer_1.0.jpg', 28500, 'Black', 'Velvet'),
            ('Red Velvet Jacket With Bowtie', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/blazer_red-velvet-jacket-bowtie_1.0.jpg', 29500, 'Red', 'Velvet'),
            ('Green Patterned Velvet Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_green-patterned-velvet-tuxedo-blazer-luxury-prom-wedding_1.0.jpg', 32500, 'Green', 'Velvet'),
            
            -- Sequin & Sparkle Collection
            ('Gold Sequin Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_men-s-gold-sequin-tuxedo-blazer-luxury-prom-wedding-jacket_1.0.jpg', 38500, 'Gold', 'Sequin'),
            ('Black Glitter Rhinestone Shawl Lapel Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_black-glitter-rhinestone-shawl-lapel-tuxedo-blazer-prom-2025_1.0.jpg', 42500, 'Black', 'Rhinestone'),
            ('Rose Brown Sparkle Prom Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_copy-of-rose-brown-sparkle-prom-blazer_1.0.jpg', 34500, 'Rose Brown', 'Sparkle'),
            
            -- Floral & Pattern Collection
            ('Black Red Floral Blazer With Matching Bowtie', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-and-red-floral-with-matching-bowtie_1.0.jpg', 26500, 'Black/Red', 'Floral'),
            ('Red Floral Prom Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_red-floral-prom-tuxedo-blazer-2025-black-satin-lapel_1.0.jpg', 28500, 'Red', 'Floral'),
            ('Black Floral Prom Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-floral-prom-tuxedo-blazer-2025-satin-lapel_1.0.jpg', 28500, 'Black', 'Floral'),
            ('Red Floral Brocade Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/blazer_men-s-red-floral-brocade-tuxedo-blazer-luxury-prom-wedding-jacket_1.0.jpg', 35500, 'Red', 'Brocade'),
            
            -- Paisley Collection
            ('Rose Gold Paisley Blazer With Black Shawl Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_rose-gold-paisley-matching-bowtie-with-black-shawl-lapel-prom-blazer_1.0.jpg', 32500, 'Rose Gold', 'Paisley'),
            ('Burgundy Paisley Blazer With Black Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/blazer_burgundy-paisley-with-black-lapel-blazer-with-matching-bowtie_1.0.jpg', 31500, 'Burgundy', 'Paisley'),
            ('Green Gold Paisley Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/blazer_green-gold-paisley-tuxedo-blazer-luxury-prom-wedding-jacket_1.0.jpg', 33500, 'Green/Gold', 'Paisley'),
            ('White Blue Paisley Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_white-blue-paisley-tuxedo-blazer-luxury-prom-wedding-jacket_1.0.jpg', 33500, 'White/Blue', 'Paisley'),
            
            -- Embellished Collection
            ('Royal Blue Embellished Lapel Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_men-s-royal-blue-embellished-lapel-tuxedo-blazer-prom-wedding_1.0.jpg', 36500, 'Royal Blue', 'Embellished'),
            ('Golden Pattern Black Prom Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_golden-pattern-black-prom-blazer-with-black-satin-notch-lapel_1.0.jpg', 29500, 'Black/Gold', 'Pattern'),
            ('Navy Diamond Pattern Prom Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_navy-with-diamond-pattern-prom-blazer_1.0.jpg', 27500, 'Navy', 'Pattern'),
            
            -- Classic & Solid Collection
            ('Black On Black Blazer With Matching Bowtie', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_black-on-black-blazer-with-matching-bowtie_1.0.jpg', 25500, 'Black', 'Classic'),
            ('Red Blazer With Black Lapel', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/blazer_red-with-black-lapel-blazer-with-matching-bowtie_1.0.jpg', 24500, 'Red', 'Classic'),
            ('Mint Green Gold Patterned Tuxedo Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_mint-green-gold-patterned-tuxedo-blazer-luxury-prom-wedding-jacket_1.0.jpg', 31500, 'Mint Green', 'Pattern')
        ) AS t(name, image_url, price_cents, color, style)
    LOOP
        existing_handle := create_handle(blazer_data.name);
        
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
                'BLZ-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                blazer_data.name,
                'Premium ' || blazer_data.style || ' blazer - Luxury formal wear for weddings, proms, and special events',
                blazer_data.price_cents,
                CASE 
                    WHEN blazer_data.style IN ('Velvet', 'Brocade') THEN 'Luxury Velvet Blazers'
                    WHEN blazer_data.style IN ('Sequin', 'Rhinestone', 'Sparkle') THEN 'Sparkle & Sequin Blazers'
                    WHEN blazer_data.style IN ('Floral', 'Paisley', 'Pattern', 'Embellished') THEN 'Prom & Formal Blazers'
                    ELSE 'Casual Summer Blazers'
                END,
                'active',
                blazer_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'style', blazer_data.style,
                    'color', blazer_data.color
                ),
                CASE 
                    WHEN blazer_data.style IN ('Sequin', 'Rhinestone', 'Velvet', 'Sparkle') THEN true 
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
                blazer_data.image_url,
                'primary',
                1,
                blazer_data.name,
                NOW(),
                NOW()
            );
            
            -- Create size variants
            PERFORM create_blazer_variants(
                new_product_id,
                blazer_data.name,
                'BLZ-' || LPAD(product_counter::text, 3, '0'),
                blazer_data.price_cents,
                blazer_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', blazer_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', blazer_data.name;
        END IF;
    END LOOP;
END $$;

-- Import Additional Premium Blazers (Second Batch)
DO $$
DECLARE
    new_product_id UUID;
    product_counter INT;
    blazer_data RECORD;
    existing_handle TEXT;
BEGIN
    -- Get starting counter - handle non-numeric SKUs safely
    SELECT COALESCE(MAX(
        CASE 
            WHEN SUBSTRING(sku FROM 5) ~ '^[0-9]+$' 
            THEN SUBSTRING(sku FROM 5)::INT 
            ELSE 0 
        END
    ), 0) + 1 
    INTO product_counter
    FROM products 
    WHERE sku LIKE 'BLZ-%';
    
    FOR blazer_data IN 
        SELECT * FROM (VALUES
            -- Casual & Business Collection
            ('Tan Herringbone Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-tan-herringbone-blazer-with-white-shirt-and-beige-chinos-ensemble_1.0.jpg', 22500, 'Tan', 'Herringbone'),
            ('Navy Blue Business Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_mens-navy-blue-business-blazer-executive-style_1.0.jpg', 24500, 'Navy', 'Business'),
            ('Charcoal Grey Wool Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_charcoal-grey-wool-blazer-professional_1.0.jpg', 26500, 'Charcoal', 'Wool'),
            
            -- Summer Collection
            ('Light Blue Linen Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_light-blue-linen-summer-blazer_1.0.jpg', 19500, 'Light Blue', 'Linen'),
            ('Cream Cotton Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_cream-cotton-summer-blazer_1.0.jpg', 18500, 'Cream', 'Cotton'),
            ('Khaki Casual Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_khaki-casual-blazer_1.0.jpg', 17500, 'Khaki', 'Casual'),
            
            -- Designer Pattern Collection
            ('Windowpane Check Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-blazers_windowpane-check-pattern-blazer_1.0.jpg', 28500, 'Grey Check', 'Pattern'),
            ('Houndstooth Pattern Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_houndstooth-pattern-blazer_1.0.jpg', 27500, 'Black/White', 'Pattern'),
            ('Prince of Wales Check Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_prince-of-wales-check-blazer_1.0.jpg', 29500, 'Grey', 'Pattern'),
            
            -- Bold Colors Collection
            ('Emerald Green Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_emerald-green-blazer_1.0.jpg', 25500, 'Emerald', 'Bold'),
            ('Burgundy Wine Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_burgundy-wine-blazer_1.0.jpg', 25500, 'Burgundy', 'Bold'),
            ('Mustard Yellow Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-blazers_mustard-yellow-blazer_1.0.jpg', 24500, 'Mustard', 'Bold'),
            ('Coral Pink Summer Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_coral-pink-summer-blazer_1.0.jpg', 23500, 'Coral', 'Bold'),
            ('Electric Blue Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_electric-blue-blazer_1.0.jpg', 24500, 'Electric Blue', 'Bold'),
            
            -- Textured Collection
            ('Tweed Heritage Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_tweed-heritage-blazer_1.0.jpg', 31500, 'Brown Tweed', 'Textured'),
            ('Corduroy Autumn Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_corduroy-autumn-blazer_1.0.jpg', 26500, 'Brown', 'Textured'),
            ('Suede Touch Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-blazers_suede-touch-blazer_1.0.jpg', 34500, 'Tan', 'Textured'),
            
            -- Double Breasted Collection
            ('Navy Double Breasted Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_navy-double-breasted-blazer_1.0.jpg', 28500, 'Navy', 'Double Breasted'),
            ('Ivory Double Breasted Blazer', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-blazers_ivory-double-breasted-blazer_1.0.jpg', 27500, 'Ivory', 'Double Breasted'),
            ('Black Peak Lapel Double Breasted', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_black-peak-lapel-double-breasted_1.0.jpg', 29500, 'Black', 'Double Breasted')
        ) AS t(name, image_url, price_cents, color, style)
    LOOP
        existing_handle := create_handle(blazer_data.name);
        
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
                'BLZ-' || LPAD(product_counter::text, 3, '0'),
                existing_handle,
                blazer_data.name,
                'Premium ' || blazer_data.style || ' blazer - Versatile formal and casual wear',
                blazer_data.price_cents,
                CASE 
                    WHEN blazer_data.style IN ('Linen', 'Cotton', 'Casual', 'Bold') THEN 'Casual Summer Blazers'
                    WHEN blazer_data.style IN ('Business', 'Wool', 'Double Breasted') THEN 'Men''s Suits'
                    WHEN blazer_data.style IN ('Textured', 'Herringbone', 'Pattern') THEN 'Prom & Formal Blazers'
                    ELSE 'Casual Summer Blazers'
                END,
                'active',
                blazer_data.image_url,
                jsonb_build_object(
                    'source', 'csv_import',
                    'import_date', NOW()::text,
                    'has_sizes', true,
                    'style', blazer_data.style,
                    'color', blazer_data.color
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
                blazer_data.image_url,
                'primary',
                1,
                blazer_data.name,
                NOW(),
                NOW()
            );
            
            -- Create size variants
            PERFORM create_blazer_variants(
                new_product_id,
                blazer_data.name,
                'BLZ-' || LPAD(product_counter::text, 3, '0'),
                blazer_data.price_cents,
                blazer_data.color
            );
            
            product_counter := product_counter + 1;
            RAISE NOTICE 'Imported: %', blazer_data.name;
        ELSE
            RAISE NOTICE 'Skipped (already exists): %', blazer_data.name;
        END IF;
    END LOOP;
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_blazer_variants;
DROP FUNCTION IF EXISTS create_handle;

-- Update product counts
UPDATE products p
SET 
    variant_count = (SELECT COUNT(*) FROM product_variants WHERE product_id = p.id),
    total_inventory = (SELECT COALESCE(SUM(inventory_quantity), 0) FROM product_variants WHERE product_id = p.id),
    in_stock = EXISTS(SELECT 1 FROM product_variants WHERE product_id = p.id AND inventory_quantity > 0)
WHERE p.additional_info->>'source' = 'csv_import'
AND p.category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Casual Summer Blazers');

-- Summary Report
SELECT 'Blazers Import Summary' as report;

SELECT 
    category,
    COUNT(*) as product_count,
    COUNT(*) FILTER (WHERE featured = true) as featured_items,
    AVG(base_price/100.0) as avg_price,
    MIN(base_price/100.0) as min_price,
    MAX(base_price/100.0) as max_price,
    SUM(variant_count) as total_variants
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Casual Summer Blazers', 'Men''s Suits')
AND created_at >= NOW() - INTERVAL '10 minutes'
GROUP BY category
ORDER BY product_count DESC;

-- Show sample of imported blazers
SELECT 
    sku,
    name,
    category,
    base_price/100.0 as price_dollars,
    variant_count,
    total_inventory,
    additional_info->>'style' as style,
    featured
FROM products
WHERE additional_info->>'source' = 'csv_import'
AND category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Casual Summer Blazers')
AND created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY base_price DESC
LIMIT 20;

COMMIT;