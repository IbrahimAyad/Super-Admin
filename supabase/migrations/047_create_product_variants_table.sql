-- ============================================
-- CREATE PRODUCT_VARIANTS TABLE
-- Production-ready table for product size/color variants
-- ============================================

-- Create the product_variants table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    
    -- Variant Details
    size TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT 'Default',
    sku TEXT NOT NULL UNIQUE,
    
    -- Pricing
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    cost_price DECIMAL(10,2),
    compare_at_price DECIMAL(10,2), -- MSRP for discount calculations
    
    -- Inventory
    inventory_quantity INTEGER NOT NULL DEFAULT 0,
    inventory_policy TEXT CHECK (inventory_policy IN ('deny', 'continue')) DEFAULT 'deny',
    
    -- Physical Properties
    weight DECIMAL(8,2), -- in lbs
    dimensions JSONB, -- {length, width, height} in inches
    
    -- Product Identifiers
    barcode TEXT,
    isbn TEXT,
    upc TEXT,
    mpn TEXT, -- Manufacturer Part Number
    
    -- Images & Media
    image_url TEXT,
    image_alt TEXT,
    
    -- Status & Visibility
    status TEXT CHECK (status IN ('active', 'inactive', 'archived')) DEFAULT 'active',
    position INTEGER DEFAULT 0,
    
    -- Stripe Integration
    stripe_price_id TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint on product_id + size + color
    UNIQUE(product_id, size, color)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON public.product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_product_variants_status ON public.product_variants(status);

-- Inventory management indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_inventory ON public.product_variants(inventory_quantity) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_product_variants_low_stock ON public.product_variants(inventory_quantity) WHERE inventory_quantity <= 5 AND status = 'active';

-- Size and color filtering
CREATE INDEX IF NOT EXISTS idx_product_variants_size ON public.product_variants(size);
CREATE INDEX IF NOT EXISTS idx_product_variants_color ON public.product_variants(color);

-- Pricing and sorting
CREATE INDEX IF NOT EXISTS idx_product_variants_price ON public.product_variants(price);
CREATE INDEX IF NOT EXISTS idx_product_variants_position ON public.product_variants(position);

-- Stripe integration
CREATE INDEX IF NOT EXISTS idx_product_variants_stripe_price ON public.product_variants(stripe_price_id) WHERE stripe_price_id IS NOT NULL;

-- Barcode lookups
CREATE INDEX IF NOT EXISTS idx_product_variants_barcode ON public.product_variants(barcode) WHERE barcode IS NOT NULL;

-- Updated timestamp for sync/audit
CREATE INDEX IF NOT EXISTS idx_product_variants_updated_at ON public.product_variants(updated_at);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

-- Public can view active variants for active products
CREATE POLICY "Public can view active variants" ON public.product_variants
    FOR SELECT
    USING (
        status = 'active' 
        AND product_id IN (
            SELECT id FROM public.products 
            WHERE status = 'active'
        )
    );

-- Admins can manage all variants
CREATE POLICY "Admins can manage variants" ON public.product_variants
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['products'] OR permissions @> ARRAY['all'])
        )
    );

-- Service role has full access
CREATE POLICY "Service role full access on variants" ON public.product_variants
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGERS AND FUNCTIONS
-- ============================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_product_variants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_product_variants_updated_at ON public.product_variants;
CREATE TRIGGER trigger_update_product_variants_updated_at
    BEFORE UPDATE ON public.product_variants
    FOR EACH ROW
    EXECUTE FUNCTION update_product_variants_updated_at();

-- Auto-generate SKU if not provided
CREATE OR REPLACE FUNCTION generate_variant_sku()
RETURNS TRIGGER AS $$
DECLARE
    product_sku TEXT;
    base_sku TEXT;
    size_code TEXT;
    color_code TEXT;
    counter INTEGER := 1;
    new_sku TEXT;
BEGIN
    -- If SKU is already provided, validate it's unique and return
    IF NEW.sku IS NOT NULL AND NEW.sku != '' THEN
        -- Check if SKU already exists (excluding current record on update)
        IF EXISTS (
            SELECT 1 FROM public.product_variants 
            WHERE sku = NEW.sku 
            AND (TG_OP = 'INSERT' OR id != NEW.id)
        ) THEN
            RAISE EXCEPTION 'SKU % already exists', NEW.sku;
        END IF;
        RETURN NEW;
    END IF;

    -- Get product SKU as base
    SELECT sku INTO product_sku FROM public.products WHERE id = NEW.product_id;
    
    -- Create base SKU from product SKU or fallback
    base_sku := COALESCE(product_sku, 'PROD-' || EXTRACT(EPOCH FROM NOW())::INTEGER);
    
    -- Generate size and color codes
    size_code := UPPER(REGEXP_REPLACE(NEW.size, '[^A-Z0-9]', '', 'g'));
    color_code := UPPER(LEFT(REGEXP_REPLACE(NEW.color, '[^A-Z]', '', 'g'), 3));
    
    -- Generate unique SKU
    LOOP
        new_sku := base_sku || '-' || size_code || '-' || color_code;
        
        -- Add counter if this is not the first attempt
        IF counter > 1 THEN
            new_sku := new_sku || '-' || counter;
        END IF;
        
        -- Check if this SKU exists
        IF NOT EXISTS (
            SELECT 1 FROM public.product_variants 
            WHERE sku = new_sku 
            AND (TG_OP = 'INSERT' OR id != NEW.id)
        ) THEN
            EXIT;
        END IF;
        
        counter := counter + 1;
        
        -- Safety check to prevent infinite loop
        IF counter > 1000 THEN
            RAISE EXCEPTION 'Unable to generate unique SKU after 1000 attempts';
        END IF;
    END LOOP;
    
    NEW.sku := new_sku;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_variant_sku ON public.product_variants;
