-- INSERT ALL BLAZERS USING YOUR CDN FOLDER STRUCTURE
-- Based on your actual Cloudflare R2 bucket organization

-- Clear existing products if needed (optional)
-- DELETE FROM products_enhanced WHERE category = 'Blazers';

-- ============================================
-- VELVET BLAZERS
-- ============================================

-- 1. Black Paisley Pattern Velvet Blazer (Already exists, update if needed)
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Paisley Pattern Velvet Blazer',
  'VB-002-BLK-PAISLEY',
  'mens-black-paisley-pattern-velvet-blazer',
  'mens-black-paisley-pattern-velvet-blazer',
  'FW24-VB-002',
  'FW24',
  'Luxury Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  44999,
  'Black',
  'Black Paisley',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 80, "Polyester": 20}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Black Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/flat.webp",
      "alt": "Black Paisley Pattern Velvet Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/back.webp",
        "alt": "Black Paisley Pattern Velvet Blazer - Back View"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/side.webp",
        "alt": "Black Paisley Pattern Velvet Blazer - Side View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/detail-1.webp",
        "alt": "Paisley Pattern Detail"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/detail-2.webp",
        "alt": "Button and Lapel Detail"
      }
    ],
    "total_images": 6
  }'::jsonb,
  'Luxurious black velvet blazer featuring an intricate paisley pattern. Perfect for formal events and special occasions.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 2. Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Blue Velvet Blazer',
  'VB-003-NAVY',
  'mens-navy-blue-velvet-blazer',
  'mens-navy-blue-velvet-blazer',
  'FW24-VB-003',
  'FW24',
  'Luxury Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  44999,
  'Blue',
  'Navy Blue',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-blue-velvet-blazer/main.webp",
      "alt": "Navy Blue Velvet Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-blue-velvet-blazer/flat.webp",
      "alt": "Navy Blue Velvet Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-blue-velvet-blazer/back.webp",
        "alt": "Navy Blue Velvet Blazer - Back View"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-blue-velvet-blazer/side.webp",
        "alt": "Navy Blue Velvet Blazer - Side View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-blue-velvet-blazer/detail-1.webp",
        "alt": "Velvet Texture Detail"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Classic navy velvet blazer with luxurious finish. Ideal for evening events and formal occasions.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 3. Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Velvet Blazer',
  'VB-004-BURG',
  'mens-burgundy-velvet-blazer',
  'mens-burgundy-velvet-blazer',
  'FW24-VB-004',
  'FW24',
  'Luxury Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_9',
  39999,
  49999,
  'Red',
  'Burgundy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 80, "Polyester": 20}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-burgundy-velvet-blazer/main.webp",
      "alt": "Burgundy Velvet Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-burgundy-velvet-blazer/flat.webp",
      "alt": "Burgundy Velvet Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-burgundy-velvet-blazer/back.webp",
        "alt": "Burgundy Velvet Blazer - Back View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-burgundy-velvet-blazer/detail-1.webp",
        "alt": "Rich Burgundy Color Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Statement burgundy velvet blazer that commands attention. Perfect for holiday parties and special events.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- SUMMER BLAZERS
-- ============================================

-- 4. Blue Casual Summer Blazer (Already exists, update)
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Casual Summer Blazer',
  'SB-001-BLU',
  'mens-blue-casual-summer-blazer',
  'mens-blue-casual-summer-blazer',
  'SS24-SB-001',
  'SS24',
  'Summer Essentials',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  29999,
  'Blue',
  'Sky Blue',
  '{"primary": "Linen Blend", "composition": {"Linen": 60, "Cotton": 40}}'::jsonb,
  'Relaxed Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/main.webp",
      "alt": "Blue Casual Summer Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/flat.webp",
      "alt": "Blue Casual Summer Blazer - Flat Lay"
    },
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
    "total_images": 6
  }'::jsonb,
  'Lightweight and breathable summer blazer in sky blue. Perfect for casual summer events and beach weddings.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 5. White Linen Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Linen Summer Blazer',
  'SB-002-WHT',
  'mens-white-linen-summer-blazer',
  'mens-white-linen-summer-blazer',
  'SS24-SB-002',
  'SS24',
  'Summer Essentials',
  'Blazers',
  'Summer',
  'TIER_7',
  27999,
  34999,
  'White',
  'Pure White',
  '{"primary": "Linen", "composition": {"Linen": 100}}'::jsonb,
  'Regular Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-white-linen-summer-blazer/main.webp",
      "alt": "White Linen Summer Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-white-linen-summer-blazer/flat.webp",
      "alt": "White Linen Summer Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-white-linen-summer-blazer/back.webp",
        "alt": "White Linen Summer Blazer - Back View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-white-linen-summer-blazer/detail-1.webp",
        "alt": "Linen Texture Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Pure linen blazer in crisp white. The ultimate summer sophistication for beach weddings and yacht parties.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 6. Beige Cotton Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Beige Cotton Summer Blazer',
  'SB-003-BEI',
  'mens-beige-cotton-summer-blazer',
  'mens-beige-cotton-summer-blazer',
  'SS24-SB-003',
  'SS24',
  'Summer Essentials',
  'Blazers',
  'Summer',
  'TIER_5',
  19999,
  24999,
  'Beige',
  'Sand Beige',
  '{"primary": "Cotton", "composition": {"Cotton": 98, "Elastane": 2}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-beige-cotton-summer-blazer/main.webp",
      "alt": "Beige Cotton Summer Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-beige-cotton-summer-blazer/flat.webp",
      "alt": "Beige Cotton Summer Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-beige-cotton-summer-blazer/back.webp",
        "alt": "Beige Cotton Summer Blazer - Back View"
      }
    ],
    "details": [],
    "total_images": 3
  }'::jsonb,
  'Versatile beige cotton blazer with a hint of stretch. Perfect for smart-casual summer occasions.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- FORMAL BLAZERS
