-- =====================================================
-- QUICK FIX FOR PRODUCTS ACCESS ISSUES
-- Run this IMMEDIATELY to restore product access
-- =====================================================

-- 1. Disable RLS temporarily on products to restore access
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- 2. Check if products exist
SELECT COUNT(*) as product_count FROM products;

-- 3. If you want to re-enable RLS later with proper policies, use:
-- ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- 
-- CREATE POLICY "Enable read access for all users" ON products
--   FOR SELECT USING (true);
-- 
-- CREATE POLICY "Enable all access for authenticated users" ON products
--   FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');