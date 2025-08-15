-- AUTO-GENERATED SQL FOR ALL BLAZERS IN LOCAL FOLDERS
-- Generated from: /Users/ibrahim/Desktop/Super-Admin/ENHANCED-PRODCUTS/blazers
-- CDN URL base: https://cdn.kctmenswear.com/blazers
-- Generated on: 2025-08-15T05:56:37.145Z

-- Clear existing blazers if needed (optional - uncomment to use)
-- DELETE FROM products_enhanced WHERE category = 'Blazers';


-- ============================================
-- PROM BLAZERS (18 products)
-- ============================================

-- 1. Men's Black Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Floral Pattern Prom Blazer',
  'PB-001-BLK',
  'mens-black-floral-pattern-prom-blazer',
  'mens-black-floral-pattern-prom-blazer',
  'PROM24-001',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/main-2.webp",
      "alt": "Men's Black Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/back.webp",
        "alt": "Men's Black Floral Pattern Prom Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Black Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Men's Black Floral Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Black Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/front-close.webp",
        "alt": "Men's Black Floral Pattern Prom Blazer - front close"
      }
    ],
    "total_images": 7
  }'::jsonb,
  'Men's Black Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 2. Men's Black Geometric Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Geometric Pattern Prom Blazer',
  'PB-002-BLK',
  'mens-black-geometric-pattern-prom-blazer',
  'mens-black-geometric-pattern-prom-blazer',
  'PROM24-002',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/main.webp",
      "alt": "Men's Black Geometric Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/lifestyle.webp",
        "alt": "Men's Black Geometric Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Black Geometric Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 3. Men's Black Glitter Finish Prom Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Glitter Finish Prom Blazer Shawl Lapel',
  'PB-003-BLK',
  'mens-black-glitter-finish-prom-blazer-shawl-lapel',
  'mens-black-glitter-finish-prom-blazer-shawl-lapel',
  'PROM24-003',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/main.webp",
      "alt": "Men's Black Glitter Finish Prom Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Men's Black Glitter Finish Prom Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Black Glitter Finish Prom Blazer Shawl Lapel from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 4. Men's Black Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Prom Blazer With Bowtie',
  'PB-004-BLK',
  'mens-black-prom-blazer-with-bowtie',
  'mens-black-prom-blazer-with-bowtie',
  'PROM24-004',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Men's Black Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Men's Black Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Black Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 5. Men's Burgundy Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Floral Pattern Prom Blazer',
  'PB-005-BURG',
  'mens-burgundy-floral-pattern-prom-blazer',
  'mens-burgundy-floral-pattern-prom-blazer',
  'PROM24-005',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Red',
  'Burgundy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/main.webp",
      "alt": "Men's Burgundy Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Burgundy Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Men's Burgundy Floral Pattern Prom Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/side.webp",
        "alt": "Men's Burgundy Floral Pattern Prom Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Burgundy Floral Pattern Prom Blazer - close side"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Burgundy Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 6. Men's Burgundy Paisley Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Paisley Pattern Prom Blazer With Bowtie',
  'PB-006-BURG',
  'mens-burgundy-paisley-pattern-prom-blazer-with-bowtie',
  'mens-burgundy-paisley-pattern-prom-blazer-with-bowtie',
  'PROM24-006',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Red',
  'Burgundy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-paisley-pattern-prom-blazer-with-bowtie/main.webp",
      "alt": "Men's Burgundy Paisley Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's Burgundy Paisley Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 7. Men's Gold Paisley Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Paisley Pattern Prom Blazer With Bowtie',
  'PB-007-GOLD',
  'mens-gold-paisley-pattern-prom-blazer-with-bowtie',
  'mens-gold-paisley-pattern-prom-blazer-with-bowtie',
  'PROM24-007',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Gold',
  'Gold',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-paisley-pattern-prom-blazer-with-bowtie/main.webp",
      "alt": "Men's Gold Paisley Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-paisley-pattern-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Men's Gold Paisley Pattern Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Gold Paisley Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 8. Men's Gold Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Prom Blazer',
  'PB-008-GOLD',
  'mens-gold-prom-blazer',
  'mens-gold-prom-blazer',
  'PROM24-008',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Gold',
  'Gold',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/main.webp",
      "alt": "Men's Gold Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/close-side.webp",
        "alt": "Men's Gold Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/lifestyle.webp",
        "alt": "Men's Gold Prom Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/side.webp",
        "alt": "Men's Gold Prom Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/close-side.webp",
        "alt": "Men's Gold Prom Blazer - close side"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Gold Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 9. Men's Off White Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Off White Prom Blazer With Bowtie',
  'PB-009-WHT',
  'mens-off-white-prom-blazer-with-bowtie',
  'mens-off-white-prom-blazer-with-bowtie',
  'PROM24-009',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'White',
  'Off White',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-off-white-prom-blazer-with-bowtie/main.webp",
      "alt": "Men's Off White Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's Off White Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 10. Men's Purple Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Floral Pattern Prom Blazer',
  'PB-010-PUR',
  'mens-purple-floral-pattern-prom-blazer',
  'mens-purple-floral-pattern-prom-blazer',
  'PROM24-010',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Purple',
  'Purple',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-purple-floral-pattern-prom-blazer/main.webp",
      "alt": "Men's Purple Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-purple-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Men's Purple Floral Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Purple Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 11. Men's Red Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Floral Pattern Prom Blazer',
  'PB-011-RED',
  'mens-red-floral-pattern-prom-blazer',
  'mens-red-floral-pattern-prom-blazer',
  'PROM24-011',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Red',
  'Red',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer/main.webp",
      "alt": "Men's Red Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Men's Red Floral Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Red Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 12. Men's Red Floral Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Floral Pattern Prom Blazer With Bowtie',
  'PB-012-RED',
  'mens-red-floral-pattern-prom-blazer-with-bowtie',
  'mens-red-floral-pattern-prom-blazer-with-bowtie',
  'PROM24-012',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Red',
  'Red',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer-with-bowtie/main.webp",
      "alt": "Men's Red Floral Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Red Floral Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 13. Men's Red Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Prom Blazer With Bowtie',
  'PB-013-RED',
  'mens-red-prom-blazer-with-bowtie',
  'mens-red-prom-blazer-with-bowtie',
  'PROM24-013',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Red',
  'Red',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Men's Red Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Men's Red Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Red Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 14. Men's Royal Blue Embellished Design Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Embellished Design Prom Blazer',
  'PB-014-BLU',
  'mens-royal-blue-embellished-design-prom-blazer',
  'mens-royal-blue-embellished-design-prom-blazer',
  'PROM24-014',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Royal Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-embellished-design-prom-blazer/main.webp",
      "alt": "Men's Royal Blue Embellished Design Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-embellished-design-prom-blazer/lifestyle.webp",
        "alt": "Men's Royal Blue Embellished Design Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Royal Blue Embellished Design Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 15. Men's Royal Blue Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Prom Blazer With Bowtie',
  'PB-015-BLU',
  'mens-royal-blue-prom-blazer-with-bowtie',
  'mens-royal-blue-prom-blazer-with-bowtie',
  'PROM24-015',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'Blue',
  'Royal Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/main-2.webp",
      "alt": "Men's Royal Blue Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Men's Royal Blue Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Royal Blue Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 16. Men's Teal Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Teal Floral Pattern Prom Blazer',
  'PB-016-TEAL',
  'mens-teal-floral-pattern-prom-blazer',
  'mens-teal-floral-pattern-prom-blazer',
  'PROM24-016',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_7',
  27999,
  34998,
  'Teal',
  'Teal',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/main.webp",
      "alt": "Men's Teal Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Teal Floral Pattern Prom Blazer - close side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Men's Teal Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/front-close.webp",
        "alt": "Men's Teal Floral Pattern Prom Blazer - front close"
      }
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Teal Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 17. Men's White Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Prom Blazer With Bowtie',
  'PB-017-WHT',
  'mens-white-prom-blazer-with-bowtie',
  'mens-white-prom-blazer-with-bowtie',
  'PROM24-017',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_6',
  22999,
  28748,
  'White',
  'White',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-white-prom-blazer-with-bowtie/main.webp",
      "alt": "Men's White Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's White Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 18. Men's White Rhinestone Embellished Prom Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Rhinestone Embellished Prom Blazer Shawl Lapel',
  'PB-018-WHT',
  'mens-white-rhinestone-embellished-prom-blazer-shawl-lapel',
  'mens-white-rhinestone-embellished-prom-blazer-shawl-lapel',
  'PROM24-018',
  'FW24',
  'Prom Collection 2024',
  'Blazers',
  'Prom',
  'TIER_8',
  34999,
  43748,
  'White',
  'White',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/prom/mens-white-rhinestone-embellished-prom-blazer-shawl-lapel/main.webp",
      "alt": "Men's White Rhinestone Embellished Prom Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-white-rhinestone-embellished-prom-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Men's White Rhinestone Embellished Prom Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's White Rhinestone Embellished Prom Blazer Shawl Lapel from our prom collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();


