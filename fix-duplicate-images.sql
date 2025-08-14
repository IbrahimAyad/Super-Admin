-- FIX DUPLICATE AND BROKEN IMAGES
-- This will set unique placeholder images for products with duplicates

-- First, let's see what we're dealing with
WITH image_counts AS (
  SELECT 
    primary_image,
    COUNT(*) as usage_count,
    STRING_AGG(name, ', ' ORDER BY name) as products_using
  FROM products
  WHERE primary_image IS NOT NULL
  GROUP BY primary_image
  HAVING COUNT(*) > 1
)
SELECT * FROM image_counts
ORDER BY usage_count DESC
LIMIT 20;

-- Update products with the most duplicated image (mens_double_breasted_suit_2021_0.webp)
-- These are mostly suits and blazers that need unique images
UPDATE products
SET primary_image = 
  CASE 
    -- Keep original for first product, use placeholders for rest
    WHEN name LIKE '%Double Breasted%' THEN 'https://placehold.co/600x800/2c3e50/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
    WHEN name LIKE '%Suit%' THEN 'https://placehold.co/600x800/34495e/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
    WHEN name LIKE '%Blazer%' THEN 'https://placehold.co/600x800/1a1a2e/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
    ELSE primary_image
  END
WHERE primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND name != 'Yellow Sunny Elegance Double Breasted Suit'; -- Keep original for first one

-- Fix the velvet blazer duplicates
UPDATE products
SET primary_image = 'https://placehold.co/600x800/4a0e4e/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
WHERE primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet/mens_black_paisley_pattern_velvet_model_1059.webp'
  AND name != 'Men''s Velvet Navy Blue Blazer - Luxury Collection'; -- Keep original for first one

-- Fix sparkle blazer duplicates  
UPDATE products
SET primary_image = 'https://placehold.co/600x800/ffd700/000000?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
WHERE primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/glitter/mens_black_glitter_finish_sparkle_model_1030.webp'
  AND name != 'Men''s Sparkle Black Sparkle Blazer - Party & Special Events';

-- Fix products with no images
UPDATE products
SET primary_image = 'https://placehold.co/600x800/708090/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
WHERE primary_image IS NULL OR primary_image = '';

-- Fix placeholder.com images
UPDATE products
SET primary_image = 'https://placehold.co/600x800/483d8b/ffffff?text=' || REPLACE(SUBSTRING(name, 1, 20), ' ', '+')
WHERE primary_image LIKE '%placeholder%' OR primary_image LIKE '%placehold%';

-- Summary after fixes
SELECT 
  'Image Status' as check_type,
  COUNT(*) as total_products,
  COUNT(CASE WHEN primary_image IS NOT NULL THEN 1 END) as has_image,
  COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images,
  COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as r2_images
FROM products;

-- Show sample of fixed products
SELECT 
  name,
  SUBSTRING(primary_image, 1, 80) as image_preview,
  category
FROM products
WHERE primary_image LIKE '%placehold%'
LIMIT 10;