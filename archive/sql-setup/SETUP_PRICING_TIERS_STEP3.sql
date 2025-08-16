-- =====================================================
-- STEP 3: ADD STRIPE COLUMNS & CREATE FUNCTIONS
-- Run this after Step 2 succeeds
-- =====================================================

-- Add Stripe columns to products_enhanced if they don't exist
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS stripe_product_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS stripe_price_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS stripe_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS stripe_metadata JSONB DEFAULT '{}'::jsonb;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_stripe_product ON products_enhanced(stripe_product_id) WHERE stripe_product_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_stripe_price ON products_enhanced(stripe_price_id) WHERE stripe_price_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_price_tier ON products_enhanced(price_tier);

-- Create function to assign price tier based on price
CREATE OR REPLACE FUNCTION assign_price_tier(price_cents INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
  RETURN (
    SELECT tier_id 
    FROM price_tiers 
    WHERE price_cents >= min_price 
      AND (max_price IS NULL OR price_cents <= max_price)
    ORDER BY tier_number DESC
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql;

-- Create trigger function for auto-assigning tiers
CREATE OR REPLACE FUNCTION update_price_tier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.base_price IS NOT NULL THEN
    NEW.price_tier = assign_price_tier(NEW.base_price);
  END IF;
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists and create new one
DROP TRIGGER IF EXISTS auto_assign_price_tier ON products_enhanced;
CREATE TRIGGER auto_assign_price_tier
BEFORE INSERT OR UPDATE OF base_price ON products_enhanced
FOR EACH ROW
EXECUTE FUNCTION update_price_tier();

-- Update existing products with price tiers
UPDATE products_enhanced 
SET price_tier = assign_price_tier(base_price)
WHERE price_tier IS NULL OR price_tier = '';

-- Verify setup
SELECT 
  COUNT(*) as total_products,
  COUNT(price_tier) as products_with_tiers,
  COUNT(stripe_product_id) as products_in_stripe,
  'Setup completed successfully' as status
FROM products_enhanced;