-- FIXED VERSION - Checks for existing columns and handles missing ones
-- Run this before the website team's full SQL

-- 1. First, check what columns actually exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- 2. Add slug column if it doesn't exist (website needs this)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS slug VARCHAR(200);

-- Generate slugs from existing names
UPDATE products
SET slug = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(name, '[^a-zA-Z0-9\s-]', ''), -- Remove special chars
            '\s+', '-', 'g' -- Replace spaces with hyphens
        ),
        '-+', '-', 'g' -- Remove duplicate hyphens
    )
)
WHERE slug IS NULL OR slug = '';

-- Handle duplicate slugs
WITH numbered_slugs AS (
    SELECT id, slug,
           slug || '-' || ROW_NUMBER() OVER (PARTITION BY slug ORDER BY created_at) as new_slug,
           ROW_NUMBER() OVER (PARTITION BY slug ORDER BY created_at) as rn
    FROM products
    WHERE slug IS NOT NULL
)
UPDATE products p
SET slug = ns.new_slug
FROM numbered_slugs ns
WHERE p.id = ns.id AND ns.rn > 1;

-- 3. Add visibility column if missing (referenced in their functions)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS visibility BOOLEAN DEFAULT true;

-- 4. Now run their full SQL (but with safety checks)
-- ENHANCED PRODUCTS TABLE with safety checks
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS master_category VARCHAR(100),
ADD COLUMN IF NOT EXISTS subcategory VARCHAR(100),
ADD COLUMN IF NOT EXISTS collection VARCHAR(100),
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS smart_tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS color_family VARCHAR(50),
ADD COLUMN IF NOT EXISTS occasions TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS materials TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS search_keywords TEXT,
ADD COLUMN IF NOT EXISTS ai_score INTEGER DEFAULT 50,
ADD COLUMN IF NOT EXISTS trending BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS featured BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS seasonal VARCHAR(20),
ADD COLUMN IF NOT EXISTS fit_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS style_profile VARCHAR(50),
ADD COLUMN IF NOT EXISTS bundle_components JSONB,
ADD COLUMN IF NOT EXISTS gallery_images TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS size_chart JSONB,
ADD COLUMN IF NOT EXISTS care_instructions TEXT,
ADD COLUMN IF NOT EXISTS import_batch VARCHAR(50),
ADD COLUMN IF NOT EXISTS csv_row_number INTEGER,
ADD COLUMN IF NOT EXISTS last_synced TIMESTAMP WITH TIME ZONE;

-- 5. Create tables only if they don't exist
-- COLLECTIONS TABLE
CREATE TABLE IF NOT EXISTS collections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  image_url TEXT,
  parent_id UUID REFERENCES collections(id),
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  meta_title VARCHAR(200),
  meta_description TEXT,
  product_count INTEGER DEFAULT 0,
  filters JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PRODUCT_COLLECTIONS JUNCTION TABLE
CREATE TABLE IF NOT EXISTS product_collections (
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  display_order INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (product_id, collection_id)
);

-- CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  parent_id UUID REFERENCES categories(id),
  level INTEGER DEFAULT 0,
  path TEXT,
  image_url TEXT,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  product_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- IMPORT_LOGS TABLE
CREATE TABLE IF NOT EXISTS import_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  batch_id VARCHAR(50) NOT NULL,
  file_name VARCHAR(200),
  total_rows INTEGER,
  successful_rows INTEGER,
  failed_rows INTEGER,
  errors JSONB DEFAULT '[]',
  status VARCHAR(50) DEFAULT 'pending',
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);

-- COLOR_MAPPINGS TABLE
CREATE TABLE IF NOT EXISTS color_mappings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  color_name VARCHAR(100) UNIQUE NOT NULL,
  color_family VARCHAR(50) NOT NULL,
  hex_code VARCHAR(7),
  synonyms TEXT[] DEFAULT '{}',
  is_primary BOOLEAN DEFAULT FALSE
);

