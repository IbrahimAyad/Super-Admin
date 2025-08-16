-- Import Accessories Collection with ALL Required Fields
-- This version includes slug, price_tier, and all other required fields

-- Create helper functions
CREATE OR REPLACE FUNCTION generate_accessory_seo_description(
  product_name TEXT,
  product_type TEXT,
  color TEXT
) RETURNS TEXT AS $$
DECLARE
  description TEXT;
BEGIN
  IF product_type = 'Suspender-Bowtie-Set' THEN
    description := 'Elevate your formal attire with our ' || product_name || ' from KCT Menswear. ' ||
                   'Premium elastic suspenders with adjustable Y-back design and matching pre-tied bowtie. ' ||
                   'Perfect for weddings, proms, formal events, and black-tie occasions. ' ||
                   'Features strong metal clips, adjustable straps (fits up to 50" length), and coordinated bowtie. ' ||
                   'Ships same-day for orders before 2 PM. Satisfaction guaranteed.';
  ELSE -- Vest-Tie-Set
    description := 'Complete your formal look with our ' || product_name || ' from KCT Menswear. ' ||
                   'Luxurious microfiber vest with matching necktie, crafted for comfort and style. ' ||
                   'Ideal for weddings, groomsmen, business events, and formal celebrations. ' ||
                   'Features 5-button adjustable back strap, two functional pockets, and perfectly matched tie. ' ||
                   'Available in sizes XS through 6XL. Ships same-day. Satisfaction guaranteed.';
  END IF;
  RETURN description;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_accessory_keywords(
  product_type TEXT,
  color TEXT
) RETURNS TEXT[] AS $$
BEGIN
  IF product_type = 'Suspender-Bowtie-Set' THEN
    RETURN ARRAY[
      LOWER(color) || ' suspenders',
      'mens suspenders',
      'bow tie set',
      'wedding suspenders',
      'groomsmen accessories',
      'prom accessories',
      'formal suspenders',
      'suspender bowtie combo'
    ];
  ELSE
    RETURN ARRAY[
      LOWER(color) || ' vest',
      'mens vest',
      'formal vest',
      'wedding vest',
      'waistcoat',
      'vest tie combo',
      'groomsmen vest',
      'formal waistcoat'
    ];
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Insert Suspender & Bowtie Sets (One Size)
DO $$
DECLARE
  product_id UUID;
  price NUMERIC := 49.99;
BEGIN
  
  -- Black Suspender & Bowtie Set
  product_id := gen_random_uuid();
  INSERT INTO products_enhanced (
    id, 
    name, 
    sku, 
    handle,
    slug,  -- REQUIRED
    style_code,
    season,
    collection,
    category, 
    subcategory,
    price_tier,  -- REQUIRED
    base_price,
    compare_at_price,
    color_name, 
    color_family,
    materials,
    fit_type,
    images,
    description,
    status,
    -- SEO fields
    meta_title,
    meta_description,
    meta_keywords,
    og_title,
    og_description,
    og_image,
    canonical_url,
    structured_data,
    tags,
    search_terms,
    url_slug,
    is_indexable,
    sitemap_priority,
    sitemap_change_freq,
    created_at, 
    updated_at
  ) VALUES (
    product_id,
    'Black Suspender & Bowtie Set',
    'ACC-SBS-BLK',
    'black-suspender-bowtie-set',
    'black-suspender-bowtie-set',  -- slug (same as handle)
    'SBS-BLK',  -- style_code
    'All Season',  -- season
    'Accessories Collection',  -- collection
    'Accessories',
    'Suspender Sets',  -- subcategory
    'TIER_1',  -- price_tier ($49.99 falls in Tier 1: $50-74)
    price,
    79.99,  -- compare_at_price (show savings)
    'Black',
    'Black',
    '{"primary": "Elastic", "secondary": "Metal Clips", "bowtie": "Polyester"}',  -- materials
    'One Size',  -- fit_type
    '{"hero": {"url": "https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/black-suspender-bowtie-set/main.webp"}, 
      "gallery": [
        {"url": "https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/black-suspender-bowtie-set/model.webp"},
        {"url": "https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/black-suspender-bowtie-set/suspender-set.jpg"}
      ]}',  -- images
    generate_accessory_seo_description('Black Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Black'),
    'active',
    -- SEO fields
    'Black Suspender & Bowtie Set | Formal Accessories | KCT Menswear',
    'Shop Black Suspender & Bowtie Set at $49.99. Perfect for weddings, proms & formal events. Same-day shipping available.',
    generate_accessory_keywords('Suspender-Bowtie-Set', 'Black'),
    'Black Suspender & Bowtie Set - Premium Formal Accessories',
    'Elevate your formal look with our Black Suspender & Bowtie Set. Perfect for weddings and black-tie events.',
    'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/black-suspender-bowtie-set/main.webp',
    'https://kctmenswear.com/products/black-suspender-bowtie-set',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Black Suspender & Bowtie Set", "price": "49.99", "priceCurrency": "USD"}',
    ARRAY['accessories', 'suspenders', 'bowtie', 'black', 'formal', 'wedding'],
    'black suspenders bowtie set formal accessories wedding prom',
    'black-suspender-bowtie-set',
    true,
    0.8,
    'weekly',
    NOW(),
    NOW()
  );

  -- Brown Suspender & Bowtie Set
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
    'Brown Suspender & Bowtie Set',
    'ACC-SBS-BRN',
    'brown-suspender-bowtie-set',
    'brown-suspender-bowtie-set',
    'SBS-BRN',
    'All Season',
    'Accessories Collection',
    'Accessories',
    'Suspender Sets',
    'TIER_1',
    price,
    79.99,
    'Brown',
    'Brown',
    '{"primary": "Elastic", "secondary": "Metal Clips", "bowtie": "Polyester"}',
    'One Size',
    '{"hero": {"url": "https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/brown-suspender-bowtie-set/model.webp"}, 
      "gallery": [
        {"url": "https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/brown-suspender-bowtie-set/product.jpg"}
      ]}',
    generate_accessory_seo_description('Brown Suspender & Bowtie Set', 'Suspender-Bowtie-Set', 'Brown'),
    'active',
    'Brown Suspender & Bowtie Set | Formal Accessories | KCT Menswear',
    'Shop Brown Suspender & Bowtie Set at $49.99. Classic brown accessories for formal events. Same-day shipping.',
    generate_accessory_keywords('Suspender-Bowtie-Set', 'Brown'),
    'Brown Suspender & Bowtie Set - Classic Formal Accessories',
    'Classic Brown Suspender & Bowtie Set perfect for rustic weddings and formal occasions.',
    'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/brown-suspender-bowtie-set/model.webp',
    'https://kctmenswear.com/products/brown-suspender-bowtie-set',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Brown Suspender & Bowtie Set", "price": "49.99", "priceCurrency": "USD"}',
    ARRAY['accessories', 'suspenders', 'bowtie', 'brown', 'formal', 'wedding', 'rustic'],
    'brown suspenders bowtie set formal accessories wedding rustic',
    'brown-suspender-bowtie-set',
    true,
    0.8,
    'weekly',
    NOW(),
    NOW()
  );

  -- Add more colors following the same pattern...
  
  RAISE NOTICE 'Suspender & Bowtie Sets imported successfully';
