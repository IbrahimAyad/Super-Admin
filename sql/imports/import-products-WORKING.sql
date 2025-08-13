-- SIMPLIFIED Product Import Script - WORKING VERSION
-- This version only uses columns that actually exist in the products table
-- Run the check-products-table.sql first to verify columns
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
        sizes := ARRAY['36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R'];
    ELSIF p_category = 'Knitwear' THEN
        sizes := ARRAY['S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
    ELSIF p_product_name ILIKE '%vest%' THEN
        sizes := ARRAY['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL'];
    ELSIF p_product_name ILIKE '%kid%' THEN
        sizes := ARRAY['2T', '3T', '4T', '5', '6', '7', '8', '10', '12', '14', '16'];
    ELSE
        RETURN; -- No sizes needed
    END IF;
    
    -- Create size variants
    FOREACH size IN ARRAY sizes
    LOOP
        variant_sku := p_base_sku || '-' || REPLACE(size, '.', '');
        
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
            'Standard', -- Default color
            variant_sku,
            p_base_price,
            20, -- Default inventory
            NOW(),
            NOW()
        ) ON CONFLICT (sku) DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- TEST: Import just 3 products first to verify it works
DO $$
DECLARE
    new_product_id UUID;
    product_data RECORD;
    product_counter INT := 1;
BEGIN
    -- Test with just 3 vest products first
    FOR product_data IN 
        SELECT * FROM (VALUES
            ('White Vest And Tie Set', 'White premium vest and tie set', 65.00, 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg'),
            ('Blush Vest And Tie Set', 'Blush premium vest and tie set', 65.00, 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg'),
            ('Pink Bubblegum Vest And Tie Set', 'Pink bubblegum vest and tie set', 65.00, 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg')
        ) AS t(name, description, price, image_url)
    LOOP
        new_product_id := gen_random_uuid();
        
        -- Insert product with ONLY columns that exist
        INSERT INTO products (
            id,
            sku,
            name,
            description,
            base_price,
            category,
            status,
            created_at,
            updated_at
        ) VALUES (
            new_product_id,
            'TEST-' || LPAD(product_counter::text, 3, '0'),
            product_data.name,
            product_data.description,
            product_data.price,
            'Vest & Tie Sets',
            'active',
            NOW(),
            NOW()
        );
        
        -- Add image to product_images table
        INSERT INTO product_images (
            product_id,
            image_url,
            alt_text,
            is_primary,
            display_order,
            created_at
        ) VALUES (
            new_product_id,
            product_data.image_url,
            product_data.name,
            true,
            1,
            NOW()
        ) ON CONFLICT DO NOTHING;
        
        -- Create size variants
        PERFORM create_size_variants(
            new_product_id,
            product_data.name,
            'Vest & Tie Sets',
            'TEST-' || LPAD(product_counter::text, 3, '0'),
            product_data.price
        );
        
        product_counter := product_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Test import complete - 3 products added';
END $$;

-- Clean up
DROP FUNCTION IF EXISTS create_size_variants;

COMMIT;

-- Check results
SELECT 
    p.id,
    p.sku,
    p.name,
    p.base_price,
    p.category,
    p.status,
    COUNT(pv.id) as variant_count,
    COUNT(pi.id) as image_count
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
LEFT JOIN product_images pi ON pi.product_id = p.id
WHERE p.sku LIKE 'TEST-%'
GROUP BY p.id, p.sku, p.name, p.base_price, p.category, p.status;