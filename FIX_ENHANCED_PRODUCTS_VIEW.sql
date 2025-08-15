-- FIX FOR ENHANCED PRODUCTS VIEW ERROR
-- The error is in trying to access nested JSON incorrectly

-- Drop the problematic view if it exists
DROP VIEW IF EXISTS products_legacy CASCADE;

-- Create corrected view that mimics old products table structure
CREATE OR REPLACE VIEW products_legacy AS
SELECT 
  id,
  name,
  sku,
  handle,
  category,
  base_price,
  compare_at_price,
  description,
  -- Correct way to access nested JSON
  images->'hero'->>'url' as primary_image,
  status,
  stripe_product_id,
  stripe_active,
  created_at,
  updated_at
FROM products_enhanced;

-- Alternative approach if the above doesn't work
-- This handles cases where hero might be null
CREATE OR REPLACE VIEW products_legacy_safe AS
SELECT 
  id,
  name,
  sku,
  handle,
  category,
  base_price,
  compare_at_price,
  description,
  -- Safe extraction with null handling
  CASE 
    WHEN images IS NOT NULL AND images->'hero' IS NOT NULL 
    THEN images->'hero'->>'url'
    ELSE NULL
  END as primary_image,
  status,
  stripe_product_id,
  stripe_active,
  created_at,
  updated_at
FROM products_enhanced;

-- Test the extraction
SELECT 
  name,
  images->'hero'->>'url' as hero_url,
  images->'flat'->>'url' as flat_url,
  jsonb_array_length(COALESCE(images->'lifestyle', '[]'::jsonb)) as lifestyle_count,
  jsonb_array_length(COALESCE(images->'details', '[]'::jsonb)) as detail_count
FROM products_enhanced
WHERE sku = 'VB-001-NVY';

-- If you need to extract all image URLs into an array
SELECT 
  name,
  ARRAY[
    images->'hero'->>'url',
    images->'flat'->>'url'
  ] || 
  COALESCE(
    ARRAY(
      SELECT jsonb_array_elements(images->'lifestyle')->>'url'
    ),
    ARRAY[]::text[]
  ) || 
  COALESCE(
    ARRAY(
      SELECT jsonb_array_elements(images->'details')->>'url'
    ),
    ARRAY[]::text[]
  ) as all_image_urls
FROM products_enhanced
WHERE images IS NOT NULL;