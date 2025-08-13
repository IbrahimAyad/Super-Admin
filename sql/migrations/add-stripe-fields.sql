-- Add Stripe integration fields to products and variants
-- This migration adds the necessary fields to link Supabase products with Stripe

BEGIN;

-- Add Stripe fields to products table if they don't exist
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS stripe_product_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS stripe_active BOOLEAN DEFAULT false;

-- Add Stripe fields to product_variants table if they don't exist
ALTER TABLE product_variants
ADD COLUMN IF NOT EXISTS stripe_price_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS stripe_active BOOLEAN DEFAULT false;

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_products_stripe_product_id ON products(stripe_product_id) WHERE stripe_product_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_product_variants_stripe_price_id ON product_variants(stripe_price_id) WHERE stripe_price_id IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN products.stripe_product_id IS 'Stripe Product ID (prod_xxx) for syncing with Stripe';
COMMENT ON COLUMN products.stripe_active IS 'Whether this product is active in Stripe';
COMMENT ON COLUMN product_variants.stripe_price_id IS 'Stripe Price ID (price_xxx) for checkout';
COMMENT ON COLUMN product_variants.stripe_active IS 'Whether this price is active in Stripe';

COMMIT;

-- Check current status
SELECT 
    COUNT(*) as total_products,
    COUNT(stripe_product_id) as products_with_stripe,
    COUNT(*) - COUNT(stripe_product_id) as products_needing_stripe
FROM products
WHERE status = 'active';

SELECT 
    COUNT(*) as total_variants,
    COUNT(stripe_price_id) as variants_with_stripe,
    COUNT(*) - COUNT(stripe_price_id) as variants_needing_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';