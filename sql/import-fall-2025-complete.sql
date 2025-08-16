-- Import Fall 2025 Collection with ALL Required Fields
-- This version includes slug, price_tier, and all other required fields

-- Helper functions
CREATE OR REPLACE FUNCTION get_price_tier(price NUMERIC) RETURNS TEXT AS $$
BEGIN
  IF price < 75 THEN RETURN 'TIER_1';
  ELSIF price < 100 THEN RETURN 'TIER_2';
  ELSIF price < 125 THEN RETURN 'TIER_3';
  ELSIF price < 150 THEN RETURN 'TIER_4';
  ELSIF price < 200 THEN RETURN 'TIER_5';
  ELSIF price < 250 THEN RETURN 'TIER_6';
  ELSIF price < 300 THEN RETURN 'TIER_7';
  ELSIF price < 400 THEN RETURN 'TIER_8';
  ELSIF price < 500 THEN RETURN 'TIER_9';
  ELSE RETURN 'TIER_10';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_fall_keywords(
  category TEXT,
  color TEXT
) RETURNS TEXT[] AS $$
BEGIN
  RETURN ARRAY[
    'fall 2025 collection',
    LOWER(category),
    color || ' ' || LOWER(category),
    'mens ' || LOWER(category),
    'formal wear',
    'designer ' || LOWER(category),
    'premium menswear',
    'buy ' || LOWER(category) || ' online'
  ];
END;
$$ LANGUAGE plpgsql;

-- Import Double-Breasted Suits
DO $$
DECLARE
  product_id UUID;
  base_price NUMERIC := 449.99;
