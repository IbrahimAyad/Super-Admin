-- Fix remaining function issues

-- 1. Fix get_sync_progress_by_category (400 error)
DROP FUNCTION IF EXISTS get_sync_progress_by_category();
CREATE OR REPLACE FUNCTION get_sync_progress_by_category()
RETURNS TABLE (
  category TEXT,
  total INTEGER,
  synced INTEGER,
  progress NUMERIC
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(p.category, 'Uncategorized')::TEXT as category,
    COUNT(*)::INTEGER as total,
    COUNT(CASE WHEN p.stripe_product_id IS NOT NULL THEN 1 END)::INTEGER as synced,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(CASE WHEN p.stripe_product_id IS NOT NULL THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END as progress
  FROM products p
  WHERE p.deleted_at IS NULL
  GROUP BY p.category
  ORDER BY p.category;
END;
$$ LANGUAGE plpgsql;

-- 2. Create reviews table if missing
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  customer_id UUID,
  customer_name TEXT,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Create policy for reviews
CREATE POLICY "Allow all operations for authenticated users on reviews"
ON reviews
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Fix products query permissions
DROP POLICY IF EXISTS "Allow read access to products for all" ON products;
CREATE POLICY "Allow read access to products for all"
ON products
FOR SELECT
TO authenticated, anon
USING (deleted_at IS NULL);

-- 4. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- 5. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_products_stripe_product_id ON products(stripe_product_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON products(deleted_at);

-- Test the functions
SELECT * FROM get_sync_progress_by_category() LIMIT 5;