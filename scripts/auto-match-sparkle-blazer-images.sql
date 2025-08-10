-- SQL script to automatically match sparkle/glitter blazer images to products
-- Run this in your Supabase SQL Editor

-- Create temporary function to insert blazer images
CREATE OR REPLACE FUNCTION insert_sparkle_blazer_images(
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

-- Base URL for sparkle blazers
-- https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/

-- ====================
-- BLACK SPARKLE BLAZERS
-- ====================

-- Black Glitter Finish Sparkle Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%black%sparkle%blazer%' OR name ILIKE '%black%glitter%blazer%')
    AND (name ILIKE '%glitter%' OR description ILIKE '%glitter%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_model_1030.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1031.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1032.webp'
    ]);
    RAISE NOTICE 'Updated Black Glitter Finish Sparkle Blazer';
  END IF;
END $$;

-- Black Sparkle Texture Blazer (if different product)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%black%sparkle%blazer%' OR name ILIKE '%black%texture%blazer%')
    AND (name ILIKE '%texture%' OR description ILIKE '%texture%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1036.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1047.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1053.webp'
    ]);
    RAISE NOTICE 'Updated Black Sparkle Texture Blazer';
  ELSE
    -- If no separate texture product, add to any black sparkle blazer
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%black%sparkle%blazer%' 
    ORDER BY created_at DESC LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_model_1030.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1036.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1047.webp'
      ]);
      RAISE NOTICE 'Updated Black Sparkle Blazer (Combined)';
    END IF;
  END IF;
END $$;

-- ====================
-- BLUE SPARKLE BLAZERS
-- ====================

-- Blue Sparkle Blazer with Shawl Lapel
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%blue%sparkle%blazer%' 
    AND name NOT ILIKE '%royal%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_2025_1034.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1054.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1055.webp'
    ]);
    RAISE NOTICE 'Updated Blue Sparkle Blazer';
  END IF;
END $$;

-- ====================
-- BURGUNDY SPARKLE BLAZERS
-- ====================

-- Burgundy Glitter Finish Sparkle Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%burgundy%sparkle%blazer%' OR name ILIKE '%burgundy%glitter%blazer%')
    AND (name ILIKE '%glitter%' OR description ILIKE '%glitter%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_model_1046.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1046.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1047.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1048.webp'
    ]);
    RAISE NOTICE 'Updated Burgundy Glitter Finish Sparkle Blazer';
  END IF;
END $$;

-- Burgundy Sparkle Texture Blazer (if different product)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%burgundy%sparkle%blazer%' OR name ILIKE '%burgundy%texture%blazer%')
    AND (name ILIKE '%texture%' OR description ILIKE '%texture%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1042.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1043.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1044.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1052.webp'
    ]);
    RAISE NOTICE 'Updated Burgundy Sparkle Texture Blazer';
  ELSE
    -- If no separate texture product, add all to any burgundy sparkle
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%burgundy%sparkle%blazer%'
    ORDER BY created_at DESC LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_model_1046.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1042.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1043.webp'
      ]);
      RAISE NOTICE 'Updated Burgundy Sparkle Blazer (Combined)';
    END IF;
  END IF;
END $$;

-- ====================
-- GOLD SPARKLE BLAZERS
-- ====================

-- Gold Baroque Pattern Sparkle Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%gold%sparkle%blazer%' OR name ILIKE '%gold%baroque%blazer%')
    AND (name ILIKE '%baroque%' OR description ILIKE '%baroque%' OR description ILIKE '%pattern%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1050.webp'
    ]);
    RAISE NOTICE 'Updated Gold Baroque Pattern Sparkle Blazer';
  END IF;
END $$;

-- Gold Glitter Finish Sparkle Blazer (if different product)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%gold%sparkle%blazer%' OR name ILIKE '%gold%glitter%blazer%')
    AND (name ILIKE '%glitter%' OR description ILIKE '%glitter%')
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1039.webp'
    ]);
    RAISE NOTICE 'Updated Gold Glitter Finish Sparkle Blazer';
  ELSE
    -- If no separate glitter product, add all to any gold sparkle blazer
    SELECT id INTO product_id FROM products 
    WHERE name ILIKE '%gold%sparkle%blazer%'
    ORDER BY created_at DESC LIMIT 1;
    
    IF product_id IS NOT NULL THEN
      PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1050.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp',
        'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1039.webp'
      ]);
      RAISE NOTICE 'Updated Gold Sparkle Blazer (Combined)';
    END IF;
  END IF;
END $$;

-- ====================
-- RED SPARKLE BLAZERS
-- ====================

-- Red Glitter Finish Sparkle Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE (name ILIKE '%red%sparkle%blazer%' OR name ILIKE '%red%glitter%blazer%')
    AND name NOT ILIKE '%medium%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1042.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1043.webp'
    ]);
    RAISE NOTICE 'Updated Red Glitter Finish Sparkle Blazer';
  END IF;
END $$;

-- ====================
-- ROYAL BLUE SPARKLE BLAZERS
-- ====================

-- Royal Blue Sparkle Texture Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%royal%blue%sparkle%blazer%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1046.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1047.webp'
    ]);
    RAISE NOTICE 'Updated Royal Blue Sparkle Texture Blazer';
  END IF;
END $$;

-- ====================
-- WHITE SPARKLE BLAZERS
-- ====================

-- White Sparkle Texture Blazer
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%white%sparkle%blazer%'
  LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_sparkle_blazer_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1043.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1044.webp'
    ]);
    RAISE NOTICE 'Updated White Sparkle Texture Blazer';
  END IF;
END $$;

-- ====================
-- SHOW RESULTS
-- ====================

-- Show what sparkle/glitter blazers we have and their image counts
SELECT 
  p.name,
  p.category,
  COUNT(pi.id) as image_count,
  array_agg(
    substring(pi.image_url from '[^/]+\.webp$') 
    ORDER BY pi.position
  ) as image_files
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%sparkle%blazer%' 
   OR p.name ILIKE '%glitter%blazer%'
   OR p.description ILIKE '%sparkle%'
   OR p.description ILIKE '%glitter%'
GROUP BY p.id, p.name, p.category
ORDER BY p.name;

-- Summary of all blazer types
SELECT 
  CASE 
    WHEN name ILIKE '%sparkle%' THEN 'Sparkle Blazers'
    WHEN name ILIKE '%glitter%' THEN 'Glitter Blazers'
    WHEN name ILIKE '%velvet%' THEN 'Velvet Blazers'
    WHEN name ILIKE '%prom%' THEN 'Prom Blazers'
    ELSE 'Other Blazers'
  END as blazer_type,
  COUNT(DISTINCT p.id) as product_count,
  COUNT(pi.id) as total_images
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%blazer%'
GROUP BY blazer_type
ORDER BY blazer_type;

-- Clean up
DROP FUNCTION IF EXISTS insert_sparkle_blazer_images(UUID, TEXT[]);