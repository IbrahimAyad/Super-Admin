-- ============================================
-- QUICK SETUP FOR PRODUCTION-READY PRODUCTS
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create product_variants table
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    
    -- Variant identifiers
    size VARCHAR(20),
    color VARCHAR(50),
    variant_name VARCHAR(100),
    sku VARCHAR(100) UNIQUE,
    barcode VARCHAR(100),
    
    -- Pricing
    price DECIMAL(10,2),
    compare_at_price DECIMAL(10,2),
    cost_per_item DECIMAL(10,2),
    
    -- Inventory
    inventory_quantity INTEGER DEFAULT 0,
    track_inventory BOOLEAN DEFAULT true,
    allow_backorder BOOLEAN DEFAULT false,
    low_stock_threshold INTEGER DEFAULT 5,
    
    -- Weight & Dimensions
    weight DECIMAL(10,3),
    weight_unit VARCHAR(10) DEFAULT 'lb',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    position INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON public.product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_product_variants_size_color ON public.product_variants(product_id, size, color);
CREATE INDEX IF NOT EXISTS idx_product_variants_active ON public.product_variants(is_active) WHERE is_active = true;

-- 3. Enable RLS
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

-- 4. Create simple RLS policies
CREATE POLICY "Public can view variants" ON public.product_variants
    FOR SELECT USING (true);

CREATE POLICY "Authenticated can manage variants" ON public.product_variants
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- 5. Grant permissions
GRANT ALL ON public.product_variants TO authenticated;

-- 6. Create helper function for bulk variant creation
CREATE OR REPLACE FUNCTION create_product_variants(
    p_product_id UUID,
    p_sizes TEXT[],
    p_base_price DECIMAL,
    p_base_sku TEXT
) RETURNS SETOF product_variants AS $$
DECLARE
    v_size TEXT;
    v_position INTEGER := 0;
BEGIN
    FOREACH v_size IN ARRAY p_sizes
    LOOP
        INSERT INTO product_variants (
            product_id,
            size,
            variant_name,
            sku,
            price,
            position
        ) VALUES (
            p_product_id,
            v_size,
            v_size,
            p_base_sku || '-' || v_size,
            p_base_price,
            v_position
        );
        v_position := v_position + 1;
    END LOOP;
    
    RETURN QUERY SELECT * FROM product_variants WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Add sample variants for existing products (optional)
DO $$
DECLARE
    v_product RECORD;
    v_sizes TEXT[];
BEGIN
    -- Define standard sizes based on category
    FOR v_product IN SELECT id, sku, base_price, category FROM products LIMIT 5
    LOOP
        -- Determine sizes based on category
        IF v_product.category ILIKE '%suit%' OR v_product.category ILIKE '%blazer%' THEN
            v_sizes := ARRAY['36', '38', '40', '42', '44', '46', '48', '50', '52'];
        ELSIF v_product.category ILIKE '%shirt%' THEN
            v_sizes := ARRAY['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
        ELSE
            v_sizes := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
        END IF;
        
        -- Create variants
        PERFORM create_product_variants(
            v_product.id,
            v_sizes,
            v_product.base_price,
            v_product.sku
        );
    END LOOP;
END $$;

-- 8. Verify setup
SELECT 
    'Setup Complete!' as status,
    COUNT(DISTINCT product_id) as products_with_variants,
    COUNT(*) as total_variants
FROM product_variants;

-- 9. Check health
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'product_variants' THEN 'READY'
        ELSE 'CHECK'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public' 
AND table_name IN ('products', 'product_variants', 'product_images');