-- ============================================
-- SPARKLE BLAZERS (16 products)
-- ============================================

-- 19. Men's Black Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Glitter Finish Sparkle Blazer',
  'SPB-001-BLK',
  'mens-black-glitter-finish-sparkle-blazer',
  'mens-black-glitter-finish-sparkle-blazer',
  'SPARKLE24-001',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Black Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Black Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Men's Black Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Black Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Black Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Black Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 20. Men's Black Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Sparkle Texture Sparkle Blazer',
  'SPB-002-BLK',
  'mens-black-sparkle-texture-sparkle-blazer',
  'mens-black-sparkle-texture-sparkle-blazer',
  'SPARKLE24-002',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Black',
  'Black',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Black Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Black Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Men's Black Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Black Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Black Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Black Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 21. Men's Blue Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Sparkle Blazer',
  'SPB-003-BLU',
  'mens-blue-sparkle-blazer',
  'mens-blue-sparkle-blazer',
  'SPARKLE24-003',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Blue',
  'Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer/main.webp",
      "alt": "Men's Blue Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's Blue Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 22. Men's Blue Sparkle Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Sparkle Blazer Shawl Lapel',
  'SPB-004-BLU',
  'mens-blue-sparkle-blazer-shawl-lapel',
  'mens-blue-sparkle-blazer-shawl-lapel',
  'SPARKLE24-004',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Blue',
  'Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer-shawl-lapel/main.webp",
      "alt": "Men's Blue Sparkle Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer-shawl-lapel/front-close.webp",
        "alt": "Men's Blue Sparkle Blazer Shawl Lapel - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Blue Sparkle Blazer Shawl Lapel from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 23. Men's Burgundy Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Glitter Finish Sparkle Blazer',
  'SPB-005-BURG',
  'mens-burgundy-glitter-finish-sparkle-blazer',
  'mens-burgundy-glitter-finish-sparkle-blazer',
  'SPARKLE24-005',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Burgundy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/back.webp",
        "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Burgundy Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Burgundy Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 24. Men's Burgundy Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Sparkle Texture Sparkle Blazer',
  'SPB-006-BURG',
  'mens-burgundy-sparkle-texture-sparkle-blazer',
  'mens-burgundy-sparkle-texture-sparkle-blazer',
  'SPARKLE24-006',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Red',
  'Burgundy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Burgundy Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Burgundy Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 25. Men's Gold Baroque Pattern Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Baroque Pattern Sparkle Blazer',
  'SPB-007-GOLD',
  'mens-gold-baroque-pattern-sparkle-blazer',
  'mens-gold-baroque-pattern-sparkle-blazer',
  'SPARKLE24-007',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Gold',
  'Gold',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-baroque-pattern-sparkle-blazer/main.webp",
      "alt": "Men's Gold Baroque Pattern Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-baroque-pattern-sparkle-blazer/front-close.webp",
        "alt": "Men's Gold Baroque Pattern Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Gold Baroque Pattern Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 26. Men's Gold Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Glitter Finish Sparkle Blazer',
  'SPB-008-GOLD',
  'mens-gold-glitter-finish-sparkle-blazer',
  'mens-gold-glitter-finish-sparkle-blazer',
  'SPARKLE24-008',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Gold',
  'Gold',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Gold Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Gold Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Men's Gold Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Gold Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Gold Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Gold Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 27. Men's Gold Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Sparkle Texture Sparkle Blazer',
  'SPB-009-GOLD',
  'mens-gold-sparkle-texture-sparkle-blazer',
  'mens-gold-sparkle-texture-sparkle-blazer',
  'SPARKLE24-009',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Gold',
  'Gold',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Gold Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Men's Gold Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Gold Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Men's Gold Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Gold Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Gold Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Gold Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 28. Men's Green Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Glitter Finish Sparkle Blazer',
  'SPB-010-MIX',
  'mens-green-glitter-finish-sparkle-blazer',
  'mens-green-glitter-finish-sparkle-blazer',
  'SPARKLE24-010',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Green Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/back.webp",
        "alt": "Men's Green Glitter Finish Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Green Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Men's Green Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Green Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Green Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Green Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 29. Men's Green Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Sparkle Texture Sparkle Blazer',
  'SPB-011-MIX',
  'mens-green-sparkle-texture-sparkle-blazer',
  'mens-green-sparkle-texture-sparkle-blazer',
  'SPARKLE24-011',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Green Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Men's Green Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Green Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Men's Green Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Green Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Green Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Green Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 30. Men's Navy Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Glitter Finish Sparkle Blazer',
  'SPB-012-NVY',
  'mens-navy-glitter-finish-sparkle-blazer',
  'mens-navy-glitter-finish-sparkle-blazer',
  'SPARKLE24-012',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Navy Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Navy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Men's Navy Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Men's Navy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Navy Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Navy Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 31. Men's Navy Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Sparkle Texture Sparkle Blazer',
  'SPB-013-NVY',
  'mens-navy-sparkle-texture-sparkle-blazer',
  'mens-navy-sparkle-texture-sparkle-blazer',
  'SPARKLE24-013',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Blue',
  'Navy',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Navy Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Navy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Men's Navy Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Navy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Navy Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Navy Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 32. Men's Red Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Glitter Finish Sparkle Blazer',
  'SPB-014-RED',
  'mens-red-glitter-finish-sparkle-blazer',
  'mens-red-glitter-finish-sparkle-blazer',
  'SPARKLE24-014',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Red',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-red-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Men's Red Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-red-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Men's Red Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Red Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 33. Men's Royal Blue Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Sparkle Texture Sparkle Blazer',
  'SPB-015-BLU',
  'mens-royal-blue-sparkle-texture-sparkle-blazer',
  'mens-royal-blue-sparkle-texture-sparkle-blazer',
  'SPARKLE24-015',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'Blue',
  'Royal Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's Royal Blue Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Royal Blue Sparkle Texture Sparkle Blazer - close side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Men's Royal Blue Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's Royal Blue Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Royal Blue Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 34. Men's White Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Sparkle Texture Sparkle Blazer',
  'SPB-016-WHT',
  'mens-white-sparkle-texture-sparkle-blazer',
  'mens-white-sparkle-texture-sparkle-blazer',
  'SPARKLE24-016',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_7',
  27999,
  34998,
  'White',
  'White',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-white-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Men's White Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-white-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Men's White Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men's White Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();


