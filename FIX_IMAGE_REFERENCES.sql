-- ============================================
-- FIX IMAGE REFERENCES - Update R2 to Supabase
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Check how many products have R2 image references
SELECT 
    COUNT(*) as products_with_r2_images,
    COUNT(DISTINCT primary_image) as unique_images
FROM public.products
WHERE primary_image LIKE '%r2.cloudflarestorage%'
   OR primary_image LIKE '%.jpg'
   OR primary_image LIKE '%.png'
   OR primary_image LIKE '%.webp';

-- 2. Show sample of products with old image references
SELECT 
    id,
    name,
    sku,
    primary_image
FROM public.products
WHERE primary_image IS NOT NULL
  AND (primary_image LIKE '%.jpg' 
       OR primary_image LIKE '%.png'
       OR primary_image LIKE '%.webp')
  AND primary_image NOT LIKE '%supabase%'
LIMIT 10;

-- 3. Check product_images table for R2 references
SELECT 
    COUNT(*) as r2_images_count
FROM public.product_images
WHERE image_url LIKE '%r2.cloudflarestorage%'
   OR (image_url NOT LIKE '%supabase%' 
       AND image_url IS NOT NULL);

-- 4. Update products to clear broken image references
-- This will remove the broken references so they don't show 404s
UPDATE public.products
SET primary_image = NULL
WHERE primary_image IS NOT NULL
  AND primary_image NOT LIKE '%supabase%'
  AND primary_image NOT LIKE 'http%';

-- 5. Clear image_gallery arrays with broken references
UPDATE public.products
SET image_gallery = '{}'::text[]
WHERE array_length(image_gallery, 1) > 0
  AND NOT EXISTS (
    SELECT 1 FROM unnest(image_gallery) AS img
    WHERE img LIKE '%supabase%'
  );

-- 6. Show final status
SELECT 
    'Image References Fixed' as status,
    COUNT(*) FILTER (WHERE primary_image IS NOT NULL) as products_with_images,
    COUNT(*) FILTER (WHERE primary_image IS NULL) as products_without_images,
    COUNT(*) FILTER (WHERE primary_image LIKE '%supabase%') as products_with_supabase_images
FROM public.products;