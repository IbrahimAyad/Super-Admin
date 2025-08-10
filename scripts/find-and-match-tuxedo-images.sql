-- First, let's see what tuxedo products we have
SELECT id, name, category, description
FROM products 
WHERE name ILIKE '%tux%' 
   OR name ILIKE '%tuxedo%'
   OR description ILIKE '%tuxedo%'
   OR category ILIKE '%formal%'
ORDER BY name;

-- Based on the image patterns, here are the tuxedo sets:
-- 2001: Black tuxedo with model
-- 2002: Another black variant
-- 2003: Black with different styling
-- 2004: Possibly navy or midnight blue
-- 2005: Another variant
-- 2006: Another variant
-- 2007: White/ivory tuxedo
-- 2008: Another variant
-- 2009: Gray/charcoal
-- 2010: Another variant

-- Create function to insert tuxedo images
CREATE OR REPLACE FUNCTION insert_tuxedo_images(
  p_product_id UUID,
  p_images TEXT[]
) RETURNS void AS $$
DECLARE
  i INTEGER;
BEGIN
  -- Delete existing images for this product
  DELETE FROM product_images WHERE product_id = p_product_id;
  
  -- Insert new images
  FOR i IN 1..array_length(p_images, 1) LOOP
    INSERT INTO product_images (
      product_id,
      image_url,
      image_type,
      position,
      created_at,
      updated_at
    ) VALUES (
      p_product_id,
      p_images[i],
      CASE 
        WHEN p_images[i] LIKE '%model%' THEN 'primary'
        WHEN i = 1 THEN 'primary' 
        ELSE 'gallery' 
      END,
      i - 1,
      NOW(),
      NOW()
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Base URL for tuxedos
-- https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/

-- ====================
-- TUXEDO IMAGE SETS BY NUMBER
-- ====================

-- Tuxedo Set 2001 (Black Classic with model)
DO $$
DECLARE
  product_id UUID;
BEGIN
  -- Try to find by common tuxedo naming patterns
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%black%tux%' OR name ILIKE '%classic%tux%')
    AND name NOT ILIKE '%white%'
    AND name NOT ILIKE '%gray%'
    AND name NOT ILIKE '%navy%'
  ORDER BY created_at LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_model_2001.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_2001.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2001 (Black Classic)';
  END IF;
END $$;

-- Tuxedo Set 2002
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%black%tux%' OR name ILIKE '%tuxedo%')
    AND name NOT ILIKE '%white%'
    AND name NOT ILIKE '%gray%'
  ORDER BY created_at OFFSET 1 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2002.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2002.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2002';
  END IF;
END $$;

-- Tuxedo Set 2003
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%black%tux%' OR name ILIKE '%tuxedo%')
  ORDER BY created_at OFFSET 2 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2003.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2003.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2003';
  END IF;
END $$;

-- Tuxedo Set 2004
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%navy%tux%' OR name ILIKE '%midnight%tux%' OR name ILIKE '%blue%tux%')
  ORDER BY created_at LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2004.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2004.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2004';
  ELSE
    -- If no navy found, add to next black tuxedo
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%tux%'
    ORDER BY created_at OFFSET 3 LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_tuxedo_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2004.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2004.webp'
      ]);
      RAISE NOTICE 'Updated Tuxedo 2004';
    END IF;
  END IF;
END $$;

-- Tuxedo Set 2005
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%tux%'
  ORDER BY created_at OFFSET 4 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2005.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2005.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2005';
  END IF;
END $$;

-- Tuxedo Set 2006
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%tux%'
  ORDER BY created_at OFFSET 5 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2006.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2006.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2006';
  END IF;
END $$;

-- Tuxedo Set 2007 (White/Ivory)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%white%tux%' OR name ILIKE '%ivory%tux%')
  ORDER BY created_at LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_white_tuxedo_model_2007.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_white_tuxedo_2007.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2007 (White/Ivory)';
  ELSE
    -- If no white found, add to next available tuxedo
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%tux%'
    ORDER BY created_at OFFSET 6 LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_tuxedo_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_white_tuxedo_model_2007.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_white_tuxedo_2007.webp'
      ]);
      RAISE NOTICE 'Updated Tuxedo 2007';
    END IF;
  END IF;
END $$;

-- Tuxedo Set 2008
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%tux%'
  ORDER BY created_at OFFSET 7 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2008.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2008.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2008';
  END IF;
END $$;

-- Tuxedo Set 2009 (Gray/Charcoal)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%gray%tux%' OR name ILIKE '%grey%tux%' OR name ILIKE '%charcoal%tux%')
  ORDER BY created_at LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gray_tuxedo_model_2009.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gray_tuxedo_2009.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2009 (Gray/Charcoal)';
  ELSE
    -- If no gray found, add to next available tuxedo
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%tux%'
    ORDER BY created_at OFFSET 8 LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_tuxedo_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gray_tuxedo_model_2009.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gray_tuxedo_2009.webp'
      ]);
      RAISE NOTICE 'Updated Tuxedo 2009';
    END IF;
  END IF;
END $$;

-- Tuxedo Set 2010
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%tux%'
  ORDER BY created_at OFFSET 9 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_model_2010.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_tuxedo_2010.webp'
    ]);
    RAISE NOTICE 'Updated Tuxedo 2010';
  END IF;
END $$;

-- ====================
-- SHOW RESULTS
-- ====================

-- Show what tuxedo products we have and their image counts
SELECT 
  p.name,
  p.category,
  COUNT(pi.id) as image_count,
  array_agg(
    CASE 
      WHEN pi.image_url LIKE '%model%' THEN 'Model photo'
      ELSE 'Product photo'
    END
    ORDER BY pi.position
  ) as image_types
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%tux%' 
   OR p.category ILIKE '%formal%'
GROUP BY p.id, p.name, p.category
ORDER BY p.name;

-- Clean up
DROP FUNCTION IF EXISTS insert_tuxedo_images(UUID, TEXT[]);