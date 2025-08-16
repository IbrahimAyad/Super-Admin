-- Import Accessories Collection into products_enhanced with Full SEO Optimization (FIXED)
-- Categories: Suspender & Bowtie Sets, Vest & Tie Sets
-- All accessories priced at $49.99

-- Create SEO functions for accessories
CREATE OR REPLACE FUNCTION generate_accessory_seo_description(
  product_name TEXT,
  product_type TEXT,
  color TEXT
) RETURNS TEXT AS $$
DECLARE
  description TEXT;
  occasion_text TEXT;
  material_text TEXT;
  features_text TEXT;
BEGIN
  -- Set descriptions based on product type
  IF product_type = 'Suspender-Bowtie-Set' THEN
    occasion_text := 'Perfect for weddings, proms, formal events, and black-tie occasions. ';
    material_text := 'Premium elastic suspenders with adjustable Y-back design and matching pre-tied bowtie. ';
    features_text := 'Features include strong metal clips, adjustable straps (fits up to 50" length), and coordinated bowtie with adjustable neck strap. ';
  ELSE -- Vest-Tie-Set
    occasion_text := 'Ideal for weddings, groomsmen, business events, and formal celebrations. ';
    material_text := 'Luxurious microfiber vest with matching necktie, crafted for comfort and style. ';
    features_text := 'Features include 5-button adjustable back strap, two functional pockets, and perfectly matched tie. ';
  END IF;

  -- Generate full description
  description := 'Elevate your formal attire with our ' || product_name || ' from KCT Menswear''s exclusive Accessories Collection. ' ||
                 occasion_text ||
                 material_text ||
                 features_text ||
                 'This sophisticated ' || color || ' set adds the perfect finishing touch to any formal ensemble. ' ||
                 'One-size-fits-most design ensures a comfortable fit for all body types. ' ||
                 'Complete your look with this essential formal accessory set. ' ||
                 'Ships same-day for orders placed before 2 PM. Satisfaction guaranteed.';
                 
  RETURN description;
END;
$$ LANGUAGE plpgsql;

-- Create meta description for accessories
CREATE OR REPLACE FUNCTION generate_accessory_meta_description(
  product_name TEXT,
  price NUMERIC
) RETURNS TEXT AS $$
BEGIN
  RETURN 'Shop ' || product_name || ' - Premium formal accessories at $' || price || 
         '. Perfect for weddings, proms & formal events. Same-day shipping. Shop KCT Menswear.';
END;
$$ LANGUAGE plpgsql;

-- Create SEO keywords for accessories (returns array)
CREATE OR REPLACE FUNCTION generate_accessory_keywords(
  product_name TEXT,
  product_type TEXT,
  color TEXT
) RETURNS TEXT[] AS $$
DECLARE
  keywords TEXT[];
BEGIN
  -- Base keywords
  keywords := ARRAY[
    LOWER(color) || ' ' || REPLACE(LOWER(product_type), '-', ' '),
    'mens formal accessories',
    LOWER(color) || ' accessories',
    product_name
  ];
  
  -- Type-specific keywords
  IF product_type = 'Suspender-Bowtie-Set' THEN
    keywords := keywords || ARRAY[
      'suspenders and bowtie',
      'mens suspenders',
      'bow tie set',
      'wedding suspenders',
      'groomsmen accessories',
      'prom accessories',
      'Y-back suspenders',
      'clip-on suspenders',
      'formal suspenders',
      'adjustable suspenders',
      'matching bowtie set'
    ];
  ELSE -- Vest-Tie-Set
    keywords := keywords || ARRAY[
      'vest and tie set',
      'mens vest',
      'formal vest',
      'wedding vest',
      'waistcoat',
      'groomsmen vest',
      'tuxedo vest',
      'dress vest',
      'matching tie set',
      'formal waistcoat',
      '5 button vest',
      'adjustable vest'
    ];
  END IF;
  
  -- Add more specific keywords
  keywords := keywords || ARRAY[
    LOWER(color) || ' ' || REPLACE(LOWER(product_type), '-', ' ') || ' for sale',
    'buy ' || LOWER(color) || ' accessories online',
    'affordable formal accessories',
    'mens formalwear accessories'
  ];
              
  RETURN keywords;
END;
$$ LANGUAGE plpgsql;

-- Insert Suspender & Bowtie Sets
DO $$
DECLARE
  product_id UUID;
  sku_prefix TEXT := 'ACC-SBS';
  price NUMERIC := 49.99;
