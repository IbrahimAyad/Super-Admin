-- FIX RLS POLICIES FOR ENHANCED PRODUCTS
-- This will allow public read access to enhanced products

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view active products" ON products_enhanced;
DROP POLICY IF EXISTS "Admins can manage all products" ON products_enhanced;

-- Temporarily disable RLS to test
ALTER TABLE products_enhanced DISABLE ROW LEVEL SECURITY;

-- Verify products exist
SELECT COUNT(*) as product_count FROM products_enhanced;

-- Check products
SELECT 
  id,
  name,
  sku,
  status,
  price_tier,
  images->>'total_images' as total_images
FROM products_enhanced;