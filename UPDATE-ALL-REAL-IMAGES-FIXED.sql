-- UPDATE ALL PLACEHOLDER IMAGES WITH REAL R2 BUCKET IMAGES
-- Fixed version - PostgreSQL compatible (no LIMIT in UPDATE)

BEGIN;

-- Show current state
SELECT 
    'BEFORE UPDATE' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images
FROM products
WHERE status = 'active';

-- ==========================================
-- BLAZERS (54 products from blazers CSV)
-- ==========================================

-- Black Red Blazer And Floral With Matching Bowtie
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-and-red-floral-with-matching-bowtie_1.0.jpg'
WHERE (LOWER(name) LIKE '%blazer%floral%bowtie%' OR LOWER(name) LIKE '%black%red%blazer%')
    AND primary_image LIKE '%placehold%';

-- Red Black Blazer Floral Prom Tuxedo
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_red-floral-prom-tuxedo-blazer-2025-black-satin-lapel_1.0.jpg'
WHERE (LOWER(name) LIKE '%red%floral%tuxedo%' OR LOWER(name) LIKE '%floral%prom%tuxedo%')
    AND primary_image LIKE '%placehold%';

-- Black Glitter Rhinestone Shawl Lapel Tuxedo Blazer
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_black-glitter-rhinestone-shawl-lapel-tuxedo-blazer-prom-2025_1.0.jpg'
WHERE (LOWER(name) LIKE '%glitter%rhinestone%' OR LOWER(name) LIKE '%rhinestone%shawl%')
    AND primary_image LIKE '%placehold%';

-- Royal Blue Embellished Lapel Tuxedo Blazer
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_men-s-royal-blue-embellished-lapel-tuxedo-blazer-prom-wedding_1.0.jpg'
WHERE (LOWER(name) LIKE '%royal%blue%embellished%' OR LOWER(name) LIKE '%blue%embellished%lapel%')
    AND primary_image LIKE '%placehold%';

-- ==========================================
-- VELVET BLAZERS - Map by color keywords
-- ==========================================

-- Black Velvet Blazers (update first 10)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-velvet-prom-tuxedo-blazer_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Luxury Velvet Blazers'
        AND LOWER(name) LIKE '%black%velvet%'
        AND primary_image LIKE '%placehold%'
    ORDER BY created_at
    LIMIT 10
);

-- Red Velvet Blazers (update first 10)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_red-velvet-prom-tuxedo-blazer_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Luxury Velvet Blazers'
        AND LOWER(name) LIKE '%red%velvet%'
        AND primary_image LIKE '%placehold%'
    ORDER BY created_at
    LIMIT 10
);

-- Blue Velvet Blazers (update first 10)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_blue-velvet-prom-tuxedo-blazer_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Luxury Velvet Blazers'
        AND (LOWER(name) LIKE '%blue%velvet%' OR LOWER(name) LIKE '%navy%velvet%')
        AND primary_image LIKE '%placehold%'
    ORDER BY created_at
    LIMIT 10
);

-- Green Velvet Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_green-velvet-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Luxury Velvet Blazers'
    AND LOWER(name) LIKE '%green%velvet%'
    AND primary_image LIKE '%placehold%';

-- Purple Velvet Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_purple-velvet-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Luxury Velvet Blazers'
    AND LOWER(name) LIKE '%purple%velvet%'
    AND primary_image LIKE '%placehold%';

-- ==========================================
-- SPARKLE & SEQUIN BLAZERS
-- ==========================================

-- Gold Sequin Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_gold-sequin-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Sparkle & Sequin Blazers'
    AND LOWER(name) LIKE '%gold%sequin%'
    AND primary_image LIKE '%placehold%';

-- Silver Sequin Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_silver-sequin-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Sparkle & Sequin Blazers'
    AND LOWER(name) LIKE '%silver%sequin%'
    AND primary_image LIKE '%placehold%';

-- Black Sequin Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-sequin-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Sparkle & Sequin Blazers'
    AND LOWER(name) LIKE '%black%sequin%'
    AND primary_image LIKE '%placehold%';

-- Red Sequin Blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_red-sequin-prom-tuxedo-blazer_1.0.jpg'
WHERE category = 'Sparkle & Sequin Blazers'
    AND LOWER(name) LIKE '%red%'
    AND primary_image LIKE '%placehold%';

-- ==========================================
-- DRESS SHIRTS
-- ==========================================

UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shirt_white-dress-shirt_1.0.png'
WHERE category = 'Men''s Dress Shirts'
    AND LOWER(name) LIKE '%white%dress%shirt%'
    AND primary_image LIKE '%placehold%';

UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shirt_red-dress-shirt_1.0.png'
WHERE category = 'Men''s Dress Shirts'
    AND LOWER(name) LIKE '%red%dress%shirt%'
    AND primary_image LIKE '%placehold%';

