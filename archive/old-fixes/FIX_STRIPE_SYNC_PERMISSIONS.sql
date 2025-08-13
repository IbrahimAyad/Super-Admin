-- Fix permission issues for Stripe sync

-- 1. Enable RLS on required tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_sync_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- 2. Create policies for products table
DROP POLICY IF EXISTS "Allow all operations for authenticated users on products" ON products;
CREATE POLICY "Allow all operations for authenticated users on products"
ON products
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Create policies for product_variants table
DROP POLICY IF EXISTS "Allow all operations for authenticated users on product_variants" ON product_variants;
CREATE POLICY "Allow all operations for authenticated users on product_variants"
ON product_variants
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Create policies for stripe_sync_log table
DROP POLICY IF EXISTS "Allow all operations for authenticated users on stripe_sync_log" ON stripe_sync_log;
CREATE POLICY "Allow all operations for authenticated users on stripe_sync_log"
ON stripe_sync_log
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 5. Create policies for admin_users table
DROP POLICY IF EXISTS "Allow read access for authenticated users on admin_users" ON admin_users;
CREATE POLICY "Allow read access for authenticated users on admin_users"
ON admin_users
FOR SELECT
TO authenticated
USING (true);

-- 6. Allow service role full access (for Edge Functions)
DROP POLICY IF EXISTS "Service role has full access to products" ON products;
CREATE POLICY "Service role has full access to products"
ON products
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Service role has full access to product_variants" ON product_variants;
CREATE POLICY "Service role has full access to product_variants"
ON product_variants
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Service role has full access to stripe_sync_log" ON stripe_sync_log;
CREATE POLICY "Service role has full access to stripe_sync_log"
ON stripe_sync_log
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 7. Fix inventory table permissions
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all operations for authenticated users on inventory" ON inventory;
CREATE POLICY "Allow all operations for authenticated users on inventory"
ON inventory
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 8. Grant necessary permissions
GRANT ALL ON products TO authenticated;
GRANT ALL ON product_variants TO authenticated;
GRANT ALL ON stripe_sync_log TO authenticated;
GRANT SELECT ON admin_users TO authenticated;
GRANT ALL ON inventory TO authenticated;

-- 9. Grant permissions to service_role (for Edge Functions)
GRANT ALL ON products TO service_role;
GRANT ALL ON product_variants TO service_role;
GRANT ALL ON stripe_sync_log TO service_role;
GRANT ALL ON admin_users TO service_role;
GRANT ALL ON inventory TO service_role;

-- Test the permissions
SELECT current_user, current_role;