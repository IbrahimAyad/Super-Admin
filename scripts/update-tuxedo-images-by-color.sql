-- SQL script to update tuxedo images based on color matching
-- Run this in your Supabase SQL Editor

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
-- UPDATE TUXEDOS BY COLOR
-- ====================

-- Black Classic Tuxedos (Multiple - update ones missing model photos)
-- Update first black tuxedo without model photo
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.image_url LIKE '%model%'
  WHERE p.name ILIKE '%Classic Black Solid Tuxedo%'
    AND pi.id IS NULL
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_model_2001.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_2001.webp'
    ]);
    RAISE NOTICE 'Updated Black Classic Tuxedo #1 (2001)';
  END IF;
END $$;

-- Update second black tuxedo without model photo
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.image_url LIKE '%model%'
  WHERE p.name ILIKE '%Classic Black Solid Tuxedo%'
    AND pi.id IS NULL
  ORDER BY p.created_at
  OFFSET 1 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_model_2002.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_2002.webp'
    ]);
    RAISE NOTICE 'Updated Black Classic Tuxedo #2 (2002)';
  END IF;
END $$;

-- Black Wedding Tuxedos (update ones missing model photo)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.image_url LIKE '%model%'
  WHERE p.name ILIKE '%Wedding Black Solid Tuxedo%'
    AND pi.id IS NULL
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_model_2003.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_black_tuxedo_2003.webp'
    ]);
    RAISE NOTICE 'Updated Black Wedding Tuxedo (2003)';
  END IF;
END $$;

-- Navy Blue Tuxedo (already has images but can update if needed)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%Navy Blue Solid Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    -- Only update if you want to change images
    -- Uncomment to update:
    -- PERFORM insert_tuxedo_images(product_id, ARRAY[
    --   'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_navy_tuxedo_model_2004.webp',
    --   'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_navy_tuxedo_2004.webp'
    -- ]);
    RAISE NOTICE 'Navy Blue Tuxedo found (2004) - already has images';
  END IF;
END $$;

-- Purple Tuxedo (missing model photo)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  WHERE p.name ILIKE '%Purple Solid Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_purple_tuxedo_model_2005.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_purple_tuxedo_2005.webp'
    ]);
    RAISE NOTICE 'Updated Purple Tuxedo (2005)';
  END IF;
END $$;

-- Wine/Burgundy Tuxedo (already has images)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%Wine Solid Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    -- Already has images, but can update if needed
    RAISE NOTICE 'Wine Tuxedo found (2006) - already has images';
  END IF;
END $$;

-- Ivory/White Tuxedo (for Wedding Ivory)
DO $$
DECLARE
  product_id UUID;
BEGIN
  -- Update Ivory Paisley that's missing model photo
  SELECT p.id INTO product_id 
  FROM products p
  LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.image_url LIKE '%model%'
  WHERE p.name ILIKE '%Ivory Paisley Tuxedo%'
    AND pi.id IS NULL
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_ivory_tuxedo_model_2007.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_ivory_tuxedo_2007.webp'
    ]);
    RAISE NOTICE 'Updated Ivory Tuxedo (2007)';
  END IF;
END $$;

-- Pink Tuxedo (missing model photos)
DO $$
DECLARE
  product_id UUID;
BEGIN
  -- Update Pink Paisley
  SELECT p.id INTO product_id 
  FROM products p
  WHERE p.name ILIKE '%Pink Paisley Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_pink_tuxedo_model_2008.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_pink_tuxedo_2008.webp'
    ]);
    RAISE NOTICE 'Updated Pink Paisley Tuxedo (2008)';
  END IF;
END $$;

-- Update Pink Solid
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  WHERE p.name ILIKE '%Pink Solid Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_pink_tuxedo_model_2008.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_pink_tuxedo_2008.webp'
    ]);
    RAISE NOTICE 'Updated Pink Solid Tuxedo (2008)';
  END IF;
END $$;

-- Grey Tuxedo (already has images but for completeness)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%Grey Solid Tuxedo%'
  ORDER BY created_at
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    -- Already has images
    RAISE NOTICE 'Grey Tuxedo found (2009) - already has images';
  END IF;
END $$;

-- Gold Tuxedo (missing model photo)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT p.id INTO product_id 
  FROM products p
  WHERE p.name ILIKE '%Gold Solid Tuxedo%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_tuxedo_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gold_tuxedo_model_2010.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-tux/mens_gold_tuxedo_2010.webp'
    ]);
    RAISE NOTICE 'Updated Gold Tuxedo (2010)';
  END IF;
END $$;

-- ====================
-- SHOW RESULTS
-- ====================

-- Show updated tuxedo products and their image status
SELECT 
  p.name,
  p.category,
  COUNT(pi.id) as image_count,
  COUNT(CASE WHEN pi.image_url LIKE '%model%' THEN 1 END) as model_photos,
  COUNT(CASE WHEN pi.image_url NOT LIKE '%model%' THEN 1 END) as product_photos,
  CASE 
    WHEN COUNT(CASE WHEN pi.image_url LIKE '%model%' THEN 1 END) > 0 THEN '✅ Has Model'
    ELSE '❌ Missing Model'
  END as model_status
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%tuxedo%' 
   AND p.category = 'Men''s Suits'
GROUP BY p.id, p.name, p.category
ORDER BY p.name;

-- Summary
SELECT 
  'Tuxedos with model photos' as metric,
  COUNT(DISTINCT p.id) as count
FROM products p
JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%tuxedo%' 
  AND p.category = 'Men''s Suits'
  AND pi.image_url LIKE '%model%'

UNION ALL

SELECT 
  'Tuxedos missing model photos' as metric,
  COUNT(DISTINCT p.id) as count
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.image_url LIKE '%model%'
WHERE p.name ILIKE '%tuxedo%' 
  AND p.category = 'Men''s Suits'
  AND pi.id IS NULL;

-- Clean up
DROP FUNCTION IF EXISTS insert_tuxedo_images(UUID, TEXT[]);