-- Generic dress shirts (for remaining)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shirt_white-dress-shirt_1.0.png'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Dress Shirts'
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- ==========================================
-- SUITS
-- ==========================================

-- Black Suits (update first 5)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/suit_black-3-piece-suit_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND LOWER(name) LIKE '%black%suit%'
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- Navy/Blue Suits (update first 5)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suit_navy-3-piece-suit_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND (LOWER(name) LIKE '%navy%suit%' OR LOWER(name) LIKE '%blue%suit%')
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- Grey Suits (update first 5)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suit_grey-3-piece-suit_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND LOWER(name) LIKE '%grey%suit%'
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- Generic suits for remaining
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/suit_black-3-piece-suit_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Men''s Suits'
        AND primary_image LIKE '%placehold%'
    LIMIT 20
);

-- ==========================================
-- VEST & TIE SETS
-- ==========================================

-- Black Vest Sets (update first 3)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_black-vest-and-tie-set_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Vest & Tie Sets'
        AND LOWER(name) LIKE '%black%vest%'
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Red Vest Sets (update first 3)  
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_red-vest-and-tie-set_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Vest & Tie Sets'
        AND LOWER(name) LIKE '%red%vest%'
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Blue Vest Sets (update first 3)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_royal-blue-vest-and-tie-set_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Vest & Tie Sets'
        AND (LOWER(name) LIKE '%blue%vest%' OR LOWER(name) LIKE '%royal%vest%')
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Generic vest sets for remaining
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest_black-vest-and-tie-set_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Vest & Tie Sets'
        AND primary_image LIKE '%placehold%'
    LIMIT 15
);

-- ==========================================
-- ACCESSORIES (Bowties, Ties, etc)
-- ==========================================

-- Bowties (update first 5)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/bowtie_red-and-black-with-matching-bowtie_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND LOWER(name) LIKE '%bowtie%'
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- Neckties (update first 5)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/necktie_black-with-red-design_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND LOWER(name) LIKE '%necktie%'
        AND primary_image LIKE '%placehold%'
    LIMIT 5
);

-- Cummerbunds (update first 3)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/cummerband_royal-blue-cummerbund-set_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND LOWER(name) LIKE '%cummerbund%'
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Black Dress Shoes (update first 3)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boot_black-jotter-cap-toe_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND LOWER(name) LIKE '%black%shoe%'
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Chelsea Boots (update first 3)
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/boots_black-chelsea-boots_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND LOWER(name) LIKE '%chelsea%boot%'
        AND primary_image LIKE '%placehold%'
    LIMIT 3
);

-- Generic accessories for remaining
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/necktie_black-with-red-design_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Accessories'
        AND primary_image LIKE '%placehold%'
    LIMIT 10
);

-- ==========================================
-- PROM & FORMAL BLAZERS
-- ==========================================

-- Use various prom blazer images based on keywords
UPDATE products
SET primary_image = CASE 
    WHEN LOWER(name) LIKE '%floral%' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_red-floral-prom-tuxedo-blazer-2025-black-satin-lapel_1.0.jpg'
    WHEN LOWER(name) LIKE '%sequin%' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_gold-sequin-prom-tuxedo-blazer_1.0.jpg'
    WHEN LOWER(name) LIKE '%velvet%' THEN 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-velvet-prom-tuxedo-blazer_1.0.jpg'
    ELSE 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/blazer_black-glitter-rhinestone-shawl-lapel-tuxedo-blazer-prom-2025_1.0.jpg'
END
WHERE category = 'Prom & Formal Blazers'
    AND primary_image LIKE '%placehold%';

-- ==========================================
-- CASUAL SUMMER BLAZERS
-- ==========================================

-- Update first 7 with light blue image
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/blazer_light-blue-casual-summer-blazer_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Casual Summer Blazers'
        AND primary_image LIKE '%placehold%'
    LIMIT 7
);

-- ==========================================
-- REGULAR BLAZERS
-- ==========================================

-- Update generic blazers
UPDATE products
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/blazer_black-and-red-floral-with-matching-bowtie_1.0.jpg'
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Blazers'
        AND primary_image LIKE '%placehold%'
    LIMIT 8
);

-- ==========================================
-- Show results
-- ==========================================

SELECT 
    'AFTER UPDATE' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as still_placeholder,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images,
    ROUND(
        COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) as percent_real_images
FROM products
WHERE status = 'active';

-- Show breakdown by category
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    ROUND(
        COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) as percent_real
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total DESC;

COMMIT;

-- Sample updated products
SELECT 
    name,
    category,
    SUBSTRING(primary_image, 1, 80) as image_preview
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%r2.dev%'
ORDER BY RANDOM()
LIMIT 10;