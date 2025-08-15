-- =====================================================
-- FIX: Add missing analytics columns to products_enhanced
-- Run this before Step 4
-- =====================================================

-- Add analytics columns if they don't exist
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS add_to_cart_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS purchase_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS return_rate DECIMAL(5,2) DEFAULT 0;

-- Verify columns were added
SELECT 'Analytics columns added successfully' as status;

-- Now create the analytics view (simplified version)
CREATE OR REPLACE VIEW product_tier_analytics AS
SELECT 
  pt.tier_number,
  pt.tier_name,
  pt.display_range,
  pt.color_code,
  pt.positioning,
  COUNT(pe.id) as product_count,
  COALESCE(AVG(pe.base_price), 0) as avg_price_cents,
  COALESCE(MIN(pe.base_price), 0) as min_price_cents,
  COALESCE(MAX(pe.base_price), 0) as max_price_cents,
  COALESCE(SUM(pe.view_count), 0) as total_views,
  COALESCE(SUM(pe.purchase_count), 0) as total_purchases,
  COALESCE(AVG(pe.return_rate), 0) as avg_return_rate
FROM price_tiers pt
LEFT JOIN products_enhanced pe ON pe.price_tier = pt.tier_id
GROUP BY pt.tier_id, pt.tier_number, pt.tier_name, pt.display_range, pt.color_code, pt.positioning
ORDER BY pt.tier_number;

-- Create Stripe sync tracking table if not exists
CREATE TABLE IF NOT EXISTS stripe_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products_enhanced(id),
  action VARCHAR(50) NOT NULL,
  stripe_product_id VARCHAR(255),
  stripe_price_id VARCHAR(255),
  status VARCHAR(20) NOT NULL,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grant permissions
GRANT ALL ON stripe_sync_log TO authenticated;
GRANT SELECT ON product_tier_analytics TO authenticated, anon;

-- Final verification
SELECT 
  'SETUP COMPLETE' as status,
  (SELECT COUNT(*) FROM price_tiers) as total_tiers,
  (SELECT COUNT(*) FROM products_enhanced) as total_products,
  (SELECT COUNT(*) FROM products_enhanced WHERE price_tier IS NOT NULL) as products_with_tiers;

-- Show tier distribution
SELECT 
  tier_number,
  tier_name,
  display_range,
  product_count
FROM product_tier_analytics
ORDER BY tier_number;