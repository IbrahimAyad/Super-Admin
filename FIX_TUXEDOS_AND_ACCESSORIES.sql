-- FIX TUXEDOS - 14 products sharing one image!
-- Assign unique images to each tuxedo

BEGIN;

-- ========================================
-- TUXEDOS - Fix 14 products sharing same image
-- ========================================

-- Keep the first one with its current image
-- Black Gold Design Tuxedo - KEEP AS IS (752d5ac2-1ff3-46f6-af07-8e38fead8c49)

-- Assign unique images to the other 13
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-gold-design-tuxedo/mens_tuxedos_suit_2005_1.webp'
WHERE id = '358a13f9-e236-47cd-866d-690314c36549'; -- Black Paisley Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-on-black-slim-tuxedo-tone-trim-tuxedo/mens_tuxedos_suit_2003_1.webp'
WHERE id = 'b4599c56-16f4-4d59-a6ea-ef451d3a1fb7'; -- Black Tone Trim Tuxedo Shawl Lapel

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-on-black-slim-tuxedo-tone-trim-tuxedo/mens_tuxedos_suit_model_2003_0.webp'
WHERE id = '65d895b4-1a0e-4042-953b-f38a29fd18b4'; -- Blush Pink Paisley Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/burnt-orange-tuxedo/mens_tuxedos_suit_2008_1.webp'
WHERE id = '46913915-1cb1-4207-946e-718264c6fb8c'; -- Blush Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/burnt-orange-tuxedo/mens_tuxedos_suit_model_2008_0.webp'
WHERE id = '893b13a3-3f84-46b6-b99b-3c28c2bd3eac'; -- Classic Black Tuxedo with Satin Lapels

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/hunter-green-tuxedo/mens_tuxedos_suit_model_2009_0.webp'
WHERE id = 'fb4633e4-7b66-4465-8505-299fb2bd13ab'; -- Gold Paisley Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/pink-gold-design-tuxedo/mens_tuxedos_suit_2012_1.webp'
WHERE id = 'cdb3f7c7-9562-4b0f-b4d1-a5084da9c28b'; -- Ivory Black Tone Trim Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/sand-tuxedo/mens_tuxedos_suit_model_2011_0.webp'
WHERE id = '2a8b6f75-3209-47c4-b0de-4c224c8099b1'; -- Ivory Gold Paisley Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/wine-on-wine-slim-tuxedotone-trim-tuxedo/mens_tuxedos_suit_model_2015_0.webp'
WHERE id = '68241be0-f02d-4e82-b4cc-cb14ebe69e19'; -- Ivory Paisley Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/light-grey/main.webp'
WHERE id = 'ed113151-e007-4666-abc2-e9f5e104436f'; -- Light Grey On Light Grey Slim Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/fall-smoked-blue-double-breasted-suit/main.webp'
WHERE id = 'cd1d03c4-4108-48ef-a497-e1cdc74b250d'; -- Navy Tone Trim Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/pink/main.webp'
WHERE id = '4ddadf12-d18c-47b4-9b52-c3f2ba45c068'; -- Vivid Purple Tuxedo

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/white-tuxedo-double-breasted/main.webp'
WHERE id = 'c855b553-4527-4c3e-9eee-ec09c2bc2643'; -- White Black Tuxedo

-- ========================================
-- Verify Tuxedo fix
-- ========================================

SELECT 'TUXEDOS AFTER FIX' as status,
    COUNT(*) as total,
    COUNT(DISTINCT primary_image) as unique_images,
    COUNT(*) - COUNT(DISTINCT primary_image) as duplicates
FROM products
WHERE category = 'Tuxedos';

-- ========================================
-- Now get Accessories to fix
-- ========================================

WITH dup_accessories AS (
    SELECT primary_image, COUNT(*) as count
    FROM products 
    WHERE category = 'Accessories'
    GROUP BY primary_image
)
SELECT 
    p.id,
    p.name,
    p.sku,
    SUBSTRING(p.primary_image FROM POSITION('/vest-tie-set/' IN p.primary_image) + 14 FOR 20) as vest_color,
    d.count as products_sharing_image
FROM products p
JOIN dup_accessories d ON p.primary_image = d.primary_image
WHERE p.category = 'Accessories'
ORDER BY d.count DESC, p.primary_image, p.name;

-- ========================================
-- Also check remaining categories
-- ========================================

SELECT 'DOUBLE-BREASTED' as category,
    COUNT(*) as total,
    COUNT(DISTINCT primary_image) as unique_images,
    COUNT(*) - COUNT(DISTINCT primary_image) as duplicates
FROM products
WHERE category = 'Double-Breasted Suits';

SELECT 'STRETCH SUITS' as category,
    COUNT(*) as total,
    COUNT(DISTINCT primary_image) as unique_images,
    COUNT(*) - COUNT(DISTINCT primary_image) as duplicates
FROM products
WHERE category = 'Stretch Suits';

COMMIT;