-- MANUAL COMPLETE IMAGE FIX V2
-- Fixed: PostgreSQL doesn't support LIMIT in UPDATE, using subqueries instead

BEGIN;

-- ========================================
-- ACCESSORIES (37 products total)
-- ========================================

-- SUSPENDER & BOWTIE SETS (Assigning unique images to each)
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/black-suspender-bowtie-set/main.webp' WHERE name = 'Black Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/brown-suspender-bowtie-set/model.webp' WHERE name = 'Brown Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/burnt-orange-suspender-bowtie-set/model.webp' WHERE name = 'Burnt Orange Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/dusty-rose-suspender-bowtie-set/model.webp' WHERE name = 'Dusty Rose Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/fuchsia-suspender-bowtie-set/model.webp' WHERE name = 'Fuchsia Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/gold-suspender-bowtie-set/model.webp' WHERE name = 'Gold Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/hunter-green-suspender-bowtie-set/model.webp' WHERE name = 'Hunter Green Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/medium-red-suspender-bowtie-set/model.webp' WHERE name = 'Medium Red Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/orange-suspender-bowtie-set/model.webp' WHERE name = 'Orange Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/powder-blue-suspender-bowtie-set/model.webp' WHERE name = 'Powder Blue Suspender & Bowtie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/suspender-bowtie-set/medium-red-suspender-bowtie-set/product.jpg' WHERE name = 'Red Suspender & Bowtie Set' AND category = 'Accessories';

-- VEST & TIE SETS (26 different colors)
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/blush-vest/model.webp' WHERE name = 'Blush Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/burnt-orange-vest/model.webp' WHERE name = 'Burnt Orange Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/canary-vest/model.webp' WHERE name = 'Canary Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/carolina-blue-vest/model.webp' WHERE name = 'Carolina Blue Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/chocolate-brown-vest/model.webp' WHERE name = 'Chocolate Brown Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/coral-vest/model.webp' WHERE name = 'Coral Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/dark-burgundy-vest/model.webp' WHERE name = 'Dark Burgundy Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/dark-teal/main.webp' WHERE name = 'Dark Teal Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/dusty-rose-vest/model.webp' WHERE name = 'Dusty Rose Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/dusty-sage-vest/model.webp' WHERE name = 'Dusty Sage Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/emerald-green-vest/main.webp' WHERE name = 'Emerald Green Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/fuchsia-vest/model.webp' WHERE name = 'Fuchsia Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/gold-vest/model.webp' WHERE name = 'Gold Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/grey-vest/model.webp' WHERE name = 'Grey Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/hunter-green-vest/model.webp' WHERE name = 'Hunter Green Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/lilac-vest/model.webp' WHERE name = 'Lilac Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/mint-vest/model.webp' WHERE name = 'Mint Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/peach-vest/model.webp' WHERE name = 'Peach Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/pink-vest/model.webp' WHERE name = 'Pink Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/plum-vest/model.webp' WHERE name = 'Plum Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/powder-blue-vest/model.webp' WHERE name = 'Powder Blue Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/red-vest/model.webp' WHERE name = 'Red Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/rose-gold-vest/rose-gold-vest.jpg' WHERE name = 'Rose Gold Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/royal-blue-vest/model.webp' WHERE name = 'Royal Blue Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/turquoise-vest/model.webp' WHERE name = 'Turquoise Vest & Tie Set' AND category = 'Accessories';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/menswear-accessories/vest-tie-set/wine-vest/model.webp' WHERE name = 'Wine Vest & Tie Set' AND category = 'Accessories';

-- ========================================
-- TUXEDOS (20 products - we have 8 designs, some with multiple angles)
-- ========================================