BEGIN
  
  -- Black Pinstripe Shawl Lapel Double-Breasted Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, og_image, canonical_url, structured_data, tags,
    search_terms, url_slug, is_indexable, sitemap_priority,
    sitemap_change_freq, created_at, updated_at
  ) VALUES (
    product_id,
    'Black Pinstripe Shawl Lapel Double-Breasted Suit',
    'F25-DBS-001',
    'black-pinstripe-shawl-lapel-double-breasted-suit',
    'black-pinstripe-shawl-lapel-double-breasted-suit',
    'DBS-BPSL-001',
    'Fall 2025',
    'Fall 2025 Collection',
    'Double-Breasted Suits',
    'Executive Collection',
    get_price_tier(base_price),
    base_price,
    599.99,
    'Black Pinstripe',
    'Black',
    '{"primary": "Premium Wool Blend", "lining": "Viscose", "buttons": "Horn"}',
    'Modern Fit',
    '{"hero": {"url": "https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/main.webp"},
      "gallery": [
        {"url": "https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/front.webp"},
        {"url": "https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/back.webp"}
      ]}',
    'Introducing our Black Pinstripe Shawl Lapel Double-Breasted Suit from the Fall 2025 Collection. ' ||
    'This sophisticated executive suit features a luxurious wool blend with classic pinstripe pattern. ' ||
    'The shawl lapel adds a touch of elegance perfect for boardroom meetings and formal events. ' ||
    'Features include interior pockets, professional finishing, and horn buttons. ' ||
    'Available in sizes 36R-54R and 36L-54L. Free shipping on orders over $200.',
    'active',
    'Black Pinstripe Double-Breasted Suit | Fall 2025 | KCT Menswear',
    'Shop Black Pinstripe Double-Breasted Suit at $449.99. Executive shawl lapel design. Fall 2025 Collection.',
    generate_fall_keywords('Double-Breasted Suits', 'Black Pinstripe'),
    'Black Pinstripe Shawl Lapel Double-Breasted Suit',
    'Sophisticated Black Pinstripe Double-Breasted Suit with elegant shawl lapel. Perfect for executives.',
    'https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/main.webp',
    'https://kctmenswear.com/products/black-pinstripe-shawl-lapel-double-breasted-suit',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Black Pinstripe Double-Breasted Suit", "price": "449.99", "priceCurrency": "USD"}',
    ARRAY['suits', 'double-breasted', 'black', 'pinstripe', 'fall-2025', 'executive'],
    'black pinstripe double breasted suit shawl lapel executive formal',
    'black-pinstripe-shawl-lapel-double-breasted-suit',
    true,
    0.9,
    'weekly',
    NOW(),
    NOW()
  );

  -- Forest Green Mocha Double-Breasted Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, og_image, canonical_url, structured_data, tags,
    search_terms, url_slug, is_indexable, sitemap_priority,
    sitemap_change_freq, created_at, updated_at
  ) VALUES (
    product_id,
    'Forest Green Mocha Double-Breasted Suit',
    'F25-DBS-002',
    'forest-green-mocha-double-breasted-suit',
    'forest-green-mocha-double-breasted-suit',
    'DBS-FGM-002',
    'Fall 2025',
    'Fall 2025 Collection',
    'Double-Breasted Suits',
    'Designer Collection',
    get_price_tier(base_price),
    base_price,
    599.99,
    'Forest Green Mocha',
    'Green',
    '{"primary": "Premium Wool Blend", "lining": "Viscose", "buttons": "Horn"}',
    'Modern Fit',
    '{"hero": {"url": "https://cdn.kctmenswear.com/double-breasted-suits/fall-forest-green-mocha-double-breasted-suit/main.webp"}}',
    'Stand out with our Forest Green Mocha Double-Breasted Suit from the Fall 2025 Collection. ' ||
    'This unique color combination is perfect for fall weddings and special occasions. ' ||
    'Crafted from premium wool blend with expert tailoring and attention to detail. ' ||
    'The rich forest green with mocha undertones creates a sophisticated autumn look. ' ||
    'Available in sizes 36R-54R and 36L-54L. Free shipping on orders over $200.',
    'active',
    'Forest Green Mocha Double-Breasted Suit | Fall 2025 | KCT Menswear',
    'Shop Forest Green Mocha Double-Breasted Suit at $449.99. Unique fall colors. Designer collection.',
    generate_fall_keywords('Double-Breasted Suits', 'Forest Green'),
    'Forest Green Mocha Double-Breasted Suit - Fall 2025',
    'Unique Forest Green Mocha Double-Breasted Suit perfect for fall weddings and special events.',
    'https://cdn.kctmenswear.com/double-breasted-suits/fall-forest-green-mocha-double-breasted-suit/main.webp',
    'https://kctmenswear.com/products/forest-green-mocha-double-breasted-suit',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Forest Green Mocha Double-Breasted Suit", "price": "449.99", "priceCurrency": "USD"}',
    ARRAY['suits', 'double-breasted', 'green', 'fall-2025', 'wedding', 'unique'],
    'forest green mocha double breasted suit fall wedding unique',
    'forest-green-mocha-double-breasted-suit',
    true,
    0.9,
    'weekly',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Double-Breasted Suits imported successfully';
END $$;

-- Import Tuxedos
DO $$
DECLARE
  product_id UUID;
  base_price NUMERIC := 499.99;
BEGIN
  
  -- Classic Black Tuxedo with Satin Lapels
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, og_image, canonical_url, structured_data, tags,
    search_terms, url_slug, is_indexable, sitemap_priority,
    sitemap_change_freq, created_at, updated_at
  ) VALUES (
    product_id,
    'Classic Black Tuxedo with Satin Lapels',
    'F25-TUX-001',
    'classic-black-tuxedo-satin-lapels',
    'classic-black-tuxedo-satin-lapels',
    'TUX-BLK-001',
    'Fall 2025',
    'Fall 2025 Collection',
    'Tuxedos',
    'Black Tie Collection',
    get_price_tier(base_price),
    base_price,
    699.99,
    'Black',
    'Black',
    '{"primary": "Premium Wool", "lapels": "Silk Satin", "lining": "Silk Blend", "buttons": "Covered"}',
    'Slim Fit',
    '{"hero": {"url": "https://cdn.kctmenswear.com/tuxedos/classic-black/main.webp"}}',
    'Experience timeless elegance with our Classic Black Tuxedo featuring luxurious satin lapels. ' ||
    'Perfect for black-tie events, weddings, galas, and formal occasions. ' ||
    'Crafted from premium wool with silk satin lapels and professional finishing. ' ||
    'Modern slim fit tailoring ensures a sophisticated silhouette. ' ||
    'Available in sizes 36R-54R and 36L-54L. Free shipping and expert tailoring available.',
    'active',
    'Classic Black Tuxedo | Formal Tuxedos | KCT Menswear',
    'Shop Classic Black Tuxedo at $499.99. Satin lapels, premium wool. Perfect for black-tie events.',
    generate_fall_keywords('Tuxedos', 'Black'),
    'Classic Black Tuxedo with Satin Lapels',
    'Timeless black tuxedo with satin lapels. The ultimate in formal elegance.',
    'https://cdn.kctmenswear.com/tuxedos/classic-black/main.webp',
    'https://kctmenswear.com/products/classic-black-tuxedo-satin-lapels',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Classic Black Tuxedo", "price": "499.99", "priceCurrency": "USD"}',
    ARRAY['tuxedo', 'black-tie', 'formal', 'wedding', 'gala', 'fall-2025'],
    'black tuxedo satin lapels formal black tie wedding gala',
    'classic-black-tuxedo-satin-lapels',
    true,
    1.0,
    'weekly',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Tuxedos imported successfully';
END $$;

-- Import Stretch Suits
DO $$
DECLARE
  product_id UUID;
  base_price NUMERIC := 399.99;
BEGIN
  
  -- Navy Blue Performance Stretch Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, og_image, canonical_url, structured_data, tags,
    search_terms, url_slug, is_indexable, sitemap_priority,
    sitemap_change_freq, created_at, updated_at
  ) VALUES (
    product_id,
    'Navy Blue Performance Stretch Suit',
    'F25-STR-001',
    'navy-blue-performance-stretch-suit',
    'navy-blue-performance-stretch-suit',
    'STR-NVY-001',
    'Fall 2025',
    'Fall 2025 Collection',
    'Stretch Suits',
    'Performance Collection',
    get_price_tier(base_price),
    base_price,
    549.99,
    'Navy Blue',
    'Blue',
    '{"primary": "Wool Blend with Elastane", "lining": "Breathable Mesh", "stretch": "4-way"}',
    'Athletic Fit',
    '{"hero": {"url": "https://cdn.kctmenswear.com/stretch-suits/navy-blue/main.webp"}}',
    'Experience all-day comfort with our Navy Blue Performance Stretch Suit. ' ||
    'Perfect for long workdays, travel, and active professionals. ' ||
    'Premium stretch fabric blend with 4-way stretch technology for maximum flexibility. ' ||
    'Athletic fit design accommodates movement while maintaining sharp appearance. ' ||
    'Available in sizes 36R-54R and 36L-54L. Wrinkle-resistant and machine washable.',
    'active',
    'Navy Blue Stretch Suit | Performance Suits | KCT Menswear',
    'Shop Navy Blue Performance Stretch Suit at $399.99. 4-way stretch, athletic fit. All-day comfort.',
    generate_fall_keywords('Stretch Suits', 'Navy Blue'),
    'Navy Blue Performance Stretch Suit',
    'All-day comfort Navy Blue Stretch Suit with 4-way stretch technology.',
    'https://cdn.kctmenswear.com/stretch-suits/navy-blue/main.webp',
    'https://kctmenswear.com/products/navy-blue-performance-stretch-suit',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Navy Blue Performance Stretch Suit", "price": "399.99", "priceCurrency": "USD"}',
    ARRAY['suits', 'stretch', 'performance', 'navy', 'comfort', 'fall-2025'],
    'navy blue stretch suit performance comfort travel athletic',
    'navy-blue-performance-stretch-suit',
    true,
    0.9,
    'weekly',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Stretch Suits imported successfully';
END $$;

-- Clean up functions
DROP FUNCTION IF EXISTS get_price_tier(NUMERIC);
DROP FUNCTION IF EXISTS generate_fall_keywords(TEXT, TEXT);

-- Verify the import
SELECT 
  category,
  COUNT(*) as product_count,
  MIN(base_price) as min_price,
  MAX(base_price) as max_price,
  STRING_AGG(DISTINCT price_tier, ', ') as price_tiers
FROM products_enhanced
WHERE sku LIKE 'F25-%'
GROUP BY category
ORDER BY category;