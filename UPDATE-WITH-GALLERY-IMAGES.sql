-- UPDATE PRODUCTS WITH HIGH-QUALITY GALLERY IMAGES
-- From product_gallery-Super-Admin.csv

BEGIN;

-- Show current state
SELECT 
    'BEFORE GALLERY UPDATE' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%webp%' THEN 1 END) as webp_images,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as r2_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images
FROM products
WHERE status = 'active';

-- ==========================================
-- VELVET BLAZERS (35 products)
-- ==========================================

-- Update velvet blazers with new high-quality images
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/velvet-blazer/mens_velvet_blazer_2025_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Luxury Velvet Blazers'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    ORDER BY created_at
    LIMIT 35
);

-- ==========================================
-- SPARKLE & SEQUIN BLAZERS (18 products)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/sparkle-blazer/mens_sparkle_blazer_2025_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Sparkle & Sequin Blazers'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    ORDER BY created_at
    LIMIT 18
);

-- ==========================================
-- PROM & FORMAL BLAZERS (27 products)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/prom_blazer/mens_prom_blazer_2025_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Prom & Formal Blazers'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    ORDER BY created_at
    LIMIT 27
);

-- ==========================================
-- VEST & TIE SETS (47 products)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-solid-vest-tie/blush-model.png'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Vest & Tie Sets'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    ORDER BY created_at
    LIMIT 47
);

-- ==========================================
-- TUXEDOS (20 products)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/tuxedos/mens_tuxedo_classic_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Tuxedos'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    ORDER BY created_at
    LIMIT 20
);

-- ==========================================
-- DRESS SHIRTS (16 products)
-- ==========================================

-- Mock neck shirts
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/mock_neck/mens_dress_shirt_mock_neck_3001_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Dress Shirts'
        AND LOWER(name) LIKE '%mock%neck%'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 4
);

-- Turtle neck shirts
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/turtle_neck/mens_dress_shirt_turtle_neck_3002_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Dress Shirts'
        AND LOWER(name) LIKE '%turtle%neck%'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 5
);

-- Stretch collar shirts
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/dress_shirts/stretch_collar/mens_dress_shirt_stretch_collar_model_3004_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Dress Shirts'
        AND LOWER(name) LIKE '%stretch%'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 3
);

-- ==========================================
-- SUITS (10 stretch suits + 3 regular)
-- ==========================================

-- Stretch suits
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/stretch_suits/mens_stretch_suit_2025_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND LOWER(name) LIKE '%stretch%'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 10
);

-- Double breasted suits
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_2024_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND LOWER(name) LIKE '%double%breasted%'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 4
);

-- ==========================================
-- ACCESSORIES (16 suspender/bowtie sets)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/main-suspender-bowtie-set/suspender_bowtie_set_model_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND (LOWER(name) LIKE '%suspender%' OR LOWER(name) LIKE '%bowtie%')
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 16
);

-- ==========================================
-- SUMMER BLAZERS (5 products)
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/summer-blazer/mens_summer_blazer_2025_0.webp'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Casual Summer Blazers'
        AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    LIMIT 5
);

-- ==========================================
-- Show results
-- ==========================================

SELECT 
    'AFTER GALLERY UPDATE' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%webp%' THEN 1 END) as webp_images,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502158a94b8c%' THEN 1 END) as new_gallery_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as still_placeholder,
    ROUND(
        COUNT(CASE WHEN primary_image NOT LIKE '%placehold%' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) || '%' as percent_real_images
FROM products
WHERE status = 'active';

-- Category breakdown
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%webp%' THEN 1 END) as webp,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502158a94b8c%' THEN 1 END) as new_gallery,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total DESC;

COMMIT;

-- Sample of updated products
SELECT 
    name,
    category,
    SUBSTRING(primary_image, 1, 80) as image_preview
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%8ea0502158a94b8c%'
ORDER BY RANDOM()
LIMIT 5;