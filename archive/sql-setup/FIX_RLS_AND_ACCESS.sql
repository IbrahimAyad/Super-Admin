-- FIX RLS AND ACCESS ISSUES FOR ENHANCED PRODUCTS
-- Run this in Supabase SQL Editor

-- Step 1: Check current product status
SELECT 
  name,
  sku,
  status,
  CASE 
    WHEN status = 'active' THEN '✅ Visible with RLS'
    ELSE '❌ Hidden by RLS'
  END as visibility
FROM products_enhanced;

-- Step 2: OPTION A - Disable RLS entirely (SIMPLEST FOR NOW)
ALTER TABLE products_enhanced DISABLE ROW LEVEL SECURITY;

-- OR

-- Step 2: OPTION B - Fix the policies to be more permissive
-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Anyone can view active products" ON products_enhanced;
DROP POLICY IF EXISTS "Admins can manage all products" ON products_enhanced;

-- Create a more permissive read policy
CREATE POLICY "Anyone can view all products" 
ON products_enhanced FOR SELECT 
USING (true);  -- This allows everyone to read all products

-- Keep admin write policy
CREATE POLICY "Admins can manage products" 
ON products_enhanced FOR INSERT, UPDATE, DELETE
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
    AND is_active = true
  )
);

-- Step 3: Verify access works
SELECT COUNT(*) as total_products FROM products_enhanced;

-- Step 4: Test that products are accessible
SELECT 
  id,
  name,
  sku,
  status,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->>'total_images' as image_count
FROM products_enhanced
ORDER BY created_at DESC;