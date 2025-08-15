-- INSERT REAL ENHANCED PRODUCTS WITH ACTUAL CDN IMAGES
-- These products use your actual uploaded images

-- 1. Black Paisley Pattern Velvet Blazer
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
  'Men''s Black Paisley Pattern Velvet Blazer',
  'VB-002-BLK-PAISLEY',
  'mens-black-paisley-pattern-velvet-blazer',
  'FW24-VB-002',
  'FW24',
  'Luxury Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',  -- $300-399 range
  34999,     -- $349.99
  44999,     -- $449.99 compare at
  'Black',
  'Black Paisley',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 80, "Polyester": 20}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Black Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [],
    "details": [],
    "variants": {},
    "total_images": 1
  }'::jsonb,
  'Luxurious black velvet blazer featuring an intricate paisley pattern. Perfect for formal events and special occasions.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 2. Men's Blue Casual Summer Blazer
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
  'Men''s Blue Casual Summer Blazer',
  'SB-001-BLU',
  'mens-blue-casual-summer-blazer',
  'SS24-SB-001',
  'SS24',
  'Summer Essentials',
  'Blazers',
  'Summer',
  'TIER_6',  -- $200-249 range
  22999,     -- $229.99
  29999,     -- $299.99 compare at
  'Blue',
  'Sky Blue',
  '{"primary": "Linen Blend", "composition": {"Linen": 60, "Cotton": 40}}'::jsonb,
  'Relaxed Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/main.webp",
      "alt": "Blue Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/back.webp",
        "alt": "Blue Casual Summer Blazer - Back View"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/side.webp",
        "alt": "Blue Casual Summer Blazer - Side View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/front-close.webp",
        "alt": "Blue Casual Summer Blazer - Front Close-up"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/close-side.webp",
        "alt": "Blue Casual Summer Blazer - Side Detail"
      }
    ],
    "variants": {},
    "total_images": 5
  }'::jsonb,
  'Lightweight and breathable summer blazer in a beautiful sky blue. Perfect for casual summer events and beach weddings.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 3. Add more products as needed using the same pattern
-- Just update the image URLs to match your CDN structure

-- Verify the products were added
SELECT 
  name,
  sku,
  category || '/' || subcategory as category_path,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->'hero'->>'url' as hero_image,
  jsonb_array_length(COALESCE(images->'lifestyle', '[]'::jsonb)) as lifestyle_images,
  jsonb_array_length(COALESCE(images->'details', '[]'::jsonb)) as detail_images,
  (images->>'total_images')::int as total_images,
  status
FROM products_enhanced
WHERE status = 'active'
ORDER BY created_at DESC;

-- Check image URLs are accessible
SELECT 
  name,
  jsonb_pretty(images) as image_structure
FROM products_enhanced
WHERE sku IN ('VB-002-BLK-PAISLEY', 'SB-001-BLU');