-- SQL script to automatically match vest & tie images based on colors
-- Run this in your Supabase SQL Editor

-- Create temporary function to insert vest/tie images
CREATE OR REPLACE FUNCTION insert_vest_tie_images(
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
      CASE WHEN i = 1 THEN 'primary' ELSE 'gallery' END,
      i - 1,
      NOW(),
      NOW()
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Base URLs
-- Solid Vest & Tie: https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/
-- Velvet Blazers: https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/

-- ====================
-- SOLID VEST & TIE SETS
-- ====================

-- Turquoise Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%turquoise%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/Turquoise-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/Turquoise-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Turquoise Vest & Tie';
  END IF;
END $$;

-- Blush Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%blush%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Blush Vest & Tie';
  END IF;
END $$;

-- Burnt Orange Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%burnt%orange%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/burnt-orange-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/burnt-orange-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Burnt Orange Vest & Tie';
  END IF;
END $$;

-- Canary Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%canary%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/canary-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/canary-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Canary Vest & Tie';
  END IF;
END $$;

-- Carolina Blue Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%carolina%blue%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/carolina-blue-men-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/carolina-blue-men-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Carolina Blue Vest & Tie';
  END IF;
END $$;

-- Chocolate Brown Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%chocolate%brown%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/chocolate-brown-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/chocolate-brown-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Chocolate Brown Vest & Tie';
  END IF;
END $$;

-- Coral Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%coral%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/coral-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/coral-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Coral Vest & Tie';
  END IF;
END $$;

-- Dark Burgundy Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%dark%burgundy%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dark-burgundy-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dar-burgundy-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Dark Burgundy Vest & Tie';
  END IF;
END $$;

-- Dusty Rose Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%dusty%rose%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-rose-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-rose-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Dusty Rose Vest & Tie';
  END IF;
END $$;

-- Dusty Sage Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%dusty%sage%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-sage-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-sage-vest.png'
    ]);
    RAISE NOTICE 'Updated Dusty Sage Vest & Tie';
  END IF;
END $$;

-- Emerald Green Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%emerald%green%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/emerlad-green-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/emerlad-green-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Emerald Green Vest & Tie';
  END IF;
END $$;

-- Fuchsia Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%fuchsia%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/fuchsia-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/fuchsia-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Fuchsia Vest & Tie';
  END IF;
END $$;

-- Gold Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%gold%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/gold-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/gold-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Gold Vest & Tie';
  END IF;
END $$;

-- Grey Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%grey%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/grey-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/grey-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Grey Vest & Tie';
  END IF;
END $$;

-- Hunter Green Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%hunter%green%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.jpg'
    ]);
    RAISE NOTICE 'Updated Hunter Green Vest & Tie';
  END IF;
END $$;

-- Lilac Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%lilac%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/lilac-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/lilac-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Lilac Vest & Tie';
  END IF;
END $$;

-- Mint Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%mint%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/mint-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/mint-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Mint Vest & Tie';
  END IF;
END $$;

-- Peach Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%peach%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/peach-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/peach-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Peach Vest & Tie';
  END IF;
END $$;

-- Pink Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%pink%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Pink Vest & Tie';
  END IF;
END $$;

-- Plum Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%plum%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/plum-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/plum-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Plum Vest & Tie';
  END IF;
END $$;

-- Powder Blue Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%powder%blue%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/powder-blue-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/powder-blue-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Powder Blue Vest & Tie';
  END IF;
END $$;

-- Red Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%red%vest%' AND name ILIKE '%tie%' AND name NOT ILIKE '%dark%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Red Vest & Tie';
  END IF;
END $$;

-- Rose Gold Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%rose%gold%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.jpg'
    ]);
    RAISE NOTICE 'Updated Rose Gold Vest & Tie';
  END IF;
END $$;

-- Royal Blue Vest & Tie
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%royal%blue%vest%' AND name ILIKE '%tie%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.jpg'
    ]);
    RAISE NOTICE 'Updated Royal Blue Vest & Tie';
  END IF;
END $$;

-- ====================
-- VELVET BLAZERS - BURGUNDY (Multiple Products)
-- ====================

-- You mentioned there are multiple burgundy velvet blazer products with different images
-- Let's handle them by looking for specific SKUs or product IDs in the names

-- Burgundy Velvet Blazer #1 (1091, 1074)
DO $$
DECLARE
  product_id UUID;
BEGIN
  -- Try to match by specific patterns in the name or description
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%burgundy%velvet%blazer%' 
  ORDER BY created_at LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1091.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1074.webp'
    ]);
    RAISE NOTICE 'Updated Burgundy Velvet Blazer #1';
  END IF;
END $$;

-- Burgundy Velvet Blazer #2 (1065, 1070)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%burgundy%velvet%blazer%' 
  ORDER BY created_at OFFSET 1 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1070.webp'
    ]);
    RAISE NOTICE 'Updated Burgundy Velvet Blazer #2';
  END IF;
END $$;

-- Burgundy Velvet Blazer #3 (model + 1084)
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products 
  WHERE name ILIKE '%burgundy%velvet%blazer%' 
  ORDER BY created_at OFFSET 2 LIMIT 1;
  
  IF product_id IS NOT NULL THEN
    PERFORM insert_vest_tie_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_solid_velvet_model_1084.webp',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1084.webp'
    ]);
    RAISE NOTICE 'Updated Burgundy Velvet Blazer #3';
  END IF;
END $$;

-- ====================
-- SHOW RESULTS
-- ====================

-- Show what we updated
SELECT 
  p.name,
  p.category,
  COUNT(pi.id) as image_count,
  array_agg(
    CASE 
      WHEN pi.image_url LIKE '%model%' THEN 'Model Image'
      WHEN pi.image_url LIKE '%vest%' THEN 'Product Image'
      WHEN pi.image_url LIKE '%blazer%' THEN 'Blazer Image'
      ELSE 'Other'
    END 
    ORDER BY pi.position
  ) as image_types
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE (p.name ILIKE '%vest%' AND p.name ILIKE '%tie%')
   OR (p.name ILIKE '%velvet%' AND p.name ILIKE '%blazer%')
GROUP BY p.id, p.name, p.category
ORDER BY p.name;

-- Clean up
DROP FUNCTION IF EXISTS insert_vest_tie_images(UUID, TEXT[]);