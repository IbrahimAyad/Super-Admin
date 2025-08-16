-- Update Blazer System with Flexible Size Options
-- 1. Add size configuration to products_enhanced
-- 2. Update pricing to $199-249
-- 3. Disable S and L variants by default
-- 4. Make it configurable per product

-- Step 1: Add size configuration columns to products_enhanced
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS size_options JSONB DEFAULT '{"regular": true, "short": false, "long": false}',
ADD COLUMN IF NOT EXISTS available_sizes TEXT[] DEFAULT ARRAY['36R','38R','40R','42R','44R','46R','48R','50R','52R','54R'];

-- Step 2: Update blazer pricing to $199-249 range
UPDATE products_enhanced
SET 
    base_price = 199 + FLOOR(RANDOM() * 51)::INTEGER,  -- Random price between $199-249
    compare_at_price = base_price + FLOOR(RANDOM() * 50 + 50)::INTEGER,  -- Compare price $50-100 higher
    price_tier = 'TIER_5',  -- $199-249 range
    updated_at = NOW()
WHERE (LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%');

-- Step 3: Set default size options for blazers (Regular only by default)
UPDATE products_enhanced
SET 
    size_options = '{"regular": true, "short": false, "long": false}',
    available_sizes = ARRAY['36R','38R','40R','42R','44R','46R','48R','50R','52R','54R'],
    updated_at = NOW()
WHERE (LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%');

-- Step 4: Disable existing S and L variants (set available = false, keep for future)
UPDATE product_variants
SET 
    available = false,
    updated_at = NOW()
WHERE product_id IN (
    SELECT id FROM products_enhanced 
    WHERE LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%'
)
AND (option1 LIKE '%S' OR option1 LIKE '%L')
AND option1 NOT IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL'); -- Don't affect basic sizes

-- Step 5: Ensure R variants are enabled and have correct pricing
UPDATE product_variants pv
SET 
    available = true,
    price = p.base_price,
    updated_at = NOW()
FROM products p
WHERE pv.product_id = p.id
AND p.id IN (
    SELECT id FROM products_enhanced 
    WHERE LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%'
)
AND pv.option1 LIKE '%R';

-- Step 6: Create function to toggle size options
CREATE OR REPLACE FUNCTION toggle_product_size_options(
    p_product_id UUID,
    p_enable_short BOOLEAN DEFAULT false,
    p_enable_long BOOLEAN DEFAULT false,
    p_enable_regular BOOLEAN DEFAULT true
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Update the size options
    UPDATE products_enhanced
    SET 
        size_options = jsonb_build_object(
            'regular', p_enable_regular,
            'short', p_enable_short,
            'long', p_enable_long
        ),
        updated_at = NOW()
    WHERE id = p_product_id;
    
    -- Update variant availability based on new settings
    UPDATE product_variants
    SET 
        available = CASE 
            WHEN option1 LIKE '%R' THEN p_enable_regular
            WHEN option1 LIKE '%S' AND option1 NOT IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL') THEN p_enable_short
            WHEN option1 LIKE '%L' AND option1 NOT IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL') THEN p_enable_long
            ELSE available
        END,
        updated_at = NOW()
    WHERE product_id = p_product_id;
    
    -- Return the updated configuration
    SELECT jsonb_build_object(
        'product_id', id,
        'product_name', name,
        'size_options', size_options,
        'variants_updated', (
            SELECT COUNT(*) 
            FROM product_variants 
            WHERE product_id = p_product_id
        )
    ) INTO v_result
    FROM products_enhanced
    WHERE id = p_product_id;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create view for admin to see blazer configuration
CREATE OR REPLACE VIEW blazer_size_configuration AS
SELECT 
    pe.id,
    pe.name,
    pe.sku,
    pe.base_price,
    pe.size_options,
    pe.size_options->>'regular' as regular_enabled,
    pe.size_options->>'short' as short_enabled,
    pe.size_options->>'long' as long_enabled,
    COUNT(CASE WHEN pv.option1 LIKE '%R' AND pv.available THEN 1 END) as active_regular_sizes,
    COUNT(CASE WHEN pv.option1 LIKE '%S' AND pv.available 
               AND pv.option1 NOT IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL') 
               THEN 1 END) as active_short_sizes,
    COUNT(CASE WHEN pv.option1 LIKE '%L' AND pv.available 
               AND pv.option1 NOT IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', '6XL') 
               THEN 1 END) as active_long_sizes
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(pe.name) LIKE '%blazer%' OR LOWER(pe.category) LIKE '%blazer%'
GROUP BY pe.id, pe.name, pe.sku, pe.base_price, pe.size_options;

-- Step 8: Summary report
SELECT 
    'Blazer System Update Complete' as status,
    COUNT(DISTINCT pe.id) as total_blazers,
    COUNT(DISTINCT CASE WHEN pv.available THEN pv.id END) as active_variants,
    COUNT(DISTINCT CASE WHEN NOT pv.available THEN pv.id END) as disabled_variants,
    MIN(pe.base_price) as min_price,
    MAX(pe.base_price) as max_price,
    ROUND(AVG(pe.base_price)) as avg_price
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(pe.name) LIKE '%blazer%' OR LOWER(pe.category) LIKE '%blazer%';

-- Sample: Show current configuration for first 10 blazers
SELECT * FROM blazer_size_configuration
ORDER BY name
LIMIT 10;