-- SQL script to update suspender & bowtie products with Cloudflare R2 images
-- Run this in your Supabase SQL Editor

-- First, let's see what products we have
SELECT id, name, category 
FROM products 
WHERE name ILIKE '%suspender%' 
   OR name ILIKE '%bowtie%'
   OR category ILIKE '%accessories%'
ORDER BY name;

-- Create a temporary function to insert images
CREATE OR REPLACE FUNCTION insert_product_images(
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

-- Base URL for images
-- https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/

-- Update Black Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%black%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/black-model.png'
    ]);
    RAISE NOTICE 'Updated Black Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Brown Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%brown%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-model-sus-bowtie.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Brown Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Burnt Orange Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%burnt%orange%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange.jpg'
    ]);
    RAISE NOTICE 'Updated Burnt Orange Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Dusty Rose Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%dusty%rose%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/dusty-rose-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/dusty-rose-sus-.jpg'
    ]);
    RAISE NOTICE 'Updated Dusty Rose Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Fuchsia Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%fuchsia%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-model-sus-bowtie.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Fuchsia Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Gold Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%gold%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Gold Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Hunter Green Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%hunter%green%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/hunter-green-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/hunter-green-sus-bow-tie.jpg'
    ]);
    RAISE NOTICE 'Updated Hunter Green Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Medium Red Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%medium%red%suspender%' OR name ILIKE '%red%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Medium Red Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Orange Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%orange%suspender%' AND name NOT ILIKE '%burnt%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/orange-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/orange-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Orange Suspender & Bowtie Set';
  END IF;
END $$;

-- Update Powder Blue Suspender & Bowtie Set
DO $$
DECLARE
  product_id UUID;
BEGIN
  SELECT id INTO product_id FROM products WHERE name ILIKE '%powder%blue%suspender%' OR name ILIKE '%light%blue%suspender%' LIMIT 1;
  IF product_id IS NOT NULL THEN
    PERFORM insert_product_images(product_id, ARRAY[
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model-2.png',
      'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-sus-bowtie.jpg'
    ]);
    RAISE NOTICE 'Updated Powder Blue Suspender & Bowtie Set';
  END IF;
END $$;

-- Show what we updated
SELECT 
  p.name,
  COUNT(pi.id) as image_count,
  array_agg(pi.image_url ORDER BY pi.position) as images
FROM products p
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.name ILIKE '%suspender%' 
   OR p.name ILIKE '%bowtie%'
GROUP BY p.id, p.name
ORDER BY p.name;

-- Clean up the temporary function
DROP FUNCTION IF EXISTS insert_product_images(UUID, TEXT[]);