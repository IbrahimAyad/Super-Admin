-- =====================================================
-- STRIPE SYNC PROGRESS TRACKING FUNCTION
-- Adds database function for category-based progress tracking
-- =====================================================

-- Create function to get sync progress by category
CREATE OR REPLACE FUNCTION get_sync_progress_by_category()
RETURNS TABLE (
    category text,
    total_count bigint,
    synced_count bigint,
    pending_count bigint,
    failed_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(p.category, 'Unknown') as category,
        COUNT(*) as total_count,
        COUNT(p.stripe_product_id) as synced_count,
        COUNT(*) - COUNT(p.stripe_product_id) as pending_count,
        COUNT(*) FILTER (WHERE p.stripe_sync_status = 'failed') as failed_count
    FROM public.products p
    GROUP BY COALESCE(p.category, 'Unknown')
    ORDER BY total_count ASC; -- Smallest categories first for progressive sync
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_sync_progress_by_category() TO authenticated;
GRANT EXECUTE ON FUNCTION get_sync_progress_by_category() TO service_role;

-- Create helper function to get products ready for sync
CREATE OR REPLACE FUNCTION get_products_ready_for_sync(
    p_category text DEFAULT NULL,
    p_limit int DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    name text,
    category text,
    stripe_product_id text,
    stripe_sync_status text,
    variant_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        COALESCE(p.category, 'Unknown') as category,
        p.stripe_product_id,
        COALESCE(p.stripe_sync_status, 'pending') as stripe_sync_status,
        COUNT(pv.id) as variant_count
    FROM public.products p
    LEFT JOIN public.product_variants pv ON p.id = pv.product_id
    WHERE (p_category IS NULL OR p.category = p_category)
    AND p.status = 'active'
    GROUP BY p.id, p.name, p.category, p.stripe_product_id, p.stripe_sync_status
    HAVING COUNT(pv.id) > 0  -- Only products with variants
    ORDER BY 
        CASE WHEN p.stripe_product_id IS NULL THEN 0 ELSE 1 END,  -- Unsynced first
        p.created_at
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_products_ready_for_sync(text, int) TO authenticated;
GRANT EXECUTE ON FUNCTION get_products_ready_for_sync(text, int) TO service_role;

-- Update the sync summary view to be more comprehensive
CREATE OR REPLACE VIEW public.stripe_sync_summary AS
SELECT 
    COUNT(*) FILTER (WHERE stripe_product_id IS NOT NULL) as products_synced,
    COUNT(*) FILTER (WHERE stripe_product_id IS NULL) as products_pending,
    COUNT(*) FILTER (WHERE stripe_sync_status = 'failed') as products_failed,
    (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NOT NULL) as variants_synced,
    (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NULL) as variants_pending,
    (SELECT MAX(stripe_synced_at) FROM products) as last_sync_at,
    COUNT(*) as total_products,
    -- Calculate sync percentage
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(*) FILTER (WHERE stripe_product_id IS NOT NULL) * 100.0 / COUNT(*)), 2)
        ELSE 0 
    END as sync_percentage
FROM public.products
WHERE status = 'active';

-- Create index for better performance on sync queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_sync_status_category 
ON public.products(stripe_sync_status, category) 
WHERE status = 'active';

-- Create index for sync log queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stripe_sync_log_created_at 
ON public.stripe_sync_log(created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stripe_sync_log_entity_status 
ON public.stripe_sync_log(entity_id, status, created_at DESC);

-- Add helpful comments
COMMENT ON FUNCTION get_sync_progress_by_category() IS 'Returns sync progress statistics grouped by product category for monitoring dashboard';
COMMENT ON FUNCTION get_products_ready_for_sync(text, int) IS 'Returns products ready for sync, optionally filtered by category and limited by count';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Stripe sync progress functions created successfully!';
    RAISE NOTICE 'Available functions:';
    RAISE NOTICE '- get_sync_progress_by_category(): Category-based progress';
    RAISE NOTICE '- get_products_ready_for_sync(category, limit): Products ready for sync';
    RAISE NOTICE 'Updated stripe_sync_summary view with percentage calculation';
END $$;