-- Create missing Stripe sync functions

-- 1. Create stripe_sync_summary function
CREATE OR REPLACE FUNCTION stripe_sync_summary()
RETURNS TABLE (
  total_products INTEGER,
  synced_products INTEGER,
  failed_products INTEGER,
  last_sync_at TIMESTAMPTZ,
  sync_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_products,
    COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END)::INTEGER as synced_products,
    0::INTEGER as failed_products,
    MAX(updated_at) as last_sync_at,
    CASE 
      WHEN COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END) = COUNT(*) THEN 'completed'
      WHEN COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END) > 0 THEN 'partial'
      ELSE 'pending'
    END as sync_status
  FROM products
  WHERE deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- 2. Create get_sync_progress_by_category function
CREATE OR REPLACE FUNCTION get_sync_progress_by_category()
RETURNS TABLE (
  category TEXT,
  total INTEGER,
  synced INTEGER,
  progress NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(p.category, 'Uncategorized') as category,
    COUNT(*)::INTEGER as total,
    COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END)::INTEGER as synced,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END as progress
  FROM products p
  WHERE p.deleted_at IS NULL
  GROUP BY p.category
  ORDER BY p.category;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION stripe_sync_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_sync_progress_by_category() TO authenticated;

-- Test the functions
SELECT * FROM stripe_sync_summary();
SELECT * FROM get_sync_progress_by_category();