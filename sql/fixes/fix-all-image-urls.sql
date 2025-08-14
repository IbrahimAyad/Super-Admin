-- Fix All Product Image URLs
-- This fixes the broken images by updating wrong bucket URLs

BEGIN;

-- Fix products table primary images
UPDATE products 
SET primary_image = REPLACE(
  primary_image, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev',  -- Wrong bucket
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'   -- Correct bucket
)
WHERE primary_image LIKE '%pub-8ea%';

-- Fix product_images table URLs
UPDATE product_images 
SET image_url = REPLACE(
  image_url, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev',  -- Wrong bucket
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'   -- Correct bucket
)
WHERE image_url LIKE '%pub-8ea%';

-- Check how many were fixed
SELECT 
  'Products Fixed' as table_name,
  COUNT(*) as count
FROM products 
WHERE primary_image LIKE '%pub-5cd8c531c0034986bf6282a223bd0564.r2.dev%'

UNION ALL

SELECT 
  'Product Images Fixed' as table_name,
  COUNT(*) as count
FROM product_images 
WHERE image_url LIKE '%pub-5cd8c531c0034986bf6282a223bd0564.r2.dev%';

COMMIT;

-- Verify all images now use correct buckets
SELECT DISTINCT
  SUBSTRING(primary_image FROM 'https://([^/]+)') as bucket_domain,
  COUNT(*) as product_count
FROM products
WHERE primary_image IS NOT NULL
GROUP BY bucket_domain
ORDER BY product_count DESC;