BEGIN
  
  -- Black Suspender & Bowtie Set
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
    'Black Suspender & Bowtie Set',
    'black-suspender-bowtie-set',
    sku_prefix || '-BLK',
    'Accessories',
    price,
    'Black',
    'Black',
    generate_accessory_seo_description('Black Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Black'),
    'Black Suspender & Bowtie Set | Formal Accessories | KCT Menswear',
    generate_accessory_meta_description('Black Suspender & Bowtie Set', price),
    generate_accessory_keywords('Black Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Black'),
    'Black Suspender & Bowtie Set - Premium Formal Accessories',
    'Elevate your formal look with our Black Suspender & Bowtie Set. Perfect for weddings, proms, and black-tie events.',
    'black suspenders bowtie set formal accessories wedding prom',
    'black-suspender-bowtie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  -- Brown Suspender & Bowtie Set
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
    'Brown Suspender & Bowtie Set',
    'brown-suspender-bowtie-set',
    sku_prefix || '-BRN',
    'Accessories',
    price,
    'Brown',
    'Brown',
    generate_accessory_seo_description('Brown Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Brown'),
    'Brown Suspender & Bowtie Set | Formal Accessories | KCT Menswear',
    generate_accessory_meta_description('Brown Suspender & Bowtie Set', price),
    generate_accessory_keywords('Brown Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Brown'),
    'Brown Suspender & Bowtie Set - Premium Formal Accessories',
    'Classic Brown Suspender & Bowtie Set for formal occasions. Perfect match for brown or tan suits.',
    'brown suspenders bowtie set formal accessories wedding groomsmen',
    'brown-suspender-bowtie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  -- Burnt Orange Suspender & Bowtie Set
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
    'Burnt Orange Suspender & Bowtie Set',
    'burnt-orange-suspender-bowtie-set',
    sku_prefix || '-BOR',
    'Accessories',
    price,
    'Burnt Orange',
    'Orange',
    generate_accessory_seo_description('Burnt Orange Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Burnt Orange'),
    'Burnt Orange Suspender & Bowtie Set | Formal Accessories | KCT Menswear',
    generate_accessory_meta_description('Burnt Orange Suspender & Bowtie Set', price),
    generate_accessory_keywords('Burnt Orange Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Burnt Orange'),
    'Burnt Orange Suspender & Bowtie Set - Unique Formal Accessories',
    'Stand out with our Burnt Orange Suspender & Bowtie Set. Perfect for fall weddings and unique formal events.',
    'burnt orange suspenders bowtie set fall wedding accessories',
    'burnt-orange-suspender-bowtie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  -- Continue with remaining colors...
  -- Dusty Rose
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
    'Dusty Rose Suspender & Bowtie Set',
    'dusty-rose-suspender-bowtie-set',
    sku_prefix || '-DRS',
    'Accessories',
    price,
    'Dusty Rose',
    'Pink',
    generate_accessory_seo_description('Dusty Rose Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Dusty Rose'),
    'Dusty Rose Suspender & Bowtie Set | Wedding Accessories | KCT Menswear',
    generate_accessory_meta_description('Dusty Rose Suspender & Bowtie Set', price),
    generate_accessory_keywords('Dusty Rose Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Dusty Rose'),
    'Dusty Rose Suspender & Bowtie Set - Romantic Wedding Accessories',
    'Romantic Dusty Rose Suspender & Bowtie Set perfect for weddings and special occasions.',
    'dusty rose pink suspenders bowtie wedding accessories romantic',
    'dusty-rose-suspender-bowtie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Suspender & Bowtie Sets imported successfully';
END $$;

-- Insert Vest & Tie Sets
DO $$
DECLARE
  product_id UUID;
  sku_prefix TEXT := 'ACC-VTS';
  price NUMERIC := 49.99;
BEGIN

  -- Black Sparkle Vest & Tie Set
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
    'Black Sparkle Vest & Tie Set',
    'black-sparkle-vest-tie-set',
    sku_prefix || '-BSP',
    'Accessories',
    price,
    'Black Sparkle',
    'Black',
    generate_accessory_seo_description('Black Sparkle Vest & Tie Set', 'Vest-Tie-Set', 'Black Sparkle'),
    'Black Sparkle Vest & Tie Set | Formal Vests | KCT Menswear',
    generate_accessory_meta_description('Black Sparkle Vest & Tie Set', price),
    generate_accessory_keywords('Black Sparkle Vest & Tie Set', 'Vest-Tie-Set', 'Black Sparkle'),
    'Black Sparkle Vest & Tie Set - Glamorous Formal Wear',
    'Add glamour to your formal attire with our Black Sparkle Vest & Tie Set. Perfect for proms and special events.',
    'black sparkle vest tie set formal prom glamorous',
    'black-sparkle-vest-tie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  -- Gold Sparkle Vest & Tie Set
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
    'Gold Sparkle Vest & Tie Set',
    'gold-sparkle-vest-tie-set',
    sku_prefix || '-GSP',
    'Accessories',
    price,
    'Gold Sparkle',
    'Gold',
    generate_accessory_seo_description('Gold Sparkle Vest & Tie Set', 'Vest-Tie-Set', 'Gold Sparkle'),
    'Gold Sparkle Vest & Tie Set | Luxury Formal Vests | KCT Menswear',
    generate_accessory_meta_description('Gold Sparkle Vest & Tie Set', price),
    generate_accessory_keywords('Gold Sparkle Vest & Tie Set', 'Vest-Tie-Set', 'Gold Sparkle'),
    'Gold Sparkle Vest & Tie Set - Luxurious Formal Wear',
    'Make a statement with our Gold Sparkle Vest & Tie Set. Perfect for galas and upscale events.',
    'gold sparkle vest tie set luxury formal gala',
    'gold-sparkle-vest-tie-set',
    true,
    0.8,
    'active',
    NOW(),
    NOW()
  );

  -- Add more vest & tie sets as needed...

  RAISE NOTICE 'Vest & Tie Sets imported successfully';
END $$;

-- Clean up functions
DROP FUNCTION IF EXISTS generate_accessory_seo_description(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS generate_accessory_meta_description(TEXT, NUMERIC);
DROP FUNCTION IF EXISTS generate_accessory_keywords(TEXT, TEXT, TEXT);

-- Show summary
SELECT 
  category,
  COUNT(*) as product_count,
  MIN(base_price) as min_price,
  MAX(base_price) as max_price,
  STRING_AGG(DISTINCT color_family, ', ' ORDER BY color_family) as color_families
FROM products_enhanced
WHERE sku LIKE 'ACC-%'
GROUP BY category
ORDER BY category;