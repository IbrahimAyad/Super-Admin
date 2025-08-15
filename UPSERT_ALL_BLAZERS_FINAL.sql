-- UPSERT ALL BLAZERS WITH HANDLE CONFLICT RESOLUTION
-- Generated on: 2025-08-15T06:04:18.707Z
-- This handles duplicates by updating existing products

-- Check current state
SELECT 'Before Insert' as status, COUNT(*) as blazer_count 
FROM products_enhanced WHERE category = 'Blazers';


-- PROM BLAZERS (18 products)

-- 1. Men's Black Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Floral Pattern Prom Blazer',
  'PB-BLFLPA-001',
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
      "alt": "Mens Black Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/back.webp",
        "alt": "Mens Black Floral Pattern Prom Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Mens Black Floral Pattern Prom Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/side.webp",
        "alt": "Mens Black Floral Pattern Prom Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Mens Black Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/front-close.webp",
        "alt": "Mens Black Floral Pattern Prom Blazer - front close"
      }
    ],
    "total_images": 7
  }'::jsonb,
  'Men''s Black Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 2. Men's Black Geometric Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Geometric Pattern Prom Blazer',
  'PB-BLGEPA-002',
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
      "alt": "Mens Black Geometric Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/lifestyle.webp",
        "alt": "Mens Black Geometric Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Black Geometric Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 3. Men's Black Glitter Finish Prom Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Glitter Finish Prom Blazer Shawl Lapel',
  'PB-BLGLFI-003',
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
      "alt": "Mens Black Glitter Finish Prom Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Mens Black Glitter Finish Prom Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Black Glitter Finish Prom Blazer Shawl Lapel from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 4. Men's Black Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Prom Blazer With Bowtie',
  'PB-BLPRBL-004',
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
      "alt": "Mens Black Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Mens Black Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Black Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 5. Men's Burgundy Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Floral Pattern Prom Blazer',
  'PB-BUFLPA-005',
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
      "alt": "Mens Burgundy Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Mens Burgundy Floral Pattern Prom Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/side.webp",
        "alt": "Mens Burgundy Floral Pattern Prom Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Mens Burgundy Floral Pattern Prom Blazer - close side"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Burgundy Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 6. Men's Burgundy Paisley Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Paisley Pattern Prom Blazer With Bowtie',
  'PB-BUPAPA-006',
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
      "alt": "Mens Burgundy Paisley Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s Burgundy Paisley Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 7. Men's Gold Paisley Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Paisley Pattern Prom Blazer With Bowtie',
  'PB-GOPAPA-007',
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
      "alt": "Mens Gold Paisley Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-paisley-pattern-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Mens Gold Paisley Pattern Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Gold Paisley Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 8. Men's Gold Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Prom Blazer',
  'PB-GOPRBL-008',
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
      "alt": "Mens Gold Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/lifestyle.webp",
        "alt": "Mens Gold Prom Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/side.webp",
        "alt": "Mens Gold Prom Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/close-side.webp",
        "alt": "Mens Gold Prom Blazer - close side"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Gold Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 9. Men's Off White Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Off White Prom Blazer With Bowtie',
  'PB-OFWHPR-009',
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
      "alt": "Mens Off White Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s Off White Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 10. Men's Purple Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Floral Pattern Prom Blazer',
  'PB-PUFLPA-010',
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
      "alt": "Mens Purple Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-purple-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Mens Purple Floral Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Purple Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 11. Men's Red Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Floral Pattern Prom Blazer',
  'PB-REFLPA-011',
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
      "alt": "Mens Red Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer/lifestyle.webp",
        "alt": "Mens Red Floral Pattern Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Red Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 12. Men's Red Floral Pattern Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Floral Pattern Prom Blazer With Bowtie',
  'PB-REFLPA-012',
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
      "alt": "Mens Red Floral Pattern Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Red Floral Pattern Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 13. Men's Red Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Prom Blazer With Bowtie',
  'PB-REPRBL-013',
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
      "alt": "Mens Red Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Mens Red Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Red Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 14. Men's Royal Blue Embellished Design Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Embellished Design Prom Blazer',
  'PB-ROBLEM-014',
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
      "alt": "Mens Royal Blue Embellished Design Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-embellished-design-prom-blazer/lifestyle.webp",
        "alt": "Mens Royal Blue Embellished Design Prom Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Royal Blue Embellished Design Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 15. Men's Royal Blue Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Prom Blazer With Bowtie',
  'PB-ROBLPR-015',
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
      "alt": "Mens Royal Blue Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/lifestyle.webp",
        "alt": "Mens Royal Blue Prom Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Royal Blue Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 16. Men's Teal Floral Pattern Prom Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Teal Floral Pattern Prom Blazer',
  'PB-TEFLPA-016',
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
      "alt": "Mens Teal Floral Pattern Prom Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/close-side.webp",
        "alt": "Mens Teal Floral Pattern Prom Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/front-close.webp",
        "alt": "Mens Teal Floral Pattern Prom Blazer - front close"
      }
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Teal Floral Pattern Prom Blazer from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 17. Men's White Prom Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Prom Blazer With Bowtie',
  'PB-WHPRBL-017',
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
      "alt": "Mens White Prom Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s White Prom Blazer With Bowtie from our prom collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 18. Men's White Rhinestone Embellished Prom Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Rhinestone Embellished Prom Blazer Shawl Lapel',
  'PB-WHRHEM-018',
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
      "alt": "Mens White Rhinestone Embellished Prom Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/prom/mens-white-rhinestone-embellished-prom-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Mens White Rhinestone Embellished Prom Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s White Rhinestone Embellished Prom Blazer Shawl Lapel from our prom collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- SPARKLE BLAZERS (16 products)