-- 6. Create indexes (safe with IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_products_slug ON products(slug);
CREATE INDEX IF NOT EXISTS idx_products_master_category ON products(master_category);
CREATE INDEX IF NOT EXISTS idx_products_subcategory ON products(subcategory);
CREATE INDEX IF NOT EXISTS idx_products_collection ON products(collection);
CREATE INDEX IF NOT EXISTS idx_products_tags ON products USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_products_smart_tags ON products USING GIN(smart_tags);
CREATE INDEX IF NOT EXISTS idx_products_occasions ON products USING GIN(occasions);
CREATE INDEX IF NOT EXISTS idx_products_materials ON products USING GIN(materials);
CREATE INDEX IF NOT EXISTS idx_products_color_family ON products(color_family);
CREATE INDEX IF NOT EXISTS idx_products_trending ON products(trending) WHERE trending = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(featured) WHERE featured = TRUE;

-- 7. Populate initial data
-- COLOR MAPPINGS
INSERT INTO color_mappings (color_name, color_family, hex_code, synonyms, is_primary) VALUES
('navy', 'blue', '#000080', ARRAY['navy blue', 'dark blue', 'midnight'], true),
('royal-blue', 'blue', '#4169E1', ARRAY['royal', 'bright blue'], false),
('black', 'black', '#000000', ARRAY['onyx', 'jet', 'ebony'], true),
('charcoal', 'grey', '#36454F', ARRAY['dark grey', 'charcoal grey'], false),
('grey', 'grey', '#808080', ARRAY['gray', 'silver'], true),
('burgundy', 'red', '#800020', ARRAY['wine', 'maroon', 'bordeaux'], false),
('white', 'white', '#FFFFFF', ARRAY['ivory', 'cream', 'off-white'], true),
('brown', 'brown', '#964B00', ARRAY['chocolate', 'coffee'], true),
('tan', 'brown', '#D2B48C', ARRAY['beige', 'khaki', 'sand'], false),
('emerald', 'green', '#50C878', ARRAY['emerald green', 'jewel green'], false),
('forest-green', 'green', '#228B22', ARRAY['forest', 'hunter green'], false),
('gold', 'yellow', '#FFD700', ARRAY['golden', 'champagne'], false),
('silver', 'grey', '#C0C0C0', ARRAY['metallic', 'chrome'], false),
('red', 'red', '#FF0000', ARRAY['crimson', 'scarlet'], true),
('pink', 'pink', '#FFC0CB', ARRAY['rose', 'blush', 'salmon'], true),
('purple', 'purple', '#800080', ARRAY['violet', 'plum', 'lavender'], true),
('orange', 'orange', '#FFA500', ARRAY['coral', 'peach'], true),
('blue', 'blue', '#0000FF', ARRAY['light blue', 'sky blue'], true)
ON CONFLICT (color_name) DO NOTHING;

-- INITIAL COLLECTIONS
INSERT INTO collections (slug, name, description, display_order) VALUES
('suits', 'Suits', 'Premium men''s suits for every occasion', 1),
('blazers', 'Blazers', 'Stylish blazers and sport coats', 2),
('shirts', 'Shirts', 'Dress shirts and formal wear', 3),
('vests', 'Vests & Waistcoats', 'Elegant vests and waistcoats', 4),
('accessories', 'Accessories', 'Ties, bow ties, and more', 5),
('wedding', 'Wedding', 'Complete wedding party solutions', 6),
('prom', 'Prom', 'Stand out at your special night', 7),
('bundles', 'Outfit Bundles', 'Complete outfit packages', 8)
ON CONFLICT (slug) DO NOTHING;

-- 8. Verify everything was created
SELECT 
    'Products table columns' as check_type,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'products'
UNION ALL
SELECT 
    'Collections created',
    COUNT(*)
FROM collections
UNION ALL
SELECT 
    'Color mappings created',
    COUNT(*)
FROM color_mappings;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Database preparation complete!';
  RAISE NOTICE 'All missing columns added safely';
  RAISE NOTICE 'Collections system initialized';
  RAISE NOTICE 'Ready for enhanced functionality';
END $$;