CREATE TRIGGER trigger_generate_variant_sku
    BEFORE INSERT OR UPDATE ON public.product_variants
    FOR EACH ROW
    EXECUTE FUNCTION generate_variant_sku();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get total inventory for a product
CREATE OR REPLACE FUNCTION get_product_total_inventory(product_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(inventory_quantity), 0)
        FROM public.product_variants
        WHERE product_id = product_uuid
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to check if product has variants in stock
CREATE OR REPLACE FUNCTION product_has_stock(product_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.product_variants
        WHERE product_id = product_uuid
        AND status = 'active'
        AND inventory_quantity > 0
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get available sizes for a product and color
CREATE OR REPLACE FUNCTION get_available_sizes(product_uuid UUID, variant_color TEXT DEFAULT NULL)
RETURNS TEXT[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT size
        FROM public.product_variants
        WHERE product_id = product_uuid
        AND status = 'active'
        AND inventory_quantity > 0
        AND (variant_color IS NULL OR color = variant_color)
        ORDER BY 
            -- Custom sorting for common sizes
            CASE 
                WHEN size ~ '^\d+[SRL]?$' THEN CAST(REGEXP_REPLACE(size, '[^0-9]', '', 'g') AS INTEGER)
                ELSE 999 
            END,
            size
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get available colors for a product
CREATE OR REPLACE FUNCTION get_available_colors(product_uuid UUID)
RETURNS TEXT[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT color
        FROM public.product_variants
        WHERE product_id = product_uuid
        AND status = 'active'
        AND inventory_quantity > 0
        ORDER BY color
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to find variant by product, size, and color
CREATE OR REPLACE FUNCTION find_variant(product_uuid UUID, variant_size TEXT, variant_color TEXT)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT id
        FROM public.product_variants
        WHERE product_id = product_uuid
        AND size = variant_size
        AND color = variant_color
        AND status = 'active'
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- GRANTS
-- ============================================

-- Grant permissions
GRANT SELECT ON public.product_variants TO anon, authenticated;
GRANT ALL ON public.product_variants TO service_role;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION get_product_total_inventory(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION product_has_stock(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_available_sizes(UUID, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_available_colors(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION find_variant(UUID, TEXT, TEXT) TO anon, authenticated, service_role;

-- ============================================
-- SAMPLE DATA FOR TESTING
-- ============================================

-- Insert sample variants if products exist (for testing)
DO $$
DECLARE
    sample_product_id UUID;
    jacket_sizes TEXT[] := ARRAY['38R', '40R', '42R', '44R', '46R', '48R', '50R'];
    colors TEXT[] := ARRAY['Navy', 'Charcoal', 'Black'];
    size_item TEXT;
    color_item TEXT;
    base_price DECIMAL := 599.99;
BEGIN
    -- Get a sample product ID if any products exist
    SELECT id INTO sample_product_id FROM public.products LIMIT 1;
    
    IF sample_product_id IS NOT NULL THEN
        -- Create variants for each size and color combination
        FOREACH size_item IN ARRAY jacket_sizes
        LOOP
            FOREACH color_item IN ARRAY colors
            LOOP
                INSERT INTO public.product_variants (
                    product_id,
                    size,
                    color,
                    price,
                    inventory_quantity,
                    status,
                    position
                ) VALUES (
                    sample_product_id,
                    size_item,
                    color_item,
                    base_price + (CASE WHEN size_item IN ('48R', '50R') THEN 50.00 ELSE 0.00 END),
                    FLOOR(RANDOM() * 20) + 1, -- Random inventory 1-20
                    'active',
                    CASE size_item
                        WHEN '38R' THEN 1
                        WHEN '40R' THEN 2
                        WHEN '42R' THEN 3
                        WHEN '44R' THEN 4
                        WHEN '46R' THEN 5
                        WHEN '48R' THEN 6
                        WHEN '50R' THEN 7
                    END
                ) ON CONFLICT (product_id, size, color) DO NOTHING;
            END LOOP;
        END LOOP;
        
        RAISE NOTICE 'Sample variants created for product %', sample_product_id;
    ELSE
        RAISE NOTICE 'No products found - sample variants not created';
    END IF;
END;
$$;

-- ============================================
-- VALIDATION AND VERIFICATION
-- ============================================

-- Verify table creation and basic structure
DO $$
DECLARE
    table_exists BOOLEAN;
    index_count INTEGER;
    policy_count INTEGER;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'product_variants'
    ) INTO table_exists;
    
    -- Count indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public' AND tablename = 'product_variants';
    
    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'product_variants';
    
    RAISE NOTICE 'Product Variants Table: %', CASE WHEN table_exists THEN 'EXISTS' ELSE 'NOT FOUND' END;
    RAISE NOTICE 'Indexes created: %', index_count;
    RAISE NOTICE 'RLS policies: %', policy_count;
    
    IF table_exists AND index_count >= 8 AND policy_count >= 3 THEN
        RAISE NOTICE '✅ Product variants table setup completed successfully!';
    ELSE
        RAISE WARNING '⚠️ Product variants table setup may be incomplete';
    END IF;
END;
$$;

-- Show created objects summary
SELECT 
    'PRODUCT VARIANTS MIGRATION COMPLETED' as status,
    (SELECT COUNT(*) FROM public.product_variants) as variant_count,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'product_variants') as index_count,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'product_variants') as policy_count,
    (SELECT COUNT(*) FROM pg_proc WHERE proname LIKE '%product%variant%') as function_count;