-- 19. Men's Black Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Glitter Finish Sparkle Blazer',
  'SPB-BLGLFI-001',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Black Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Mens Black Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Mens Black Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Black Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Black Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 20. Men's Black Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Sparkle Texture Sparkle Blazer',
  'SPB-BLSPTE-002',
  'mens-black-sparkle-texture-sparkle-blazer',
  'mens-black-sparkle-texture-sparkle-blazer',
  'SPARKLE24-002',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Black',
  'Black',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Black Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Mens Black Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Black Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Black Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Black Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 21. Men's Blue Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Sparkle Blazer',
  'SPB-BLSPBL-003',
  'mens-blue-sparkle-blazer',
  'mens-blue-sparkle-blazer',
  'SPARKLE24-003',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Blue',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer/main.webp",
      "alt": "Mens Blue Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s Blue Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 22. Men's Blue Sparkle Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Sparkle Blazer Shawl Lapel',
  'SPB-BLSPBL-004',
  'mens-blue-sparkle-blazer-shawl-lapel',
  'mens-blue-sparkle-blazer-shawl-lapel',
  'SPARKLE24-004',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Blue',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer-shawl-lapel/main.webp",
      "alt": "Mens Blue Sparkle Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer-shawl-lapel/front-close.webp",
        "alt": "Mens Blue Sparkle Blazer Shawl Lapel - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Blue Sparkle Blazer Shawl Lapel from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 23. Men's Burgundy Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Glitter Finish Sparkle Blazer',
  'SPB-BUGLFI-005',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Burgundy Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/back.webp",
        "alt": "Mens Burgundy Glitter Finish Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Mens Burgundy Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Mens Burgundy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Burgundy Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Burgundy Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 24. Men's Burgundy Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Burgundy Sparkle Texture Sparkle Blazer',
  'SPB-BUSPTE-006',
  'mens-burgundy-sparkle-texture-sparkle-blazer',
  'mens-burgundy-sparkle-texture-sparkle-blazer',
  'SPARKLE24-006',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Red',
  'Burgundy',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Burgundy Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Mens Burgundy Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Mens Burgundy Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Burgundy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Burgundy Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Burgundy Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 25. Men's Gold Baroque Pattern Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Baroque Pattern Sparkle Blazer',
  'SPB-GOBAPA-007',
  'mens-gold-baroque-pattern-sparkle-blazer',
  'mens-gold-baroque-pattern-sparkle-blazer',
  'SPARKLE24-007',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Gold',
  'Gold',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-baroque-pattern-sparkle-blazer/main.webp",
      "alt": "Mens Gold Baroque Pattern Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-baroque-pattern-sparkle-blazer/front-close.webp",
        "alt": "Mens Gold Baroque Pattern Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Gold Baroque Pattern Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 26. Men's Gold Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Glitter Finish Sparkle Blazer',
  'SPB-GOGLFI-008',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Gold Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Mens Gold Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Mens Gold Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Gold Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Gold Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 27. Men's Gold Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Gold Sparkle Texture Sparkle Blazer',
  'SPB-GOSPTE-009',
  'mens-gold-sparkle-texture-sparkle-blazer',
  'mens-gold-sparkle-texture-sparkle-blazer',
  'SPARKLE24-009',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Gold',
  'Gold',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Gold Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Mens Gold Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Mens Gold Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Gold Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Gold Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Gold Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 28. Men's Green Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Glitter Finish Sparkle Blazer',
  'SPB-GRGLFI-010',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Green Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/back.webp",
        "alt": "Mens Green Glitter Finish Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Mens Green Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Mens Green Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Green Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Green Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 29. Men's Green Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Sparkle Texture Sparkle Blazer',
  'SPB-GRSPTE-011',
  'mens-green-sparkle-texture-sparkle-blazer',
  'mens-green-sparkle-texture-sparkle-blazer',
  'SPARKLE24-011',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Multi',
  'Multi-Color',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Green Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/back.webp",
        "alt": "Mens Green Sparkle Texture Sparkle Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Mens Green Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Green Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Green Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Green Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 30. Men's Navy Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Glitter Finish Sparkle Blazer',
  'SPB-NAGLFI-012',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Navy Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/side.webp",
        "alt": "Mens Navy Glitter Finish Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/close-side.webp",
        "alt": "Mens Navy Glitter Finish Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Navy Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Navy Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 31. Men's Navy Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Sparkle Texture Sparkle Blazer',
  'SPB-NASPTE-013',
  'mens-navy-sparkle-texture-sparkle-blazer',
  'mens-navy-sparkle-texture-sparkle-blazer',
  'SPARKLE24-013',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Navy',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Navy Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/side.webp",
        "alt": "Mens Navy Sparkle Texture Sparkle Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Navy Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Navy Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Navy Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 32. Men's Red Glitter Finish Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Glitter Finish Sparkle Blazer',
  'SPB-REGLFI-014',
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
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-red-glitter-finish-sparkle-blazer/main.webp",
      "alt": "Mens Red Glitter Finish Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-red-glitter-finish-sparkle-blazer/front-close.webp",
        "alt": "Mens Red Glitter Finish Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Red Glitter Finish Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 33. Men's Royal Blue Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Sparkle Texture Sparkle Blazer',
  'SPB-ROBLSP-015',
  'mens-royal-blue-sparkle-texture-sparkle-blazer',
  'mens-royal-blue-sparkle-texture-sparkle-blazer',
  'SPARKLE24-015',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'Blue',
  'Royal Blue',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens Royal Blue Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/close-side.webp",
        "alt": "Mens Royal Blue Sparkle Texture Sparkle Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens Royal Blue Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Royal Blue Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 34. Men's White Sparkle Texture Sparkle Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Sparkle Texture Sparkle Blazer',
  'SPB-WHSPTE-016',
  'mens-white-sparkle-texture-sparkle-blazer',
  'mens-white-sparkle-texture-sparkle-blazer',
  'SPARKLE24-016',
  'FW24',
  'Sparkle Collection',
  'Blazers',
  'Sparkle',
  'TIER_8',
  34999,
  43748,
  'White',
  'White',
  '{"primary": "Sparkle Fabric", "composition": {"Polyester": 75, "Metallic Fiber": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-white-sparkle-texture-sparkle-blazer/main.webp",
      "alt": "Mens White Sparkle Texture Sparkle Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/sparkle/mens-white-sparkle-texture-sparkle-blazer/front-close.webp",
        "alt": "Mens White Sparkle Texture Sparkle Blazer - front close"
      }
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s White Sparkle Texture Sparkle Blazer from our sparkle collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- SUMMER BLAZERS (6 products)

