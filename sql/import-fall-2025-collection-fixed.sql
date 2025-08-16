-- Import Fall 2025 Collection into products_enhanced with Full SEO Optimization (FIXED)
-- Categories: Double-Breasted Suits, Mens Shirts, Stretch Suits, Suits, Tuxedos

-- Create SEO functions
CREATE OR REPLACE FUNCTION generate_seo_description(
  product_name TEXT,
  category TEXT,
  color TEXT
) RETURNS TEXT AS $$
DECLARE
  description TEXT;
  occasion_text TEXT;
  material_text TEXT;
  fit_text TEXT;
BEGIN
  -- Set occasion based on category
  CASE category
    WHEN 'Tuxedos' THEN
      occasion_text := 'Perfect for black-tie events, weddings, galas, and formal occasions. ';
      material_text := 'Premium wool blend with satin lapels. ';
      fit_text := 'Modern slim fit tailoring with classic elegance. ';
    WHEN 'Double-Breasted Suits' THEN
      occasion_text := 'Ideal for business meetings, weddings, and upscale events. ';
      material_text := 'Luxurious wool blend with fine craftsmanship. ';
      fit_text := 'Sophisticated double-breasted design with contemporary fit. ';
    WHEN 'Stretch Suits' THEN
      occasion_text := 'Perfect for all-day comfort at work or special events. ';
      material_text := 'Premium stretch fabric blend for flexibility and comfort. ';
      fit_text := 'Athletic fit with modern stretch technology. ';
    WHEN 'Suits' THEN
      occasion_text := 'Versatile for business, weddings, and formal events. ';
      material_text := 'High-quality wool blend with superior construction. ';
      fit_text := 'Classic or slim fit options available. ';
    WHEN 'Mens Shirts' THEN
      occasion_text := 'Essential for business attire or formal occasions. ';
      material_text := 'Premium cotton blend with wrinkle-resistant finish. ';
      fit_text := 'Tailored fit with comfort stretch. ';
    ELSE
      occasion_text := 'Perfect for any formal occasion. ';
      material_text := 'Premium quality materials. ';
      fit_text := 'Modern tailored fit. ';
  END CASE;

  -- Generate description
  description := 'Introducing our ' || product_name || ' from the exclusive Fall 2025 Collection. ' ||
                 occasion_text ||
                 material_text ||
                 fit_text ||
                 'Features include interior pockets, professional finishing, and attention to detail that sets KCT Menswear apart. ' ||
                 'Available in a full range of sizes with expert tailoring options. ' ||
                 'Shop with confidence - satisfaction guaranteed. Free shipping on orders over $200.';
                 
  RETURN description;
END;
$$ LANGUAGE plpgsql;

-- Create meta description function
CREATE OR REPLACE FUNCTION generate_meta_description(
  product_name TEXT,
  category TEXT,
  price NUMERIC
) RETURNS TEXT AS $$
BEGIN
  RETURN 'Shop ' || product_name || ' - Premium ' || category || ' starting at $' || price || 
         '. Fall 2025 Collection. Free shipping. Expert tailoring. Shop now at KCT Menswear.';
END;
$$ LANGUAGE plpgsql;

-- Create SEO keywords function (returns array)
CREATE OR REPLACE FUNCTION generate_seo_keywords(
  product_name TEXT,
  category TEXT,
  color TEXT
) RETURNS TEXT[] AS $$
DECLARE
  keywords TEXT[];
  category_keywords TEXT[];
