-- =====================================================
-- SAFE STRIPE INTEGRATION MIGRATION
-- Adds Stripe fields to products and variants tables
-- This migration is REVERSIBLE and NON-DESTRUCTIVE
-- =====================================================

-- Step 1: Add Stripe fields to products table (nullable, no constraints)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS stripe_product_id TEXT;

COMMENT ON COLUMN public.products.stripe_product_id IS 'Stripe Product ID for payment processing - populated by sync function';

-- Step 2: Add Stripe fields to product_variants table (nullable, no constraints)
ALTER TABLE public.product_variants 
ADD COLUMN IF NOT EXISTS stripe_price_id TEXT;

COMMENT ON COLUMN public.product_variants.stripe_price_id IS 'Stripe Price ID for checkout - populated by sync function';

-- Step 3: Add indexes for performance (CONCURRENTLY to avoid locking)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_stripe_id 
ON public.products(stripe_product_id) 
WHERE stripe_product_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_variants_stripe_price_id 
ON public.product_variants(stripe_price_id) 
WHERE stripe_price_id IS NOT NULL;

-- Step 4: Add sync status tracking columns
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS stripe_sync_status TEXT DEFAULT 'pending' 
CHECK (stripe_sync_status IN ('pending', 'synced', 'failed', 'skip'));

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS stripe_sync_error TEXT;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS stripe_synced_at TIMESTAMPTZ;

-- Step 5: Create sync tracking table for audit trail
CREATE TABLE IF NOT EXISTS public.stripe_sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sync_type TEXT NOT NULL CHECK (sync_type IN ('product', 'variant', 'price', 'full')),
    entity_id UUID,
    entity_type TEXT CHECK (entity_type IN ('product', 'variant')),
    stripe_id TEXT,
    action TEXT CHECK (action IN ('create', 'update', 'skip', 'error')),
    status TEXT CHECK (status IN ('success', 'failed', 'pending')),
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by TEXT DEFAULT CURRENT_USER
);

-- Step 6: Create view for products needing sync
CREATE OR REPLACE VIEW public.products_pending_stripe_sync AS
SELECT 
    p.id,
    p.name,
    p.sku,
    p.description,
    p.base_price,
    p.stripe_product_id,
    p.stripe_sync_status,
    COUNT(pv.id) as variant_count,
    COUNT(pv.stripe_price_id) as synced_variant_count
FROM public.products p
LEFT JOIN public.product_variants pv ON p.id = pv.product_id
WHERE p.stripe_sync_status = 'pending' 
   OR p.stripe_product_id IS NULL
GROUP BY p.id, p.name, p.sku, p.description, p.base_price, p.stripe_product_id, p.stripe_sync_status;

-- Step 7: Create helper function to validate Stripe IDs
CREATE OR REPLACE FUNCTION validate_stripe_id(stripe_id TEXT, id_type TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF stripe_id IS NULL THEN
        RETURN TRUE; -- NULL is valid (not synced yet)
    END IF;
    
    -- Validate Stripe ID format
    IF id_type = 'product' THEN
        RETURN stripe_id ~ '^prod_[a-zA-Z0-9]{14,}$';
    ELSIF id_type = 'price' THEN
        RETURN stripe_id ~ '^price_[a-zA-Z0-9]{14,}$';
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Add validation triggers (disabled by default - enable when ready)
CREATE OR REPLACE FUNCTION validate_stripe_product_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT validate_stripe_id(NEW.stripe_product_id, 'product') THEN
        RAISE EXCEPTION 'Invalid Stripe product ID format: %', NEW.stripe_product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_stripe_price_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT validate_stripe_id(NEW.stripe_price_id, 'price') THEN
        RAISE EXCEPTION 'Invalid Stripe price ID format: %', NEW.stripe_price_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers are created but DISABLED by default for safety
-- Uncomment these lines when you're ready to enforce validation:
-- CREATE TRIGGER validate_product_stripe_id 
--     BEFORE INSERT OR UPDATE ON public.products
--     FOR EACH ROW EXECUTE FUNCTION validate_stripe_product_id();

-- CREATE TRIGGER validate_variant_stripe_price_id 
--     BEFORE INSERT OR UPDATE ON public.product_variants
--     FOR EACH ROW EXECUTE FUNCTION validate_stripe_price_id();

-- Step 9: Add RLS policies for sync operations
ALTER TABLE public.stripe_sync_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view sync logs" ON public.stripe_sync_log
    FOR SELECT USING (
        auth.jwt() ->> 'email' IN (
            SELECT email FROM public.admin_users WHERE role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Service role can manage sync logs" ON public.stripe_sync_log
    FOR ALL USING (auth.role() = 'service_role');

-- Step 10: Create summary view for monitoring
CREATE OR REPLACE VIEW public.stripe_sync_summary AS
SELECT 
    COUNT(*) FILTER (WHERE stripe_product_id IS NOT NULL) as products_synced,
    COUNT(*) FILTER (WHERE stripe_product_id IS NULL) as products_pending,
    COUNT(*) FILTER (WHERE stripe_sync_status = 'failed') as products_failed,
    (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NOT NULL) as variants_synced,
    (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NULL) as variants_pending,
    (SELECT MAX(stripe_synced_at) FROM products) as last_sync_at
FROM public.products;

-- =====================================================
-- ROLLBACK SCRIPT (Save this separately)
-- =====================================================
-- To completely reverse this migration, run:
/*
-- Remove columns from products
ALTER TABLE public.products 
DROP COLUMN IF EXISTS stripe_product_id,
DROP COLUMN IF EXISTS stripe_sync_status,
DROP COLUMN IF EXISTS stripe_sync_error,
DROP COLUMN IF EXISTS stripe_synced_at;

-- Remove columns from variants
ALTER TABLE public.product_variants 
DROP COLUMN IF EXISTS stripe_price_id;

-- Drop indexes
DROP INDEX IF EXISTS idx_products_stripe_id;
DROP INDEX IF EXISTS idx_variants_stripe_price_id;

-- Drop views
DROP VIEW IF EXISTS public.products_pending_stripe_sync;
DROP VIEW IF EXISTS public.stripe_sync_summary;

-- Drop functions
DROP FUNCTION IF EXISTS validate_stripe_id(TEXT, TEXT);
DROP FUNCTION IF EXISTS validate_stripe_product_id();
DROP FUNCTION IF EXISTS validate_stripe_price_id();

-- Drop sync log table
DROP TABLE IF EXISTS public.stripe_sync_log;
*/

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Stripe fields migration completed successfully!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run sync-stripe-products Edge Function to populate IDs';
    RAISE NOTICE '2. Monitor progress via stripe_sync_summary view';
    RAISE NOTICE '3. Enable validation triggers when ready';
END $$;