-- 35. Men's Blue Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Blue Casual Summer Blazer',
  'SB-BLCASU-001',
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
      "alt": "Mens Blue Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/back.webp",
        "alt": "Mens Blue Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/side.webp",
        "alt": "Mens Blue Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/close-side.webp",
        "alt": "Mens Blue Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/front-close.webp",
        "alt": "Mens Blue Casual Summer Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Blue Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 36. Men's Brown Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Brown Casual Summer Blazer',
  'SB-BRCASU-002',
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
      "alt": "Mens Brown Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Brown Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 37. Men's Mint Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Mint Casual Summer Blazer',
  'SB-MICASU-003',
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
      "alt": "Mens Mint Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/back.webp",
        "alt": "Mens Mint Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/lifestyle.webp",
        "alt": "Mens Mint Casual Summer Blazer - lifestyle"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/side.webp",
        "alt": "Mens Mint Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/close-side.webp",
        "alt": "Mens Mint Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/front-close.webp",
        "alt": "Mens Mint Casual Summer Blazer - front close"
      }
    ],
    "total_images": 6
  }'::jsonb,
  'Men''s Mint Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 38. Men's Pink Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Pink Casual Summer Blazer',
  'SB-PICASU-004',
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
  'Pink',
  'Pink',
  '{"primary": "Polyester Blend", "composition": {"Polyester": 75, "Viscose": 25}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/main.webp",
      "alt": "Mens Pink Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/side.webp",
        "alt": "Mens Pink Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/close-side.webp",
        "alt": "Mens Pink Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/front-close.webp",
        "alt": "Mens Pink Casual Summer Blazer - front close"
      }
    ],
    "total_images": 4
  }'::jsonb,
  'Men''s Pink Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 39. Men's Salmon Casual Summer Blazer 2025
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Salmon Casual Summer Blazer 2025',
  'SB-SACASU-005',
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
      "alt": "Mens Salmon Casual Summer Blazer 2025 - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/back.webp",
        "alt": "Mens Salmon Casual Summer Blazer 2025 - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/lifestyle.webp",
        "alt": "Mens Salmon Casual Summer Blazer 2025 - lifestyle"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/close-up.webp",
        "alt": "Mens Salmon Casual Summer Blazer 2025 - close up"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/main-close.webp",
        "alt": "Mens Salmon Casual Summer Blazer 2025 - main close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Salmon Casual Summer Blazer 2025 from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 40. Men's Yellow Casual Summer Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Yellow Casual Summer Blazer',
  'SB-YECASU-006',
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
      "alt": "Mens Yellow Casual Summer Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/back.webp",
        "alt": "Mens Yellow Casual Summer Blazer - back"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/side.webp",
        "alt": "Mens Yellow Casual Summer Blazer - side"
      }
    ],
    "details": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/close-side.webp",
        "alt": "Mens Yellow Casual Summer Blazer - close side"
      },
      {
        "url": "https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/front-close.webp",
        "alt": "Mens Yellow Casual Summer Blazer - front close"
      }
    ],
    "total_images": 5
  }'::jsonb,
  'Men''s Yellow Casual Summer Blazer from our summer collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- VELVET BLAZERS (29 products)

