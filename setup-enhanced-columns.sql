-- Add missing columns to products_enhanced table
-- This will ensure all fields from our enhanced form are supported

-- Fashion-Specific Fields
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS product_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS occasion JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS cost_per_unit INTEGER DEFAULT 0;

-- Fashion Attributes
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS care_instructions TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS size_range JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS measurements JSONB DEFAULT '{}'::jsonb;

-- Inventory & Status
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS launch_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS discontinue_date TIMESTAMPTZ;

-- Analytics Fields
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS add_to_cart_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS purchase_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS return_rate DECIMAL(5,2) DEFAULT 0;

-- SEO Fields  
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS meta_keywords TEXT[],
ADD COLUMN IF NOT EXISTS search_terms TEXT,
ADD COLUMN IF NOT EXISTS url_slug VARCHAR(255),
ADD COLUMN IF NOT EXISTS canonical_url TEXT,
ADD COLUMN IF NOT EXISTS og_image TEXT,
ADD COLUMN IF NOT EXISTS structured_data JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS is_indexable BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sitemap_priority DECIMAL(2,1) DEFAULT 0.8,
ADD COLUMN IF NOT EXISTS sitemap_change_freq VARCHAR(20) DEFAULT 'weekly';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_enhanced_product_type ON products_enhanced(product_type);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_is_available ON products_enhanced(is_available);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_launch_date ON products_enhanced(launch_date);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_view_count ON products_enhanced(view_count DESC);

-- Update existing products with default values where needed
UPDATE products_enhanced 
SET 
  is_available = true,
  view_count = 0,
  add_to_cart_count = 0,
  purchase_count = 0,
  return_rate = 0,
  is_indexable = true,
  sitemap_priority = 0.8,
  sitemap_change_freq = 'weekly'
WHERE is_available IS NULL OR view_count IS NULL;

SELECT 'Enhanced columns added successfully!' as status;