-- Main tuxedo designs
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-gold-design-tuxedo/mens_tuxedos_suit_2005_0.webp' WHERE name LIKE '%Black Gold%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-on-black-slim-tuxedo-tone-trim-tuxedo/mens_tuxedos_suit_2003_0.webp' WHERE name LIKE '%Black on Black%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/burnt-orange-tuxedo/mens_tuxedos_suit_2008_0.webp' WHERE name LIKE '%Burnt Orange%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/hunter-green-tuxedo/mens_tuxedos_suit_2009_0.webp' WHERE name LIKE '%Hunter Green%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/pink-gold-design-tuxedo/mens_tuxedos_suit_2012_0.webp' WHERE name LIKE '%Pink Gold%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/sand-tuxedo/mens_tuxedos_suit_2011_0.webp' WHERE name LIKE '%Sand%' AND category = 'Tuxedos';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/wine-on-wine-slim-tuxedotone-trim-tuxedo/mens_tuxedos_suit_2015_0.webp' WHERE name LIKE '%Wine%' AND category = 'Tuxedos';

-- For any remaining tuxedos, use alternate angles by ID
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-gold-design-tuxedo/mens_tuxedos_suit_2005_1.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-on-black-slim-tuxedo-tone-trim-tuxedo/mens_tuxedos_suit_2003_1.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-on-black-slim-tuxedo-tone-trim-tuxedo/mens_tuxedos_suit_model_2003_0.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/burnt-orange-tuxedo/mens_tuxedos_suit_2008_1.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/burnt-orange-tuxedo/mens_tuxedos_suit_model_2008_0.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/hunter-green-tuxedo/mens_tuxedos_suit_model_2009_0.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/pink-gold-design-tuxedo/mens_tuxedos_suit_2012_1.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/sand-tuxedo/mens_tuxedos_suit_model_2011_0.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/wine-on-wine-slim-tuxedotone-trim-tuxedo/mens_tuxedos_suit_model_2015_0.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Tuxedos' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

-- ========================================
-- SUITS (10 products - we have 5 designs with multiple images)
-- ========================================

UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/brown-gold-buttons/mens_suits_suit_2035_0.webp' WHERE name LIKE '%Brown%Gold%' AND category = 'Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/burnt-orange/mens_suits_suit_2036_0.webp' WHERE name LIKE '%Burnt Orange%' AND category = 'Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/fall-rust/V2RK-5_RUST_JPG_WEB.jpg' WHERE name LIKE '%Fall Rust%' AND category = 'Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/brick-fall-suit/main.webp' WHERE name LIKE '%Brick%' AND category = 'Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/mint/main.webp' WHERE name LIKE '%Mint%' AND category = 'Suits';

-- Use alternate images for duplicates
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/brown-gold-buttons/mens_suits_suit_model_2035_0.webp' WHERE name LIKE '%Brown%' AND category = 'Suits' AND (primary_image IS NULL OR primary_image = '');
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/brown-gold-buttons/mens_suits_suit_model_2035_1.webp' WHERE name LIKE '%Brown%' AND category = 'Suits' AND (primary_image IS NULL OR primary_image = '');
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/burnt-orange/mens_suits_suit_model_2036_0.webp' WHERE name LIKE '%Orange%' AND category = 'Suits' AND (primary_image IS NULL OR primary_image = '');
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/fall-rust/V2RK-5_RUST_VEST_JPG_WEB.jpg' WHERE name LIKE '%Rust%' AND category = 'Suits' AND (primary_image IS NULL OR primary_image = '');
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/suits/fall-rust/V2RK-5-RUST-LINING-WEB.jpg' WHERE category = 'Suits' AND (primary_image IS NULL OR primary_image = '');

-- ========================================
-- SHIRTS (All should have unique images)
-- ========================================

UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/black-turtleneck/main.webp' WHERE name = 'Black Turtleneck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/black-ultra-stretch-dress-shirt/main.webp' WHERE name = 'Black Ultra Stretch Dress Shirt' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/light-blue-turtleneck/main.webp' WHERE name = 'Light Blue Turtleneck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/tan-turtleneck/main.webp' WHERE name = 'Tan Turtleneck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/white-turtleneck/main.webp' WHERE name = 'White Turtleneck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/light-blue-collarless-dress-shirt/main.webp' WHERE name = 'Light Blue Collarless Dress Shirt' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/white-collarless-dress-shirt/main.webp' WHERE name = 'White Collarless Dress Shirt' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/black-collarless-dress-shirt/main.webp' WHERE name = 'Black Collarless Dress Shirt' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/black-short-sleeve-moc-neck/main.webp' WHERE name = 'Black Short Sleeve Mock Neck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/light-grey-turtleneck/main.webp' WHERE name = 'Light Grey Turtleneck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/navy-short-sleeve-moc-neck/main.webp' WHERE name = 'Navy Short Sleeve Mock Neck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/tan-short-sleeve-moc-neck/main.webp' WHERE name = 'Tan Short Sleeve Mock Neck' AND category = 'Shirts';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/mens-shirts/white-short-sleeve-moc-neck/main.webp' WHERE name = 'White Short Sleeve Mock Neck' AND category = 'Shirts';