-- ============================================
-- SUMMER BLAZERS (6 products)
-- ============================================

-- 35. Men's Blue Casual Summer Blazer
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
  'SUMMER24-001',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Blue',
  'Blue',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/main.webp",
      "alt": "Men's Blue Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/back.webp",
        "alt": "Men's Blue Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/close-side.webp",
        "alt": "Men's Blue Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/side.webp",
        "alt": "Men's Blue Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/close-side.webp",
        "alt": "Men's Blue Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/front-close.webp",
        "alt": "Men's Blue Casual Summer Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Blue Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 36. Men's Brown Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Brown Casual Summer Blazer',
  'SB-002-MIX',
  'mens-brown-casual-summer-blazer',
  'mens-brown-casual-summer-blazer',
  'SUMMER24-002',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-brown-casual-summer-blazer/main-zoon.webp",
      "alt": "Men's Brown Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Brown Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 37. Men's Mint Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Mint Casual Summer Blazer',
  'SB-003-MIX',
  'mens-mint-casual-summer-blazer',
  'mens-mint-casual-summer-blazer',
  'SUMMER24-003',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/main.webp",
      "alt": "Men's Mint Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/back.webp",
        "alt": "Men's Mint Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/close-side.webp",
        "alt": "Men's Mint Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/lifestyle.webp",
        "alt": "Men's Mint Casual Summer Blazer - lifestyle"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/close-side.webp",
        "alt": "Men's Mint Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/front-close.webp",
        "alt": "Men's Mint Casual Summer Blazer - front close"
      }
    ],
    "total_images": 6
  }'::jsonb,
  'Men's Mint Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 38. Men's Pink Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Pink Casual Summer Blazer',
  'SB-004-MIX',
  'mens-pink-casual-summer-blazer',
  'mens-pink-casual-summer-blazer',
  'SUMMER24-004',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/main.webp",
      "alt": "Men's Pink Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/close-side.webp",
        "alt": "Men's Pink Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/side.webp",
        "alt": "Men's Pink Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/close-side.webp",
        "alt": "Men's Pink Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/front-close.webp",
        "alt": "Men's Pink Casual Summer Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men's Pink Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 39. Men's Salmon Casual Summer Blazer 2025
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Salmon Casual Summer Blazer 2025',
  'SB-005-MIX',
  'mens-salmon-casual-summer-blazer-2025',
  'mens-salmon-casual-summer-blazer-2025',
  'SUMMER24-005',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/main-close.webp",
      "alt": "Men's Salmon Casual Summer Blazer 2025 - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/back.webp",
        "alt": "Men's Salmon Casual Summer Blazer 2025 - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/lifestyle.webp",
        "alt": "Men's Salmon Casual Summer Blazer 2025 - lifestyle"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/close-up.webp",
        "alt": "Men's Salmon Casual Summer Blazer 2025 - close up"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/main-close.webp",
        "alt": "Men's Salmon Casual Summer Blazer 2025 - main close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Salmon Casual Summer Blazer 2025 from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 40. Men's Yellow Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Yellow Casual Summer Blazer',
  'SB-006-MIX',
  'mens-yellow-casual-summer-blazer',
  'mens-yellow-casual-summer-blazer',
  'SUMMER24-006',
  'SS24',
  'Summer Collection',
  'Blazers',
  'Summer',
  'TIER_6',
  22999,
  28748,
  'Multi',
  'Multi-Color',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/main.webp",
      "alt": "Men's Yellow Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/back.webp",
        "alt": "Men's Yellow Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/close-side.webp",
        "alt": "Men's Yellow Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/side.webp",
        "alt": "Men's Yellow Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/close-side.webp",
        "alt": "Men's Yellow Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/front-close.webp",
        "alt": "Men's Yellow Casual Summer Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men's Yellow Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();