END $$;

-- Insert Vest & Tie Sets (XS-6XL sizes)
DO $$
DECLARE
  product_id UUID;
  price NUMERIC := 49.99;
BEGIN

  -- Black Sparkle Vest & Tie Set
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
    'Black Sparkle Vest & Tie Set',
    'ACC-VTS-BSP',
    'black-sparkle-vest-tie-set',
    'black-sparkle-vest-tie-set',
    'VTS-BSP',
    'All Season',
    'Accessories Collection',
    'Accessories',
    'Vest Sets',
    'TIER_1',
    price,
    89.99,
    'Black Sparkle',
    'Black',
    '{"vest": "Polyester Blend with Metallic Thread", "tie": "Matching Polyester", "backing": "Adjustable Elastic"}',
    'XS-6XL',
    '{"hero": {"url": "https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/black-sparkle/main.webp"}}',
    generate_accessory_seo_description('Black Sparkle Vest & Tie Set', 'Vest-Tie-Set', 'Black Sparkle'),
    'active',
    'Black Sparkle Vest & Tie Set | Formal Vests | KCT Menswear',
    'Shop Black Sparkle Vest & Tie Set at $49.99. Glamorous formal vest perfect for proms. Sizes XS-6XL.',
    generate_accessory_keywords('Vest-Tie-Set', 'Black Sparkle'),
    'Black Sparkle Vest & Tie Set - Glamorous Formal Wear',
    'Add glamour with our Black Sparkle Vest & Tie Set. Perfect for proms and special events.',
    'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/black-sparkle/main.webp',
    'https://kctmenswear.com/products/black-sparkle-vest-tie-set',
    '{"@context": "https://schema.org", "@type": "Product", "name": "Black Sparkle Vest & Tie Set", "price": "49.99", "priceCurrency": "USD"}',
    ARRAY['accessories', 'vest', 'tie', 'black', 'sparkle', 'prom', 'formal'],
    'black sparkle vest tie set formal prom glamorous',
    'black-sparkle-vest-tie-set',
    true,
    0.8,
    'weekly',
    NOW(),
    NOW()
  );

  -- Add more vest sets following the same pattern...

  RAISE NOTICE 'Vest & Tie Sets imported successfully';
END $$;

-- Clean up functions
DROP FUNCTION IF EXISTS generate_accessory_seo_description(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS generate_accessory_keywords(TEXT, TEXT);

-- Verify the import
SELECT 
  category,
  subcategory,
  COUNT(*) as product_count,
  MIN(base_price) as min_price,
  MAX(base_price) as max_price
FROM products_enhanced
WHERE sku LIKE 'ACC-%'
GROUP BY category, subcategory
ORDER BY category, subcategory;