-- TEST GALLERY IMPORT - Try with just a few products first
-- This tests the syntax and ensures everything works

BEGIN;

-- Test with one product from each category

-- 1. Test Men's Suits (apostrophe test)
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
WHERE category = 'Men''s Suits'
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
  AND id IN (
    SELECT id FROM products 
    WHERE category = 'Men''s Suits' 
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 1
  );

-- 2. Test Velvet Blazers
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_velvet_blazer_2025_0.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
  AND id IN (
    SELECT id FROM products 
    WHERE category = 'Luxury Velvet Blazers'
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 1
  );

-- 3. Test Vest & Tie Sets
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
  AND id IN (
    SELECT id FROM products 
    WHERE category = 'Vest & Tie Sets'
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 1
  );

-- 4. Test Gallery Creation (for the suit we just updated)
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 
       'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp',
       'primary',
       1,
       'Men''s Double Breasted Suit - Main View'
FROM products
WHERE primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id,
       'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_1.webp',
       'gallery',
       2,
       'Men''s Double Breasted Suit - Side View'
FROM products
WHERE primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

-- Check results
SELECT 
    'TEST RESULTS' as status,
    category,
    name,
    SUBSTRING(primary_image, 1, 50) as image_preview
FROM products
WHERE primary_image LIKE '%8ea0502158a94b8c%'
ORDER BY updated_at DESC
LIMIT 5;

-- Check gallery entries
SELECT 
    'GALLERY TEST' as status,
    COUNT(*) as gallery_images_created
FROM product_images
WHERE image_url LIKE '%8ea0502158a94b8c%';

COMMIT;