-- 41. Men's All Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Navy Velvet Blazer',
  'VB-ALNAVE-001',
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
      "alt": "Mens All Navy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s All Navy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 42. Men's All Navy Velvet Jacker
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Navy Velvet Jacker',
  'VB-ALNAVE-002',
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
      "alt": "Mens All Navy Velvet Jacker - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-jacker/side.webp",
        "alt": "Mens All Navy Velvet Jacker - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s All Navy Velvet Jacker from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 43. Men's All Red Velvet Jacker
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s All Red Velvet Jacker',
  'VB-ALREVE-003',
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
      "alt": "Mens All Red Velvet Jacker - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-all-red-velvet-jacker/side.webp",
        "alt": "Mens All Red Velvet Jacker - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s All Red Velvet Jacker from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 44. Men's Black Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Paisley Pattern Velvet Blazer',
  'VB-BLPAPA-004',
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
      "alt": "Mens Black Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/side.webp",
        "alt": "Mens Black Paisley Pattern Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Black Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 45. Men's Black Velvet Blazer Shawl Lapel
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Velvet Blazer Shawl Lapel',
  'VB-BLVEBL-005',
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
      "alt": "Mens Black Velvet Blazer Shawl Lapel - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-blazer-shawl-lapel/lifestyle.webp",
        "alt": "Mens Black Velvet Blazer Shawl Lapel - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Black Velvet Blazer Shawl Lapel from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 46. Men's Black Velvet Jacket
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Black Velvet Jacket',
  'VB-BLVEJA-006',
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
      "alt": "Mens Black Velvet Jacket - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-jacket/side.webp",
        "alt": "Mens Black Velvet Jacket - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Black Velvet Jacket from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 47. Men's Brown Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Brown Velvet Blazer With Bowtie',
  'VB-BRVEBL-007',
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
      "alt": "Mens Brown Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-brown-velvet-blazer-with-bowtie/lifestyle.webp",
        "alt": "Mens Brown Velvet Blazer With Bowtie - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Brown Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 48. Men's Cherry Red Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Cherry Red Velvet Blazer',
  'VB-CHREVE-008',
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
      "alt": "Mens Cherry Red Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Cherry Red Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 49. Men's Dark Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Dark Burgundy Velvet Blazer',
  'VB-DABUVE-009',
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
      "alt": "Mens Dark Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Dark Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 50. Men's Euro Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Euro Burgundy Velvet Blazer',
  'VB-EUBUVE-010',
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
      "alt": "Mens Euro Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Euro Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 51. Men's Green Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Paisley Pattern Velvet Blazer',
  'VB-GRPAPA-011',
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
      "alt": "Mens Green Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Green Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 52. Men's Green Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Velvet Blazer',
  'VB-GRVEBL-012',
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
      "alt": "Mens Green Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Green Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 53. Men's Green Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Green Velvet Blazer With Bowtie',
  'VB-GRVEBL-013',
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
      "alt": "Mens Green Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer-with-bowtie/side.webp",
        "alt": "Mens Green Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Green Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 54. Men's Hunter Green Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Hunter Green Velvet Blazer',
  'VB-HUGRVE-014',
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
      "alt": "Mens Hunter Green Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-hunter-green-velvet-blazer/lifestyle.webp",
        "alt": "Mens Hunter Green Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Hunter Green Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 55. Men's Navy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Velvet Blazer',
  'VB-NAVEBL-015',
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
      "alt": "Mens Navy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer/side.webp",
        "alt": "Mens Navy Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Navy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 56. Men's Navy Velvet Blazer 2025 
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Navy Velvet Blazer 2025 ',
  'VB-NAVEBL-016',
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
      "alt": "Mens Navy Velvet Blazer 2025  - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer-2025-/lifestyle.webp",
        "alt": "Mens Navy Velvet Blazer 2025  - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Navy Velvet Blazer 2025  from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 57. Men's Notch Lapel Burgundy Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Notch Lapel Burgundy Velvet Blazer',
  'VB-NOLABU-017',
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
      "alt": "Mens Notch Lapel Burgundy Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s Notch Lapel Burgundy Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 58. Men's Pink Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Pink Velvet Blazer',
  'VB-PIVEBL-018',
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
  'Pink',
  'Pink',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Slim Fit',
  '{
    "hero": {
      "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-pink-velvet-blazer/main.webp",
      "alt": "Mens Pink Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-pink-velvet-blazer/lifestyle.webp",
        "alt": "Mens Pink Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Pink Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 59. Men's Purple Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Velvet Blazer',
  'VB-PUVEBL-019',
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
      "alt": "Mens Purple Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer/lifestyle.webp",
        "alt": "Mens Purple Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Purple Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 60. Men's Purple Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Purple Velvet Blazer With Bowtie',
  'VB-PUVEBL-020',
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
      "alt": "Mens Purple Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Purple Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 61. Men's Red Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Paisley Pattern Velvet Blazer',
  'VB-REPAPA-021',
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
      "alt": "Mens Red Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-paisley-pattern-velvet-blazer/side.webp",
        "alt": "Mens Red Paisley Pattern Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Red Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 62. Men's Red Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Red Velvet Blazer With Bowtie',
  'VB-REVEBL-022',
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
      "alt": "Mens Red Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-red-velvet-blazer-with-bowtie/side.webp",
        "alt": "Mens Red Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Red Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 63. Men's Royal Blue Paisley Pattern Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Paisley Pattern Velvet Blazer',
  'VB-ROBLPA-023',
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
      "alt": "Mens Royal Blue Paisley Pattern Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-paisley-pattern-velvet-blazer/lifestyle.webp",
        "alt": "Mens Royal Blue Paisley Pattern Velvet Blazer - lifestyle"
      }
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Royal Blue Paisley Pattern Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 64. Men's Royal Blue Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Velvet Blazer',
  'VB-ROBLVE-024',
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
      "alt": "Mens Royal Blue Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 2
  }'::jsonb,
  'Men''s Royal Blue Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 65. Men's Royal Blue Velvet Blazer With Bowtie
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Royal Blue Velvet Blazer With Bowtie',
  'VB-ROBLVE-025',
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
      "alt": "Mens Royal Blue Velvet Blazer With Bowtie - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer-with-bowtie/side.webp",
        "alt": "Mens Royal Blue Velvet Blazer With Bowtie - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Royal Blue Velvet Blazer With Bowtie from our velvet collection. Includes matching bowtie.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 66. Men's White Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s White Velvet Blazer',
  'VB-WHVEBL-026',
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
      "alt": "Mens White Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
    ],
    "details": [
    ],
    "total_images": 1
  }'::jsonb,
  'Men''s White Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 67. Men's Wine Velvet Blazer
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Men''s Wine Velvet Blazer',
  'VB-WIVEBL-027',
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
      "alt": "Mens Wine Velvet Blazer - Main View"
    },
    "flat": null,
    "lifestyle": [
      {
        "url": "https://cdn.kctmenswear.com/blazers/velvet/mens-wine-velvet-blazer/side.webp",
        "alt": "Mens Wine Velvet Blazer - side"
      }
    ],
    "details": [
    ],
    "total_images": 3
  }'::jsonb,
  'Men''s Wine Velvet Blazer from our velvet collection.',
  'active'
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 68. Notch Lapel Black Velvet Tuxedo
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Notch Lapel Black Velvet Tuxedo',
  'VB-NOLABL-028',
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
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- 69. Notch Lapel Navy Velvet Tuxedo
INSERT INTO products_enhanced (
  name, sku, handle, slug, style_code, season, collection,
  category, subcategory, price_tier, base_price, compare_at_price,
  color_family, color_name, materials, fit_type, images,
  description, status
) VALUES (
  'Notch Lapel Navy Velvet Tuxedo',
  'VB-NOLANA-029',
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
) ON CONFLICT (handle) DO UPDATE SET
  name = EXCLUDED.name,
  sku = CASE 
    WHEN products_enhanced.sku IS NULL OR products_enhanced.sku = '' 
    THEN EXCLUDED.sku 
    ELSE products_enhanced.sku 
  END,
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


-- SUMMARY
-- Total products: 69

-- Verify results
SELECT 'After Insert' as status, COUNT(*) as blazer_count 
FROM products_enhanced WHERE category = 'Blazers';

SELECT 
  subcategory,
  COUNT(*) as count
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY subcategory;

-- Show sample of products
SELECT 
  name,
  sku,
  handle,
  subcategory,
  price_tier,
  images->'hero'->>'url' as hero_image
FROM products_enhanced
WHERE category = 'Blazers'
ORDER BY updated_at DESC
LIMIT 10;