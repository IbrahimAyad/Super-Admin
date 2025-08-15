-- INSERT BLAZERS BASED ON YOUR LOCAL ENHANCED-PRODCUTS FOLDER
-- These match your actual folder structure
-- Upload these exact files to your CDN at: https://cdn.kctmenswear.com/blazers/[category]/[product-name]/[image].webp

-- ============================================
-- PROM BLAZERS (18 products from your folders)
-- ============================================

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
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 2. Black Geometric Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Geometric Pattern Prom Blazer',
  'PB-002-BLK-GEO',
  'mens-black-geometric-pattern-prom-blazer',
  'mens-black-geometric-pattern-prom-blazer',
  'PROM24-002',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34999,
  'Black',
  'Black Geometric',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/main.webp",
      "alt": "Black Geometric Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/lifestyle.webp",
        "alt": "Black Geometric Prom Blazer - Lifestyle"
      }
    ],
    "details": [],
    "total_images": 2
  }'::jsonb,
  'Modern geometric pattern blazer perfect for prom night.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 3. Black Glitter Finish Prom Blazer with Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Glitter Finish Prom Blazer - Shawl Lapel',
  'PB-003-BLK-GLITTER',
  'mens-black-glitter-finish-prom-blazer-shawl-lapel',
  'mens-black-glitter-finish-prom-blazer-shawl-lapel',
  'PROM24-003',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_8',
  32999,
  39999,
  'Black',
  'Black Glitter',
  '{"primary": "Glitter Fabric", "composition": {"Polyester": 80, "Metallic Fiber": 20}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/main.webp",
      "alt": "Black Glitter Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Black Glitter Prom Blazer - Lifestyle"
      }
    ],
    "details": [],
    "total_images": 2
  }'::jsonb,
  'Eye-catching glitter finish blazer with elegant shawl lapel for ultimate prom sophistication.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 4. Black Prom Blazer with Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Prom Blazer with Bowtie',
  'PB-004-BLK-BOW',
  'mens-black-prom-blazer-with-bowtie',
  'mens-black-prom-blazer-with-bowtie',
  'PROM24-004',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  24999,
  29999,
  'Black',
  'Classic Black',
  '{"primary": "Polyester", "composition": {"Polyester": 100}}'::jsonb,
  'Regular Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Black Prom Blazer with Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Black Prom Blazer with Bowtie - Lifestyle"
      }
    ],
    "details": [],
    "total_images": 2
  }'::jsonb,
  'Classic black prom blazer complete with matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 5. Burgundy Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Floral Pattern Prom Blazer',
  'PB-005-BURG-FLORAL',
  'mens-burgundy-floral-pattern-prom-blazer',
  'mens-burgundy-floral-pattern-prom-blazer',
  'PROM24-005',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34999,
  'Red',
  'Burgundy Floral',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/main.webp",
      "alt": "Burgundy Floral Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Burgundy Floral Prom Blazer - Lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/side.webp",
        "alt": "Burgundy Floral Prom Blazer - Side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Side Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Rich burgundy blazer with elegant floral pattern for a sophisticated prom look.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 6. Gold Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Prom Blazer',
  'PB-006-GOLD',
  'mens-gold-prom-blazer',
  'mens-gold-prom-blazer',
  'PROM24-006',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_8',
  32999,
  39999,
  'Gold',
  'Metallic Gold',
  '{"primary": "Metallic Fabric", "composition": {"Polyester": 85, "Metallic Fiber": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/main.webp",
      "alt": "Gold Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/lifestyle.webp",
        "alt": "Gold Prom Blazer - Lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/side.webp",
        "alt": "Gold Prom Blazer - Side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/close-side.webp",
        "alt": "Side Detail"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Make a bold statement with this stunning metallic gold prom blazer.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 7. Royal Blue Prom Blazer with Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Prom Blazer with Bowtie',
  'PB-007-BLUE-BOW',
  'mens-royal-blue-prom-blazer-with-bowtie',
  'mens-royal-blue-prom-blazer-with-bowtie',
  'PROM24-007',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34999,
  'Blue',
  'Royal Blue',
  '{"primary": "Polyester", "composition": {"Polyester": 100}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Royal Blue Prom Blazer with Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Royal Blue Prom Blazer - Lifestyle"
      }
    ],
    "details": [],
    "total_images": 2
  }'::jsonb,
  'Vibrant royal blue prom blazer complete with matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 8. Red Prom Blazer with Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Prom Blazer with Bowtie',
  'PB-008-RED-BOW',
  'mens-red-prom-blazer-with-bowtie',
  'mens-red-prom-blazer-with-bowtie',
  'PROM24-008',
  'SS24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34999,
  'Red',
  'Classic Red',
  '{"primary": "Polyester", "composition": {"Polyester": 100}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Red Prom Blazer with Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Red Prom Blazer - Lifestyle"
      }
    ],
    "details": [],
    "total_images": 2
  }'::jsonb,
  'Bold red prom blazer with matching bowtie for a confident look.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- VELVET BLAZERS (from velvet folder)
-- ============================================

-- 9. Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Velvet Blazer',
  'VB-001-NAVY',
  'mens-navy-velvet-blazer',
  'mens-navy-velvet-blazer',
  'FW24-VB-001',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  44999,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer/main.webp",
      "alt": "Navy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [],
    "details": [],
    "total_images": 1
  }'::jsonb,
  'Luxurious navy velvet blazer for formal occasions.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 10. Burgundy Velvet Blazer with Notch Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Notch Lapel Burgundy Velvet Blazer',
  'VB-002-BURG',
  'mens-notch-lapel-burgundy-velvet-blazer',
  'mens-notch-lapel-burgundy-velvet-blazer',
  'FW24-VB-002',
  'FW24',
  'Velvet Collection',
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
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-notch-lapel-burgundy-velvet-blazer/main.webp",
      "alt": "Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [],
    "details": [],
    "total_images": 1
  }'::jsonb,
  'Sophisticated burgundy velvet blazer with classic notch lapel.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check how many blazers we've added
SELECT 
  subcategory,
  COUNT(*) as count
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
  images->'hero'->>'url' as hero_image
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY subcategory, name
LIMIT 20;

-- ============================================
-- IMPORTANT NOTES:
-- ============================================
-- 1. You have 69 blazer folders locally in ENHANCED-PRODCUTS
-- 2. This SQL includes 10 sample products based on your actual folders
-- 3. To use these, upload your local images to your CDN:
--    FROM: /Users/ibrahim/Desktop/Super-Admin/ENHANCED-PRODCUTS/blazers/[category]/[product]/
--    TO: https://cdn.kctmenswear.com/blazers/[category]/[product]/
-- 4. The 'summer' and 'sparkle' folders are empty in your local setup
-- 5. Most products have: main.webp or main-2.webp, lifestyle.webp, back.webp, side.webp, etc.