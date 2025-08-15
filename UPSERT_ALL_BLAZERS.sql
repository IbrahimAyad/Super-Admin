-- UPSERT ALL BLAZERS - HANDLES DUPLICATES PROPERLY
-- This will update existing products or insert new ones

-- First, let's see what we have
SELECT 
  'Current Blazers' as status,
  COUNT(*) as count,
  STRING_AGG(DISTINCT subcategory, ', ') as categories
FROM products_enhanced 
WHERE category = 'Blazers';

-- For each product, we'll use handle as the unique identifier
-- Since handle is what matches your folder names

-- Example of safe upsert for first few products
-- This checks handle instead of sku

-- 1. Black Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Floral Pattern Prom Blazer',
  'PB-001-BLK-FLORAL',
  'mens-black-floral-pattern-prom-blazer',
  'mens-black-floral-pattern-prom-blazer',
  'PROM24-001',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34999,
  'Black',
  'Black with Floral',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/main-2.webp",
      "alt": "Black Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Black Floral Prom Blazer - Lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/back.webp",
        "alt": "Black Floral Prom Blazer - Back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/side.webp",
        "alt": "Black Floral Prom Blazer - Side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/front-close.webp",
        "alt": "Front Close-up"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Side Detail"
      }
    ],
    "total_images": 6
  }'::jsonb,
  'Stand out at prom with this elegant black blazer featuring intricate floral patterns.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = EXCLUDED.sku,
  slug = EXCLUDED.slug,
  style_code = EXCLUDED.style_code,
  season = EXCLUDED.season,
  collection = EXCLUDED.collection,
  subcategory = EXCLUDED.subcategory,
  price_tier = EXCLUDED.price_tier,
  base_price = EXCLUDED.base_price,
  compare_at_price = EXCLUDED.compare_at_price,
  color_family = EXCLUDED.color_family,
  color_name = EXCLUDED.color_name,
  materials = EXCLUDED.materials,
  fit_type = EXCLUDED.fit_type,
  images = EXCLUDED.images,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  updated_at = NOW();

-- Let me create a better solution that generates all products
-- But first, let's check which handles already exist

WITH existing_handles AS (
  SELECT handle 
  FROM products_enhanced 
  WHERE category = 'Blazers'
)
SELECT 
  'Existing Handles' as info,
  COUNT(*) as count,
  STRING_AGG(handle, ', ' ORDER BY handle) as handles
FROM existing_handles;