-- ============================================
-- VELVET BLAZERS (29 products)
-- ============================================

-- 41. Men's All Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Navy Velvet Blazer',
  'VB-001-NVY',
  'mens-all-navy-velvet-blazer',
  'mens-all-navy-velvet-blazer',
  'VELVET24-001',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-blazer/main.webp",
      "alt": "Men's All Navy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's All Navy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 42. Men's All Navy Velvet Jacker
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Navy Velvet Jacker',
  'VB-002-NVY',
  'mens-all-navy-velvet-jacker',
  'mens-all-navy-velvet-jacker',
  'VELVET24-002',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-jacker/main.webp",
      "alt": "Men's All Navy Velvet Jacker - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-jacker/side.webp",
        "alt": "Men's All Navy Velvet Jacker - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's All Navy Velvet Jacker from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 43. Men's All Red Velvet Jacker
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Red Velvet Jacker',
  'VB-003-RED',
  'mens-all-red-velvet-jacker',
  'mens-all-red-velvet-jacker',
  'VELVET24-003',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Red',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-red-velvet-jacker/main.webp",
      "alt": "Men's All Red Velvet Jacker - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-red-velvet-jacker/side.webp",
        "alt": "Men's All Red Velvet Jacker - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's All Red Velvet Jacker from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 44. Men's Black Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Paisley Pattern Velvet Blazer',
  'VB-004-BLK',
  'mens-black-paisley-pattern-velvet-blazer',
  'mens-black-paisley-pattern-velvet-blazer',
  'VELVET24-004',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Men's Black Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/side.webp",
        "alt": "Men's Black Paisley Pattern Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Black Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 45. Men's Black Velvet Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Velvet Blazer Shawl Lapel',
  'VB-005-BLK',
  'mens-black-velvet-blazer-shawl-lapel',
  'mens-black-velvet-blazer-shawl-lapel',
  'VELVET24-005',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-blazer-shawl-lapel/main.webp",
      "alt": "Men's Black Velvet Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Men's Black Velvet Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Black Velvet Blazer Shawl Lapel from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 46. Men's Black Velvet Jacket
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Velvet Jacket',
  'VB-006-BLK',
  'mens-black-velvet-jacket',
  'mens-black-velvet-jacket',
  'VELVET24-006',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-jacket/main.webp",
      "alt": "Men's Black Velvet Jacket - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-jacket/side.webp",
        "alt": "Men's Black Velvet Jacket - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Black Velvet Jacket from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 47. Men's Brown Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Brown Velvet Blazer With Bowtie',
  'VB-007-MIX',
  'mens-brown-velvet-blazer-with-bowtie',
  'mens-brown-velvet-blazer-with-bowtie',
  'VELVET24-007',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-brown-velvet-blazer-with-bowtie/main.webp",
      "alt": "Men's Brown Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-brown-velvet-blazer-with-bowtie/lifestyle.webp",
        "alt": "Men's Brown Velvet Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Brown Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 48. Men's Cherry Red Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Cherry Red Velvet Blazer',
  'VB-008-RED',
  'mens-cherry-red-velvet-blazer',
  'mens-cherry-red-velvet-blazer',
  'VELVET24-008',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Red',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-cherry-red-velvet-blazer/main.webp",
      "alt": "Men's Cherry Red Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Cherry Red Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 49. Men's Dark Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Dark Burgundy Velvet Blazer',
  'VB-009-BURG',
  'mens-dark-burgundy-velvet-blazer',
  'mens-dark-burgundy-velvet-blazer',
  'VELVET24-009',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_9',
  39999,
  49998,
  'Red',
  'Burgundy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-dark-burgundy-velvet-blazer/main.webp",
      "alt": "Men's Dark Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Dark Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 50. Men's Euro Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Euro Burgundy Velvet Blazer',
  'VB-010-BURG',
  'mens-euro-burgundy-velvet-blazer',
  'mens-euro-burgundy-velvet-blazer',
  'VELVET24-010',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_9',
  39999,
  49998,
  'Red',
  'Burgundy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-euro-burgundy-velvet-blazer/main.webp",
      "alt": "Men's Euro Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Euro Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 51. Men's Green Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Paisley Pattern Velvet Blazer',
  'VB-011-MIX',
  'mens-green-paisley-pattern-velvet-blazer',
  'mens-green-paisley-pattern-velvet-blazer',
  'VELVET24-011',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-green-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Men's Green Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Green Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 52. Men's Green Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Velvet Blazer',
  'VB-012-MIX',
  'mens-green-velvet-blazer',
  'mens-green-velvet-blazer',
  'VELVET24-012',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer/main.webp",
      "alt": "Men's Green Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Green Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 53. Men's Green Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Velvet Blazer With Bowtie',
  'VB-013-MIX',
  'mens-green-velvet-blazer-with-bowtie',
  'mens-green-velvet-blazer-with-bowtie',
  'VELVET24-013',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer-with-bowtie/main.webp",
      "alt": "Men's Green Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer-with-bowtie/side.webp",
        "alt": "Men's Green Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Green Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 54. Men's Hunter Green Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Hunter Green Velvet Blazer',
  'VB-014-MIX',
  'mens-hunter-green-velvet-blazer',
  'mens-hunter-green-velvet-blazer',
  'VELVET24-014',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-hunter-green-velvet-blazer/main.webp",
      "alt": "Men's Hunter Green Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-hunter-green-velvet-blazer/lifestyle.webp",
        "alt": "Men's Hunter Green Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Hunter Green Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 55. Men's Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Velvet Blazer',
  'VB-015-NVY',
  'mens-navy-velvet-blazer',
  'mens-navy-velvet-blazer',
  'VELVET24-015',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer/main.webp",
      "alt": "Men's Navy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer/side.webp",
        "alt": "Men's Navy Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Navy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 56. Men's Navy Velvet Blazer 2025 
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Velvet Blazer 2025 ',
  'VB-016-NVY',
  'mens-navy-velvet-blazer-2025-',
  'mens-navy-velvet-blazer-2025-',
  'VELVET24-016',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer-2025-/main.webp",
      "alt": "Men's Navy Velvet Blazer 2025  - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer-2025-/lifestyle.webp",
        "alt": "Men's Navy Velvet Blazer 2025  - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Navy Velvet Blazer 2025  from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 57. Men's Notch Lapel Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Notch Lapel Burgundy Velvet Blazer',
  'VB-017-BURG',
  'mens-notch-lapel-burgundy-velvet-blazer',
  'mens-notch-lapel-burgundy-velvet-blazer',
  'VELVET24-017',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_9',
  39999,
  49998,
  'Red',
  'Burgundy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-notch-lapel-burgundy-velvet-blazer/main.webp",
      "alt": "Men's Notch Lapel Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's Notch Lapel Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 58. Men's Pink Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Pink Velvet Blazer',
  'VB-018-MIX',
  'mens-pink-velvet-blazer',
  'mens-pink-velvet-blazer',
  'VELVET24-018',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-pink-velvet-blazer/main.webp",
      "alt": "Men's Pink Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-pink-velvet-blazer/lifestyle.webp",
        "alt": "Men's Pink Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Pink Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 59. Men's Purple Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Velvet Blazer',
  'VB-019-PUR',
  'mens-purple-velvet-blazer',
  'mens-purple-velvet-blazer',
  'VELVET24-019',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Purple',
  'Purple',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer/main.webp",
      "alt": "Men's Purple Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer/lifestyle.webp",
        "alt": "Men's Purple Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Purple Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 60. Men's Purple Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Velvet Blazer With Bowtie',
  'VB-020-PUR',
  'mens-purple-velvet-blazer-with-bowtie',
  'mens-purple-velvet-blazer-with-bowtie',
  'VELVET24-020',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Purple',
  'Purple',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer-with-bowtie/main.webp",
      "alt": "Men's Purple Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Purple Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 61. Men's Red Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Paisley Pattern Velvet Blazer',
  'VB-021-RED',
  'mens-red-paisley-pattern-velvet-blazer',
  'mens-red-paisley-pattern-velvet-blazer',
  'VELVET24-021',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Red',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Men's Red Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-paisley-pattern-velvet-blazer/side.webp",
        "alt": "Men's Red Paisley Pattern Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Red Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 62. Men's Red Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Velvet Blazer With Bowtie',
  'VB-022-RED',
  'mens-red-velvet-blazer-with-bowtie',
  'mens-red-velvet-blazer-with-bowtie',
  'VELVET24-022',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Red',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-velvet-blazer-with-bowtie/main.webp",
      "alt": "Men's Red Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-velvet-blazer-with-bowtie/side.webp",
        "alt": "Men's Red Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Red Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 63. Men's Royal Blue Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Paisley Pattern Velvet Blazer',
  'VB-023-BLU',
  'mens-royal-blue-paisley-pattern-velvet-blazer',
  'mens-royal-blue-paisley-pattern-velvet-blazer',
  'VELVET24-023',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Royal Blue',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-paisley-pattern-velvet-blazer/main.webp",
      "alt": "Men's Royal Blue Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-paisley-pattern-velvet-blazer/lifestyle.webp",
        "alt": "Men's Royal Blue Paisley Pattern Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Royal Blue Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 64. Men's Royal Blue Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Velvet Blazer',
  'VB-024-BLU',
  'mens-royal-blue-velvet-blazer',
  'mens-royal-blue-velvet-blazer',
  'VELVET24-024',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Royal Blue',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer/main.webp",
      "alt": "Men's Royal Blue Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men's Royal Blue Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 65. Men's Royal Blue Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Velvet Blazer With Bowtie',
  'VB-025-BLU',
  'mens-royal-blue-velvet-blazer-with-bowtie',
  'mens-royal-blue-velvet-blazer-with-bowtie',
  'VELVET24-025',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Royal Blue',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer-with-bowtie/main.webp",
      "alt": "Men's Royal Blue Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer-with-bowtie/side.webp",
        "alt": "Men's Royal Blue Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Royal Blue Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 66. Men's White Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Velvet Blazer',
  'VB-026-WHT',
  'mens-white-velvet-blazer',
  'mens-white-velvet-blazer',
  'VELVET24-026',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'White',
  'White',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-white-velvet-blazer/main.webp",
      "alt": "Men's White Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men's White Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 67. Men's Wine Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Wine Velvet Blazer',
  'VB-027-MIX',
  'mens-wine-velvet-blazer',
  'mens-wine-velvet-blazer',
  'VELVET24-027',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-wine-velvet-blazer/main.webp",
      "alt": "Men's Wine Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-wine-velvet-blazer/side.webp",
        "alt": "Men's Wine Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men's Wine Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 68. Notch Lapel Black Velvet Tuxedo
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Notch Lapel Black Velvet Tuxedo',
  'VB-028-BLK',
  'notch-lapel-black-velvet-tuxedo',
  'notch-lapel-black-velvet-tuxedo',
  'VELVET24-028',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/notch-lapel-black-velvet-tuxedo/main.webp",
      "alt": "Notch Lapel Black Velvet Tuxedo - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Notch Lapel Black Velvet Tuxedo from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();

-- 69. Notch Lapel Navy Velvet Tuxedo
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Notch Lapel Navy Velvet Tuxedo',
  'VB-029-NVY',
  'notch-lapel-navy-velvet-tuxedo',
  'notch-lapel-navy-velvet-tuxedo',
  'VELVET24-029',
  'FW24',
  'Velvet Collection',
  'Blazers',
  'Velvet',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/notch-lapel-navy-velvet-tuxedo/main.webp",
      "alt": "Notch Lapel Navy Velvet Tuxedo - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Notch Lapel Navy Velvet Tuxedo from our velvet collection.',
  'active'
) ON CONFLICT (sku) DO UPDATE SET
  images = EXCLUDED.images,
  updated_at = NOW();


-- ============================================
-- SUMMARY
-- ============================================
-- Total products generated: 69
-- Categories: prom, sparkle, summer, velvet

-- Verify all products
SELECT 
  subcategory,
  COUNT(*) as count
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY subcategory;

-- Show sample products
SELECT 
  name,
  sku,
  subcategory,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->'hero'->>'url' as hero_image
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY created_at DESC
LIMIT 10;