BEGIN
  -- Base keywords
  keywords := ARRAY[
    'mens ' || LOWER(category),
    color || ' ' || LOWER(category),
    'formal wear',
    'menswear',
    product_name
  ];
  
  -- Category-specific keywords
  CASE category
    WHEN 'Tuxedos' THEN
      category_keywords := ARRAY[
        'black tie', 'formal tuxedo', 'wedding tuxedo', 'prom tuxedo', 
        'groom attire', 'luxury tuxedo'
      ];
    WHEN 'Double-Breasted Suits' THEN
      category_keywords := ARRAY[
        'double breasted jacket', 'business suit', 'executive suit', 
        'peak lapel suit', '6-button suit'
      ];
    WHEN 'Stretch Suits' THEN
      category_keywords := ARRAY[
        'comfort suit', 'flexible suit', 'travel suit', 
        'performance suit', 'modern fit suit'
      ];
    WHEN 'Suits' THEN
      category_keywords := ARRAY[
        'business suit', 'wedding suit', 'two piece suit', 
        'professional attire', 'office wear'
      ];
    WHEN 'Mens Shirts' THEN
      category_keywords := ARRAY[
        'dress shirt', 'formal shirt', 'business shirt', 
        'cotton shirt', 'fitted shirt'
      ];
    ELSE
      category_keywords := ARRAY['formal wear', 'business attire'];
  END CASE;
  
  keywords := keywords || category_keywords || ARRAY[
    'fall 2025 collection',
    'designer menswear',
    'affordable ' || LOWER(category),
    'buy ' || LOWER(category) || ' online'
  ];
              
  RETURN keywords;
END;
$$ LANGUAGE plpgsql;

-- Insert Fall 2025 Collection products
DO $$
DECLARE
  product_id UUID;
  sku_prefix TEXT;
  base_price NUMERIC;
