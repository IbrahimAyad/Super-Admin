-- ============================================
-- SUPABASE STORAGE BUCKETS SETUP
-- ============================================
-- This script creates the necessary storage buckets for product images
-- Run this in your Supabase SQL Editor

-- Note: Storage buckets cannot be created via SQL directly in Supabase
-- You need to create them via the Supabase Dashboard UI or API
-- This file documents the required setup

-- ============================================
-- REQUIRED STORAGE BUCKETS
-- ============================================
-- 1. Go to your Supabase Dashboard > Storage
-- 2. Create these buckets with the following settings:

-- BUCKET 1: product-images
-- - Name: product-images
-- - Public: YES (toggle on)
-- - File size limit: 5MB
-- - Allowed MIME types: image/jpeg, image/png, image/webp, image/gif

-- BUCKET 2: customer-avatars  
-- - Name: customer-avatars
-- - Public: YES (toggle on)
-- - File size limit: 2MB
-- - Allowed MIME types: image/jpeg, image/png, image/webp

-- ============================================
-- STORAGE POLICIES (Run these after creating buckets)
-- ============================================

-- Allow public read access to product images
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'product-images',
  'Public read access',
  '{"Select": true}'::jsonb,
  NULL
);

-- Allow authenticated users to upload product images
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'product-images',
  'Authenticated users can upload',
  '{"Insert": true}'::jsonb,
  '(auth.role() = ''authenticated'')'
);

-- Allow authenticated users to update their own uploads
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'product-images',
  'Users can update own uploads',
  '{"Update": true}'::jsonb,
  '(auth.uid() = owner)'
);

-- Allow authenticated users to delete their own uploads
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'product-images',
  'Users can delete own uploads',
  '{"Delete": true}'::jsonb,
  '(auth.uid() = owner)'
);

-- Allow public read access to customer avatars
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'customer-avatars',
  'Public read access',
  '{"Select": true}'::jsonb,
  NULL
);

-- Allow users to upload their own avatar
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'customer-avatars',
  'Users can upload own avatar',
  '{"Insert": true}'::jsonb,
  '(auth.uid()::text = (storage.foldername(name))[1])'
);

-- Allow users to update their own avatar
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'customer-avatars',
  'Users can update own avatar',
  '{"Update": true}'::jsonb,
  '(auth.uid()::text = (storage.foldername(name))[1])'
);

-- Allow users to delete their own avatar
INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
VALUES (
  'customer-avatars',
  'Users can delete own avatar',
  '{"Delete": true}'::jsonb,
  '(auth.uid()::text = (storage.foldername(name))[1])'
);

-- ============================================
-- FIX EXISTING IMAGE URLs (Optional)
-- ============================================
-- If your product_images table has incorrect URLs, you can update them
-- to use the proper Supabase Storage URL format:

-- First, check what URLs are currently stored:
SELECT DISTINCT 
  substring(url from 1 for 50) as url_preview,
  COUNT(*) as count
FROM product_images
GROUP BY url_preview
ORDER BY count DESC;

-- If URLs need fixing, update them to Supabase Storage format:
-- UPDATE product_images
-- SET url = REPLACE(
--   url,
--   'old-domain-or-pattern',
--   'https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/'
-- )
-- WHERE url LIKE '%old-domain-or-pattern%';

-- ============================================
-- VERIFY STORAGE SETUP
-- ============================================
-- After creating buckets and policies, verify with:

-- Check if buckets exist (run in Dashboard SQL Editor)
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE name IN ('product-images', 'customer-avatars');

-- Check storage policies
SELECT bucket_id, name, definition
FROM storage.policies
WHERE bucket_id IN ('product-images', 'customer-avatars');

-- ============================================
-- TEST UPLOAD (After setup)
-- ============================================
-- You can test the storage setup by:
-- 1. Going to /storage-test page in your app
-- 2. Or manually uploading via Supabase Dashboard > Storage
-- 3. Check that uploaded files are accessible via their public URLs

-- Example public URL format:
-- https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/[path-to-file]