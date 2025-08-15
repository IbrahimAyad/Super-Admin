-- QUICK ENHANCED PRODUCTS TABLE CREATION
-- Run this in Supabase SQL Editor

-- Create enhanced products table
CREATE TABLE IF NOT EXISTS products_enhanced (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core product info
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) UNIQUE NOT NULL,
  handle VARCHAR(255) UNIQUE NOT NULL,
  style_code VARCHAR(50),
  season VARCHAR(50),
  collection VARCHAR(100),
  
  -- Categories
  category VARCHAR(100) NOT NULL,
  subcategory VARCHAR(100),
  
  -- 20-tier pricing
  price_tier VARCHAR(50) NOT NULL DEFAULT 'TIER_1',
  base_price INTEGER NOT NULL,
  compare_at_price INTEGER,
  
  -- Fashion attributes
  color_family VARCHAR(50),
  color_name VARCHAR(100),
  materials JSONB DEFAULT '{}'::jsonb,
  fit_type VARCHAR(50),
  
  -- Enhanced images (JSONB)
  images JSONB DEFAULT '{
    "hero": null,
    "flat": null,
    "lifestyle": [],
    "details": [],
    "variants": {},
    "total_images": 0
  }'::jsonb,
  
  -- Content
  description TEXT,
  
  -- Status
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  
  -- Stripe
  stripe_product_id VARCHAR(255),
  stripe_active BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_products_enhanced_status ON products_enhanced(status);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_category ON products_enhanced(category);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_sku ON products_enhanced(sku);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_images ON products_enhanced USING gin(images);

-- Create price tiers table
CREATE TABLE IF NOT EXISTS price_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  tier_number INTEGER UNIQUE NOT NULL,
  min_price INTEGER NOT NULL,
  max_price INTEGER,
  display_range VARCHAR(50) NOT NULL
);

-- Insert price tiers
INSERT INTO price_tiers (tier_id, tier_number, min_price, max_price, display_range) VALUES
  ('TIER_1', 1, 5000, 7499, '$50-74'),
  ('TIER_2', 2, 7500, 9999, '$75-99'),
  ('TIER_3', 3, 10000, 12499, '$100-124'),
  ('TIER_4', 4, 12500, 14999, '$125-149'),
  ('TIER_5', 5, 15000, 19999, '$150-199'),
  ('TIER_6', 6, 20000, 24999, '$200-249'),
  ('TIER_7', 7, 25000, 29999, '$250-299'),
  ('TIER_8', 8, 30000, 39999, '$300-399'),
  ('TIER_9', 9, 40000, 49999, '$400-499'),
  ('TIER_10', 10, 50000, 59999, '$500-599'),
  ('TIER_11', 11, 60000, 69999, '$600-699'),
  ('TIER_12', 12, 70000, 79999, '$700-799'),
  ('TIER_13', 13, 80000, 89999, '$800-899'),
  ('TIER_14', 14, 90000, 99999, '$900-999'),
  ('TIER_15', 15, 100000, 124999, '$1000-1249'),
  ('TIER_16', 16, 125000, 149999, '$1250-1499'),
  ('TIER_17', 17, 150000, 199999, '$1500-1999'),
  ('TIER_18', 18, 200000, 299999, '$2000-2999'),
  ('TIER_19', 19, 300000, 499999, '$3000-4999'),
  ('TIER_20', 20, 500000, 999999999, '$5000+')
ON CONFLICT (tier_id) DO NOTHING;

-- Enable RLS
ALTER TABLE products_enhanced ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view active products" 
ON products_enhanced FOR SELECT 
USING (status = 'active');

CREATE POLICY "Admins can manage all products" 
ON products_enhanced FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
    AND is_active = true
  )
);

-- Insert test product
INSERT INTO products_enhanced (
  name,
  sku,
  handle,
  style_code,
  season,
  collection,
  category,
  subcategory,
  price_tier,
  base_price,
  compare_at_price,
  color_family,
  color_name,
  materials,
  fit_type,
  images,
  description,
  status
) VALUES (
  'Premium Velvet Blazer - Midnight Navy',
  'VB-001-NVY',
  'premium-velvet-blazer-navy',
  'FW24-VB-001',
  'FW24',
  'Luxury Essentials',
  'Blazers',
  'Formal',
  'TIER_8',
  34900,
  44900,
  'Blue',
  'Midnight Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/main.webp",
      "alt": "Premium Velvet Blazer Navy - Hero"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/flat.webp",
      "alt": "Premium Velvet Blazer Navy - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/back.webp",
        "alt": "Back View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/detail-1.webp",
        "alt": "Fabric Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'A luxurious velvet blazer perfect for formal occasions. Made from premium cotton velvet with silk lining.',
  'active'
);

-- Verify creation
SELECT 'Enhanced Products System Created Successfully!' as status;
SELECT COUNT(*) as enhanced_products FROM products_enhanced;
SELECT COUNT(*) as price_tiers FROM price_tiers;