-- Fix Missing Images and CORS Issues
-- This script updates broken image URLs to working ones

BEGIN;

-- 1. Update products using the broken R2 bucket to the working one
UPDATE products 
SET primary_image = REPLACE(
  primary_image, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
)
WHERE primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev%';

-- Also update product_images table
UPDATE product_images 
SET image_url = REPLACE(
  image_url, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
)
WHERE image_url LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev%';

-- 2. Fix specific missing images by replacing with similar working ones
UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg'
WHERE primary_image LIKE '%tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg'
AND primary_image NOT LIKE '%batch_1/batch_2/%';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_royal-blue-three-piece-suit_1.0.jpg'
WHERE primary_image LIKE '%mens-suits_royal-blue-three-piece-suit_1.0.jpg';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-jacket_turquoise-tuxedo-jacket_1.0.jpg'
WHERE primary_image LIKE '%tuxedo-jacket_turquoise-tuxedo-jacket_1.0.jpg';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_charcoal-grey-executive-suit_1.0.jpg'
WHERE primary_image LIKE '%mens-suits_charcoal-grey-executive-suit_1.0.jpg';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-suits_classic-navy-business-suit_1.0.jpg'
WHERE primary_image LIKE '%mens-suits_classic-navy-business-suit_1.0.jpg';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/vest-tie_lavender-vest-and-tie-set_1.0.jpg'
WHERE primary_image LIKE '%vest-tie_lavender-vest-and-tie-set_1.0.jpg';

UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg'
WHERE primary_image LIKE '%mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg';

-- 3. Sync product_images table with updated primary_image
UPDATE product_images pi
SET image_url = p.primary_image
FROM products p
WHERE pi.product_id = p.id 
AND pi.image_type = 'primary'
AND pi.image_url != p.primary_image;

-- 4. Show what was fixed
SELECT 
    'Fixed Images Summary' as report,
    COUNT(*) as total_products_with_images,
    COUNT(*) FILTER (WHERE primary_image LIKE '%pub-5cd8c531c0034986bf6282a223bd0564.r2.dev%') as working_bucket_images,
    COUNT(*) FILTER (WHERE primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev%') as problematic_bucket_images
FROM products
WHERE primary_image IS NOT NULL;

-- 5. List products that might still have issues
SELECT 
    sku,
    name,
    LEFT(primary_image, 80) || '...' as image_url_preview
FROM products
WHERE primary_image IS NOT NULL
AND (
    primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev%'
    OR primary_image LIKE '%emerlad-green-model.png%'
    OR primary_image LIKE '%mens_tuxedo_model_2006.webp%'
)
ORDER BY sku;

COMMIT;