BEGIN
  -- Set base prices based on category
  -- Double-Breasted Suits
  base_price := 449.99;
  sku_prefix := 'F25-DBS';
  
  -- Black Strip Shawl Lapel Double-Breasted Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, handle, sku, category, base_price, 
    color_name, color_family, 
    description,
    meta_title,
    meta_description,
    meta_keywords,
    og_title,
    og_description,
    search_terms,
    url_slug,
    is_indexable,
    sitemap_priority,
    status, created_at, updated_at
  ) VALUES (
    product_id,
    'Black Pinstripe Shawl Lapel Double-Breasted Suit',
    'black-pinstripe-shawl-lapel-double-breasted-suit',
    sku_prefix || '-001',
    'Double-Breasted Suits',
    base_price,
    'Black Pinstripe',
    'Black',
    generate_seo_description('Black Pinstripe Shawl Lapel Double-Breasted Suit', 'Double-Breasted Suits', 'Black'),
    'Black Pinstripe Double-Breasted Suit | Fall 2025 | KCT Menswear',
    generate_meta_description('Black Pinstripe Shawl Lapel Double-Breasted Suit', 'Double-Breasted Suits', base_price),
    generate_seo_keywords('Black Pinstripe Shawl Lapel Double-Breasted Suit', 'Double-Breasted Suits', 'Black'),
    'Black Pinstripe Shawl Lapel Double-Breasted Suit - Fall 2025 Collection',
    'Sophisticated Black Pinstripe Double-Breasted Suit with shawl lapel. Perfect for executive meetings and formal events.',
    'black pinstripe double breasted suit shawl lapel formal business',
    'black-pinstripe-shawl-lapel-double-breasted-suit',
    true,
    0.9,
    'active',
    NOW(),
    NOW()
  );

  -- Forest Green Mocha Double-Breasted Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, handle, sku, category, base_price,
    color_name, color_family,
    description,
    meta_title,
    meta_description,
    meta_keywords,
    og_title,
    og_description,
    search_terms,
    url_slug,
    is_indexable,
    sitemap_priority,
    status, created_at, updated_at
  ) VALUES (
    product_id,
    'Forest Green Mocha Double-Breasted Suit',
    'forest-green-mocha-double-breasted-suit',
    sku_prefix || '-002',
    'Double-Breasted Suits',
    base_price,
    'Forest Green Mocha',
    'Green',
    generate_seo_description('Forest Green Mocha Double-Breasted Suit', 'Double-Breasted Suits', 'Forest Green'),
    'Forest Green Mocha Double-Breasted Suit | Fall 2025 | KCT Menswear',
    generate_meta_description('Forest Green Mocha Double-Breasted Suit', 'Double-Breasted Suits', base_price),
    generate_seo_keywords('Forest Green Mocha Double-Breasted Suit', 'Double-Breasted Suits', 'Forest Green'),
    'Forest Green Mocha Double-Breasted Suit - Unique Fall 2025',
    'Stand out with our Forest Green Mocha Double-Breasted Suit. Perfect for fall weddings and special occasions.',
    'forest green mocha double breasted suit fall wedding unique',
    'forest-green-mocha-double-breasted-suit',
    true,
    0.9,
    'active',
    NOW(),
    NOW()
  );

  -- Continue with more products...
  -- Tuxedos category
  sku_prefix := 'F25-TUX';
  base_price := 499.99;
  
  -- Classic Black Tuxedo
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, handle, sku, category, base_price,
    color_name, color_family,
    description,
    meta_title,
    meta_description,
    meta_keywords,
    og_title,
    og_description,
    search_terms,
    url_slug,
    is_indexable,
    sitemap_priority,
    status, created_at, updated_at
  ) VALUES (
    product_id,
    'Classic Black Tuxedo with Satin Lapels',
    'classic-black-tuxedo-satin-lapels',
    sku_prefix || '-001',
    'Tuxedos',
    base_price,
    'Black',
    'Black',
    generate_seo_description('Classic Black Tuxedo with Satin Lapels', 'Tuxedos', 'Black'),
    'Classic Black Tuxedo | Formal Tuxedos | KCT Menswear',
    generate_meta_description('Classic Black Tuxedo with Satin Lapels', 'Tuxedos', base_price),
    generate_seo_keywords('Classic Black Tuxedo with Satin Lapels', 'Tuxedos', 'Black'),
    'Classic Black Tuxedo with Satin Lapels - Timeless Elegance',
    'Timeless black tuxedo with satin lapels. Perfect for black-tie events, weddings, and galas.',
    'black tuxedo satin lapels formal black tie wedding gala',
    'classic-black-tuxedo-satin-lapels',
    true,
    1.0,
    'active',
    NOW(),
    NOW()
  );

  -- Stretch Suits category
  sku_prefix := 'F25-STR';
  base_price := 399.99;
  
  -- Navy Blue Stretch Suit
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, name, handle, sku, category, base_price,
    color_name, color_family,
    description,
    meta_title,
    meta_description,
    meta_keywords,
    og_title,
    og_description,
    search_terms,
    url_slug,
    is_indexable,
    sitemap_priority,
    status, created_at, updated_at
  ) VALUES (
    product_id,
    'Navy Blue Performance Stretch Suit',
    'navy-blue-performance-stretch-suit',
    sku_prefix || '-001',
    'Stretch Suits',
    base_price,
    'Navy Blue',
    'Blue',
    generate_seo_description('Navy Blue Performance Stretch Suit', 'Stretch Suits', 'Navy Blue'),
    'Navy Blue Stretch Suit | Performance Suits | KCT Menswear',
    generate_meta_description('Navy Blue Performance Stretch Suit', 'Stretch Suits', base_price),
    generate_seo_keywords('Navy Blue Performance Stretch Suit', 'Stretch Suits', 'Navy Blue'),
    'Navy Blue Performance Stretch Suit - All-Day Comfort',
    'Experience all-day comfort with our Navy Blue Performance Stretch Suit. Perfect for long workdays and travel.',
    'navy blue stretch suit performance comfort travel business',
    'navy-blue-performance-stretch-suit',
    true,
    0.9,
    'active',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Fall 2025 Collection products imported successfully';
END $$;

-- Clean up functions
DROP FUNCTION IF EXISTS generate_seo_description(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS generate_meta_description(TEXT, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS generate_seo_keywords(TEXT, TEXT, TEXT);

-- Show summary
SELECT 
  category,
  COUNT(*) as product_count,
  MIN(base_price) as min_price,
  MAX(base_price) as max_price
FROM products_enhanced
WHERE sku LIKE 'F25-%'
GROUP BY category
ORDER BY category;