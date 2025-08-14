-- FIX COLLECTIONS TABLE - Handle existing table with missing columns

-- 1. Check if collections table exists and what columns it has
SELECT 
    'Current collections table structure' as info,
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'collections'
ORDER BY ordinal_position;

-- 2. Add missing columns to existing collections table
ALTER TABLE collections 
ADD COLUMN IF NOT EXISTS slug VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES collections(id),
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS meta_title VARCHAR(200),
ADD COLUMN IF NOT EXISTS meta_description TEXT,
ADD COLUMN IF NOT EXISTS product_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS filters JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. Generate slugs for existing collections if they have names but no slugs
UPDATE collections
SET slug = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(name, '[^a-zA-Z0-9\s-]', ''), 
            '\s+', '-', 'g'
        ),
        '-+', '-', 'g'
    )
)
WHERE slug IS NULL AND name IS NOT NULL;

-- 4. Now safely insert collections (only if they don't exist)
INSERT INTO collections (slug, name, description, display_order) VALUES
('suits', 'Suits', 'Premium men''s suits for every occasion', 1),
('blazers', 'Blazers', 'Stylish blazers and sport coats', 2),
('shirts', 'Shirts', 'Dress shirts and formal wear', 3),
('vests', 'Vests & Waistcoats', 'Elegant vests and waistcoats', 4),
('accessories', 'Accessories', 'Ties, bow ties, and more', 5),
('wedding', 'Wedding', 'Complete wedding party solutions', 6),
('prom', 'Prom', 'Stand out at your special night', 7),
('bundles', 'Outfit Bundles', 'Complete outfit packages', 8),
('tuxedos', 'Tuxedos', 'Formal tuxedos for special events', 9),
('summer', 'Summer Collection', 'Lightweight summer wear', 10),
('velvet', 'Velvet Collection', 'Luxury velvet blazers and suits', 11),
('sparkle', 'Sparkle & Sequin', 'Eye-catching sparkle and sequin pieces', 12)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    display_order = EXCLUDED.display_order;

-- 5. Create other tables if they don't exist
-- PRODUCT_COLLECTIONS JUNCTION TABLE
CREATE TABLE IF NOT EXISTS product_collections (
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  display_order INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (product_id, collection_id)
);

-- CATEGORIES TABLE (separate from collections)
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

-- 6. Auto-populate product_collections based on current data
-- Clear any existing auto-assignments
TRUNCATE product_collections;

-- Assign products to collections based on their categories
WITH collection_mappings AS (
    SELECT 
        p.id as product_id,
        c.id as collection_id
    FROM products p
    CROSS JOIN collections c
    WHERE 
        (p.category ILIKE '%suit%' AND c.slug = 'suits')
        OR (p.category ILIKE '%blazer%' AND c.slug = 'blazers')
        OR (p.category ILIKE '%shirt%' AND c.slug = 'shirts')
        OR (p.category ILIKE '%vest%' AND c.slug = 'vests')
        OR (p.category ILIKE '%accessories%' AND c.slug = 'accessories')
        OR (p.category ILIKE '%tuxedo%' AND c.slug = 'tuxedos')
        OR (p.category ILIKE '%prom%' AND c.slug = 'prom')
        OR (p.category ILIKE '%summer%' AND c.slug = 'summer')
        OR (p.category ILIKE '%velvet%' AND c.slug = 'velvet')
        OR (p.category ILIKE '%sparkle%' OR p.category ILIKE '%sequin%' AND c.slug = 'sparkle')
)
INSERT INTO product_collections (product_id, collection_id)
SELECT product_id, collection_id FROM collection_mappings
ON CONFLICT DO NOTHING;

-- 7. Update collection counts
UPDATE collections c
SET product_count = (
    SELECT COUNT(DISTINCT pc.product_id)
    FROM product_collections pc
    JOIN products p ON p.id = pc.product_id
    WHERE pc.collection_id = c.id
    AND p.status = 'active'
);

-- 8. Verify the fix worked
SELECT 
    'Collections structure fixed' as status,
    COUNT(*) as total_collections,
    COUNT(slug) as collections_with_slugs,
    SUM(product_count) as total_products_assigned
FROM collections;

-- Show collection counts
SELECT 
    slug,
    name,
    product_count,
    display_order
FROM collections
ORDER BY display_order;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Collections table fixed!';
  RAISE NOTICE 'All missing columns added';
  RAISE NOTICE 'Collections populated with products';
END $$;