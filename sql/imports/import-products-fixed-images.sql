-- Enhanced Product Import Script with Proper Image Handling
-- Fixed: Using product_images table instead of image_url column
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
        
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

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
            ('Pink Nan Bubblegum Vest And Tie Set', 'nan-bubblegum-vest-and-tie-set', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg')
        ) AS t(name, slug, image_url)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product WITHOUT image_url column
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
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
            jsonb_build_object(
                'source', 'csv_import',
                'original_slug', vest_data.slug,
                'has_sizes', true,
                'image_url', vest_data.image_url  -- Store image URL in metadata
            ),
            NOW(),
            NOW()
        );
        
        -- Insert image into product_images table
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
        );
        
        -- Create size variants
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

-- Clean up
DROP FUNCTION IF EXISTS create_size_variants;

-- Summary
DO $$
DECLARE
    total_products INT;
    total_images INT;
    total_variants INT;
BEGIN
    SELECT COUNT(*) INTO total_products 
    FROM products 
    WHERE metadata->>'source' = 'csv_import';
    
    SELECT COUNT(*) INTO total_images
    FROM product_images pi
    JOIN products p ON pi.product_id = p.id
    WHERE p.metadata->>'source' = 'csv_import';
    
    SELECT COUNT(*) INTO total_variants
    FROM product_variants pv
    JOIN products p ON pv.product_id = p.id
    WHERE p.metadata->>'source' = 'csv_import';
    
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Import Complete\!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Products imported: %', total_products;
    RAISE NOTICE 'Images added: %', total_images;
    RAISE NOTICE 'Size variants created: %', total_variants;
    RAISE NOTICE '=================================';
END $$;

COMMIT;
