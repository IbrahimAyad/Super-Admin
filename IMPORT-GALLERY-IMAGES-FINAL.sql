-- AUTO-GENERATED: Import Gallery Images from CSV
-- Generated: 2025-08-13T21:41:53.999Z

BEGIN;

-- Clear old gallery entries for products we're updating
DELETE FROM product_images 
WHERE product_id IN (
  SELECT id FROM products 
  WHERE status = 'active' 
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
);


-- Update Men'S Double Breasted Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_double_breasted_suit_2021%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Double Breasted Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp', 'primary', 1, 'Men''S Double Breasted Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_1.webp', 'gallery', 2, 'Men''S Double Breasted Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_2.webp', 'gallery', 3, 'Men''S Double Breasted Suit - Image 3'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2021_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Double Breasted Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2022_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_double_breasted_suit_2022%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Double Breasted Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2023_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_double_breasted_suit_2023%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Double Breasted Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_model_2024_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_double_breasted_suit_2024%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Double Breasted Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2024_0.webp', 'primary', 1, 'Men''S Double Breasted Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_model_2024_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_model_2024_0.webp', 'gallery', 2, 'Men''S Double Breasted Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_model_2024_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Dress Shirt Mock Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/mock_neck/mens_dress_shirt_mock_neck_3001_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_mock_neck_3001%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Mock Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/mock_neck/mens_dress_shirt_mock_neck_3003_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_mock_neck_3003%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Mock Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/mock_neck/mens_dress_shirt_mock_neck_3007_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_mock_neck_3007%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Mock Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/mock_neck/mens_dress_shirt_mock_neck_3011_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_mock_neck_3011%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Stretch Collar Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%collar%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_stretch_collar_3004%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Dress Shirt Stretch Collar Dress Shirt
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_3004_0.webp', 'primary', 1, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 1'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp', 'gallery', 2, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 2'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_1.webp', 'gallery', 3, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 3'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_2.webp', 'gallery', 4, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 4'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_3.webp', 'gallery', 5, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 5'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Dress Shirt Stretch Collar Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%collar%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_stretch_collar_3005%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Dress Shirt Stretch Collar Dress Shirt
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp', 'primary', 1, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 1'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_1.webp', 'gallery', 2, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 2'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_2.webp', 'gallery', 3, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 3'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_3.webp', 'gallery', 4, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 4'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_4.webp', 'gallery', 5, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 5'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Dress Shirt Stretch Collar Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%collar%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_stretch_collar_3008%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Dress Shirt Stretch Collar Dress Shirt
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp', 'primary', 1, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 1'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_1.webp', 'gallery', 2, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 2'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_2.webp', 'gallery', 3, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 3'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_3.webp', 'gallery', 4, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 4'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_4.webp', 'gallery', 5, 'Men''s Dress Shirt Stretch Collar Dress Shirt - Image 5'
FROM products
WHERE category = 'Men''s Dress Shirts'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Dress Shirt Turtle Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3002_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_turtle_neck_3002%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Turtle Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3006_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_turtle_neck_3006%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Turtle Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3009_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_turtle_neck_3009%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Turtle Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3010_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_turtle_neck_3010%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Dress Shirt Turtle Neck Dress Shirt
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3012_0.webp'
WHERE category = 'Men''s Dress Shirts'
  AND (
    LOWER(name) LIKE '%neck%'
    OR LOWER(sku) LIKE '%mens_dress_shirt_turtle_neck_3012%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 10-Z Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/10-z_20.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%10-z%'
    OR LOWER(sku) LIKE '%10-z%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 20250803  Trendy Teal Menswear Ensemble Remix 01k1q29pfgfcpv0m0dw198y3r5 Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/20250803_0017_Trendy Teal Menswear Ensemble_remix_01k1q29pfgfcpv0m0dw198y3r5.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%01k1q29pfgfcpv0m0dw198y3r5%'
    OR LOWER(sku) LIKE '%20250803_0017_Trendy Teal Menswear Ensemble_remix_01k1q29pfgfcpv0m0dw198y3r5%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Blush Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%blush%'
    OR LOWER(sku) LIKE '%blush%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Blush-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%blush-vest%'
    OR LOWER(sku) LIKE '%blush-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Burnt-Orange Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/burnt-orange-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%burnt-orange%'
    OR LOWER(sku) LIKE '%burnt-orange%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Burnt-Orange-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/burnt-orange-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%burnt-orange-vest%'
    OR LOWER(sku) LIKE '%burnt-orange-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Canary Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/canary-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%canary%'
    OR LOWER(sku) LIKE '%canary%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Canary-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/canary-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%canary-vest%'
    OR LOWER(sku) LIKE '%canary-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Carolina-Blue-Men Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/carolina-blue-men-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%carolina-blue-men%'
    OR LOWER(sku) LIKE '%carolina-blue-men%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Carolina-Blue-Men-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/carolina-blue-men-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%carolina-blue-men-vest%'
    OR LOWER(sku) LIKE '%carolina-blue-men-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Chocolate-Brown Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/chocolate-brown-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%chocolate-brown%'
    OR LOWER(sku) LIKE '%chocolate-brown%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Chocolate-Brown-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/chocolate-brown-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%chocolate-brown-vest%'
    OR LOWER(sku) LIKE '%chocolate-brown-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Coral Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/coral-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%coral%'
    OR LOWER(sku) LIKE '%coral%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Coral-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/coral-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%coral-vest%'
    OR LOWER(sku) LIKE '%coral-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dar-Burgundy-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dar-burgundy-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dar-burgundy-vest%'
    OR LOWER(sku) LIKE '%dar-burgundy-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dark-Burgundy Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dark-burgundy-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dark-burgundy%'
    OR LOWER(sku) LIKE '%dark-burgundy%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dusty-Rose Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-rose-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dusty-rose%'
    OR LOWER(sku) LIKE '%dusty-rose%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dusty-Rose-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-rose-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dusty-rose-vest%'
    OR LOWER(sku) LIKE '%dusty-rose-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dusty-Sage Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-sage-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dusty-sage%'
    OR LOWER(sku) LIKE '%dusty-sage%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dusty-Sage-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/dusty-sage-vest.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%dusty-sage-vest%'
    OR LOWER(sku) LIKE '%dusty-sage-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Emerlad-Green-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/emerlad-green-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%emerlad-green-vest%'
    OR LOWER(sku) LIKE '%emerlad-green-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Emerlad-Green=Model Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/emerlad-green=model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%emerlad-green=model%'
    OR LOWER(sku) LIKE '%emerlad-green=model%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Fuchsia Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/fuchsia-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%fuchsia%'
    OR LOWER(sku) LIKE '%fuchsia%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Fuchsia-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/fuchsia-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%fuchsia-vest%'
    OR LOWER(sku) LIKE '%fuchsia-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Gold Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/gold-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%gold%'
    OR LOWER(sku) LIKE '%gold%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Gold-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/gold-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%gold-vest%'
    OR LOWER(sku) LIKE '%gold-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Grey Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/grey-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%grey%'
    OR LOWER(sku) LIKE '%grey%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Grey-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/grey-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%grey-vest%'
    OR LOWER(sku) LIKE '%grey-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Hunter-Green Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%hunter-green%'
    OR LOWER(sku) LIKE '%hunter-green%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Hunter-Green Vest & Tie Set
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.jpg', 'primary', 1, 'Hunter-Green Vest & Tie Set - Image 1'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.png', 'gallery', 2, 'Hunter-Green Vest & Tie Set - Image 2'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/hunter-green-model.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Lilac Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/lilac-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%lilac%'
    OR LOWER(sku) LIKE '%lilac%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Lilac-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/lilac-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%lilac-vest%'
    OR LOWER(sku) LIKE '%lilac-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Mint Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/mint-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%mint%'
    OR LOWER(sku) LIKE '%mint%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Mint-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/mint-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%mint-vest%'
    OR LOWER(sku) LIKE '%mint-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Peach Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/peach-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%peach%'
    OR LOWER(sku) LIKE '%peach%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Peach-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/peach-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%peach-vest%'
    OR LOWER(sku) LIKE '%peach-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Pink-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%pink-vest%'
    OR LOWER(sku) LIKE '%pink-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Pink-Vest Vest & Tie Set
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest-model.png', 'primary', 1, 'Pink-Vest Vest & Tie Set - Image 1'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest.jpg', 'gallery', 2, 'Pink-Vest Vest & Tie Set - Image 2'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/pink-vest-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Plum Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/plum-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%plum%'
    OR LOWER(sku) LIKE '%plum%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Plum-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/plum-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%plum-vest%'
    OR LOWER(sku) LIKE '%plum-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Powder-Blue Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/powder-blue-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%powder-blue%'
    OR LOWER(sku) LIKE '%powder-blue%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Powder-Blue-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/powder-blue-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%powder-blue-vest%'
    OR LOWER(sku) LIKE '%powder-blue-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Red-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%red-vest%'
    OR LOWER(sku) LIKE '%red-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Red-Vest Vest & Tie Set
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest-model.png', 'primary', 1, 'Red-Vest Vest & Tie Set - Image 1'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest.jpg', 'gallery', 2, 'Red-Vest Vest & Tie Set - Image 2'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/red-vest-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Rose-Gold-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%rose-gold-vest%'
    OR LOWER(sku) LIKE '%rose-gold-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Rose-Gold-Vest Vest & Tie Set
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.jpg', 'primary', 1, 'Rose-Gold-Vest Vest & Tie Set - Image 1'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.png', 'gallery', 2, 'Rose-Gold-Vest Vest & Tie Set - Image 2'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/rose-gold-vest.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Royal-Blue Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%royal-blue%'
    OR LOWER(sku) LIKE '%royal-blue%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Royal-Blue Vest & Tie Set
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.jpg', 'primary', 1, 'Royal-Blue Vest & Tie Set - Image 1'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.png', 'gallery', 2, 'Royal-Blue Vest & Tie Set - Image 2'
FROM products
WHERE category = 'Vest & Tie Sets'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/royal-blue-model.jpg'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Turquoise Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/Turquoise-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%Turquoise%'
    OR LOWER(sku) LIKE '%Turquoise%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Turquoise-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/Turquoise-vest.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%Turquoise-vest%'
    OR LOWER(sku) LIKE '%Turquoise-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Wine Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/wine-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%wine%'
    OR LOWER(sku) LIKE '%wine%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Wine-Veset Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/wine-veset.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%wine-veset%'
    OR LOWER(sku) LIKE '%wine-veset%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 30-B-Men-S-Glitter-Vest-Bowtie-Hanky-Set Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/30-b-men-s-glitter-vest-bowtie-hanky-set.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%30-b-men-s-glitter-vest-bowtie-hanky-set%'
    OR LOWER(sku) LIKE '%30-b-men-s-glitter-vest-bowtie-hanky-set%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 30-I-Men-S-Glitter-Vest-Bowtie-Hanky-Set Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/30-i-men-s-glitter-vest-bowtie-hanky-set.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%30-i-men-s-glitter-vest-bowtie-hanky-set%'
    OR LOWER(sku) LIKE '%30-i-men-s-glitter-vest-bowtie-hanky-set%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 30-Q-Men-S-Glitter-Vest-Bowtie-Hanky-Set Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/30-q-men-s-glitter-vest-bowtie-hanky-set.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%30-q-men-s-glitter-vest-bowtie-hanky-set%'
    OR LOWER(sku) LIKE '%30-q-men-s-glitter-vest-bowtie-hanky-set%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 30-Zz-Men-S-Glitter-Vest-Bowtie-Hanky-Set Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/30-zz-men-s-glitter-vest-bowtie-hanky-set.jpg'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%30-zz-men-s-glitter-vest-bowtie-hanky-set%'
    OR LOWER(sku) LIKE '%30-zz-men-s-glitter-vest-bowtie-hanky-set%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Black-Sparkle-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/black-sparkle-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%black-sparkle-vest%'
    OR LOWER(sku) LIKE '%black-sparkle-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Gold-Sparkle-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/gold-sparkle-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%gold-sparkle-vest%'
    OR LOWER(sku) LIKE '%gold-sparkle-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Royal-Sparkle-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/royal-sparkle-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%royal-sparkle-vest%'
    OR LOWER(sku) LIKE '%royal-sparkle-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Silver-Sparkle-Vest Vest & Tie Set
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-sparkle-vest/silver-sparkle-vest-model.png'
WHERE category = 'Vest & Tie Sets'
  AND (
    LOWER(name) LIKE '%silver-sparkle-vest%'
    OR LOWER(sku) LIKE '%silver-sparkle-vest%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update 20250803  Stylish Formal Accessories Remix 01k1qdvxc3emd96chtgx0jr6jm
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/20250803_0339_Stylish Formal Accessories_remix_01k1qdvxc3emd96chtgx0jr6jm.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%01k1qdvxc3emd96chtgx0jr6jm%'
    OR LOWER(sku) LIKE '%20250803_0339_Stylish Formal Accessories_remix_01k1qdvxc3emd96chtgx0jr6jm%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Black
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/black-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%black%'
    OR LOWER(sku) LIKE '%black%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Brown-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-model-sus-bowtie.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%brown-sus-bowtie%'
    OR LOWER(sku) LIKE '%brown-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Brown-Sus-Bowtie
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-model-sus-bowtie.png', 'primary', 1, 'Brown-Sus-Bowtie - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-model-sus-bowtie.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-sus-bowtie.jpg', 'gallery', 2, 'Brown-Sus-Bowtie - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/brown-model-sus-bowtie.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Burnt-Orange
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%burnt-orange%'
    OR LOWER(sku) LIKE '%burnt-orange%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Burnt-Orange
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange-model.png', 'primary', 1, 'Burnt-Orange - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange.jpg', 'gallery', 2, 'Burnt-Orange - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/burnt-orange-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Dusty-Rose
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/dusty-rose-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%dusty-rose%'
    OR LOWER(sku) LIKE '%dusty-rose%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Dusty-Rose-Sus-
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/dusty-rose-sus-.jpg'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%dusty-rose-sus-%'
    OR LOWER(sku) LIKE '%dusty-rose-sus-%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Fuchsia-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-model-sus-bowtie.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%fuchsia-sus-bowtie%'
    OR LOWER(sku) LIKE '%fuchsia-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Fuchsia-Sus-Bowtie
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-model-sus-bowtie.png', 'primary', 1, 'Fuchsia-Sus-Bowtie - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-model-sus-bowtie.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-sus-bowtie.jpg', 'gallery', 2, 'Fuchsia-Sus-Bowtie - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/fuchsia-model-sus-bowtie.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Gold-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%gold-sus-bowtie%'
    OR LOWER(sku) LIKE '%gold-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Gold-Sus-Bowtie
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie-model.png', 'primary', 1, 'Gold-Sus-Bowtie - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie.jpg', 'gallery', 2, 'Gold-Sus-Bowtie - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/gold-sus-bowtie-model.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Hunter-Green
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/hunter-green-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%hunter-green%'
    OR LOWER(sku) LIKE '%hunter-green%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Hunter-Green-Sus-Bow-Tie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/hunter-green-sus-bow-tie.jpg'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%hunter-green-sus-bow-tie%'
    OR LOWER(sku) LIKE '%hunter-green-sus-bow-tie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Medium-Red-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%medium-red-sus-bowtie%'
    OR LOWER(sku) LIKE '%medium-red-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Medium-Red-Sus-Bowtie
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png', 'primary', 1, 'Medium-Red-Sus-Bowtie - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model.png', 'gallery', 2, 'Medium-Red-Sus-Bowtie - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie.jpg', 'gallery', 3, 'Medium-Red-Sus-Bowtie - Image 3'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/medium-red-sus-bowtie-model-2.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Orange
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/orange-model.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%orange%'
    OR LOWER(sku) LIKE '%orange%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Orange-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/orange-sus-bowtie.jpg'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%orange-sus-bowtie%'
    OR LOWER(sku) LIKE '%orange-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Powder-Blue
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model-2.png'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%powder-blue%'
    OR LOWER(sku) LIKE '%powder-blue%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Powder-Blue
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model-2.png', 'primary', 1, 'Powder-Blue - Image 1'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model-2.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model.png', 'gallery', 2, 'Powder-Blue - Image 2'
FROM products
WHERE category = 'Accessories'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-model-2.png'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Powder-Blue-Sus-Bowtie
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/powder-blue-sus-bowtie.jpg'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%powder-blue-sus-bowtie%'
    OR LOWER(sku) LIKE '%powder-blue-sus-bowtie%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Sbh10-Suspender-Sets-Convertible-Clipbutton
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/sbh10-suspender-sets-convertible-clipbutton-35.jpg'
WHERE category = 'Accessories'
  AND (
    LOWER(name) LIKE '%sbh10-suspender-sets-convertible-clipbutton%'
    OR LOWER(sku) LIKE '%sbh10-suspender-sets-convertible-clipbutton%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_model_1009.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_floral_pattern_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_floral_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Floral Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp', 'primary', 1, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1001.webp', 'gallery', 2, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1009.webp', 'gallery', 3, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1010.webp', 'gallery', 4, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 4'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1011.webp', 'gallery', 5, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 5'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1012.webp', 'gallery', 6, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 6'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1013.webp', 'gallery', 7, 'Men''s Black Floral Pattern Prom Blazer Blazer - Image 7'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_2025_1000.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Floral Pattern Prom Blazer Lifestyle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_floral_pattern_prom_blazer_model_lifestyle_1009.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%lifestyle%'
    OR LOWER(sku) LIKE '%mens_black_floral_pattern_prom_blazer_lifestyle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Geometric Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_geometric_pattern_prom_blazer_2025_1010.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_geometric_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Geometric Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_geometric_pattern_prom_blazer_2025_1010.webp', 'primary', 1, 'Men''s Black Geometric Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_geometric_pattern_prom_blazer_2025_1010.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_geometric_pattern_prom_blazer_2025_1016.webp', 'gallery', 2, 'Men''s Black Geometric Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_geometric_pattern_prom_blazer_2025_1010.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Glitter Finish Prom Blazer Shawl Lapel Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_glitter_finish_prom_blazer_shawl_lapel_2025_1004.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%lapel%'
    OR LOWER(sku) LIKE '%mens_black_glitter_finish_prom_blazer_shawl_lapel_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Glitter Finish Prom Blazer Shawl Lapel Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_glitter_finish_prom_blazer_shawl_lapel_2025_1004.webp', 'primary', 1, 'Men''s Black Glitter Finish Prom Blazer Shawl Lapel Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_glitter_finish_prom_blazer_shawl_lapel_2025_1004.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_glitter_finish_prom_blazer_shawl_lapel_2025_1005.webp', 'gallery', 2, 'Men''s Black Glitter Finish Prom Blazer Shawl Lapel Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_glitter_finish_prom_blazer_shawl_lapel_2025_1004.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_prom_blazer_with_bowtie_2025_1015.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_black_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Solid Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_black_solid_prom_blazer_model_1015.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_solid_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_model_1011.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_floral_pattern_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1011.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_floral_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Burgundy Floral Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1011.webp', 'primary', 1, 'Men''s Burgundy Floral Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1011.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1012.webp', 'gallery', 2, 'Men''s Burgundy Floral Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1011.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1013.webp', 'gallery', 3, 'Men''s Burgundy Floral Pattern Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_floral_pattern_prom_blazer_2025_1011.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Burgundy Paisley Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_paisley_pattern_prom_blazer_model_1007.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_paisley_pattern_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Paisley Pattern Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_burgundy_paisley_pattern_prom_blazer_with_bowtie_2025_1007.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_burgundy_paisley_pattern_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Gold Paisley Pattern Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_paisley_pattern_prom_blazer_with_bowtie_2025_1019.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_gold_paisley_pattern_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Gold Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_gold_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Gold Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp', 'primary', 1, 'Men''s Gold Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1007.webp', 'gallery', 2, 'Men''s Gold Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1008.webp', 'gallery', 3, 'Men''s Gold Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1009.webp', 'gallery', 4, 'Men''s Gold Prom Blazer Blazer - Image 4'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_gold_prom_blazer_2025_1006.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Navy Printed Design Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_model_1013.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_navy_printed_design_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Navy Printed Design Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_navy_printed_design_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Navy Printed Design Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp', 'primary', 1, 'Men''s Navy Printed Design Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1014.webp', 'gallery', 2, 'Men''s Navy Printed Design Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1015.webp', 'gallery', 3, 'Men''s Navy Printed Design Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1016.webp', 'gallery', 4, 'Men''s Navy Printed Design Prom Blazer Blazer - Image 4'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_navy_printed_design_prom_blazer_2025_1013.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Pink Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1008.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_pink_floral_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Pink Floral Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1008.webp', 'primary', 1, 'Men''s Pink Floral Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1008.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1009.webp', 'gallery', 2, 'Men''s Pink Floral Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1008.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1010.webp', 'gallery', 3, 'Men''s Pink Floral Pattern Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_pink_floral_pattern_prom_blazer_2025_1008.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_model_1018.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_floral_pattern_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_2025_1001.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_floral_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Red Floral Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_2025_1001.webp', 'primary', 1, 'Men''s Red Floral Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_2025_1001.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_2025_1002.webp', 'gallery', 2, 'Men''s Red Floral Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_2025_1001.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Floral Pattern Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_floral_pattern_prom_blazer_with_bowtie_2025_1018.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_red_floral_pattern_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_prom_blazer_with_bowtie_2025_1014.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_red_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Solid Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_red_solid_prom_blazer_model_1014.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_solid_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Royal Blue Solid Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal_blue_solid_prom_blazer_model_1017.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal_blue_solid_prom_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Royal-Blue Embellished Design Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_embellished_design_prom_blazer_2025_1003.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal-blue_embellished_design_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Royal-Blue Embellished Design Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_embellished_design_prom_blazer_2025_1003.webp', 'primary', 1, 'Men''s Royal-Blue Embellished Design Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_embellished_design_prom_blazer_2025_1003.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_embellished_design_prom_blazer_2025_1020.webp', 'gallery', 2, 'Men''s Royal-Blue Embellished Design Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_embellished_design_prom_blazer_2025_1003.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Royal-Blue Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_royal-blue_prom_blazer_with_bowtie_2025_1017.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_royal-blue_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Teal Floral Pattern Prom Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1005.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_teal_floral_pattern_prom_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Teal Floral Pattern Prom Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1005.webp', 'primary', 1, 'Men''s Teal Floral Pattern Prom Blazer Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1005.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1006.webp', 'gallery', 2, 'Men''s Teal Floral Pattern Prom Blazer Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1005.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1007.webp', 'gallery', 3, 'Men''s Teal Floral Pattern Prom Blazer Blazer - Image 3'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_teal_floral_pattern_prom_blazer_2025_1005.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S White Prom Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_prom_blazer_with_bowtie_2025_1012.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_white_prom_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S White Prom Blazer With Bowtie Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_prom_blazer_with_bowtie_2025_1012.webp', 'primary', 1, 'Men''s White Prom Blazer With Bowtie Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_prom_blazer_with_bowtie_2025_1012.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_prom_blazer_with_bowtie_2025_1021.webp', 'gallery', 2, 'Men''s White Prom Blazer With Bowtie Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_prom_blazer_with_bowtie_2025_1012.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S White Rhinestone Embellished Prom Blazer Shawl Lapel Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025_1002.webp'
WHERE category = 'Prom & Formal Blazers'
  AND (
    LOWER(name) LIKE '%lapel%'
    OR LOWER(sku) LIKE '%mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S White Rhinestone Embellished Prom Blazer Shawl Lapel Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025_1002.webp', 'primary', 1, 'Men''s White Rhinestone Embellished Prom Blazer Shawl Lapel Blazer - Image 1'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025_1002.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025_1003.webp', 'gallery', 2, 'Men''s White Rhinestone Embellished Prom Blazer Shawl Lapel Blazer - Image 2'
FROM products
WHERE category = 'Prom & Formal Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_white_rhinestone_embellished_prom_blazer_shawl_lapel_2025_1002.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Glitter Finish Sparkle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_model_1030.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%sparkle%'
    OR LOWER(sku) LIKE '%mens_black_glitter_finish_sparkle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp', 'primary', 1, 'Men''s Black Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1031.webp', 'gallery', 2, 'Men''s Black Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1032.webp', 'gallery', 3, 'Men''s Black Glitter Finish Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_glitter_finish_sparkle_blazer_2025_1030.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp', 'primary', 1, 'Men''s Black Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1036.webp', 'gallery', 2, 'Men''s Black Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1047.webp', 'gallery', 3, 'Men''s Black Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1053.webp', 'gallery', 4, 'Men''s Black Sparkle Texture Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_black_sparkle_texture_sparkle_blazer_2025_1032.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Blue Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_2025_1034.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_blue_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Blue Sparkle Blazer Shawl Lapel Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1054.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%lapel%'
    OR LOWER(sku) LIKE '%mens_blue_sparkle_blazer_shawl_lapel_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Blue Sparkle Blazer Shawl Lapel Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1054.webp', 'primary', 1, 'Men''s Blue Sparkle Blazer Shawl Lapel Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1054.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1055.webp', 'gallery', 2, 'Men''s Blue Sparkle Blazer Shawl Lapel Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_blue_sparkle_blazer_shawl_lapel_2025_1054.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Burgundy Glitter Finish Sparkle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_model_1046.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%sparkle%'
    OR LOWER(sku) LIKE '%mens_burgundy_glitter_finish_sparkle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Burgundy Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp', 'primary', 1, 'Men''s Burgundy Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1046.webp', 'gallery', 2, 'Men''s Burgundy Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1047.webp', 'gallery', 3, 'Men''s Burgundy Glitter Finish Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1048.webp', 'gallery', 4, 'Men''s Burgundy Glitter Finish Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_glitter_finish_sparkle_blazer_2025_1040.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Burgundy Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Burgundy Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp', 'primary', 1, 'Men''s Burgundy Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1042.webp', 'gallery', 2, 'Men''s Burgundy Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1043.webp', 'gallery', 3, 'Men''s Burgundy Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1044.webp', 'gallery', 4, 'Men''s Burgundy Sparkle Texture Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1052.webp', 'gallery', 5, 'Men''s Burgundy Sparkle Texture Sparkle Blazer Blazer - Image 5'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_burgundy_sparkle_texture_sparkle_blazer_2025_1041.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Gold Baroque Pattern Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_gold_baroque_pattern_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Gold Baroque Pattern Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp', 'primary', 1, 'Men''s Gold Baroque Pattern Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1050.webp', 'gallery', 2, 'Men''s Gold Baroque Pattern Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_baroque_pattern_sparkle_blazer_2025_1048.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Gold Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_gold_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Gold Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp', 'primary', 1, 'Men''s Gold Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1039.webp', 'gallery', 2, 'Men''s Gold Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1040.webp', 'gallery', 3, 'Men''s Gold Glitter Finish Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1049.webp', 'gallery', 4, 'Men''s Gold Glitter Finish Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_glitter_finish_sparkle_blazer_2025_1037.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Gold Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_gold_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Gold Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp', 'primary', 1, 'Men''s Gold Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1032.webp', 'gallery', 2, 'Men''s Gold Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1033.webp', 'gallery', 3, 'Men''s Gold Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1034.webp', 'gallery', 4, 'Men''s Gold Sparkle Texture Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1035.webp', 'gallery', 5, 'Men''s Gold Sparkle Texture Sparkle Blazer Blazer - Image 5'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_gold_sparkle_texture_sparkle_blazer_2025_1031.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Green Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_green_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Green Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp', 'primary', 1, 'Men''s Green Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1034.webp', 'gallery', 2, 'Men''s Green Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1035.webp', 'gallery', 3, 'Men''s Green Glitter Finish Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1036.webp', 'gallery', 4, 'Men''s Green Glitter Finish Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1037.webp', 'gallery', 5, 'Men''s Green Glitter Finish Sparkle Blazer Blazer - Image 5'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_glitter_finish_sparkle_blazer_2025_1033.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Green Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_green_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Green Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp', 'primary', 1, 'Men''s Green Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1030.webp', 'gallery', 2, 'Men''s Green Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1031.webp', 'gallery', 3, 'Men''s Green Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1032.webp', 'gallery', 4, 'Men''s Green Sparkle Texture Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1033.webp', 'gallery', 5, 'Men''s Green Sparkle Texture Sparkle Blazer Blazer - Image 5'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_green_sparkle_texture_sparkle_blazer_2025_1029.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Navy Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_navy_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Navy Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp', 'primary', 1, 'Men''s Navy Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1039.webp', 'gallery', 2, 'Men''s Navy Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1040.webp', 'gallery', 3, 'Men''s Navy Glitter Finish Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1041.webp', 'gallery', 4, 'Men''s Navy Glitter Finish Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_glitter_finish_sparkle_blazer_2025_1038.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Navy Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_navy_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Navy Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp', 'primary', 1, 'Men''s Navy Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1036.webp', 'gallery', 2, 'Men''s Navy Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1044.webp', 'gallery', 3, 'Men''s Navy Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1051.webp', 'gallery', 4, 'Men''s Navy Sparkle Texture Sparkle Blazer Blazer - Image 4'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_navy_sparkle_texture_sparkle_blazer_2025_1035.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Glitter Finish Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1042.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_glitter_finish_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Red Glitter Finish Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1042.webp', 'primary', 1, 'Men''s Red Glitter Finish Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1042.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1043.webp', 'gallery', 2, 'Men''s Red Glitter Finish Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_red_glitter_finish_sparkle_blazer_2025_1042.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Royal-Blue Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal-blue_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Royal-Blue Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp', 'primary', 1, 'Men''s Royal-Blue Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1046.webp', 'gallery', 2, 'Men''s Royal-Blue Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1047.webp', 'gallery', 3, 'Men''s Royal-Blue Sparkle Texture Sparkle Blazer Blazer - Image 3'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_royal-blue_sparkle_texture_sparkle_blazer_2025_1045.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S White Sparkle Texture Sparkle Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1043.webp'
WHERE category = 'Sparkle & Sequin Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_white_sparkle_texture_sparkle_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S White Sparkle Texture Sparkle Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1043.webp', 'primary', 1, 'Men''s White Sparkle Texture Sparkle Blazer Blazer - Image 1'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1043.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1044.webp', 'gallery', 2, 'Men''s White Sparkle Texture Sparkle Blazer Blazer - Image 2'
FROM products
WHERE category = 'Sparkle & Sequin Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_white_sparkle_texture_sparkle_blazer_2025_1043.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2025_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2025_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2025_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2025_1.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2025_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2026_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2026%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2026_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2026_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2026_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2026_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2026_1.webp', 'gallery', 3, 'Men''s Stretch Suits Suit - Image 3'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2026_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2027_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2027%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2027_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2027_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2027_1.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2027_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2028_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2028%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2028_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2028_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2028_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2028_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2028_1.webp', 'gallery', 3, 'Men''s Stretch Suits Suit - Image 3'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2028_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2029_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2029%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2029_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2029_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2029_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2029_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2030_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2030%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2030_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2030_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2030_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2030_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2031_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2031%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2031_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2031_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2031_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2031_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2031_1.webp', 'gallery', 3, 'Men''s Stretch Suits Suit - Image 3'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2031_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2032_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2032%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2032_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2032_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2032_1.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2032_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2033_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2033%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Stretch Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_2033_0.webp', 'primary', 1, 'Men''s Stretch Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2033_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2033_0.webp', 'gallery', 2, 'Men''s Stretch Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2033_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Stretch Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suits_suit_model_2034_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_stretch_suits_suit_2034%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_suits_suit_2035%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_2035_0.webp', 'primary', 1, 'Men''s Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_0.webp', 'gallery', 2, 'Men''s Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_1.webp', 'gallery', 3, 'Men''s Suits Suit - Image 3'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2035_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2036_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_suits_suit_2036%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_2036_0.webp', 'primary', 1, 'Men''s Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2036_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2036_0.webp', 'gallery', 2, 'Men''s Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2036_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Suits Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2037_0.webp'
WHERE category = 'Men''s Suits'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_suits_suit_2037%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Suits Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_2037_0.webp', 'primary', 1, 'Men''s Suits Suit - Image 1'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2037_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2037_0.webp', 'gallery', 2, 'Men''s Suits Suit - Image 2'
FROM products
WHERE category = 'Men''s Suits'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/suits/mens_suits_suit_model_2037_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Blue Casual Summer Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
WHERE category = 'Casual Summer Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_blue_casual_summer_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Blue Casual Summer Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp', 'primary', 1, 'Men''s Blue Casual Summer Blazer Blazer - Image 1'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1026.webp', 'gallery', 2, 'Men''s Blue Casual Summer Blazer Blazer - Image 2'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1027.webp', 'gallery', 3, 'Men''s Blue Casual Summer Blazer Blazer - Image 3'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1028.webp', 'gallery', 4, 'Men''s Blue Casual Summer Blazer Blazer - Image 4'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1029.webp', 'gallery', 5, 'Men''s Blue Casual Summer Blazer Blazer - Image 5'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_blue_casual_summer_blazer_2025_1025.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Brown Casual Summer Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_brown_casual_summer_blazer_2025_1023.webp'
WHERE category = 'Casual Summer Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_brown_casual_summer_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Brown Casual Summer Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_brown_casual_summer_blazer_2025_1023.webp', 'primary', 1, 'Men''s Brown Casual Summer Blazer Blazer - Image 1'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_brown_casual_summer_blazer_2025_1023.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_brown_casual_summer_blazer_2025_1026.webp', 'gallery', 2, 'Men''s Brown Casual Summer Blazer Blazer - Image 2'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_brown_casual_summer_blazer_2025_1023.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Mint Casual Summer Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
WHERE category = 'Casual Summer Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_mint_casual_summer_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Mint Casual Summer Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp', 'primary', 1, 'Men''s Mint Casual Summer Blazer Blazer - Image 1'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1028.webp', 'gallery', 2, 'Men''s Mint Casual Summer Blazer Blazer - Image 2'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1029.webp', 'gallery', 3, 'Men''s Mint Casual Summer Blazer Blazer - Image 3'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1030.webp', 'gallery', 4, 'Men''s Mint Casual Summer Blazer Blazer - Image 4'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1031.webp', 'gallery', 5, 'Men''s Mint Casual Summer Blazer Blazer - Image 5'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1032.webp', 'gallery', 6, 'Men''s Mint Casual Summer Blazer Blazer - Image 6'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_mint_casual_summer_blazer_2025_1027.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Pink Casual Summer Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
WHERE category = 'Casual Summer Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_pink_casual_summer_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Pink Casual Summer Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp', 'primary', 1, 'Men''s Pink Casual Summer Blazer Blazer - Image 1'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1025.webp', 'gallery', 2, 'Men''s Pink Casual Summer Blazer Blazer - Image 2'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1026.webp', 'gallery', 3, 'Men''s Pink Casual Summer Blazer Blazer - Image 3'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1027.webp', 'gallery', 4, 'Men''s Pink Casual Summer Blazer Blazer - Image 4'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1028.webp', 'gallery', 5, 'Men''s Pink Casual Summer Blazer Blazer - Image 5'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1029.webp', 'gallery', 6, 'Men''s Pink Casual Summer Blazer Blazer - Image 6'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1030.webp', 'gallery', 7, 'Men''s Pink Casual Summer Blazer Blazer - Image 7'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1031.webp', 'gallery', 8, 'Men''s Pink Casual Summer Blazer Blazer - Image 8'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1032.webp', 'gallery', 9, 'Men''s Pink Casual Summer Blazer Blazer - Image 9'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_pink_casual_summer_blazer_2025_1024.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Yellow Casual Summer Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
WHERE category = 'Casual Summer Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_yellow_casual_summer_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Yellow Casual Summer Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp', 'primary', 1, 'Men''s Yellow Casual Summer Blazer Blazer - Image 1'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1023.webp', 'gallery', 2, 'Men''s Yellow Casual Summer Blazer Blazer - Image 2'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1024.webp', 'gallery', 3, 'Men''s Yellow Casual Summer Blazer Blazer - Image 3'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1025.webp', 'gallery', 4, 'Men''s Yellow Casual Summer Blazer Blazer - Image 4'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1026.webp', 'gallery', 5, 'Men''s Yellow Casual Summer Blazer Blazer - Image 5'
FROM products
WHERE category = 'Casual Summer Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_yellow_casual_summer_blazer_2025_1022.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2001_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2001%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2001_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2001_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2001_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2001_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2002_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2002%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2002_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2002_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2002_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2002_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2003%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2003_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2003_1.webp', 'gallery', 3, 'Men''s Tuxedos Suit - Image 3'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2003_2.webp', 'gallery', 4, 'Men''s Tuxedos Suit - Image 4'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2003_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2004_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2004%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2004_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2004_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2004_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2005_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2005%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2005_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2005_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2005_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2006_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2006%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2007_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2007%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2008_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2008%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2008_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2008_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2008_1.webp', 'gallery', 3, 'Men''s Tuxedos Suit - Image 3'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2008_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2009_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2009%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2009_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2009_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2009_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2009_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2010%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_2.webp', 'gallery', 3, 'Men''s Tuxedos Suit - Image 3'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2010_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2011_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2011%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2011_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2011_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2011_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2011_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2012_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2012%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2012_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2012_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2012_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2012_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2013_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2013%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2014_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2014%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2014_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2014_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2014_1.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2014_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2015_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2015%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2015_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2015_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2015_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2015_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2016_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2016%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2017_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2017%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Tuxedos Suit
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2017_0.webp', 'primary', 1, 'Men''s Tuxedos Suit - Image 1'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2017_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2017_0.webp', 'gallery', 2, 'Men''s Tuxedos Suit - Image 2'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2017_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2017_1.webp', 'gallery', 3, 'Men''s Tuxedos Suit - Image 3'
FROM products
WHERE category = 'Tuxedos'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_model_2017_0.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2018_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2018%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2019_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2019%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Tuxedos Suit
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedos_suit_2020_0.webp'
WHERE category = 'Tuxedos'
  AND (
    LOWER(name) LIKE '%suit%'
    OR LOWER(sku) LIKE '%mens_tuxedos_suit_2020%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Paisley Pattern Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_model_1059.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_black_paisley_pattern_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Black Paisley Pattern Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_blazer_2025_1059.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_paisley_pattern_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Paisley Pattern Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_blazer_2025_1059.webp', 'primary', 1, 'Men''s Black Paisley Pattern Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_blazer_2025_1059.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_blazer_2025_1060.webp', 'gallery', 2, 'Men''s Black Paisley Pattern Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_paisley_pattern_velvet_blazer_2025_1059.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_solid_velvet_model_1064.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_black_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Solid Velvet Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_solid_velvet_model_1064.webp', 'primary', 1, 'Men''s Black Solid Velvet Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_solid_velvet_model_1064.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_solid_velvet_model_1081.webp', 'gallery', 2, 'Men''s Black Solid Velvet Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_solid_velvet_model_1064.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1081.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_black_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Black Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1081.webp', 'primary', 1, 'Men''s Black Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1081.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1090.webp', 'gallery', 2, 'Men''s Black Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1081.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1096.webp', 'gallery', 3, 'Men''s Black Velvet Blazer Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_2025_1081.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Black Velvet Blazer Shawl Lapel Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_black_velvet_blazer_shawl_lapel_2025_1064.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%lapel%'
    OR LOWER(sku) LIKE '%mens_black_velvet_blazer_shawl_lapel_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Brown Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_brown_solid_velvet_model_1078.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_brown_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Brown Velvet Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_brown_velvet_blazer_with_bowtie_2025_1078.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_brown_velvet_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_solid_velvet_model_1084.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_burgundy_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Burgundy Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_burgundy_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Burgundy Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp', 'primary', 1, 'Men''s Burgundy Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1070.webp', 'gallery', 2, 'Men''s Burgundy Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1074.webp', 'gallery', 3, 'Men''s Burgundy Velvet Blazer Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1079.webp', 'gallery', 4, 'Men''s Burgundy Velvet Blazer Blazer - Image 4'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1084.webp', 'gallery', 5, 'Men''s Burgundy Velvet Blazer Blazer - Image 5'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1085.webp', 'gallery', 6, 'Men''s Burgundy Velvet Blazer Blazer - Image 6'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1091.webp', 'gallery', 7, 'Men''s Burgundy Velvet Blazer Blazer - Image 7'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_burgundy_velvet_blazer_2025_1065.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Green Paisley Pattern Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_paisley_pattern_velvet_model_1089.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_green_paisley_pattern_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Green Paisley Pattern Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_paisley_pattern_velvet_blazer_2025_1089.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_green_paisley_pattern_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Green Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_solid_velvet_model_1060.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_green_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Green Solid Velvet Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_solid_velvet_model_1060.webp', 'primary', 1, 'Men''s Green Solid Velvet Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_solid_velvet_model_1060.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_solid_velvet_model_1082.webp', 'gallery', 2, 'Men''s Green Solid Velvet Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_solid_velvet_model_1060.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Green Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1056.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_green_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Green Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1056.webp', 'primary', 1, 'Men''s Green Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1056.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1082.webp', 'gallery', 2, 'Men''s Green Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1056.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1093.webp', 'gallery', 3, 'Men''s Green Velvet Blazer Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_2025_1056.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Green Velvet Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_with_bowtie_2025_1060.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_green_velvet_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Green Velvet Blazer With Bowtie Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_with_bowtie_2025_1060.webp', 'primary', 1, 'Men''s Green Velvet Blazer With Bowtie Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_with_bowtie_2025_1060.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_with_bowtie_2025_1068.webp', 'gallery', 2, 'Men''s Green Velvet Blazer With Bowtie Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_green_velvet_blazer_with_bowtie_2025_1060.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Navy Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_solid_velvet_model_1066.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_navy_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Navy Solid Velvet Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_solid_velvet_model_1066.webp', 'primary', 1, 'Men''s Navy Solid Velvet Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_solid_velvet_model_1066.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_solid_velvet_model_1087.webp', 'gallery', 2, 'Men''s Navy Solid Velvet Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_solid_velvet_model_1066.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Navy Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_navy_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Navy Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp', 'primary', 1, 'Men''s Navy Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1063.webp', 'gallery', 2, 'Men''s Navy Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1066.webp', 'gallery', 3, 'Men''s Navy Velvet Blazer Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1076.webp', 'gallery', 4, 'Men''s Navy Velvet Blazer Blazer - Image 4'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1077.webp', 'gallery', 5, 'Men''s Navy Velvet Blazer Blazer - Image 5'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1087.webp', 'gallery', 6, 'Men''s Navy Velvet Blazer Blazer - Image 6'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1092.webp', 'gallery', 7, 'Men''s Navy Velvet Blazer Blazer - Image 7'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1095.webp', 'gallery', 8, 'Men''s Navy Velvet Blazer Blazer - Image 8'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_navy_velvet_blazer_2025_1062.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Pink Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_pink_solid_velvet_model_1057.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_pink_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Pink Solid Velvet Lifestyle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_pink_solid_velvet_model_lifestyle_1057.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%lifestyle%'
    OR LOWER(sku) LIKE '%mens_pink_solid_velvet_lifestyle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Pink Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_pink_velvet_blazer_2025_1057.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_pink_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Purple Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_solid_velvet_model_1072.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_purple_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Purple Solid Velvet Lifestyle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_solid_velvet_model_lifestyle_1072.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%lifestyle%'
    OR LOWER(sku) LIKE '%mens_purple_solid_velvet_lifestyle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Purple Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_2025_1072.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_purple_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Purple Velvet Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_with_bowtie_2025_1069.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_purple_velvet_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Purple Velvet Blazer With Bowtie Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_with_bowtie_2025_1069.webp', 'primary', 1, 'Men''s Purple Velvet Blazer With Bowtie Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_with_bowtie_2025_1069.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_with_bowtie_2025_1073.webp', 'gallery', 2, 'Men''s Purple Velvet Blazer With Bowtie Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_purple_velvet_blazer_with_bowtie_2025_1069.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Paisley Pattern Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_paisley_pattern_velvet_model_1075.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_red_paisley_pattern_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Paisley Pattern Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_paisley_pattern_velvet_blazer_2025_1075.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_paisley_pattern_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Paisley Pattern Velvet Lifestyle Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_paisley_pattern_velvet_model_lifestyle_1075.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%lifestyle%'
    OR LOWER(sku) LIKE '%mens_red_paisley_pattern_velvet_lifestyle%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Red Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1055.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_red_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Red Solid Velvet Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1055.webp', 'primary', 1, 'Men''s Red Solid Velvet Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1080.webp', 'gallery', 2, 'Men''s Red Solid Velvet Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1088.webp', 'gallery', 3, 'Men''s Red Solid Velvet Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_solid_velvet_model_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1055.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_red_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Red Velvet Blazer Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1055.webp', 'primary', 1, 'Men''s Red Velvet Blazer Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1071.webp', 'gallery', 2, 'Men''s Red Velvet Blazer Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1080.webp', 'gallery', 3, 'Men''s Red Velvet Blazer Blazer - Image 3'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_2025_1055.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Red Velvet Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_with_bowtie_2025_1088.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_red_velvet_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Red Velvet Blazer With Bowtie Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_with_bowtie_2025_1088.webp', 'primary', 1, 'Men''s Red Velvet Blazer With Bowtie Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_with_bowtie_2025_1088.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_with_bowtie_2025_1094.webp', 'gallery', 2, 'Men''s Red Velvet Blazer With Bowtie Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_red_velvet_blazer_with_bowtie_2025_1088.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Royal Blue Solid Velvet Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal_blue_solid_velvet_model_1058.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%velvet%'
    OR LOWER(sku) LIKE '%mens_royal_blue_solid_velvet%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Royal Blue Solid Velvet Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal_blue_solid_velvet_model_1058.webp', 'primary', 1, 'Men''s Royal Blue Solid Velvet Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal_blue_solid_velvet_model_1058.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal_blue_solid_velvet_model_1061.webp', 'gallery', 2, 'Men''s Royal Blue Solid Velvet Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal_blue_solid_velvet_model_1058.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S Royal-Blue Paisley Pattern Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_paisley_pattern_velvet_blazer_model_1067.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal-blue_paisley_pattern_velvet_blazer%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Royal-Blue Paisley Pattern Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_paisley_pattern_velvet_blazer_2025_1067.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal-blue_paisley_pattern_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Royal-Blue Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_2025_1061.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_royal-blue_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update Men'S Royal-Blue Velvet Blazer With Bowtie Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_with_bowtie_2025_1058.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%bowtie%'
    OR LOWER(sku) LIKE '%mens_royal-blue_velvet_blazer_with_bowtie_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;

-- Add gallery images for Men'S Royal-Blue Velvet Blazer With Bowtie Blazer
INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_with_bowtie_2025_1058.webp', 'primary', 1, 'Men''s Royal-Blue Velvet Blazer With Bowtie Blazer - Image 1'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_with_bowtie_2025_1058.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO product_images (product_id, image_url, image_type, position, alt_text)
SELECT id, 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_with_bowtie_2025_1083.webp', 'gallery', 2, 'Men''s Royal-Blue Velvet Blazer With Bowtie Blazer - Image 2'
FROM products
WHERE category = 'Luxury Velvet Blazers'
  AND primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_royal-blue_velvet_blazer_with_bowtie_2025_1058.webp'
  AND status = 'active'
ON CONFLICT DO NOTHING;


-- Update Men'S White Velvet Blazer Blazer
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_white_velvet_blazer_2025_1086.webp'
WHERE category = 'Luxury Velvet Blazers'
  AND (
    LOWER(name) LIKE '%blazer%'
    OR LOWER(sku) LIKE '%mens_white_velvet_blazer_2025%'
  )
  AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
  AND status = 'active'
;


-- Update statistics
SELECT 
    'IMPORT COMPLETE' as status,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502158a94b8c%' THEN 1 END) as new_gallery_images,
    COUNT(CASE WHEN primary_image LIKE '%webp%' THEN 1 END) as webp_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as remaining_placeholders
FROM products
WHERE status = 'active';

-- Gallery entries created
SELECT 
    COUNT(*) as total_gallery_images,
    COUNT(DISTINCT product_id) as products_with_galleries
FROM product_images;

COMMIT;