-- ========================================
-- DOUBLE-BREASTED SUITS (12 products - we have 10 designs)
-- ========================================

UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/main.webp' WHERE name LIKE '%Black Strip%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/fall-forest-green-mocha-double-breasted-suit/main.webp' WHERE name LIKE '%Forest Green%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/fall-mocha-double-breasted-suit/DRK-5_MOCHA_JPG_WEB.jpg' WHERE name LIKE '%Mocha%' AND NOT name LIKE '%Forest%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/fall-smoked-blue-double-breasted-suit/main.webp' WHERE name LIKE '%Smoked Blue%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/light-grey/main.webp' WHERE name LIKE '%Light Grey%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/pin-stripe-canyon-clay-double-breasted-suit/main.webp' WHERE name LIKE '%Canyon Clay%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/pink/main.webp' WHERE name LIKE '%Pink%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/red-tuxedo-double-breasted/main.webp' WHERE name LIKE '%Red%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/tan-tuxedo-double-breasted/main.webp' WHERE name LIKE '%Tan%' AND category = 'Double-Breasted Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/white-tuxedo-double-breasted/main.webp' WHERE name LIKE '%White%' AND category = 'Double-Breasted Suits';

-- Use alternate images for the 2 extra products
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/front.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Double-Breasted Suits' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/double-breasted-suits/black-strip-shawl-lapel/back.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Double-Breasted Suits' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

-- ========================================
-- STRETCH SUITS (10 products - we have 9 designs)
-- ========================================

UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/beige-slim-stretch/main.webp' WHERE name LIKE '%Beige%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/black-slim-stretch/main.webp' WHERE name LIKE '%Black%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/burgundy--slim-stretch/main.webp' WHERE name LIKE '%Burgundy%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/light-grey-slim-stretch/main.webp' WHERE name LIKE '%Light Grey%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/mauve-slim-stretch/main.webp' WHERE name LIKE '%Mauve%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/mint-slim-stretch/main.webp' WHERE name LIKE '%Mint%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/pink-slim-stretch/main.webp' WHERE name LIKE '%Pink%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/salmon-slim-stretch/main.webp' WHERE name LIKE '%Salmon%' AND category = 'Stretch Suits';
UPDATE products SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/tan-slim-stretch/main.webp' WHERE name LIKE '%Tan%' AND category = 'Stretch Suits';

-- Use alternate image for the 10th product
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/stretch-suits/beige-slim-stretch/lifestlye.webp' 
WHERE id IN (
    SELECT id FROM products 
    WHERE category = 'Stretch Suits' AND (primary_image IS NULL OR primary_image = '')
    ORDER BY name
    LIMIT 1
);

-- ========================================
-- VERIFICATION
-- ========================================

-- Check for any products still without images
SELECT 
    category,
    COUNT(*) as products_without_images,
    STRING_AGG(name, ', ' ORDER BY name) as product_names
FROM products
WHERE category IN ('Accessories', 'Suits', 'Shirts', 'Tuxedos', 'Stretch Suits', 'Double-Breasted Suits', 'Blazers')
  AND (primary_image IS NULL OR primary_image = '')
GROUP BY category;

-- Final count of unique images per category
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(DISTINCT primary_image) as unique_images,
    COUNT(*) - COUNT(DISTINCT primary_image) as remaining_duplicates
FROM products
WHERE category IN ('Accessories', 'Suits', 'Shirts', 'Tuxedos', 'Stretch Suits', 'Double-Breasted Suits', 'Blazers')
GROUP BY category
ORDER BY category;

COMMIT;