-- ============================================

-- 7. Classic Black Formal Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Classic Black Formal Blazer',
  'FB-001-BLK',
  'mens-classic-black-formal-blazer',
  'mens-classic-black-formal-blazer',
  'AW24-FB-001',
  'AW24',
  'Formal Essentials',
  'Blazers',
  'Formal',
  'TIER_10',
  54999,
  69999,
  'Black',
  'Classic Black',
  '{"primary": "Wool", "composition": {"Wool": 90, "Cashmere": 10}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/main.webp",
      "alt": "Classic Black Formal Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/flat.webp",
      "alt": "Classic Black Formal Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/back.webp",
        "alt": "Classic Black Formal Blazer - Back View"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/side.webp",
        "alt": "Classic Black Formal Blazer - Side View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/detail-1.webp",
        "alt": "Premium Wool Texture"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-classic-black-formal-blazer/detail-2.webp",
        "alt": "Button and Stitching Detail"
      }
    ],
    "total_images": 6
  }'::jsonb,
  'Timeless black formal blazer crafted from premium wool with cashmere blend. Essential for black-tie events.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 8. Charcoal Grey Formal Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Charcoal Grey Formal Blazer',
  'FB-002-CHAR',
  'mens-charcoal-grey-formal-blazer',
  'mens-charcoal-grey-formal-blazer',
  'AW24-FB-002',
  'AW24',
  'Formal Essentials',
  'Blazers',
  'Formal',
  'TIER_9',
  44999,
  54999,
  'Grey',
  'Charcoal',
  '{"primary": "Wool", "composition": {"Wool": 100}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/mens-charcoal-grey-formal-blazer/main.webp",
      "alt": "Charcoal Grey Formal Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/formal/mens-charcoal-grey-formal-blazer/flat.webp",
      "alt": "Charcoal Grey Formal Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-charcoal-grey-formal-blazer/back.webp",
        "alt": "Charcoal Grey Formal Blazer - Back View"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/formal/mens-charcoal-grey-formal-blazer/detail-1.webp",
        "alt": "Charcoal Wool Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Sophisticated charcoal grey blazer in pure wool. Versatile formal piece for business and evening events.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- CASUAL BLAZERS
-- ============================================

-- 9. Navy Cotton Casual Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Cotton Casual Blazer',
  'CB-001-NAVY',
  'mens-navy-cotton-casual-blazer',
  'mens-navy-cotton-casual-blazer',
  'SS24-CB-001',
  'SS24',
  'Smart Casual',
  'Blazers',
  'Casual',
  'TIER_4',
  14999,
  19999,
  'Blue',
  'Navy',
  '{"primary": "Cotton", "composition": {"Cotton": 95, "Elastane": 5}}'::jsonb,
  'Regular Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/casual/mens-navy-cotton-casual-blazer/main.webp",
      "alt": "Navy Cotton Casual Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/casual/mens-navy-cotton-casual-blazer/flat.webp",
      "alt": "Navy Cotton Casual Blazer - Flat Lay"
    },
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/casual/mens-navy-cotton-casual-blazer/back.webp",
        "alt": "Navy Cotton Casual Blazer - Back View"
      }
    ],
    "details": [],
    "total_images": 3
  }'::jsonb,
  'Comfortable navy cotton blazer with stretch. Perfect for smart-casual occasions and office wear.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 10. Grey Textured Casual Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Grey Textured Casual Blazer',
  'CB-002-GREY',
  'mens-grey-textured-casual-blazer',
  'mens-grey-textured-casual-blazer',
  'SS24-CB-002',
  'SS24',
  'Smart Casual',
  'Blazers',
  'Casual',
  'TIER_5',
  17999,
  22999,
  'Grey',
  'Light Grey',
  '{"primary": "Cotton Blend", "composition": {"Cotton": 70, "Polyester": 30}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/casual/mens-grey-textured-casual-blazer/main.webp",
      "alt": "Grey Textured Casual Blazer - Main View"
    },
    "flat": {
      "url": "https://cdn.kctmenswear.com/blazers/casual/mens-grey-textured-casual-blazer/flat.webp",
      "alt": "Grey Textured Casual Blazer - Flat Lay"
    },
    "lifestyle": [],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/casual/mens-grey-textured-casual-blazer/detail-1.webp",
        "alt": "Textured Fabric Detail"
      }
    ],
    "total_images": 3
  }'::jsonb,
  'Modern grey blazer with subtle texture. Ideal for business casual and weekend sophistication.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- VERIFICATION
-- ============================================

-- Check all inserted blazers
SELECT 
  subcategory,
  COUNT(*) as count,
  STRING_AGG(name, ', ') as products
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY subcategory;

-- Show all blazers with their images
SELECT 
  name,
  sku,
  subcategory,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->'hero'->>'url' as hero_image,
  (images->>'total_images')::int as total_images,
  status
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY subcategory, name;

-- Count total products
SELECT 
  'Total Blazers Added' as metric,
  COUNT(*) as count
FROM products_enhanced
WHERE category = 'Blazers' AND status = 'active';