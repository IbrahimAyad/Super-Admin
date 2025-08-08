-- ============================================
-- SIMPLE PRODUCT SYSTEM SETUP
-- Run this in Supabase SQL Editor NOW
-- ============================================

-- 1. Ensure product_variants table exists
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    
    -- Core variant fields
    size VARCHAR(20),
    color VARCHAR(50),
    sku VARCHAR(100) UNIQUE,
    
    -- Pricing & Inventory
    price DECIMAL(10,2),
    inventory_quantity INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    position INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_variants_product ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_variants_sku ON public.product_variants(sku);

-- 3. Ensure product_images has correct structure
ALTER TABLE public.product_images ADD COLUMN IF NOT EXISTS position INTEGER DEFAULT 0;
ALTER TABLE public.product_images ADD COLUMN IF NOT EXISTS image_type VARCHAR(20) DEFAULT 'additional';

-- 4. Add missing columns to products table
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS details JSONB;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS product_type VARCHAR(50);

-- 5. Enable RLS with simple policies
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "variants_public_read" ON public.product_variants;
DROP POLICY IF EXISTS "variants_auth_all" ON public.product_variants;

CREATE POLICY "variants_public_read" ON public.product_variants
    FOR SELECT USING (true);

CREATE POLICY "variants_auth_all" ON public.product_variants
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- 6. Grant permissions
GRANT ALL ON public.product_variants TO authenticated;
GRANT SELECT ON public.product_variants TO anon;

-- 7. Verify setup
SELECT 
    'Tables Ready' as status,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'products') as products_exists,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'product_variants') as variants_exists,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'product_images') as images_exists;

-- 8. Show sample data structure
SELECT 
    'Sample Product Structure' as info,
    json_build_object(
        'product', json_build_object(
            'name', 'Classic Navy Suit',
            'sku', 'SUIT-NAV-001',
            'price', 229.99,
            'category', 'Suits',
            'product_type', 'suits'
        ),
        'variants', json_build_array(
            json_build_object('size', '40R', 'inventory', 10),
            json_build_object('size', '42R', 'inventory', 8),
            json_build_object('size', '44R', 'inventory', 5)
        ),
        'images', json_build_array(
            'image1.jpg',
            'image2.jpg',
            'image3.jpg'
        )
    ) as structure;