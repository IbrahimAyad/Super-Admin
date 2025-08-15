-- FIX REMAINING IMAGE URLS
-- These products still have old image paths that don't exist

-- First, let's check what images are still broken
SELECT 
    name, 
    primary_image,
    CASE 
        WHEN primary_image LIKE '%nan_%' THEN 'Has nan_ prefix'
        WHEN primary_image LIKE '%vest-tie_%' THEN 'Has vest-tie_ prefix'
        WHEN primary_image LIKE '%vest-and-tie_%' THEN 'Has vest-and-tie_ prefix'
        WHEN primary_image NOT LIKE 'https://%' THEN 'Missing https://'
        ELSE 'Other issue'
    END as issue
FROM products
WHERE primary_image NOT LIKE 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/%'
   OR primary_image LIKE '%nan_%'
   OR primary_image LIKE '%vest-tie_%'
   OR primary_image LIKE '%vest-and-tie_%'
   OR primary_image LIKE '%boots_%'
   OR primary_image LIKE '%blazer_%'
   OR primary_image LIKE '%bowtie_%'
   OR primary_image LIKE '%cummerband_%'
   OR primary_image LIKE '%kid-suit_%'
   OR primary_image LIKE '%mens-tuxedos_%'
   OR primary_image LIKE '%mens-blazers_%'
   OR primary_image LIKE '%mens-suits_%'
   OR primary_image LIKE '%mens-double-breasted-suit_%'
ORDER BY category, name
LIMIT 100;

-- Fix products that still have relative paths (not full URLs)
UPDATE products
SET primary_image = 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/' || primary_image
WHERE primary_image NOT LIKE 'https://%'
  AND primary_image IS NOT NULL
  AND primary_image != '';

-- Count how many still need fixing
SELECT 
    'Products with broken image paths' as status,
    COUNT(*) as count
FROM products
WHERE primary_image NOT LIKE 'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/%'
   OR primary_image IS NULL;