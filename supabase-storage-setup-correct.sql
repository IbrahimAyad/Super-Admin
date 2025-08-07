-- ============================================
-- SUPABASE STORAGE BUCKETS SETUP (CORRECTED)
-- ============================================
-- Run this in your Supabase SQL Editor

-- ============================================
-- IMPORTANT: CREATE BUCKETS FIRST
-- ============================================
-- You MUST create the storage buckets via Supabase Dashboard first:
-- 1. Go to Storage section in your Supabase Dashboard
-- 2. Click "New bucket"
-- 3. Create these buckets:
--    - Name: product-images (Public: YES)
--    - Name: customer-avatars (Public: YES)

-- ============================================
-- VERIFY BUCKETS EXIST
-- ============================================
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE name IN ('product-images', 'customer-avatars');

-- ============================================
-- STORAGE RLS POLICIES (Using Correct Syntax)
-- ============================================

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for product images" ON storage.objects;
DROP POLICY IF EXISTS "Admin full access to product images" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

-- ============================================
-- PRODUCT IMAGES BUCKET POLICIES
-- ============================================

-- Allow public read access to product images
CREATE POLICY "Public read access for product images" ON storage.objects
FOR SELECT
USING (bucket_id = 'product-images');

-- Allow authenticated users to upload product images
CREATE POLICY "Authenticated users can upload product images" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Allow authenticated users to update product images
CREATE POLICY "Authenticated users can update product images" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images');

-- Allow authenticated users to delete product images
CREATE POLICY "Authenticated users can delete product images" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'product-images');

-- ============================================
-- CUSTOMER AVATARS BUCKET POLICIES
-- ============================================

-- Allow public read access to avatars
CREATE POLICY "Public read access for avatars" ON storage.objects
FOR SELECT
USING (bucket_id = 'customer-avatars');

-- Allow users to upload their own avatar (folder must match their user ID)
CREATE POLICY "Users can upload own avatar" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'customer-avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own avatar
CREATE POLICY "Users can update own avatar" ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'customer-avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete own avatar" ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'customer-avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- ALTERNATIVE: MAKE BUCKETS FULLY PUBLIC
-- ============================================
-- If you want to make the buckets completely public (easier for testing):

-- Make product-images bucket public (if not already)
UPDATE storage.buckets
SET public = true
WHERE name = 'product-images';

-- Make customer-avatars bucket public (if not already)
UPDATE storage.buckets
SET public = true
WHERE name = 'customer-avatars';

-- ============================================
-- TEST QUERIES
-- ============================================

-- Check if buckets are public
SELECT name, public
FROM storage.buckets
WHERE name IN ('product-images', 'customer-avatars');

-- Check storage policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- CHECK EXISTING PRODUCT IMAGES
-- ============================================

-- See what URLs are stored in your product_images table
SELECT 
    id,
    product_id,
    CASE 
        WHEN url LIKE 'http%' THEN 'Absolute URL'
        WHEN url LIKE '/%' THEN 'Absolute Path'
        ELSE 'Relative Path'
    END as url_type,
    substring(url from 1 for 100) as url_preview
FROM product_images
LIMIT 10;

-- Count images by URL pattern
SELECT 
    CASE 
        WHEN url LIKE 'https://gvcswimqaxvylgxbklbz.supabase.co%' THEN 'Supabase Storage URL'
        WHEN url LIKE 'http%' THEN 'Other HTTP URL'
        WHEN url IS NULL THEN 'NULL'
        ELSE 'Path Only'
    END as url_pattern,
    COUNT(*) as count
FROM product_images
GROUP BY url_pattern;

-- ============================================
-- FIX IMAGE URLS IF NEEDED
-- ============================================

-- Example: If your URLs are just filenames, update them to full Supabase Storage URLs
-- UPDATE product_images
-- SET url = 'https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/' || url
-- WHERE url NOT LIKE 'http%';

-- Example: If your URLs point to a different domain
-- UPDATE product_images
-- SET url = REPLACE(url, 'old-domain.com', 'gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public')
-- WHERE url LIKE '%old-domain.com%';

-- ============================================
-- VERIFY EVERYTHING IS WORKING
-- ============================================

-- Final check - this should return your bucket info
SELECT 
    b.id,
    b.name,
    b.public,
    COUNT(o.id) as object_count
FROM storage.buckets b
LEFT JOIN storage.objects o ON b.id = o.bucket_id
WHERE b.name IN ('product-images', 'customer-avatars')
GROUP BY b.id, b.name, b.public;